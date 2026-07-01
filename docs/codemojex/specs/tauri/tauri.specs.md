# codemojex Tauri track — spec index (`cmt.N`)

> The rung ladder + carve-stubs for the Tauri desktop-shell track. Design canon: [`./tauri.design.md`]
> (scope · as-built reconcile · the golden port surface · the Operator forks F1–F4). Program canon:
> [`../../program/codemojex.program.md`]. Rungs are slugged **`cmt.N`**; the AAW progress scope is
> **`cm-tauri`**. Full triads (`cmt.N.{md,stories.md,llms.md}`) are carved per rung at ship time — the
> stubs below are the source until then.

## The ladder

| Rung | Title | App(s) | Risk | Depends | Triad |
|---|---|---|---|---|---|
| **cmt.1** | Shell run-loop (wrap local Phoenix; welcome → lobby → game in-window + dev panel) | game-tauri | LOW | — | stub below |
| **cmt.2** | Local-bundle dev wiring (serve the LOCAL bundle, not the edge pointer) | codemojex (+ game) | LOW–MED | cmt.1, F2 | stub below |
| **cmt.3** | DS foundation in the island (Tailwind v4 + tokens + gold + `cn` + i18n) | game (+ codemoji-design) | MED | cmt.2, F1 | stub below |
| **cmt.4** | The real screen — in-progress (port `GoldenInProgressScreen`; live prop map) | game | MED–HIGH | cmt.3, F3 | stub below |
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
is **read-only** reuse (vendored under F1-A). The four BCS libs are never edited. **Pathspec commits
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

### cmt.3 — DS foundation in the island
Bring the `@codemoji/design` runtime foundation into the island's Vite build — Tailwind v4 + the token
theme + `gold.png` + the `cn` util + a react-i18next init (bundled ru/en) — **without breaking the ESM
`mount` contract or the bundle's self-containment**. A smoke render of one vendored DS atom proves it.
- **Scope In:** the ruled F1 path (vendor / package / dist); Tailwind v4 in `vite.config.ts`; the token
  theme + gold texture; `cn` + an i18n init module; a smoke render of a DS atom (e.g. `EmojiTile`).
- **Scope Out:** the full golden composition (cmt.4); live-data mapping.
- **Risk:** MED — build-config surgery on a self-contained workspace; the `mount` export + bundle self-
  containment must survive. **Formation:** Trio.
- **Depends:** cmt.2; ruling **F1**.
- **Acceptance (sketch):** `pnpm --filter @codemojex/game build` still emits a single self-contained
  `game-[hash].js` exporting `mount` (grep: no bare external imports); the smoke atom is styled by the
  tokens (gold texture resolves); `useTranslation()` returns real ru copy. **Mutation guard:** removing
  the i18n init makes the smoke render show raw keys.

### cmt.4 — The real screen (in-progress)
Port `GoldenInProgressScreen` into the island as the rendered surface, fed by **live** `GameProps` mapped
onto the golden component props, replacing the plain `GameEdge` UI.
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
