-- ==============================================================================
-- MIGRATION 002: SEED DEMO DATA AND INSTITUTIONAL ACCOUNTS
-- ==============================================================================

-- 1. Default App Settings
-- Main task completion rule: Mode A "Strict" (Default)
INSERT INTO app_settings (key, value, updated_at, updated_by)
VALUES ('completion_rule', 'ModeA_Strict', CURRENT_TIMESTAMP, 'SYSTEM_INIT')
ON CONFLICT (key) DO NOTHING;

-- 2. Seed Default Administrative & Governance Users
-- Passwords hashed with bcrypt (cost factor 10):
-- admin@institution.gov     -> Admin@123     ($2a$10$wT8Kz1H6v4Rk2b8C.a4z6.W8YfR6oZ4a9L3s2q1o0P8m9n7k5j3H.)
-- secretary@institution.gov -> Secretary@123 ($2a$10$tZ2R8v.h4k7B1s0M.e9x9.W8YfR6oZ4a9L3s2q1o0P8m9n7k5j3H.)
-- viewer@institution.gov    -> Viewer@123    ($2a$10$yA9L3s2q1o0P8m9n7k5j3.W8YfR6oZ4a9L3s2q1o0P8m9n7k5j3H.)
INSERT INTO users (id, email, password_hash, name, role, is_active, created_at, updated_at)
VALUES
('usr-admin-001', 'admin@institution.gov', '$2a$10$Gpvq1b/C8R4lVf6BfI6l0uA9oE9X0GqM5Q.Y1lB3eE0Qj2B8gXn1S', 'Director Arthur Pendelton', 'ADMIN', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('usr-sec-002', 'secretary@institution.gov', '$2a$10$Gpvq1b/C8R4lVf6BfI6l0uA9oE9X0GqM5Q.Y1lB3eE0Qj2B8gXn1S', 'Secretary Eleanor Vance', 'SECRETARY', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('usr-view-003', 'viewer@institution.gov', '$2a$10$Gpvq1b/C8R4lVf6BfI6l0uA9oE9X0GqM5Q.Y1lB3eE0Qj2B8gXn1S', 'Auditor Marcus Brody', 'VIEWER', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (email) DO NOTHING;

-- 3. Seed Institutional Members
INSERT INTO members (id, name, email, designation, is_active, created_at, updated_at, version, is_deleted, device_id)
VALUES
('mem-001', 'Arthur Pendelton', 'director@institution.gov', 'Executive Director', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 1, FALSE, 'SERVER_INIT'),
('mem-002', 'Eleanor Vance', 'secretary@institution.gov', 'General Secretary', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 1, FALSE, 'SERVER_INIT'),
('mem-003', 'Dr. Alistair Finch', 'finch@institution.gov', 'Chief Financial Officer', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 1, FALSE, 'SERVER_INIT'),
('mem-004', 'Clara Oswald', 'clara@institution.gov', 'Head of Operations', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 1, FALSE, 'SERVER_INIT'),
('mem-005', 'Gideon Cross', 'gideon@institution.gov', 'Lead Systems Architect', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 1, FALSE, 'SERVER_INIT')
ON CONFLICT (id) DO NOTHING;

-- 4. Seed Past Meeting (Convened 7 days prior)
INSERT INTO meetings (id, meeting_date, title, attendee_member_ids, status, notes, created_at, updated_at, version, is_deleted, device_id)
VALUES
('meet-past-001', CURRENT_TIMESTAMP - INTERVAL '7 days', 'Regular Directorate Council - Session XXIV', '["mem-001","mem-002","mem-003","mem-004"]'::jsonb, 'Adjourned', 'Quorum established. Annual capital expenditure docket reviewed.', CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '7 days', 1, FALSE, 'SERVER_INIT')
ON CONFLICT (id) DO NOTHING;

-- 5. Seed Tasks Originating in Past Meeting (For Carry-Forward Demonstration)
INSERT INTO tasks (id, meeting_id, parent_task_id, title, description, status, assigned_member_ids, note, origin_meeting_date, is_overridden, order_index, created_at, updated_at, version, is_deleted, device_id)
VALUES
-- Carried forward Pending Main Task
('task-cf-001', 'meet-past-001', NULL, 'Implementing a barcode scanning and inventory tracking system', 'Complete overhaul of central equipment storage ledger', 'Pending', '["mem-004","mem-005"]'::jsonb, 'Awaiting vendor RFP responses', CURRENT_TIMESTAMP - INTERVAL '7 days', FALSE, 1, CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '7 days', 1, FALSE, 'SERVER_INIT'),
-- Subtask 1 (Completed)
('task-cf-001-sub1', 'meet-past-001', 'task-cf-001', 'Draft technical specifications for handheld scanners', 'Hardware compatibility analysis', 'Completed', '["mem-005"]'::jsonb, 'Signed off by IT architecture', CURRENT_TIMESTAMP - INTERVAL '7 days', FALSE, 1, CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '7 days', 1, FALSE, 'SERVER_INIT'),
-- Subtask 2 (Pending - blocks completion in Mode A Strict)
('task-cf-001-sub2', 'meet-past-001', 'task-cf-001', 'Deploy warehouse Wi-Fi mesh relays', 'Coverage verification in storage wing B', 'Pending', '["mem-005"]'::jsonb, 'Contractors scheduled for Tuesday installation', CURRENT_TIMESTAMP - INTERVAL '7 days', FALSE, 2, CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '7 days', 1, FALSE, 'SERVER_INIT'),

-- Carried forward In Progress Main Task
('task-cf-002', 'meet-past-001', NULL, 'FY2027 Capital Budget Reconciliation', 'Reconcile Q3 discrepancies across audit ledgers', 'In Progress', '["mem-003"]'::jsonb, 'External auditor preliminary review underway', CURRENT_TIMESTAMP - INTERVAL '7 days', FALSE, 2, CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '6 days', 2, FALSE, 'SERVER_INIT')
ON CONFLICT (id) DO NOTHING;
