# CMD.1 — Codemojex Design: Golden Room ↔ Figma Reconcile · agent brief (llms)

> The brief an implementor builds from and the Operator accepts against. It carries the **verified
> ground**, the **boundary**, the **deliberate-overrides table** (the load-bearing part — these are
> *not* drift to fix), the **residual-decisions table**, and the **rendered-pixel verification recipe**.
> Build to [`cmd.1.md`](cmd.1.md); cover [`cmd.1.stories.md`](cmd.1.stories.md). Invent no surface:
> ground every component, token, node id, and key in the as-built tree below or mark it forward-tense.

## References

- **Spec triad** — [`cmd.1.md`](cmd.1.md) (deliverables + invariants) · [`cmd.1.stories.md`](cmd.1.stories.md)
  (Given/When/Then) · this brief.
- **Design roadmap** — [`../codemojex.design.roadmap.md`](../codemojex.design.roadmap.md) (the `cmd.*`
  ladder, the reconcile contract, the standing laws).
- **Rendering roadmap** — [`../../codemojex-tma.roadmap.md`](../../codemojex-tma.roadmap.md) (the
  three-tier model; the board island is Tier 3; the blind/sealed `Codemojex.View` contract the design
  must honor — INV2).
- **Game-design canon** — [`../../../codemojex/codemojex.design.md`](../../../codemojex/codemojex.design.md)
  (the Golden Room = a `classic`-typed game carrying the `golden` marker, the buy-in tournament,
  `gold_multiplier` **removed**, calibration `D-16`/`D-18`). The canon for INV6/D6.
- **The masters** — Figma `1089:19410` (in-progress / open) · `1108:27589` (finished / settled).
  References on disk: `node/codemoji-design/gameplay/assets/golden-room-in-progress-1089-19410.png`,
  `…finished-1108-27589.png` (whole-screen, 1×).
- **Toolchain** — `node/codemoji-design/visual/README.md` (`extract`, `figma-export`, `shoot`,
  `compare`, `overlay`, `structure-diff`, `reexport-references`, `drift`) · `THEMING.md` (tokens).

## Reconcile ground (pre-build, verified against the as-built `node/codemoji-design`)

- **The two screens** — `stories/golden-game/GoldenScreen.tsx` exports `GoldenInProgressScreen`
  (`1089:19410`) and `GoldenFinishedScreen` (`1108:27589`) as plain components, backing both the
  `Golden Game/Overview` story and `stories/screens/GoldenGame.stories.tsx` (the drift view). Sample
  data lives in the file: `GOLDEN_STANDINGS`, `GOLDEN_ANSWER`.
- **In-progress composition (as-built)** — `StatusBar` → `GoldenHero` → guess `BoardCard`
  (`game.guessTheCode`, `EmojiSlots`, `GuessActions`) → `Button variant="default"` (`golden.viewWinners`,
  **dark**) → `EmojiKeyboard` card → `StandingsCard` (`BoardTabs defaultActive="leaderboard"` over
  `GoldenLeaderboard`) → `GameRules` → `ShareKeys`.
- **Finished composition (as-built)** — `StatusBar` → `GoldenHero` (`00:00:00`) → `GoldenAnswerReveal`
  → `Button variant="default"` (`gameOverDialog.playAgain`, dark) → `StandingsCard` → `GameRules` →
  `ShareKeys`.
- **`GoldenHero.tsx`** — gold-texture two-card grid (`bg-gold-texture`): left = `{timeLeft}` +
  `t('board.roundEnds')` ("Конец раунда"); right = `{prizePool.toLocaleString()} 💎` +
  `t('golden.prizePoolBoost', { boost })`. Banner = `t('golden.roomTitle')` (clip-text on
  `--gold-texture`) + `t('golden.readRules')`. **Carries `boost?: number /** the gold_multiplier … */`
  — the D6 drift.**
- **`GoldenAnswerReveal.tsx`** — `bg-gold-texture` banner, `t('golden.correctAnswer')`, the code as
  `EmojiTile size="sm" state="filled"` per slot. Finished-screen only (INV2).
- **Reused board components** — `StatusBar`, `EmojiSlots`, `GuessActions`, `EmojiKeyboard`, `BoardTabs`
  (switchable: `panels` map + `defaultActive`), `GameRules`, `ShareKeys`, `lib/BoardCard`,
  `lib/EmojiTile`.
- **Tokens** — gold is `--gold-texture` (the `bg-gold-texture` utility) plus the `--gold-*` family
  (`--gold-surface` / `--gold-border` / `--gold-foreground`, `--color-gold`) from the pipeline
  (`tokens/tokens.mjs` → `src/theme.mjs` → `dist/theme.css`). `--primary` = black (the dark
  CTA); `--color-enter` = `#0050FF` (the blue control). `dist/` and `bin/` are **gitignored-but-tracked**
  (force-add new files: `git add -f`).
- **Catalogue** — `stories/screens/screens.data.mjs` derives `goldenInProgress` (`game_state: 'open'`)
  and `goldenFinished` (`game_state: 'settled'`) from `gameplay/manifest.json`, flagged via
  `GOLDEN_SCREEN_IDS = ['1089:19410','1108:27589']`. **Still labels them "boost-class"** (D6 drift).
- **No `figma/golden/` manifest yet** — only `figma/codemojies/` (board) is extracted. D5 closes this.

## The deliberate overrides — PRESERVE, DO NOT "FIX" (INV1)

These golden divergences from the master are **intentional**. A pass that reverts any of them toward
the master **fails the rung**. Record each in the rung ledger as a decision.

| Override | As-built | Why it diverges from the master |
|---|---|---|
| Dark in-room CTA | `Button variant="default"` (black `--primary`) on both screens | The gold treatment is the hero / answer / standings — **not the action**. The master's in-room button is dark; the gild would over-saturate the screen. |
| Gold-texture gild | `bg-gold-texture` + clip-text on `--gold-texture` (gold.png) | The app renders the gild as a *texture* (gold.png), token-driven, not a flat gold fill — so it themes from one place (INV4). |
| Main-Blue standings bar | the points bar in the (shared) leaderboard | A deliberate role-colour the board reconcile already settled; carried into golden unchanged. |
| Board-gradient background | the screen component paints `#E8F3F7 → #AFC7D6` itself | The screen is self-contained (the lobby/board pattern), so the gradient is an override owned by the component, not the canvas. |

## The residual reconcile decisions — log with a recommendation (D6, D7)

| Decision | Master | As-built | Recommended resolution (for the Operator) |
|---|---|---|---|
| **Boost-class → tournament (D6)** | `1089`/`1108` predate the recalibration; likely show a boost | `GoldenHero.boost` + `golden.prizePoolBoost` + "boost-class" labels (the removed `gold_multiplier`) | **Canon wins** (INV6): retire the boost framing; the design must not advertise a deleted mechanic. Flag the divergence-from-master for confirmation. The *edit* may be a follow-up rung if deferred. |
| **Top-chrome gap (D7)** | `NavPhonePanel` + `BalancePill` + `StatCards` | only a thin `StatusBar` | Largest residual drift. Recommend mirroring the board chrome on golden **iff** the board (`cmd.2`) ships it; otherwise keep golden lean and record the divergence. Operator's call. |
| **Finished-CTA copy (D7)** | open-room phrasing ("play again in an open room") | `gameOverDialog.playAgain` | Recommend a dedicated `golden.playAgainOpen` key (RU + EN) if the master's distinction is intended; else keep the shared key. |
| **Prize-unit (D7)** | — | hero pool `💎` vs `GOLDEN_STANDINGS` prizes `$`/`🔑` | Inconsistent within one screen. Recommend one unit per surface, consistent with the lobby (which shows prize in USD per the rendering roadmap) and the economy (diamonds internal). Operator's call on player-facing unit. |

## Requirements (deliverable → check)

- **D1 / INV3** — `react-i18next` for every golden string; RU byte-verbatim vs HEAD, EN present. Check:
  `grep -RnE ">[А-Яа-яA-Za-z]" stories/golden-game/*.tsx` finds no hard-coded copy; a locale diff shows
  RU unchanged + EN added.
- **D2 / D3 / D8 / INV5** — the two compositions match their masters in a **rendered** side-by-side.
  Check: the verification recipe below.
- **D4 / INV1** — the overrides table above is in the ledger; no revert. Check: read the ledger; grep
  the components still carry the override.
- **D5** — `figma/golden/manifest.json` + `reference/*.png` exist. Check: `extract` ran; `structure-diff
  golden …` prints a table.
- **D6 / INV6** — the canon-drift decision recorded with direction + Operator flag.
- **D7** — the three decisions logged with recommendations.
- **INV2** — in-progress shows no score / no reveal; `GoldenAnswerReveal` finished-only. Check: grep
  `GoldenInProgressScreen` does not name `GoldenAnswerReveal`.
- **INV4** — gold via tokens. Check: no gradient/colour literal in a golden `.tsx`.
- **INV7** — boundary + pathspec commit. Check: `git status --short` all under `node/codemoji-design/`.

## Agent stories

### CMD.1-AS1 — Reconcile the in-progress screen + record its overrides [implements US1, US4]
Confirm `GoldenInProgressScreen` composes the master order with the gold-texture hero, the dark CTA,
and the score-less in-room state; record the dark-CTA + gold-texture + Main-Blue + gradient overrides
as decisions. Shoot + overlay against `export-node 1089:19410`; name any residual drift.

### CMD.1-AS2 — Reconcile the finished screen + hold the blind contract [implements US2]
Confirm `GoldenFinishedScreen` shows `GoldenAnswerReveal` (finished-only) above the dark CTA; confirm
the in-progress screen shows neither scores nor a reveal. Shoot + overlay against `export-node 1108:27589`.

### CMD.1-AS3 — Localize + verify the copy [implements US3]
Confirm every golden string resolves through `react-i18next`; diff the `golden.*` keys against HEAD
(RU byte-verbatim, EN present); add both locales for any new key.

### CMD.1-AS4 — Extract the golden masters to a manifest [implements US5]
`bin/codemoji-design extract 1089:19410` and `1108:27589` → `figma/golden/`; run `structure-diff golden`.
Note the @2x state (1× until the Windows plugin reload; `reexport-references golden` after).

### CMD.1-AS5 — Record the canon + residual decisions [implements US6, US7]
Log D6 (boost-class → tournament, canon wins, Operator flag) and D7's three decisions (top-chrome,
finished-CTA copy, prize-unit) with recommendations.

### CMD.1-AS6 — Hold the boundary + pathspec commit [implements US8]
Keep the change under `node/codemoji-design/`; verify `git diff --cached --name-only` is purely the
rung; commit `git commit -- <golden paths>`; never `git add -A`; leave Operator out-of-band files.

## Verification recipe (the rendered gate — INV5)

```sh
cd node/codemoji-design
pnpm build-storybook                       # produce storybook-static/ (rebuild ONCE; do not race parallel builds)

# in-progress (1089:19410)
pnpm figma-export 1089:19410 /tmp/g-prog.figma.png         # @2x once the plugin is reloaded; 1× until then
pnpm shoot screens-golden-game--in-progress figure /tmp/g-prog.live.png
pnpm overlay /tmp/g-prog.figma.png /tmp/g-prog.live.png /tmp/g-prog
#  → read /tmp/g-prog.overlay.png (ghosted double edge = a shift) + /tmp/g-prog.diff-blend.png

# finished (1108:27589) — same three steps with the finished story id and 1108:27589

# after D5 (manifest extracted) — element-level golden drift:
pnpm extract 1089:19410 && pnpm extract 1108:27589
pnpm structure-diff golden screens-golden-game--finished figure
```

Read the side-by-side; a green `pnpm exec tsc` / `build-storybook` alone does **not** satisfy the
rung. (Confirm the exact story ids from `GoldenGame.stories.tsx` — the kebab is `title--export-name`,
e.g. `screens-golden-game--in-progress`.)

## Build notes (design-system gotchas, verified this session)

- **`pnpm exec tsc`, not `npx`.** Bare `pnpm exec tsc` may abort `TS2688 Cannot find type definition
  file for 'node'` (tsconfig pins `types:["node"]` but `@types/node` is absent) — use the
  explicit-flag form (`--lib ES2022,DOM,DOM.Iterable …`) which bypasses tsconfig, or add `@types/node`.
- **`@2x` is plugin-gated.** The chain is shipped; it returns 1× until the **Windows** figma-local
  plugin is reloaded (an Operator action — never deploy to Operator infra). Tools say so explicitly.
- **`/usr/bin/grep` for multi-path** (the aliased `ugrep` mangles multi-path) — **but BSD grep has no
  `-P`/PCRE**: use `node` or `rg` for Unicode classes (a `grep -P '[\x{0400}-\x{04FF}]'` Cyrillic scan
  silently returns nothing on macOS — a false negative).
- **`dist/` and `bin/` are gitignored-but-tracked** — `git add -f` a new file there; a plain
  `git commit -- <path>` works for an already-tracked file.
- **Rebuild once, shoot many.** Do not run parallel `build-storybook` (the shared `storybook-static/`
  races). Analyze read-only, edit, then one rebuild.
- **Measurement artifacts to ignore** — the figure-bezel ~+7px x-offset; the 1000px component-story
  viewport stretch; live render ~42–46% of the master frame height because the DS stubs image-heavy
  regions (so whole-screen overlay is meaningless — compare **section by section**); `structure-diff`
  mis-pairs background/full-frame figures (a diagnostic aid, not a gate).
- **Verify a flagged "corruption" before acting** — a reported i18n "Mr. n" corruption this session was
  a **false alarm** ("Совет от Mr. Freeman:" was intact). Read the actual bytes before "fixing."

## Prose discipline (into every artifact, code comment, and sub-prompt)

No gendered pronouns for any agent; no perceptual verbs (sees / notices) or interior-state (wants /
feels); no first-person agent narration. Third person for any agent reference. Enforce these same rules
in any prompt this brief's reader emits. The implementor edits only files under `node/codemoji-design/`
and never commits — the Director commits, pathspec-only, when asked.
