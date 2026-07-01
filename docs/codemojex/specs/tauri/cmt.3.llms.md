# cmt.3 — the build brief (`.llms.md`)

> Derived from [`./cmt.3.md`] (authoritative body) + [`./cmt.3.stories.md`] (acceptance). This rung
> **integrates the Operator's prototype** — most of the code is already written at
> `mercury/docs/game-effector/`. The builder's job is: copy the four JS/TS files into the real trees,
> wire consumption + the workspace glob, apply the echo/ diff, **prove the round-trip live**, then flip to
> Arm B. Cap reading to the prototype (below) + this triad. Boundary: `mercury/codemojex/apps/game/**` +
> additive `mercury/packages/mercury-effector/**` + the one glob line + the echo/ `room_channel.ex` (a
> **separate** commit) + the Arm-B host. **Agents run no git.**

## References (the prototype — copy from these; they are complete)

| Prototype file (`mercury/docs/game-effector/`) | Lands at | Action |
|---|---|---|
| `mercury/packages/mercury-effector/src/channel.ts` | `mercury/packages/mercury-effector/src/channel.ts` | **copy verbatim** (new) |
| `mercury/packages/mercury-effector/src/index.ts` | `mercury/packages/mercury-effector/src/index.ts` | append `export * from "./channel";` (the only change) |
| `mercury/codemojex/apps/game/src/channel/model.ts` | `…/apps/game/src/channel/model.ts` | **copy verbatim** (new) |
| `mercury/codemojex/apps/game/src/channel/PhoenixGame.tsx` | `…/apps/game/src/channel/PhoenixGame.tsx` | **copy verbatim** (new) |
| `room_channel.ex.diff` | `echo/apps/codemojex/lib/codemojex_web/channels/room_channel.ex` | **apply the diff** (echo/, separate commit) |
| `REPORT.md` | — | the integration map + the two known snags |

Also read (pattern only): the existing `@codemojex/economy` `{vite.config.ts, tsconfig.json, package.json}`
(the `@mercury` source-alias precedent) and the island's `{vite.config.ts, vitest.config.ts, tsconfig.json,
package.json}` (the `r()` alias helper + the deps to extend). Do **not** re-read the whole island.

**Grounded facts (NO-INVENT — probed):**

- **`createChannel`** (`channel.ts`) — an Effector plug over a Phoenix channel: `$status`
  (`idle→joining→joined/errored/closed`), `$error`, events `joined`/`message`, a `pushFx` routed via
  `sample`, `bind(channel, inbound) → unbind`, `useStatus()`. Structurally typed against `ChannelLike`
  (`join/on/off/push/onClose/onError/leave`) → **no `@echo/phoenix` dep**. Imports **only** `effector` +
  `effector-react`.
- **`createGameModel`** (`model.ts`) — `GAME_INBOUND = ["game:update","revealed","golden_win",
  "guess_rejected"]`; `sample` maps the join reply + `game:update` → `$props: GameProps|null`, every other
  frame → `serverEvent {name,payload}`; `submitGuess(emojis)`/`lock(pos,code)`/`unlock(pos)` → `chan.push`.
  Imports `createChannel` from `@mercury/effector`, `effector`, `@/types`.
- **`PhoenixGame`** (`PhoenixGame.tsx`) — props `{ game, session, endpoint="/socket", fallback? }`; one
  `new Socket(endpoint, { params: { session } })`, `socket.channel("game:"+game)`, `bind` on mount / unbind
  + `leave` + `disconnect` on unmount; a `Bridge` (`pushEvent`→`chan.push`; `onServerEvent`→ the model's
  `serverEvent` subs); renders `<GameEdge {...props} bridge={bridge}/>` from `$props`, else the fallback
  `"Подключение…"`. Imports `@echo/phoenix` `Socket` (already vendored), `effector-react`, `@mercury/effector`
  (the `ChannelLike` type), `@/GameEdge`, `@/types`, `@/channel/model`.
- **The echo/ side is ready** (probed): `channel "game:*", CodemojexWeb.RoomChannel` (`user_socket.ex:4`);
  `connect` → `{:ok, %{plr: plr}} -> assign(socket, :player, plr)` (`user_socket.ex:13`), so
  `socket.assigns.player` exists; `room_channel.ex` is the 48-line diff base; the diff's `Codemojex.submit/3`
  (`game.ex:21`, `{:error,:bad_guess}` fallback `:46`), `lock/4` (`:76`), `unlock/3` (`:77`),
  `game_view/1` (`view.ex:49`), `leaderboard/2` (`game.ex:259`), `my_history/3` (`:258`), `Store.player/1`
  (`store.ex:70`) all exist; `game_props`/`named`/`player_name` are copied from `GameLive`
  (`game_live.ex:108/117/121`). **The only echo/ delta (Phase A) is `RoomChannel`.**
- **Workspace glob** — `mercury/pnpm-workspace.yaml` currently globs `codemojex-node/packages/*` +
  `codemojex-node/apps/*`; the real dir is `codemojex/`. Fix both lines `codemojex-node/` → `codemojex/`.

## Requirements (each traced `[US:]`)

- **R1 — the additive `@mercury/effector` plug.** `[US1]` Copy `channel.ts`; append the one barrel line.
  Nothing else in `@mercury/effector`/`@mercury/core` changes. → cmt.3-INV1, cmt.3-INV2.
- **R2 — the game channel layer.** `[US2]` Copy `model.ts` + `PhoenixGame.tsx` under `src/channel/`. Leave
  `GameEdge.tsx`, `types.ts`, `index.tsx` byte-unchanged (Phase A). → cmt.3-INV3.
- **R3 — consumption + glob.** `[US3]` Add the `@mercury/effector` alias to `vite.config.ts` +
  `vitest.config.ts` (`"@mercury/effector": r("../../../packages/mercury-effector/src/index.ts")`) + the
  `tsconfig.json` `paths` entry; add island deps `@mercury/effector` `workspace:*`, `effector`/
  `effector-react` `^23.3.0`; fix the workspace glob (both lines). `pnpm install`. → cmt.3-INV4, cmt.3-INV6.
- **R4 — the echo/ twin.** `[US4]` Apply `room_channel.ex.diff`. (Director commits echo/ separately.) →
  cmt.3-INV5 (server), cmt.3-INV7.
- **R5 — prove live, then flip.** `[US5]` Phase A: mount `PhoenixGame` as a second/flagged path; prove
  join→props→`submit_guess` in the shell. Phase B (post-proof): flip the default `mount` (`index.tsx` renders
  `PhoenixGame`, reading `{game, session}` from data attrs) + slim `GameLive` to the Tier-3 page host. →
  cmt.3-INV5, cmt.3-INV7.

## Execution topology

**Three zones.** (1) `@mercury/effector` (the generic plug, standalone). (2) `@codemojex/game` (the model +
`PhoenixGame` + consumption). (3) `echo/apps/codemojex` (the `RoomChannel` twin; Arm-B adds the `GameLive`
host). The game's own vendored `@echo/phoenix` supplies `Socket`; `@mercury/effector` is resolved from
source by the alias; `effector`/`effector-react` resolve from the island's own `node_modules`.

**Build-order DAG (A-first, then B).**
1. **Layer 1** — copy `channel.ts` + barrel line → `typecheck:mercury && build:mercury` green.
2. **Consumption** — the alias (vite/vitest/tsconfig) + the `+3` deps + the glob fix → `pnpm install`.
3. **Layer 2** — copy `model.ts` + `PhoenixGame.tsx` → `pnpm --filter @codemojex/game typecheck`.
4. **Layer 3 (echo/)** — apply the `RoomChannel` diff → `mix compile --warnings-as-errors` + `mix test`.
5. **PROVE (Phase A)** — mount `PhoenixGame` (second/flagged path); live round-trip in the shell (INV5).
6. **FLIP (Phase B, after the proof)** — default-`mount` → `PhoenixGame` (`index.tsx`) + `GameLive` slims
   to the page host (`{game, session}` data attrs). Record the SES caveat (INV7).

**Exact files**

| File | Change | Phase |
|---|---|---|
| `mercury/packages/mercury-effector/src/channel.ts` | **new** (copy) | A |
| `mercury/packages/mercury-effector/src/index.ts` | +1 barrel line | A |
| `mercury/codemojex/apps/game/src/channel/model.ts` | **new** (copy) | A |
| `mercury/codemojex/apps/game/src/channel/PhoenixGame.tsx` | **new** (copy) | A |
| `mercury/codemojex/apps/game/package.json` | +3 deps | A |
| `mercury/codemojex/apps/game/vite.config.ts` | + `@mercury/effector` alias | A |
| `mercury/codemojex/apps/game/vitest.config.ts` | + the same alias | A |
| `mercury/codemojex/apps/game/tsconfig.json` | + the `paths` entry | A |
| `mercury/pnpm-workspace.yaml` | `codemojex-node/` → `codemojex/` (2 lines) | A |
| `echo/apps/codemojex/lib/codemojex_web/channels/room_channel.ex` | apply the diff (**separate commit**) | A |
| `mercury/codemojex/apps/game/src/index.tsx` | default `mount` → `PhoenixGame` | **B** |
| `echo/apps/codemojex/…/live/game_live.ex` + the Tier-3 page host | slim to a page host (`{game, session}` attrs) | **B** |

## Known snags (carry the fix in — do not rediscover)

1. **Self-containment vs the barrel walk (INV4).** `model.ts`/`PhoenixGame.tsx` import `@mercury/effector`
   (the barrel), whose `export * from "./toast"` reaches `@mercury/ui`. `@mercury/effector` has
   `sideEffects:false`, so the OUTPUT tree-shakes `@mercury/ui` out — but the build may still need to
   **resolve** `@mercury/ui` (not in the island's deps). **Verify** the emitted `game-[hash].js` has no
   `@mercury/ui`. **If the build errors or the bundle carries `@mercury/ui`:** switch the two imports to the
   granular `@mercury/effector/channel` and alias `@mercury/effector/channel` →
   `../../../packages/mercury-effector/src/channel.ts` — the barrel is then never walked.
2. **`@echo/phoenix` strict-`tsc` lints (REPORT).** `PhoenixGame` is the first consumer to import
   `@echo/phoenix`, surfacing ~3 pre-existing unused-var lints in that vendored package under the island's
   `noUnusedLocals`. Fix minimally (address the 3 lints **in the vendored package** or relax that package's
   `noUnusedLocals`) — it is a vendored-package hygiene fix, not a `GameEdge`/contract change.
3. **`GameEdge.test.tsx` jest-dom matcher types.** A pre-existing test-setup gap (untouched by this rung);
   keep the suite green as-is — do not let it mask a new failure.

## Agent stories

- **AS1 — the additive plug** `[implements R1]`. **Directive:** copy `channel.ts` + the barrel line.
  **Acceptance gate:** `typecheck:mercury && build:mercury` green; `grep -E "@echo|@codemojex|@mercury/ui"
  channel.ts` → 0; resolved barrel export set ⊇ before + `createChannel`; `@codemojex/economy` still green.
- **AS2 — game layer + consumption + glob** `[implements R2, R3]`. **Directive:** copy `model.ts` +
  `PhoenixGame.tsx`; add the alias + `+3` deps + the glob fix; `pnpm install`. **Acceptance gate:** `pnpm
  --filter @codemojex/game typecheck && build` green; the emitted bundle has no `@mercury/ui` / no bare
  external import (else apply snag-1's granular mitigation); `GameEdge.tsx`/`types.ts`/`index.tsx` unchanged;
  `verify:mercury` green.
- **AS3 — the echo/ twin + the live proof** `[implements R4, R5]`. **Directive:** apply the `RoomChannel`
  diff; mount `PhoenixGame` (Phase A) and prove the round-trip; then Phase B flip. **Acceptance gate:** from
  `echo/apps/codemojex`, `TMPDIR=/tmp mix compile --warnings-as-errors` + `mix test` green; the live
  round-trip holds (join→props→`submit_guess`; a rejected guess → `guess_rejected`); Phase B: default mount
  = `PhoenixGame`, `GameLive` = page host, SES caveat recorded.

## Rulings folded (the three forks — RESOLVED, no Operator gate before build)

- **F-cmt3-1 (consumption): RULED** — integrate the prototype's `createChannel` (additive `@mercury/effector`)
  + the game `channel/*`; resolve `@mercury/effector` from source (vite alias + tsconfig paths, the economy
  precedent) **and fix the workspace glob**. Guard: no `@mercury/ui` in the self-contained bundle (snag-1).
- **F-cmt3-2 (transport): RULED = Arm B, reached A-first.** End-state B: the raw `game:<gam>` channel is THE
  transport; `GameLive` slims to the Tier-3 host; `RoomChannel` owns all data. Reached by landing Arm A
  (additive, `index.tsx` untouched, `GameEdge` unchanged) + **proving the round-trip live**, THEN flipping.
  Caveat (INV7): the SES rides a socket param (`data-session`), out of the httpOnly cookie.
- **F-cmt3-3 (Tailwind tokens): DEFERRED to cmt.4.** cmt.3 is the channel/Effector STATE foundation ONLY —
  no Tailwind, no golden `@theme`, no golden screen. cmt.4 builds the styled screen ON this state layer.

## Comprehensive prompt (for the builder)

> Integrate the Operator's Effector Phoenix-channel prototype per this brief and the authoritative body
> [`./cmt.3.md`]. The four JS/TS files at `mercury/docs/game-effector/` are complete — **copy them
> verbatim** into the real trees; apply `room_channel.ex.diff` to echo/. Wire consumption (the
> `@mercury/effector` source alias in vite/vitest/tsconfig, the `+3` island deps) and **fix the workspace
> glob** (`codemojex-node/` → `codemojex/`, both lines). Build **A-first**: land the layers additively with
> `index.tsx`/`GameEdge` untouched, **prove the live round-trip** (join `game:<gam>` → props render in the
> shell → `submit_guess` round-trips), THEN flip to Arm B (default `mount` → `PhoenixGame`; slim `GameLive`
> to the page host passing `{game, session}` data attrs). Carry the three known snags' fixes (self-
> containment mitigation; the `@echo/phoenix` lints; the jest-dom gap). Framing: third person, no gendered
> pronouns for agents, no perceptual/interior-state verbs, forward-tense for unbuilt surface; cite the
> prototype file / `file:line` for every surface, invent nothing. Gates: from `mercury/`, `pnpm run
> typecheck:mercury && build:mercury`, `pnpm --filter @codemojex/game typecheck && build && test`,
> `@codemojex/economy` green, the self-containment grep, the barrel export-set superset; from
> `echo/apps/codemojex`, `TMPDIR=/tmp mix compile --warnings-as-errors && mix test`, `valkey-cli -p 6390
> ping`. Boundary: `mercury/codemojex/apps/game/**` + additive `mercury/packages/mercury-effector/**` + the
> glob line + `echo/…/room_channel.ex` (+ the Arm-B host) — no other echo/ edit, no `@mercury/ui`/
> `@mercury/core` existing-export change, no `git`.
