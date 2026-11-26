-- ==============================================================================
-- MIGRATION 003: MEMBER ACCOUNTS & ADMIN ACCOUNT ACTIVITIES AUDIT TRAIL
-- ==============================================================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(128);
ALTER TABLE users ADD COLUMN IF NOT EXISTS member_id VARCHAR(64);

CREATE INDEX IF NOT EXISTS idx_users_username ON users(LOWER(username));
CREATE INDEX IF NOT EXISTS idx_users_member_id ON users(member_id);

CREATE TABLE IF NOT EXISTS account_activities (
    id VARCHAR(64) PRIMARY KEY,
    actor_user_id VARCHAR(64),
    actor_email VARCHAR(255),
    actor_name VARCHAR(255) NOT NULL,
    actor_role VARCHAR(32) NOT NULL,
    action_type VARCHAR(64) NOT NULL,
    target_info VARCHAR(512),
    details TEXT,
    device_id VARCHAR(64),
    platform VARCHAR(64),
    ip_address VARCHAR(128),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_acc_activities_timestamp ON account_activities(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_acc_activities_actor ON account_activities(actor_email);
