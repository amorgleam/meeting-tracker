// ==============================================================================
// AUTHENTICATION & INSTITUTIONAL ACCOUNTS ROUTES (src/routes/auth.js)
// Handles login (email/username + password), JWT issuance, Admin account password
// updates, and Admin-managed Member account creation & password resets.
// ==============================================================================

const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const db = require('../db');
const { signToken, verifyToken, requireRole } = require('../auth');
const { recordAccountActivity } = require('../utils/accountActivity');

const SALT_ROUNDS = parseInt(process.env.BCRYPT_SALT_ROUNDS || '10', 10);

async function findUserByIdentifier(identifier) {
  const clean = identifier.trim().toLowerCase();
  if (db.isInMemoryFallback()) {
    return Array.from(db.memoryStore.users.values()).find(
      u => !u.is_deleted && (
        (u.email && u.email.toLowerCase() === clean) ||
        (u.username && u.username.toLowerCase() === clean)
      )
    );
  }
  const result = await db.query(
    `SELECT * FROM users
     WHERE is_deleted = FALSE
       AND (LOWER(email) = LOWER($1) OR LOWER(COALESCE(username, '')) = LOWER($1))
     LIMIT 1;`,
    [clean]
  );
  return result.rows[0] || null;
}

// POST /api/v1/auth/login - Login with email or username + password
router.post('/login', async (req, res) => {
  const { email, username, password, device_id, platform } = req.body || {};
  const identifier = (email || username || '').trim();

  if (!identifier || !password) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'Both email/username and password are required for authentication.'
    });
  }

  try {
    const user = await findUserByIdentifier(identifier);

    if (!user) {
      await recordAccountActivity({
        actorEmail: identifier,
        actorName: identifier,
        actorRole: 'UNKNOWN',
        actionType: 'LOGIN_FAILED',
        targetInfo: identifier,
        details: 'Login rejected: account not found in institutional registry.',
        deviceId: device_id || '',
        platform: platform || '',
        req,
      });
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid credentials. Account does not exist in the institutional registry.'
      });
    }

    if (user.is_active === false) {
      await recordAccountActivity({
        actorUserId: user.id,
        actorEmail: user.email,
        actorName: user.name,
        actorRole: user.role,
        actionType: 'LOGIN_FAILED',
        targetInfo: user.email,
        details: 'Login blocked: account is deactivated by Administrator.',
        deviceId: device_id || '',
        platform: platform || '',
        req,
      });
      return res.status(403).json({
        error: 'Forbidden',
        message: 'This institutional account has been deactivated by the Administrator.'
      });
    }

    const passwordMatch = await bcrypt.compare(password, user.password_hash);
    if (!passwordMatch) {
      await recordAccountActivity({
        actorUserId: user.id,
        actorEmail: user.email,
        actorName: user.name,
        actorRole: user.role,
        actionType: 'LOGIN_FAILED',
        targetInfo: user.email,
        details: 'Login rejected: incorrect password.',
        deviceId: device_id || '',
        platform: platform || '',
        req,
      });
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid credentials. Password verification failed.'
      });
    }

    const token = signToken(user);
    await recordAccountActivity({
      actorUserId: user.id,
      actorEmail: user.email,
      actorName: user.name,
      actorRole: user.role,
      actionType: 'LOGIN_SUCCESS',
      targetInfo: user.email,
      details: `${user.name} signed in via ${platform || 'Client'}.`,
      deviceId: device_id || '',
      platform: platform || '',
      req,
    });

    res.json({
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        username: user.username || user.email.split('@')[0],
        role: user.role,
        member_id: user.member_id || null,
      }
    });
  } catch (err) {
    console.error('[AUTH ERROR]', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// GET /api/v1/auth/me - Current session user profile
router.get('/me', verifyToken, (req, res) => {
  res.json({ user: req.user });
});

// GET /api/v1/auth/accounts - Admin only: list all Admin & Member accounts
router.get('/accounts', verifyToken, requireRole(['ADMIN']), async (req, res) => {
  try {
    let accounts = [];
    if (db.isInMemoryFallback()) {
      accounts = Array.from(db.memoryStore.users.values())
        .filter(u => !u.is_deleted)
        .map(({ password_hash, ...safe }) => safe);
    } else {
      const result = await db.query(
        `SELECT id, email, username, name, role, member_id, is_active, created_at, updated_at
         FROM users WHERE is_deleted = FALSE ORDER BY role ASC, name ASC;`
      );
      accounts = result.rows;
    }
    res.json({ count: accounts.length, accounts });
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// POST /api/v1/auth/accounts - Admin only: create or link Member account during enrollment
router.post('/accounts', verifyToken, requireRole(['ADMIN']), async (req, res) => {
  const { email, username, name, password, role, member_id } = req.body || {};
  const cleanEmail = (email || '').trim().toLowerCase();
  const cleanUsername = (username || (cleanEmail.includes('@') ? cleanEmail.split('@')[0] : cleanEmail)).trim().toLowerCase();

  if (!cleanEmail || !name || !password) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'Email, full name, and initial password are required to create an account.'
    });
  }

  if (String(password).length < 4) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'Password must be at least 4 characters long.'
    });
  }

  // Only permit creating Member accounts here unless explicitly managed
  const targetRole = (role && String(role).toUpperCase() === 'ADMIN') ? 'ADMIN' : 'SECRETARY';
  const now = new Date().toISOString();

  try {
    const hash = await bcrypt.hash(String(password), SALT_ROUNDS);
    let accountId = uuidv4();

    if (db.isInMemoryFallback()) {
      const existing = Array.from(db.memoryStore.users.values()).find(
        u => !u.is_deleted && ((member_id && u.member_id === member_id) || u.email.toLowerCase() === cleanEmail)
      );
      if (existing) {
        accountId = existing.id;
      }
      db.memoryStore.users.set(accountId, {
        id: accountId,
        email: cleanEmail,
        username: cleanUsername,
        password_hash: hash,
        name: name.trim(),
        role: existing ? existing.role : targetRole,
        member_id: member_id || existing?.member_id || null,
        is_active: true,
        created_at: existing?.created_at || now,
        updated_at: now,
        is_deleted: false,
      });
    } else {
      let existingRow = null;
      if (member_id) {
        const mRes = await db.query('SELECT id, role FROM users WHERE member_id = $1 AND is_deleted = FALSE LIMIT 1;', [member_id]);
        existingRow = mRes.rows[0];
      }
      if (!existingRow) {
        const eRes = await db.query('SELECT id, role FROM users WHERE LOWER(email) = LOWER($1) AND is_deleted = FALSE LIMIT 1;', [cleanEmail]);
        existingRow = eRes.rows[0];
      }

      if (existingRow) {
        accountId = existingRow.id;
        await db.query(
          `UPDATE users SET email = $1, username = $2, name = $3, password_hash = $4,
             member_id = COALESCE($5, member_id), updated_at = $6, is_active = TRUE
           WHERE id = $7;`,
          [cleanEmail, cleanUsername, name.trim(), hash, member_id || null, now, accountId]
        );
      } else {
        await db.query(
          `INSERT INTO users (id, email, username, password_hash, name, role, member_id, is_active, created_at, updated_at, is_deleted)
           VALUES ($1,$2,$3,$4,$5,$6,$7,TRUE,$8,$8,FALSE);`,
          [accountId, cleanEmail, cleanUsername, hash, name.trim(), targetRole, member_id || null, now]
        );
      }
    }

    await recordAccountActivity({
      actorUserId: req.user.id,
      actorEmail: req.user.email,
      actorName: req.user.name,
      actorRole: req.user.role,
      actionType: 'MEMBER_ENROLLED',
      targetInfo: cleanEmail,
      details: `Admin provisioned member login account for ${name.trim()} (${cleanEmail}).`,
      req,
    });

    res.status(201).json({
      status: 'ok',
      account: {
        id: accountId,
        email: cleanEmail,
        username: cleanUsername,
        name: name.trim(),
        role: targetRole,
        member_id: member_id || null,
        is_active: true,
      }
    });
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// PUT /api/v1/auth/accounts/:id/password - Admin only: change Admin or Member password
router.put('/accounts/:id/password', verifyToken, requireRole(['ADMIN']), async (req, res) => {
  const targetId = req.params.id;
  const { new_password } = req.body || {};

  if (!new_password || String(new_password).length < 4) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'new_password must be at least 4 characters long.'
    });
  }

  const now = new Date().toISOString();
  try {
    const hash = await bcrypt.hash(String(new_password), SALT_ROUNDS);
    let targetUser = null;

    if (db.isInMemoryFallback()) {
      targetUser = db.memoryStore.users.get(targetId) ||
        Array.from(db.memoryStore.users.values()).find(u => u.member_id === targetId && !u.is_deleted);
      if (!targetUser) {
        return res.status(404).json({ error: 'Not Found', message: 'Account not found.' });
      }
      targetUser.password_hash = hash;
      targetUser.updated_at = now;
    } else {
      const findRes = await db.query(
        'SELECT id, email, name, role FROM users WHERE (id = $1 OR member_id = $1) AND is_deleted = FALSE LIMIT 1;',
        [targetId]
      );
      targetUser = findRes.rows[0];
      if (!targetUser) {
        return res.status(404).json({ error: 'Not Found', message: 'Account not found.' });
      }
      await db.query(
        'UPDATE users SET password_hash = $1, updated_at = $2 WHERE id = $3;',
        [hash, now, targetUser.id]
      );
    }

    await recordAccountActivity({
      actorUserId: req.user.id,
      actorEmail: req.user.email,
      actorName: req.user.name,
      actorRole: req.user.role,
      actionType: 'PASSWORD_CHANGED',
      targetInfo: targetUser.email,
      details: `Admin updated password for ${targetUser.name} (${targetUser.email}).`,
      req,
    });

    res.json({ status: 'ok', message: `Password updated for ${targetUser.email}.` });
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

// PUT /api/v1/auth/admin-password - Admin only convenience route to update Admin password
router.put('/admin-password', verifyToken, requireRole(['ADMIN']), async (req, res) => {
  const { new_password } = req.body || {};
  if (!new_password || String(new_password).length < 4) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'new_password must be at least 4 characters long.'
    });
  }
  const now = new Date().toISOString();
  try {
    const hash = await bcrypt.hash(String(new_password), SALT_ROUNDS);
    if (db.isInMemoryFallback()) {
      const adminUser = db.memoryStore.users.get(req.user.id);
      if (adminUser) {
        adminUser.password_hash = hash;
        adminUser.updated_at = now;
      }
    } else {
      await db.query('UPDATE users SET password_hash = $1, updated_at = $2 WHERE id = $3;', [hash, now, req.user.id]);
    }

    await recordAccountActivity({
      actorUserId: req.user.id,
      actorEmail: req.user.email,
      actorName: req.user.name,
      actorRole: req.user.role,
      actionType: 'PASSWORD_CHANGED',
      targetInfo: req.user.email,
      details: `Admin updated Admin account password (${req.user.email}).`,
      req,
    });

    res.json({ status: 'ok', message: 'Administrator password updated cleanly.' });
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

module.exports = router;
