# Interactions

← [README](README.md) · siblings: [architecture](architecture.md) · [events](events.md) ·
[channels](channels.md) · [effector-pipeline](effector-pipeline.md)

End-to-end walkthroughs of the flows a developer actually debugs. Each step names the surface that
executes it.

## 1 · Cold boot (page load → connected island)

1. **Root layout** (`CodemojexWeb.Layouts.root/1`): modulepreload hints → the import map → the
   Telegram web-app script → `<script type="module" src="/assets/app.js">`.
2. **The boot module loads**: bare `@echo/*` imports resolve through the import map;
   `new LiveSocket("/live", Socket, { params: { _csrf_token }, hooks: { GameIsland } })`,
   `connect()`, `window.liveSocket = liveSocket`.
3. **`GameLive.mount/3`** (server): resolves the SES → player, parses the `GAM`, reads
   `Codemojex.game_view/1`, subscribes to `Phoenix.PubSub` topic `"game:" <> gam` (connected pass),
   assigns `game_bundle: dev_bundle_url()` and `game_props`.
4. **Render**: `#game-root` with `phx-hook="GameIsland"`, `phx-update="ignore"` (LiveView will
   never re-render inside it — updates ride `push_event`), `data-bundle`, `data-props`, plus a
   `modulepreload` for the bundle.
5. **`GameIsland.mounted()`** (boot): read `data-bundle`; dev-detect (`devOriginOf`) and, when dev,
   `wireViteDev` (§5); `import(bundle)`; `mount(el, safeParse(data-props), bridge)`; register
   `game:update` + the three one-off `handleEvent`s.
6. **`mount()`** (island entry): build the `LiveMount` facade, create the Effector model, render
   `<BridgeGame model bridge initial>`; `BridgeGame` binds
   `bridgeChannel(bridge, { joinReply: initial })` — the synthetic join seeds `$props` — and
   `GameEdge` paints **immediately from the initial props** (no fallback flash, no client fetch).

## 2 · A guess, round-trip (the happy path)

Player taps six keys, hits «Угадать»:

1. **GameEdge**: `bridge.pushEvent("submit_guess", { emojis: picks })`, clears picks.
2. **Boot bridge** → `this.pushEvent` → the LiveView socket → **`GameLive.handle_event/3`**.
3. **`Codemojex.submit/3`** (`Guesses`): game open + not expired + codes valid for the set →
   `Locks.merge` overlays pinned positions → `Wallet.charge_guess` (keys on a paid room, clips on a
   free one) → `Lanes.enqueue(Bus.conn(), "cm", player, JOB, payload)` — the lane is the
   **player's PLR**, so the bus rotates service across players and a masher cannot starve the field.
   `GameLive` replies `{:noreply}` — the score does *not* return on this call.
4. **`EchoMQ.Consumer`** (`:cm_score`, supervised in `Codemojex.Application`) claims the job via
   `Lanes.claim`; **`ScoreWorker.handle/1`** scores against the cached immutable secret, writes a
   `GES` guess, bumps the attempts counter, records `Board.record(game, player, total)` (Valkey:
   `HSET …:base` max + `ZADD …:board`).
5. **Fan-out** (classic game): `Events.publish` onto the retained bus log **and**
   `Phoenix.PubSub.broadcast("game:" <> gam, {:scored, %{game, player: name, pct, eff}})`.
6. **`GameLive.handle_info({:scored, _})`** → `push_props/1` → re-read `game_view` + `leaderboard`
   + `my_history` → `push_event(socket, "game:update", game_props)`.
7. **Boot**: the `game:update` handler → `handle.update(props)` → facade records `live.props` and
   fires `model.propsReceived(props)`.
8. **Effector**: `$props` updates → `$view` (new `prize_pool`) and `$leaderboard` recompute →
   `useUnit` re-renders `GameEdge`. The player sees the board move.

A perfect 600 on an `:open` game additionally triggers `Rooms.close_game/1` (the settle queue takes
it from there).

## 3 · Rejection, reveal, golden close

- **Rejection**: `submit/3` returns `{:error, reason}` → `GameLive` pushes
  `guess_rejected %{reason}` → boot fans it to the island's listeners → GameEdge toast
  (`rejectText/1`: «Недостаточно ключей», «Игра завершена», …) + `model.events.guessRejected`.
- **Reveal**: `Rooms.broadcast_revealed/4` sends the ONE fat `{:revealed, …}` (secret, nonce,
  commitment, final board, payouts, state) → `GameLive` pushes `revealed` **and** follows with a
  fresh `game:update`. A blind golden game's scores exist server-side all along but first surface
  here.
- **Golden win**: `Rooms.announce_golden/2` → `{:golden_win, %{game, diamonds}}` → toast
  «Победа! +N💎» + `model.events.goldenWin`.

## 4 · The HMR dev loop (hot swap)

Setup: game dev server running (`vite` in `apps/game`, entry
`http://127.0.0.1:5173/src/index.tsx`); Phoenix started with `GAME_DEV_URL` pointing at it; open the
game (browser or the Tauri shell).

1. `GameIsland.mounted()` detects the source-path bundle → `wireViteDev(origin)`: awaited
   `/@react-refresh` (preamble installed exactly once) then `/@vite/client` (the HMR socket) →
   then imports the entry through the dev server.
2. **Edit `GameEdge.tsx`** (a component): react-refresh swaps the component in place. Picks, toast,
   scroll — all React state — survive. Neither the page nor the LiveView socket notices.
3. **Edit `model.ts` or `index.tsx`** (not a component): the update bubbles to the self-accepting
   entry; the OLD module's `accept` callback hands the retained `LiveMount` to the NEW module's
   `remount`: old root unmounted, fresh root + **fresh model built by the new code**, seeded from
   `live.props` (the latest `game:update`, not the stale mount props). In-flight picks reset —
   deliberately: preserving them would mean running old model logic against a new tree.
4. **Kill the dev server and edit anyway** → next mount logs
   `GameIsland: vite dev wire failed (dev server up?)` and, if the entry import also fails,
   `GameIsland: game bundle failed to load` — the page and socket stay alive; restart the server
   and re-navigate.

## 5 · Failure modes (what you'll see, where it's handled)

| State | Symptom | Handler |
|---|---|---|
| no `data-bundle` (edge pointer + `GAME_ASSET_URL` both empty) | `GameIsland: no game bundle url…` | boot, `mounted()` guard |
| bundle import fails (edge outage, dev server down) | `GameIsland: game bundle failed to load <url>` — island inert, page alive | boot, guarded `import()` |
| bundle lacks `mount` (see F-1, [architecture.md](architecture.md) §4) | `GameIsland: game bundle has no mount(el, props, bridge) export` | boot; gated at build by the artifact-import check |
| malformed `data-props` | island mounts with `{}` | boot, `safeParse` |
| bad/missing SES on the raw socket | connection refused (`:error`) | `UserSocket.connect/3` |
| unknown `GAM` / dead game route | flash «Room not found» → `push_navigate` to the lobby | `GameLive.mount/3` else-branch |
| guess while closed/expired/broke | `guess_rejected` toast, nothing enqueued | `Guesses.submit/3` cond + wallet |
| LiveView socket drop | LiveView reconnects; hook re-`mounted()` re-imports and re-mounts the island from fresh `data-props` | phoenix_live_view runtime |
