# FWHD Troubleshooting

Common issues and solutions for FWHD deployments.

---

## Diagnostic Commands

### Quick Health Check

```bash
# Database state
flyer db path && ls -la $(flyer db path)

# Active deployment
flyer deploy active

# Package sync status
ls -la /app/packages/
ls -la /app/packages/current

# Litestream status
flyer stream status
```

---

## Issue: Database Not Found

**Symptoms:**
```
Error: open database: unable to open database file
```

**Causes:**
1. Database path doesn't exist
2. Litestream restore failed
3. Directory permissions

**Solutions:**

```bash
# Check path
flyer db path

# Create directory
mkdir -p /app/data

# Try restore from S3
flyer stream restore

# Initialize if new
flyer db init

# Check permissions
ls -la /app/data/
chmod 755 /app/data
```

---

## Issue: Litestream Restore Fails

**Symptoms:**
```
Error: litestream restore failed: no replica exists
```

**Causes:**
1. First deployment (no backup yet)
2. Wrong S3 credentials
3. Wrong bucket/path

**Solutions:**

```bash
# Fresh deployment - just initialize
flyer db init

# Check S3 access
aws s3 ls s3://fwhd-packages/db/ --endpoint-url https://fly.storage.tigris.dev

# Verify config
flyer config show | grep -A5 "s3 {"
flyer config show | grep -A5 "litestream {"

# Check environment
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY
```

---

## Issue: Sync Fails - No Active Version

**Symptoms:**
```
Error: get active version: no rows in result set
```

**Causes:**
1. No release activated yet
2. Wrong component name
3. Database empty

**Solutions:**

```bash
# Check active_versions table
sqlite3 /app/data/packages.db "SELECT * FROM active_versions;"

# Check releases
sqlite3 /app/data/packages.db "SELECT * FROM releases WHERE status = 'active';"

# If empty, need to create first release
flyer pkg list  # Check if packages exist
flyer release pending  # Check pending releases

# Activate a release
flyer release activate RLS0xxx
```

---

## Issue: Sync Fails - Download Error

**Symptoms:**
```
Error: download from S3: AccessDenied
```

**Causes:**
1. Invalid S3 credentials
2. Bucket doesn't exist
3. Key doesn't exist

**Solutions:**

```bash
# Check credentials
echo $AWS_ACCESS_KEY_ID | head -c 10

# List bucket
aws s3 ls s3://fwhd-packages/ --endpoint-url https://fly.storage.tigris.dev

# Check specific key
aws s3 ls s3://fwhd-packages/packages/backend-1.0.0.tar.gz \
  --endpoint-url https://fly.storage.tigris.dev

# Verify package record
flyer pkg get PKG0xxx
```

---

## Issue: Workers Not Starting

**Symptoms:**
- Workers crash on start
- Health checks fail
- No `/api/v2` responses

**Causes:**
1. Entry point missing
2. Node.js version mismatch
3. Missing dependencies
4. Port conflicts

**Solutions:**

```bash
# Check entry point
ls -la /app/packages/current/dist/index.js

# Check symlink
ls -la /app/packages/current

# Try running manually
cd /app/packages/current
node dist/index.js

# Check Node version
node --version

# Check for missing modules
npm ls --production

# Check port usage
lsof -i :3001
```

---

## Issue: Deployment Stuck in Pending

**Symptoms:**
```
flyer deploy active
# Shows status: pending for long time
```

**Causes:**
1. DistrWatcher not running
2. Litestream sync delay
3. Echo not started

**Solutions:**

```bash
# Check Echo logs for DistrWatcher
grep DistrWatcher /var/log/echo.log

# Force Litestream sync
litestream replicate -config /app/litestream.yml &

# Check if database is being replicated
flyer stream status

# Manual deployment start
flyer deploy start --release RLS0xxx --trigger manual
```

---

## Issue: Rollback Not Working

**Symptoms:**
- Activated previous release
- Workers still running old version

**Causes:**
1. Symlink not updated
2. Workers not restarted
3. Wrong release activated

**Solutions:**

```bash
# Verify active version
sqlite3 /app/data/packages.db "SELECT * FROM active_versions;"

# Check symlink
ls -la /app/packages/current

# Force update symlink
ln -sfn /app/packages/v8.0.0 /app/packages/current

# Verify entry point
ls -la /app/packages/current/dist/index.js

# Restart workers (via Echo)
# Check Echo supervisor commands
```

---

## Issue: Litestream Not Replicating

**Symptoms:**
- Database changes not appearing on other machines
- `flyer stream status` shows stale data

**Causes:**
1. Litestream process not running
2. S3 write errors
3. WAL not being checkpointed

**Solutions:**

```bash
# Check if Litestream is running
pgrep -a litestream

# Start if not running
flyer stream replicate &

# Check Litestream logs
litestream replicate -config /app/litestream.yml 2>&1 | tail -50

# Force WAL checkpoint
sqlite3 /app/data/packages.db "PRAGMA wal_checkpoint(TRUNCATE);"

# Check S3 for recent uploads
aws s3 ls s3://fwhd-packages/db/packages/ \
  --endpoint-url https://fly.storage.tigris.dev \
  | tail -5
```

---

## Issue: Config Not Loading

**Symptoms:**
```
Using default values instead of configured
```

**Causes:**
1. Config file not found
2. Syntax error in config
3. Wrong `--config` path

**Solutions:**

```bash
# Check current config
flyer config show

# Verify file exists
ls -la flyer.conf flyer.default.conf

# Check config search paths
# 1. --config flag
# 2. /app/
# 3. /etc/flyer/
# 4. ./

# Validate syntax (look for errors)
cat flyer.conf

# Generate fresh default
flyer config init --output /tmp/
diff flyer.conf /tmp/flyer.conf
```

---

## Issue: Branded ID Parse Error

**Symptoms:**
```
Error: invalid branded ID: XYZ123
```

**Causes:**
1. Wrong ID format
2. Invalid namespace
3. Wrong character count (must be 14)

**Solutions:**

```bash
# Validate ID format
flyer id parse PKG0KM3abc123xy

# Check valid namespaces
flyer id list

# Generate correct ID
flyer id new PKG
```

---

## Common Environment Issues

### Missing Environment Variables

```bash
# Check required vars
env | grep AWS
env | grep PG_

# Set in shell
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx

# Or use .env file
flyer pg --env .env.staging functions check
```

### Wrong Database Path

```bash
# Check configured path
flyer db path

# Override with flag
flyer --db /custom/path/packages.db db init
```

### S3 Endpoint Issues

```bash
# Verify Tigris endpoint
curl -I https://fly.storage.tigris.dev/health

# Check bucket access
aws s3 ls s3://fwhd-packages/ \
  --endpoint-url https://fly.storage.tigris.dev
```

---

## Debug Mode

Enable verbose output:

```bash
# Global verbose flag (if supported)
flyer --verbose sync

# Check Go debug output
GODEBUG=http2debug=2 flyer sync
```

---

## Log Locations

| Component | Log Location |
|-----------|--------------|
| Flyer | stdout/stderr |
| Litestream | stdout/stderr |
| Echo | `/var/log/echo.log` |
| Workers | `/var/log/worker-*.log` |

---

## Getting Help

1. Check this guide first
2. Review [Concepts](01-concepts.md) for understanding
3. Check [Workflows](03-workflows.md) for correct procedures
4. Search related tasks in `dev/tasks/`
5. Check FWHD plan: PLN0KIoZj7TQXK
