# LiveView Boot — developer docs

The **LiveView boot** (`@codemojex/liveview-boot`, `mercury/codemojex/apps/liveview-boot/`) is the
TypeScript LiveView client for the codemojex Mini App: it bootstraps the one shared `LiveSocket`,
carries the `GameIsland` hook that dynamic-imports the React game bundle, bridges the island to the
LiveView transport, and — in dev — hot-wires Vite HMR into a page Vite does not own. It is built in
the Mercury workspace and shipped as the committed `echo/apps/codemojex/priv/static/assets/app.js`
(the "ship-with" tier, same as the vendored `phoenix.js` / `phoenix_live_view.js`).

These docs cover the whole vertical the boot sits in — from EchoMQ jobs on the server to Effector
stores in the island — **grounded in the as-built sources** (every path and payload verified
2026-07-02; where a surface is designed but not shipped, it is marked as a seam).

## The one-paragraph system

A player's guess leaves the React island over a bridge, lands in `GameLive`, is validated + charged
and enqueued as a branded `JOB` on the player's **EchoMQ lane**; the `ScoreWorker` consumer claims
it, scores against the cached immutable secret, writes the guess, records the leaderboard in Valkey,
and fans the result out twice — once onto EchoMQ's **retained event log**, once as an ephemeral
**`Phoenix.PubSub`** broadcast on `"game:" <> game`. `GameLive` (subscribed) re-reads the
privacy-preserving view and pushes a fresh `game:update`; the boot's `GameIsland` hook forwards it
into the island, where it becomes an **Effector** `$props` store update — `prize_pool` re-renders
through `$view`, the leaderboard through `$leaderboard`, with React subscribed via `useUnit`.

```
guess ──bridge──▶ GameLive ──Lanes.enqueue──▶ EchoMQ "cm" ──claim──▶ ScoreWorker
                                                                        │
                       ┌── Events.publish (retained bus log) ◀──────────┤
                       └── Phoenix.PubSub "game:"<>gam ◀────────────────┘
                                     │
                    GameLive push_event("game:update", game_props)
                                     │
             boot GameIsland ──handle.update──▶ model.propsReceived
                                     │
                  $props ─▶ $view (prize_pool) · $leaderboard ─▶ useUnit ─▶ React
```

## File map

| Doc | What it covers |
|---|---|
| [architecture.md](architecture.md) | The three delivery tiers, the import map + one-Socket law, the boot build, the self-contained island bundle (and the F-1 export-signature gate), the two transports over one model, the dev hot-wire |
| [events.md](events.md) | The complete event catalog with payloads: LiveView pushes, island outbound, channel pushes, the bus's retained log, the Effector events, the HMR events |
| [channels.md](channels.md) | The channel layer end to end: `UserSocket` auth, `RoomChannel`, `createChannel`, the `bridgeChannel` adapter, `PhoenixGame` vs `BridgeGame`, and the as-built seams |
| [interactions.md](interactions.md) | Step-by-step walkthroughs: cold boot, mount, the guess round-trip, reveal/golden close, the HMR dev loop, failure modes |
| [effector-pipeline.md](effector-pipeline.md) | The named pipeline in depth: EchoMQ → PubSub → GameUpdates → (`prize_pool`, `leaderboard`) Effector, stage by stage with the real code |

## The load-bearing sources

| Surface | Path |
|---|---|
| The boot (hook + socket + dev wire) | `mercury/codemojex/apps/liveview-boot/src/app.ts` |
| The island entry (mount + hot swap) | `mercury/codemojex/apps/game/src/index.tsx` |
| The game model (Effector) | `mercury/codemojex/apps/game/src/channel/model.ts` |
| The two transport components | `mercury/codemojex/apps/game/src/channel/{BridgeGame,PhoenixGame}.tsx` |
| The channel plug + bridge adapter | `mercury/packages/mercury-effector/src/{channel,bridge}.ts` |
| The LiveView host | `echo/apps/codemojex/lib/codemojex_web/live/game_live.ex` |
| The socket + channel | `echo/apps/codemojex/lib/codemojex_web/channels/{user_socket,room_channel}.ex` |
| The play API + scorer + settle | `echo/apps/codemojex/lib/codemojex/game.ex` |
| The view + leaderboard reads | `echo/apps/codemojex/lib/codemojex/{view,board}.ex` |
| The reveal/golden broadcasts | `echo/apps/codemojex/lib/codemojex/rooms.ex` |

Design record for the hot-swap + deep-Effector work: `docs/codemojex/specs/tauri/hotswap-effector.design.md`.
Delivery canon: `echo/docs/codemojex/frontend-delivery.design.md`.
