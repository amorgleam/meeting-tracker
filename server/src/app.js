// ==============================================================================
// EXPRESS APP CONFIGURATION (src/app.js)
// Security headers (Helmet), CORS, JSON body parsers, and API v1 routing.
// ==============================================================================

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const fs = require('fs');

const healthRoutes = require('./routes/health');
const authRoutes = require('./routes/auth');
const settingsRoutes = require('./routes/settings');
const syncRoutes = require('./routes/sync');
const meetingsRoutes = require('./routes/meetings');
const tasksRoutes = require('./routes/tasks');
const membersRoutes = require('./routes/members');

const app = express();

// Security Middleware
app.use(helmet({
  contentSecurityPolicy: false // Allow swagger and api previews
}));

// CORS Configuration
const allowedOrigin = process.env.CORS_ORIGIN || '*';
app.use(cors({
  origin: allowedOrigin === '*' ? '*' : allowedOrigin.split(','),
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Device-Id']
}));

// Body Parsers
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request Logger (Development & Diagnostics)
app.use((req, res, next) => {
  if (process.env.NODE_ENV !== 'test') {
    const start = Date.now();
    res.on('finish', () => {
      console.log(`[HTTP] ${req.method} ${req.originalUrl} -> ${res.statusCode} (${Date.now() - start}ms)`);
    });
  }
  next();
});

// OpenAPI Spec Raw Endpoint
app.get('/api/docs/openapi.yaml', (req, res) => {
  const specPath = path.join(__dirname, '..', 'openapi.yaml');
  if (fs.existsSync(specPath)) {
    res.setHeader('Content-Type', 'text/yaml');
    fs.createReadStream(specPath).pipe(res);
  } else {
    res.status(404).send('OpenAPI specification file not found');
  }
});

// Interactive API Docs Landing Page
app.get('/api/docs', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8" />
      <title>Meeting Tracker API Documentation</title>
      <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css" />
    </head>
    <body style="margin: 0; background-color: #FAF7F0;">
      <div id="swagger-ui"></div>
      <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
      <script>
        SwaggerUIBundle({
          url: '/api/docs/openapi.yaml',
          dom_id: '#swagger-ui',
          presets: [SwaggerUIBundle.presets.apis],
          layout: 'BaseLayout'
        });
      </script>
    </body>
    </html>
  `);
});

// API v1 Route Mounts
app.use('/api/v1/health', healthRoutes);
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/settings', settingsRoutes);
app.use('/api/v1/sync', syncRoutes);
app.use('/api/v1/meetings', meetingsRoutes);
app.use('/api/v1/tasks', tasksRoutes);
app.use('/api/v1/members', membersRoutes);

// Root route redirect to docs or health
app.get('/', (req, res) => {
  res.json({
    name: 'Institutional Meeting Tracker API Gateway',
    version: '1.0.0',
    documentation: '/api/docs',
    health: '/api/v1/health',
    websocket: '/ws'
  });
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `The requested endpoint ${req.method} ${req.path} does not exist.`
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('[UNHANDLED SERVER EXCEPTION]', err);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'production' ? 'An unexpected server error occurred.' : err.message
  });
});

module.exports = app;
