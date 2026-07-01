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
| **cmt.4.1** | **The game DS + i18n foundation** (Tailwind v4 + the verbatim token `@theme` + `cn` + react-i18next + the `?inline` CSS delivery + the dev-flagged `GameSmoke`; the gold texture EXCLUDED — defers with the golden rung) | game | MED | cmt.3 | ✅ **BUILT** (2026-07-02, [`./cmt.4.1.md`]) |
| **cmt.4.2** | **The Classic `BoardScreen`** (compose the Classic Free/Paid board natively on the cmt.4.1 stack; the `GameProps`→board mapping replacing the plain `GameEdge` internals; balances omit/neutralize per **F3✓**) | game | MED–HIGH | cmt.4.1 | 📋 **frontier** (Venus carves the triad at ship) |
| **cmt.4.3** | **The Classic finished-state + events** (settle/reveal composition; `guess_rejected`/`revealed`/win handling over the bridge — folded from the old cmt.5 scope) | game | MED | cmt.4.2 | stub below |
| **cmt.5** | **The GOLDEN variant — deferred by R-classic** (the golden screens + the gold texture + `GoldenAnswerReveal` + the boost surface) | game | MED–HIGH | cmt.4.3 | later (stub below) |
| cmt.6 | Tier-1/2 fidelity (welcome + lobby in the desktop window) | codemojex | LOW–MED | cmt.4.3 | later |
| cmt.7 | Dev-panel as product (`export_events` IPC; privileged runtime taps) | game-tauri | MED | cmt.1 | later |
| cmt.8 | Distributable (build/sign/installers; prod `check_origin` allowlist) | game-tauri (+ codemojex) | MED–HIGH | cmt.4.3 | later |

**Build order:** cmt.1 → cmt.2 → cmt.3 → cmt.4.1 → cmt.4.2 → cmt.4.3 → (cmt.5-golden ∥ cmt.6 ∥ cmt.7 ∥ cmt.8).
**cmt.1–cmt.4.1 shipped/built; the frontier is cmt.4.2** (the Classic board — the **R-classic** re-aim, 2026-07-02).

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

### cmt.4 — The Classic game screen (SPLIT: cmt.4.1 · cmt.4.2 · cmt.4.3)
The Operator SPLIT cmt.4 at Bootstrap and re-aimed the split **Classic-first** (**R-classic**,
2026-07-02): the Classic Free/Paid board ships before any golden surface — "Free/Paid" is the existing
`view.free` / `view.guess_fee` distinction already in `GameProps` (no new flow). The native-reimplement
ruling stands (no `@codemoji/design` dependency; `node/codemoji-design` = visual reference only); the
target is the **Classic `BoardScreen`** (`stories/board/BoardScreen.tsx`, the "Game (Free)" board, Figma
94:2974), NOT the golden screen — the golden variant moved whole to cmt.5.

- **cmt.4.1 — the game DS + i18n foundation. ✅ BUILT (2026-07-02, Director-verified); triad
  [`./cmt.4.1.md`].** Tailwind v4 (`@tailwindcss/vite`) in the island build; the verbatim token `@theme`
  port of `tokens.mjs` (asset-backed values excluded); `cn`; react-i18next (bundled ru/en, the `smoke.*`
  seed); the ruled CSS delivery (`?inline` → one `<style data-cmjx-game>` at `mount()`, preflight
  skipped); the dev-flagged `GameSmoke` (`VITE_GAME_SMOKE`, off by default — the branch is folded out of
  the default artifact). The pixel proof stays OWED Operator-observed via the cmt.2 hot-load loop.
- **cmt.4.2 — the Classic `BoardScreen` composition (the frontier).** Compose the Classic board natively
  on the cmt.4.1 stack: the `GameProps`→board mapping replacing the plain `GameEdge` internals; the
  `board.*`/`game.*` i18n namespaces port here; **balances omit/neutralize per the F3 ruling** (nothing
  fabricated; the server `game_props` extension is a deferred `/codemojex-ship` rung). Venus carves the
  triad at its ship. **Risk:** MED–HIGH. **Formation:** Trio/Squad. **Depends:** cmt.4.1.
- **cmt.4.3 — the Classic finished-state + events.** The settle/reveal composition + the one-off event
  handlers (`guess_rejected` → reject, `revealed` → reveal, win handling) via `bridge.onServerEvent`; the
  `submit_guess`/`lock`/`unlock` round-trips via `bridge.pushEvent` (folded from the old cmt.5 scope).
  **Risk:** MED. **Depends:** cmt.4.2.

### cmt.5 — The GOLDEN variant (deferred by R-classic, 2026-07-02)
The golden surface, whole: the golden screen treatments (`GoldenInProgressScreen`/`GoldenFinishedScreen`
re-implemented natively on the Classic stack) + `GoldenAnswerReveal`; the gold texture (`gold.png` /
`--gold-texture` / `bg-gold-texture` — the asset-backed tokens excluded from cmt.4.1's port land here,
with the 1.39 MB raster's delivery-at-scale fork); the `golden_win`/boost surface (needs the server
`game_props` extension — a `/codemojex-ship` rung).
- **Scope Out:** welcome/lobby polish (cmt.6); the toolkit dev-panel (cmt.7); distribution (cmt.8).
- **Risk:** MED–HIGH. **Formation:** Trio/Squad.
- **Depends:** cmt.4.3 (+ the `/codemojex-ship` `game_props` extension for balances/boost).
