#!/usr/bin/env bash
# Step 4b — PostgreSQL (out of the box, apt), started, with the dev role the
# codemojex Repo expects (postgres/postgres over TCP on 127.0.0.1). The dev DB and
# migrations are step 7c. System of record for wallets, games, ledger, key shop.
set -uo pipefail
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"; export DEBIAN_FRONTEND=noninteractive
echo "== postgresql =="
command -v psql >/dev/null 2>&1 || $SUDO apt-get install -y -qq postgresql postgresql-client >/dev/null 2>&1
PGVER="$(ls /etc/postgresql 2>/dev/null | sort -V | tail -1)"
echo "   cluster: PostgreSQL $PGVER"
$SUDO pg_ctlcluster "$PGVER" main start 2>/dev/null || $SUDO pg_ctlcluster "$PGVER" main restart 2>/dev/null || true
sleep 2
echo "ALTER USER postgres PASSWORD 'postgres';" > /tmp/.pg_pw.sql
$SUDO su - postgres -c "psql -f /tmp/.pg_pw.sql" >/dev/null 2>&1 || true
rm -f /tmp/.pg_pw.sql
if PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres -tAc "select 1" >/dev/null 2>&1; then
  echo "   tcp auth ok (postgres/postgres @ 127.0.0.1:5432)"
else
  echo "   WARNING: postgres TCP auth not verified — check pg_hba (host all all 127.0.0.1/32 scram-sha-256)"
fi
