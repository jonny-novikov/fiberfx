# cmt.3 — acceptance stories (Given / When / Then)

> Derived from [`./cmt.3.md`] (authoritative). Each story is a Connextra user story + concrete
> Given/When/Then acceptance + the invariant(s) it exercises. The Coverage line maps every Deliverable
> `cmt.3-D#` → its story. Names are grounded in the Operator's prototype (`mercury/docs/game-effector/`) +
> the as-built echo/ + island trees.

## US1 — the generic `createChannel` Effector plug (additive)

*As a Mercury consumer, I want a reusable Effector plug for a Phoenix channel, added additively and free of
any `@echo/phoenix` dependency, so that any channel-shaped transport can drive Effector state without
coupling the package to a socket library.*

- **Given** `@mercury/effector`'s factory convention and its `export *` barrel,
- **When** a new `src/channel.ts` exports `createChannel()` (`$status`/`$error`/`joined`/`message`/`push`/
  `pushAsync`/`bind`/`useStatus` + the `ChannelLike`/`ChannelModel` types) and `src/index.ts` gains
  `export * from "./channel"`,
- **Then** the resolved `@mercury/effector` export set after ⊇ before **plus** `createChannel`;
  `channel.ts` imports **only** `effector` + `effector-react` (grep: nothing from `@echo/*`/`@codemojex/*`/
  `@mercury/ui`); `typecheck:mercury && build:mercury` green; `@codemojex/economy` still typechecks + builds.
- **encodes cmt.3-INV1, cmt.3-INV2**.

## US2 — the game channel model + `PhoenixGame` hot-plug (additive)

*As the island developer, I want an Effector game model fed by a `game:<id>` channel and a `PhoenixGame`
component that renders the untouched `GameEdge`, so that the same island runs over a Phoenix channel with
no LiveView host and no change to `GameEdge`.*

- **Given** `GameEdge` is transport-agnostic (`GameProps` + a `Bridge`) and the prototype's `createGameModel`
  maps join reply + `game:update` → `$props`, `revealed`/`golden_win`/`guess_rejected` → `serverEvent`, and
  `submit_guess`/`lock`/`unlock` → pushes,
- **When** `src/channel/model.ts` + `src/channel/PhoenixGame.tsx` are added (a `Socket` with `params:{
  session }`, join `game:<id>`, `bind`, a `Bridge` over the model) and `index.tsx`/`GameEdge.tsx`/`types.ts`
  stay byte-unchanged,
- **Then** `PhoenixGame` renders `GameEdge` from `$props`; the existing `GameEdge.test.tsx` suite stays
  green; `pnpm --filter @codemojex/game typecheck` resolves the new files.
- **encodes cmt.3-INV3**, cmt.3-INV5.

## US3 — consume `@mercury/effector` from source + fix the workspace glob

*As the island build, I want `@mercury/effector` resolved from source and the workspace glob corrected, so
that a package edit is live in the island with no prebuild, `workspace:*` deps resolve, and the emitted
bundle stays a single self-contained ESM.*

- **Given** the island has no `@mercury`/`effector` deps and `mercury/pnpm-workspace.yaml` globs
  `codemojex-node/{packages,apps}/*` (a dir that does not exist — `@codemojex/*` are outside the workspace),
- **When** the glob is fixed to `codemojex/{packages,apps}/*`, `@mercury/effector` `workspace:*` +
  `effector`/`effector-react` `^23.3.0` are added to the island deps, and a vite alias + tsconfig `paths`
  map `@mercury/effector` → `../../../packages/mercury-effector/src/index.ts` (three `../`, the economy
  precedent) in `vite.config.ts` + `vitest.config.ts` + `tsconfig.json`,
- **Then** `verify:mercury` stays green; `pnpm --filter @codemojex/game build` emits one `game-[hash].js`
  ESM exporting `mount` with **no** bare external import and **no** `@mercury/ui` component code (mitigation:
  the granular `@mercury/effector/channel` import if the barrel walk pulls `@mercury/ui`).
- **encodes cmt.3-INV4, cmt.3-INV6**.

## US4 — the echo/ `RoomChannel` becomes the `GameLive` twin

*As a channel client, I want `RoomChannel` to answer joins with full game props and route guesses/locks
through the same `Codemojex` calls the LiveView uses, so that the raw channel is a faithful transport twin
and the secret is never sent.*

- **Given** `channel "game:*"` is registered (`user_socket.ex:4`), `connect` assigns `:player`
  (`user_socket.ex:13`), and `room_channel.ex` is the 48-line thin channel,
- **When** the Operator's `room_channel.ex.diff` is applied — `handle_in` `submit_guess`/`lock`/`unlock`/
  `refresh` → `Codemojex.submit`/`lock`/`unlock`; `join`/`refresh` → full `game_props` (view/leaderboard/
  history/me); `{:scored,_}` → `push_props` as `game:update`; `game_props`/`named`/`player_name` copied from
  `GameLive`,
- **Then** from `echo/apps/codemojex`, `TMPDIR=/tmp mix compile --warnings-as-errors` + `mix test` pass; a
  join returns `game_props` **without** `secret`; a `submit_guess` routes to `Codemojex.submit` (a rejected
  guess pushes `guess_rejected`).
- **encodes cmt.3-INV5** (server half), cmt.3-INV7.

## US5 — the live round-trip proof, then the Arm-B flip

*As the Operator, I want the channel transport proven by a live round-trip before it becomes the default, so
that the flip to Arm B ships on evidence, not a claim.*

- **Given** Phoenix `:4000` up (dev bypass) + Postgres + Valkey `:6390`, with `PhoenixGame` mounted as a
  second/flagged path (Phase A),
- **When** the shell mounts `PhoenixGame` for a real `game:<gam>`,
- **Then** the join reply renders `GameEdge` from `$props`, `submit_guess` round-trips, and `game:update`
  re-renders (a no-subscription/unbound model leaves the "Подключение…" fallback); **then** (Phase B,
  post-proof) the default `mount` flips to `PhoenixGame` (`index.tsx`) and `GameLive` slims to the Tier-3
  page host passing `{game, session}` data attrs — with the SES-in-a-data-attr caveat recorded (INV7).
- **encodes cmt.3-INV5, cmt.3-INV7**, cmt.3-INV3.

## Coverage

| Deliverable | Story |
|---|---|
| cmt.3-D1 — `createChannel` additive plug | US1 |
| cmt.3-D2 — game channel model + `PhoenixGame` | US2 |
| cmt.3-D3 — consumption + glob fix | US3 |
| cmt.3-D4 — echo/ `RoomChannel` twin | US4 |
| cmt.3-D5 — live proof + Arm-B flip | US5 |

Every `cmt.3-INV#` is exercised: INV1 (US1), INV2 (US1), INV3 (US2/US5), INV4 (US3), INV5 (US2/US4/US5),
INV6 (US3), INV7 (US4/US5).
