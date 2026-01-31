# Flyer Database Recreation Guide

**Purpose:** Recreate a local PostgreSQL database with initial seed data using the `flyer` CLI tool.

---

## Prerequisites

1. **PostgreSQL running** on localhost:5432
2. **Database exists:** `codemoji_game`
3. **User exists:** `codemoji_dev` with password `codemoji_password`
4. **Flyer built:** `go build -o flyer ./cmd/flyer`

### Starting PostgreSQL (macOS Homebrew)

```bash
# Check status
brew services list | grep post

# Start PostgreSQL 16
brew services start postgresql@16

# If stale PID file exists:
rm /usr/local/var/postgresql@16/postmaster.pid
pg_ctl -D /usr/local/var/postgresql@16 -l /usr/local/var/log/postgresql@16.log start
```

---

## Configuration

### flyer.conf

Create/edit `flyer.conf` in the flyer directory:

```nginx
# flyer.conf - Local database configuration

postgres {
    host       localhost;
    port       5432;
    database   codemoji_game;
    user       codemoji_dev;
    password   codemoji_password;
    export_dir /tmp/codemoji-migration;
    sql_dir    /Users/jonny/dev/fireheadz/phoenix/sql;
}
```

### Verify Configuration

```bash
./flyer config show
```

Expected output for postgres section:
```
postgres {
    host       localhost;
    port       5432;
    database   codemoji_game;
    user       codemoji_dev;
    password   ****;
    ...
}
```

---

## Recreation Steps

### Step 1: Check Branded ID Functions

Verify that the branded ID functions exist in the database:

```bash
./flyer pg functions check
```

**Expected output:**
```
Checking branded ID functions on codemoji_dev@localhost:5432/codemoji_game...
  OK  encode_base62
  OK  decode_base62
  OK  extract_snowflake_ts
  OK  format_branded_id
All 4 functions verified.
```

**If functions are missing:**
```bash
./flyer pg functions create
```

---

### Step 2: Clear Existing Data

Preview what will be truncated:
```bash
./flyer pg clear
```

Execute truncation:
```bash
./flyer pg clear --confirm
```

**Tables truncated (FK-safe order):**
1. `game_rooms`
2. `shop_packages`
3. `player_resources`
4. `players`
5. `emoji_sets`

**Expected output:**
```
Clearing migration tables on codemoji_dev@localhost:5432/codemoji_game...
  TRUNCATED  game_rooms
  TRUNCATED  shop_packages
  TRUNCATED  player_resources
  TRUNCATED  players
  TRUNCATED  emoji_sets

All 5 tables cleared. Verification:
  game_rooms:          0 rows
  shop_packages:       0 rows
  player_resources:    0 rows
  players:             0 rows
  emoji_sets:          0 rows
```

---

### Step 3: Upload Initial Data

Preview scripts to be executed:
```bash
./flyer pg data upload
```

Execute with confirmation (skip clean since already cleared):
```bash
./flyer pg data upload --confirm --skip-clean
```

**Scripts executed in order:**
| Script | Purpose |
|--------|---------|
| `00-preflight.sql` | Verify functions, tables, generated columns exist |
| `01-clean.sql` | Truncate tables (skipped if `--skip-clean`) |
| `02-import-emoji-sets.sql` | Import emoji set definitions |
| `03-import-players.sql` | Import player records with branded IDs |
| `04-transform-player-resources.sql` | Create player resource records |
| `05-import-shop-packages.sql` | Import shop package definitions |
| `06-import-game-rooms.sql` | Import game room configurations |
| `07-verify.sql` | Verify data integrity and counts |

**Expected output:**
```
Executing against codemoji_dev@localhost:5432/codemoji_game...

  [ok]  00-preflight.sql
  [ok]  01-clean.sql
  [ok]  02-import-emoji-sets.sql
  [ok]  03-import-players.sql
  [ok]  04-transform-player-resources.sql
  [ok]  05-import-shop-packages.sql
  [ok]  06-import-game-rooms.sql
  [ok]  07-verify.sql

Upload completed successfully
```

---

### Step 4: Verify Data

Check final row counts:

```bash
psql -h localhost -U codemoji_dev -d codemoji_game -c "
  SELECT 'emoji_sets' AS tbl, COUNT(*) FROM emoji_sets
  UNION ALL SELECT 'players', COUNT(*) FROM players
  UNION ALL SELECT 'player_resources', COUNT(*) FROM player_resources
  UNION ALL SELECT 'shop_packages', COUNT(*) FROM shop_packages
  UNION ALL SELECT 'game_rooms', COUNT(*) FROM game_rooms
  ORDER BY 1;
"
```

**Expected counts:**
| Table | Rows |
|-------|------|
| emoji_sets | 2 |
| game_rooms | 4 |
| player_resources | 122 |
| players | 122 |
| shop_packages | 8 |

---

## Quick Reference

### Full Recreation (One-liner)

```bash
./flyer pg functions check && \
./flyer pg clear --confirm && \
./flyer pg data upload --confirm --skip-clean
```

### Dry Run (Test without committing)

```bash
./flyer pg data dry-run
```

This wraps all scripts in `BEGIN/ROLLBACK` to test without making changes.

---

## Troubleshooting

### "PG_PASS environment variable is required"

**Cause:** flyer.conf not loaded or missing postgres password.

**Fix:** Ensure flyer.conf exists with proper postgres block including password.

### "connect: connection refused"

**Cause:** PostgreSQL not running.

**Fix:**
```bash
brew services start postgresql@16
# or
pg_ctl -D /usr/local/var/postgresql@16 start
```

### "FAIL Branded ID functions missing"

**Cause:** Functions not installed in database.

**Fix:**
```bash
./flyer pg functions create --sql-dir /path/to/phoenix/sql
```

### "cannot find initial_data directory"

**Cause:** sql_dir not configured or pointing to wrong location.

**Fix:** Update flyer.conf with correct sql_dir path:
```nginx
postgres {
    sql_dir /Users/jonny/dev/fireheadz/phoenix/sql;
}
```

---

## Related Files

| File | Purpose |
|------|---------|
| `flyer.conf` | Local configuration overrides |
| `flyer.default.conf` | Default configuration |
| `phoenix/sql/functions.sql` | Branded ID PostgreSQL functions |
| `phoenix/sql/initial_data/` | Import SQL scripts |
| `phoenix/sql/initial_schema.sql` | Full database schema |

---

## See Also

- [README.md](README.md) - Full flyer CLI documentation
- [QUICK-REFERENCE.md](QUICK-REFERENCE.md) - Command cheat sheet
- [CONFIGURATION.md](CONFIGURATION.md) - Configuration reference
