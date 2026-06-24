# syntax=docker/dockerfile:1
#
# Codemojex — custom PostgreSQL for Fly shared-cpu-2x / 2 GB.
#
# The Fly-blessed way to self-run Postgres: point at the official postgres image
# and strip the public services. The official image's entrypoint runs initdb on
# first boot, chowns the mounted Fly volume, and drops from root to the postgres
# user — so there is no perms dance and no from-source build. We only pin the
# major version and layer the tuned configuration.
#
# This is UNMANAGED Postgres: backups, a replica, and recovery are yours to own.
# Wire off-site WAL archiving (WAL-G or pgBackRest to Tigris) before real money.
#
# First boot reads these from Fly secrets (never baked into a layer):
#   fly secrets set -a codemojex-postgres \
#     POSTGRES_PASSWORD="$(openssl rand -hex 32)" POSTGRES_DB=codemojex

ARG PG_VERSION=17
FROM postgres:${PG_VERSION}

COPY postgresql.conf /etc/postgresql/postgresql.conf

# PGDATA is a subdirectory of the volume mount so initdb does not trip on the
# volume root's lost+found. The conf's data_directory points at the same path.
ENV PGDATA=/var/lib/postgresql/data/pgdata

EXPOSE 5432

CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]
