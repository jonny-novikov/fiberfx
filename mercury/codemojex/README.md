# codemojex-nodejs

A type-safe **Fastify** backend and TypeScript libraries that scaffold the `/api` for the
Codemojex Postgres model — the schema derived from the Ecto definitions in
`echo/apps/codemojex` (six tables: `players`, `transactions`, `emoji_sets`, `rooms`, `games`,
`guesses`). One source of truth flows the whole way: **Drizzle schema → zod DTOs → Fastify
route types**, so a column change surfaces as a compile error in the routes.

## Layout (npm workspaces)

```
codemojex-nodejs
├─ packages/
│  ├─ types/   @codemojex/types — branded ids ({ns}{base62}) + domain enums (no deps)
│  ├─ db/      @codemojex/db    — Drizzle pg schema (the 6 tables) + pool/client + drizzle-kit
│  └─ dto/     @codemojex/dto   — zod DTOs derived from the Drizzle tables (drizzle-zod)
└─ apps/
   └─ api/     codemojex-api    — the Fastify server: zod type provider + /api routes + Swagger
```

The packages export their TypeScript source directly (internal-package pattern); only the
`api` app is built (with `tsup`, which bundles the `@codemojex/*` sources).

## Stack

`fastify@5` · `fastify-type-provider-zod@7` · `zod@4` · `drizzle-orm@0.45` + `drizzle-zod@0.8`
(Postgres via `pg`) · `@fastify/swagger` + `@fastify/swagger-ui` · `@fastify/sensible` · `@fastify/cors`.

## The data model

The Drizzle schema in `packages/db/src/schema.ts` mirrors the Ecto migrations exactly — column
names are snake_case to match the existing database, the `bigint` balance columns carry the
`players_non_negative` CHECK, `games` carries the `games_type` / `games_status` /
`*_revenue_pct_range` CHECKs, and the partial unique indexes (`players_tg_user_id_index`,
`transactions_buy_in_once_index`) reproduce their `WHERE` predicates. `drizzle-kit generate`
emits this as `packages/db/drizzle/*.sql`.

Branded ids are the BCS `{ns}{base62}` strings `echo_data` mints — `PLR` players, `ROM` rooms,
`GAM` games, `GES` guesses, `EMS` emoji sets, `TXN` transactions — typed nominally in
`@codemojex/types` and validated in path params by `@codemojex/dto`.

Where Postgres enforces a value set with a CHECK (`games.type`, `games.status`) — and for
`transactions.currency` (one of the five balance columns) — the DTOs use a `z.enum`. The
softer policy columns (`feedback`, `scoring`, `settlement`, `economy`, `rooms.status`) are
plain `text` in the DB, so the DTOs keep them as strings; the known values live as union types
in `@codemojex/types` for editor help.

**Server-side game fields never leak.** `games.secret`, `games.commitment` and `games.nonce`
are columns the engine writes but no player sees. The public read DTO (`Games.gamePublic`)
omits them, and because the zod serializer parses every response through that schema, those
columns are stripped from `GET /api/games` and `GET /api/games/:id` even though the query
selects the full row.

## The /api surface

| Resource | Routes |
|----------|--------|
| `players` | list · get · create · patch · delete |
| `rooms` | list · get · create · patch · delete |
| `emoji-sets` | list · get · create · patch · delete |
| `games` | list · get · create · patch  (reads via `gamePublic`) |
| `guesses` | list · get · create  (append-only) |
| `transactions` | list · get · create  (append-only) |

Plus `GET /api/health` and Swagger UI at `/docs` (OpenAPI generated from the zod schemas).
List endpoints take `?limit=&offset=`; `guesses`/`transactions` also filter by branded id.

## Run it

```bash
npm install
cp .env.example .env            # set DATABASE_URL

# create the schema in Postgres
npm run db:generate             # (already generated; re-run after schema edits)
npm run db:migrate

npm run dev                     # tsx watch -> http://localhost:3000, docs at /docs
# or
npm run build && npm start      # tsup bundle -> node dist/server.js
```

`npm run typecheck` runs `tsc` across every package and the app.
