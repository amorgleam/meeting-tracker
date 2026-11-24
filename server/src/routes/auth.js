// ==============================================================================
// AUTHENTICATION ROUTES (src/routes/auth.js)
// Handles login, JWT token issuance, and current user profile queries.
// ==============================================================================

const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const db = require('../db');
const { signToken, verifyToken } = require('../auth');

router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'Both email and password are required for authentication.'
    });
  }

  try {
    let user = null;
    if (db.isInMemoryFallback()) {
      user = Array.from(db.memoryStore.users.values()).find(
        u => u.email.toLowerCase() === email.trim().toLowerCase() && !u.is_deleted
      );
    } else {
      const result = await db.query('SELECT * FROM users WHERE LOWER(email) = LOWER($1) AND is_deleted = FALSE;', [email.trim()]);
      user = result.rows[0];
    }

    if (!user) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid credentials. User does not exist in the institutional registry.'
      });
    }

    const passwordMatch = await bcrypt.compare(password, user.password_hash);
    if (!passwordMatch) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid credentials. Password verification failed.'
      });
    }

    const token = signToken(user);
    res.json({
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });
  } catch (err) {
    console.error('[AUTH ERROR]', err);
    res.status(500).json({ error: 'Internal Server Error', message: err.message });
  }
});

router.get('/me', verifyToken, (req, res) => {
  res.json({
    user: req.user
  });
});

module.exports = router;
