# cmt.3 — the Effector Phoenix-channel state foundation (the body)

> **Track:** codemojex Tauri (`cmt.N`) · **AAW scope:** `cm-tauri` · **Risk:** MED–HIGH · **Depends:** cmt.2.
> Canon: [`./tauri.design.md`] · [`./tauri.specs.md`] · program [`../../program/codemojex.program.md`].
> The `.md` **body is authoritative**; [`./cmt.3.stories.md`] (acceptance) and [`./cmt.3.llms.md`] (build
> brief) derive from it. **DESIGN/SPEC ONLY** — no production code ships from this doc.
>
> **[RECONCILE] — the Operator ruled the forks + provided a prototype.** cmt.3 is now the **channel /
> Effector STATE foundation only**. The earlier "DS foundation" framing (Tailwind v4 + golden-token
> `@theme` + a styled smoke atom) is **superseded → moved to cmt.4** (F-cmt3-3 deferred). The deliverable
> is: integrate the Operator's **Effector Phoenix-channel slice** (a complete, unapplied prototype at
> `mercury/docs/game-effector/`) into the real trees, extend + prove it, and reach the ruled **Arm B**
> transport (a raw `game:<gam>` channel is THE game transport) **A-first** — land Arm A additively, prove
> the round-trip live, then flip to B.
>
> **[SHIPPED — Phase A · 2026-07-01 · `/cm-ship`]** The mercury-side foundation shipped: **D1/D2/D3** +
> **Arm A** (fold the game into the mercury workspace — the glob fix's as-built form, since the reorg had
> moved `@echo/phoenix*` into `mercury/packages/`) + the harden (a jest-dom **dual-`vitest`-major** fix +
> 3 ratified `phoenix/src` lint fixes). **Gate GREEN:** `@codemojex/game` typecheck 0 · build · **23/23** ·
> `model.test.ts` mutation-verified; the `echo/` bundle is byte-identical (boundary held). **D4** (the
> `RoomChannel` twin) + **Phase B** (the Arm-B flip + the INV7 SES caveat) are **deferred to
> `/codemojex-ship`**, gated on the Operator-observed live round-trip (INV5). Follow-ons: edge Docker deploy
> rework · dual-`vitest`-major convergence.

## Goal

Make a raw Phoenix `game:<gam>` channel the game's state transport, with the island driven by
`@mercury/effector` stores instead of a LiveView host — integrated from the Operator's prototype, extended
into the real trees, and **proven by a live round-trip** (join → props render in the shell → `submit_guess`
round-trips). Three JS/TS layers land additively (a generic `createChannel` Effector plug in
`@mercury/effector`; a codemojex `createGameModel` + `PhoenixGame` hot-plug in `@codemojex/game`), one echo/
`RoomChannel` becomes the channel-transport twin of `GameLive`, the workspace-glob mismatch is fixed, and
`GameEdge` + the island's self-containment stay intact. Reaching **Arm B** (the channel is THE transport;
`GameLive` slims to a page host) is done **after** the live proof passes.

## Rationale (5W)

- **Why.** cmt.4 (the golden screen) needs a state substrate that is not tied to the LiveView render
  lifecycle; a channel-backed Effector layer gives the island server-authoritative props + one-off events +
  outbound pushes over one socket, decoupled from LiveView. The Operator supplied a working prototype, so
  cmt.3 is an **integrate-and-prove** rung, not a green-field design.
- **Who.** The island developer building cmt.4 on this state layer; the Operator, who ruled the three forks.
- **What.** The prototype's three layers into the real trees + the workspace-glob fix + the echo/
  `RoomChannel` twin (the Operator's diff) + a proven live round-trip + the Arm-A→Arm-B flip.
- **Where.** Primary edit `mercury/codemojex/apps/game/**` + additive `mercury/packages/mercury-effector/**`
  + the one-line `mercury/pnpm-workspace.yaml` glob fix. **echo/** is touched **only** at
  `room_channel.ex` (Phase A) and — for the Arm-B flip — `game_live.ex` + the Tier-3 page host; this is one
  coherent **channel-transport** concern the **Director** commits **separately** (JS under `mercury/…` +
  `docs/…`; echo/ as its own pathspec). No other echo/ edit.
- **When.** After cmt.2; the forks are already ruled (no Operator gate before build). The **Arm-B flip** is
  gated on the **live proof** passing.

## Scope

**In**

- **`@mercury/effector` `createChannel`** — the generic Effector plug for a Phoenix channel (the prototype's
  `channel.ts`), added **additively** (a new file + a `+ export * from "./channel"` barrel line). Structurally
  typed against a `ChannelLike`, so `@mercury/effector` takes **no `@echo/phoenix` dependency**.
- **`@codemojex/game` channel layer** — `src/channel/model.ts` (`createGameModel` on `createChannel`, mapping
  the channel to `$props` + one-off `serverEvent` + outbound `submit_guess`/`lock`/`unlock`) and
  `src/channel/PhoenixGame.tsx` (one `@echo/phoenix` `Socket` + one `game:<id>` channel, building the `Bridge`
  and rendering `GameEdge` **untouched**). Additive: `index.tsx` untouched in Phase A.
- **Consumption wiring** — resolve `@mercury/effector` from source (a vite alias + tsconfig `paths`, three
  `../`, the `@codemojex/economy` precedent) + add `@mercury/effector`/`effector`/`effector-react` to the
  island deps; **fix the workspace glob** (`mercury/pnpm-workspace.yaml`: `codemojex-node/…` → `codemojex/…`).
- **The echo/ `RoomChannel` twin** — apply the Operator's `room_channel.ex.diff`: `handle_in`
  `submit_guess`/`lock`/`unlock`/`refresh` → the same `Codemojex.*` calls `GameLive` uses; `join`/`refresh`
  return full `game_props` (view/leaderboard/history/me — the **secret is never sent**); `{:scored,_}` →
  `game:update`; `revealed`/`golden_win` preserved.
- **The live round-trip proof** (the bar), then **the Arm-B flip** — switch the bundle's default `mount` to
  `PhoenixGame` (`index.tsx`) + slim `GameLive` to the Tier-3 page host passing `{game, session}` data attrs;
  `RoomChannel` owns all data.

**Out**

- **All Tailwind / golden-token / golden-screen work** (cmt.4, F-cmt3-3 deferred) — cmt.3 renders the
  **existing plain `GameEdge`** over the new transport; no `@theme`, no styling.
- `GameProps` balance/boost extension (cmt.4, F3); react-i18next (cmt.4).
- Any echo/ edit beyond the channel-transport concern (`room_channel.ex` + the Arm-B `game_live.ex`/host).
- Any `@mercury/ui`/`@mercury/core` existing-export change.

## Deliverables

- **cmt.3-D1 — `createChannel` (additive `@mercury/effector` plug).** New
  `mercury/packages/mercury-effector/src/channel.ts` exporting `createChannel()` → `{ $status, $error,
  joined, message, push, pushAsync, bind, useStatus }` + `ChannelLike`/`PushLike`/`ChannelMessage`/
  `ChannelStatus`/`ChannelModel` types (the prototype, verbatim); a `+ export * from "./channel"` line in
  `src/index.ts`. Imports **only** `effector` + `effector-react`.
- **cmt.3-D2 — the game channel layer (additive).** New `src/channel/model.ts` (`createGameModel`,
  `GAME_INBOUND = ["game:update","revealed","golden_win","guess_rejected"]`, `$props`, `serverEvent`,
  `submitGuess`/`lock`/`unlock`) + `src/channel/PhoenixGame.tsx` (props `{ game, session, endpoint?,
  fallback? }`; opens `new Socket(endpoint, { params: { session } })`, joins `game:<id>`, binds the model,
  builds the `Bridge`, renders `GameEdge` from `$props`). `GameEdge`, `types.ts`, `index.tsx` unchanged.
- **cmt.3-D3 — consumption + glob fix.** The `@mercury/effector` source alias in `vite.config.ts` +
  `vitest.config.ts` + `tsconfig.json` `paths`; `+3` island deps (`@mercury/effector` `workspace:*`,
  `effector`/`effector-react` `^23.3.0`); `mercury/pnpm-workspace.yaml` globs `codemojex/{packages,apps}/*`.
- **cmt.3-D4 — the echo/ `RoomChannel` twin.** `room_channel.ex.diff` applied (the 48-line thin channel →
  the 109-line `GameLive` twin) — `Codemojex.submit`/`lock`/`unlock`, `game_props`/`named`/`player_name`
  copied from `GameLive`, `push_props` → `game:update`. Committed as a **separate echo/ concern** by the
  Director. **Preserved reference** (the prototype's authored twin + diff, relocated here before
  `mercury/docs/game-effector/` is deleted): [`./cmt.3-D4.room_channel.ex`] (the 109-line twin) +
  [`./cmt.3-D4.room_channel.ex.diff`]. The as-built `room_channel.ex` is the 48-line thin original
  (`2248ea6d`) until `/codemojex-ship` applies this.
- **cmt.3-D5 — the live proof, then the Arm-B flip.** Phase A: mount `PhoenixGame` (a second/flagged path)
  and **prove the round-trip live** in the shell. Phase B (post-proof): the default-`mount` flip + the
  `GameLive` slim to the page host; the channel is THE transport.

## Invariants (each a runnable check — a no-op must fail it)

- **cmt.3-INV1 — `@mercury/effector` extended additively.** The **resolved export set** after ⊇ before
  (theme · toast · form · strength · cooldown · formatter all still exported) **plus** `createChannel` (+ its
  types); the only `@mercury/effector` edit is the new `channel.ts` + the one barrel line; `pnpm run
  typecheck:mercury && pnpm run build:mercury` green (from `mercury/`); the existing `@codemojex/economy`
  consumer still typechecks + builds. *No-op fails:* a removed/renamed export or an economy break.
- **cmt.3-INV2 — `createChannel` takes no `@echo/phoenix` dep.** `channel.ts` is structurally typed against
  `ChannelLike`; a grep of its imports finds **only** `effector` + `effector-react` (nothing from `@echo/*`,
  `@codemojex/*`, or `@mercury/ui`). *No-op fails:* any transport import in the package.
- **cmt.3-INV3 — Arm A keeps `GameEdge` + the `mount` contract unchanged.** In Phase A `src/GameEdge.tsx`,
  `src/index.tsx`, `src/types.ts` are byte-unchanged; `PhoenixGame` renders `GameEdge` verbatim; the game's
  existing vitest (`GameEdge.test.tsx`) stays green. *No-op fails:* a `GameEdge`/contract edit in Phase A.
- **cmt.3-INV4 — the self-contained bundle holds (no `@mercury/ui` in the graph).** `pnpm --filter
  @codemojex/game build` emits a single `game-[hash].js` ESM exporting `mount`; a grep of the emitted JS
  finds **no** bare external import and **no** `@mercury/ui` component code (effector + `@mercury/effector`
  source + `@echo/phoenix` + react are all bundled). **Mitigation if the barrel walk pulls `@mercury/ui`:**
  import `createChannel`/`ChannelLike` from the granular `@mercury/effector/channel` entry (alias it to
  `src/channel.ts`) so `toast → @mercury/ui` is never walked. *No-op fails:* `@mercury/ui` in the bundle or
  a lost `mount`.
- **cmt.3-INV5 — the live round-trip (the proof bar).** With Phoenix `:4000` up (dev bypass) + Postgres +
  Valkey `:6390`, mounting `PhoenixGame` in the shell joins `game:<gam>`, the join reply renders `GameEdge`
  from `$props`, and `submit_guess` round-trips (a rejected guess pushes `guess_rejected` → the toast;
  `{:scored}` → `game:update` re-renders). *No-op fails:* an unbound channel / unfed model leaves the
  fallback "Подключение…". **Fallback posture** if the live loop is not agent-reachable (TCC/shell): the
  model's `sample` wiring is unit-proven (join reply → `$props`; `game:update` → `$props`; other →
  `serverEvent`; push → channel) + typecheck/build green + Operator-observed in-window.
- **cmt.3-INV6 — the workspace-glob fix restores resolution.** `mercury/pnpm-workspace.yaml` globs
  `codemojex/{packages,apps}/*` (not `codemojex-node/`); `@codemojex/*` `workspace:*` deps resolve; the
  mercury-scoped `verify:mercury` (not a blind `pnpm -r`) stays green. *No-op fails:* an unresolved
  `workspace:*`.
- **cmt.3-INV7 — Arm-B end-state + the SES caveat.** After the flip: `GameLive` is the Tier-3 page host
  (renders `{game, session}` as data attrs), the default `mount` renders `PhoenixGame`, `RoomChannel` owns
  all data (the join reply + `game:update` + one-offs). **Documented caveat (accept knowingly):** the `SES`
  reaches the client as a socket connect param (`data-session` → `PhoenixGame.session` → `Socket params:{
  session }`) — the **same** SES the `UserSocket` authenticates (`connect` → `assign(:player)`,
  `user_socket.ex:11-13`), but rendering it into a data attribute takes it **out of the httpOnly cookie**
  (a client-readable value; an XSS-exposure delta). *No-op fails:* the flip without the caveat recorded.

## Definition of Done

- The forks are **ruled** (F-cmt3-1 = integrate the prototype from source + fix the glob; F-cmt3-2 = Arm B
  reached A-first; F-cmt3-3 = Tailwind deferred to cmt.4) — folded into this triad, no further Operator gate
  before build.
- **cmt.3-INV1..7** pass. Gates (from `mercury/`): `pnpm run typecheck:mercury && build:mercury`; `pnpm
  --filter @codemojex/game typecheck && build && test`; `@codemojex/economy` still green. Echo/ side (the
  Director, that app's ladder): from `echo/apps/codemojex`, `TMPDIR=/tmp mix compile --warnings-as-errors`
  + `TMPDIR=/tmp mix test`, `valkey-cli -p 6390 ping`, `pg_isready`.
- **The proof bar = the live round-trip** (INV5); the Arm-B flip lands **after** it passes.
- **Grounding discharged:** `channel "game:*"` registered (`user_socket.ex:4`) + `:player` assigned at
  connect (`user_socket.ex:13`) + `room_channel.ex` = the 48-line diff base + every `Codemojex.*` call real
  (`game.ex`/`view.ex`/`locks.ex`/`store.ex`) → the only echo/ delta is `RoomChannel` (+ the Arm-B host).
- No id-mint / process / lease / schema surface → the **≥100 determinism loop is not required** (per
  [`./tauri.specs.md`] § determinism posture); posture = build + the live proof + the per-surface gate.
- Commits (Director, when the Operator asks): `mercury/codemojex/… + mercury/packages/mercury-effector/… +
  mercury/pnpm-workspace.yaml + docs/codemojex/…` as one pathspec; `echo/apps/codemojex/…` as a **separate**
  pathspec. No `git add -A`.
