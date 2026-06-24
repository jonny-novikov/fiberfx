-- Codemojex — external login roles, scoped per database, capped.
-- Run once after first boot (psql -f, or drop into the bootstrap). The app does
-- NOT use these; it connects on 5432 over the private network as its own role.
-- These identities are for external Postgres clients and the web dashboard.
--
-- The per-role CONNECTION LIMITs sum to 20: that is the external ceiling,
-- enforced by Postgres itself regardless of how a client reaches the port.
-- Passwords are passed as psql variables so they never sit in the file:
--   psql -v app_pw="$EXT_APP_PW" -v ro_pw="$EXT_RO_PW" -f 0002-external-roles.sql

-- Read/write external identity (migrations, ops, an admin's client).
CREATE ROLE codemojex_app LOGIN PASSWORD :'app_pw' CONNECTION LIMIT 15;
-- Read-only identity (the web dashboard, analysts, a BI client).
CREATE ROLE codemojex_ro  LOGIN PASSWORD :'ro_pw'  CONNECTION LIMIT 5;

GRANT CONNECT ON DATABASE codemojex TO codemojex_app, codemojex_ro;
GRANT USAGE   ON SCHEMA  public      TO codemojex_app, codemojex_ro;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES    IN SCHEMA public TO codemojex_app;
GRANT USAGE, SELECT                  ON ALL SEQUENCES  IN SCHEMA public TO codemojex_app;
GRANT SELECT                         ON ALL TABLES    IN SCHEMA public TO codemojex_ro;

-- Cover tables created later (e.g. by app migrations) without re-granting.
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO codemojex_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO codemojex_ro;
