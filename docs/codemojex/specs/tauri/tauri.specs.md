# codemojex Tauri track — spec index (`cmt.N`)

> The rung ladder + carve-stubs for the Tauri desktop-shell track. Design canon: [`./tauri.design.md`]
> (scope · as-built reconcile · the golden port surface · the Operator forks F1–F4). Program canon:
> [`../../program/codemojex.program.md`]. Rungs are slugged **`cmt.N`**; the AAW progress scope is
> **`cm-tauri`**. Full triads (`cmt.N.{md,stories.md,llms.md}`) are carved per rung at ship time — the
> stubs below are the source until then.

## The ladder

| Rung | Title | App(s) | Risk | Depends | Triad |
|---|---|---|---|---|---|
| **cmt.1** | Shell run-loop (wrap local Phoenix; welcome → lobby → game in-window + dev panel) | game-tauri | LOW | — | ✅ **shipped** (stub below) |
| **cmt.2** | Local-bundle dev wiring (serve the LOCAL bundle, not the edge pointer) | codemojex (+ game) | LOW–MED | cmt.1, F2 | ✅ **shipped** (stub below) |
| **cmt.3** | **Effector Phoenix-channel state foundation** (integrate the Operator prototype: `createChannel` + `PhoenixGame` + the `RoomChannel` twin; Arm B, A-first; prove live) | game + additive `@mercury/effector` + echo/ `RoomChannel` | MED–HIGH | cmt.2 | ✅ **shipped Phase A** ([`./cmt.3.md`]) |
| **cmt.4** | The real screen — in-progress (**Tailwind v4 + golden tokens** [deferred from cmt.3] + re-implement `GoldenInProgressScreen` natively on the cmt.3 state layer; live prop map) | game | MED–HIGH | cmt.3, F3 | stub below |
| **cmt.5** | The real screen — finished + events (`GoldenAnswerReveal`; bridge events) | game | MED | cmt.4 | stub below |
| cmt.6 | Tier-1/2 fidelity (welcome + lobby in the desktop window) | codemojex | LOW–MED | cmt.5 | later |
| cmt.7 | Dev-panel as product (`export_events` IPC; privileged runtime taps) | game-tauri | MED | cmt.1 | later |
| cmt.8 | Distributable (build/sign/installers; prod `check_origin` allowlist) | game-tauri (+ codemojex) | MED–HIGH | cmt.5 | later |

**Build order:** cmt.1 → cmt.2 → cmt.3 → cmt.4 → cmt.5 → (cmt.6 ∥ cmt.7 ∥ cmt.8). **This week = cmt.1–cmt.5.**

## Brands

**None new.** The track consumes the existing BCS ids across the `mount(el, props, bridge)` bridge —
`SES` (session), `ROM`/`GAM` (room/game), `PLR` (player), `GES` (guess). No `cmt` entity is minted. (If
cmt.7's privileged runtime taps ever persist a diagnostic entity, a 3-char namespace is assigned then,
verified free against the catalog in [`../../codemojex.roadmap.md`].)

## Boundary

Wider than a standard codemojex rung (see [`./tauri.design.md`] §6): three trees —
`mercury/codemojex/apps/game-tauri` (shell), `mercury/codemojex/apps/game` (island), and — for wiring
rungs only — `echo/apps/codemojex` (`static_paths` / `check_origin` / `game_props`). `node/codemoji-design`
is **read-only** — a **visual reference only** (**[RECONCILE]** the Operator ruled the golden components
**re-implemented natively** in `@codemojex/game` (cmt.4–cmt.5), **not** vendored; the old "vendored under
F1-A" is superseded. cmt.3 is the upstream **Effector Phoenix-channel state layer** — see the cmt.3 stub +
[`./cmt.3.md`]). The four BCS libs are never edited. **Pathspec commits
per-tree; never `git add -A`.** A rung touching `echo/apps/codemojex` runs that app's full gate ladder.

## Determinism posture

No id-mint / process / lease / schema surface is introduced by cmt.1–cmt.5 (the shell is a viewer; the
island is presentational; the bridge carries ids minted elsewhere). So the **≥100 determinism loop is not
required** on this track — the honest posture is a build+run smoke + the per-surface gate. (A codemojex
edit under F3-A that touches `game_props` runs codemojex's own suite, not a determinism loop.)

---

## Stubs — carve next; [`./tauri.design.md`] is the source

### cmt.1 — Shell run-loop
The `game-tauri` Tauri shell builds and launches, wraps the locally-running Phoenix on `:4000`, and the
full three-tier flow renders in the native window with the dev panel available. **Near-floor:** the debug
binary already builds; this rung formalizes the run entrypoint and *verifies the loop end-to-end*.
- **Status:** ✅ **SHIPPED 2026-07-01** (Director-solo). Delivered `bin/run.sh` + the README run-section
  (the CLI-free `cargo run` path) + the build-unblock (`src`→`src-tauri` reconcile · generated icon set ·
  the three JSON-comment config keys `tauri-build` rejected). Verified: `cargo build` clean → `cargo run` →
  window process alive; the webview loaded Tier-1 welcome (Phoenix logged `GET /` from the webview, distinct
  from curls); `/` + `/lobby` serve 200 under `dev_auth_bypass`. Not agent-verifiable (macOS TCC blocks
  screen-capture + AppleScript): the visual click-through + the Ctrl+` panel — Operator-observed in-window.
- **Scope In:** a documented run entrypoint (a `cargo run` / `cargo tauri dev` script + a README run
  section + the `PHX_APP_URL` knob); verify welcome → lobby → game in-window; verify the dev panel taps
  the LiveView `/live` frames (Ctrl+`).
- **Scope Out:** local-bundle wiring (cmt.2); the golden screen (cmt.3+); any codemojex edit.
- **Risk:** LOW — game-tauri only, no backend edit. **Formation:** Solo/Duo.
- **Depends:** Phoenix `:4000` up with `dev_auth_bypass` + Postgres `codemojex_dev` + Valkey `:6390`.
- **Acceptance (sketch):** `cargo build` clean; `PHX_APP_URL=http://localhost:4000 cargo run` opens the
  window; welcome → "Играть" → `/lobby` (a `SES` minted via the dev bypass) → enter room → `/game/:gam`
  renders the current island; Ctrl+` shows `/live` frames streaming. **Mutation guard:** pointing
  `PHX_APP_URL` at a down port shows a connection error (the URL is load-bearing).

### cmt.2 — Local-bundle dev wiring
Make the running Phoenix serve the **locally-built** game bundle instead of the deployed edge pointer, so
the shell renders the game under development. Grounded in `Edge.game_url/0 = fetch_pointer() || fallback()`
(`edge.ex:42-44`) + the `static_paths` gotcha (`codemojex_web.ex:8`).
- **Status:** ✅ **SHIPPED 2026-07-01** (Director-solo). **F2 RULED → Arm D (new): a prod-safe `GAME_DEV_URL`
  override in `GameLive`** (`dev_bundle_url/0`: `System.get_env("GAME_DEV_URL") || GameBundle.src()`) so the
  game module loads from the game's **Vite dev server** (fast reload — no rebuild, no Phoenix restart),
  bypassing `GameBundle`'s immutable same-origin serve. (Arms A/B/C retained for a committed static bundle.)
  Delivered: the `GameLive` override + `bin/dev-local.sh` orchestrator + the README "Local game-dev loop".
  Verified: `mix compile --warnings-as-errors` clean; `GET /game/<GAM>` renders
  `data-bundle="http://127.0.0.1:5173/src/index.tsx"`; Vite serves that module with
  `Access-Control-Allow-Origin: http://localhost:4000` (cross-origin `import()` allowed). Boundary: this rung
  edited `echo/apps/codemojex` (one dev-gated line) — codemojex compile gate run. Not agent-verifiable (TCC):
  the pixel render — Operator-observed. **True hot-swap** (vs. fast-reload) is a follow-up (needs Vite's
  `/@vite/client` in the module graph).
- **Scope In:** the ruled F2 arm — `GAME_EDGE_HOST=<unreachable>` + `GAME_ASSET_URL=<local>`; if Arm A,
  the one-line `game` add to `static_paths`; a scripted, documented dev env (env + start order).
- **Scope Out:** changing bundle *contents* (cmt.3+); the golden screen.
- **Risk:** LOW–MED — Arm A edits `codemojex_web.ex` (runs the codemojex gate); Arm B/C are env-only.
  **Formation:** Duo.
- **Depends:** cmt.1; ruling **F2**.
- **Acceptance (sketch):** with the env set, `Edge.game_url/0` resolves to the local URL; `GET
  /game-bundle/<file>` serves the local bytes; the `/game/:gam` page in the shell dynamic-imports the
  LOCAL bundle (verified by a hash/marker); reverting restores the edge pointer. **Mutation guard:**
  without `GAME_EDGE_HOST` black-holing, the live edge pointer wins (the override is load-bearing).

### cmt.3 — Effector Phoenix-channel state foundation
**Full triad carved:** [`./cmt.3.md`] (authoritative) · [`./cmt.3.stories.md`] · [`./cmt.3.llms.md`].
**[RECONCILE] — the Operator ruled the forks + supplied a prototype** (`mercury/docs/game-effector/`, a
complete unapplied Effector Phoenix-channel slice). cmt.3 is now the **channel / Effector STATE foundation
only**; all Tailwind / golden-token / golden-screen work **moves to cmt.4** (F-cmt3-3 deferred). Integrate
the prototype's three layers into the real trees + fix the workspace glob + apply the echo/ `RoomChannel`
diff + **prove a live round-trip**, reaching the ruled **Arm B** transport (the raw `game:<gam>` channel is
THE transport) **A-first**.
- **Status:** ✅ **SHIPPED — Phase A (mercury foundation) 2026-07-01** (`/cm-ship`, Duo). Delivered **D1**
  `createChannel` (additive, effector-only) · **D2** `channel/{model,PhoenixGame}` · **D3** consumption +
  **Arm A** — the "workspace-glob fix" became *fold the game into the mercury workspace* (delete the
  vestigial nested `pnpm-workspace.yaml` + drop the `!codemojex/apps/game` exclusion), since the Operator's
  reorg had moved `@echo/phoenix*` into `mercury/packages/` (Operator-ruled). Harden: a jest-dom
  **dual-`vitest`-major** fix (`test/setup.ts` + `src/vitest.d.ts`) + 3 ratified `phoenix/src`
  `noUnusedLocals` fixes. **Gate GREEN:** `@codemojex/game` typecheck 0 · build (self-contained `mount`) ·
  **23/23** · `model.test.ts` mutation-verified. **Deferred to `/codemojex-ship`** (echo/ + live-proof-gated):
  **D4** the `RoomChannel` twin + **Phase B** the Arm-B flip (`game_live.ex`/`index.tsx` + the INV7 SES
  caveat), after the Operator observes the live round-trip (INV5, TCC fallback). **Follow-ons:** the edge
  Docker deploy → rewrite to build from the `mercury/` workspace context; the dual `vitest` major (3.x
  hoisted vs 4.x game) wants convergence (separate concern).
- **Scope In:** `@mercury/effector` `createChannel` (additive: new `channel.ts` + a barrel line, no
  `@echo/phoenix` dep); the game `channel/{model.ts,PhoenixGame.tsx}` (a `Socket` + `game:<id>` channel →
  Effector `$props`; renders `GameEdge` untouched); `@mercury/effector` consumed from source (vite alias +
  tsconfig paths, the economy precedent) + `+3` island deps; the **workspace-glob fix**
  (`codemojex-node/` → `codemojex/`); the echo/ `RoomChannel` twin of `GameLive` (the Operator's diff); a
  proven **live round-trip** (join → props → `submit_guess`), then the **Arm-B flip** (default `mount` →
  `PhoenixGame`; `GameLive` slims to the page host).
- **Scope Out:** all Tailwind / golden tokens / golden screen (cmt.4); `GameProps` balance/boost (cmt.4, F3);
  react-i18next (cmt.4); any echo/ edit beyond the channel-transport concern (`room_channel.ex` + the Arm-B
  host).
- **Risk:** MED–HIGH — an echo/ channel **contract change** (`RoomChannel` twin) + a transport flip + a live
  proof. **Formation:** Trio.
- **Depends:** cmt.2. **Forks — RULED (folded, no gate before build):** F-cmt3-1 = integrate the prototype
  from source + fix the glob · F-cmt3-2 = **Arm B, reached A-first** (prove live, then flip; the SES rides a
  socket param — INV7 caveat) · F-cmt3-3 = **Tailwind deferred to cmt.4**. See [`./cmt.3.llms.md`] § Rulings.
- **Boundary:** JS under `mercury/…` (+ the one glob line) + `docs/…` = one commit; `echo/…/room_channel.ex`
  (+ the Arm-B `game_live.ex`/host) = a **separate** echo/ commit (the Director; that app's gate ladder).
- **Acceptance (sketch):** `typecheck:mercury && build:mercury` green; `pnpm --filter @codemojex/game build`
  emits one self-contained `game-[hash].js` exporting `mount` (grep: no bare external import, no
  `@mercury/ui`); the `@mercury/effector` export set is a superset + `createChannel`; economy still builds;
  `mix compile --warnings-as-errors` + `mix test` green in codemojex; the **live round-trip** holds.
  **Mutation guard:** an unbound channel / unfed model leaves the "Подключение…" fallback (the channel feed
  is load-bearing).

### cmt.4 — The real screen (in-progress)
Port `GoldenInProgressScreen` into the island as the rendered surface, fed by **live** `GameProps` mapped
onto the golden component props, replacing the plain `GameEdge` UI.
> **[RECONCILE] (cmt.4 owed at its ship).** Per the Operator's ruling, "port/vendored/consumed" below means
> **re-implement natively inside `@codemojex/game`** on the **cmt.3 Effector Phoenix-channel state layer**
> (`createChannel` / `PhoenixGame` / `$props`) — **no `@codemoji/design` dependency**. cmt.4's own first
> tasks are the **Tailwind v4 + golden-token `@theme`** (deferred here from cmt.3) + react-i18next, then the
> native `GoldenInProgressScreen` fed by `$props`. cmt.4's own Venus authors the full triad.
- **Scope In:** vendored/consumed board + golden components; a `GameProps → golden props` mapping (`view`
  → `GoldenHero`/`StatusBar`/`EmojiSlots`/`GuessActions`/`EmojiKeyboard`; `leaderboard` →
  `GoldenLeaderboard`); the in-progress state rendered from real props via `mount`.
- **Scope Out:** the finished state + one-off event paths (cmt.5). Under **F3-Arm-A** the server
  `game_props` extension (balances/boost) is this rung's codemojex sub-slice.
- **Risk:** MED–HIGH — the real-screen swap + the data mapping (+ a possible `game_props` change).
  **Formation:** Trio/Squad.
- **Depends:** cmt.3; ruling **F3**.
- **Acceptance (sketch):** the `/game/:gam` page renders the golden in-progress screen from the live
  `game_props`; tapping a keyboard emoji fills a slot; `submit_guess` fires over the bridge (seen in the
  dev panel); the leaderboard shows live standings. **Mutation guard:** a `game:update` prop diff
  re-renders the screen.

### cmt.5 — The real screen (finished) + events
Add `GoldenFinishedScreen` + `GoldenAnswerReveal` on settle, and wire the full event set so the golden
screen is live end-to-end.
- **Scope In:** the finished-state composition + the reveal; the one-off handlers (`guess_rejected` →
  reject toast, `revealed` → reveal, `golden_win` → win toast) via `bridge.onServerEvent`; the
  `submit_guess`/`lock`/`unlock` round-trips via `bridge.pushEvent`.
- **Scope Out:** welcome/lobby polish (cmt.6); the toolkit dev-panel (cmt.7); distribution (cmt.8).
- **Risk:** MED. **Formation:** Trio.
- **Depends:** cmt.4.
- **Acceptance (sketch):** on settle the screen shows the finished state + the revealed answer;
  `golden_win` shows the win toast with diamonds; a rejected guess shows the reason; each event is
  visible in the dev panel. **Mutation guard:** unsubscribing `onServerEvent` stops the toasts.
