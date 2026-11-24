// ==============================================================================
// INSTITUTIONAL SETTINGS ROUTES (src/routes/settings.js)
// Governs global settings such as the main-task completion rule mode.
// ==============================================================================

const express = require('express');
const router = express.Router();
const db = require('../db');
const { verifyToken, requireRole } = require('../auth');
const { broadcast } = require('../websocket');

// GET /api/v1/settings - Public or authenticated
router.get('/', async (req, res) => {
  try {
    let settingRecord = null;
    if (db.isInMemoryFallback()) {
      settingRecord = db.memoryStore.app_settings.get('completion_rule');
    } else {
      const result = await db.query('SELECT * FROM app_settings WHERE key = $1;', ['completion_rule']);
      settingRecord = result.rows[0];
    }

    const rule = settingRecord ? settingRecord.value : (process.env.DEFAULT_COMPLETION_RULE || 'ModeA_Strict');
    res.json({
      completion_rule: rule,
      updated_at: settingRecord ? settingRecord.updated_at : new Date().toISOString()
    });
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// PUT /api/v1/settings - Admin & Secretary only
router.put('/', verifyToken, requireRole(['ADMIN', 'SECRETARY']), async (req, res) => {
  const { completion_rule } = req.body;

  if (!completion_rule || !['ModeA_Strict', 'ModeB_Relaxed'].includes(completion_rule)) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'Invalid completion_rule. Allowed values are "ModeA_Strict" or "ModeB_Relaxed".'
    });
  }

  const now = new Date().toISOString();
  try {
    if (db.isInMemoryFallback()) {
      db.memoryStore.app_settings.set('completion_rule', {
        key: 'completion_rule',
        value: completion_rule,
        updated_at: now,
        updated_by: req.user.name
      });
    } else {
      await db.query(`
        INSERT INTO app_settings (key, value, updated_at, updated_by)
        VALUES ($1, $2, $3, $4)
        ON CONFLICT (key) DO UPDATE
        SET value = EXCLUDED.value, updated_at = EXCLUDED.updated_at, updated_by = EXCLUDED.updated_by;
      `, ['completion_rule', completion_rule, now, req.user.name]);
    }

    // Broadcast change to all connected devices in realtime
    broadcast('settings_updated', {
      completion_rule,
      updated_at: now,
      updated_by: req.user.name
    });

    res.json({
      status: 'success',
      completion_rule,
      updated_at: now
    });
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

module.exports = router;
