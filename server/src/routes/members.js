// ==============================================================================
// MEMBERS REGISTRY ROUTES (src/routes/members.js)
// ==============================================================================

const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken, requireRole } = require('../auth');
const { broadcast } = require('../websocket');
const { v4: uuidv4 } = require('uuid');

// GET /api/v1/members - List members
router.get('/', async (req, res) => {
  try {
    let members = [];
    if (db.isInMemoryFallback()) {
      members = Array.from(db.memoryStore.members.values())
        .filter(m => !m.is_deleted)
        .sort((a, b) => a.name.localeCompare(b.name));
    } else {
      const result = await db.query('SELECT * FROM members WHERE is_deleted = FALSE ORDER BY name ASC;');
      members = result.rows;
    }
    res.json(members);
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// POST /api/v1/members - Add member (Admin & Secretary)
router.post('/', verifyToken, requireRole(['ADMIN', 'SECRETARY']), async (req, res) => {
  const { name, email, designation, device_id } = req.body;

  if (!name) {
    return res.status(400).json({ error: 'Bad Request', message: 'Member name is required.' });
  }

  const id = uuidv4();
  const now = new Date().toISOString();
  const member = {
    id,
    name: name.trim(),
    email: email || '',
    designation: designation || 'Member',
    is_active: true,
    created_at: now,
    updated_at: now,
    version: 1,
    is_deleted: false,
    device_id: device_id || 'SERVER'
  };

  try {
    if (db.isInMemoryFallback()) {
      db.memoryStore.members.set(id, member);
    } else {
      await db.query(`
        INSERT INTO members (id, name, email, designation, is_active, created_at, updated_at, version, is_deleted, device_id)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10);
      `, [
        member.id,
        member.name,
        member.email,
        member.designation,
        member.is_active,
        member.created_at,
        member.updated_at,
        member.version,
        member.is_deleted,
        member.device_id
      ]);
    }

    broadcast('entity_updated', { entity_type: 'member', payload: member });
    res.status(201).json(member);
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

module.exports = router;
