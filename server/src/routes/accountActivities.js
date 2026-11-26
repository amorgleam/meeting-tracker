// ==============================================================================
// ACCOUNT ACTIVITIES AUDIT ROUTES (src/routes/accountActivities.js)
// Strictly Admin-only audit view of login, enrollment, password & session events.
// ==============================================================================

const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken, requireRole } = require('../auth');
const { recordAccountActivity } = require('../utils/accountActivity');

// GET /api/v1/account-activities - Admin only
router.get('/', verifyToken, requireRole(['ADMIN']), async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit || '200', 10), 500);
  try {
    let activities = [];
    if (db.isInMemoryFallback()) {
      activities = Array.from(db.memoryStore.account_activities.values())
        .sort((a, b) => String(b.timestamp).localeCompare(String(a.timestamp)))
        .slice(0, limit);
    } else {
      const result = await db.query(
        'SELECT * FROM account_activities ORDER BY timestamp DESC LIMIT $1;',
        [limit]
      );
      activities = result.rows;
    }
    res.json({ count: activities.length, activities });
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// POST /api/v1/account-activities - Record authenticated client event
router.post('/', verifyToken, async (req, res) => {
  const { action_type, target_info, details, device_id, platform } = req.body || {};
  if (!action_type) {
    return res.status(400).json({ error: 'Bad Request', message: 'action_type is required.' });
  }
  const entry = await recordAccountActivity({
    actorUserId: req.user.id,
    actorEmail: req.user.email,
    actorName: req.user.name,
    actorRole: req.user.role,
    actionType: String(action_type),
    targetInfo: String(target_info || ''),
    details: String(details || ''),
    deviceId: device_id ? String(device_id) : '',
    platform: platform ? String(platform) : '',
    req,
  });
  res.status(201).json(entry);
});

module.exports = router;
