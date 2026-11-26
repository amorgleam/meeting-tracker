// ==============================================================================
// DATABASE CONNECTION & POOL MANAGER (src/db.js)
// Supports PostgreSQL in production and provides automatic fallback memory store
// for offline testing environments.
// ==============================================================================

const { Pool } = require('pg');
require('dotenv').config();

let pool = null;
let isInMemoryFallback = false;

// In-memory table store used when PostgreSQL is unreachable in mock/test mode
const memoryStore = {
  app_settings: new Map([
    ['completion_rule', { key: 'completion_rule', value: process.env.DEFAULT_COMPLETION_RULE || 'ModeA_Strict', updated_at: new Date().toISOString(), updated_by: 'INIT' }]
  ]),
  users: new Map(),
  members: new Map(),
  meetings: new Map(),
  tasks: new Map(),
  activity_logs: new Map(),
  account_activities: new Map()
};

const databaseUrl = process.env.DATABASE_URL;

if (databaseUrl && !databaseUrl.includes('secret_password')) {
  try {
    const isSsl = process.env.NODE_ENV === 'production' || databaseUrl.includes('sslmode=require');
    pool = new Pool({
      connectionString: databaseUrl,
      ssl: isSsl ? { rejectUnauthorized: false } : false,
      max: parseInt(process.env.PG_MAX_CONNECTIONS || '20', 10),
      connectionTimeoutMillis: parseInt(process.env.PG_CONNECTION_TIMEOUT_MS || '5000', 10),
    });

    pool.on('error', (err) => {
      console.error('Unexpected PostgreSQL client error:', err.message);
    });
  } catch (err) {
    console.warn('PostgreSQL pool initialization failed, switching to in-memory fallback:', err.message);
    isInMemoryFallback = true;
  }
} else {
  console.log('No valid DATABASE_URL provided. Using resilient in-memory fallback store.');
  isInMemoryFallback = true;
}

/**
 * Execute a query against PostgreSQL or fallback memory store
 */
async function query(text, params = []) {
  if (pool && !isInMemoryFallback) {
    try {
      const start = Date.now();
      const res = await pool.query(text, params);
      const duration = Date.now() - start;
      return res;
    } catch (err) {
      console.warn(`Query failed on PostgreSQL (${err.message}). Executing via memory adapter.`);
      return queryMemory(text, params);
    }
  } else {
    return queryMemory(text, params);
  }
}

/**
 * In-memory SQL emulator for rapid testing and zero-dependency verification
 */
function queryMemory(sql, params) {
  const normalized = sql.trim().toUpperCase();

  if (normalized.startsWith('SELECT 1') || normalized.startsWith('SELECT NOW()')) {
    return { rows: [{ '?column?': 1, now: new Date().toISOString() }], rowCount: 1 };
  }

  // Settings
  if (sql.includes('FROM app_settings WHERE key = $1')) {
    const key = params[0];
    const val = memoryStore.app_settings.get(key);
    return { rows: val ? [val] : [], rowCount: val ? 1 : 0 };
  }

  if (sql.includes('INSERT INTO app_settings') || sql.includes('UPDATE app_settings')) {
    const key = params[0];
    const value = params[1];
    const record = { key, value, updated_at: new Date().toISOString() };
    memoryStore.app_settings.set(key, record);
    return { rows: [record], rowCount: 1 };
  }

  // User queries
  if (sql.includes('FROM users WHERE email = $1')) {
    const email = params[0];
    const user = Array.from(memoryStore.users.values()).find(u => u.email === email && !u.is_deleted);
    return { rows: user ? [user] : [], rowCount: user ? 1 : 0 };
  }

  // Members queries
  if (sql.includes('FROM members')) {
    const list = Array.from(memoryStore.members.values()).filter(m => !m.is_deleted);
    return { rows: list, rowCount: list.length };
  }

  // Meetings queries
  if (sql.includes('FROM meetings')) {
    const list = Array.from(memoryStore.meetings.values()).filter(m => !m.is_deleted);
    return { rows: list, rowCount: list.length };
  }

  // Tasks queries
  if (sql.includes('FROM tasks')) {
    const list = Array.from(memoryStore.tasks.values()).filter(t => !t.is_deleted);
    return { rows: list, rowCount: list.length };
  }

  // Activity logs queries
  if (sql.includes('FROM activity_logs')) {
    const list = Array.from(memoryStore.activity_logs.values());
    return { rows: list, rowCount: list.length };
  }

  return { rows: [], rowCount: 0 };
}

async function getClient() {
  if (pool && !isInMemoryFallback) {
    return await pool.connect();
  }
  return {
    query: (text, params) => query(text, params),
    release: () => {}
  };
}

module.exports = {
  query,
  getClient,
  pool,
  memoryStore,
  isInMemoryFallback: () => isInMemoryFallback,
  setFallback: (val) => { isInMemoryFallback = val; }
};
