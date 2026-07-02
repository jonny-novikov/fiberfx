# GameRoom — the STEELMAN design (a native-iOS-grade game screen)

> **Track:** codemojex Tauri (`cmt.N`) · **AAW scope:** `cm-tauri` · **Lens:** STEELMAN (the strongest
> case for a shipped-iOS-app result) · **Sibling:** [`./gameroom.steward.design.md`] (the pragmatic,
> reuse-first arm) · **Depends:** cmt.3 (the Effector Phoenix-channel state foundation, in build).
> Ground: [`./cmt.3.md`] · [`./tauri.design.md`] · [`./tauri.specs.md`] · the migration source
> `node/codemoji-design/stories/board/` (REFERENCE ONLY — re-implemented natively, never imported).
>
> **DESIGN/PROPOSAL ONLY.** This document is one of two competing GameRoom proposals; the Operator rules
> the ladder + the forks. It authors no `cmt.N` triad and edits no production code. It is the STEELMAN —
> where a cheaper path exists, the Steward doc argues it; this doc argues the complete, high-fidelity one.

---

## 1 · The vision — GameRoom feels like an app you downloaded

**GameRoom** is the base game screen of Codemoji Tauri — the Free / classic guess-the-code board, established
under its new name (**"Board" is retired**; the golden room becomes a gold *treatment* on GameRoom, a later
rung). The steelman claim: GameRoom should not read as "a web page in a desktop window." It should read as a
native iOS app — a 430×932 iPhone-Pro-Max-shaped window, safe-area-correct, momentum-scrolling, sprite-sharp,
driven by live server state over a Phoenix channel, and **held to that bar by a gate that introspects the real
running screen**, not merely a folder of static stories.

Three pillars carry that vision, each argued at full strength below:

1. **A pixel-faithful native migration** of the complete board component set (~20 components) into
   `@codemojex/game`, bound to the cmt.3 channel state — completeness and fidelity, not a thin subset.
2. **A live-screen visual-consistency rig** — an island-local Storybook *plus* a Playwright gate that
   screenshots the actual Tauri screen at the pinned iPhone viewport and pixel-diffs it against a committed
   reference. A real drift gate, not decoration.
3. **A first-class iPhone-Pro-Max window** — a dedicated game-tauri window (not the dev toolkit) sized and
   chromed like a shipped iOS app: safe-area insets, overscroll/momentum, the iOS status-bar chrome, no
   desktop affordances.

---

## 2 · The substrate GameRoom stands on (grounded, no invention)

| Surface | Where | What GameRoom takes from it |
|---|---|---|
| The mount contract | `mercury/codemojex/apps/game/src/index.tsx` | `mount(el, props, bridge) → {update, unmount}` — the one outward contract; GameRoom renders under it |
| The engine↔game types | `…/game/src/types.ts` | `GameProps = { view, leaderboard, history, me }`; `GameView.emojiset = { sprite_url, cell_size, cols, rows, codes }`; `Bridge = { pushEvent, onServerEvent }` |
| The channel state (cmt.3) | `…/game/src/channel/{model.ts,PhoenixGame.tsx}` | `createGameModel` → `$props` (Effector store) + `serverEvent` + `submitGuess/lock/unlock`; `PhoenixGame` opens the socket, joins `game:<id>`, builds the `Bridge`, and renders the screen from `$props` |
| The current screen | `…/game/src/GameEdge.tsx` (+ plain `src/components/*`) | GameRoom **succeeds** `GameEdge` — the plain placeholder components (`EmojiSlots`/`EmojiKeyboard`/`GuessActions`/`InfoDashboard`/`Leaderboard`/`sprite.ts`, ~700 B each) are replaced by the faithful port; `PhoenixGame` renders `GameRoom` instead of `GameEdge` |
| The build | `…/game/vite.config.ts` | self-contained ESM `game-[hash].js` → `echo/apps/codemojex/priv/static/game`; React bundled; `@mercury/effector` from source; **INV: no `@mercury/ui` in the graph** |
| The migration source | `node/codemoji-design/stories/board/**` | the ~20 board components — **read as a reference, re-implemented natively** in the island (Operator's ruling); zero edits to `node/` |
| The desktop host | `mercury/codemojex/apps/game-tauri/src-tauri/src/lib.rs` | today a **dev toolkit** window (`inner_size(1280.0, 840.0)`, wraps a remote Phoenix URL, injects a channel-tap panel) — the iPhone game window is added here |

**The board component inventory (the migration source, `stories/board/`):**
`BoardScreen.tsx` (the composition) · `InfoDashboard` (= `BalancePill` + `RoundInfo` + `StatCards`) ·
`PreviousAttempt` · `EmojiSlots` · `GuessActions` · `EmojiKeyboard` · `BoardTabs` · `GuessHistory` ·
`Leaderboard` · `GameRules` · `ShareKeys` · `KeysBalance` · `StatusBar` (golden-era header) ·
`lib/{BoardCard, EmojiTile, SpriteEmoji}` · `cn` · `Button` (variant `enter`/`outline`/`default`) · the
`NavPhonePanel` phone chrome (shared from `stories/lobby/`).

**The vertical order of the screen** (from `BoardScreen.tsx`): phone chrome → Info dashboard (balance pill ·
timer+prize · stat cards) → the guess card (heading · previous attempt · slots · actions) → the emoji keyboard
→ the tabs (History ⇄ Leaderboard) → rules → share → the free-key footer. The content column is
`mx-auto max-w-sm px-2` on a full-bleed screen-fill gradient (`--color-bg-app-from → --color-bg-app-to`).

---

## 3 · Pillar 1 — the pixel-faithful native migration (completeness IS the app feel)

### 3.1 · Why full fidelity, not a thin subset

A native app does not ship "the core loop, polish later." The steelman position: the board set is already
designed, storyboarded, and Figma-reconciled down to exact tile states, fixed token palettes, and per-peg
annotation colours. Porting a *subset* discards that finished work and produces a screen that reads as a
prototype. The whole set is ~20 small presentational components with no server logic of their own — the cost
is bounded and front-loaded, and each component is independently story-able (Pillar 2), so fidelity is
*verifiable*, not aspirational. Completeness is what separates "a game in a window" from "an app."

### 3.2 · The native Tailwind v4 token theme (reimplemented, not borrowed)

The board components are **plain Tailwind v4 utilities** over a named token vocabulary — not `@mercury/ui`
`.mx-*` recipes. Per the Operator's ruling (and cmt.3 fork 3), the island owns its **own** Tailwind v4
`@theme`, reimplementing the board tokens natively. This keeps the self-containment INV intact (no
`@mercury/ui` in the bundle) and is the correct home for these tokens — they are utility-class design tokens,
not Mercury component tokens, so Mercury's token-discipline law does not reach them. **This divergence is
surfaced as a conscious call (fork #4), not assumed.**

The token set to reimplement natively (grounded in the board components):

| Token | Value / role | Seen in |
|---|---|---|
| `--color-bg-app-from` / `--color-bg-app-to` | screen-fill gradient `#E8F3F7 → #AFC7D6` | `BoardScreen`, `preview.tsx` |
| `--color-main-blue` | `#54C0EC` — leaderboard/history bar + active tab (**FIXED, Operator-pinned**, not the themeable accent) | `Leaderboard`, `GuessHistory`, `BoardTabs` |
| `--color-primary` (+ `/10`) | slot fill, avatar chips | `EmojiSlots`, `Leaderboard` |
| `bg-active-slot` | `#1F1F1F` — the dark "fill me next" slot with the pulsing `?` | `EmojiSlots` |
| the `enter` button | `#0050FF` — the blue submit ("Проверить") | `GuessActions`, `Button` |
| the peg palette (FIXED) | green `#4CAF50`/`#E8F5E9` · yellow `#FFC107`/`#FFF8E1` · red `#F44336`/`#FFEBEE` | `GuessHistory` |
| `bg-card` · `bg-slot` · `bg-control` (`#A8ACB0`) · `bg-success` | surfaces + chrome | across the set |
| `text-muted` · `text-dark-muted` · `text-card-foreground(-secondary)` | type roles | across the set |
| sizes | `size-13` (52 px slot) · `rounded-2xl` · `rounded-[0.625rem]` · `text-h5` · `text-2xs` | `EmojiSlots`, footer, metrics |

Tailwind v4 wires into the island's Vite build via `@tailwindcss/vite` — the exact plugin the design
Storybook already uses (`node/codemoji-design/.storybook/main.ts`). The `@theme` block lives in the island
(`src/gameroom/theme.css` or the island's entry CSS), bundled into `game-[hash].js`.

### 3.3 · The sprite pipeline is the crux — drive it from live state

Every gameplay emoji (slots, keyboard, previous attempt, history) is drawn from a **sprite sheet** by
`background-position`, never a Unicode glyph — so the art is identical across platforms
(`SpriteEmoji`, `lib/SpriteEmoji.tsx`). The design component bakes a `DEFAULT_SPRITE`
(`/assets/emoji/01-emoji-set.png`, 72 px cells, 10×15). The steelman requirement: the native `SpriteEmoji`
draws from the **live** `view.emojiset` (`sprite_url`/`cell_size`/`cols`/`rows`), mapping the server config
onto the same `XXYY` → `(col,row)` → offset math. The design's `SpriteConfig` and the engine's `EmojiSet`
are field-for-field the same shape, so the map is mechanical:

```
SpriteConfig { spriteUrl, cellSize, gridCols, gridRows }  ⟵  view.emojiset { sprite_url, cell_size, cols, rows }
```

This is the single most load-bearing fidelity decision: get the offset math and the sheet source right and
every emoji surface is correct for **any** room's set; get it wrong and the whole board is subtly off. The
island already carries a `src/components/sprite.ts` seed to grow from.

### 3.4 · The component ports + their interactions

Each design component is re-implemented natively; the interactive ones bind to `$props` + the bridge:

- **`EmojiSlots`** — the 6-slot guess row (the heart). Tile states: filled (`bg-primary/10`, sprite@40),
  filled+locked (`+ border-border` + a lock badge), **active** (the first empty unlocked slot — dark
  `bg-active-slot` with a pulsing white `?`), empty. Picks are the only client-owned state; clearing a slot
  filters the pick list.
- **`EmojiKeyboard`** — the 7-column **scrolling** grid (the board shows 5 rows + a 0.4-row peek via
  `aspect-ratio`, momentum + `touch-action: pan-y` + `overscroll-contain`). Key states: default,
  **selected** (green ring), **used** (faded, appeared in a prior guess). `onSelect(code)` appends to the
  next open slot; disabled when `view.status !== "open"`.
- **`GuessActions`** — Clear (`outline`) + Check (`enter`, blue, fills the row, shows `🔑 <fee>`). Disabled
  until all six slots are filled (`ready = picks.length === 6 && status === "open"`); Check →
  `bridge.pushEvent("submit_guess", { emojis: picks })` → `model.submitGuess`.
- **`InfoDashboard`** = `BalancePill` (keys) + `RoundInfo` (timer + prize + diamonds) + `StatCards`
  (players/attempts/best). Fed by `view` (prize/totals/ends_ms) + client placeholders for the data gap (§3.5).
- **`PreviousAttempt`** — the last completed guess row; tapping refills the slots.
- **`BoardTabs`** — History ⇄ Leaderboard (the app opens on History), an underline-colour toggle (active =
  Main Blue), one panel shown at a time.
- **`GuessHistory`** — the player's attempts (`history`), each with the per-peg **annotation** marks
  (idle/green/yellow/red — a private deduction aid), points-over-a-Main-Blue-bar.
- **`Leaderboard`** — avatar · @handle · metric-over-score · a thin Main-Blue progress bar; the current
  player's row lifted (`bg-primary/10`); the leader-change notify toggle.
- **`GameRules` · `ShareKeys` · the free-key footer** — the long tail; static + i18n.
- **`NavPhonePanel`** — the iOS status-bar + app-header chrome (Pillar 3).
- **lib: `BoardCard` · `EmojiTile` · `SpriteEmoji` · `cn` · `Button`** — the shared atoms.

The composition — **`GameRoom.tsx`** — mirrors `BoardScreen`'s vertical order over `$props`, and is what
`PhoenixGame` renders (superseding `GameEdge`). One-off `serverEvent`s (`guess_rejected` / `revealed` /
`golden_win`) surface as the toast, exactly as `GameEdge` does today.

### 3.5 · The data gap (surfaced, ruled downstream)

`diamonds` / `keys` / `clips` / `boost` are **not** in `GameProps` (cmt.3 F3). The steelman GameRoom renders
them as **client placeholders** now (per the cmt.3 ruling), and a real server-props rung follows via
`/codemojex-ship` — a **data-model fork** touching the echo/ Ecto schema + `@codemojex/db` + `RoomChannel`'s
`game_props`, out of this presentational ladder (fork #5). GameRoom's contract is written so the placeholder
→ real-prop swap is a one-line source change, not a re-layout.

### 3.6 · The interactions omitted by the design (documented, not silently dropped)

The design components explicitly omit the app's `@dnd-kit` **drag-reorder** of picked slots and the
**lock/unlock** pin toggle (they document the slot *states*, not the gestures). The cmt.3 model already
exports `lock(pos,code)` / `unlock(pos)`, so the wire is ready. The steelman ladder restores these gestures as
a named rung item (they are part of "shipped iOS app" tactility), but flags them as the one place where the
design reference is a state-spec, not an interaction-spec — so the gesture design is authored fresh, grounded
in the app's behaviour, not copied from a component that omits it.

---

## 4 · Pillar 2 — the live-screen visual-consistency rig (a real drift gate)

### 4.1 · Two layers: the Storybook reference + the live-screen diff

**Layer A — an island-local Storybook.** The design system's Storybook lives in `node/` (out of the island's
bounds), so GameRoom gets its **own** Storybook inside `@codemojex/game`, mirroring the proven recipe:
`@storybook/react-vite` + the `@tailwindcss/vite` plugin (v4 utilities) + i18n/theme decorators + static
sprite dirs — exactly `node/codemoji-design/.storybook/{main.ts,preview.tsx}`, re-homed. Every GameRoom
component gets a story; the full `GameRoom` screen gets a story fed by fixture `GameProps`. This is the
canonical visual reference and the fast authoring loop.

**Layer B — the live-screen consistency gate (the steelman bet).** Static stories prove a component renders
in isolation; they do **not** prove the *shipped screen* still matches — runtime drift (webfont loading, the
sprite offset math against a real sheet, safe-area layout in the actual window, the momentum viewport) is
exactly what escapes a static story. So the gate **introspects the running screen**: a headless Playwright
runner (modelled on `mcp/e2e/{validator.js,shot.js,figures.suite.js}`) opens GameRoom at the **pinned iPhone
viewport**, waits for `document.fonts.ready` + networkidle (the `validator.js` pattern), screenshots the live
board, and **pixel-diffs** it against a committed Storybook-rendered baseline. A tolerance (e.g. ≤ N% changed
pixels) makes it a hard gate: a regression that moves a tile, drops a token, or mis-scales a sprite fails the
run with a diff artifact — not a silent visual bug shipped to the edge bundle.

### 4.2 · Why this is worth a new gate

The `mcp/e2e` precedent already proves the shape works headless anywhere and prints PASS/FAIL text with a
captured artifact. The board is a *pixel* product (sprite art, fixed palettes, exact tile geometry), so a
geometry-only assertion (getBBox, as the SVG validator does) is insufficient — the steelman gate captures
pixels. The cost is one dev dependency (a diff engine — `pixelmatch` or `odiff`) + committed baseline PNGs +
a runner script; the return is that "GameRoom matches the design" becomes a **checked closure**, re-runnable
each rung, rather than a maintainer's eyeball. That is the difference between a design system and a design
*aspiration*. (Heaviness + the diff-engine dependency is surfaced as fork #3.)

### 4.3 · What the gate reads

- the **live Tauri screen** (or the island's Vite dev server at the iPhone viewport — the cmt.2 dev loop
  already serves the module at `http://127.0.0.1:5173/src/index.tsx`);
- against the **Storybook** full-screen story render (same fixture `GameProps`, same viewport);
- producing `/tmp/shots/gameroom__<state>.png` + a diff mask, and a PASS/FAIL line per screen state
  (empty · 3-of-6 · complete · post-submit · leaderboard tab · history tab).

---

## 5 · Pillar 3 — the iPhone-Pro-Max window (first-class, not a CSS afterthought)

### 5.1 · The target dimensions (pinned + cited)

- **Content column:** `max-w-sm` = **384 px** (`BoardScreen`, `GoldenScreen`'s `Frame`), centred `mx-auto`
  with `px-2`, on a full-bleed gradient. The Figma master frame is **375-wide** (`BoardScreen` comment) — the
  classic iPhone logical width. The column is design-fixed; the window is wider and full-bleeds the gradient
  behind the centred column.
- **The window:** iPhone Pro Max logical points. **iPhone 15/14 Pro Max = 430 × 932**; iPhone 16 Pro Max =
  440 × 956. The steelman target is **430 × 932** (the most-cited Pro Max CSS viewport); the exact device is
  an Operator pick. A 430-wide window full-bleeds the gradient with ~23 px each side of the 384 px column —
  precisely the design intent.

### 5.2 · The game-tauri window config

`game-tauri/src-tauri/src/lib.rs` today builds **one** window — the **dev toolkit** (`inner_size(1280.0,
840.0)`, title "Codemoji — Dev Toolkit", wraps `PHX_APP_URL`, injects the channel-tap panel). The iPhone game
window is a **distinct** surface:

```
WebviewWindowBuilder::new(app, "game", WebviewUrl::External(<phoenix/game url>))
  .title("Codemoji")
  .inner_size(430.0, 932.0)      // iPhone Pro Max logical points
  .resizable(false)              // an app window, not a resizable desktop pane
  .min_inner_size(430.0, 932.0)  // pin the aspect
  // no dev-panel injection on the game window
```

**Fork #2 (surfaced):** does the iPhone window **replace** the dev toolkit, sit **beside** it (Tauri v2
multiwindow — the README's mode C), or become a **separate binary / a mode flag**? The dev toolkit is
valuable (cmt.7 grows it into a product), so the steelman leaning is *both windows, mode-selected* — but the
Operator rules the topology.

### 5.3 · The iOS-app CSS layer

- **Safe-area insets** — `padding: env(safe-area-inset-top/bottom/left/right)`. On desktop WKWebView there is
  no physical notch, so the insets are zero and the **iOS chrome is simulated** by `NavPhonePanel`'s
  status-bar image (`iphone-topbar.png` — system time · Dynamic Island · signal/wifi/battery) at the top.
  Honest nuance: on a real iOS Tauri (mobile) target the env() insets apply for real; on desktop the chrome
  is the image. The layout uses env() so it is correct on both.
- **Momentum + overscroll** — `-webkit-overflow-scrolling: touch` + `overscroll-behavior: contain` on the
  scroll containers (the keyboard viewport already does exactly this; the screen root adopts the same), so a
  drag scrolls with iOS-like momentum and never chains to a "page."
- **The screen-fill gradient** is full-bleed to the window edges; the content column is `max-w-sm mx-auto` —
  the design's own layout, now inside a phone-shaped window instead of a browser tab.
- **No desktop chrome** — non-resizable, fixed aspect, the app title only; the window *is* the phone.

### 5.4 · Why a dedicated window beats a CSS max-width in a desktop pane

The steelman argument: a `max-w-sm` column floating in an 1280×840 desktop window is a web page; a 430×932
non-resizable window with safe-area chrome and momentum scroll is an app. The window *shape* is the single
strongest signal of "native iOS," and it is a bounded, well-understood Tauri window-config change grounded in
the existing `lib.rs`. Sizing the window is where the feel is won.

---

## 6 · The rung decomposition (the steelman `cmt.N` ladder)

Anchored after **cmt.3** (the state foundation). This ladder **re-scopes** the existing cmt.4/5 stubs
(golden-screen → GameRoom) and **re-sequences** the golden into a later treatment; the existing tail (Tier
fidelity / dev-panel / distributable) shifts after — the exact renumber is the Director/Operator reconcile
(**fork #1**), especially since a sibling Steward ladder competes.

| Rung | Title | Deliverables | App(s) | Risk | Depends |
|---|---|---|---|---|---|
| **cmt.4** | GameRoom atoms + Tailwind v4 foundation | wire `@tailwindcss/vite` into the island build; the native `@theme` token set (§3.2); port `SpriteEmoji` (live-`emojiset` driven) · `cn` · `Button` · `BoardCard` · `EmojiTile`; a smoke story rendering one sprite-accurate atom | game | MED | cmt.3 |
| **cmt.5** | GameRoom core loop | `InfoDashboard` · `PreviousAttempt` · `EmojiSlots` · `GuessActions` · `EmojiKeyboard`, composed as **`GameRoom.tsx`** over `$props`; `PhoenixGame` renders GameRoom (supersedes `GameEdge`); **pick → fill → submit round-trips live**; client placeholders for the data gap | game | MED–HIGH | cmt.4 |
| **cmt.6** | GameRoom standings | `BoardTabs` (History ⇄ Leaderboard) · `GuessHistory` (per-peg annotation) · `Leaderboard` (Main-Blue bars) over `history`/`leaderboard`/`me` | game | MED | cmt.5 |
| **cmt.7** | GameRoom long tail + i18n | `GameRules` · `ShareKeys` · the free-key footer; `react-i18next` wired (the Russian copy); the complete screen | game | LOW–MED | cmt.6 |
| **cmt.8** | The iPhone-Pro-Max shell | the game-tauri iPhone window (430×932, non-resizable, §5.2); safe-area/momentum/overscroll CSS; `NavPhonePanel` chrome; window-topology fork resolved | game-tauri (+ game CSS) | MED | cmt.5 (∥ 6/7) |
| **cmt.9** | GameRoom Storybook | island-local `@storybook/react-vite` + `@tailwindcss/vite`; a story per component + a full-screen story on fixture `GameProps` | game | LOW–MED | cmt.5 |
| **cmt.10** | The visual-consistency rig | the Playwright live-screen ↔ Storybook **pixel-diff** gate; committed baselines; per-state screens (§4.3); the gate in the app's test ladder | game (+ e2e tooling) | MED | cmt.8, cmt.9 |
| **cmt.11** | The golden treatment | `GoldenHero` · `GoldenAnswerReveal` · `GoldenLeaderboard` + the gold tokens, as a *treatment* on GameRoom (the golden IS GameRoom + gold); the boosted-game surfaces | game | MED | cmt.6 |
| *(downstream)* | Server-props rung | `diamonds`/`keys`/`clips`/`boost` into `game_props` + `@codemojex/db` + `GameProps` — **a data-model fork via `/codemojex-ship`**, not this presentational ladder | codemojex + game | MED–HIGH | cmt.5 |

**Build order:** cmt.4 → cmt.5 → cmt.6 → cmt.7, with cmt.8 ∥ (after cmt.5) and cmt.9 ∥ (after cmt.5), then
cmt.10 (needs 8 + 9), and cmt.11 after cmt.6. The **playable, live, iPhone-shaped** milestone is cmt.5 +
cmt.8; the **guarded** milestone (drift gate green) is cmt.10.

**Each rung's determinism posture:** GameRoom introduces no id-mint / process / lease / schema surface (it is
presentational over the channel), so the ≥100 determinism loop is not required (per [`./tauri.specs.md`] §
determinism posture); the posture is typecheck + build + the app vitest + the live proof + (from cmt.10) the
visual-consistency gate. The self-containment INV (no `@mercury/ui` in the bundle; one ESM exporting `mount`)
is re-checked every rung.

---

## 7 · The sharpest design bets (steelman)

1. **The consistency gate introspects the *live* screen, not just static stories.** Pixel-diff the actual
   running Tauri screen (fonts-ready, real sprite sheet, real safe-area layout) against a committed reference.
   Static stories catch "does it render"; only the live-screen diff catches "does the *shipped* board still
   match." This is the difference between a design system and a design aspiration — and the `mcp/e2e`
   precedent proves the headless-Playwright shape already works here.

2. **The iPhone window is a product surface, not a `max-width`.** A dedicated 430×932 non-resizable Tauri
   window with safe-area chrome and momentum scroll — distinct from the dev toolkit — is the single strongest
   "native iOS" signal, and it is a bounded window-config change grounded in the existing `lib.rs`. Size the
   window and the feel is won; leave it a column in a desktop pane and it stays a web page.

3. **Fidelity is carried by the sprite pipeline driven from live state.** Port the *complete* set, and make
   `SpriteEmoji` draw from `view.emojiset` (not the baked default) — the design `SpriteConfig` and the engine
   `EmojiSet` are the same shape, so the map is mechanical and, once right, every emoji surface is correct for
   any room's set. Completeness + the live sprite map is what reads as "an app," not "a demo."

---

## 8 · Forks surfaced for the Operator (never decided here)

1. **The ladder renumber / re-scope.** GameRoom-first re-scopes the existing cmt.4/5 (golden → GameRoom) and
   re-sequences the golden into cmt.11 + shifts the existing cmt.6/7/8 tail (Tier fidelity · dev-panel ·
   distributable). Steelman arm: the full re-decomposition above. Steward arm (sibling doc): a leaner reuse of
   the existing numbers. The Operator rules the final ladder.
2. **The iPhone window vs the dev toolkit.** Replace, sit beside (Tauri v2 multiwindow / mode C), or a
   separate binary / mode flag? A topology + `game-tauri` fork (§5.2). Steelman leaning: both windows,
   mode-selected.
3. **The visual-rig heaviness + its dependency.** Live-screen pixel-diff (steelman — heavier, a new diff-engine
   dep + committed baselines + a runner) vs Storybook-only static stories (steward — lighter). A dependency +
   gate-cost fork.
4. **Tailwind v4 + a native token `@theme` in the island.** Reimplemented natively (Operator's ruling; not
   `@mercury/ui`), which the self-containment INV requires — but it is a conscious divergence from the Mercury
   token-discipline law's *spirit* (the island owns tokens Mercury does not). Already surfaced at cmt.3 fork 3;
   re-affirmed here, not re-litigated.
5. **The data gap (`diamonds`/`keys`/`clips`/`boost`).** Client placeholders now (cmt.3 F3 ruled); a real
   server-props rung is a **data-model fork** (echo/ Ecto schema + `@codemojex/db` + `RoomChannel.game_props`)
   via `/codemojex-ship`, outside this presentational ladder.

---

## 9 · Boundary + posture

- **`node/codemoji-design/` is a REFERENCE-ONLY source** — read to capture structure, re-implemented natively
  in `@codemojex/game`; **zero edits** to `node/` (Operator's ruling; the island stays self-contained).
- **The island self-containment INV governs every rung** — GameRoom is plain-Tailwind + island-local, never
  imports `@mercury/ui`; the bundle stays one ESM exporting `mount` (checked in the gate).
- **echo/ is read-only** — the only echo/ touch in this arc is the (already-ruled, cmt.3) `RoomChannel`
  transport; the server-props rung forks to `/codemojex-ship`.
- **This doc edits only itself.** No triad, no code, no git. The Operator rules the ladder + the five forks;
  the winning arm (or a synthesis with the Steward) becomes the cmt.4+ triads.
