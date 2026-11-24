// ==============================================================================
// TASKS & DOCKET ROUTES (src/routes/tasks.js)
// ==============================================================================

const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken, requireRole } = require('../auth');
const { broadcast } = require('../websocket');
const { v4: uuidv4 } = require('uuid');

// GET /api/v1/tasks - List tasks
router.get('/', async (req, res) => {
  const { meeting_id, status, parent_task_id } = req.query;

  try {
    let tasks = [];
    if (db.isInMemoryFallback()) {
      tasks = Array.from(db.memoryStore.tasks.values()).filter(t => {
        if (t.is_deleted) return false;
        if (meeting_id && t.meeting_id !== meeting_id) return false;
        if (status && t.status.toLowerCase() !== status.toLowerCase()) return false;
        if (parent_task_id !== undefined && t.parent_task_id !== parent_task_id) return false;
        return true;
      });
    } else {
      let queryText = 'SELECT * FROM tasks WHERE is_deleted = FALSE';
      const params = [];
      if (meeting_id) {
        params.push(meeting_id);
        queryText += ` AND meeting_id = $${params.length}`;
      }
      if (status) {
        params.push(status);
        queryText += ` AND LOWER(status) = LOWER($${params.length})`;
      }
      queryText += ' ORDER BY order_index ASC, created_at ASC;';
      const result = await db.query(queryText, params);
      tasks = result.rows;
    }
    res.json(tasks);
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// POST /api/v1/tasks - Add main task or subtask
router.post('/', verifyToken, requireRole(['ADMIN', 'SECRETARY']), async (req, res) => {
  const {
    meeting_id,
    parent_task_id,
    title,
    description,
    assigned_member_ids,
    note,
    origin_meeting_date,
    deadline,
    device_id
  } = req.body;

  if (!meeting_id || !title) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'Both meeting_id and title are required to enter an item into the docket.'
    });
  }

  const id = uuidv4();
  const now = new Date().toISOString();
  const task = {
    id,
    meeting_id,
    parent_task_id: parent_task_id || null,
    title: title.trim(),
    description: description || '',
    status: 'Pending',
    assigned_member_ids: assigned_member_ids || [],
    note: note || '',
    origin_meeting_date: origin_meeting_date ? new Date(origin_meeting_date).toISOString() : now,
    deadline: deadline ? new Date(deadline).toISOString() : null,
    is_overridden: false,
    order_index: 0,
    created_at: now,
    updated_at: now,
    version: 1,
    is_deleted: false,
    device_id: device_id || 'SERVER'
  };

  try {
    if (db.isInMemoryFallback()) {
      db.memoryStore.tasks.set(id, task);
    } else {
      await db.query(`
        INSERT INTO tasks (
          id, meeting_id, parent_task_id, title, description, status,
          assigned_member_ids, note, origin_meeting_date, deadline, is_overridden,
          order_index, created_at, updated_at, version, is_deleted, device_id
        ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17);
      `, [
        task.id,
        task.meeting_id,
        task.parent_task_id,
        task.title,
        task.description,
        task.status,
        JSON.stringify(task.assigned_member_ids),
        task.note,
        task.origin_meeting_date,
        task.deadline,
        task.is_overridden,
        task.order_index,
        task.created_at,
        task.updated_at,
        task.version,
        task.is_deleted,
        task.device_id
      ]);
    }

    broadcast('entity_updated', { entity_type: 'task', payload: task });
    res.status(201).json(task);
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

module.exports = router;
