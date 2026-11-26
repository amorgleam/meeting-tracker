// ==============================================================================
// BACKEND UNIT & INTEGRATION TESTS (test/api.test.js)
// Tests: Auth, Health, Settings, Sync Push/Pull, and Conflict Resolution.
// ==============================================================================

const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const app = require('../src/app');
const { runSeed } = require('../src/seed');
const { memoryStore } = require('../src/db');

let server;
let baseUrl;

test.before(async () => {
  await runSeed();
  await new Promise((resolve) => {
    server = http.createServer(app);
    server.listen(0, '127.0.0.1', () => {
      const port = server.address().port;
      baseUrl = `http://127.0.0.1:${port}`;
      resolve();
    });
  });
});

test.after(async () => {
  await new Promise((resolve) => server.close(resolve));
});

test('GET /api/v1/health returns healthy status and latency probe', async () => {
  const res = await fetch(`${baseUrl}/api/v1/health`);
  assert.equal(res.status, 200);
  const data = await res.json();
  assert.equal(data.status, 'healthy');
  assert.equal(data.service, 'meeting-tracker-server');
  assert.ok(data.database);
});

test('POST /api/v1/auth/login authenticates Admin credentials', async () => {
  const res = await fetch(`${baseUrl}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'admin@institution.gov', password: 'Admin@123' })
  });
  assert.equal(res.status, 200);
  const data = await res.json();
  assert.ok(data.token);
  assert.equal(data.user.role, 'ADMIN');
});

test('POST /api/v1/auth/login rejects invalid credentials', async () => {
  const res = await fetch(`${baseUrl}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'admin@institution.gov', password: 'WrongPassword' })
  });
  assert.equal(res.status, 401);
});

test('GET /api/v1/settings returns completion rule', async () => {
  const res = await fetch(`${baseUrl}/api/v1/settings`);
  assert.equal(res.status, 200);
  const data = await res.json();
  assert.ok(['ModeA_Strict', 'ModeB_Relaxed'].includes(data.completion_rule));
});

test('POST /api/v1/sync/push and GET /api/v1/sync/pull delta cycle', async () => {
  // Push a new task from client
  const now = new Date().toISOString();
  const pushPayload = {
    device_id: 'test-device-01',
    mutations: [
      {
        id: 'outbox-1',
        entity_type: 'task',
        entity_id: 'test-task-sync-1',
        operation: 'UPSERT',
        payload: {
          id: 'test-task-sync-1',
          meeting_id: 'meet-past-001',
          title: 'Automated Sync Verification Item',
          status: 'In Progress',
          origin_meeting_date: now,
          deadline: new Date(Date.now() + 86400000 * 7).toISOString(),
          created_at: now,
          updated_at: now,
          version: 1,
          is_deleted: false,
          device_id: 'test-device-01'
        }
      }
    ]
  };

  const pushRes = await fetch(`${baseUrl}/api/v1/sync/push`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(pushPayload)
  });
  assert.equal(pushRes.status, 200);
  const pushResult = await pushRes.json();
  assert.equal(pushResult.applied_count, 1);

  // Pull changes
  const pullRes = await fetch(`${baseUrl}/api/v1/sync/pull?since=${encodeURIComponent(new Date(Date.now() - 60000).toISOString())}`);
  assert.equal(pullRes.status, 200);
  const pullData = await pullRes.json();
  const found = pullData.tasks.find(t => t.id === 'test-task-sync-1');
  assert.ok(found, 'Pushed task should be present in sync pull');
  assert.equal(found.title, 'Automated Sync Verification Item');
  assert.ok(found.deadline, 'Deadline should be preserved in sync pull');
});

test('Field-level conflict resolution: older client update does not overwrite newer server state', async () => {
  const olderDate = new Date(Date.now() - 3600000).toISOString(); // 1 hour ago
  const newerDate = new Date().toISOString();

  // Seed server with newer task state
  memoryStore.tasks.set('conflict-task-1', {
    id: 'conflict-task-1',
    meeting_id: 'meet-past-001',
    title: 'Server Authority Title',
    status: 'Completed',
    origin_meeting_date: olderDate,
    created_at: olderDate,
    updated_at: newerDate, // Newer on server
    version: 5,
    is_deleted: false,
    device_id: 'server'
  });

  // Client attempts to push older status 'Pending'
  const stalePushPayload = {
    device_id: 'client-offline-stale',
    mutations: [
      {
        id: 'outbox-stale',
        entity_type: 'task',
        entity_id: 'conflict-task-1',
        operation: 'UPSERT',
        payload: {
          id: 'conflict-task-1',
          meeting_id: 'meet-past-001',
          title: 'Client Stale Title',
          status: 'Pending',
          origin_meeting_date: olderDate,
          created_at: olderDate,
          updated_at: olderDate, // Older than server!
          version: 2,
          is_deleted: false,
          device_id: 'client-offline-stale'
        }
      }
    ]
  };

  const pushRes = await fetch(`${baseUrl}/api/v1/sync/push`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(stalePushPayload)
  });
  assert.equal(pushRes.status, 200);
  const pushResult = await pushRes.json();
  assert.equal(pushResult.conflicts_resolved, 1, 'Server should detect and resolve conflict');

  // Verify server kept newer status 'Completed'
  const taskInDb = memoryStore.tasks.get('conflict-task-1');
  assert.equal(taskInDb.status, 'Completed', 'Server latest update should win');
});

test('POST /api/v1/devices/heartbeat and GET /api/v1/devices track connected devices', async () => {
  const hbRes = await fetch(`${baseUrl}/api/v1/devices/heartbeat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      device_id: 'win-test-99',
      device_name: 'Windows Secretariat PC',
      platform: 'Windows',
      user_name: 'Director Pendelton',
      user_role: 'Admin'
    })
  });
  assert.equal(hbRes.status, 200);
  const hbData = await hbRes.json();
  assert.ok(hbData.count >= 1);

  const listRes = await fetch(`${baseUrl}/api/v1/devices`);
  assert.equal(listRes.status, 200);
  const listData = await listRes.json();
  const dev = listData.devices.find(d => d.device_id === 'win-test-99');
  assert.ok(dev, 'Registered device should appear in connected devices list');
  assert.equal(dev.platform, 'Windows');
});

test('Admin can provision Member account, change passwords, and view Account Activities; Member cannot change passwords', async () => {
  // 1. Login as Admin
  const adminLogin = await fetch(`${baseUrl}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'admin', password: 'Admin@123' })
  });
  assert.equal(adminLogin.status, 200);
  const { token: adminToken } = await adminLogin.json();

  // 2. Admin provisions member account during enrollment
  const createRes = await fetch(`${baseUrl}/api/v1/auth/accounts`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${adminToken}` },
    body: JSON.stringify({
      email: 'member.jane@institution.gov',
      name: 'Jane Doe',
      password: 'InitPassword1',
      member_id: 'mem-jane-01'
    })
  });
  assert.equal(createRes.status, 201);

  // 3. Member can sign in with email or username
  const memberLogin = await fetch(`${baseUrl}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'member.jane', password: 'InitPassword1' })
  });
  assert.equal(memberLogin.status, 200);
  const { token: memberToken, user: memberUser } = await memberLogin.json();

  // 4. Member CANNOT view account activities or reset passwords (403 Forbidden)
  const deniedActivities = await fetch(`${baseUrl}/api/v1/account-activities`, {
    headers: { 'Authorization': `Bearer ${memberToken}` }
  });
  assert.equal(deniedActivities.status, 403);

  const deniedPwReset = await fetch(`${baseUrl}/api/v1/auth/accounts/${memberUser.id}/password`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${memberToken}` },
    body: JSON.stringify({ new_password: 'HackedPassword' })
  });
  assert.equal(deniedPwReset.status, 403);

  // 5. Admin resets Member password
  const resetRes = await fetch(`${baseUrl}/api/v1/auth/accounts/${memberUser.id}/password`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${adminToken}` },
    body: JSON.stringify({ new_password: 'UpdatedPassword2' })
  });
  assert.equal(resetRes.status, 200);

  // 6. Admin can read Account Activities
  const actRes = await fetch(`${baseUrl}/api/v1/account-activities`, {
    headers: { 'Authorization': `Bearer ${adminToken}` }
  });
  assert.equal(actRes.status, 200);
  const actData = await actRes.json();
  assert.ok(actData.activities.some(a => a.action_type === 'MEMBER_ENROLLED'));
  assert.ok(actData.activities.some(a => a.action_type === 'PASSWORD_CHANGED'));
});
