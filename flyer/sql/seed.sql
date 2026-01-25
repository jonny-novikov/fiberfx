-- FWHD v3 Bootstrap Seed Data
-- This creates the initial package/release/active_version records
-- Tarball is already uploaded to Tigris S3

-- Package: @fireheadz/codemoji-backend v4.1.0
INSERT OR REPLACE INTO packages (id, name, version, tigris_key, size_bytes, checksum, created_at)
VALUES (
    'PKG0KDrlSvSq7E',
    '@fireheadz/codemoji-backend',
    '4.1.0',
    'packages/backend-v4.1.0-20260125-140131.tar.gz',
    399802,
    'sha256:1c2723d7534777af05f5aea72d65e5227c20c081a76a1908f028d70ae7dd8109',
    '2026-01-25T14:02:13+03:00'
);

-- Release: v4.1.0 (active)
INSERT OR REPLACE INTO releases (id, package_id, tag, status, notes, created_at, staged_at, activated_at)
VALUES (
    'RLS0KDrnAJBg8G',
    'PKG0KDrlSvSq7E',
    'v4.1.0',
    'active',
    'Initial FWHD v3 bootstrap release',
    '2026-01-25T14:02:36+03:00',
    '2026-01-25T11:02:53',
    '2026-01-25T11:02:53'
);

-- Active version: backend → v4.1.0 release
INSERT OR REPLACE INTO active_versions (component, release_id, activated_at, activated_by)
VALUES (
    'backend',
    'RLS0KDrnAJBg8G',
    '2026-01-25T11:03:20',
    'docker-build-bootstrap'
);
