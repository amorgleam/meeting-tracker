// ==============================================================================
// REALTIME WEBSOCKET SERVER & BROADCASTER (src/websocket.js)
// Broadcasts updates to all connected desktop, mobile, and web clients.
// Keeps connection alive through Cloudflare 100s proxy timeout via 30s pings.
// ==============================================================================

const WebSocket = require('ws');

let wss = null;
const clients = new Set();

function initWebSocket(server) {
  wss = new WebSocket.Server({ server, path: '/ws' });
  const heartbeatIntervalMs = parseInt(process.env.WS_HEARTBEAT_INTERVAL_MS || '30000', 10);

  wss.on('connection', (ws, req) => {
    ws.isAlive = true;
    ws.clientIp = req.headers['cf-connecting-ip'] || req.socket.remoteAddress;
    clients.add(ws);

    // Initial greeting
    ws.send(JSON.stringify({
      event: 'connected',
      message: 'Institutional Realtime WebSocket Gateway connected',
      server_time: new Date().toISOString()
    }));

    ws.on('pong', () => {
      ws.isAlive = true;
    });

    ws.on('message', (message) => {
      try {
        const parsed = JSON.parse(message);
        if (parsed.event === 'ping') {
          ws.send(JSON.stringify({ event: 'pong', timestamp: new Date().toISOString() }));
        }
      } catch (err) {
        // Ignore non-json frames
      }
    });

    ws.on('close', () => {
      clients.delete(ws);
    });

    ws.on('error', () => {
      clients.delete(ws);
    });
  });

  // Automated heartbeat interval: keeps Cloudflare proxy connection alive
  const pingInterval = setInterval(() => {
    for (const ws of clients) {
      if (!ws.isAlive) {
        clients.delete(ws);
        ws.terminate();
        continue;
      }
      ws.isAlive = false;
      ws.ping();
    }
  }, heartbeatIntervalMs);

  wss.on('close', () => {
    clearInterval(pingInterval);
  });

  console.log('[WEBSOCKET] Realtime WebSocket gateway initialized on path /ws');
  return wss;
}

/**
 * Broadcast an event payload to all active clients (optionally excluding sender)
 */
function broadcast(event, data, excludeWs = null) {
  const payload = JSON.stringify({
    event,
    data,
    timestamp: new Date().toISOString()
  });

  for (const client of clients) {
    if (client !== excludeWs && client.readyState === WebSocket.OPEN) {
      try {
        client.send(payload);
      } catch (err) {
        console.warn('[WEBSOCKET BROADCAST ERROR]', err.message);
      }
    }
  }
}

function getActiveClientCount() {
  return clients.size;
}

module.exports = {
  initWebSocket,
  broadcast,
  getActiveClientCount
};
