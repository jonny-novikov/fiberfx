---
name: codemojex-tauri-track
description: codemojex Tauri desktop-shell track (cmt.N) — native shell wrapping the Phoenix game; ships /cm-ship; cmt.1-3 shipped; GameRoom board-screen decomposition paused pending Operator ruling
metadata: 
  node_type: memory
  type: project
  originSessionId: 8c85ea96-925f-41ca-80a2-7859620110e6
---

**codemojex Tauri (`cmt.N`)** = a native desktop shell (Tauri v2, `mercury/codemojex/apps/game-tauri`) wrapping the running Phoenix codemojex game + the game island `mercury/codemojex/apps/game` (`@codemojex/game`). Canon `docs/codemojex/specs/tauri/` (tauri.design.md · tauri.specs.md ladder). Ships via **/cm-ship** (the Node side; NOT /codemojex-ship). AAW scope `cm-tauri`.

**Shipped 2026-07-01:** cmt.1 (shell run-loop, Director-solo) · cmt.2 (local Vite dev via a `GAME_DEV_URL` override in echo/ GameLive) · **cmt.3 Phase A** — the Effector Phoenix-channel STATE layer: `@mercury/effector` `createChannel` (additive, effector-only) + game `channel/{model,PhoenixGame}` driving `GameEdge` from `$props`. Commits `13652a7f` (game tree + admin.1, Operator out-of-band) + `2d67d8f3` (packages/docs remainder, Director). **Arm A:** the game folded into the mercury workspace (deleted its vestigial nested `pnpm-workspace.yaml` + dropped `!codemojex/apps/game`) since the reorg moved `@echo/phoenix*` → `mercury/packages/`; the built Vite bundle stays self-contained regardless.

**Deferred to /codemojex-ship** (echo/ + live-proof-gated): cmt.3 **D4** (the `RoomChannel` twin of GameLive) + **Phase B** (the Arm-B flip: default `mount`→`PhoenixGame`, GameLive slims to a page host; INV7 = SES rides a socket connect param). Land after the Operator observes the live round-trip (INV5, TCC fallback).

**Follow-ons flagged:** (1) the game dir's standalone edge Docker deploy (`edge.codemoji.games`, Dockerfile + fly.toml + bin/edge-deploy.sh) BREAKS under Arm A (frozen-lockfile + self-containment) — needs a rewrite to build from the `mercury/` workspace context; (2) [[mercury-dual-vitest-jestdom-trap]].

**NEXT (paused mid-escalation to ship cmt.3):** the **GameRoom** (retired name "Board", from `node/codemoji-design/stories/board/`) first-screen migration into `@codemojex/game`. Two design proposals authored + idle (`gameroom.{steelman,steward}.design.md`); Steward's reconcile = GameRoom is a **restyle+rename+additive-grow of the existing GameEdge** (which already composes 5 state-fed components; `sprite.ts` draws the live emojiset), NOT a from-scratch port. Owed: synthesis + `cmt.progress.md` decomposition + an iPhone-Pro-Max Tauri window + a visual-testing rig — all pending the Operator's fork rulings (reuse-vs-report · gate depth · window dims · i18n). [[codemojex-program]] [[cm-ship-program]] [[codemojex-tma-edge]]
