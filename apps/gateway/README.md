# FiberFx Gateway

Secure database management UI for Codemoji. Combines a Go authentication server with Outerbase Studio.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Public Internet                          │
│                         HTTPS                               │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                    Go Server (:8080)                        │
│  ┌─────────────┐  ┌─────────────┐  ┌───────────────────┐   │
│  │ Static Files│  │ JWT Auth    │  │ Reverse Proxy     │   │
│  │ (Svelte UI) │  │ (admin_users)│ │ (authenticated)   │   │
│  └─────────────┘  └─────────────┘  └─────────┬─────────┘   │
│                                              │              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ /api/db/query - Database Query Endpoint             │   │
│  │ Supports PostgreSQL (pgx) and SQLite (modernc.org)  │   │
│  └─────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┼──┘
                                               │ localhost
┌──────────────────────────────────────────────▼──────────────┐
│              Outerbase Studio (Next.js :3008)               │
│                    Child Process                             │
└─────────────────────────────────────────────────────────────┘
                                               │
┌──────────────────────────────────────────────▼──────────────┐
│                   PostgreSQL (codemoji-db)                  │
│   postgres://fireheadz_studio:***@codemoji-db.internal:5432 │
└─────────────────────────────────────────────────────────────┘
```

## Features

- **JWT Authentication** - Login via admin_users table
- **HTTP-only Cookies** - Secure token storage
- **Svelte Login UI** - Clean, responsive login page
- **Outerbase Studio** - Full database management UI
- **Multi-Database** - PostgreSQL and SQLite support
- **Scale-to-Zero** - Cost optimized for Fly.io

## Quick Deploy

```bash
cd fiberfx/apps

# 1. Create Fly app (if not exists)
fly apps create codemoji-db-gateway

# 2. Set secrets with codemoji_game database
fly secrets set \
  DATABASE_URL="postgres://fireheadz_studio:9El4M7mB5Bkxqv5@codemoji-db.internal:5432/codemoji_game" \
  JWT_SECRET="$(openssl rand -base64 32)" \
  MASTER_PASSWORD="your-admin-password"

# 3. Deploy
fly deploy
```

## Local Development

### Prerequisites

- Go 1.23+
- Node.js 22+
- pnpm 10+
- flyctl (for database proxy)

### Quick Start

```bash
cd fiberfx/apps/gateway

# 1. Start database proxy (connects to Fly.io PostgreSQL)
./scripts/dev-proxy.sh

# 2. Copy environment template
cp .env.example .env.local
# Edit .env.local with your secrets

# 3. Build and run
go build -o gateway ./cmd/gateway
./gateway
```

### Database Proxy

The gateway connects to `codemoji-db` PostgreSQL on Fly.io. For local development, use the proxy script:

```bash
# Start proxy (maps localhost:54321 → codemoji-db.internal:5432)
./scripts/dev-proxy.sh

# Check status
./scripts/dev-proxy.sh status

# Stop proxy
./scripts/dev-proxy.sh stop
```

With proxy running, use this connection string:
```
postgres://fireheadz_studio:9El4M7mB5Bkxqv5@localhost:54321/codemoji_game
```

### Build

```bash
# Build Go binary
go build -o gateway ./cmd/gateway

# Build Svelte frontend
cd web && pnpm build
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DATABASE_URL` | Yes | - | PostgreSQL connection string |
| `JWT_SECRET` | Yes | - | HMAC key for JWT signing |
| `MASTER_PASSWORD` | Yes | - | Shared admin password |
| `DRIVER` | No | `postgres` | Database driver: `postgres` or `sqlite` |
| `SQLITE_PATH` | No | `./data/app.db` | SQLite file path (when DRIVER=sqlite) |
| `PORT` | No | `8080` | Go server port |
| `STUDIO_PORT` | No | `3008` | Outerbase Studio port |
| `STUDIO_WORK_DIR` | No | `/app/studio` | Studio working directory |
| `STUDIO_CMD` | No | `node server.js` | Studio start command |
| `WEB_DIR` | No | `/app/web` | Static files directory |
| `COOKIE_SECURE` | No | `true` | Secure cookie flag |
| `COOKIE_DOMAIN` | No | - | Cookie domain |
| `DEBUG` | No | `false` | Enable debug logging |

## Database Drivers

### PostgreSQL (default)

Uses pgx driver with native OID type extraction:

```bash
DRIVER=postgres
DATABASE_URL="postgres://user:pass@host:5432/database"
```

### SQLite

Uses modernc.org/sqlite (pure Go, no CGO):

```bash
DRIVER=sqlite
SQLITE_PATH="./data/app.db"
```

## Access

Open https://codemoji-db-gateway.fly.dev

Login with:
- **Username**: Your Telegram username (from admin_users table)
- **Password**: The MASTER_PASSWORD you set

## Security

- Admin users are validated against `admin_users` table
- JWT tokens stored in HTTP-only, secure cookies
- All non-authenticated requests redirect to login
- Studio only accessible via authenticated proxy
- Database credentials stored as Fly.io secrets

## Troubleshooting

### Gateway won't start

Check database connection:
```bash
fly ssh console -a codemoji-db-gateway
curl -f http://localhost:8080/health
```

### Can't login

Verify admin user exists:
```sql
SELECT telegram_username, is_active FROM admin_users;
```

### Reset password

```bash
fly secrets set MASTER_PASSWORD="new-password" -a codemoji-db-gateway
```

### Database proxy not working

```bash
# Check flyctl auth
fly auth whoami

# Verify app access
fly apps list | grep codemoji-db

# Manually test proxy
fly proxy 54321:5432 -a codemoji-db
```

## Project Structure

```
gateway/
├── cmd/gateway/          # Go entry point
├── internal/
│   ├── auth/             # JWT authentication
│   ├── config/           # Configuration
│   ├── db/               # Database drivers (PostgreSQL, SQLite)
│   ├── process/          # Child process manager
│   ├── proxy/            # Reverse proxy
│   └── static/           # Static file server
├── scripts/
│   └── dev-proxy.sh      # Local database proxy
├── web/                  # Svelte frontend (login page)
├── .env.example          # Environment template
├── .env.local            # Local config (gitignored)
├── go.mod
└── README.md
```

## API Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/health` | GET | No | Health check |
| `/api/auth/login` | POST | No | Login with credentials |
| `/api/auth/logout` | POST | No | Clear session |
| `/api/me` | GET | Yes | Current user info |
| `/api/db/query` | POST | Yes | Execute SQL query |
| `/login` | GET | No | Login page |
| `/*` | GET | Yes | Outerbase Studio (proxied) |
