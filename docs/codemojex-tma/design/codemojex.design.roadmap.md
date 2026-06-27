# Codemoji · Design System — Figma Reconcile on the As-Built Screens

<show-structure depth="2"/>

This roadmap governs the **visual layer** of the Codemoji Telegram Mini App: the `@codemoji/design`
Storybook design system in `node/codemoji-design`, and the discipline that keeps each game screen
in step with its Figma master. It is the companion to the rendering roadmap
[`../codemojex-tma.roadmap.md`](../codemojex-tma.roadmap.md) — that plan decides **how** each tier
renders (Static welcome → LiveView lobby → LiveReact board); this plan decides **what** each screen
looks like and **how its appearance is held to the design source**. The two meet at one seam: the
React board island of Tier 3, whose content is the components catalogued here, mounted through
`mount(el, props, bridge)` against the `BoardProps` contract.

It is written against the as-built design system, not ahead of it. Every component, token, Figma
node id, and commit named here exists in `node/codemoji-design` — the one forward-tense exception is
the rung ladder below (`cmd.2`…`cmd.6`), which is reconciled ahead of its work and marked as such so
a reader never mistakes a planned rung for a shipped one.

## What the design system is

`@codemoji/design` is three things in one package:

1. **A token pipeline.** `tokens/tokens.mjs` → `src/theme.mjs` → `dist/theme.css` — a Tailwind v4
   `@theme` block with drop-in variable names (`--accent`, `--gradient-gold`, `--gold-texture`, the
   semantic `--primary`/`--enter` controls). A single themeable `--accent` drives the accent themes
   (orange/blue/green via `[data-theme]`); the gold treatment is formalized as `--gradient-gold` /
   `--gold-texture` (the app's `gold.png`). The app consumes the built `theme.css`; the wiring is the
   subject of [`../../../node/codemoji-design/THEMING.md`](../../../node/codemoji-design/THEMING.md).

2. **A Storybook component catalogue.** Each game screen is catalogued as a **live re-expression
   beside its Figma master** — the `DriftView` two-pane (the rendered build on the left, the exported
   Figma reference on the right) — so divergence is visible in the same view, not eyeballed across
   tools. Components live under `stories/board/`, `stories/golden-game/`, `stories/lobby/`; the
   assembled screens under `stories/screens/`.

3. **A Figma reconcile toolchain.** `bin/codemoji-design extract <nodeId>` walks a node through the
   token-free figma-local bridge and writes `figma/<screen>/` — `manifest.json` (the flattened
   figure list: id · name · type · x/y/w/h · render name), per-figure `reference/*.png`, `spec.md`,
   `tokens.md`. The visual-diff tools (`visual/`) screenshot a live story and compare it to the
   exported master.

## The reconcile contract — what "matches Figma" means

A screen is **reconciled** when its live re-expression reads as its Figma master under four rules:

- **Copy** — every string is localized through `react-i18next` (the existing app RU verbatim is
  canonical; EN is added). No hard-coded copy in a component.
- **Structure** — the section order, the card composition, the paddings/radii/gaps read as the
  master at the master's native width.
- **Deliberate overrides are preserved and recorded.** Where the app and the master disagree on a
  control or a treatment **on purpose**, the **app/canon wins**, and the divergence is written down
  as a decision — so a later pass does not "fix" an intentional override back toward a stale master.
  This is the load-bearing rule: the `DriftView` exists to *show* role-drift, not to erase it.
- **Verified in rendered pixels.** The gate is `shoot` → `compare`/`overlay` (and `structure-diff`
  where a manifest exists) against a fresh `export-node`, not a green build or a string grep. Build,
  then shoot, then read the side-by-side.

## The screens and their masters

| Screen | Tier (rendering roadmap) | Figma master(s) | Reference on disk | Reconcile rung |
|---|---|---|---|---|
| Welcome | 1 — Static HTML | — | — | out of scope (no framework surface) |
| Rooms (Lobby) | 2 — LiveView | `121:2056` (+ variants `561:12013`, `846:15620`) | `gameplay/assets/rooms-lobby-*.png` (whole-screen) | `cmd.3` |
| Game (Free) / Board | 3 — LiveReact island | `94:2974` | `figma/codemojies/` (**extracted manifest** + per-figure renders) | `cmd.2` |
| Golden Room — in progress | 3 — LiveReact island | `1089:19410` | `gameplay/assets/golden-room-in-progress-1089-19410.png` (whole-screen) | **`cmd.1`** |
| Golden Room — finished | 3 — LiveReact island | `1108:27589` | `gameplay/assets/golden-room-finished-1108-27589.png` (whole-screen) | **`cmd.1`** |

Only the board master (`94:2974`) is **extracted to a manifest** today, so `structure-diff` (figure
bbox ↔ live DOM bbox) is board-only. The lobby and golden screens have **whole-screen 1× PNGs only**
→ `overlay` is the available element-level tool until they are extracted. Closing that gap for golden
is a deliverable of `cmd.1`.

## The toolchain

| Tool (`node/codemoji-design/`) | Does | Half of the loop |
|---|---|---|
| `bin/codemoji-design extract <nodeId>` | Figma node → `figma/<screen>/` manifest + per-figure renders + spec/tokens | transform the source |
| `visual/figma-export.mjs` | one node → an image via the bridge (defaults to **@2x**) | capture the **exported Figma** |
| `visual/shoot.mjs` | serve `storybook-static/` and screenshot a story element | capture the **live** render |
| `visual/compare.mjs` | pixelmatch → a heat-map diff **+ a side-by-side composite** | compare (how *much*) |
| `visual/overlay.mjs` | onion-skin + difference-blend (resized to a common width) | compare (*shifted?*) |
| `visual/structure-diff.mjs` | manifest figure bboxes ↔ live DOM boxes → Δpos/Δsize per figure | compare (*which* element) |
| `visual/reexport-references.mjs` | re-export a screen's references in place at **@2x** | refresh references |
| `visual/drift.mjs` | one command: figma-export → shoot → compare | the whole loop |

**Retina @2x** is the standing fidelity floor: `figma-export` and `reexport-references` default to
`scale: 2`. The @2x chain is shipped end to end but **inert until the figma-local plugin is reloaded
on the Windows Figma machine** (the plugin renders the `SCALE` constraint); until then every tool
reports `[asked @2x, plugin returned @1x — reload the Figma plugin]`. The reload is an Operator
action on Operator infrastructure.

## The rung ladder

The design system is delivered one screen-reconcile at a time, then as a consumable theme + the
export bridge that turns figures into React. `cmd.1` is the first rung; the rest are reconciled here
forward-tense.

| Rung | Title | Status |
|---|---|---|
| **`cmd.1`** | **Codemojex Design: Golden Room ↔ Figma Reconcile** | this rung — see [`specs/cmd.1.md`](specs/cmd.1.md) |
| `cmd.2` | Board (Game Free) ↔ Figma Reconcile — formalize the shipped pass + the `InfoDashboard`/`StatCards` dashboard | PROPOSED (board reconcile largely shipped; this rung captures it as a spec) |
| `cmd.3` | Rooms (Lobby) ↔ Figma Reconcile — extract the lobby master to a manifest; settle the curated room/archive counts | PROPOSED (lobby reconcile largely shipped) |
| `cmd.4` | Tokens & Theming delivery — wire the app `@import` of `theme.css`, the accent themes, the gold tokens (`THEMING.md`) | PROPOSED |
| `cmd.5` | The figma-livesync export bridge — the `FigureBundle` IR → React slices (the figl S-2/S-5 seams; the RULED **Bundle (staged)** arm) | PROPOSED — grounded in [`../kb/figma-livesync/index.md`](../kb/figma-livesync/index.md) |
| `cmd.6` | Board-island delivery — the `mount(el, props, bridge)` + `BoardProps` contract the reconciled components ship behind | covered by the **rendering** roadmap (Tier 3); named here only for the seam |

## Standing laws (carried into every rung)

- **Deliberate role-drift is preserved and recorded** — never silently reverted toward the master.
  The recorded overrides to date: the blue `enter` control (`--color-enter` `#0050FF`); the gold
  treatment (`--gradient-gold` / `--gold-texture`) on the hero / answer-reveal / standings; the
  Main-Blue points bar in the leaderboard; the board gradient (`#E8F3F7 → #AFC7D6`) painted by the
  screen component itself.
- **Tokens are single-source** — a colour/treatment is a token in the pipeline, never a literal in a
  component, so the app and Storybook theme from one place.
- **The canon wins over a stale master** — where a Figma master predates an approved game-design
  recalibration (the Golden Room economy is the live example), the **approved canon**
  (`docs/codemojex/codemojex.design.md` + the calibration ledger) is the reconcile target, and the
  divergence from the master is recorded for Operator confirmation rather than silently kept.
- **The privacy / blind contract is visible in the design** — a golden game withholds per-guess
  scores until its sealed reveal; the components must render a score-less state and surface the secret
  only at close (`GoldenAnswerReveal` on the finished screen, never the in-progress one).
- **Verify rendered pixels** — build → shoot → read the side-by-side, every rung.
- **Commit pathspec-only** — `git commit -- <exact paths>`, never `git add -A`; the Operator
  pre-stages out-of-band, so re-verify `git diff --cached --name-only` is purely the rung first.

## Open seams

- **@2x plugin reload** — the Retina chain is shipped but waits on the Windows Figma plugin reload
  (Operator). Until then references stay 1×.
- **Golden + lobby manifests** — neither golden master nor the lobby master is extracted to a
  `figma/<screen>/manifest.json`, so `structure-diff` is board-only. `cmd.1` extracts golden.
- **Golden top-chrome** — the masters carry a `NavPhonePanel` + `BalancePill` + `StatCards` chrome
  the live golden screens render as only a thin `StatusBar`; the largest residual golden drift.
- **Boost-class → tournament canon drift** — the golden components still encode the **removed**
  `gold_multiplier` (the `GoldenHero` `boost` prop + `golden.prizePoolBoost` label, and the
  `screens.data.mjs` "boost-class" labels), against the approved $1-buy-in tournament canon. The
  reconcile direction is recorded in `cmd.1`.

## Map

Rendering roadmap: [`../codemojex-tma.roadmap.md`](../codemojex-tma.roadmap.md) · figma-livesync KB:
[`../kb/figma-livesync/index.md`](../kb/figma-livesync/index.md) · the export design fork:
[`../kb/figma-livesync/export.design.md`](../kb/figma-livesync/export.design.md) · game-design canon:
[`../../codemojex/codemojex.design.md`](../../codemojex/codemojex.design.md) · the design system:
`node/codemoji-design/` (`README.md` · `THEMING.md` · `visual/README.md`) · this ladder's first rung:
[`specs/cmd.1.md`](specs/cmd.1.md).
