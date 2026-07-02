---
name: cm-ship
description: >-
  Use this skill to ship ONE spec-driven rung of Codemojex Game in Javascript — the Bun/Node/TypeScript consumer at
  mercury/codemojex/ (the @codemojex/* pnpm workspace: apps admin · economy · game · game-tauri, +dashboard;
  packages db · domain · types), COUPLED to the @mercury/* design system it composes (and may additively extend:
  @mercury/core + @mercury/effector) and to the echo/ codemojex Elixir engine's shared Postgres + Valkey
  substrate it reads — any rung under docs/codemojex/specs/<chapter>/ (admin.* · economy.* · tauri.* ·
  dashboard.*), end to end through the AAW-light supervised loop to one ratifying mercury/codemojex/… +
  docs/codemojex/… pathspec commit. It is /x-mode with the codemojex-node context pre-loaded, run LIGHT
  (Mirror-Mercury: the venus-cm / mars-cm role team over the cm-program floor; Apollo mentor-only): it binds the
  laws to a NEGOTIATED island (the Director scopes the touched rings + domains from the Operator's request and
  ratifies before any spawn) and LAZY-LOADS the domain capability (cm-backend / frontend-mercury / rust-tauri /
  elixir-coupled) so a service rung never drags the design-system craft and a frontend rung never drags Fastify.
  The INPUT is the rung's chaptered triad (docs/aaw/aaw.specs-approach.md); the canon is
  docs/codemojex/codemojex.design.md (the shared substrate) + mercury.design.md (a coupled frontend). Triggers:
  "cm-ship admin.1", "ship the codemojex-node economy rung", "as Director ship the @codemojex admin rung". Do NOT
  use for the echo/ codemojex Elixir engine (/codemojex-ship, cm.N), the Mercury design-system packages
  (/mercury-ship, mx.N), the echo_mq bus (/echo-mq-ship), or the echo_graft engine (/graft-ship).
argument-hint: <chapter>.<n> (admin.1 · economy.N · tauri.N · dashboard.N) · a named scope · empty (the next unshipped rung per the chapter roadmap)
---

# CM-SHIP — ship a codemojex-node rung via the LIGHT supervised loop (Mirror Mercury)

Ship ONE spec-driven rung of **codemojex-node** — the `@codemojex/*` Node/TypeScript workspace at
`mercury/codemojex/`, the consumer that **composes** the `@mercury/*` design system and **reads** the echo/
codemojex engine's shared Postgres + Valkey substrate — end to end through the AAW loop, Director-supervised, to
one ratifying pathspec commit **when the Operator asks**. It is **`/x-mode` with the codemojex-node context
pre-loaded, run LIGHT**: it adds nothing to the laws — it binds them to a **negotiated island** and **lazy-loads
the domain capability** so the run does not re-derive them or drag the wrong craft into context.

**codemojex-node ≠ the echo/ codemojex engine.** `/cm-ship` ships the **Node** side (`mercury/codemojex/`,
`@codemojex/*`, chaptered slugs `admin.1` / `economy.N` / `tauri.N`); `/codemojex-ship` ships the **Elixir**
engine (`echo/apps/codemojex`, `cm.N`). `/cm-ship` **never edits `echo/`**.

**It is a binding layer, not a re-implementation.** Defer to the sources of truth:

1. **`.claude/commands/x.md` + the `/x-mode` skill** — the LAWS (CLAUDE_LAWS 1/1a/2/3/4), the pipeline
   (architect reconcile/author + Arms → Director rules the Arms via `AskUserQuestion` → implementor build +
   self-verify → Director verify → implementor harden → Director ship; the verifier on a high-risk rung), the
   §5 spawn protocol, the §6 audit tools, the §10 commit rules. **Read the `/x-mode` skill first** — the deltas
   below are the codemojex-node binding, and the topology router collapses it to a Duo/Trio for most rungs.
2. **The program floor** — `.claude/skills/cm-program.md` (the negotiated island, the capability router, the
   master laws, the `pnpm --filter @codemojex/*` gate ladder, the `docs/codemojex/specs/<chapter>/` spec home,
   the aaw ledger, the git posture). The role skills the peers load — `venus-cm` / `mars-cm` — cite it.
3. **The rung's spec** — the chaptered triad `docs/codemojex/specs/<chapter>/<rung>.{md,stories.md,llms.md}`
   (the `<rung>.md` body authoritative), authored to `docs/aaw/aaw.specs-approach.md`; the canon
   `docs/codemojex/codemojex.design.md` (the six-table substrate the node reads) + the chapter's
   `<chapter>.roadmap.md`; for a coupled frontend rung, `docs/mercury/mercury.design.md`.

## Arguments & scope

```
$ARGUMENTS
```

- **A RUNG** — `<chapter>.<n>` (`admin.1`, `economy.2`, `tauri.1`, `dashboard.1`) → ship it through the loop. The
  aaw `scope` (only when the rung stands up a team) is the **dashed** slug `codemojex-<chapter>`
  (`codemojex-admin`, never a dot — `^[a-z0-9][a-z0-9-]*$`), matching the on-disk `<scope>.progress.md` ledger.
- **A named scope** → a cross-cutting increment; reuse the exact existing ledger slug (a wrong slug mints a new
  empty ledger and strands the hand-written one).
- **Empty** → read the chapter's `<chapter>.roadmap.md` + `codemojex-<chapter>.progress.md` and ship the next
  **unshipped** rung in program order; if ambiguous, ask in plain text (do not guess a large scope).

## THE BOUNDARY — a NEGOTIATED island (read this first)

The git root is `jonnify` (the PARENT), holding ≥10 unrelated programs. codemojex-node treats the rest as if it
did not exist — **except** the two surfaces it is coupled to — and **each rung's actual touch is scoped from the
Operator's request at Bootstrap (§0) and ratified before any spawn** (the formation `tool_x_decision`). The rings
(`cm-program.md` § the boundary):

- **Primary (edit):** `mercury/codemojex/**` — the `@codemojex/*` apps + packages.
- **Coupled (edit, ADDITIVE):** `mercury/packages/mercury-core/` + `mercury/packages/mercury-effector/` (the
  **core + fx** foundation). A change to an *existing* core/fx export that `@mercury/ui`/`mercury/apps/*` consume
  **forks to `/mercury-ship`**.
- **Coupled (ADDITIVE, barrel holds):** `mercury/packages/mercury-ui/` — additive only; the barrel master
  invariant is re-checked (the **resolved** export set: 0 removed/renamed).
- **Read-only (grounding):** `echo/apps/codemojex` (the Ecto schema + the `cm:<game>:*` keyspace the node reads);
  `mercury/apps/*` (a `@mercury` call-site). Never edited — an `echo/` edit forks OUT to `/codemojex-ship`.
- **Out:** `html/ elixir/ go/ infra/ node/ tradex/ mcp/ bin/ scripts/ memory/ …` — never read, searched, built,
  or touched. Every `Glob`/`Grep`/`find` roots at `mercury/codemojex/` (or a ratified coupled ring); the gate is
  `pnpm --filter @codemojex/<app>`, NEVER a blind `pnpm -r`; the commit is a `mercury/codemojex/…` (+
  `docs/codemojex/…`, + the ratified additive `mercury/packages/…`) pathspec.

## Navigate the workspace (where everything lives)

| Need | Path |
|---|---|
| The apps (edit surface) | `mercury/codemojex/apps/{admin,economy,game,game-tauri}/src/` (+ `dashboard/` as it opens) |
| The shared packages | `mercury/codemojex/packages/{db,domain,types}/src/` |
| The composed foundation (compose / additive-extend) | `mercury/packages/{mercury-core,mercury-effector,mercury-ui}/src/` |
| The read-only substrate contract (the Ecto schema + keyspace) | `echo/apps/codemojex/lib/codemojex/` + `docs/codemojex/codemojex.design.md` |
| The chapter spec home | `docs/codemojex/specs/<chapter>/<rung>.{md,stories.md,llms.md}` + `<chapter>.roadmap.md` |
| The run ledger | `docs/codemojex/specs/<chapter>/codemojex-<chapter>.progress.md` |
| The workflow + spec-format contract | `docs/aaw/aaw.framework.md` + `docs/aaw/aaw.specs-approach.md` |
| The program floor + the role skills | `.claude/skills/cm-program.md` · `venus-cm` · `mars-cm` · `cm-backend` |

## The capability router — lazy-load by domain (the run's defining move)

The workspace spans a Fastify backend, React frontends, a Rust/Tauri host, and an Elixir data-coupling. `/cm-ship`
classifies the rung's domain(s) at Bootstrap and the peers load **only** the matching capability (read a
bare-`.md` reference by path; `Skill`-load a dir-based role skill) — context economy as a correctness lever:

| Domain | Triggered by | Lazy-loads | Adds to the gate |
|---|---|---|---|
| **backend** | `admin`, a `dashboard` API, a package doing Postgres/Valkey I/O | **`cm-backend`** (Fastify · Drizzle · Valkey · TypeBox · no-secret-on-wire) | the `app.inject` suite · the secret-strip assertion · the boot-smoke (solo + clustered) |
| **frontend / mercury** | `economy`, `game`, `dashboard` UI, a `game-tauri` web view | **`mercury-program` + `venus-mercury`/`mars-mercury`** + the model-invoked **`frontend-design`** plugin | the **barrel-diff** (resolved export set) on any `@mercury` touch · a token/no-raw-hex grep · the app's vitest |
| **rust / tauri** | `game-tauri` (`src-tauri`) | the Rust `graft-ship` cargo craft (a forward slot, filled when first worked) | `cargo build` + `cargo test` in `apps/game-tauri/src-tauri` |
| **elixir-coupled** | a feature binding the echo/ shared schema / keyspace | **read-only** grounding via `/codemojex-ship` + `echo/CLAUDE.md` | (echo/ not edited — an echo/ change forks to `/codemojex-ship`) |

## What is different from a generic /x-mode run (the codemojex-node binding)

- **The team is LIGHT + role-specialized (Mirror Mercury).** Spawn each peer `subagent_type: "general-purpose"`
  and adopt its `.claude/agents/<role>.md` charter; on a codemojex-node rung the charter routes the architect +
  implementor to the **cm role skills** (the same way an `mx.*` rung routes to `*-mercury`), both standing on the
  shared floor `.claude/skills/cm-program.md`:
  - **the architect** = `venus` → **loads `venus-cm`** — classifies the domain + loads the capability lens, the
    lag-1 capability-scoped reconcile against as-built `@codemojex`, authors the chaptered triad
    (aaw.specs-approach), surfaces the scope/schema/`@mercury`/dependency forks.
  - **the implementor** = `mars` → **loads `mars-cm`** — builds to the brief inside the ratified scope, loads the
    capability craft (`cm-backend` / `mars-mercury` / cargo / echo-grounding), runs the gate. Two-pass.
  - **the verifier + mentor** = `apollo` (the generic charter, loading `cm-program` + the rung's capability) —
    the in-pipeline verifier **only on a high-risk rung**; on every rung the standing post-ship MENTOR
    (PROPOSE-ONLY, Director-ratified). The peers self-register via `mcp__aaw__agent_register` (LAW-1; no narrated
    spawns).
- **Spawn resilience — write-ready dispatch (x.md §5 LAW-1b).** A peer dies to `ECONNRESET` on a long read-heavy
  run (files survive; the report does not). The Director pre-grounds every dispatch — front-load the signatures,
  paths, import convention, a usage sketch, the gate — so the peer's first actions are WRITES; cap required
  reading at ≤2–3 named files; split a heavy rung into short waves; recover from the tree on a death.
- **The master laws bind by domain** (`cm-program.md` § the laws): **backend** — no data route answers
  unauthenticated + no `secret`/`keyboard` on the wire (an `app.inject` proof). **frontend** — the `@mercury/ui`
  barrel is additive-only (the resolved export set); token discipline (no raw hex); compose the mature
  foundation. **elixir-coupled** — a `@codemojex/db` schema drift from the echo/ Ecto schema is closed IN
  `@codemojex/db`, never by editing `echo/`.
- **The gate ladder is the codemojex-node one, run from `mercury/codemojex/`** (NEVER `pnpm -r`): `pnpm install`
  → `pnpm --filter @codemojex/<app> typecheck` + `build` + `test` → the capability-specific gate (the inject
  secret-strip + boot-smoke · the barrel-diff · cargo). Node ≥20, no `TMPDIR`.
- **The risk tier decides the verify depth + the formation.** HIGH-risk: a `@codemojex/db` schema/migration
  (coupled to echo/), a `@mercury/ui` barrel touch, a treasury/cash-out rung (the `cm.8` coupling), an auth
  surface, an external-wire cutover → **Squad** (the verifier mandatory, the deepened verify — the resolved
  barrel-diff / a migration up-down proof / a mutation battery). A pure-read / additive read plane / a single
  frontend view / docs is **NORMAL** → Trio (or Duo).

## Topology router — right-size the LIGHT formation (rigor constant, ceremony scales)

| Formation | Active roles | Use when |
|---|---|---|
| **Duo** | Director + **one** peer | A single-concern increment — a docs/spec author or **reconcile**, or an already-green rung needing only the independent verify. No aaw team needed. |
| **Trio** | Director + `venus-cm` + `mars-cm` *(two-pass)* | The standard **NORMAL** rung: architect reconcile/author + Arms → Director rules → implementor build + self-verify → Director verify → implementor harden. The Director's solo verify is the gate. |
| **Squad** | Director + `venus-cm` + `mars-cm`(-1/-2) + **verifier** (`apollo`) | The **HIGH-risk** rung (a schema/migration, a barrel touch, a treasury rung, an auth surface). Adds the dedicated verifier + the deepened verify. |

**Apply at Bootstrap (§0), before any spawn:** floor by risk (HIGH → Squad, verifier mandatory); collapse by
build-state (a built-and-green increment re-spawns **no builder** — only the remaining verify/harden/ship legs).
If the rung stands up an aaw team, `mcp__aaw__status(scope)` must then show EXACTLY the chosen tier's peers.

## 0. Bootstrap (Director, before any spawn) — SCOPE the island, CLASSIFY the domain

Read the rung's chaptered triad + the chapter roadmap + the canon `codemojex.design.md` (+ `mercury.design.md`
for a coupled frontend) + **the `/x-mode` skill** + `cm-program.md` + `docs/aaw/aaw.framework.md`. Then the two
moves that make this program:

1. **Scope the island — from the Operator's request, ratified.** Name the touched rings: the primary
   `@codemojex/<app>`(s), and which coupled `@mercury` rings the rung needs (none / core+fx additive / a
   `@mercury/ui` additive). Confirm every read/search so far stayed inside the ratified rings. **When the request
   is ambiguous about the rings or a coupled `@mercury` touch, STOP and `AskUserQuestion`** — the boundary is
   Operator-ratified, recorded as the formation `tool_x_decision`. (A `@mercury/ui` barrel touch or a
   `@codemojex/db` schema change escalates the risk tier.)
2. **Classify the domain — lazy-load plan.** Map the rung to backend / frontend-mercury / rust-tauri /
   elixir-coupled (§ the capability router); the peers will load ONLY those capability skills. Declare the mode
   (**AAW-light**) + the topology tier (Duo/Trio/Squad) from risk × build-state, recorded as the formation
   decision.

Deep-reason the rung (the `/x-mode` §0: the 5W, the solution space incl. a do-nothing baseline, the invariants as
runnable gates — the inject secret-strip, the barrel-diff, the boot-smoke — the smallest change that preserves
correctness). **Confirm the Stage-1 gate is reachable** — the triad exists (or `venus-cm` authors it) and any
open Operator fork is resolvable. Note the toolchain: Node ≥20, `pnpm install` (this sub-workspace installs
independently), Valkey :6390 + Postgres reachable for a service rung's boot-smoke.

## 1. Run the pipeline (per `/x-mode`, codemojex-node-bound & light-collapsed)

For a **Squad** rung, stand up the aaw team per `/x-mode` §1 (`mcp__aaw__init` → spawn+register the `director` →
`TeamCreate(codemojex-<chapter>)` → open the ledger). For a **Duo/Trio**, the Director spawns the one or two peers
directly. **zsh does not word-split unquoted vars** — iterate file lists with `find … -print0 | while IFS= read
-r -d '' f`.

Lift each stage's directive from the rung's `.llms.md` (or the Stage-1 `venus-cm` brief); wrap each spawn in the
`/x-mode` §3 per-spawn ceremony + "Read and operate by `.claude/agents/<role>.md`; load `<the rung's capability
skill(s)>`; stay inside the ratified scope; the gate is `pnpm --filter @codemojex/<app>`, never `pnpm -r`."

**venus-cm** (classify + load the capability lens → reconcile the triad lag-1 against as-built `@codemojex` →
author the chaptered triad + the build brief; frame scope/schema/`@mercury`/dependency forks as four-part Arms)
→ **Director rules the Arms** (the mandatory `AskUserQuestion` — a fork is never decided silently) →
**mars-cm-1** (load the capability craft; build to the brief inside the ratified scope — the real `@codemojex` /
`@mercury` / `@codemojex/db` surface only, **no invented route/prop/column**; run the gate) → **Director verify**
(a REAL pass: a fresh reconcile + an **independent gate re-run** — `pnpm --filter` typecheck + build + test + the
capability gate [the inject secret-strip + boot-smoke · the resolved barrel-diff] — + ≥1 adversarial probe + a
**mutation spot-check**: Edit-in → test/typecheck-catches → revert → `git diff --stat` clean **net-zero**,
LAW-1a) → **mars-cm-2** (resume the same identity — remediate + harden + the full gate; REMEDIATE loop MAX 3) →
**verifier (`apollo`)** *(HIGH-risk only)* (the post-build reconcile + the adversarial capability verify + a
mutation kill-rate; resolve every ambiguity with the Operator via `AskUserQuestion`; spec-sync; **BUILD-GRADE /
BLOCKED**) → **Director ship** (the solo ship-gate + the commit when asked + the record fold). On a NORMAL rung
`apollo` is out of the pipeline — it mentors after the ship (PROPOSE-ONLY, Director-ratified).

## 2. The commit (Director-only, per x.md §10 — only when the Operator asks)

At ship: the Director's verify clean + the codemojex-node gate green (+ on a HIGH rung, the verifier BUILD-GRADE);
`git status --short` AND `git diff --cached --name-only` reviewed; `.git/rebase-merge` / `rebase-apply` checked.
Then a **pathspec** commit — `git add <explicit rung paths>` then `git commit -F <msg> -- <those paths>`; **NEVER
`git add -A`, NEVER a bare commit** (the git root is `jonnify`; the Operator pre-stages out-of-band). The rung
commit is the rung's **measured surface ONLY** — `mercury/codemojex/**` (+ the ratified additive
`mercury/packages/{mercury-core,mercury-effector,mercury-ui}/**` on a coupled rung) + the rung's
`docs/codemojex/specs/<chapter>/` triad + the `codemojex-<chapter>.progress.md` ledger. **When the tree is
entangled** (a sibling-program edit, staged infra), commit those as **separate scoped commits per concern**. The
message ends with the `Co-Authored-By: Claude Fable 5` trailer. **Do not push unless asked.** **Record fold:**
flip the rung's status in the chapter `<chapter>.roadmap.md` (+ the index `<chapter>.md`), backward-reconcile the
rung `.md` to the green as-built surface, and surface the next frontier.

## 3. Quality gate (before ship)

- [ ] The chaptered triad + the canon + the chapter roadmap + `cm-program.md` + the `/x-mode` skill +
      `aaw.framework.md` read; the **island scoped + Operator-ratified** (the rings recorded as a decision); the
      **domain classified + the capability lazy-load plan** declared; mode AAW-light; the topology tier recorded.
- [ ] **Every read/search/edit stayed inside the ratified rings** — `mercury/codemojex/**` (+ the ratified
      `mercury/packages/…`) + `docs/codemojex/**` + `docs/aaw/**`; no OUT-of-bounds dir, no `echo/` edit.
- [ ] Every peer is a REAL self-registered `Agent` spawn (`general-purpose` + the venus/mars/apollo charter +
      the cm role skill + only the rung's capability skill(s); no FAKE-N); the Director called no Edit/Write on
      production code EXCEPT a mutation spot-check reverted **net-zero** (LAW-1a); every design Arm was ruled via
      `AskUserQuestion` before the build.
- [ ] The codemojex-node gate is green, run from `mercury/codemojex/`: `pnpm install` + `pnpm --filter
      @codemojex/<app>` typecheck + build + test + the capability gate (the inject secret-strip + the boot-smoke
      · the resolved barrel-diff: 0 removed/renamed · cargo). **No blind `pnpm -r`.**
- [ ] The boundary holds: only the ratified rings changed; a `@mercury` touch was additive (barrel held); no
      `@codemojex/db`↔echo/ schema drift left open.
- [ ] Commit (if asked): exactly one Director pathspec commit **per concern**; nothing foreign in `--cached`; the
      chapter fold landed.
- [ ] (Squad) `mcp__aaw__status(scope)` shows EXACTLY the chosen topology tier's peers (no FAKE-N).

## 4. Map

- The laws + pipeline: `.claude/commands/x.md` + the `/x-mode` skill. The reconcile differ:
  `.claude/commands/reconcile.md`. The charters the peers wrap: `.claude/agents/{venus,mars,apollo}.md`.
- The program floor + the role/capability skills: `.claude/skills/cm-program.md` · `venus-cm` · `mars-cm` ·
  `cm-backend` (+ the referenced `mercury-program`/`*-mercury`, `frontend-design`, `graft-ship`, `codemojex-ship`).
- The workflow + the spec-format contract: `docs/aaw/aaw.framework.md` + `docs/aaw/aaw.specs-approach.md`.
- The canon (the shared substrate) + the chapter homes: `docs/codemojex/codemojex.design.md` ·
  `docs/codemojex/specs/<chapter>/`. For a coupled frontend: `docs/mercury/mercury.design.md`.
- The code (the boundary): `mercury/codemojex/{apps,packages}/` (+ the coupled `mercury/packages/*`).
- The run's audit trail: the rung's `codemojex-<chapter>.progress.md` + `mcp__aaw__status`.
