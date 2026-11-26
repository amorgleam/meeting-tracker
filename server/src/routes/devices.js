// ==============================================================================
// CONNECTED DEVICES ROUTES (src/routes/devices.js)
// Lists currently active desktop, mobile, and web devices connected to sync.
// ==============================================================================

const express = require('express');
const router = express.Router();
const { getConnectedDevices, touchHttpDevice } = require('../websocket');

// GET /api/v1/devices - Returns list of active connected devices
router.get('/', (req, res) => {
  const devices = getConnectedDevices();
  res.json({
    count: devices.length,
    devices,
    server_time: new Date().toISOString()
  });
});

// POST /api/v1/devices/heartbeat - Registers or refreshes an active HTTP client
router.post('/heartbeat', (req, res) => {
  const { device_id, device_name, platform, user_name, user_role } = req.body || {};
  if (!device_id) {
    return res.status(400).json({ error: 'Bad Request', message: 'device_id is required' });
  }

  touchHttpDevice({ device_id, device_name, platform, user_name, user_role }, req);
  const devices = getConnectedDevices();
  res.json({
    status: 'ok',
    count: devices.length,
    devices
  });
});

module.exports = router;
