// ==============================================================================
// MEETINGS ROUTES (src/routes/meetings.js)
// ==============================================================================

const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken, requireRole } = require('../auth');
const { broadcast } = require('../websocket');
const { v4: uuidv4 } = require('uuid');

// GET /api/v1/meetings - List meetings
router.get('/', async (req, res) => {
  try {
    let meetings = [];
    if (db.isInMemoryFallback()) {
      meetings = Array.from(db.memoryStore.meetings.values())
        .filter(m => !m.is_deleted)
        .sort((a, b) => new Date(b.meeting_date) - new Date(a.meeting_date));
    } else {
      const result = await db.query('SELECT * FROM meetings WHERE is_deleted = FALSE ORDER BY meeting_date DESC;');
      meetings = result.rows;
    }
    res.json(meetings);
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// GET /api/v1/meetings/:id - Meeting details with tasks and activity log
router.get('/:id', async (req, res) => {
  const { id } = req.params;
  try {
    let meeting = null;
    let tasks = [];
    let activityLogs = [];

    if (db.isInMemoryFallback()) {
      meeting = db.memoryStore.meetings.get(id);
      tasks = Array.from(db.memoryStore.tasks.values()).filter(t => t.meeting_id === id && !t.is_deleted);
      activityLogs = Array.from(db.memoryStore.activity_logs.values()).filter(a => a.meeting_id === id);
    } else {
      const meetRes = await db.query('SELECT * FROM meetings WHERE id = $1 AND is_deleted = FALSE;', [id]);
      meeting = meetRes.rows[0];

      if (meeting) {
        const taskRes = await db.query('SELECT * FROM tasks WHERE meeting_id = $1 AND is_deleted = FALSE ORDER BY order_index ASC;', [id]);
        tasks = taskRes.rows;

        const actRes = await db.query('SELECT * FROM activity_logs WHERE meeting_id = $1 ORDER BY timestamp DESC;', [id]);
        activityLogs = actRes.rows;
      }
    }

    if (!meeting) {
      return res.status(404).json({ error: 'Not Found', message: 'Meeting session not found.' });
    }

    res.json({
      ...meeting,
      tasks,
      activity_logs: activityLogs
    });
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// POST /api/v1/meetings - Convene formal meeting
router.post('/', verifyToken, requireRole(['ADMIN', 'SECRETARY']), async (req, res) => {
  const { meeting_date, title, attendee_member_ids, notes, device_id } = req.body;

  if (!meeting_date) {
    return res.status(400).json({ error: 'Bad Request', message: 'meeting_date is required to convene a session.' });
  }

  const id = uuidv4();
  const now = new Date().toISOString();
  const meeting = {
    id,
    meeting_date: new Date(meeting_date).toISOString(),
    title: title || `Executive Session - ${meeting_date.substring(0, 10)}`,
    attendee_member_ids: attendee_member_ids || [],
    status: 'In Progress',
    notes: notes || '',
    created_at: now,
    updated_at: now,
    version: 1,
    is_deleted: false,
    device_id: device_id || 'SERVER'
  };

  try {
    if (db.isInMemoryFallback()) {
      db.memoryStore.meetings.set(id, meeting);
    } else {
      await db.query(`
        INSERT INTO meetings (id, meeting_date, title, attendee_member_ids, status, notes, created_at, updated_at, version, is_deleted, device_id)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);
      `, [
        meeting.id,
        meeting.meeting_date,
        meeting.title,
        JSON.stringify(meeting.attendee_member_ids),
        meeting.status,
        meeting.notes,
        meeting.created_at,
        meeting.updated_at,
        meeting.version,
        meeting.is_deleted,
        meeting.device_id
      ]);
    }

    broadcast('entity_updated', { entity_type: 'meeting', payload: meeting });
    res.status(201).json(meeting);
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

module.exports = router;
