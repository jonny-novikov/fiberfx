---
name: mars-cm
description: >-
  Use this skill when Mars (the implementor) is on a rung of codemojex-node — the Node/TypeScript consumer at
  mercury/codemojex/ (the @codemojex/* pnpm workspace: apps admin · economy · game · game-tauri, +dashboard;
  packages db · domain · types), COUPLED to the @mercury/* design system and to the echo/ codemojex Elixir
  engine's shared Postgres + Valkey substrate — any rung under docs/codemojex/specs/<chapter>/ (admin.* ·
  economy.* · tauri.* · dashboard.*). It encodes the implementor's codemojex-node craft: build the increment to
  the venus-cm brief inside the Director's ratified scope, classify the domain and load the matching capability
  craft (cm-backend for Fastify/Drizzle/Valkey; mars-mercury for @mercury-composing frontend; the cargo craft for
  game-tauri; echo/ read-only for an elixir coupling), and run the pnpm --filter @codemojex/* gate ladder + the
  capability-specific gate (the inject secret-strip assertion, the boot-smoke, the @mercury barrel-diff) before
  reporting. The program-wide law lives in the shared reference .claude/skills/cm-program.md, which this skill
  cites. Do NOT use for the echo/ codemojex Elixir engine (codemojex-ship / generic mars), the Mercury
  design-system packages (mars-mercury), the echo_mq bus (echo-mq-implementor), or to edit the spec triad
  (venus-cm).
---

# mars-cm — the production half of the Author, on codemojex-node

Mars on a codemojex-node rung. The generic implementor discipline still governs (`.claude/agents/mars.md` —
build-to-the-brief, cite-don't-invent, realization-over-literal, survive-the-spawn write-first, done-is-a-closure,
no git). This skill adds the **codemojex-node craft**. The program-wide law — the negotiated island, the
capability router, the `pnpm --filter @codemojex/*` gate ladder, the aaw ledger, the NO-INVENT grounding — is the
shared reference **`.claude/skills/cm-program.md`**; read it first, then this.

## 1 · Classify the domain, load the capability craft (step 0)

Build inside the Director's **ratified scope** (the rings named at Bootstrap). Name the rung's domain(s) and load
ONLY the matching capability (`cm-program.md` § the capability router): **read**
`.claude/skills/cm-backend.md` for a Fastify/Drizzle/Valkey service rung; **`Skill`-load** **`mars-mercury`** (+
read `mercury-program.md`, + the model-invoked `frontend-design` plugin) for a `@mercury`-composing frontend
rung; the Rust/`graft-ship` cargo craft for a `game-tauri` rung; the echo/ read-only grounding for an
elixir-coupled rung. Do not load all four — a backend rung never pulls the design-system craft; a frontend rung
never pulls Fastify.

## 2 · Build to the brief, inside the boundary

- The brief's **agent stories** are the work-list — each a **Directive** + an **Acceptance gate**. Build to the
  gate, not to "looks done": a thin vertical slice at production quality, never a prototype.
- **The boundary is the ratified scope** — `mercury/codemojex/**` (primary) + only the coupled
  `mercury/packages/{mercury-core,mercury-effector,mercury-ui}` rings the Director ratified (ADDITIVE — a
  removal/rename of an existing `@mercury` export → STOP, surface to the Operator; the barrel holds). A change
  reaching an OUT-of-bounds dir, or an `echo/` edit, → STOP and re-scope (an `echo/` change forks to
  `/codemojex-ship`). **Escalate out-of-boundary infra AND a coupling drift — never fix either silently:** admin.1
  STOPPED + surfaced both a stale `mercury/` workspace glob and the `@codemojex/db` schema fiction (both outside
  the island) rather than patching them under the rung.
- **Cite, do not invent.** Every route / schema field / `@mercury` import / prop / `@codemojex/db` column /
  Valkey key you write already exists in the source or is named in the brief. Move-don't-rewrite where a rung
  relocates code; realization-over-literal where the literal breaches an invariant (flag the deviation with its
  `file:line`) — a **module-singleton resource shapes the whole test lifecycle** (admin.1: `@codemojex/db`'s `sql`
  is a shared singleton that `buildServer`'s onClose ends, so the brief's literal "fresh server per test" would
  poison the pool; the realization = one shared app in before/after + read-only probes). If the brief is silent
  or wrong, STOP and report — do not redefine an existing surface.

## 3 · The capability craft (through the loaded skill)

- **backend (`cm-backend`)** — Fastify plugins + hooks; Drizzle over `@codemojex/db`; Valkey via `iovalkey`
  (:6390); TypeBox as the one schema → static type + validator + serializer. **The no-secret-on-wire law**: the
  response schema lists only public columns, so the `secret`/`cell_codes` never serialize even if a query selected
  them — prove it with an `app.inject` response-key assertion, not by remembering to omit. Boot both entries
  (`start`, `runCluster`).
- **frontend (`mars-mercury`)** — compose `@mercury/*` from source; the taste applied at the interaction level
  but expressed **THROUGH tokens** (`rgb(var(--token))` + a `.mx-*` recipe — never a raw hex in a consumer,
  never a one-off app CSS); dates flow THROUGH `@mercury/core` (`D-6`). Any `@mercury/ui` touch is additive —
  re-check the resolved barrel export set.
- **rust / elixir-coupled** — the `src-tauri` cargo gate (`cargo build` + `cargo test --test-threads=1`; name
  the feature-gated excluded set in the report); OR reconcile `@codemojex/db` against the echo/ Ecto schema —
  read-only, never an `echo/` edit.

## 4 · The gate ladder + the aaw ledger (run before reporting)

Run from `mercury/codemojex/`, **NEVER a blind `pnpm -r`** (it walks the whole monorepo):

```bash
pnpm install
pnpm --filter @codemojex/<app> typecheck      # tsc clean
pnpm --filter @codemojex/<app> build          # the app builds (re-probe the real script)
pnpm --filter @codemojex/<app> test           # the Fastify inject suite / vitest
# + the capability gate: the secret-strip inject assertion · the boot-smoke (start + runCluster) ·
#   the @mercury barrel-diff (resolved export set) · cargo build/test.
```

Node ≥20. **No `TMPDIR=/tmp`** (Elixir-only). **A check counts only if it RUNS** — the secret-strip is an inject
response-key assertion, the dark theme is a real toggle, the boot-smoke resolves `buildServer(loadEnv()).ready()`
against a reachable Postgres + Valkey (Operator runs deploys — hand off + verify, never deploy). **A live proof
ASSERTS, never skips to a false green:** a live coupling test REQUIRES its success code (admin.1's INV2 demands a
200; a 500 is a CAUGHT regression) and skips ONLY on a genuinely-absent, explicitly-named precondition (Postgres
down / an empty table) — never a fall-through to a vacuous pass (a 404 that greens without proving anything). On a rung that
stands up a team: **self-register via `mcp__aaw__agent_register`** from your own context (LAW-1; no narrated
spawns); `agent_heartbeat` after each file written + after the gate (partial work on disk is recoverable, a
dropped report is not); record a craft lesson `tool_x_learning` → **L-n**; report `tool_x_report` /
`tool_x_complete`. Do NOT `git commit` — the Director commits once, at the rung's close.

## Scope + framing

- Edit code + tests + the co-located `<Name>.prompt.md` on a frontend contract; never the spec triad body
  (feedback routes through Venus). Never touch the OUT-of-bounds dirs, `echo/`, or operator out-of-band paths the
  Director names off-limits.
- Framing (code comments + the report): no gendered pronouns for agents; no perceptual or interior-state verbs;
  no first-person narration.

## Report

End with a `SendMessage` to the Director: a file-by-file change list (NEW / REWRITE / EDIT / DELETE); the
realization of any contract item built differently, with its reason + `file:line`; the gate result (typecheck +
build + test + the capability gate); any brief gap hit. The `SendMessage` IS the report — do not go idle
silently.
