// ==============================================================================
// ACCOUNT ACTIVITY LOGGER HELPER (src/utils/accountActivity.js)
// Persists authentication, enrollment, password, and security events.
// ==============================================================================

const { v4: uuidv4 } = require('uuid');
const db = require('../db');

function extractIp(req) {
  if (!req) return 'system';
  const forwarded = req.headers && req.headers['x-forwarded-for'];
  if (forwarded && typeof forwarded === 'string') {
    return forwarded.split(',')[0].trim();
  }
  return (req.headers && req.headers['cf-connecting-ip']) || (req.socket && req.socket.remoteAddress) || 'unknown';
}

async function recordAccountActivity({
  actorUserId = null,
  actorEmail = '',
  actorName = 'System',
  actorRole = 'SYSTEM',
  actionType,
  targetInfo = '',
  details = '',
  deviceId = '',
  platform = '',
  req = null,
}) {
  const entry = {
    id: uuidv4(),
    actor_user_id: actorUserId,
    actor_email: actorEmail,
    actor_name: actorName,
    actor_role: actorRole,
    action_type: actionType,
    target_info: targetInfo,
    details,
    device_id: deviceId || (req && req.headers && req.headers['x-device-id']) || 'unknown',
    platform: platform || (req && req.headers && req.headers['x-device-platform']) || 'Unknown',
    ip_address: extractIp(req),
    timestamp: new Date().toISOString(),
  };

  try {
    if (db.isInMemoryFallback()) {
      db.memoryStore.account_activities.set(entry.id, entry);
    } else {
      await db.query(
        `INSERT INTO account_activities (
          id, actor_user_id, actor_email, actor_name, actor_role,
          action_type, target_info, details, device_id, platform, ip_address, timestamp
        ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12);`,
        [
          entry.id,
          entry.actor_user_id,
          entry.actor_email,
          entry.actor_name,
          entry.actor_role,
          entry.action_type,
          entry.target_info,
          entry.details,
          entry.device_id,
          entry.platform,
          entry.ip_address,
          entry.timestamp,
        ]
      );
    }
  } catch (err) {
    console.warn('[ACCOUNT ACTIVITY LOG ERROR]', err.message);
  }
  return entry;
}

module.exports = { recordAccountActivity };
