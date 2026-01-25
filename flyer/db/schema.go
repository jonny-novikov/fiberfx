// db/schema.go
// =============================================================================
// DATABASE SCHEMA - SQLite schema for FWHD deployment management
// =============================================================================
//
// Tables:
//   - packages: Built artifacts stored on Tigris S3
//   - releases: Deployable versions (tagged packages)
//   - deploy_commands: Commands to execute during deployment
//   - deployments: Audit trail of deployment actions
//   - active_versions: Current active release tracking
//
// =============================================================================

package db

// Schema contains the DDL for the packages.db database
const Schema = `
-- =============================================================================
-- FWHD DEPLOYMENT MANAGEMENT SCHEMA
-- =============================================================================
-- Litestream-compatible SQLite database for deployment orchestration
-- All IDs are branded: PKGxxxxx, RLSxxxxx, DPLxxxxx, CMDxxxxx
-- =============================================================================

-- Packages: Built artifacts stored on Tigris S3 or direct URL
CREATE TABLE IF NOT EXISTS packages (
    id          TEXT PRIMARY KEY,       -- PKGxxxxx
    name        TEXT NOT NULL,          -- @fireheadz/codemoji-backend
    version     TEXT NOT NULL,          -- 1.2.3
    tigris_key  TEXT NOT NULL UNIQUE,   -- packages/PKGxxxx.tar.gz
    direct_url  TEXT,                   -- Optional: Direct download URL (GitHub releases, etc)
    size_bytes  INTEGER NOT NULL,       -- File size
    checksum    TEXT NOT NULL,          -- sha256:xxxx
    metadata    TEXT,                   -- JSON: {build_info, commit, etc}
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_packages_name ON packages(name);
CREATE INDEX IF NOT EXISTS idx_packages_version ON packages(name, version);

-- Releases: Deployable versions (tagged packages)
CREATE TABLE IF NOT EXISTS releases (
    id          TEXT PRIMARY KEY,       -- RLSxxxxx
    package_id  TEXT NOT NULL REFERENCES packages(id),
    tag         TEXT NOT NULL,          -- v8.0.0
    status      TEXT NOT NULL DEFAULT 'draft',  -- draft|staged|active|deprecated
    notes       TEXT,                   -- Release notes (optional)
    created_at  TEXT NOT NULL DEFAULT (datetime('now')),
    staged_at   TEXT,                   -- When staged for deployment
    activated_at TEXT                   -- When marked active
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_releases_tag ON releases(tag);
CREATE INDEX IF NOT EXISTS idx_releases_status ON releases(status);
CREATE INDEX IF NOT EXISTS idx_releases_package ON releases(package_id);

-- Deploy Commands: Commands to execute during deployment
CREATE TABLE IF NOT EXISTS deploy_commands (
    id          TEXT PRIMARY KEY,       -- CMDxxxxx
    release_id  TEXT NOT NULL REFERENCES releases(id),
    phase       TEXT NOT NULL,          -- pre_deploy|post_deploy|rollback
    command     TEXT NOT NULL,          -- Shell command to run
    timeout_sec INTEGER DEFAULT 60,     -- Command timeout
    retry_count INTEGER DEFAULT 0,      -- Number of retries on failure
    run_order   INTEGER NOT NULL DEFAULT 0,  -- Execution order within phase
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_commands_release ON deploy_commands(release_id);
CREATE INDEX IF NOT EXISTS idx_commands_phase ON deploy_commands(release_id, phase);

-- Deployments: Audit trail of deployment actions
CREATE TABLE IF NOT EXISTS deployments (
    id          TEXT PRIMARY KEY,       -- DPLxxxxx
    release_id  TEXT NOT NULL REFERENCES releases(id),
    status      TEXT NOT NULL DEFAULT 'pending', -- pending|downloading|running|completed|failed|cancelled|rolled_back
    machine_id  TEXT,                   -- Fly machine ID
    trigger     TEXT NOT NULL,          -- manual|ci|watcher
    started_at  TEXT NOT NULL DEFAULT (datetime('now')),
    ended_at    TEXT,
    error       TEXT,                   -- Error message if failed
    rollback_to TEXT REFERENCES releases(id),  -- Previous release if rollback
    metadata    TEXT                    -- JSON: {logs, metrics, etc}
);

CREATE INDEX IF NOT EXISTS idx_deployments_release ON deployments(release_id);
CREATE INDEX IF NOT EXISTS idx_deployments_status ON deployments(status);
CREATE INDEX IF NOT EXISTS idx_deployments_started ON deployments(started_at DESC);

-- Active Versions: Current active release per component
CREATE TABLE IF NOT EXISTS active_versions (
    component   TEXT PRIMARY KEY,       -- 'backend', 'frontend', etc
    release_id  TEXT NOT NULL REFERENCES releases(id),
    activated_at TEXT NOT NULL DEFAULT (datetime('now')),
    activated_by TEXT                   -- Who/what activated
);

-- =============================================================================
-- VIEWS
-- =============================================================================

-- Active deployments with full context
CREATE VIEW IF NOT EXISTS v_active_deployments AS
SELECT
    d.id AS deployment_id,
    d.status AS deployment_status,
    d.machine_id,
    d.trigger,
    d.started_at,
    r.id AS release_id,
    r.tag,
    r.status AS release_status,
    p.id AS package_id,
    p.name,
    p.version,
    p.tigris_key
FROM deployments d
JOIN releases r ON d.release_id = r.id
JOIN packages p ON r.package_id = p.id
WHERE d.status IN ('pending', 'downloading', 'running');

-- Pending releases ready for deployment
CREATE VIEW IF NOT EXISTS v_pending_releases AS
SELECT
    r.id AS release_id,
    r.tag,
    r.status,
    r.created_at,
    r.staged_at,
    p.id AS package_id,
    p.name,
    p.version,
    p.tigris_key,
    p.size_bytes,
    p.checksum
FROM releases r
JOIN packages p ON r.package_id = p.id
WHERE r.status = 'staged'
ORDER BY r.staged_at DESC;

-- Deployment history with details
CREATE VIEW IF NOT EXISTS v_deployment_history AS
SELECT
    d.id AS deployment_id,
    d.status,
    d.trigger,
    d.started_at,
    d.ended_at,
    d.error,
    CASE WHEN d.ended_at IS NOT NULL
        THEN (julianday(d.ended_at) - julianday(d.started_at)) * 86400
        ELSE NULL
    END AS duration_sec,
    r.tag,
    p.name,
    p.version
FROM deployments d
JOIN releases r ON d.release_id = r.id
JOIN packages p ON r.package_id = p.id
ORDER BY d.started_at DESC;
`

// Migrations for future schema changes
var Migrations = []string{
	// Migration 1: Add indexes for performance (already in schema)
	// Migration 2: Add direct_url column for GitHub releases / direct downloads
	`ALTER TABLE packages ADD COLUMN direct_url TEXT;`,
}
