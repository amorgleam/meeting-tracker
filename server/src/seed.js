// ==============================================================================
// DATABASE SEEDER (src/seed.js)
// Seeds default institutional accounts, settings, and initial docket items.
// ==============================================================================

const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const db = require('./db');

async function runSeed() {
  console.log('[SEED] Seeding institutional database accounts and demo records...');

  const passwordHash = await bcrypt.hash('Admin@123', 10);
  const secHash = await bcrypt.hash('Secretary@123', 10);
  const viewHash = await bcrypt.hash('Viewer@123', 10);

  // Populate memory store if fallback mode is active
  db.memoryStore.users.set('usr-admin-001', {
    id: 'usr-admin-001',
    email: 'admin@institution.gov',
    username: 'admin',
    password_hash: passwordHash,
    name: 'Director Arthur Pendelton',
    role: 'ADMIN',
    is_active: true,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    is_deleted: false
  });

  db.memoryStore.users.set('usr-sec-002', {
    id: 'usr-sec-002',
    email: 'secretary@institution.gov',
    username: 'secretary',
    password_hash: secHash,
    name: 'Secretary Eleanor Vance',
    role: 'SECRETARY',
    is_active: true,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    is_deleted: false
  });

  db.memoryStore.users.set('usr-view-003', {
    id: 'usr-view-003',
    email: 'viewer@institution.gov',
    username: 'viewer',
    password_hash: viewHash,
    name: 'Auditor Marcus Brody',
    role: 'VIEWER',
    is_active: true,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    is_deleted: false
  });

  // Seed Members into memoryStore
  const members = [
    { id: 'mem-001', name: 'Arthur Pendelton', email: 'director@institution.gov', designation: 'Executive Director', is_active: true },
    { id: 'mem-002', name: 'Eleanor Vance', email: 'secretary@institution.gov', designation: 'General Secretary', is_active: true },
    { id: 'mem-003', name: 'Dr. Alistair Finch', email: 'finch@institution.gov', designation: 'Chief Financial Officer', is_active: true },
    { id: 'mem-004', name: 'Clara Oswald', email: 'clara@institution.gov', designation: 'Head of Operations', is_active: true },
    { id: 'mem-005', name: 'Gideon Cross', email: 'gideon@institution.gov', designation: 'Lead Systems Architect', is_active: true }
  ];
  for (const m of members) {
    db.memoryStore.members.set(m.id, {
      ...m,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      version: 1,
      is_deleted: false,
      device_id: 'SERVER_INIT'
    });
  }

  // Seed demo past meeting
  const pastMeetingDate = new Date(Date.now() - 7 * 86400000).toISOString();
  db.memoryStore.meetings.set('meet-past-001', {
    id: 'meet-past-001',
    meeting_date: pastMeetingDate,
    title: 'Regular Directorate Council - Session XXIV',
    attendee_member_ids: ['mem-001', 'mem-002', 'mem-003', 'mem-004'],
    status: 'Adjourned',
    notes: 'Quorum established. Annual capital expenditure docket reviewed.',
    created_at: pastMeetingDate,
    updated_at: pastMeetingDate,
    version: 1,
    is_deleted: false,
    device_id: 'SERVER_INIT'
  });

  // Seed carried forward demo tasks
  db.memoryStore.tasks.set('task-cf-001', {
    id: 'task-cf-001',
    meeting_id: 'meet-past-001',
    parent_task_id: null,
    title: 'Implementing a barcode scanning and inventory tracking system',
    description: 'Complete overhaul of central equipment storage ledger',
    status: 'Pending',
    assigned_member_ids: ['mem-004', 'mem-005'],
    note: 'Awaiting vendor RFP responses',
    origin_meeting_date: pastMeetingDate,
    is_overridden: false,
    order_index: 1,
    created_at: pastMeetingDate,
    updated_at: pastMeetingDate,
    version: 1,
    is_deleted: false,
    device_id: 'SERVER_INIT'
  });

  db.memoryStore.tasks.set('task-cf-001-sub1', {
    id: 'task-cf-001-sub1',
    meeting_id: 'meet-past-001',
    parent_task_id: 'task-cf-001',
    title: 'Draft technical specifications for handheld scanners',
    description: 'Hardware compatibility analysis',
    status: 'Completed',
    assigned_member_ids: ['mem-005'],
    note: 'Signed off by IT architecture',
    origin_meeting_date: pastMeetingDate,
    is_overridden: false,
    order_index: 1,
    created_at: pastMeetingDate,
    updated_at: pastMeetingDate,
    version: 1,
    is_deleted: false,
    device_id: 'SERVER_INIT'
  });

  db.memoryStore.tasks.set('task-cf-001-sub2', {
    id: 'task-cf-001-sub2',
    meeting_id: 'meet-past-001',
    parent_task_id: 'task-cf-001',
    title: 'Deploy warehouse Wi-Fi mesh relays',
    description: 'Coverage verification in storage wing B',
    status: 'Pending',
    assigned_member_ids: ['mem-005'],
    note: 'Contractors scheduled for Tuesday installation',
    origin_meeting_date: pastMeetingDate,
    is_overridden: false,
    order_index: 2,
    created_at: pastMeetingDate,
    updated_at: pastMeetingDate,
    version: 1,
    is_deleted: false,
    device_id: 'SERVER_INIT'
  });

  // Also execute SQL seed if PostgreSQL pool is active
  const seedFile = path.join(__dirname, '..', 'migrations', '002_seed_demo_data.sql');
  if (fs.existsSync(seedFile)) {
    try {
      const sql = fs.readFileSync(seedFile, 'utf8');
      await db.query(sql);
      console.log('[SEED] SQL seed data applied.');
    } catch (err) {
      console.log('[SEED] Direct SQL skipped or handled by memory store:', err.message);
    }
  }

  // Ensure default seeded user hashes in PostgreSQL are real working bcrypt hashes
  // (only updates if missing or still holding the legacy migration placeholder hash)
  const legacyPlaceholderHash = '$2a$10$Gpvq1b/C8R4lVf6BfI6l0uA9oE9X0GqM5Q.Y1lB3eE0Qj2B8gXn1S';
  const defaultUsers = [
    { id: 'usr-admin-001', email: 'admin@institution.gov', username: 'admin', hash: passwordHash, name: 'Director Arthur Pendelton', role: 'ADMIN' },
    { id: 'usr-sec-002', email: 'secretary@institution.gov', username: 'secretary', hash: secHash, name: 'Secretary Eleanor Vance', role: 'SECRETARY' },
    { id: 'usr-view-003', email: 'viewer@institution.gov', username: 'viewer', hash: viewHash, name: 'Auditor Marcus Brody', role: 'VIEWER' },
  ];
  if (!db.isInMemoryFallback()) {
    for (const u of defaultUsers) {
      try {
        await db.query(
          `INSERT INTO users (id, email, username, password_hash, name, role, is_active, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
           ON CONFLICT (email) DO UPDATE SET
             username = COALESCE(users.username, EXCLUDED.username),
             password_hash = CASE
               WHEN users.password_hash = $7 THEN EXCLUDED.password_hash
               ELSE users.password_hash
             END;`,
          [u.id, u.email, u.username, u.hash, u.name, u.role, legacyPlaceholderHash]
        );
      } catch (err) {
        console.warn(`[SEED USER WARNING] ${u.email}:`, err.message);
      }
    }
  }

  console.log('[SEED] Demo data initialization complete.');
}

if (require.main === module) {
  runSeed().then(() => process.exit(0)).catch(err => {
    console.error('[SEED FATAL]', err);
    process.exit(1);
  });
}

module.exports = { runSeed };
