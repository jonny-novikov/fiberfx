# The dev loop — three processes, one thread of identity

> Grounded 2026-07-02: every command below was run and verified on this machine during the boot
> this document was written from.

## Prerequisites

| Dependency | Check | Expected |
|---|---|---|
| Valkey on `:6390` | `valkey-cli -p 6390 ping` | `PONG` |
| Postgres (dev) | `pg_isready` | `accepting connections` |
| Node ≥ 22.12 + pnpm ≥ 10 | `node --version` | the game's `engines` (`package.json`) |
| Elixir/Erlang via asdf | `cd echo/apps/codemojex && asdf current` | elixir 1.18.4 · erlang 28.5.0.1 (from `echo/.tool-versions`) |
| Rust toolchain | `cargo --version` | any recent; the shell's `target/` is warm (~2.1 GB), so `cargo run` links in seconds |
| Workspace deps | `cd mercury/codemojex && pnpm install` | resolves the mercury workspace root upward |

## The three processes

### 1 — Vite dev server (the game island), `:5173`

```bash
cd mercury/codemojex/apps/game
pnpm exec vite --host 127.0.0.1 --port 5173 --strictPort
```

Serves `src/index.tsx` as a **cross-origin ES module**, transformed on the fly (React JSX,
`@tailwindcss/vite` compiling `theme.css`, the `?inline` import). Verify:

```bash
curl -sf -o /dev/null -w "%{http_code}\n" http://127.0.0.1:5173/src/index.tsx   # → 200
```

The served module's first line shows `import.meta.env = {...}` — the smoke flag appears there
only when the server was started with it (see § The smoke flag).

### 2 — Phoenix (the engine), `:4000`

```bash
cd echo/apps/codemojex
TMPDIR=/tmp GAME_DEV_URL=http://127.0.0.1:5173/src/index.tsx mix phx.server
```

- **`TMPDIR=/tmp` is mandatory for all `mix` commands** in this repo (the harness tmp overlay
  hits ENOSPC and surfaces as spurious I/O failures).
- **`GAME_DEV_URL`** is the dev-only override (`game_live.ex:41-46`): when set, `GameLive`
  assigns the island's bundle URL to the Vite entry instead of `GameBundle.src()` (the
  edge/local built bundle). Unset it to fall back to the built artifact.
- Boot is healthy when the log shows
  `Running CodemojexWeb.Endpoint with Bandit … at 127.0.0.1:4000`. A
  `{:missing_token, "ECHO_BOT_HELLO_TOKEN"}` warning is benign — the live Telegram poller stays
  off; the game itself is unaffected.

Verify: `curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/` → `200`
(`<title>Codemoji</title>`).

### 3 — The Tauri shell

```bash
cd mercury/codemojex/apps/game-tauri
PHX_APP_URL=http://localhost:4000 bin/run.sh
```

A plain `cargo run` (no Tauri CLI needed): the window points at the **external** Phoenix URL, so
it opens immediately — there is no local dev server to wait on. The dev panel is available in the
window via the floating button or **Ctrl+`**.

### The orchestrator script

`mercury/codemojex/apps/game-tauri/bin/dev-local.sh` starts (1) idempotently (reuses a running
Vite) and (3) in the foreground, and **prints** the (2) command — Phoenix deliberately runs in its
own terminal (its own asdf toolchain; `GAME_DEV_URL` wanted at boot). Closing the shell tears
Vite down via a trap.

## The flow in the window

`/` (welcome) → `/lobby` (LobbyLive) → `/game/:gam` (GameLive — the page that mounts the island).
Reaching `/lobby` requires the platform auth handshake (the Telegram gate — a redirect back to `/`
is the gate working, not a bug; see
[troubleshooting.md](./troubleshooting.md)).

## Reload semantics — fast-reload today, HMR after `phoenix:build`

Two tiers, depending on the **host page's boot JS** (`echo/apps/codemojex/priv/static/assets/app.js`):

- **Fast-reload (works today):** edit `mercury/codemojex/apps/game/src/**` → reload the game view
  in the shell → the dynamic import re-fetches from Vite → fresh code. No rebuild anywhere.
- **True HMR (react-refresh + in-place remount):** the island's entry self-accepts hot updates
  and remounts from retained props (page + socket never reload) — but the **committed `app.js`
  does not yet carry the new `@codemojex/liveview-boot` wiring** that injects `/@vite/client` and
  the `/@react-refresh` preamble (verified: zero occurrences in the committed asset). Unlock it
  with the Operator-run pass:

  ```bash
  pnpm --filter @codemojex/game phoenix:build    # bin/phoenix-modules-build.sh — rewrites committed echo/ assets
  ```

  then hard-reload the shell. Until then, use fast-reload.

## The smoke flag (`VITE_GAME_SMOKE`)

`import.meta.env.VITE_GAME_SMOKE` is baked per Vite **server run** — toggling it means
restarting process (1):

```bash
# smoke ON (the island renders the GameSmoke probe instead of the game)
VITE_GAME_SMOKE=1 pnpm exec vite --host 127.0.0.1 --port 5173 --strictPort
# smoke OFF — start it plain (the default; the real game renders)
```

Verify which mode is live without opening the window:
`curl -s http://127.0.0.1:5173/src/index.tsx | head -1` — the inlined `import.meta.env` object
shows `"VITE_GAME_SMOKE": "1"` only in smoke mode. Full procedure + what to observe:
[testing.md](./testing.md) § The pixel proof.

## Teardown

Close the shell window (kills the `codemoji-devtools` process; the script variant also traps
Vite down), then `Ctrl+C` (or `kill`) the Vite and Phoenix processes. Check stragglers:
`lsof -nP -i :4000 -i :5173`.
