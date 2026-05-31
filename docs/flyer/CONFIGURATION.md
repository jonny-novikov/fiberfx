# Flyer Configuration Reference

Complete reference for `flyer.conf` configuration.

---

## Configuration Files

### File Locations

| File | Purpose | Required |
|------|---------|----------|
| `flyer.default.conf` | Default values | Yes (ships with tool) |
| `flyer.conf` | User overrides | No |

### Search Order

When loading configuration, flyer searches:

1. `--config <dir>` flag (if specified)
2. `/app/` directory
3. `/etc/flyer/` directory
4. Current working directory

### Override Behavior

Configuration is merged in order:
1. Built-in defaults
2. `flyer.default.conf`
3. `flyer.conf` (overrides only changed values)

---

## Syntax

### Basic Directives

```nginx
# Simple directive
directive_name value;

# Quoted values (for paths with spaces)
path "/path/with spaces/file.db";
```

### Blocks

```nginx
block_name {
    directive1 value1;
    directive2 value2;
}
```

### Comments

```nginx
# This is a comment
directive value;  # Inline comments NOT supported
```

### Environment Variables

Two syntaxes supported:

```nginx
# env: prefix (preferred)
password env:MY_SECRET_VAR;

# Shell-style ${VAR}
path ${HOME}/data/app.db;
```

---

## Configuration Blocks

### `database` - SQLite Database

SQLite database for FWHD deployment tracking.

```nginx
database {
    path /app/data/packages.db;
}
```

| Directive | Default | Description |
|-----------|---------|-------------|
| `path` | `/app/data/packages.db` | Path to SQLite database file |

### `s3` - S3/Tigris Storage

Object storage for packages and database replicas.

```nginx
s3 {
    endpoint   https://fly.storage.tigris.dev;
    bucket     fwhd-packages;
    region     auto;
    access_key env:AWS_ACCESS_KEY_ID;
    secret_key env:AWS_SECRET_ACCESS_KEY;
}
```

| Directive | Default | Description |
|-----------|---------|-------------|
| `endpoint` | `https://fly.storage.tigris.dev` | S3-compatible endpoint URL |
| `bucket` | `fwhd-packages` | Bucket name |
| `region` | `auto` | AWS region |
| `access_key` | `env:AWS_ACCESS_KEY_ID` | Access key (use env: for security) |
| `secret_key` | `env:AWS_SECRET_ACCESS_KEY` | Secret key (use env: for security) |

### `litestream` - Replication Settings

Litestream SQLite replication to S3.

```nginx
litestream {
    config_path              /app/litestream.yml;
    retention_days           7;
    s3_path                  db/packages;
    sync_interval            10s;
    snapshot_interval        1h;
    retention                72h;
    retention_check_interval 1h;
    validation_interval      1h;
}
```

| Directive | Default | Description |
|-----------|---------|-------------|
| `config_path` | `/app/litestream.yml` | Path to generated litestream.yml |
| `retention_days` | `7` | Days to retain replicas |
| `s3_path` | `db/packages` | S3 prefix for replicas |
| `sync_interval` | `10s` | WAL sync frequency |
| `snapshot_interval` | `1h` | Full snapshot frequency |
| `retention` | `72h` | Replica retention period |
| `retention_check_interval` | `1h` | Cleanup check frequency |
| `validation_interval` | `1h` | Replica validation frequency |

### `packages` - Package Storage

Local package storage settings.

```nginx
packages {
    dir         /app/packages;
    entry_point dist/index.js;
}
```

| Directive | Default | Description |
|-----------|---------|-------------|
| `dir` | `/app/packages` | Local packages directory |
| `entry_point` | `dist/index.js` | Application entry point |

### `sync` - Sync Settings

Package synchronization settings.

```nginx
sync {
    component backend;
    timeout   60;
}
```

| Directive | Default | Description |
|-----------|---------|-------------|
| `component` | `backend` | Component name to sync |
| `timeout` | `60` | Download timeout in seconds |

### `postgres` - PostgreSQL Settings

PostgreSQL connection for `pg` commands.

```nginx
postgres {
    host       localhost;
    port       25432;
    database   codemoji_game;
    user       fireheadz_studio;
    password   env:PG_PASS;
    export_dir /tmp/codemoji-migration;
    sql_dir    /Users/jonny/dev/fireheadz/phoenix/sql;
}
```

| Directive | Default | Description |
|-----------|---------|-------------|
| `host` | `localhost` | PostgreSQL host |
| `port` | `25432` | PostgreSQL port |
| `database` | `codemoji_game` | Database name |
| `user` | `fireheadz_studio` | Database user |
| `password` | `env:PG_PASS` | Database password (use env: for security) |
| `export_dir` | `/tmp/codemoji-migration` | CSV export directory |
| `sql_dir` | (auto-detected) | Path to phoenix/sql directory |

---

## Example Configurations

### Development (Local)

```nginx
# flyer.conf - Development overrides

database {
    path ./data/packages.db;
}

s3 {
    endpoint http://localhost:9000;
    bucket   dev-packages;
    access_key minioadmin;
    secret_key minioadmin;
}

postgres {
    host     localhost;
    port     5432;
    database codemoji_dev;
    user     postgres;
    password env:PGPASSWORD;
    sql_dir  /Users/jonny/dev/fireheadz/phoenix/sql;
}
```

### Staging (Fly.io)

```nginx
# flyer.conf - Staging overrides

postgres {
    host     codemoji-postgres.flycast;
    port     5432;
    database codemoji_game;
    user     fireheadz_studio;
    password env:PG_PASS;
}

packages {
    dir /app/packages;
}
```

### Production (Fly.io)

```nginx
# flyer.conf - Production overrides

database {
    path /data/packages.db;
}

s3 {
    bucket   prod-fwhd-packages;
}

litestream {
    retention_days 30;
    retention      168h;
}

postgres {
    host     codemoji-postgres.internal;
    port     5432;
    database codemoji_prod;
    password env:PG_PASS;
}
```

---

## Troubleshooting

### View Current Configuration

```bash
flyer config show
```

### Generate Default Files

```bash
flyer config init --output .
```

### Override Config Location

```bash
flyer --config /etc/flyer config show
```

### Debug Environment Variable Resolution

If `env:VAR` isn't resolving:

1. Check the variable is exported: `echo $VAR`
2. Check flyer can see it: `flyer config show`
3. Try explicit path: `PG_PASS=secret flyer pg functions check`

---

## Migration from Environment-Only

If upgrading from env-only configuration:

**Before (environment only):**
```bash
export PG_HOST=localhost
export PG_PORT=5432
export PG_NAME=mydb
export PG_USER=myuser
export PG_PASS=secret
flyer pg functions check
```

**After (flyer.conf):**
```nginx
postgres {
    host     localhost;
    port     5432;
    database mydb;
    user     myuser;
    password env:PG_PASS;  # Still secure!
}
```

```bash
export PG_PASS=secret
flyer pg functions check
```

Both approaches work - flyer.conf takes precedence when present.
