// ==============================================================================
// AUTHENTICATION & ROLE AUTHORIZATION MIDDLEWARE (src/auth.js)
// JWT token generation, verification, and role-based access control.
// ==============================================================================

const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'institutional_ultra_secure_jwt_secret_key_change_in_production_9283748293';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '30d';

function signToken(user) {
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
}

function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Formal institutional authentication token required.'
    });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid, expired, or revoked authentication credentials.'
    });
  }
}

/**
 * Role-Based Access Control (RBAC) middleware
 * e.g., requireRole(['ADMIN', 'SECRETARY'])
 */
function requireRole(allowedRoles) {
  const roles = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles];
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Unauthorized', message: 'No authentication context.' });
    }
    const userRole = (req.user.role || '').toUpperCase();
    const authorized = roles.some(r => r.toUpperCase() === userRole);

    if (!authorized) {
      return res.status(403).json({
        error: 'Forbidden',
        message: `Institutional privilege level [${roles.join(', ')}] required. User has [${userRole}].`
      });
    }
    next();
  };
}

module.exports = {
  signToken,
  verifyToken,
  requireRole
};
