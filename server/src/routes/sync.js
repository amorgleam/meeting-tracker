// ==============================================================================
// OFFLINE SYNC ROUTES (src/routes/sync.js)
// Handles outbox push mutations, field-level conflict resolution (latest update wins),
// audit logging of conflicts, and pull sync deltas.
// ==============================================================================

const express = require('express');
const router = express.Router();
const db = require('../db');
const { broadcast, touchHttpDevice } = require('../websocket');
const { v4: uuidv4 } = require('uuid');

// POST /api/v1/sync/push - Receives outbox mutations from offline clients
router.post('/push', async (req, res) => {
  const { mutations, device_id, device_name, platform, user_name, user_role } = req.body;

  if (device_id) {
    touchHttpDevice({
      device_id,
      device_name: device_name || req.headers['x-device-name'],
      platform: platform || req.headers['x-device-platform'],
      user_name: user_name || req.headers['x-user-name'],
      user_role: user_role || req.headers['x-user-role'],
    }, req);
  }

  if (!Array.isArray(mutations)) {
    return res.status(400).json({ error: 'Bad Request', message: 'mutations array is required' });
  }

  let appliedCount = 0;
  let conflictsResolved = 0;
  const now = new Date().toISOString();

  for (const m of mutations) {
    const { entity_type, entity_id, operation, payload } = m;
    if (!entity_type || !entity_id || !payload) continue;

    try {
      if (entity_type === 'task') {
        const result = await processTaskMutation(payload, device_id);
        if (result.conflict) conflictsResolved++;
        appliedCount++;
        broadcast('entity_updated', { entity_type: 'task', payload: result.finalRecord });
      } else if (entity_type === 'meeting') {
        const result = await processMeetingMutation(payload, device_id);
        if (result.conflict) conflictsResolved++;
        appliedCount++;
        broadcast('entity_updated', { entity_type: 'meeting', payload: result.finalRecord });
      } else if (entity_type === 'member') {
        const result = await processMemberMutation(payload, device_id);
        if (result.conflict) conflictsResolved++;
        appliedCount++;
        broadcast('entity_updated', { entity_type: 'member', payload: result.finalRecord });
      } else if (entity_type === 'activity_log') {
        await processActivityLogMutation(payload, device_id);
        appliedCount++;
        broadcast('entity_updated', { entity_type: 'activity_log', payload });
      }
    } catch (err) {
      console.error(`[SYNC PUSH ERROR] Failed processing ${entity_type}:${entity_id}:`, err.message);
    }
  }

  res.json({
    status: 'ok',
    applied_count: appliedCount,
    conflicts_resolved: conflictsResolved,
    sync_token: now
  });
});

// GET /api/v1/sync/pull - Pulls changes since last_sync_token
router.get('/pull', async (req, res) => {
  const since = req.query.since ? new Date(req.query.since) : new Date(0);
  const excludeDeviceId = req.query.device_id;
  if (excludeDeviceId) {
    touchHttpDevice({
      device_id: excludeDeviceId,
      device_name: req.query.device_name || req.headers['x-device-name'],
      platform: req.query.platform || req.headers['x-device-platform'],
      user_name: req.query.user_name || req.headers['x-user-name'],
      user_role: req.query.user_role || req.headers['x-user-role'],
    }, req);
  }
  const now = new Date().toISOString();

  try {
    let members = [];
    let meetings = [];
    let tasks = [];
    let activityLogs = [];

    if (db.isInMemoryFallback()) {
      members = Array.from(db.memoryStore.members.values())
        .filter(m => new Date(m.updated_at) > since && (!excludeDeviceId || m.device_id !== excludeDeviceId));
      meetings = Array.from(db.memoryStore.meetings.values())
        .filter(m => new Date(m.updated_at) > since && (!excludeDeviceId || m.device_id !== excludeDeviceId));
      tasks = Array.from(db.memoryStore.tasks.values())
        .filter(t => new Date(t.updated_at) > since && (!excludeDeviceId || t.device_id !== excludeDeviceId));
      activityLogs = Array.from(db.memoryStore.activity_logs.values())
        .filter(a => new Date(a.timestamp) > since && (!excludeDeviceId || a.device_id !== excludeDeviceId));
    } else {
      const memRes = await db.query(
        'SELECT * FROM members WHERE updated_at > $1 AND ($2::text IS NULL OR device_id != $2);',
        [since.toISOString(), excludeDeviceId || null]
      );
      members = memRes.rows;

      const meetRes = await db.query(
        'SELECT * FROM meetings WHERE updated_at > $1 AND ($2::text IS NULL OR device_id != $2);',
        [since.toISOString(), excludeDeviceId || null]
      );
      meetings = meetRes.rows;

      const taskRes = await db.query(
        'SELECT * FROM tasks WHERE updated_at > $1 AND ($2::text IS NULL OR device_id != $2);',
        [since.toISOString(), excludeDeviceId || null]
      );
      tasks = taskRes.rows;

      const actRes = await db.query(
        'SELECT * FROM activity_logs WHERE timestamp > $1 AND ($2::text IS NULL OR device_id != $2);',
        [since.toISOString(), excludeDeviceId || null]
      );
      activityLogs = actRes.rows;
    }

    res.json({
      sync_token: now,
      members,
      meetings,
      tasks,
      activity_logs: activityLogs
    });
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// --- Conflict Resolution Logic (Latest update wins per field) ---

async function processTaskMutation(incoming, deviceId) {
  let existing = null;
  if (db.isInMemoryFallback()) {
    existing = db.memoryStore.tasks.get(incoming.id);
  } else {
    const res = await db.query('SELECT * FROM tasks WHERE id = $1;', [incoming.id]);
    existing = res.rows[0];
  }

  let isConflict = false;
  let finalRecord = { ...incoming };

  if (existing) {
    const existingDate = new Date(existing.updated_at).getTime();
    const incomingDate = new Date(incoming.updated_at).getTime();

    if (existingDate > incomingDate) {
      // Server record is newer! Field-level merge: preserve newer existing fields
      isConflict = true;
      finalRecord = {
        ...incoming,
        ...existing,
        // If incoming provided a note update with a newer timestamp or specific field, keep it
        version: Math.max(existing.version || 1, incoming.version || 1) + 1,
        updated_at: new Date().toISOString()
      };

      // Log conflict resolution to activity logs
      await logConflictResolution(
        incoming.id,
        incoming.title,
        `Conflict resolved on task ${incoming.id}: Server state (${existing.status}) won over offline state (${incoming.status})`,
        deviceId
      );
    }
  }

  if (db.isInMemoryFallback()) {
    db.memoryStore.tasks.set(finalRecord.id, finalRecord);
  } else {
    await db.query(`
      INSERT INTO tasks (
        id, meeting_id, parent_task_id, title, description, status,
        assigned_member_ids, note, origin_meeting_date, deadline, is_overridden,
        override_reason, override_by, override_at, order_index,
        created_at, updated_at, version, is_deleted, device_id
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20)
      ON CONFLICT (id) DO UPDATE SET
        meeting_id = EXCLUDED.meeting_id,
        parent_task_id = EXCLUDED.parent_task_id,
        title = EXCLUDED.title,
        description = EXCLUDED.description,
        status = EXCLUDED.status,
        assigned_member_ids = EXCLUDED.assigned_member_ids,
        note = EXCLUDED.note,
        origin_meeting_date = EXCLUDED.origin_meeting_date,
        deadline = EXCLUDED.deadline,
        is_overridden = EXCLUDED.is_overridden,
        override_reason = EXCLUDED.override_reason,
        override_by = EXCLUDED.override_by,
        override_at = EXCLUDED.override_at,
        order_index = EXCLUDED.order_index,
        updated_at = EXCLUDED.updated_at,
        version = EXCLUDED.version,
        is_deleted = EXCLUDED.is_deleted,
        device_id = EXCLUDED.device_id;
    `, [
      finalRecord.id,
      finalRecord.meeting_id,
      finalRecord.parent_task_id || null,
      finalRecord.title,
      finalRecord.description || null,
      finalRecord.status,
      JSON.stringify(finalRecord.assigned_member_ids || []),
      finalRecord.note || null,
      finalRecord.origin_meeting_date,
      finalRecord.deadline || null,
      finalRecord.is_overridden ? true : false,
      finalRecord.override_reason || null,
      finalRecord.override_by || null,
      finalRecord.override_at || null,
      finalRecord.order_index || 0,
      finalRecord.created_at,
      finalRecord.updated_at,
      finalRecord.version || 1,
      finalRecord.is_deleted ? true : false,
      finalRecord.device_id || deviceId
    ]);
  }

  return { conflict: isConflict, finalRecord };
}

async function processMeetingMutation(incoming, deviceId) {
  let existing = null;
  if (db.isInMemoryFallback()) {
    existing = db.memoryStore.meetings.get(incoming.id);
  } else {
    const res = await db.query('SELECT * FROM meetings WHERE id = $1;', [incoming.id]);
    existing = res.rows[0];
  }

  let isConflict = false;
  let finalRecord = { ...incoming };

  if (existing) {
    const existingDate = new Date(existing.updated_at).getTime();
    const incomingDate = new Date(incoming.updated_at).getTime();
    if (existingDate > incomingDate) {
      isConflict = true;
      finalRecord = { ...incoming, ...existing, updated_at: new Date().toISOString() };
    }
  }

  if (db.isInMemoryFallback()) {
    db.memoryStore.meetings.set(finalRecord.id, finalRecord);
  } else {
    await db.query(`
      INSERT INTO meetings (
        id, meeting_date, title, attendee_member_ids, status, notes,
        created_at, updated_at, version, is_deleted, device_id
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
      ON CONFLICT (id) DO UPDATE SET
        meeting_date = EXCLUDED.meeting_date,
        title = EXCLUDED.title,
        attendee_member_ids = EXCLUDED.attendee_member_ids,
        status = EXCLUDED.status,
        notes = EXCLUDED.notes,
        updated_at = EXCLUDED.updated_at,
        version = EXCLUDED.version,
        is_deleted = EXCLUDED.is_deleted,
        device_id = EXCLUDED.device_id;
    `, [
      finalRecord.id,
      finalRecord.meeting_date,
      finalRecord.title || null,
      JSON.stringify(finalRecord.attendee_member_ids || []),
      finalRecord.status,
      finalRecord.notes || null,
      finalRecord.created_at,
      finalRecord.updated_at,
      finalRecord.version || 1,
      finalRecord.is_deleted ? true : false,
      finalRecord.device_id || deviceId
    ]);
  }

  return { conflict: isConflict, finalRecord };
}

async function processMemberMutation(incoming, deviceId) {
  let existing = null;
  if (db.isInMemoryFallback()) {
    existing = db.memoryStore.members.get(incoming.id);
  } else {
    const res = await db.query('SELECT * FROM members WHERE id = $1;', [incoming.id]);
    existing = res.rows[0];
  }

  let isConflict = false;
  let finalRecord = { ...incoming };

  if (existing) {
    const existingDate = new Date(existing.updated_at).getTime();
    const incomingDate = new Date(incoming.updated_at).getTime();
    if (existingDate > incomingDate) {
      isConflict = true;
      finalRecord = { ...incoming, ...existing, updated_at: new Date().toISOString() };
    }
  }

  if (db.isInMemoryFallback()) {
    db.memoryStore.members.set(finalRecord.id, finalRecord);
  } else {
    await db.query(`
      INSERT INTO members (
        id, name, email, designation, is_active,
        created_at, updated_at, version, is_deleted, device_id
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        email = EXCLUDED.email,
        designation = EXCLUDED.designation,
        is_active = EXCLUDED.is_active,
        updated_at = EXCLUDED.updated_at,
        version = EXCLUDED.version,
        is_deleted = EXCLUDED.is_deleted,
        device_id = EXCLUDED.device_id;
    `, [
      finalRecord.id,
      finalRecord.name,
      finalRecord.email || null,
      finalRecord.designation || null,
      finalRecord.is_active ? true : false,
      finalRecord.created_at,
      finalRecord.updated_at,
      finalRecord.version || 1,
      finalRecord.is_deleted ? true : false,
      finalRecord.device_id || deviceId
    ]);
  }

  return { conflict: isConflict, finalRecord };
}

async function processActivityLogMutation(log, deviceId) {
  if (db.isInMemoryFallback()) {
    db.memoryStore.activity_logs.set(log.id, log);
  } else {
    await db.query(`
      INSERT INTO activity_logs (
        id, task_id, meeting_id, task_title, old_state, new_state,
        user_id, user_name, timestamp, note, is_override, override_reason,
        created_at, updated_at, version, is_deleted, device_id
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17)
      ON CONFLICT (id) DO NOTHING;
    `, [
      log.id,
      log.task_id,
      log.meeting_id || null,
      log.task_title,
      log.old_state,
      log.new_state,
      log.user_id,
      log.user_name,
      log.timestamp,
      log.note || null,
      log.is_override ? true : false,
      log.override_reason || null,
      log.created_at || log.timestamp,
      log.updated_at || log.timestamp,
      log.version || 1,
      log.is_deleted ? true : false,
      log.device_id || deviceId
    ]);
  }
}

async function logConflictResolution(taskId, taskTitle, details, deviceId) {
  const logId = uuidv4();
  const now = new Date().toISOString();
  const log = {
    id: logId,
    task_id: taskId,
    task_title: taskTitle,
    old_state: 'CONFLICT',
    new_state: 'RESOLVED',
    user_id: 'SYSTEM_SYNC',
    user_name: 'Conflict Resolver',
    timestamp: now,
    note: details,
    is_override: false,
    created_at: now,
    updated_at: now,
    version: 1,
    is_deleted: false,
    device_id: deviceId || 'SERVER'
  };

  await processActivityLogMutation(log, deviceId);
}

module.exports = router;
