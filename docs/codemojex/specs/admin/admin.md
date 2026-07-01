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
| [admin.5](./admin.5.md) | **the dashboard Shell — BUILT** | the `@codemojex/dashboard` SPA skeleton (Vite + React, composing `@mercury/ui` + `@mercury/effector`): an operator shell layout, the Bearer-gated admin API client, and ONE end-to-end DB view (games), on a two-clock data seam (HTTP now, effector `channel` later) |
| [admin.5.1](./admin.5.1.md) | **rooms + players list desks — BUILT** | the two remaining list views over the Shell (`@mercury/ui` `Table`), client-side search + pagination — the read plane's full browser surface; frontend-only, no open fork |
| [admin.5.2](./admin.5.2.md) | **master-detail — BUILT** | room / player detail (`GET /:id`) on a selected-id + keyed-detail seam (selection-filtered), rendered in a side pane beside the narrowed list (ruled Arm C) — the seam admin.5.3 extends |
| admin.5.3 | the live game path | room → game → the embedded `@codemojex/game` live view, split game / events; subsumes the old live-pubsub slot — forks (embed / spectator bridge / split) in [`admin.5.desks.design.md`](./admin.5.desks.design.md) |
| admin.5.4 | PROPOSED forward slot | undescribed by the Operator; two candidates sketched (cross-desk observability · operator actions) — needs confirmation |

**Two tracks.** Milestone A (admin.1–4) is the **backend** control plane — the gated Fastify read plane and its
write / economy / moderation desks. Milestone B (admin.5, then the admin.5.1–5.4 desk ladder) is the **operator
console** — a `@codemojex/dashboard` React SPA over that same read plane. The Shell (admin.5) shipped; the desk
ladder fills it (admin.5.1 list desks → admin.5.2 master-detail → admin.5.3 the live game path → admin.5.4 a
proposed slot), with the fork-heavy rungs framed in [`admin.5.desks.design.md`](./admin.5.desks.design.md). The
console composes `@mercury/ui` (mature; the Shell houses no reusable component) and seats its future live feed on
`@mercury/effector`'s `channel` adapter. The console reads only the
`@codemojex/admin` API; the `@codemojex/economy` app is a separate **static** `/economy` calibration console with
no API (a structural sibling, not a data source), and is distinct from admin.3's economy & treasury **desk**.

## The master invariant

**No secret on the wire, and no data route answers unauthenticated.** Every rung holds two properties: a game's
server-side `secret` (and its `cell_codes` keyboard snapshot) is never serialized on any response, and every data route
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
