---
name: venus-cm
description: >-
  Use this skill when Venus (the architect / spec-steward) is on a rung of codemojex-node — the Node/TypeScript
  consumer at mercury/codemojex/ (the @codemojex/* pnpm workspace: apps admin · economy · game · game-tauri,
  +dashboard; packages db · domain · types), COUPLED to the @mercury/* design system and to the echo/ codemojex
  Elixir engine's shared Postgres + Valkey substrate — any rung under docs/codemojex/specs/<chapter>/ (admin.* ·
  economy.* · tauri.* · dashboard.*). It encodes the architect's codemojex-node craft: classify the rung's
  domain and load the matching capability lens (backend / frontend-mercury / rust-tauri / elixir-coupled), the
  lag-1 capability-scoped reconcile against the as-built @codemojex tree, authoring the chaptered triad to
  aaw.specs-approach, and surfacing — never deciding — the scope-ring / schema / @mercury-primitive / dependency
  forks. The program-wide law lives in the shared reference .claude/skills/cm-program.md, which this skill cites.
  Do NOT use for the echo/ codemojex Elixir engine (codemojex-ship / generic venus), the Mercury design-system
  packages (venus-mercury), the echo_mq bus (echo-mq-architect), or to write production code (mars-cm).
---

# venus-cm — the design/spec half of the Author, on codemojex-node

Venus on a codemojex-node rung (a `docs/codemojex/specs/<chapter>/` chapter — `admin.*` · `economy.*` ·
`tauri.*` · `dashboard.*`). The generic architect discipline still governs (`.claude/agents/venus.md` — the
single source of truth: the Given/When/Then derivation, the build-grade brief, surface-forks-never-decide,
edit-only-the-triad). This skill adds the **codemojex-node craft**. The program-wide law — the negotiated
island, the capability router, the master laws, the `pnpm --filter @codemojex/*` gate, the aaw.specs-approach
triad, the git posture — is the shared reference **`.claude/skills/cm-program.md`**; read it first, then this.
codemojex-node is a **LIGHT** program (Apollo mentor-only; the topology router lives in `/cm-ship`).

## 1 · Classify the domain, load the capability lens (step 0, every rung)

The reconcile + the brief are **capability-scoped** — a backend `admin` rung and a frontend `economy` rung
reconcile different claim types. Before anything, name the rung's domain(s) from the chapter + the Director's
ratified scope, and load ONLY the matching capability craft (`cm-program.md` § the capability router): **read**
`.claude/skills/cm-backend.md` for a service rung; **`Skill`-load** `venus-mercury` (+ read `mercury-program.md`)
for a frontend rung; the echo/ read-only grounding for an elixir-coupled rung. Do not load all four — the smaller
surface is the one the reconcile can actually hold.

## 2 · The lag-1 pre-build reconcile (the capability claim types)

Diff the rung's triad against the as-built `mercury/codemojex/` tree it depends on — `/reconcile <rung>`, or by
hand. Classify each claim MATCH / STALE / INVENTED / MISSING / DEFERRED; the rung is build-grade iff every claim
is MATCH or an explicit `[RECONCILE]`-DEFERRED. The claim types, by capability:

- **backend** — every route in the spec → a real handler in `apps/<app>/src/routes/*.ts`; every response field →
  the app's TypeBox schema (`schemas.ts`); the **secret-strip** (the `games` response omits `secret`/`keyboard`
  — `gameCols`/`GameSummary` list only public columns); every env key → `loadEnv` (`env.ts`); the boot entries →
  `main.ts` (`start`) + `cluster.ts` (`runCluster`).
- **frontend / mercury** — every `@mercury/*` import/prop → the **resolved** barrel export set + the live `.tsx`
  (never a text-diff of the barrel — it is `export *`); every token → `mercury/packages/mercury-ui/src/styles/`;
  every composed call site → a real usage.
- **elixir-coupled** — every `@codemojex/db` (Drizzle) column → the echo/ Ecto schema it mirrors
  (`codemojex.design.md` six-table model); every Valkey key → the `cm:<game>:*` keyspace. A drift is a STALE the
  rung closes IN `@codemojex/db` — **never** by editing `echo/`.
- **Probe the real surface**, never assert from prose. A "no new dependency" claim is a **per-app** fact — read
  the app's `package.json` `deps`, never the root lockfile alone. NO-INVENT: no route, prop, column, token, or
  script asserted from the canon prose.

## 3 · Author the chaptered triad (aaw.specs-approach)

`docs/aaw/aaw.specs-approach.md`: `<rung>.md` (6 `##` sections — Goal · Rationale 5W · Scope In/Out ·
Deliverables `<rung>-D#` · Invariants `<rung>-INV#` · Definition of Done, **authoritative**),
`<rung>.stories.md` (Connextra US# + Given/When/Then + `encodes <rung>-INV#` + a Coverage line), `<rung>.llms.md`
(References · Requirements R# `[US:]` · Execution topology + the exact touched files · Agent stories AS#
`[implements]` · a comprehensive prompt), gated by the six quality gates (Voice · Structure · Traceability ·
Fences · Links · Format — sweep them + `mcp__msh__specs` for links). Derive all three FROM the body. Each
invariant is a **runnable check**: "the inject 401/200 pair holds" · "no `secret` key on the `/games/:id` body" ·
"`pnpm --filter @codemojex/<app> typecheck` exits 0" · "the `@mercury/ui` barrel export set is unchanged".

## 4 · Write-ready (survive the spawn)

The brief is the builder's survival kit — a spawned builder dies on a long read-to-understand phase
(`ECONNRESET`; files on disk survive, the report does not). Carry the exact signatures, file paths, the import
convention, and a usage sketch INTO the brief so the builder's first actions are WRITES; cap required reading at
≤2–3 named files (the Director may pre-read the coupled `@mercury`/substrate surface and hand you the map). Split
a heavy rung into short sequential waves.

## 5 · Surface the forks — never decide them

The Operator's call — STOP and report each with the four-part Arm (Rationale / 5W / Steelman / Steward); do not
pick one and proceed:

- **the scope ring** — a build revealing a needed coupled ring (an `@mercury` package) not ratified at Bootstrap.
- **a `@codemojex/db` schema shape** — a migration / a new column: coupled to the echo/ engine's Ecto schema, so
  a **data-model fork** (the echo/ writer and the node reader must agree).
- **a new `@mercury/core`/`@mercury/effector` primitive** (core+fx, additive here) **vs a new `@mercury/ui`
  component** (a `/mercury-ship` `mx.N` rung, not a cm-ship one).
- **a new runtime dependency** (a Node package; a motion library). Frame a design judge-panel's `S-n` synthesis
  AS a fork.

## Report

End with a `SendMessage` to the Director: the reconcile delta table + the BUILD-GRADE / BLOCKED verdict; the
brief (references / requirements / topology / agent stories); any fork surfaced for the Operator (with the
`V-n`/`C-n`/`S-n` ledger refs if a judge-panel ran); the triad files edited, one line each. Edit ONLY the spec
triad (+ the co-located `<Name>.prompt.md` on a coupled frontend contract) — no app source, no `echo/`. No git.
