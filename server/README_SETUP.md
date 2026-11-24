# ==============================================================================
# MEETING TRACKER: PRODUCTION SERVER & HOSTING SETUP GUIDE
# Infrastructure: Render.com (Web Service + Managed PostgreSQL) + Cloudflare (Edge/SSL/DNS)
# ==============================================================================

This document provides definitive, step-by-step instructions for deploying the **Meeting Tracker** backend to **Render.com** and routing traffic securely through **Cloudflare** with end-to-end encryption, WebSocket realtime sync, and automated database backups.

---

## TABLE OF CONTENTS
1. [Architecture Overview](#1-architecture-overview)
2. [Prerequisites](#2-prerequisites)
3. [Step 1: Deploy to Render via Blueprint (render.yaml)](#3-step-1-deploy-to-render-via-blueprint)
4. [Step 2: Configure Cloudflare DNS & SSL/TLS](#4-step-2-configure-cloudflare-dns--ssltls)
5. [Step 3: Enable and Configure WebSockets on Cloudflare](#5-step-3-enable-and-configure-websockets-on-cloudflare)
6. [Step 4: Verify Deployment and Health Check](#6-step-4-verify-deployment-and-health-check)
7. [Step 5: Automated Backup Recommendation](#7-step-5-automated-backup-recommendation)
8. [Environment Variable Reference](#8-environment-variable-reference)
9. [Troubleshooting & FAQs](#9-troubleshooting--faqs)

---

## 1. ARCHITECTURE OVERVIEW

```
+-----------------------------------------------------------------------------------+
| CLIENTS (Windows Desktop App, Android Mobile APK, Browser Web App)               |
+-----------------------------------------------------------------------------------+
                                  | HTTPS / WSS
                                  v
+-----------------------------------------------------------------------------------+
| CLOUDFLARE EDGE (DNS, DDoS Protection, SSL Offloading, WebSockets Proxy)         |
| Domain: e.g., tracker.your-institution.gov                                        |
| SSL Mode: Full (Strict)                                                           |
+-----------------------------------------------------------------------------------+
                                  | HTTPS / WSS (Proxy Pass)
                                  v
+-----------------------------------------------------------------------------------+
| RENDER WEB SERVICE (Node.js 20+ Express + ws Server)                              |
| Internal Service: meeting-tracker-api.onrender.com                                 |
| Port: 10000 (auto-injected)                                                       |
| Endpoints: REST API (/api/v1/*), OpenAPI Spec, WebSockets (/ws)                   |
+-----------------------------------------------------------------------------------+
                                  | Private Virtual Network (Zero Latency / No Egress)
                                  v
+-----------------------------------------------------------------------------------+
| RENDER MANAGED POSTGRESQL (PostgreSQL 16)                                         |
| Service: meeting-tracker-db                                                       |
| Automated Daily Snapshots + Point-in-time Recovery                                |
+-----------------------------------------------------------------------------------+
```

---

## 2. PREREQUISITES

Before beginning, ensure you have:
1. A **GitHub** or **GitLab** account containing the `meeting_tracker` repository.
2. A free or team account on **[Render.com](https://render.com)**.
3. A domain managed on **[Cloudflare.com](https://cloudflare.com)** (e.g. `your-institution.gov`).
4. Administrative rights to add DNS records on Cloudflare.

---

## 3. STEP 1: DEPLOY TO RENDER VIA BLUEPRINT

The repository contains a fully automated `render.yaml` infrastructure-as-code file.

### Option A: 1-Click Blueprint Deploy (Recommended)
1. Log in to your **Render Dashboard** (`https://dashboard.render.com`).
2. Click the **"New +"** button in the top navigation and select **"Blueprint"**.
3. Connect your Git repository (`meeting_tracker`).
4. Render will parse `render.yaml` and display the resources it is about to create:
   - **`meeting-tracker-db`**: Managed PostgreSQL Database.
   - **`meeting-tracker-api`**: Node.js Web Service.
5. Review the plan options (Starter plan recommended for persistent WebSocket connections).
6. Click **"Apply"**.
7. Render will automatically:
   - Provision the PostgreSQL database.
   - Build the Node.js application (`npm install`).
   - Run database migrations (`npm run migrate`).
   - Seed default institutional users and initial docket (`npm run seed`).
   - Launch the web server on internal port 10000.
8. Note your public Render service URL: `https://meeting-tracker-api-xxxx.onrender.com`.

### Option B: Manual Setup on Render
If you prefer manual service creation:
1. **Create PostgreSQL Database**:
   - Go to **New +** > **PostgreSQL**.
   - Name: `meeting-tracker-db`.
   - Database: `meeting_tracker`.
   - User: `tracker_admin`.
   - Click **Create Database**.
   - Copy the **Internal Database URL** (`postgresql://tracker_admin:...@dpg-xxx-a/meeting_tracker`).
2. **Create Web Service**:
   - Go to **New +** > **Web Service**.
   - Root Directory: `server`.
   - Runtime: `Node`.
   - Build Command: `npm install && npm run migrate && npm run seed`.
   - Start Command: `npm start`.
   - Health Check Path: `/api/v1/health`.
   - Under **Environment Variables**, add:
     - `DATABASE_URL`: (Paste the Internal Database URL)
     - `JWT_SECRET`: (Generate a 64-character random string)
     - `NODE_ENV`: `production`
     - `CORS_ORIGIN`: `*`
     - `DEFAULT_COMPLETION_RULE`: `ModeA_Strict`

---

## 4. STEP 2: CONFIGURE CLOUDFLARE DNS & SSL/TLS

To use a professional institutional custom domain (such as `tracker.your-institution.gov` or `meetings.yourdomain.com`):

### 1. Add Custom Domain in Render
1. Open your `meeting-tracker-api` web service in the Render Dashboard.
2. Navigate to **Settings** > **Custom Domains**.
3. Click **Add Custom Domain** and enter your desired subdomain:
   - Example: `tracker.your-institution.gov`
4. Render will display the verification target: `meeting-tracker-api-xxxx.onrender.com`.

### 2. Add DNS Record in Cloudflare
1. Log in to your **Cloudflare Dashboard** and select your domain zone.
2. Go to **DNS** > **Records** > **Add Record**.
3. Configure the record:
   - **Type**: `CNAME`
   - **Name**: `tracker` (or your chosen subdomain)
   - **Target**: `meeting-tracker-api-xxxx.onrender.com` (your Render service URL)
   - **Proxy status**: `Proxied` (Orange Cloud icon enabled)
   - **TTL**: `Auto`
4. Click **Save**.

### 3. Configure SSL/TLS Encryption Mode
1. In Cloudflare, navigate to **SSL/TLS** > **Overview**.
2. Set the encryption mode to:
   - **`Full (strict)`** (Recommended)
   *(Render provisions an automatic Let's Encrypt certificate on its edge. "Full (strict)" validates this certificate and guarantees end-to-end encryption from the browser to Render).*
3. Under **SSL/TLS** > **Edge Certificates**:
   - Enable **Always Use HTTPS**: `ON`
   - Enable **Automatic HTTPS Rewrites**: `ON`
   - Minimum TLS Version: `TLS 1.2` or `TLS 1.3`
   - Enable **HTTP/2** and **HTTP/3 (with QUIC)**: `ON`

---

## 5. STEP 3: ENABLE AND CONFIGURE WEBSOCKETS ON CLOUDFLARE

The Meeting Tracker uses WebSockets (`/ws`) for instantaneous sync broadcasting across all connected desktop and mobile devices.

### 1. Verify Cloudflare WebSockets Setting
1. In Cloudflare Dashboard, go to **Network**.
2. Find the **WebSockets** toggle.
3. Confirm that **WebSockets is ON**.
   *(WebSockets is enabled by default on all Cloudflare accounts with no additional cost).*

### 2. Handling Connection Timeouts (Heartbeat)
- **Cloudflare Policy**: Cloudflare will terminate idle WebSocket connections after **100 seconds** of inactivity.
- **Meeting Tracker Solution**: The server includes an automated WebSocket heartbeat ping every **30 seconds** (`WS_HEARTBEAT_INTERVAL_MS=30000`).
- If you notice unexpected disconnects behind strict corporate proxies, configure Cloudflare **WAF (Web Application Firewall)** to ensure requests with the `Upgrade: websocket` header are exempt from challenge interstitials.

---

## 6. STEP 4: VERIFY DEPLOYMENT AND HEALTH CHECK

Once deployment completes and DNS has propagated (typically 1 to 5 minutes):

### 1. Verify REST API Health Endpoint
Open in your browser or run in terminal:
```bash
curl -i https://tracker.your-institution.gov/api/v1/health
```
Expected JSON Response:
```json
{
  "status": "healthy",
  "service": "meeting-tracker-server",
  "version": "1.0.0",
  "timestamp": "2026-11-24T12:00:00.000Z",
  "database": {
    "status": "connected",
    "latency_ms": 1.4
  },
  "websockets": {
    "active_clients": 0
  }
}
```

### 2. Verify OpenAPI Documentation
Navigate to:
```
https://tracker.your-institution.gov/api/docs
```
You will see the interactive OpenAPI documentation detailing all endpoints, schemas, and sync contracts.

### 3. Verify Default Institutional Accounts
Log in via `POST /api/v1/auth/login`:
| Role | Email | Password | Privileges |
|---|---|---|---|
| **Admin** | `admin@institution.gov` | `Admin@123` | Full control, Executive Override, Change Rules |
| **Secretary** | `secretary@institution.gov` | `Secretary@123` | Session management, Executive Override |
| **Viewer** | `viewer@institution.gov` | `Viewer@123` | View-only audit, reports, and ledger export |

---

## 7. STEP 5: AUTOMATED BACKUP RECOMMENDATION

Meeting Tracker maintains institutional records, audit logs, and legal session minutes. Regular database backups are essential.

### 1. Render Automated Daily Snapshots (Tier 1)
- When using the `starter` or higher PostgreSQL plan on Render, Render takes **automated daily snapshots** retained for 7 days (or 30 days on Pro plans).
- To restore a snapshot:
  1. Go to **Dashboard** > `meeting-tracker-db` > **Backups**.
  2. Select the desired recovery snapshot and click **Restore**.

### 2. Automated Offsite Backup via GitHub Actions Cron (Tier 2 - Recommended)
To maintain an independent offsite copy in case of provider outages or disaster recovery:
1. Create a private GitHub repository or AWS S3 bucket for institutional archives.
2. Set up a GitHub Action running a nightly cron job:
```yaml
name: Nightly Database Backup
on:
  schedule:
    - cron: '0 2 * * *' # 2:00 AM UTC daily
  workflow_dispatch:

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - name: Install PostgreSQL Client
        run: sudo apt-get update && sudo apt-get install -y postgresql-client
      - name: Dump PostgreSQL Database
        run: |
          pg_dump "${{ secrets.RENDER_EXTERNAL_DB_URL }}" -F c -b -v -f "meeting_tracker_$(date +%Y%m%d_%H%M%S).dump"
      - name: Upload to Secure Cold Storage / S3 / Artifacts
        # Store in encrypted S3 bucket or GitHub Actions Encrypted Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: db-backup-${{ github.run_id }}
          path: "*.dump"
          retention-days: 90
```

### 3. Manual On-Demand Backup
Run from any administrative terminal with `pg_dump`:
```bash
pg_dump "postgresql://tracker_admin:password@dpg-xxx-a.oregon-postgres.render.com/meeting_tracker?sslmode=require" -F c -b -v -f backup_$(date +%Y%m%d).dump
```

To restore from a dump:
```bash
pg_restore -d "DATABASE_URL" -c -v backup_file.dump
```

---

## 8. ENVIRONMENT VARIABLE REFERENCE

| Variable | Required | Default | Description |
|---|---|---|---|
| `PORT` | No | `3000` (Render sets `10000`) | Network port for HTTP & WebSocket server |
| `NODE_ENV` | Yes | `production` | Environment mode (`production`, `development`) |
| `DATABASE_URL` | Yes | N/A | PostgreSQL connection string |
| `JWT_SECRET` | Yes | (Generated) | Secret key for signing authorization tokens |
| `JWT_EXPIRES_IN` | No | `30d` | JWT session lifetime token string |
| `BCRYPT_SALT_ROUNDS`| No | `10` | Salt work factor for password hashing |
| `CORS_ORIGIN` | No | `*` | Allowed origins (set to domain in locked setups) |
| `WS_HEARTBEAT_INTERVAL_MS` | No | `30000` | Keep-alive ping interval for Cloudflare proxy |
| `DEFAULT_COMPLETION_RULE` | No | `ModeA_Strict` | Institutional rule: `ModeA_Strict` or `ModeB_Relaxed` |

---

## 9. TROUBLESHOOTING & FAQS

### Q: Why do WebSocket connections drop after 100 seconds?
**Cause**: Cloudflare terminates idle HTTP and WebSocket connections after 100 seconds if no traffic flows.  
**Fix**: Verify that `WS_HEARTBEAT_INTERVAL_MS` is set to `30000` (30 seconds). The server automatically sends ping frames every 30 seconds to keep the Cloudflare tunnel active.

### Q: Cloudflare shows "Error 525: SSL Handshake Failed"
**Cause**: The SSL encryption mode on Cloudflare is set to "Full (Strict)", but Render's custom domain SSL certificate hasn't finished provisioning yet.  
**Fix**: Temporarily switch Cloudflare SSL to **"Full"** for 5 minutes until Render finishes issuing its edge certificate, then switch back to **"Full (strict)"**.

### Q: How do I change the global completion rule?
**Option 1**: In the Meeting Tracker Flutter app, navigate to **Admin Settings** (signed in as Admin or Secretary) and select **Mode A (Strict)** or **Mode B (Relaxed)**. The app calls `PUT /api/v1/settings`, updates PostgreSQL, and broadcasts the change via WebSocket to all devices.  
**Option 2**: Run SQL: `UPDATE app_settings SET value = 'ModeB_Relaxed', updated_at = CURRENT_TIMESTAMP WHERE key = 'completion_rule';`
