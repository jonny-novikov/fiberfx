# 90 — Deferred: learner authentication and per-learner progress

**Status: DEFERRED. NOT IMPLEMENTED THIS CYCLE.** Every part of this document is a forward
sketch. No code, schema, command, dependency, or server change described here is built,
scheduled, or part of the current `jonnify-cms` deliverable. The document exists to record the
intended shape so that a later cycle can pick it up without re-deciding the seams. Until then
the static jonnify site and `cms` remain exactly as the other specs describe: stateless,
read-mostly, no accounts, no learner state.

> **Forward reference (scope update).** SQLite has since been adopted in this module for a
> separate, already-implemented purpose — the filesystem-mirrored **content store**
> (`docs/specs/07-content-store.md`), which holds the decomposed `/elixir` pages for
> byte-parity rebuilds. `go.mod` therefore already carries `modernc.org/sqlite` (the same
> CGO-free driver this section names below), and §4's "`go.mod` is **not** to gain
> `modernc.org/sqlite` in this cycle" no longer holds. The **progress/auth** store sketched
> here remains deferred and unimplemented; the two stores are unrelated (content vs. learner
> state).

## 1. What is deferred and why

The course is a tree of static pages. A natural future feature is **per-learner progress**:
a reader signs in, and the site remembers which modules they have completed, resumes them
where they left off, and can show progress across the 54-module spine. That requires identity
(login) and durable per-learner state (completion records) — neither of which a static file
server provides.

This is deferred for two reasons:

1. **The static server stays stateless.** The jonnify Fiber server is a pure static file
   server with no data layer, no database, and no sessions (per the jonnify `CLAUDE.md`).
   Adding accounts to it would change its nature and its operational profile. The deferred
   design keeps that server untouched.
2. **Identity is owned externally.** Login is intended to be performed by an **external auth
   system** — initially a **Telegram Mini App**, later a dedicated **Node.js backend** — using
   a **magic-link** flow. `jonnify-cms` and the static site are not in the business of issuing
   credentials; they would, at most, consume an already-authenticated learner identity handed
   to them by that external system.

Because both the identity provider and the progress store live outside the current scope,
nothing here is implemented now.

## 2. Boundaries (what stays as-is)

When this feature is eventually built, these invariants hold:

- **The static jonnify server remains stateless.** It continues to serve `/elixir` pages
  byte-for-byte. It does not gain a database, sessions, or per-request user state. Progress is
  not served by it.
- **`cms` remains an offline, read-mostly authoring tool.** Its current commands
  (`manifest`, `routes`, `graph`, `audit`, `readiness`, `check`, `stamp`, `build`) do not
  change behavior. Any progress functionality would be additive and separately gated, never a
  prerequisite for the existing commands.
- **No login UI ships inside the course pages from `cms`.** Authentication is an external
  surface (the Telegram Mini App / Node backend); the course pages stay public and cacheable.

## 3. Integration seam (sketch — NOT IMPLEMENTED)

The intended seam is a thin, optional **progress service** that is *separate* from both the
static server and `cms`'s authoring commands. The external auth system authenticates the
learner and presents a verified learner identity (an opaque external id, e.g. a Telegram user
id, or a future backend subject claim). The progress service then maps that identity to
completion records keyed by **module id** — the same `F‹c›.0N` ids the manifest already uses
(`docs/specs/01-manifest.md`), so progress aligns with the existing course structure with no
new identifier scheme.

```
   ┌────────────────────────┐        verified identity        ┌────────────────────────┐
   │  External auth system  │ ───────────────────────────────▶│   Progress service     │
   │  (Telegram Mini App,    │   (magic-link; opaque ext id)   │   (future, separate)   │
   │   future Node backend)  │                                 │                        │
   └────────────────────────┘                                  │  - learner table       │
                                                               │  - module_completion    │
   ┌────────────────────────┐     module ids = F‹c›.0N         │  - SQLite (CGO-free)   │
   │  jonnify-cms manifest   │ ───────────────────────────────▶│                        │
   │  (module id authority)  │     (read-only reference)       └────────────────────────┘
   └────────────────────────┘
            ▲                                                              │
            │  unchanged, stateless                                        │ optional read
   ┌────────────────────────┐                                             ▼
   │  static jonnify server  │   serves /elixir pages, no learner state  (progress shown by the
   │  (/elixir, byte-for-    │                                            external surface, not
   │   byte, no DB)          │                                            by the static server)
   └────────────────────────┘
```

`jonnify-cms` would, at most, contribute a **read-only reference** of valid module ids and
their order (it already computes this), so the progress service can validate and order
completion records against the canonical course structure. The static server is not a node in
the write path.

## 4. Storage driver decision (recorded for the future)

When a Go progress store is added, it **must** use the house database driver
**`modernc.org/sqlite`** — the pure-Go, CGO-free SQLite driver.

- It is **CGO-free**, so it matches the `CGO_ENABLED=0` static Alpine build the jonnify
  deployment and `jonnify-cms` already use (`docs/specs/00-overview.md` §5, design goal 5). A
  cgo SQLite driver (e.g. `mattn/go-sqlite3`) would force `CGO_ENABLED=1` and a C toolchain in
  the image, breaking the static-binary build; it is excluded for that reason.
- It is the same driver already used elsewhere in this workspace (the gateway's
  `internal/db/sqlite.go`), so it is the established house choice — consistency, not a new
  dependency class.

This is a recorded decision, not an instruction to add the dependency now. `go.mod` is **not**
to gain `modernc.org/sqlite` in this cycle.

## 5. Data model (sketch — NOT IMPLEMENTED)

A minimal two-table model is sufficient for completion tracking. Shown as the intended shape
only; no migration, no DDL, and no Go types are created this cycle.

```sql
-- NOT IMPLEMENTED THIS CYCLE — sketch only.

-- One row per authenticated learner. Identity originates in the external
-- auth system; `ext_id` is that system's opaque subject (e.g. a Telegram user id).
CREATE TABLE learner (
    id          INTEGER PRIMARY KEY,         -- internal surrogate id
    ext_id      TEXT NOT NULL UNIQUE,        -- opaque id from the external auth system
    ext_source  TEXT NOT NULL,               -- e.g. "telegram", later "node-backend"
    created_at  TEXT NOT NULL                -- RFC 3339 UTC
);

-- One row per (learner, completed module). Module ids are the manifest's
-- F‹c›.0N ids (e.g. "F2.06"), validated against jonnify-cms's module list.
CREATE TABLE module_completion (
    learner_id   INTEGER NOT NULL REFERENCES learner(id),
    module_id    TEXT    NOT NULL,           -- "F1.01" .. "F6.09", a manifest module id
    completed_at TEXT    NOT NULL,           -- RFC 3339 UTC
    PRIMARY KEY (learner_id, module_id)
);
```

Design notes (all forward-looking):

- **`module_id` is the join to the manifest.** Validating a completion record against
  `manifest.Modules` (the existing module id set) keeps progress and course structure in one
  vocabulary; a renamed or removed module is detectable as an orphaned completion the same way
  the link audit detects orphaned files.
- **No course content lives in the store.** The store holds identity and completion only; page
  content remains static files. This preserves the stateless-server boundary.
- **Branded ids are available as pivots if needed.** Should externally meaningful keys for
  learners or events be required, the branded Snowflake scheme already specified
  (`docs/specs/06-snowflake-stamp.md`) is the house convention (a `LRN`/`EVT` namespace), with
  no new id machinery required. This is optional and not part of the minimal model above.

## 6. Magic-link flow (sketch — NOT IMPLEMENTED)

For completeness, the intended login is a **magic-link** flow owned entirely by the external
auth system: the learner requests a link, the external system delivers and verifies it
(in-app for the Telegram Mini App, by email/token for the future Node backend), and on
verification the external system establishes the learner identity that the progress service
consumes. No part of this flow runs in the static jonnify server or in `cms`. Token issuance,
delivery, expiry, and session handling are external concerns and are not specified here beyond
naming the seam.

## 7. Explicit non-goals for this cycle

To prevent scope creep, the following are **out of scope and not delivered now**:

- No `cms` subcommand for login, learners, or progress.
- No database dependency in `go.mod` (no `modernc.org/sqlite`, no driver of any kind).
- No schema, migration, or DDL committed.
- No change to the static jonnify server (no DB, no sessions, no auth middleware).
- No Telegram Mini App or Node backend code, and no magic-link issuance.
- No network calls anywhere in `jonnify-cms` (the offline design goal,
  `docs/specs/00-overview.md` §5, holds unchanged).

This document is a placeholder for a future cycle and imposes no work on the current one.
