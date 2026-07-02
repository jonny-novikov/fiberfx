# GameRoom — the pragmatic migration (Steward design)

> **Status:** DESIGN v0 (Venus **Steward** lens, 2026-07-01). **DESIGN/SPEC ONLY** — no production code
> ships from this doc. Grounded **NO-INVENT** against the as-built `mercury/codemojex/apps/{game,game-tauri}`,
> the `node/codemoji-design` board reference (visual reference only), and `docs/codemojex/specs/tauri/cmt.3.md`.
> Every surface named is a real file, or is marked **forward-tense**.
>
> **Lens.** This is the **reuse-first, low-risk, defer-the-cost** proposal — the sibling
> [`./gameroom.steelman.design.md`] argues the maximal (native-iOS-grade) case; the two are authored
> INDEPENDENTLY and cross-reviewed after both land. Convergence is confidence; divergence is a fork for the
> Operator. Canon: [`./tauri.design.md`] · [`./tauri.specs.md`] · [`../../program/codemojex.program.md`].

## 0. What GameRoom is (the reframe)

**GameRoom is the base game screen** — the *Free / classic* Codemoji game, rendered natively inside the
island `@codemojex/game`, fed by the cmt.3 Effector/Phoenix-channel state. It is the migration target of the
`node/codemoji-design/stories/board/` component set. Two naming moves the Operator has ruled:

- **"Board" is RETIRED.** The migrated screen is **GameRoom**; the internal component `GameEdge`
  (`src/GameEdge.tsx`) is promoted to `GameRoom` (the outward `mount` contract is unchanged — see §3.1).
- **"Golden" is a *treatment*, not a screen.** The golden room is a gold visual treatment applied to a
  *whole* GameRoom (gold tokens · `GoldenHero` · reveal) as a **later** rung — not a parallel screen.

**This reframes the current `tauri.specs.md` ladder.** The carved stubs frame cmt.4/cmt.5 as "port
`GoldenInProgressScreen`/`GoldenFinishedScreen`". Under the Operator's GameRoom-first ruling, **the base
GameRoom comes first and golden moves to the tail** — the ladder below (§4) supersedes those two stubs. That
reordering is a decomposition proposal, surfaced as a fork (§5-F1), not a decision.

## 1. Reconcile — the as-built ground truth (the reuse thesis)

The Steward case rests on one fact: **most of the "migration" already exists.** The island is not a blank
canvas — cmt.3 wired a working, state-fed core loop; it is only *unstyled*.

**The island already renders the core loop (`mercury/codemojex/apps/game/src/`).**
`GameEdge.tsx` composes **five native components** from `@/components/` — `InfoDashboard`, `EmojiSlots`,
`GuessActions`, `EmojiKeyboard`, `Leaderboard` — plus a plain history `<ul>`, driven by live props: picks are
the only client state; `submit_guess` goes out over `bridge.pushEvent`; `guess_rejected`/`revealed`/
`golden_win` arrive over `bridge.onServerEvent` as toasts (`GameEdge.tsx:22-40`). These components are
**plain** — BEM class names (`.slots`, `.info`, `.game__toast`), **no Tailwind wired** (cmt.3 deferred all
styling — `cmt.3.md` Scope Out).

**The sprite renderer is already live-fed and matches the board 1:1.** `src/components/sprite.ts`
`cellStyle(set, code, display)` draws an `"XXYY"` cell from the **live** `view.emojiset`
(`sprite_url`/`cell_size`/`cols`/`rows`) — the same model as the board's `lib/SpriteEmoji.tsx`
(`SpriteEmoji.tsx:46-71`), except the island's is *server-fed* (richer) while the board's bakes a
`DEFAULT_SPRITE`. **No sprite port is needed** — every migrated emoji reuses `cellStyle`.

**The state layer is in place (cmt.3).** `src/channel/model.ts` `createGameModel()` maps the `game:<gam>`
channel to Effector `$props` + `serverEvent` + outbound `submitGuess`/`lock`/`unlock`; `PhoenixGame.tsx`
plugs a live channel into it and renders the screen from `$props`. GameRoom sits ON this — it changes *what
is rendered*, never the transport.

**The board reference (`node/codemoji-design/stories/board/`, read-only).** `BoardScreen.tsx` composes ~13
components in the Figma vertical order: phone chrome (`NavPhonePanel`) → `InfoDashboard` (balance pill ·
timer+prize · stat cards) → a guess `BoardCard` (heading · `PreviousAttempt` · `EmojiSlots` · `GuessActions`)
→ `EmojiKeyboard` → `BoardTabs` {`GuessHistory` ⇄ `Leaderboard`} → `GameRules` → `ShareKeys` → free-key
footer, on a `max-w-sm` (384px) frame, painted with the `--color-bg-app-from → --color-bg-app-to` gradient
(`BoardScreen.tsx:84-138`). It leans on Tailwind utilities, custom tokens (`bg-card`, `border-main-blue`,
`bg-slot`, `text-dark-muted`, …), the `cn` util, and `react-i18next`.

### The migration map — reuse / restyle / add / defer

| Board component | GameRoom disposition | Cost |
|---|---|---|
| `lib/SpriteEmoji`, `lib/EmojiTile` | **REUSE** the island's `sprite.ts` `cellStyle` — no port | 0 |
| `EmojiSlots`, `EmojiKeyboard`, `GuessActions`, `Leaderboard`, `InfoDashboard` | **RESTYLE** the 5 existing native components to the board look (already state-wired) | low |
| `GameEdge` shell | **PROMOTE → `GameRoom`** + apply the phone-frame layout (`max-w-sm`, gradient, `BoardCard`) | low |
| `PreviousAttempt`, `BoardTabs`, `GuessHistory` | **ADD** (additive; live `history`/`leaderboard` props) | med |
| `GameRules`, `ShareKeys`, `StatusBar`, `NavPhonePanel`, free-key footer | **ADD** (static long-tail) | low |
| Per-peg annotation `marks` (green/yellow/red) | **DEFER** — no live data (`HistoryRow` carries none) | — |
| `StatusBar` balances (`diamonds`/`clips`/`keys`), `GoldenHero` `boost` | **DEFER** to client placeholders (the F3 gap) until a server-props rung | — |
| Golden treatment (`GoldenHero`, gold tokens, reveal) | **DEFER** to the tail (a treatment on a whole GameRoom) | — |

**Verdict: BUILD-GRADE reuse basis.** The core loop, the sprite renderer, and the state layer are on disk;
GameRoom is a **restyle + rename + additive grow**, not a from-scratch port of ~20 components.

## 2. The Steward thesis — three calls

1. **Reuse the skeleton; don't re-port.** `GameEdge` + `@/components/*` + `sprite.ts` already render the loop
   on live state. The migration *styles and grows* them — it does not rebuild them. This collapses "port ~20
   board components" into "restyle 5 + add ~6 additive + reuse 1 sprite."
2. **Defer everything with no live data.** The board's per-peg `marks` and the `StatusBar` balances have **no
   source in `GameProps`** (`types.ts:38-49`) — the same class as the F3 gap (`tauri.design.md` §3). Render
   without them (placeholders), and let a server-props rung feed them; **do not invent** the values.
3. **Start the gate small.** A component Storybook + a screenshot check (the `mcp/e2e` Playwright pattern),
   not a live-Tauri-screen diff rig. Optimize for a gate a maintainer keeps green.

Plus a fourth, lighter call: **keep inline RU, defer `react-i18next`.** The board threads `t(...)` keys
everywhere; the island already ships inline RU (`InfoDashboard.tsx:11` "Банк"; `GameEdge` reject text). The
game is RU-first — translate each `t(key)` to its RU string at migration and keep the i18n runtime off the
critical path (adding it is a runtime-dependency fork — §5-F2).

## 3. The three pillars, designed

### 3.1 Pillar 1 — the GameRoom migration (thin, reuse-first)

**Sequence the migration behind the core loop.** The provable core is *slots → keyboard → submit →
leaderboard* — all five components already exist and are state-wired. So:

1. **A styling substrate first (Tailwind v4 + a native token theme).** Wire `@tailwindcss/vite` into the
   island's `vite.config.ts`, and author a **native** `@theme` reproducing the board's token set —
   `--color-bg-app-from`/`-to` (`#E8F3F7`/`#AFC7D6`), `--color-card`/`-foreground`, `--color-main-blue`
   (`#54C0EC`), `--color-slot`/`--color-active-slot`, `--color-dark-muted`, `--color-border` — grounded in
   the board reference, **not** imported from `@codemoji/design` (the Operator's re-implement-natively
   ruling, `tauri.design.md` §5-F1). Add a `cn`/`cx` merge util (reuse `@mercury/core`'s `cx` if it carries
   `tailwind-merge` semantics; else two tiny deps — §5-F2). The self-containment INV (`cmt.3-INV4`: one ESM
   `game-[hash].js`, no `@mercury/ui` in the graph) is re-checked after Tailwind lands.
2. **Promote `GameEdge` → `GameRoom` + the phone-frame layout.** Rename the internal component/file; keep
   `index.tsx`'s `mount(el, props, bridge)` export **byte-identical** (the only outward contract —
   `index.tsx:9`), and update `PhoenixGame.tsx`'s import. Apply the `BoardScreen` shell: the `max-w-sm`
   column, the app gradient, `BoardCard` wrappers. Restyle the 5 native components to the board look.
3. **Grow the fuller guess surface additively.** Add `PreviousAttempt` (tap-to-refill), `BoardTabs`
   (History ⇄ Leaderboard), `GuessHistory` (without `marks` — deferred). These consume the live `history` +
   `leaderboard` props already in `$props`.
4. **Add the static long-tail last.** `GameRules`, `ShareKeys`, the `StatusBar` chrome, the free-key footer
   — presentational, low-interaction, balances as placeholders.

The finished/settled state + the existing event toasts (`guess_rejected`/`revealed`/`golden_win`, already
wired in `GameEdge.tsx:22-29`) ride with the core-loop rung — no new event plumbing, just styled states.

### 3.2 Pillar 2 — visual testing that starts small and grows

**Reuse the proven patterns; own the gate in-boundary.** Two precedents already exist in the monorepo:
`@mercury/storybook` (`mercury/apps/storybook`, **Storybook 10.4.6 + `@storybook/react-vite`**, `storybook
build → storybook-static`) and the `mcp/e2e` headless-Playwright validator (`shot.js` · `figures.suite.js` ·
`validator.js`). The pragmatic gate **reuses those patterns inside the codemojex island** (both source trees
are out-of-boundary — reuse the *config shape*, don't edit them):

1. **Component stories first.** A Storybook (or a lightweight `stories/` set) co-located in
   `mercury/codemojex/apps/game`, modeled on `@mercury/storybook`'s config, with one story per GameRoom
   component (fixture `GameProps` — the same shape the board's `BOARD_LEADERS`/`BOARD_HISTORY` sample uses).
   This is the consistency surface a maintainer eyeballs and a reviewer diffs.
2. **A single lightweight screenshot check.** A `shot.js`-style Playwright pass over the built Storybook
   (`storybook-static`) capturing each story to PNG — a smoke/diff gate the maintainer keeps green. This is
   the whole visual gate for the base GameRoom.
3. **DEFER the live-Tauri-screen diff.** Diffing the running Tauri window against the reference (the
   Steelman's maximal rig) is real value but heavy (screen-capture is TCC-blocked for agents —
   `cmt.1` status note) and brittle. Grow into it only if the static gate proves insufficient.

### 3.3 Pillar 3 — iPhone Pro Max window (focused)

**A one-file window-config + a CSS layout rung — not an OS-emulation project.** Today `game-tauri`'s
`src-tauri/src/lib.rs:40` opens a `1280.0 × 840.0` "Dev Toolkit" window wrapping `PHX_APP_URL`. The change:

- **`lib.rs` window config:** `inner_size` → an **iPhone 16 Pro Max** logical frame **440 × 956** (primary;
  the documented alternative is iPhone 15/14 Pro Max **430 × 932** — a one-line value the Operator/Steelman
  can confirm). "Max-height per the iPhone Max" = the **956** (or 932) height. Add `min_inner_size` =
  the same, `resizable(false)` (a fixed phone frame), and a product title (retire "Dev Toolkit"). The dev
  panel stays available but off the default product chrome.
- **CSS layout in the served app:** the GameRoom shell already centers at `max-w-sm` (384px content, §1);
  add `env(safe-area-inset-*)` padding (top/bottom safe area) so the screen reads like a shipped iOS app
  inside the fixed frame.

Pinned dims are grounded: the design content is `max-w-sm` = 384px on a 375-wide Figma frame
(`BoardScreen.tsx:92`); the window is the phone body around it (440-wide gives the 384 content + gutters).

## 4. The rung ladder (Steward decomposition — supersedes the cmt.4/cmt.5 stubs)

Thin, provable, reuse-first; risk deferred to the tail. Each rung is one `cmt.N` triad carved at ship time.

| Rung | Title | Risk | Depends | Deliverables (grounded) |
|---|---|---|---|---|
| **cmt.4** | **Tailwind v4 + native token theme** (the styling substrate) | LOW–MED | cmt.3 | `@tailwindcss/vite` in `vite.config.ts`; a native `@theme` reproducing the board token set (§3.1); a `cn`/`cx` util; **smoke: restyle one existing component** (e.g. `EmojiSlots`) to prove the pipeline. `cmt.3-INV4` self-containment re-checked. |
| **cmt.5** | **GameRoom core** (promote + style the loop) | MED | cmt.4 | `GameEdge → GameRoom` (rename; `mount` export unchanged); the `max-w-sm` phone-frame shell + gradient + `BoardCard`; restyle the 5 native components; live `$props`; the settled state + the existing event toasts. **Working, styled base GameRoom.** |
| **cmt.6** | **GameRoom guess surface** (tabs · history · previous-attempt) | LOW–MED | cmt.5 | `PreviousAttempt` (tap-to-refill), `BoardTabs` (History ⇄ Leaderboard), `GuessHistory` (**no `marks`** — deferred). Additive, on live `history`/`leaderboard`. |
| **cmt.7** | **GameRoom static long-tail** (rules · share · chrome) | LOW | cmt.5 (∥ cmt.6) | `GameRules`, `ShareKeys`, `StatusBar`/`NavPhonePanel` chrome, free-key footer; balances as **client placeholders** (F3). |
| **cmt.8** | **iPhone Pro Max window + safe-area** | LOW | cmt.5 (∥ cmt.6/7) | `game-tauri/src-tauri/src/lib.rs` `inner_size`/`min`/`resizable(false)`/title; the served-app `env(safe-area-inset-*)` CSS. Pinned dims (§3.3). |
| **cmt.9** | **Storybook + lightweight visual gate** | LOW | cmt.5+ | A co-located Storybook (the `@mercury/storybook` pattern) with a story per component; a `shot.js`-style screenshot pass over `storybook-static`. Live-screen diff **deferred**. |
| **cmt.10** | **Golden treatment** (the gold GameRoom variant) | MED | cmt.5–cmt.7 | Gold tokens (`--gold-texture`/`gold.png`), `GoldenHero`, the gathering/gold states, `GoldenAnswerReveal` on settle — a treatment on the whole GameRoom, not a separate screen. |

**Build order:** cmt.4 → cmt.5 → (cmt.6 ∥ cmt.7 ∥ cmt.8 ∥ cmt.9) → cmt.10. The base GameRoom is *whole and
shippable at cmt.7*; cmt.8/9 harden the app-feel and the gate; cmt.10 adds the gold skin last.

## 5. Forks + defer/reuse calls — surfaced for the Operator (never decided here)

- **F1 — Ladder supersession (the reframe).** Adopting GameRoom-first **reorders `tauri.specs.md`**: the
  current cmt.4/cmt.5 "port `GoldenInProgress`/`FinishedScreen`" stubs are replaced by the §4 ladder, and
  golden becomes cmt.10. *Steelman:* keep the golden-screen-first stubs (the golden room is the marquee
  MVP). *Steward:* base GameRoom first — it is the classic game, the reuse basis is highest, and golden is a
  thin treatment on top. **STOP — the Operator rules the ladder.**
- **F2 — Runtime dependencies (a design fork).** GameRoom adds: **Tailwind v4** (`@tailwindcss/vite`); a
  `cn`/`tailwind-merge` util (or reuse `@mercury/core` `cx`); Storybook (dev-only). *Steward REC:* Tailwind +
  reuse `@mercury/core cx` if it merges; **defer `react-i18next`** (keep inline RU). Adding `react-i18next`
  (EN + RU) is a later dependency-fork rung, not the critical path. **The Operator rules new deps.**
- **F3 — The data gap (a defer, echoing `tauri.design.md` F3).** `marks`, `diamonds`/`clips`/`keys`, `boost`
  have no `GameProps` source. *Steward REC:* **placeholders now, server-props later** — never invent. A
  `game_props` extension is a `/codemojex-ship` (echo/) rung, out of this track's boundary.
- **F4 — Visual-gate scope.** Static Storybook screenshot (Steward) vs a live-Tauri-screen diff rig
  (Steelman). *Steward REC:* start static; grow into live only if needed.
- **F5 — iPhone frame dims.** 440 × 956 (iPhone 16 Pro Max) vs 430 × 932 (15/14 Pro Max) — a one-line
  `lib.rs` value; confirm the exact target.

## 6. Boundary + gates (per surface a rung touches)

**Boundary (per `tauri.design.md` §6 + `cm-program.md`):** primary edit `mercury/codemojex/apps/game/**`
(island) + `mercury/codemojex/apps/game-tauri/**` (shell, cmt.8); **additive** `mercury/packages/mercury-*`
only if a coupled primitive is genuinely needed (barrel-additive; a change to an existing `@mercury/*` export
**forks to `/mercury-ship`**). `node/codemoji-design`, `mcp/e2e`, `mercury/apps/storybook` are **read-only
reference** — reuse the *pattern*, never edit. No `echo/` edit (a `game_props` need forks to
`/codemojex-ship`). Commits are pathspec-only, per-tree; never `git add -A`.

**Gate ladder (from `mercury/codemojex/`, never a blind `pnpm -r`):** `pnpm --filter @codemojex/game
typecheck && build && test`; the ESM bundle is one self-contained `game-[hash].js` exporting `mount` (grep:
no bare external import, no `@mercury/ui`) — `cmt.3-INV4`; the `@mercury/ui` barrel export set unchanged on
any `@mercury` touch. **game-tauri (cmt.8):** `cargo build` clean in `src-tauri` + a `cargo run` launch
smoke. **Determinism:** no id-mint/process/lease/schema surface (the screen is presentational, ids minted
elsewhere) — the ≥100 loop is **not required** (`tauri.specs.md` § determinism posture); posture = build +
run smoke + the visual gate. **A check counts only if it RUNS** — "renders on live state" is proven by a
mounted render fed by a channel/bridge event, "themes in the app look" by a Storybook screenshot, never by
reading source.

## References (grounded — real files)

- Island: `mercury/codemojex/apps/game/src/{index.tsx,GameEdge.tsx,types.ts}` ·
  `src/components/{EmojiSlots,EmojiKeyboard,GuessActions,Leaderboard,InfoDashboard,sprite}.ts(x)` ·
  `src/channel/{model.ts,PhoenixGame.tsx}` · `vite.config.ts` · `package.json`
- Shell: `mercury/codemojex/apps/game-tauri/src-tauri/src/lib.rs`
- State foundation: [`./cmt.3.md`] · [`./cmt.3.llms.md`] · `mercury/docs/game-effector/`
- Board reference (read-only): `node/codemoji-design/stories/board/{BoardScreen,EmojiKeyboard,BoardTabs,
  StatusBar,GuessHistory}.tsx` · `stories/board/lib/SpriteEmoji.tsx` · the token pipeline (`src/theme.mjs`)
- Visual-test precedents (read-only): `mercury/apps/storybook/{package.json,vite.config.ts}` ·
  `mcp/e2e/{shot.js,figures.suite.js,validator.js}`
- Canon: [`./tauri.design.md`] · [`./tauri.specs.md`] · [`../../program/codemojex.program.md`]
