// ==============================================================================
// REALTIME WEBSOCKET SERVER & CONNECTED DEVICES REGISTRY (src/websocket.js)
// Broadcasts updates to all connected desktop, mobile, and web clients.
// Tracks live WebSocket + recent HTTP sync devices and broadcasts presence.
// Keeps connection alive through proxy timeouts via 30s pings.
// ==============================================================================

const WebSocket = require('ws');
const url = require('url');

let wss = null;
const clients = new Set();
const httpDevices = new Map(); // device_id -> metadata with TTL

const HTTP_DEVICE_TTL_MS = 120 * 1000; // 2 minutes active window for HTTP sync clients

function extractClientIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (forwarded && typeof forwarded === 'string') {
    return forwarded.split(',')[0].trim();
  }
  return req.headers['cf-connecting-ip'] || req.socket.remoteAddress || 'unknown';
}

function getConnectedDevices() {
  const nowMs = Date.now();
  const byId = new Map();

  // 1. Live WebSocket clients (highest fidelity, active right now)
  for (const ws of clients) {
    if (ws.readyState !== WebSocket.OPEN) continue;
    const meta = ws.deviceMeta || {};
    const id = meta.device_id || `ws-${meta.connected_at || 'anon'}`;
    byId.set(id, {
      device_id: id,
      device_name: meta.device_name || id,
      platform: meta.platform || 'Unknown',
      user_name: meta.user_name || 'Guest',
      user_role: meta.user_role || 'Viewer',
      ip: ws.clientIp || 'unknown',
      connected_at: meta.connected_at,
      last_seen_at: meta.last_seen_at || meta.connected_at,
      transport: 'websocket',
      online: true,
    });
  }

  // 2. Recent HTTP sync clients (prune expired)
  for (const [id, info] of httpDevices.entries()) {
    if (nowMs - info.lastSeenMs > HTTP_DEVICE_TTL_MS) {
      httpDevices.delete(id);
      continue;
    }
    if (!byId.has(id)) {
      byId.set(id, {
        device_id: id,
        device_name: info.device_name || id,
        platform: info.platform || 'Unknown',
        user_name: info.user_name || 'Guest',
        user_role: info.user_role || 'Viewer',
        ip: info.ip || 'unknown',
        connected_at: info.connected_at,
        last_seen_at: info.last_seen_at,
        transport: 'http',
        online: true,
      });
    }
  }

  return Array.from(byId.values()).sort((a, b) =>
    String(b.last_seen_at || '').localeCompare(String(a.last_seen_at || ''))
  );
}

function touchHttpDevice(meta = {}, req = null) {
  if (!meta.device_id) return;
  const nowIso = new Date().toISOString();
  const existing = httpDevices.get(meta.device_id);
  const entry = {
    device_id: meta.device_id,
    device_name: meta.device_name || existing?.device_name || meta.device_id,
    platform: meta.platform || existing?.platform || 'Unknown',
    user_name: meta.user_name || existing?.user_name || 'Member',
    user_role: meta.user_role || existing?.user_role || 'Admin',
    ip: req ? extractClientIp(req) : (existing?.ip || 'unknown'),
    connected_at: existing?.connected_at || nowIso,
    last_seen_at: nowIso,
    lastSeenMs: Date.now(),
  };

  const isNew = !existing;
  httpDevices.set(meta.device_id, entry);

  // Also update matching live WebSocket if present
  for (const ws of clients) {
    if (ws.deviceMeta?.device_id === meta.device_id) {
      ws.deviceMeta = {
        ...ws.deviceMeta,
        device_name: entry.device_name,
        platform: entry.platform,
        user_name: entry.user_name,
        user_role: entry.user_role,
        last_seen_at: nowIso,
      };
    }
  }

  if (isNew) {
    broadcastDevices();
  }
}

function broadcastDevices() {
  const devices = getConnectedDevices();
  broadcast('devices_updated', {
    count: devices.length,
    devices,
  });
}

function initWebSocket(server) {
  wss = new WebSocket.Server({ server, path: '/ws' });
  const heartbeatIntervalMs = parseInt(process.env.WS_HEARTBEAT_INTERVAL_MS || '30000', 10);

  wss.on('connection', (ws, req) => {
    const parsedUrl = url.parse(req.url || '', true);
    const query = parsedUrl.query || {};
    const nowIso = new Date().toISOString();

    ws.isAlive = true;
    ws.clientIp = extractClientIp(req);
    ws.deviceMeta = {
      device_id: query.device_id ? String(query.device_id) : `ws-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
      device_name: query.device_name ? String(query.device_name) : (query.device_id ? String(query.device_id) : 'Connected Client'),
      platform: query.platform ? String(query.platform) : 'Unknown',
      user_name: query.user_name ? String(query.user_name) : 'Institutional User',
      user_role: query.user_role ? String(query.user_role) : 'Admin',
      connected_at: nowIso,
      last_seen_at: nowIso,
    };
    clients.add(ws);

    // Initial greeting + current device list
    ws.send(JSON.stringify({
      event: 'connected',
      message: 'Institutional Realtime WebSocket Gateway connected',
      server_time: nowIso,
      devices: getConnectedDevices(),
    }));

    broadcastDevices();

    ws.on('pong', () => {
      ws.isAlive = true;
      if (ws.deviceMeta) {
        ws.deviceMeta.last_seen_at = new Date().toISOString();
      }
    });

    ws.on('message', (message) => {
      try {
        const parsed = JSON.parse(message);
        if (parsed.event === 'ping') {
          if (ws.deviceMeta) {
            ws.deviceMeta.last_seen_at = new Date().toISOString();
          }
          ws.send(JSON.stringify({ event: 'pong', timestamp: new Date().toISOString() }));
        } else if (parsed.event === 'register_device' && parsed.data) {
          const d = parsed.data;
          ws.deviceMeta = {
            ...ws.deviceMeta,
            device_id: d.device_id || ws.deviceMeta.device_id,
            device_name: d.device_name || ws.deviceMeta.device_name,
            platform: d.platform || ws.deviceMeta.platform,
            user_name: d.user_name || ws.deviceMeta.user_name,
            user_role: d.user_role || ws.deviceMeta.user_role,
            last_seen_at: new Date().toISOString(),
          };
          broadcastDevices();
        }
      } catch (err) {
        // Ignore non-json frames
      }
    });

    ws.on('close', () => {
      clients.delete(ws);
      broadcastDevices();
    });

    ws.on('error', () => {
      clients.delete(ws);
      broadcastDevices();
    });
  });

  // Automated heartbeat interval: keeps proxy connection alive
  const pingInterval = setInterval(() => {
    for (const ws of clients) {
      if (!ws.isAlive) {
        clients.delete(ws);
        ws.terminate();
        broadcastDevices();
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
  return getConnectedDevices().length;
}

module.exports = {
  initWebSocket,
  broadcast,
  getActiveClientCount,
  getConnectedDevices,
  touchHttpDevice,
};
