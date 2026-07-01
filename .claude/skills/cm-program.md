---
name: cm-program
description: >-
  The shared program floor every codemojex-node dev skill cites — the venus-cm / mars-cm role skills and the
  cm-ship command all stand on it. codemojex-node is the Node/TypeScript consumer at mercury/codemojex/
  (the @codemojex/* pnpm workspace: apps admin · economy · game · game-tauri, +dashboard coming; packages
  db · domain · types), COUPLED to the @mercury/* design system it composes and to the echo/ codemojex Elixir
  engine whose Postgres + Valkey substrate it reads. This file carries the program-wide law: the negotiated
  island boundary, the capability router (lazy-load backend / frontend-mercury / rust-tauri / elixir-coupled by
  domain), the master laws (no-secret-on-wire · @mercury barrel-additive · token discipline · compose-the-mature
  -foundation), the pnpm --filter @codemojex/* gate ladder, the docs/codemojex/specs/<chapter>/ spec home
  (aaw.specs-approach), the aaw ledger, and the git posture. Read it once per cm-ship rung. It is an operational
  digest — the binding authority is the canon it points at, never overrides. Do NOT use for the echo/ codemojex
  Elixir engine (/codemojex-ship), the Mercury design-system packages (/mercury-ship), or the echo_mq bus
  (/echo-mq-ship).
---

# codemojex-node — the program law (shared reference)

The common law every codemojex-node dev skill cites. The role-specific craft lives in the two role skills
(`venus-cm`, `mars-cm`); the domain-specific craft lives in the lazy-loaded capability skills (`cm-backend`, and
the referenced `mercury-program` / rust / echo craft). This file is the program-wide floor all of them stand on.
Read it once per `cm-ship` rung; the role skill points back here.

**codemojex-node ≠ the echo/ codemojex engine.** This program is the **Node/TypeScript** consumer at
`mercury/codemojex/` (`@codemojex/*`) — NOT the Elixir game engine at `echo/apps/codemojex` (that ships via
`/codemojex-ship`, slugs `cm.N`). This floor **never edits `echo/`**; it READS the echo/ engine's shared Postgres
+ Valkey substrate as a coupling contract (§ the elixir-coupled capability).

**Framing.** Third person for any agent reference; no gendered pronouns for agents; no perceptual or
interior-state verbs for agents or software — a server registers, refuses, returns; a component renders,
resolves. Forward-tense ("`dashboard.1` adds …") for an unbuilt surface.

**TMPDIR=/tmp is an Elixir-only rule — it does NOT apply here.** codemojex-node is Node (≥20) + pnpm.

## The canon (read-first, NO-INVENT)

- **The chapter spec home** — `docs/codemojex/specs/<chapter>/` (`admin/` · `economy/` · `tauri/` · `dashboard/`
  as they open), authored to `docs/aaw/aaw.specs-approach.md`: a chapter index `<chapter>.md`, a
  `<chapter>.roadmap.md`, and per-rung triads `<rung>.{md,stories.md,llms.md}` (the `<rung>.md` body
  authoritative). The run ledger is `<scope>.progress.md` (e.g. `codemojex-admin.progress.md`).
- **The engine canon (the shared-substrate contract)** — `docs/codemojex/codemojex.design.md` (the six-table
  Postgres model — `players` · `transactions` · `emoji_sets` · `rooms` · `games` · `guesses` (+ `notifications`)
  — and the `cm:<game>:*` Valkey keyspace the node side READS) + `docs/codemojex/codemojex.roadmap.md`. The node
  side is a **reader** of the substrate the Elixir engine writes; the schema is the coupling, not an HTTP call.
- **The mercury canon (for a coupled frontend rung)** — `.claude/skills/mercury-program.md` + the design canon
  `docs/mercury/mercury.design.md` (the token vocabulary §6, the barrel master-invariant §2).
- **The workflow** — `docs/aaw/aaw.framework.md` + the spec-format contract `docs/aaw/aaw.specs-approach.md`
  (the chaptered triad + the six quality gates) + the architect's instruments `docs/aaw/aaw.architect-approach.md`.
- **The taste plugin** — the model-invoked `frontend-design` skill (taste / aesthetics), loaded only on a
  frontend rung; how it feeds the system is the Mercury valve (`mercury-program.md`).

## The boundary — a NEGOTIATED island in the jonnify monorepo

The git root is `jonnify` (the PARENT); it holds ≥10 unrelated programs. codemojex-node treats the rest of the
tree as if it did not exist — **except** the two surfaces it is COUPLED to (`@mercury/*`, the echo/ substrate),
and each rung's actual touch is **scoped from the Operator's request at Bootstrap and ratified before any spawn**
(the formation `tool_x_decision`). The rings:

| Ring | Paths | Rule |
|---|---|---|
| **Primary — edit** | `mercury/codemojex/**` — the `@codemojex/*` apps + packages | the rung's home |
| **Coupled — edit, additive** | `mercury/packages/mercury-core/` + `mercury/packages/mercury-effector/` (the **core + fx** foundation) | ADDITIVE only; a change to an *existing* `@mercury/core`/`@mercury/effector` export that `@mercury/ui`/`mercury/apps/*` consume **forks to `/mercury-ship`** |
| **Coupled — additive, barrel holds** | `mercury/packages/mercury-ui/` | ADDITIVE only; the barrel master-invariant is re-checked (the **resolved** export set: 0 removed/renamed) |
| **Read-only — grounding** | `echo/apps/codemojex` (the Ecto schema + the `cm:<game>:*` keyspace the node reads); `mercury/apps/*` (a `@mercury` call-site) | never edited — an `echo/` edit forks OUT to `/codemojex-ship` |
| **Out** | `html/ elixir/ go/ infra/ node/ tradex/ mcp/ bin/ scripts/ memory/ …` | never read, searched, built, or touched |

Enforce it mechanically: **every `Glob`/`Grep`/`find` roots at `mercury/codemojex/` (or a ratified coupled ring)**
— never a bare search from the jonnify root; **the gate uses `pnpm --filter @codemojex/<app>`, never a blind
`pnpm -r`** (which walks the whole monorepo); **the commit is a `mercury/codemojex/…` (+ `docs/codemojex/…`, +
the ratified `mercury/packages/…` additions) pathspec**.

## The capability router — lazy-load by domain (context economy is a correctness lever)

The workspace is heterogeneous (Fastify backend · React frontends · a Rust/Tauri host · an Elixir data-coupling).
A rung loads **only** the capability its domain needs — a backend `admin` rung never drags the design-system
craft into context; a frontend `economy` rung never drags Fastify/Drizzle. The Director classifies the domain(s)
at Bootstrap; the peer then loads the matching capability — **read** a bare-`.md` reference by path
(`.claude/skills/cm-backend.md`, `.claude/skills/mercury-program.md`) and **`Skill`-load** a dir-based role skill
(`venus-mercury` / `mars-mercury`) or the model-invoked `frontend-design` plugin — never all four.

| Domain | Triggered by | Lazy-loads | Adds to the gate |
|---|---|---|---|
| **backend** | `admin`, a `dashboard` API, a package doing Postgres/Valkey I/O | **`cm-backend`** — Fastify · Drizzle (`@codemojex/db`) · Valkey (`iovalkey` :6390) · TypeBox · the **no-secret-on-wire** law | the `app.inject` suite · the secret-strip assertion · `buildServer(loadEnv()).ready()` boot-smoke (solo + clustered) |
| **frontend / mercury** | `economy`, `game`, `dashboard` UI, a `game-tauri` web view | **`mercury-program`** + the role's **`venus-mercury`/`mars-mercury`** craft + the model-invoked **`frontend-design`** plugin (compose `@mercury/*`, token discipline) | the **barrel-diff** (resolved export set) on any `@mercury` touch · a no-raw-hex/token grep · the app's vitest |
| **rust / tauri** | `game-tauri` (the `src-tauri` Rust host) | a **forward slot** — the Rust craft (the `echo_graft`/`graft-ship` cargo discipline: `--test-threads=1`, name the excluded feature-gated set); filled when a tauri rung is first worked | `cargo build` + `cargo test` in `apps/game-tauri/src-tauri` |
| **elixir-coupled** | a node feature binding the echo/ engine's shared Postgres schema / `cm:<game>:*` keyspace | **read-only** grounding — reconcile `@codemojex/db` (Drizzle) against the echo/ Ecto schema (`codemojex.design.md`) + the keyspace; via `/codemojex-ship` + `echo/CLAUDE.md` | (echo/ is NOT edited — an echo/ change forks to `/codemojex-ship`) |

## The laws (the load-bearing properties — an invariant that asserts one is a runnable check)

| Law | What it binds | Where |
|---|---|---|
| **No secret on the wire (backend)** | No data route answers unauthenticated, and no response body carries a server-side `secret` (or `keyboard`) — the read plane's TypeBox *response* schema lists only public columns, so `fast-json-stringify` drops the secret even if a query selected it. Proven by an `app.inject` response-key assertion, not by remembering to omit. | `cm-backend` · `admin.md` |
| **@mercury barrel-additive (coupled)** | When a rung additively touches `@mercury/ui`, every name exported from `mercury/packages/mercury-ui/src/index.ts` before the rung is still exported after it (additions OK; **removals/renames break the Mercury apps** → STOP, surface to the Operator). The barrel is `export *`, so prove it with the **resolved** export set, never a text-diff. | `mercury-program.md` §2 |
| **Token discipline (frontend)** | A composed `@mercury` surface styles through enum props + `rgb(var(--token))`; a codemojex app **never** authors a private `.mx-*` recipe or a raw hex — a new token family is a `/mercury-ship` fork. | `mercury-program.md` §6 |
| **Compose the mature foundation** | A codemojex frontend COMPOSES `@mercury/core` (formatters, `cx`, date) + `@mercury/ui` + `@mercury/effector`; it does not re-implement them. "Translate the prototype" borrows an app's *anatomy*, never its throwaway logic — dates flow THROUGH `@mercury/core` (`D-6`). | `mercury.design.md` |
| **The spec triad (aaw.specs-approach)** | Every rung carries a chaptered triad: `<rung>.md` (6 `##` sections — Goal · Rationale 5W · Scope · Deliverables `<rung>-D#` · Invariants `<rung>-INV#` · DoD) + `<rung>.stories.md` (Connextra US# · G/W/T · `encodes <rung>-INV#` · Coverage) + `<rung>.llms.md` (References · Requirements R# `[US:]` · Execution topology · Agent stories AS# `[implements]` · a comprehensive prompt). The six gates: Voice · Structure · Traceability · Fences · Links · Format. | `aaw.specs-approach.md` |

## The codemojex-node facts (NO-INVENT — ground each in a real file or a canon §)

- **The workspace** — `mercury/codemojex/` = `@codemojex/node` (private pnpm workspace, `type: module`, engines
  `node ≥20`, root `typecheck` = `tsc -p tsconfig.json` over project references). Re-probe the app's
  `package.json` `scripts` for its real `build`/`test`/`dev` — never assert a script name.
- **The apps** (`mercury/codemojex/apps/`): `@codemojex/admin` (a **Fastify** operator-API control plane over
  `@codemojex/db` + Valkey — the read/light-management plane, boots solo `main.ts`→`start` + clustered
  `cluster.ts`→`@echo/cluster runCluster`) · `@codemojex/economy` (a **React/Vite/Effector** revenue-model
  calibration console composing `@mercury/*`) · `@codemojex/game` (the **React** game island) · `@codemojex/game
  -tauri` (a **Tauri** desktop wrapper — `src-tauri` Rust host + a web view). Forward: `@codemojex/dashboard`.
- **The packages** (`mercury/codemojex/packages/`): `@codemojex/db` (the **Drizzle** schema — the Postgres record,
  mirroring the echo/ engine's Ecto tables) · `@codemojex/domain` (domain logic) · `@codemojex/types` (shared
  types). A schema drift between `@codemojex/db` and the echo/ Ecto schema is the elixir-coupling risk.
- **The couplings** — (1) **to `@mercury/*`**: the React apps consume `@mercury/core` + `@mercury/ui` +
  `@mercury/effector` **from source** (a vite alias + tsconfig `paths`); a cm-ship rung may ADDITIVELY extend
  core + fx (and additively `@mercury/ui`, barrel-held). (2) **to echo/**: `@codemojex/db` + `iovalkey` read the
  **same** Postgres tables + `cm:<game>:*` Valkey keyspace the Elixir engine writes; the `secret` on `games` is
  server-side and must be stripped at any node wire (the no-secret law).

## The gate ladder (run from `mercury/codemojex/`, before reporting — NEVER a blind `pnpm -r`)

```bash
pnpm install                                  # the workspace deps (this sub-workspace installs independently)
pnpm --filter @codemojex/<app> typecheck      # tsc clean for the rung's app(s)
pnpm --filter @codemojex/<app> build          # the app builds (re-probe the real script)
pnpm --filter @codemojex/<app> test           # the app's suite (the Fastify inject suite / vitest)
# + the capability-specific gate (above): the secret-strip inject assertion · the boot-smoke ·
#   the @mercury barrel-diff (resolved export set) · the cargo build/test.
```

Node ≥20, pnpm. **A check counts only if it RUNS** — a story like "no secret on the wire" is proven by an
`app.inject` response-key assertion, "the game themes in dark" by toggling the theme in a real view, never by
reading the source. **The build-local boot is not the live deploy** — a service rung boots the real entry
(`start` AND `runCluster`) against a reachable Postgres + Valkey (Operator runs deploys — hand off, then verify).

## The aaw ledger (the durable record — `mcp__aaw__*`)

On a rung that stands up a team (`mcp__aaw__aaw_init` → `agent_register` → `TeamCreate(<dashed-scope>)`), the
`tool_x_*` family records: `tool_x_alternative` → **V-n** (an option), `tool_x_consensus` → **C-n** (a panel's
agreement), `tool_x_nxm_synthesize` → **S-n** (a fusion), `tool_x_decision` → **D-n** (a ruled fork), `tool_x_
learning` → **L-n** (a craft lesson). The dashed scope is `codemojex-<app>` (`codemojex-admin`, `codemojex-
economy`, `codemojex-tauri`, `codemojex-dashboard` — never a dot; `^[a-z0-9][a-z0-9-]*$`, a dot split-brains the
registry) and matches the on-disk `<scope>.progress.md` ledger filename. A Duo/Trio rung needs no team; a Squad
or a design judge-panel opens the ledger.

## Process locks (every rung, this repo)

- **Agents run NO git.** The Director commits once, at the rung's close, by **pathspec** (`git commit -F <msg>
  -- <paths>`; never `git add -A`, never a bare commit) — and **only when the Operator asks**. The Operator
  pre-stages out-of-band, so the tree is routinely entangled with sibling programs: re-verify `git diff --cached
  --name-only` is purely the rung before committing, and split an entangled tree into one scoped commit per
  concern. Do not push unless asked.
- **The boundary.** The diff stays inside `mercury/codemojex/**` + the rung's `docs/codemojex/` triad/ledger (+
  the ratified additive `mercury/packages/{mercury-core,mercury-effector,mercury-ui}/**` on a coupled rung). A
  change reaching an OUT-of-bounds dir (or an `echo/` edit) is a diff no one can review — STOP and re-scope.
- **Escalate, do not invent.** A spec⇄canon / spec⇄spec / spec⇄as-built contradiction STOPS and escalates to the
  Director; the canon is the authority; a deterministic re-grep/probe (the barrel export set, a `curl`/inject, a
  `package.json` read) closes every escalation. Ground every module / route / prop / token / table in a real file
  or a canon § — forward-tense for an unbuilt surface.
