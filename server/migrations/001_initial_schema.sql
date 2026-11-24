-- ==============================================================================
-- MIGRATION 001: INITIAL SCHEMA FOR INSTITUTIONAL MEETING TRACKER
-- ==============================================================================

-- 1. App Governance & Settings Table
CREATE TABLE IF NOT EXISTS app_settings (
    key VARCHAR(64) PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(128)
);

-- 2. System Users (Authentication & Authorization)
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(32) NOT NULL DEFAULT 'VIEWER', -- 'ADMIN', 'SECRETARY', 'VIEWER'
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE
);

-- 3. Institutional Members (Attendees & Assignees)
CREATE TABLE IF NOT EXISTS members (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    designation VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version INTEGER NOT NULL DEFAULT 1,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    device_id VARCHAR(64) NOT NULL
);

-- 4. Meetings / Formal Sessions
CREATE TABLE IF NOT EXISTS meetings (
    id VARCHAR(64) PRIMARY KEY,
    meeting_date TIMESTAMPTZ NOT NULL,
    title VARCHAR(512),
    attendee_member_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
    status VARCHAR(32) NOT NULL DEFAULT 'In Progress', -- 'In Progress', 'Adjourned'
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version INTEGER NOT NULL DEFAULT 1,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    device_id VARCHAR(64) NOT NULL
);

-- 5. Tasks & Subtasks Docket Ledger
CREATE TABLE IF NOT EXISTS tasks (
    id VARCHAR(64) PRIMARY KEY,
    meeting_id VARCHAR(64) NOT NULL,
    parent_task_id VARCHAR(64),
    title VARCHAR(1024) NOT NULL,
    description TEXT,
    status VARCHAR(32) NOT NULL DEFAULT 'Pending', -- 'Pending', 'In Progress', 'Completed', 'Eliminated'
    assigned_member_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
    note TEXT,
    origin_meeting_date TIMESTAMPTZ NOT NULL,
    deadline TIMESTAMPTZ,
    is_overridden BOOLEAN NOT NULL DEFAULT FALSE,
    override_reason TEXT,
    override_by VARCHAR(255),
    override_at TIMESTAMPTZ,
    order_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version INTEGER NOT NULL DEFAULT 1,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    device_id VARCHAR(64) NOT NULL
);

-- 6. Comprehensive Immutable Activity & Audit Log
CREATE TABLE IF NOT EXISTS activity_logs (
    id VARCHAR(64) PRIMARY KEY,
    task_id VARCHAR(64) NOT NULL,
    meeting_id VARCHAR(64),
    task_title VARCHAR(1024) NOT NULL,
    old_state VARCHAR(64) NOT NULL,
    new_state VARCHAR(64) NOT NULL,
    user_id VARCHAR(64) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    note TEXT,
    is_override BOOLEAN NOT NULL DEFAULT FALSE,
    override_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version INTEGER NOT NULL DEFAULT 1,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    device_id VARCHAR(64) NOT NULL
);

-- 7. High-Performance Indices for Offline-Sync and Fast Querying
CREATE INDEX IF NOT EXISTS idx_tasks_meeting_id ON tasks(meeting_id);
CREATE INDEX IF NOT EXISTS idx_tasks_parent_id ON tasks(parent_task_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_updated_at ON tasks(updated_at);
CREATE INDEX IF NOT EXISTS idx_meetings_updated_at ON meetings(updated_at);
CREATE INDEX IF NOT EXISTS idx_members_updated_at ON members(updated_at);
CREATE INDEX IF NOT EXISTS idx_activity_meeting_id ON activity_logs(meeting_id);
CREATE INDEX IF NOT EXISTS idx_activity_updated_at ON activity_logs(updated_at);
