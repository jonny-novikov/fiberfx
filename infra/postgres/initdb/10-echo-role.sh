#!/usr/bin/env bash
#
# First-boot bootstrap for echo-postgres: create the per-app login role from the
# POSTGRES_ECHO_* secrets. The official postgres image runs every file in
# /docker-entrypoint-initdb.d/ exactly ONCE, on an empty data directory, as the
# postgres superuser over the local socket — so this never re-runs on an existing
# volume. To add the role to an already-initialised cluster, run the same SQL by
# hand (fly proxy + psql as the superuser).
#
# The role is the everyday application identity for the echo_* apps (echo_mesh, …)
# — NOT the superuser. It gets read/write (SELECT/INSERT/UPDATE/DELETE) on the
# application database plus CREATEDB, so the app can `mix ecto.create` and own the
# database it makes. It is deliberately not a superuser and cannot create roles.

set -Eeuo pipefail

if [[ -z "${POSTGRES_ECHO_USER:-}" || -z "${POSTGRES_ECHO_PASSWORD:-}" ]]; then
  echo "initdb/10-echo-role: POSTGRES_ECHO_USER / POSTGRES_ECHO_PASSWORD unset — skipping" >&2
  exit 0
fi

# psql performs the :var / :'var' / :"var" substitution itself, so the secret is
# passed as a bound value, never interpolated by the shell.
psql -v ON_ERROR_STOP=1 \
     --username "$POSTGRES_USER" \
     --dbname   "$POSTGRES_DB" \
     --set=echo_user="$POSTGRES_ECHO_USER" \
     --set=echo_pw="$POSTGRES_ECHO_PASSWORD" \
     --set=app_db="$POSTGRES_DB" <<-'EOSQL'
  -- read=SELECT  write=INSERT  update=UPDATE  delete=DELETE  "new db"=CREATEDB
  CREATE ROLE :"echo_user" WITH LOGIN PASSWORD :'echo_pw' CREATEDB;

  -- Full data access in the shared application database, plus the schema CREATE
  -- that Ecto migrations need; default privileges cover tables created later.
  GRANT CONNECT ON DATABASE :"app_db" TO :"echo_user";
  GRANT USAGE, CREATE ON SCHEMA public TO :"echo_user";
  GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES   IN SCHEMA public TO :"echo_user";
  GRANT USAGE, SELECT                  ON ALL SEQUENCES IN SCHEMA public TO :"echo_user";
  ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO :"echo_user";
  ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO :"echo_user";
EOSQL

echo "initdb/10-echo-role: created role '${POSTGRES_ECHO_USER}' (LOGIN, CREATEDB, RW on ${POSTGRES_DB})" >&2
