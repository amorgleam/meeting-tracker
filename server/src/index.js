// ==============================================================================
// SERVER ENTRY POINT (src/index.js)
// Initializes HTTP Server, WebSocket Gateway, and starts listening.
// ==============================================================================

require('dotenv').config();
const http = require('http');
const app = require('./app');
const { initWebSocket } = require('./websocket');
const { runMigrations } = require('./migrate');
const { runSeed } = require('./seed');

const PORT = parseInt(process.env.PORT || '3000', 10);
const server = http.createServer(app);

// Initialize WebSocket gateway attached to HTTP server
initWebSocket(server);

async function start() {
  console.log('====================================================');
  console.log('INSTITUTIONAL MEETING TRACKER - ENTERPRISE BACKEND');
  console.log('====================================================');

  try {
    // Attempt migrations and seed on boot
    await runMigrations();
    await runSeed();
  } catch (err) {
    console.warn('[BOOT WARNING] Database initialization warning:', err.message);
  }

  server.listen(PORT, '0.0.0.0', () => {
    console.log(`[HTTP] Meeting Tracker API server listening on port ${PORT}`);
    console.log(`[HTTP] Health probe available at: http://localhost:${PORT}/api/v1/health`);
    console.log(`[HTTP] Interactive API Docs at:  http://localhost:${PORT}/api/docs`);
    console.log(`[WS]   WebSocket Gateway at:     ws://localhost:${PORT}/ws`);
    console.log('====================================================');
  });
}

// Graceful Termination
function shutdown(signal) {
  console.log(`\n[SHUTDOWN] Received ${signal}. Closing server connections gracefully...`);
  server.close(() => {
    console.log('[SHUTDOWN] HTTP & WebSocket servers successfully closed.');
    process.exit(0);
  });

  // Force exit if not closed within 10 seconds
  setTimeout(() => {
    console.error('[SHUTDOWN] Forced shutdown after timeout.');
    process.exit(1);
  }, 10000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

if (require.main === module) {
  start();
}

module.exports = { server, app };
