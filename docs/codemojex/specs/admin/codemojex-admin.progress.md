# codemojex-admin — AAW scope ledger

## {codemojex-admin-decisions} Decisions

### D-1

admin.1 scope = the gated read foundation — Operator-ruled. This week ships admin.1: harden the as-built Fastify read plane (/health, rooms, games, players + live Valkey board) into a real operator API — auth-gated, TypeBox-typed, secret-never-on-wire, bootable solo + clustered, with tests. Management (admin.2), economy/treasury incl. cm.8 (admin.3), moderation (admin.4) ladder behind it. Rationale: the read foundation is the floor every later write/economy rung stands on.

### D-2

admin.1 auth = operator bearer token — Operator-ruled. The admin API currently has NO access control; admin.1 adds a Fastify preHandler checking a bearer against an env ADMIN_TOKEN (one shared operator credential, zero new deps). Coarse by design — per-operator identity/audit is deferred to a later rung. Chosen over the Telegram-admin allowlist (heavier: pulls in SES/initData verify) and over deferring auth (open API = weakest posture).

## {codemojex-admin-progress} Progress

### P-1

admin chapter authored + gated — sharpen complete. Wrote docs/codemojex/specs/admin/{admin.md (index), admin.roadmap.md, admin.1.md, admin.1.stories.md, admin.1.llms.md} to aaw.specs-approach.md. Six gates GREEN: voice · structure (6 §, 5 5W bullets) · traceability (Coverage + every INV encoded + R#[US:] + AS#[implements]) · fences · format via the sweep, and links via mcp__msh__specs (no findings). Grounded in the as-built Fastify app (server.ts buildServer, env.ts loadEnv, reply.ts send, schemas.ts, routes/{rooms,games,players}.ts, valkey.ts readBoard, cluster.ts runCluster) — no invention. admin.1 = the gated read foundation: a Fastify preHandler bearer gate (ADMIN_TOKEN, /health exempt) over the as-built read plane, secret-never-on-wire, boots green solo + clustered. NEXT (build stage): implement admin.1 (Mars) — pnpm install in mercury/codemojex (deps absent), env.ts adminToken, the preHandler, apps/admin/test/admin.test.ts app.inject suite, typecheck + boot smoke.
