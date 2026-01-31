# FWHD Workflows

Common workflows for FWHD deployment operations.

---

## Workflow 1: Initial Setup

Set up FWHD on a new machine.

### 1.1 Build Flyer

```bash
cd phoenix/tools/flyer
go build -ldflags "-X main.version=1.0.0" -o flyer ./cmd/flyer
```

### 1.2 Create Configuration

```bash
./flyer config init
```

Edit `flyer.conf`:

```nginx
database {
    path /app/data/packages.db;
}

s3 {
    endpoint   https://fly.storage.tigris.dev;
    bucket     fwhd-packages;
    access_key env:AWS_ACCESS_KEY_ID;
    secret_key env:AWS_SECRET_ACCESS_KEY;
}

packages {
    dir         /app/packages;
    entry_point dist/index.js;
}

sync {
    component backend;
    timeout   60;
}
```

### 1.3 Initialize Database

```bash
./flyer db init
```

### 1.4 Generate Litestream Config

```bash
./flyer stream generate
```

---

## Workflow 2: CI/CD Release

Deploy a new version through CI/CD.

### 2.1 Build and Upload Package

```bash
# In CI pipeline
npm run build
tar -czf backend-${VERSION}.tar.gz dist/ node_modules/ package.json

# Upload to Tigris
aws s3 cp backend-${VERSION}.tar.gz s3://fwhd-packages/packages/ \
  --endpoint-url https://fly.storage.tigris.dev

# Get checksum and size
CHECKSUM=$(sha256sum backend-${VERSION}.tar.gz | cut -d' ' -f1)
SIZE=$(stat -c%s backend-${VERSION}.tar.gz)
```

### 2.2 Create Package Record

```bash
flyer pkg create \
  --name "@fireheadz/codemoji-backend" \
  --version "${VERSION}" \
  --key "packages/backend-${VERSION}.tar.gz" \
  --checksum "sha256:${CHECKSUM}" \
  --size ${SIZE}
```

### 2.3 Create and Activate Release

```bash
# Get package ID from previous command output
PKG_ID="PKG0KM3abc123xy"

# Create release
flyer release create --package ${PKG_ID} --tag v${VERSION}

# Get release ID
RLS_ID="RLS0KM3def456yz"

# Stage and activate
flyer release stage ${RLS_ID}
flyer release activate ${RLS_ID}
```

### 2.4 Verify Deployment

```bash
# Check active deployment
flyer deploy active

# Check release status
flyer release pending  # Should be empty after activation
```

---

## Workflow 3: Machine Startup

Startup sequence for Fly.io machines.

### start.sh

```bash
#!/bin/bash
set -e

echo "=== FWHD Startup ==="

# 1. Restore database from S3 (if not exists)
echo "Restoring database..."
flyer stream restore --if-not-exists

# 2. Initialize schema (idempotent)
echo "Initializing database..."
flyer db init

# 3. Generate Litestream config
echo "Generating Litestream config..."
flyer stream generate

# 4. Sync packages from S3
echo "Syncing packages..."
flyer sync --component backend

# 5. Start Litestream replication in background
echo "Starting Litestream..."
flyer stream replicate &

# 6. Start main application
echo "Starting Phoenix Echo..."
exec /app/bin/echo start
```

### Dockerfile

```dockerfile
FROM elixir:1.15-alpine

# Install flyer
COPY --from=builder /build/flyer /usr/local/bin/flyer

# Install litestream
RUN wget -O /tmp/litestream.tar.gz \
    https://github.com/benbjohnson/litestream/releases/download/v0.3.13/litestream-v0.3.13-linux-amd64.tar.gz \
    && tar -xzf /tmp/litestream.tar.gz -C /usr/local/bin

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENTRYPOINT ["/app/start.sh"]
```

---

## Workflow 4: Manual Deployment

Deploy manually without CI/CD.

### 4.1 Check Current State

```bash
# Current active deployment
flyer deploy active

# Current packages
flyer pkg list --limit 5

# Pending releases
flyer release pending
```

### 4.2 Create New Release

```bash
# Assuming package already uploaded
flyer release create --package PKG0xxx --tag v8.2.0 --notes "Manual hotfix"
```

### 4.3 Stage and Verify

```bash
flyer release stage RLS0xxx

# Verify staging
flyer release pending
```

### 4.4 Activate

```bash
flyer release activate RLS0xxx

# Watch for DistrWatcher to pick up
# Check Echo logs for deployment progress
```

---

## Workflow 5: Rollback

Roll back to a previous version.

### 5.1 Find Previous Release

```bash
# List all releases
psql -d packages -c "SELECT id, tag, status, activated_at FROM releases ORDER BY activated_at DESC LIMIT 10;"
```

### 5.2 Reactivate Previous

```bash
# Activate the previous release
flyer release activate RLS0xxx_previous

# The current release will be demoted
# DistrWatcher will download and switch to previous version
```

### 5.3 Verify Rollback

```bash
flyer deploy active
# Should show the previous version
```

---

## Workflow 6: Debugging

Debug deployment issues.

### 6.1 Check Database State

```bash
# Direct SQLite access
sqlite3 /app/data/packages.db

# Check active version
SELECT * FROM active_versions;

# Check recent releases
SELECT * FROM releases ORDER BY created_at DESC LIMIT 5;

# Check failed deployments
SELECT * FROM deployments WHERE status = 'failed' ORDER BY started_at DESC;
```

### 6.2 Check Litestream

```bash
flyer stream status

# Check generations
litestream generations -config /app/litestream.yml /app/data/packages.db
```

### 6.3 Check Package Directory

```bash
# List extracted packages
ls -la /app/packages/

# Check symlink
ls -la /app/packages/current

# Verify entry point
ls -la /app/packages/current/dist/index.js
```

### 6.4 Manual Sync

```bash
# Force re-sync
rm -rf /app/packages/current
flyer sync --component backend
```

---

## Workflow 7: Database Migration (pg commands)

Migrate PostgreSQL data using flyer pg commands.

### 7.1 Configure PostgreSQL

Add to `flyer.conf`:

```nginx
postgres {
    host       localhost;
    port       5432;
    database   codemoji_game;
    user       codemoji_dev;
    password   env:PG_PASS;
    export_dir /tmp/migration;
    sql_dir    /path/to/phoenix/sql;
}
```

### 7.2 Export from Source

```bash
# Connect to source database
export PG_HOST=source.db.host
export PG_PASS=source_password

# Export to CSV
flyer pg data fetch --output-dir /tmp/migration
```

### 7.3 Import to Target

```bash
# Connect to target database
export PG_HOST=target.db.host
export PG_PASS=target_password

# Check functions
flyer pg functions check

# If missing, create them
flyer pg functions create

# Dry run first
flyer pg data dry-run

# Execute import
flyer pg data upload --confirm
```

---

## Workflow 8: Complete CI/CD Pipeline

Full GitHub Actions workflow.

### .github/workflows/deploy.yml

```yaml
name: Deploy Backend

on:
  push:
    branches: [main]
    paths:
      - 'apps/backend/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Build
        run: |
          cd apps/backend
          npm ci
          npm run build

      - name: Package
        run: |
          cd apps/backend
          VERSION=$(node -p "require('./package.json').version")
          tar -czf backend-${VERSION}.tar.gz dist/ node_modules/ package.json
          echo "VERSION=${VERSION}" >> $GITHUB_ENV

      - name: Upload to Tigris
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.TIGRIS_ACCESS_KEY }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.TIGRIS_SECRET_KEY }}
        run: |
          aws s3 cp apps/backend/backend-${VERSION}.tar.gz \
            s3://fwhd-packages/packages/ \
            --endpoint-url https://fly.storage.tigris.dev

      - name: Create Release
        run: |
          CHECKSUM=$(sha256sum apps/backend/backend-${VERSION}.tar.gz | cut -d' ' -f1)
          SIZE=$(stat -c%s apps/backend/backend-${VERSION}.tar.gz)

          # Create package
          flyer pkg create \
            --name "@fireheadz/codemoji-backend" \
            --version "${VERSION}" \
            --key "packages/backend-${VERSION}.tar.gz" \
            --checksum "sha256:${CHECKSUM}" \
            --size ${SIZE}

          # Create and activate release
          PKG_ID=$(flyer pkg list --limit 1 | tail -1 | awk '{print $1}')
          flyer release create --package ${PKG_ID} --tag v${VERSION}
          RLS_ID=$(psql -t -c "SELECT id FROM releases ORDER BY created_at DESC LIMIT 1")
          flyer release stage ${RLS_ID}
          flyer release activate ${RLS_ID}
```

---

## Next

- [Troubleshooting](04-troubleshooting.md) - Common issues and solutions
