# game-tauri — the codemojex desktop dev loop

> The **codemojex Tauri track** (`cmt.N`): a native Tauri v2 desktop shell
> (`mercury/codemojex/apps/game-tauri`) wrapping the Phoenix-served codemojex game, with the React
> **game island** (`mercury/codemojex/apps/game`, `@codemojex/game`) hot-served from Vite during
> development. These docs cover the as-built system and the local dev loop. Grounded 2026-07-02
> against the live tree; the spec canon lives at the repo root under
> [`docs/codemojex/specs/tauri/`](../../../docs/codemojex/specs/tauri/) (`tauri.design.md` ·
> `tauri.specs.md` · the per-rung triads).

## The documents

| Doc | What it covers |
|---|---|
| [architecture.md](./architecture.md) | The three tiers (Phoenix engine · game island · Tauri shell), the `mount` contract, the Effector state layer, bundle delivery |
| [dev-loop.md](./dev-loop.md) | The 3-process local loop: prerequisites, exact boot commands, the `GAME_DEV_URL` override, reload semantics, teardown |
| [design-system.md](./design-system.md) | The cmt.4.1 foundation: Tailwind v4, the token `@theme`, `cn`, i18n, the `?inline` CSS delivery, rules for board authors |
| [testing.md](./testing.md) | The machine gate ladder, the artifact greps, the node-import gate, the vitest suites, the Operator-observed smoke pixel proof |
| [troubleshooting.md](./troubleshooting.md) | The known gotchas, each with symptom → cause → fix |

## 60-second quick start

Three processes, three terminals (details + verification in [dev-loop.md](./dev-loop.md)):

```bash
# 1 — the game island on Vite :5173
cd mercury/codemojex/apps/game
pnpm exec vite --host 127.0.0.1 --port 5173 --strictPort

# 2 — Phoenix on :4000, importing the island FROM Vite
cd echo/apps/codemojex
TMPDIR=/tmp GAME_DEV_URL=http://127.0.0.1:5173/src/index.tsx mix phx.server

# 3 — the desktop shell wrapping Phoenix
cd mercury/codemojex/apps/game-tauri
PHX_APP_URL=http://localhost:4000 bin/run.sh
```

Or use the orchestrator: `mercury/codemojex/apps/game-tauri/bin/dev-local.sh` starts (1) and (3)
and prints the (2) command — Phoenix runs in its own terminal because it wants its own toolchain
and `GAME_DEV_URL` set at boot.

Edit `mercury/codemojex/apps/game/src/**` → reload the game view in the shell → fresh code. No
rebuild, no Phoenix restart, no edge deploy.

## Where the track stands (2026-07-02)

- **Shipped:** cmt.1 (shell run-loop) · cmt.2 (the `GAME_DEV_URL` local-bundle wiring) · cmt.3
  Phase A (the Effector Phoenix-channel state layer) · the hotswap-effector HMR entry
  (`1c99cfa6`) · **cmt.4.1 — the game DS + i18n foundation** (`457e0f56`).
- **The Classic-first re-sequence (R-classic, 2026-07-02):** cmt.4 was split — **cmt.4.2 = the
  Classic `BoardScreen`** (the frontier) → cmt.4.3 = the Classic finished-state/events → cmt.5 =
  the deferred GOLDEN variant (gold texture + boost).
- **Owed to the Operator:** the cmt.4.1 pixel proof (the smoke, [testing.md](./testing.md) § The
  pixel proof) and the `phoenix:build` pass that unlocks true HMR
  ([dev-loop.md](./dev-loop.md) § Reload semantics).
