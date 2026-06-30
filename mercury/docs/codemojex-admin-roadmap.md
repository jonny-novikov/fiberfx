# Mercury · Roadmap — codemojex-admin on Bun, and the dashboard
<show-structure depth="2"/>

The admin console exists today: a Fastify surface over the shared Postgres and
ValKey, reading the board and withholding the game secret by column selection,
verified end to end in the bench. This roadmap takes it from there to a
schema-typed, functional-handler surface running on Bun with the `@echo/fx`
WebAssembly kernel underneath, and adds the React dashboard the operators will
use. Two further rungs — a RESP connector and an EchoMQ job runtime — are named
for the horizon.

The near-term plan is scoped to one week and three workstreams: the Bun
foundation, the Fastify handlers with optimized serializers, and the
`codemojex-dashboard` front end built on `mercury/ui`. Everything is grounded in
the two prior research pieces — `docs/echo-runtime-engines.md` for why the surface
moves to Bun, and `docs/effective-ts-fp-wasm.md` for the functional-handler and
error-as-value style — and in the architecture vision, which names the proposed
`@echo/wire` and `@echo/mq` substrate the future rungs become.

## The arc

| Rung | What | Horizon |
|---|---|---|
| Foundation | admin on Bun, the wasm kernel under Bun, Node kept as fallback | this week |
| Handlers + serializers | TypeBox schemas, fast-json-stringify, functional Result handlers | this week |
| Dashboard | `codemojex-dashboard` React app on `mercury/ui`, one shared type source | this week |
| RESP connector | `@echo/wire` — Bun-native RESP3 at parity, push frames for the live board | future |
| Job runtime | `@echo/mq` — pull a job from EchoMQ and run it, compute in the kernel | future |

The constant across all five: the compute kernel stays WebAssembly, so the engine
moves underneath the surface without forking the code, and one identity contract
and one set of route schemas drive the server and the client alike.

## Ship this week — foundation

The first workstream moves the runtime without changing behavior, so the rest of
the week builds on a known-good base.

**Bun as the runtime, Node as the fallback.** The admin moves onto Bun for the
tail-call property the functional core will rely on and for the faster start, with
Node kept runnable as the compatibility baseline. The work is the workspace, not
the source: pin the engine, add the Bun lockfile, and route the scripts through
Bun, while leaving the existing `postgres` and `iovalkey` drivers and Drizzle in
place to keep the change small. Bun targets Node compatibility closely enough that
most Fastify applications run unchanged, so the gate is to prove that the specific
dependency set — the Postgres driver, the ValKey client, Drizzle — falls inside
that compatibility rather than in the few-percent gap, before any further change.

**The wasm kernel under Bun.** `@echo/fx` is built with the nodejs wasm-pack
target, which Bun loads, so the codec, the minter, and the routing hash run
unchanged. This is confirmed first, because every route's branded-id check depends
on it.

**Boot and configuration unchanged.** The frozen, typed `Env` parsed once at boot
carries over as-is; a missing or malformed value still fails the boot rather than
the first request.

*Gate.* The admin boots under Bun; every route that passed in the bench passes the
same checks under Bun; the wasm kernel mints and decodes a branded id under Bun;
and the dependency set is confirmed clear of the compatibility gap. Node stays
green as the fallback.

## Ship this week — Fastify handlers and optimized serializers

The second workstream is the substantive one. It gives every route a schema,
turns the schema into both a validator and a compiled serializer, makes
secret-withholding a property of the wire rather than of a hand-written column
list, and rewrites the handlers in the error-as-value style.

**One schema per route, three outputs.** Fastify infers types from inline JSON
Schema through a type provider; with the TypeBox provider, a single `Type.Object`
definition yields the static TypeScript type (`Static<typeof Schema>`), the
runtime validator, and the response serializer at once, and an OpenAPI document
for free. The surface registers `withTypeProvider` and the TypeBox validator
compiler, and each route carries a `schema` with `params`, `querystring`, and a
`response` keyed by status code.

**Optimized serializers, and why they matter here.** When a route declares a
response schema, Fastify compiles it with fast-json-stringify into a dedicated
serialization function at startup; because it knows the exact output shape, it
skips the runtime type inspection that the generic stringifier performs and runs
on the order of two to five times faster. The property that matters most for
codemojex is the second one: a response schema strips any field not named in it,
so a value a handler did not intend to expose never reaches the wire. The game
response schema names the public columns and omits the secret and the keyboard
snapshot, which means the serializer drops them structurally even if a future
change to a query accidentally selects them. This upgrades the existing rule —
withhold the secret by choosing columns — to a stronger one: withhold the secret
by the serializer contract, enforced at startup and independent of the handler.

**Branded ids validated in two layers.** A route parameter that is a branded id
gets a TypeBox string with the pattern `^[A-Z]{3}[0-9A-Za-z]{11}$`, so the Ajv
validator rejects a malformed id with a 400 before the handler runs; the
authoritative check stays the `@echo/fx` decode, which confirms the namespace and
the structural validity and lets the handler return a 404 for a well-formed but
unknown id. The cheap shape check sheds bad input at the edge; the kernel remains
the source of truth for what a valid id is.

**Functional handlers over a Result.** Following the prior piece's choice, the
handler body is a thin adapter and the work lives in pure functions. A handler
calls a pure function that builds the query and shapes the row, which returns a
`Result` (neverthrow) rather than throwing; the adapter matches the `Result` with
ts-pattern and maps the success arm to the serialized payload and the error arm to
a status. The database and ValKey calls are the only effects, kept at the edge of
the handler; the transform between them is pure and testable without a server.

**The route specs.** Each route names its parameter schema, its response schema,
and the withholding rule.

| Route | Params / query | Response schema | Note |
|---|---|---|---|
| `GET /rooms` | — | array of room summary | public columns only |
| `GET /rooms/:id` | `id` ROM pattern | room plus its games | games omit secret/keyboard |
| `PATCH /rooms/:id/status` | `id` ROM, body `open`/`closed` | id plus new status | management |
| `GET /games` | `status` query | array of game summary | secret/keyboard omitted |
| `GET /games/:id` | `id` GAM pattern | game, board, recent guesses | board read from ValKey; no secret |
| `GET /players` | `q` query | array of wallet summary | balances |
| `GET /players/:id` | `id` PLR pattern | player, guesses, ledger | ledger provisional |

*Gate.* No route ships without a response schema; a test asserts the compiled game
serializer omits `secret` and `keyboard` given an input that contains them; the
`Static` types make the handlers typecheck with no casts; the branded-pattern
params return 400 on a malformed id and 404 on an unknown one; and the schema
serialization path is confirmed faster than the generic stringifier on the game
payload.

## Ship this week — codemojex-dashboard on mercury/ui

The third workstream is the operator front end: a React application that consumes
the admin API, built from a shared component library, with the route schemas as
the single source of types so the client cannot see a field the server withholds.

**Two packages, proposed.** `mercury/ui` is a presentational component library —
a table, a status pill, a leaderboard or board view, a stat card, an emoji cell —
with no data fetching of its own; `codemojex-dashboard` is the application that
composes them into views. Both are marked PROPOSED; they are the intended shape,
not existing code.

**One type source, server to client.** The TypeBox route schemas move into a
shared package that both the admin and the dashboard import. The admin uses them
to validate and serialize; the dashboard derives the response types with `Static`
and reuses the branded id types from `@mercury/db`. The consequence is structural:
because the game response schema has no secret field, the response type has no
secret field, and the client can neither receive nor reference one. The
withholding that the serializer enforces on the wire is the same withholding the
client's types express.

**The views.** Three, mirroring the API: rooms (a list and a detail with the
room's games), games (a list with a status filter, and a detail with the live
board and recent guesses), and players (a searchable list and a detail with the
wallet and history), plus the one management action to flip a room open or closed.

**The data layer.** A typed fetch client wraps the admin endpoints using the
shared response types; server state is held with a query cache (TanStack Query is
the idiomatic fit) so the views stay in sync without hand-rolled state. The live
board is read by polling the game-detail endpoint for now; the RESP rung replaces
the poll with a push later.

**The build.** The dashboard compiles to a static bundle with Vite and React, or
with Bun's bundler, and consumes `mercury/ui` as a workspace dependency. Nothing
in the bundle carries a secret, because nothing in the types or the responses
does.

*Gate.* The dashboard renders the three views against the live admin; a type-level
assertion confirms no response type exposes `secret` or `keyboard`; the build
produces a static bundle; and the board view reflects the ValKey sorted set for
the active game.

## Future — the RESP connector (@echo/wire)

The first horizon rung is a Bun-native RESP3 connector at parity with the
canonical `EchoMQ.RESP`, replacing the off-the-shelf ValKey client for the board
reads. It negotiates with HELLO, carries the full RESP3 type set, and routes
out-of-band push frames, which is the point of the rung: the server-assisted
client-tracking push becomes a cache-invalidation hint, so the dashboard's live
board moves from polling to a pushed update. The connector is marked PARITY: its
behavior is checked against the canonical connector before it carries production
reads, the same discipline the routing hash is held to.

*Gate.* The connector reads the board at parity with the current client; a push
frame drives a board refresh in the dashboard without a poll; the parity check
against `EchoMQ.RESP` passes.

## Future — the EchoMQ job runtime (@echo/mq)

The second horizon rung is a runtime that pulls a job from an EchoMQ lane and runs
it. It boots authenticated, bounds its in-flight depth, keeps an idle heartbeat,
and parks on an edge-triggered wake key rather than polling — the connector
discipline already specified for EchoMQ. Fairness across lanes is round-robin,
never hashed. The job shell does the I/O and the orchestration and delegates the
compute — the scoring, the fused numeric work — to the `@echo/fx` WebAssembly
kernel, which is why the kernel stays wasm and stays engine-neutral.

This rung is where the engine landscape pays off. A long-lived worker can run on
the same Bun surface; an ephemeral FLAME-style job machine, where cold start
dominates, runs the shell on a fast-start runtime — a QuickJS-class runtime or a
V8-isolate worker, per the engines piece — and still calls the same wasm kernel
for the math, so the cold-start tier never has to run the heavy compute it is
poor at.

*Gate.* A job is pulled from a lane, run against the kernel, and its result
persisted; the in-flight depth stays bounded under load; the consumer parks on the
wake key rather than spinning; and the ephemeral shell delegates all compute to
the kernel.

## The gate ladder

| Rung | Ships | Gate |
|---|---|---|
| Foundation | admin on Bun; kernel under Bun; Node fallback | bench routes pass on Bun; deps clear of the compat gap |
| Handlers + serializers | TypeBox schemas; fast-json-stringify; Result handlers | every route schema'd; serializer drops secret/keyboard; 400/404 on ids |
| Dashboard | `codemojex-dashboard` on `mercury/ui`; shared types | three views render; no secret in any response type; static bundle |
| RESP connector | `@echo/wire` RESP3, push frames | board read at parity; push drives a refresh |
| Job runtime | `@echo/mq` consumer; kernel compute | job pulled and run; depth bounded; parks not polls |

The thread through the ladder: move the runtime first on a fixed behavior, make
the schema the single contract for validation, serialization, and the client's
types, keep the compute in an engine-neutral kernel, and let correctness rest on a
serializer contract and a parity check rather than on a handler remembering to
omit a field.

## References

- Fastify validation and serialization: an output schema raises throughput and
  prevents accidental disclosure:
  `https://fastify.dev/docs/latest/Reference/Validation-and-Serialization/`
- fast-json-stringify compiles a schema into a dedicated serializer, 2x or more
  over the generic stringifier: `https://github.com/fastify/fast-json-stringify`
- Schema-based serialization strips unknown fields and is 2-5x faster (overview):
  `https://jsonic.io/guides/fastify-json-api`
- Standalone serializer precompilation for ahead-of-time builds:
  `https://github.com/fastify/fast-json-stringify-compiler`
- The TypeBox type provider: one schema yields types, validation, and
  serialization: `https://github.com/fastify/fastify-type-provider-typebox`
- Fastify type providers, inferring types from inline JSON Schema:
  `https://fastify.dev/docs/latest/Reference/Type-Providers/`
- TypeBox defines a type and a runtime validator together, with string patterns
  and unions: `https://gkhanko.medium.com/how-to-setup-a-nodejs-api-with-fastify-typescript-runtime-type-support-35606c0b657b`
- Why the surface runs on Bun (engine, tail calls, cold start): the companion
  piece `docs/echo-runtime-engines.md`
- The functional-handler and error-as-value style (neverthrow, ts-pattern): the
  companion piece `docs/effective-ts-fp-wasm.md`
- The proposed `@echo/wire` and `@echo/mq` substrate: the companion piece
  `docs/mercury-echo-architecture.md`
