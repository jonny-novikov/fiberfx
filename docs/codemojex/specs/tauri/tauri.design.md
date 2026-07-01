# codemojex Tauri track — the native desktop shell over the three-tier game

> **Status:** DESIGN v0 (Director scaffold, 2026-07-01). **DESIGN/SPEC ONLY** — no production code is
> committed from this doc. Grounded **NO-INVENT** against the as-built `echo/apps/codemojex`,
> `mercury/codemojex/apps/{game,game-tauri}`, and `node/codemoji-design`; every surface named below is a
> real file, or is marked **forward-tense**. Canon: [`../../codemojex.design.md`],
> [`../../codemojex.roadmap.md`], the manual [`../../program/codemojex.program.md`]. The rung index and
> per-rung stubs are [`./tauri.specs.md`].
>
> **Naming reconcile.** The Operator's working name is the `tauri/` folder (honored here); the house
> rung slug is **`cmt.N`** (codemojex-tauri, by the `cmn.` = codemojex-notifications precedent) and the
> AAW progress scope is **`cm-tauri`**.

## 0. Scope and intent

Ship a **native desktop product**: a Tauri v2 window that presents the *whole* codemojex game — the
three-tier flow **welcome → Lobby → the React game** — served by the codemojex Phoenix app, with the
**real golden-game screen** (reused from the `@codemoji/design` MVP) as the injected Tier-3 island, and
a **channel/event dev panel** overlaid for development. The near-term target is a **local development
environment** (the shell wrapping a locally-running Phoenix on `:4000`); the arc ends at a
**distributable** signed build.

The product is one entity's life across three surfaces that already exist as peers joined by the
branded thread (`SES` session · `ROM`/`GAM` game · `PLR` player · `GES` guess): the shell does not fork
the app, it **wraps** it.

## 1. Reconcile — the as-built surface (ground truth)

Everything in this section is on disk **today**; file:line anchors are from a fresh probe.

**The shell — `mercury/codemojex/apps/game-tauri/` (builds; runs).** A Tauri v2 app
(`src-tauri/Cargo.toml`: `tauri` v2 + `tauri-plugin-websocket`). `src-tauri/src/lib.rs` creates one
window at `PHX_APP_URL` (default `http://localhost:4000`) via `WebviewUrl::External`, injects
`dev-panel/inject.js` as an `initialization_script` (it wraps `window.WebSocket` at document-start, so it
taps every Phoenix Channel/LiveView frame — toggle **Ctrl+`**), and exposes an `export_events` command.
The debug binary compiles (`src-tauri/target/debug/codemoji-devtools`, 41.7 MB). *Scaffold reconcile done
this session:* the Rust project dir was renamed `src` → `src-tauri` (README/CLI convention), the icon set
was generated, and three JSON-comment (`"//…"`) keys that `tauri-build`'s strict parser rejects were
removed from `tauri.conf.json` / `capabilities/default.json`.

**The game island — `mercury/codemojex/apps/game/` (`@codemojex/game`).** A Vite/React **19.2.7** island
whose only outward contract is `mount(el, props, bridge) → { update, unmount }`
(`src/index.tsx`), rendering `src/GameEdge.tsx` from `GameProps` (`src/types.ts`:
`{ view, leaderboard, history, me }`) over a `Bridge` (`{ pushEvent, onServerEvent }`). It builds a
content-hashed ESM bundle into `echo/apps/codemojex/priv/static/game` (`vite.config.ts`). A built bundle
already exists: `priv/static/game/game-CH1WlMZX.js` (193 KB) + a Vite manifest. This is the **current**,
plain screen — *not yet* the golden design.

**The backend three tiers — `echo/apps/codemojex/` (Phoenix, running on `:4000`).**
- **Tier 1 (welcome):** `GET /` → `PageController.home` (`router.ex:32`), which embeds
  `priv/static/welcome/index.html` at compile time (`page_controller.ex:19-23`). No auth on `/`. Welcome
  → `/lobby` via a plain anchor.
- **Tier 2 (Lobby):** `live "/lobby", LobbyLive` under `pipe_through :browser` (`router.ex:45-51`);
  `mount` resolves the `SES` and bounces to `/` if absent (`lobby_live.ex:18-32`); `enter_room` →
  `push_navigate` to `~p"/game/#{gam}"` (`lobby_live.ex:62-67`).
- **Tier 3 (game):** `live "/game/:gam", GameLive` (`router.ex:45-51`); `mount` assigns
  `game_bundle: GameBundle.src()` + `game_props` (`game_live.ex:26-38`) into a div
  `phx-hook="GameIsland"` (`game_live.ex:48-55`). The `GameIsland` hook dynamic-imports the bundle and
  calls `mod.mount(el, props, bridge)` (`assets/js/app.js:33-42`). Events **out**: `submit_guess` /
  `lock` / `unlock`; **in**: `game:update` / `guess_rejected` / `revealed` / `golden_win`.

**Bundle resolution + the local-dev knobs.** `Edge.game_url/0 = fetch_pointer() || fallback()`
(`edge.ex:42-44`); the pointer host is `GAME_EDGE_HOST || "edge.codemoji.games"` (`edge.ex:54`), the
fallback is `System.get_env("GAME_ASSET_URL")` (`edge.ex:75`); `GameBundle` fetches the bytes once and
re-serves them **same-origin** at `/game-bundle/:file` (`game_bundle.ex:38-45`). **The live edge pointer
wins unless black-holed.** Two gotchas: `priv/static/game/` is **not** in `static_paths`
(`codemojex_web.ex:8`), so a local bundle needs a one-line `static_paths` add *or* an external static
server; and `config :codemojex, :game_asset_url` (`runtime.exs:52`) is **dead code** — set the env var.

**Local dev already unblocked.** `config/dev.exs:21` sets `dev_auth_bypass: true`, so `MiniAppAuth` mints
a session for a fixed fake Telegram uid `999000001` ("dev") — **no Telegram, no forged initData**
(`mini_app_auth.ex:24,68-86`). Dev also sets `check_origin: false` (`dev.exs:30`) and ships **no CSP**, so
a Tauri webview connects to `/live` + `/socket` out of the box. Prereqs (both **verified up**): Postgres
`codemojex_dev` + Valkey `:6390` (`PONG`).

**The real screen — `node/codemoji-design/stories/golden-game/` (`@codemoji/design`).** The designated
MVP: `GoldenScreen.tsx` exports `GoldenInProgressScreen` + `GoldenFinishedScreen`, composing ~10 `board/`
components (`StatusBar`, `EmojiSlots`, `GuessActions`, `EmojiKeyboard`, `BoardTabs`, `GameRules`,
`ShareKeys`, `lib/BoardCard`, `lib/EmojiTile`, `lib/SpriteEmoji`), a DS `Button`, and the golden surfaces
`GoldenHero` / `GoldenLeaderboard` / `GoldenAnswerReveal`. Stack: **Tailwind v4** (`@tailwindcss/vite`) +
a token pipeline (`tokens/tokens.mjs → src/theme.mjs → dist/theme.css`, the `--gold-texture`/`gold.png`),
the `cn` util (`clsx` + `tailwind-merge`), **react-i18next** (`stories/i18n/i18n.ts` + `locales/{ru,en}`),
and **React 19.2.7**. Reference screenshots exist (`gameplay/assets/golden-room-*.png`).

## 2. The product frame

The shell is Mode A of the game-tauri README — *wrap the remote (local) Phoenix app*; nothing about the
React build changes to make the window render. "Complete product" = the three tiers all present and
faithful in the native window:

1. **Tier 1 / Tier 2 are essentially free** — Phoenix already serves welcome + Lobby; the shell just
   points at `:4000`. The work is *fidelity in a desktop window* (viewport, the Telegram-web-app script
   degrading gracefully outside Telegram), not new surface.
2. **Tier 3 is the build** — replace the plain island with the golden screen and feed it live data.
3. **The dev panel** rides along as the developer surface (channel/LiveView frames), and later grows into
   a real toolkit (Tauri IPC export, privileged runtime taps).

## 3. The real screen — the golden port surface

Reusing the MVP is a **port**, not a copy, because the golden screen is the capstone of a design system.
Four alignments make it tractable, and one gap makes it a design decision:

- **Sprite model is identical end-to-end.** DS `SpriteEmoji` uses the same `"XXYY"` (col,row) sprite-sheet
  scheme as the island's `types.ts` **and** the server's `Codemojex.EmojiSet`. Live `view.emojiset`
  (`sprite_url`/`cell_size`/`cols`/`rows`/`codes`) maps directly to `SpriteConfig` — no translation.
- **React majors match** (both 19.2.7) — vendoring DS components carries no cross-major hazard.
- **The bridge contract is untouched** — `mount(el, props, bridge)` stays; only what's *rendered* changes.
- **i18n and tokens are concrete, bounded tasks** — initialize react-i18next (bundled ru/en,
  `useSuspense:false`) and wire Tailwind v4 + the token theme + `gold.png` into the island's Vite build.
- **THE GAP (a reconcile finding → fork F3):** the golden `StatusBar` wants `diamonds`/`clips`/`keys`
  and `GoldenHero` wants a `boost` multiplier; the live `GameProps` carries **none of these** (`me` is a
  bare `PLR`). Closing it means extending `GameLive.game_props/3` server-side, or deriving/placeholdering
  client-side. Decided in F3.

## 4. The rung ladder (the spec-driven build plan)

Rungs are thin and provable; this-week = **cmt.1 – cmt.5**. Risk drives formation
(`program.md` topology router). The full per-rung triads are carved at ship time; stubs live in
[`./tauri.specs.md`].

| Rung | Title | App(s) | Risk | Depends | Status |
|---|---|---|---|---|---|
| **cmt.1** | **Shell run-loop** — game-tauri wraps local Phoenix; welcome → lobby → game verified in the native window + dev panel | game-tauri | LOW | — | 📋 near-floor (binary builds; formalize + verify) |
| **cmt.2** | **Local-bundle dev wiring** — Phoenix serves the LOCAL game bundle (not the edge pointer); a scripted, documented dev env | codemojex (+ game) | LOW–MED | cmt.1, **F2** | 📋 forward |
| **cmt.3** | **DS foundation in the island** — Tailwind v4 + token theme + `gold.png` + `cn` + i18n init in the game's Vite build; the ESM bundle still builds; a smoke render | game (+ codemoji-design) | MED | cmt.2, **F1** | 📋 forward |
| **cmt.4** | **The real screen (in-progress)** — port `GoldenInProgressScreen`; map live `GameProps` → golden props; replace the `GameEdge` UI | game | MED–HIGH | cmt.3, **F3** | 📋 forward |
| **cmt.5** | **The real screen (finished) + events** — `GoldenFinishedScreen` + `GoldenAnswerReveal` on settle; wire `guess_rejected`/`revealed`/`golden_win` + `submit_guess` | game | MED | cmt.4 | 📋 forward |
| cmt.6 | **Tier-1/2 fidelity** — welcome + lobby polish in the desktop window | codemojex | LOW–MED | cmt.5 | later |
| cmt.7 | **Dev-panel as product** — the event panel integrated + `export_events` via Tauri IPC; privileged runtime taps | game-tauri | MED | cmt.1 | later |
| cmt.8 | **Distributable** — prod build/sign/installers; `check_origin` allowlist for the Tauri origin; the edge/pointer story | game-tauri (+ codemojex) | MED–HIGH | cmt.5 | later |

**Build order:** cmt.1 → cmt.2 → cmt.3 → cmt.4 → cmt.5 → (cmt.6/cmt.7/cmt.8). cmt.3+ are gated on the
Operator ruling **F1**; cmt.4 on **F3**.

## 5. Open decisions for the Operator (frame only — the Director rules via `AskUserQuestion`)

- **F1 — How does the island consume `@codemoji/design`? — [RECONCILE] RULED CLOSED (2026-07-01).** The
  Operator ruled a path outside A/B/C: the golden components are **re-implemented natively inside
  `@codemojex/game`** with **no `@codemoji/design` dependency** (`node/codemoji-design` = visual reference
  only), state via an **additively-extended `@mercury/effector`**. **Split across the ladder:** cmt.3 is now
  the **Effector Phoenix-channel STATE foundation** (the Operator's prototype — `createChannel` +
  `PhoenixGame` + a `RoomChannel` twin; Arm B, A-first; the three forks resolved F-cmt3-1/2/3 in
  [`./cmt.3.llms.md`] § Rulings); the **Tailwind v4 + golden-token + native golden-screen** work is **cmt.4**,
  built on that state layer. §3's "vendoring DS components" framing is superseded for cmt.4–cmt.5. Arms A/B/C
  below are retained for the record.**
  - *Arm A — Vendor/copy* the needed `board/` + golden components + tokens + i18n into the island (self-
    contained; matches the island's `INV-VENDORED-FAITHFUL` ethos — it already vendors `@echo/phoenix`).
  - *Arm B — Depend on `@codemoji/design`* as a workspace package (single source of truth; couples the
    self-contained island to the DS build + a shared pnpm workspace).
  - *Arm C — Build the DS to a consumable dist* and import that.
  - **REC: Arm A** — the island owns its runtime by design; vendoring keeps the ESM bundle self-contained.
- **F2 — How is the LOCAL bundle served to Phoenix?**
  - *Arm A — `static_paths`* one-line add of `game` in `codemojex_web.ex:8` (Phoenix serves
    `priv/static/game` same-origin) + `GAME_ASSET_URL` at that path.
  - *Arm B — external static server* for `priv/static/game` + `GAME_ASSET_URL` (no codemojex edit).
  - *Arm C — the game's Vite dev server* (HMR) + `GAME_ASSET_URL` at it (fastest iteration).
  - **REC: Arm C for dev iteration** (HMR in the shell), **Arm A for a committed, stable bundle.** Either
    also needs `GAME_EDGE_HOST=<unreachable>` so the live edge pointer stops winning.
- **F3 — Close the golden data gap (`diamonds`/`clips`/`keys`/`boost`).**
  - *Arm A — extend `GameLive.game_props/3`* to carry the player balances + golden boost (the honest,
    server-authoritative source).
  - *Arm B — the island derives/omits* (forward-tense placeholders until the server carries them).
  - *Arm C — a second bridge/IPC channel* supplies them.
  - **REC: Arm A** — server is the source of truth for balances; placeholders risk shipping a lie.
- **F4 — Shell scope now.** Thin Mode-A wrapper (REC) vs. toolkit chrome (Mode C multiwebview, native
  menus) — defer chrome to cmt.7.

## 6. Boundary + the gate

**A wider boundary than a normal codemojex rung — call it out.** This track spans **three trees**:
`mercury/codemojex/apps/game-tauri` (the shell), `mercury/codemojex/apps/game` (the island), and — for
the wiring rungs — `echo/apps/codemojex` (`static_paths`, `check_origin`, `game_props`). It **reuses**
`node/codemoji-design` read-only (vendored under F1-A). The four BCS libs are never edited. Commits are
**pathspec-only, per-tree**, never `git add -A`; a rung that touches `echo/apps/codemojex` is a real
codemojex code change and runs that app's gate ladder.

**Gate ladder (per surface a rung touches):**
- **game island / codemoji-design:** `pnpm --filter @codemojex/game typecheck && … build` (the ESM bundle
  builds; `mount` export intact); a Vite dev smoke; the vitest suite.
- **game-tauri:** `cargo build` clean (`src-tauri`); a `cargo run` launch smoke (window opens at
  `PHX_APP_URL`).
- **codemojex (only when touched):** from `echo/apps/codemojex`, `TMPDIR=/tmp mix compile
  --warnings-as-errors` + `TMPDIR=/tmp mix test`, `valkey-cli -p 6390 ping`, `pg_isready`.
- **the loop:** launch the shell against `:4000`, confirm welcome → lobby (dev bypass) → game renders and
  the dev panel taps LiveView frames.

**No new brands.** The track adds no BCS entity; it consumes the existing `SES`/`ROM`/`GAM`/`PLR`/`GES`
ids across the bridge. (If cmt.7's privileged taps ever mint a diagnostic entity, assign then.)

## References (grounded)

- Shell: `mercury/codemojex/apps/game-tauri/{README.md,src-tauri/src/lib.rs,dev-panel/inject.js,src-tauri/tauri.conf.json}`
- Island: `mercury/codemojex/apps/game/{src/index.tsx,src/GameEdge.tsx,src/types.ts,vite.config.ts,package.json}`
- Backend tiers: `echo/apps/codemojex/lib/codemojex_web/{router.ex,controllers/page_controller.ex,live/lobby_live.ex,live/game_live.ex}` · `assets/js/app.js`
- Bundle + auth: `echo/apps/codemojex/lib/codemojex/{edge.ex,game_bundle.ex}` · `lib/codemojex_web/mini_app_auth.ex` · `config/{dev.exs,runtime.exs}` · `lib/codemojex_web.ex`
- Real screen: `node/codemoji-design/stories/golden-game/{GoldenScreen,GoldenHero,GoldenLeaderboard,GoldenAnswerReveal}.tsx` · `stories/board/**` · `stories/i18n/i18n.ts` · `tokens/tokens.mjs`
- Canon: [`../../codemojex.design.md`] · [`../../codemojex.roadmap.md`] · [`../../program/codemojex.program.md`]
