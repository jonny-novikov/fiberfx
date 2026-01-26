# PostgreSQL Query Execution Architecture

> **X-MODE Documentation** | FiberFx Gateway + Svelte Studio Integration
>
> Target: `codemoji-db.fly.dev` via `codemoji-backend`

---

## 5W Analysis

### WHAT: Query Execution Pipeline

A **three-tier query execution system** that routes SQL from Svelte frontend through Go gateway to PostgreSQL:

```
┌─────────────────┐     HTTP POST      ┌─────────────────┐      pgx Pool       ┌─────────────────┐
│  Svelte Studio  │ ────────────────→  │   Go Gateway    │  ──────────────→   │   PostgreSQL    │
│  (Browser)      │                    │   (:8080)       │                     │   (codemoji-db) │
│                 │ ←────────────────  │                 │  ←──────────────   │                 │
└─────────────────┘   JSON + OIDs      └─────────────────┘    Rows + Meta     └─────────────────┘
```

**Components:**
1. **LocalPostgresQueryable** - Svelte TypeScript driver (`local-postgres.ts`)
2. **db.Handler** - Go HTTP handler (`internal/db/handler.go`)
3. **PostgresDriver** - Go pgx wrapper (`internal/db/postgres.go`)

### WHERE: Codebase Locations

| Component | Path | Purpose |
|-----------|------|---------|
| Frontend Driver | `apps/studio/src/drivers/database/local-postgres.ts` | HTTP client, OID mapping |
| Gateway Handler | `apps/gateway/internal/db/handler.go` | REST endpoint |
| Postgres Driver | `apps/gateway/internal/db/postgres.go` | pgx execution |
| Type Definitions | `apps/gateway/internal/db/types.go` | Shared contracts |
| Driver Interface | `apps/gateway/internal/db/driver.go` | Abstraction layer |

### WHY: Design Rationale

1. **Security**: Database credentials never reach browser
2. **Abstraction**: Same API supports PostgreSQL and SQLite drivers
3. **Caching**: Gateway can cache schema introspection
4. **Auth Integration**: Queries routed through auth middleware

### WHICH: Constraints & Dependencies

| Constraint | Value | Source |
|------------|-------|--------|
| Max Connections | 5 | `cmd/gateway/main.go:199` |
| Min Connections | 1 | `cmd/gateway/main.go:200` |
| Connection Lifetime | 30 min | `cmd/gateway/main.go:201` |
| Idle Timeout | 5 min | `cmd/gateway/main.go:202` |
| Query Timeout | Context-based | Inherited from HTTP request |

**Dependencies:**
- `github.com/jackc/pgx/v5` - PostgreSQL driver
- `github.com/go-chi/chi/v5` - HTTP router
- `@anthropic-ai/sdk` - Outerbase SDK (frontend)

### WHO: Consumers

1. **Outerbase Studio UI** - Schema browser, query editor
2. **Data Grid Component** - Table viewing/editing
3. **Schema Introspection** - `information_schema` queries
4. **DDL Operations** - CREATE, ALTER, DROP via raw SQL

---

## Current Problems & D-N Decisions

### D-1: UUID Serialization Format

**Problem:** UUIDs serialize as `[16]int` arrays instead of standard strings.

**Location:** `internal/db/postgres.go:106-112`

```go
case [16]byte:
    result := make([]int, 16)  // WRONG: Returns [123, 45, 67, ...]
    for i, b := range val {
        result[i] = int(b)
    }
    return result
```

**Impact:**
- UUIDs display as `[123,45,67,89,...]` in Svelte grid
- Copy/paste broken
- Filtering by UUID fails

**Decision:** Fix to return RFC 4122 string format.

```go
case [16]byte:
    return fmt.Sprintf("%08x-%04x-%04x-%04x-%012x",
        binary.BigEndian.Uint32(val[0:4]),
        binary.BigEndian.Uint16(val[4:6]),
        binary.BigEndian.Uint16(val[6:8]),
        binary.BigEndian.Uint16(val[8:10]),
        val[10:16])
```

**Status:** 🔴 Critical | Blocking UX

---

### D-2: Incomplete OID Type Mapping

**Problem:** Frontend only maps 12 PostgreSQL OIDs, defaulting others to TEXT.

**Location:** `apps/studio/src/drivers/database/local-postgres.ts:38-58`

```typescript
function mapPgTypeToColumnType(pgTypeOid: number): ColumnType {
    switch (pgTypeOid) {
        case 23: case 20: case 21: return ColumnType.INTEGER;
        case 700: case 701: case 1700: return ColumnType.REAL;
        case 16: return ColumnType.INTEGER;  // bool
        case 1082: case 1114: case 1184: return ColumnType.TEXT;
        default: return ColumnType.TEXT;  // EVERYTHING ELSE
    }
}
```

**Missing Critical OIDs:**

| OID | Type | UX Impact |
|-----|------|-----------|
| 2950 | UUID | No UUID formatting |
| 114/3802 | JSON/JSONB | No JSON viewer |
| 1009 | TEXT[] | No array handling |
| 17 | BYTEA | Binary as text |

**Decision:** Extend mapping with tier-based approach.

```typescript
// Tier 1: Numeric
case 23: case 20: case 21: case 26: return ColumnType.INTEGER;
case 700: case 701: case 1700: return ColumnType.REAL;

// Tier 2: Structured
case 114: case 3802: return ColumnType.BLOB;  // JSON viewer
case 2950: return ColumnType.TEXT;  // UUID (gateway formats)

// Tier 3: Arrays (future)
case 1009: case 1007: case 1016: return ColumnType.TEXT;  // Array notation
```

**Status:** 🟡 Medium | Degraded UX

---

### D-3: Batch Query Atomicity

**Problem:** Batch queries execute independently, not transactionally.

**Location:** `internal/db/postgres.go:77-88`

```go
func (d *PostgresDriver) Batch(ctx context.Context, queries []string) ([]QueryResult, error) {
    for i, q := range queries {
        result, err := d.Query(ctx, q)  // Each query = separate transaction
        if err != nil {
            return nil, err  // Partial commit, no rollback!
        }
    }
}
```

**Scenario:** 5 queries, #3 fails:
- Queries 1-2: ✅ Committed (can't undo)
- Query 3: ❌ Failed
- Queries 4-5: ⏸️ Never run

**Frontend Workaround:** Studio wraps with BEGIN/COMMIT:
```typescript
async transaction(stmts: string[]) {
    const wrapped = ["BEGIN", ...stmts, "COMMIT"];
    return this.batch(wrapped).slice(1, -1);
}
```

**Decision:** Document current behavior; consider pgx Batch API for v2.

**Status:** 🟢 Low | Workaround exists

---

### D-4: BYTEA Encoding

**Problem:** Binary data converts to int arrays, not hex strings.

**Location:** `internal/db/postgres.go:99-105`

```go
case []byte:
    result := make([]int, len(val))  // [72, 101, 108, 108, 111]
    for i, b := range val {
        result[i] = int(b)
    }
    return result
```

**Decision:** Convert to PostgreSQL hex format `\x48656c6c6f`.

```go
case []byte:
    return fmt.Sprintf("\\x%x", val)  // \x48656c6c6f
```

**Status:** 🟡 Medium | Data display issue

---

### D-5: Time Zone Handling

**Problem:** `time.Time` values may lose timezone in JSON serialization.

**Current:** pgx returns `time.Time`, Go's JSON encoder uses RFC 3339.

**Risk:** TIMESTAMPTZ values may appear in server's local TZ, not UTC.

**Decision:** Explicitly format with UTC:

```go
case time.Time:
    return val.UTC().Format(time.RFC3339Nano)
```

**Status:** 🟢 Low | Edge case

---

## Svelte UX Integration Guide

### Connection Flow

```svelte
<!-- src/routes/+page.svelte -->
<script lang="ts">
  import { LocalPostgresQueryable } from '$lib/drivers/local-postgres';
  import { PostgresLikeDriver } from '@anthropic-ai/sdk';

  const queryable = new LocalPostgresQueryable();
  const driver = new PostgresLikeDriver(queryable);

  // Schema introspection
  const tables = await driver.getTables();

  // Direct query
  const result = await queryable.query('SELECT * FROM users LIMIT 10');
</script>
```

### Reactive Query Pattern

```svelte
<script lang="ts">
  let query = $state('SELECT 1');
  let result = $state<DatabaseResultSet | null>(null);
  let error = $state<string | null>(null);

  async function execute() {
    error = null;
    try {
      result = await queryable.query(query);
    } catch (e) {
      error = e.message;
    }
  }
</script>

<textarea bind:value={query} />
<button onclick={execute}>Run</button>

{#if error}
  <div class="error">{error}</div>
{:else if result}
  <DataGrid
    headers={result.headers}
    rows={result.rows}
    stat={result.stat}
  />
{/if}
```

### Type-Aware Cell Rendering

```svelte
<!-- DataCell.svelte -->
<script lang="ts">
  import { ColumnType } from '@anthropic-ai/sdk';

  let { value, type }: { value: unknown; type: ColumnType } = $props();
</script>

{#if type === ColumnType.INTEGER}
  <span class="number">{value?.toLocaleString()}</span>
{:else if type === ColumnType.REAL}
  <span class="number">{Number(value).toFixed(2)}</span>
{:else if isJsonString(value)}
  <JsonViewer {value} />
{:else}
  <span class="text">{String(value ?? 'NULL')}</span>
{/if}
```

---

## codemoji-db Connection Patterns

### Fly.io Internal Networking

```env
# Production (fly.toml secrets)
DATABASE_URL=postgres://fireheadz_studio:***@codemoji-db.internal:5432/codemoji_game

# Local Development (with fly proxy)
DATABASE_URL=postgres://codemoji_dev:codemoji_password@localhost:5432/codemoji_game

# Staging Proxy (port forward)
DATABASE_URL=postgres://codemoji_dev:codemoji_password@localhost:15432/codemoji_game
```

### Connection Pool Settings

```go
// cmd/gateway/main.go
poolConfig.MaxConns = 5           // Fly.io free tier limit
poolConfig.MinConns = 1           // Keep 1 warm
poolConfig.MaxConnLifetime = 30 * time.Minute
poolConfig.MaxConnIdleTime = 5 * time.Minute
```

### Health Check Integration

```go
// Verify DB connectivity
func handleHealth(pm *process.Manager) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        // Also check DB pool health
        if err := pool.Ping(r.Context()); err != nil {
            // Return degraded status
        }
    }
}
```

---

## Architecture Diagram

```mermaid
flowchart TB
    subgraph Browser["Browser (Svelte 5)"]
        UI[Outerbase Studio UI]
        LPQ[LocalPostgresQueryable]
        PLD[PostgresLikeDriver]
        UI --> PLD --> LPQ
    end

    subgraph Gateway["Go Gateway (:8080)"]
        Router[Chi Router]
        Auth[Auth Middleware]
        DBH[db.Handler]
        PGD[PostgresDriver]
        Pool[pgxpool.Pool]
        Router --> Auth --> DBH --> PGD --> Pool
    end

    subgraph Fly["Fly.io"]
        PGDB[(codemoji-db<br/>PostgreSQL 15)]
    end

    LPQ -->|"POST /api/db/query<br/>JSON body"| Router
    Pool -->|"pgx protocol<br/>:5432"| PGDB

    style Browser fill:#f5f5f5
    style Gateway fill:#e8f4ea
    style Fly fill:#fff3e0
```

---

## API Contract Reference

### Single Query

**Request:**
```http
POST /api/db/query
Content-Type: application/json
Cookie: session=...

{"query": "SELECT id, name FROM users LIMIT 5"}
```

**Response:**
```json
{
  "response": {
    "items": [
      {"id": 1, "name": "alice"},
      {"id": 2, "name": "bob"}
    ],
    "headers": [
      {"name": "id", "type": 23},
      {"name": "name", "type": 25}
    ],
    "stat": {
      "rowsAffected": 0,
      "rowsRead": null,
      "rowsWritten": null,
      "queryDurationMs": 12
    }
  }
}
```

### Batch Query

**Request:**
```json
{"queries": ["SELECT 1 AS a", "SELECT 2 AS b"]}
```

**Response:**
```json
{
  "response": [
    {"items": [{"a": 1}], "headers": [...], "stat": {...}},
    {"items": [{"b": 2}], "headers": [...], "stat": {...}}
  ]
}
```

### Error Response

```json
{
  "error": "ERROR: relation \"missing_table\" does not exist (SQLSTATE 42P01)"
}
```

---

## PostgreSQL OID Quick Reference

| OID | Type | Mapped To | Notes |
|-----|------|-----------|-------|
| 16 | BOOL | INTEGER | 0/1 |
| 17 | BYTEA | TEXT | Needs hex encoding |
| 20 | INT8 | INTEGER | bigint |
| 21 | INT2 | INTEGER | smallint |
| 23 | INT4 | INTEGER | integer |
| 25 | TEXT | TEXT | |
| 26 | OID | INTEGER | Object ID |
| 114 | JSON | TEXT | Needs JSON viewer |
| 700 | FLOAT4 | REAL | |
| 701 | FLOAT8 | REAL | |
| 1082 | DATE | TEXT | ISO 8601 |
| 1114 | TIMESTAMP | TEXT | No TZ |
| 1184 | TIMESTAMPTZ | TEXT | With TZ |
| 1700 | NUMERIC | REAL | Arbitrary precision |
| 2950 | UUID | TEXT | RFC 4122 |
| 3802 | JSONB | TEXT | Binary JSON |

---

## Implementation Checklist

- [ ] **D-1:** Fix UUID serialization in `postgres.go`
- [ ] **D-2:** Extend OID mapping in `local-postgres.ts`
- [ ] **D-3:** Document batch behavior (no code change)
- [ ] **D-4:** Fix BYTEA hex encoding in `postgres.go`
- [ ] **D-5:** Ensure UTC timestamps in `postgres.go`
- [ ] Add JSON pretty-print for 114/3802 OIDs
- [ ] Add array notation for array types
- [ ] Health check includes DB ping

---

*Generated by X-MODE | 2026-01-19*
