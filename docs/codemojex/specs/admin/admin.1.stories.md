# admin.1 · stories

## admin.1-US1
As an operator, I want the admin API to reject any request that lacks my credential, so that the control plane over
live games and player wallets is never open.

**Acceptance criteria.**
- **Given** a server from `buildServer(env)` with `ADMIN_TOKEN` set, **when** `GET /rooms` is called with no
  `Authorization` header, **then** the status is 401 and the body is `{ "error": "unauthorized" }`.
- **Given** the same server, **when** `GET /rooms` carries `Authorization: Bearer <ADMIN_TOKEN>`, **then** the
  status is 200 and the body is the rooms array.
- **Given** a wrong token, **when** any data route is called, **then** the status is 401.

INVEST: independent of the read-shape work; verifiable by `app.inject`; encodes admin.1-INV1.
Priority: must · Size: S · Implements deliverables: admin.1-D1.

## admin.1-US2
As an operator, I want a game's detail without its secret, so that reading the live board can never leak the answer.

**Acceptance criteria.**
- **Given** a game row, **when** `GET /games/:id` is called with the token, **then** the 200 body has `game`,
  `board`, and `guesses`, and the `game` object has no `secret` key and no `keyboard` key.
- **Given** `GET /games` with the token, **then** each item carries the `GameSummary` public columns and no `secret`.

INVEST: independent of the gate; verifiable by a response-key assertion; encodes admin.1-INV2.
Priority: must · Size: S · Implements deliverables: admin.1-D2.

## admin.1-US3
As an operator, I want the health route to answer without a credential, so that an uptime probe or load balancer
can check liveness without the operator secret.

**Acceptance criteria.**
- **Given** the built server, **when** `GET /health` is called with no `Authorization` header, **then** the status
  is 200 and the body reports `postgres`, `valkey`, and `worker`.
- **Given** the gate is active, **when** `/health` is called, **then** the gate lets it pass.

INVEST: independent; verifiable by a tokenless `app.inject`; encodes admin.1-INV3.
Priority: must · Size: XS · Implements deliverables: admin.1-D2.

## admin.1-US4
As the Director, I want the `mercury/codemojex` workspace installed and the admin app typechecked and boot-smoked,
so that admin.1 ships on a green, running foundation and not an unverified scaffold.

**Acceptance criteria.**
- **Given** a clean `mercury/codemojex`, **when** `pnpm install` then `pnpm --filter @codemojex/admin typecheck`
  run, **then** the typecheck exits 0.
- **Given** the built app against a reachable Postgres + Valkey, **when** `buildServer(loadEnv()).ready()` runs,
  **then** it resolves without throwing, for the `start` and the `runCluster` entries.

INVEST: independent of behaviour; verifiable by the command exit code plus the boot smoke; encodes admin.1-INV4.
Priority: must · Size: M · Implements deliverables: admin.1-D4.

Coverage: D1→US1 · D2→US2,US3 · D3→US1,US2,US3 · D4→US4.  Spec: admin.1.md · Agent brief: admin.1.llms.md.
