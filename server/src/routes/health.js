// ==============================================================================
// HEALTH CHECK ROUTE (src/routes/health.js)
// Used by Render zero-downtime deploy checks and Cloudflare monitors.
// ==============================================================================

const express = require('express');
const router = express.Router();
const db = require('../db');
const { getActiveClientCount, getConnectedDevices } = require('../websocket');

router.get('/', async (req, res) => {
  const start = Date.now();
  let dbStatus = 'connected';
  let latencyMs = 0;

  try {
    const result = await db.query('SELECT 1;');
    latencyMs = Date.now() - start;
  } catch (err) {
    dbStatus = 'degraded: ' + err.message;
  }

  res.status(200).json({
    status: 'healthy',
    service: 'meeting-tracker-server',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    uptime_seconds: Math.floor(process.uptime()),
    database: {
      status: dbStatus,
      latency_ms: latencyMs,
      fallback_mode: db.isInMemoryFallback()
    },
    websockets: {
      active_clients: getActiveClientCount(),
      devices: getConnectedDevices()
    },
    memory: process.memoryUsage()
  });
});

module.exports = router;
