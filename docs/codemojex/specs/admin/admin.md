# admin · the codemojex operator control plane

The spec chapter for **`@codemojex/admin`** (`mercury/codemojex/apps/admin/`) — a Fastify + Drizzle + Valkey
operator API over the codemojex system of record. Postgres (`@codemojex/db`) is the record; Valkey (`:6390`) is
the read-only live board; the API browses rooms, games, and players, performs explicit management, and never
serializes a game's secret.

Roadmap: [`admin.roadmap.md`](./admin.roadmap.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md)

## The value ladder

| Rung | Ships | Deliverable arc |
|---|---|---|
| [admin.1](./admin.1.md) | the gated read foundation | bearer gate + hardened read plane (health · rooms · games · players · board) + secret-strip proof + boots green |
| admin.2 | lifecycle management | open / close / void a game, create + configure a room (the explicit management endpoints) |
| admin.3 | the economy & treasury desk | balances, the `TXN` + `RVL` ledgers, cm.8 withdrawal review + approve |
| admin.4 | players & moderation | player detail, membership (`RMP`), adjust / ban, the append-only analytics view (`AEV`) |
| admin.5 | the console UI (optional) | a Mercury-UI frontend over the admin API |

## The master invariant

**No secret on the wire, and no data route answers unauthenticated.** Every rung holds two properties: a game's
server-side `secret` (and its `keyboard` snapshot) is never serialized on any response, and every data route
requires the operator credential — only the `/health` liveness route answers without it.

## The closed error set

The wire error is `{ "error": <string> }` (the `ErrorResponse` schema). The fixed status vocabulary — a rung adds
no new reason:

| Status | Reason | Source |
|---|---|---|
| 401 | UNAUTHORIZED — absent or wrong operator credential | the admin.1 bearer gate |
| 400 | BAD_REQUEST — schema-invalid params / query / body | `reply.badRequest` · TypeBox validation |
| 404 | NOT_FOUND — no such row | `reply.notFound` |
| 500 | INTERNAL — an unexpected throw | Fastify default |

## The architecture decision (inherited by every rung)

- **Schema-driven routes.** One TypeBox schema per route (`schemas.ts` + the `@fastify/type-provider-typebox`
  provider) yields the static type, the request validator, and the response serializer; a response schema lists
  only public columns, so `fast-json-stringify` strips a withheld field at the wire.
- **Postgres is the record; Valkey is the read board.** Reads and management go through `@codemojex/db` (Drizzle);
  a game's leaderboard is read from Valkey `board:<gameId>` via `readBoard`. The admin never scores.
- **Result-typed handlers.** A handler returns `Result<T, ApiError>`; `send` (`reply.ts`) maps the error arm to
  `reply.code(status).send({ error })` and returns the success arm through the route schema.
- **Boots solo and clustered.** `start` (`main.ts`) is the single process; `runCluster` (`cluster.ts`,
  `@echo/cluster`, `node` backend) warms (`buildServer` + `ready`) then serves across cores. `buildServer` never
  listens.

Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md) · Roadmap: [`admin.roadmap.md`](./admin.roadmap.md)
