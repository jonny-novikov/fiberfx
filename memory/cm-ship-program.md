---
name: cm-ship-program
description: "/cm-ship = AAW-light ship harness for mercury-side codemojex-node (mercury/codemojex/, the @codemojex/* Node/TS workspace); Mirror-Mercury team (cm-program floor + venus-cm/mars-cm + cm-backend capability); scope-negotiated boundary + lazy-loaded capability router; DISTINCT from /codemojex-ship (echo/ Elixir engine, cm.N)"
metadata: 
  node_type: memory
  type: project
  originSessionId: bcd9b57a-f3d4-44ec-bde7-93fbc0a81666
---

**`/cm-ship`** (built 2026-07-01) = the AAW-light ship command for **codemojex-node** — the Node/TypeScript
consumer at `mercury/codemojex/` (the `@codemojex/*` pnpm workspace: apps `admin`(Fastify) · `economy`/`game`
(React+@mercury) · `game-tauri`(Rust/Tauri, `src-tauri`) · `dashboard`(coming); packages `db`(Drizzle) ·
`domain` · `types`; root `@codemojex/node`, Node ≥20). **DISTINCT from `/codemojex-ship`** (the echo/ **Elixir**
engine at `echo/apps/codemojex`, slugs `cm.N`): `/cm-ship` NEVER edits `echo/` — it composes `@mercury/*` and
READS the echo/ engine's shared Postgres + `cm:<game>:*` Valkey substrate (a schema-coupling, not an HTTP call).

**Built Mirror-Mercury (2 Operator forks ruled):** (1) **edit surface** = `mercury/codemojex/**` primary +
ADDITIVE `@mercury/core`+`@mercury/effector` (the "core+fx") + ADDITIVE `@mercury/ui` (barrel-held), **scope
-negotiated per rung + Operator-ratified at Bootstrap** (the Director names the touched rings, `AskUserQuestion`
if ambiguous); (2) **shape** = floor + 2 roles.

**The skillset** (`.claude/skills/`): `cm-program.md` (the floor — negotiated island · the capability router ·
master laws [no-secret-on-wire · @mercury barrel-additive · token discipline · compose-the-mature-foundation] ·
`pnpm --filter @codemojex/*` gate · `docs/codemojex/specs/<chapter>/` spec home [aaw.specs-approach] · git
posture) · `venus-cm` + `mars-cm` (role skills, cite the floor) · `cm-backend.md` (the backend capability). The
generic `.claude/agents/venus.md`/`mars.md` charters gained a `## Codemojex-node program` section routing a
`docs/codemojex/specs/<chapter>/` rung → `venus-cm`/`mars-cm`.

**The capability router (lazy-load by domain = context economy):** backend → **read** `cm-backend.md`
(Fastify/Drizzle/Valkey/TypeBox + the no-secret-on-wire law + `app.inject` + boot-smoke); frontend → **Skill-load**
`venus-mercury`/`mars-mercury` (+ read `mercury-program.md`, + the `frontend-design` plugin); rust/tauri →
forward slot (the `graft-ship` cargo craft); elixir-coupled → read-only echo/ grounding (`@codemojex/db` Drizzle
vs the echo/ Ecto schema). **Bare-`.md` refs (`cm-program`, `cm-backend`, `mercury-program`) are READ by path;
only dir-based skills (`venus-cm`/`mars-cm`/`*-mercury`) are `Skill`-loaded** (the harness registers dir skills,
not bare `.md`).

**Slugs** = per-chapter `<chapter>.<n>` (`admin.1` · `economy.N` · `tauri.N` · `dashboard.N`), aaw scope
`codemojex-<chapter>`; NEVER `cm.N` (the echo/ engine's). **admin.1 SHIPPED 2026-07-01 (200362cd) — the inaugural run**, which grew from a backend auth rung into a full `@codemojex/db` read-model reconcile (the Drizzle schema was fiction-modeled "from observation" → verify columns against `information_schema` / the migration DDL, NEVER typecheck). **FLOOR CORRECTION: codemojex is a MEMBER of the `mercury/` pnpm workspace** (its `@echo/*` `workspace:*` deps live in `mercury/packages/`; `pnpm install` runs the whole mercury workspace + shares `mercury/pnpm-lock.yaml`) — cm-program's "installs independently" was WRONG, fixed. Apollo mentored the findings into venus-cm (verify-the-mirror + invariant-names-from-DDL) + mars-cm (reinforced: singleton test-lifecycle · escalate-infra+drift · live-proof-asserts) + cm-program (a new "verify a mirror against its source" law + substrate facts). Also fixed a stale `mercury/codemojex-node/apps/{economy,api}` → real
`mercury/codemojex/apps/{admin,economy,game,game-tauri}` across the mercury skills/charters.
[[codemojex-admin-program]] [[codemojex-program]] [[mercury-design-system]]
