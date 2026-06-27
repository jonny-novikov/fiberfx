# CMD.1 · Codemojex Design: Golden Room ↔ Figma Reconcile

> Bring the two **Golden Room** screens — in-progress (`1089:19410`) and finished (`1108:27589`) — to
> fidelity against their Figma masters in the `@codemoji/design` Storybook: localized copy, aligned
> structure, the deliberate role-drift **overrides preserved and recorded**, the blind/sealed contract
> visible in the components, and the golden masters extracted to a `figma/golden/` manifest so the
> match is **verifiable in rendered pixels**, not eyeballed. The one place the design must diverge from
> the master — the removed `gold_multiplier` "boost" framing — is reconciled toward the **approved
> tournament canon** and flagged for Operator confirmation.

## Goal

After `cmd.1`, the `Screens/Golden Game` drift views read as their masters: the in-progress screen
(`GoldenInProgressScreen`) and the finished screen (`GoldenFinishedScreen`) render the gold hero,
the score-less in-room state, the sealed answer reveal, the standings, the rules, and the share block
in Russian, at the master's composition — and every place the live build *intentionally* differs from
the master (the dark in-room CTA, the gold-texture treatment, the Main-Blue standings bar, the
tournament economy that supersedes the master's boost) is written down as a decision rather than left
as ambiguous drift. The golden masters are extracted to `figma/golden/manifest.json` with @2x
references, so `structure-diff` works on golden (today only `overlay` does), and the reconcile is
gated by a rendered side-by-side, not a build. This is the first rung of the `cmd.*` design ladder
(see [`../codemojex.design.roadmap.md`](../codemojex.design.roadmap.md)).

## Rationale (5W)

- **Why** — The Golden Room is the launch differentiator (the $1-buy-in tournament, calibration
  ledger `D-16`/`D-18`), and its two screens are the **most-drifted** in the catalogue: golden-specific
  surfaces with no shared-board equivalent, a top-chrome gap, a stale boost-class economy baked into a
  component, and a prize unit that disagrees with itself within one screen. A reconcile makes the
  board island render the **approved** design, and — more durably — **records every deliberate
  divergence** so the recurring failure mode of a design pass (a verifier "fixing" an intentional
  override back toward the master, or silently keeping a master that the game design has since
  superseded) cannot happen on golden again. The Golden Room also carries the **blind/sealed**
  contract from the engine (`Codemojex.View` withholds scores for a golden game before reveal); the
  design must make that contract visible, not contradict it.
- **What** — localize the golden copy through `react-i18next`; align the two screens' structure to
  their masters; **preserve and record** the gold treatment, the dark in-room CTA, and the Main-Blue
  standings bar as deliberate overrides; make the score-less-until-reveal state explicit; **extract**
  the two golden masters to a `figma/golden/` manifest with @2x references; and **reconcile the canon
  drift** — the `GoldenHero` `boost`/`gold_multiplier` framing and the `screens.data.mjs` "boost-class"
  labels against the approved tournament economy — recording the direction (canon wins) for Operator
  confirmation.
- **Who** — **players** (see the approved Golden Room, in their language, honoring the blind rule);
  the **board-island builder** (renders Tier 3 from reconciled components against `BoardProps`); the
  **design-system maintainer** (a recorded contract of what matches and what is a deliberate override,
  so a future pass does not re-litigate settled drift); the **Operator** (one decision surface for the
  canon-vs-master divergences).
- **When** — the **first** rung of the design ladder; it depends on the shipped board reconcile (the
  shared `stories/board/` components golden reuses) and the shipped drift toolchain (`extract`,
  `shoot`, `compare`, `overlay`, `structure-diff`, the @2x chain) — both landed earlier in the design
  system. It precedes `cmd.2` (board), `cmd.3` (lobby), and `cmd.4` (theming delivery).
- **Where** — `node/codemoji-design/`: `stories/golden-game/` (`GoldenScreen.tsx`, `GoldenHero.tsx`,
  `GoldenAnswerReveal.tsx`, `GoldenLeaderboard.tsx`), the shared `stories/board/` components golden
  reuses (`StatusBar`, `EmojiSlots`, `GuessActions`, `EmojiKeyboard`, `BoardTabs`, `GameRules`,
  `ShareKeys`, `lib/BoardCard`), `stories/screens/GoldenGame.stories.tsx` + `stories/screens/screens.data.mjs`,
  `stories/i18n/locales/{ru,en}/translation.json`, and the new `figma/golden/` manifest. **No file
  outside `node/codemoji-design/` is touched**, and no token-pipeline file changes unless a missing
  golden token is required (in which case it lands in `tokens/tokens.mjs`, never a component literal).

## Scope

- **In** — the two golden screens' copy, structure, and recorded overrides; the golden components
  (`GoldenHero`, `GoldenAnswerReveal`, `GoldenLeaderboard`) and the golden composition in
  `GoldenScreen.tsx`; the localized strings in the `golden.*` / `board.*` namespaces; the extraction
  of `1089:19410` and `1108:27589` to `figma/golden/manifest.json` + `reference/*.png` (@2x); the
  recorded reconcile direction for the boost-class → tournament canon drift, the golden top-chrome
  gap, the finished-CTA copy, and the prize-unit inconsistency.
- **Out** — the Golden Room **engine** build (the `:gathering` state, the buy-in, `close_split`) — that
  is a `codemojex.roadmap.md` rung, not a design rung; the **lobby** Golden Room *card* (the room entry
  point lives on the lobby screen → `cmd.3`); the board (Game Free) reconcile (→ `cmd.2`); the theming
  **delivery** / app `@import` wiring (→ `cmd.4`); the figma-livesync **export bridge** (→ `cmd.5`); the
  board-island `mount`/`BoardProps` wiring (rendering roadmap, Tier 3); any change to the figma-local
  **plugin** (Operator infra) — the @2x reload is a handoff, not a deliverable here.

## Deliverables

- **CMD.1-D1 (localized golden copy)** — every golden string resolves through `react-i18next` with the
  existing RU verbatim as canonical and EN added: the hero (`golden.roomTitle`, `golden.readRules`,
  `board.roundEnds`, the prize label), the in-room CTA (`golden.viewWinners`), the finished CTA
  (`gameOverDialog.playAgain`), and the answer reveal (`golden.correctAnswer`). No hard-coded copy in a
  golden component. *(Shipped earlier in the session; this rung records it as the contract.)*
- **CMD.1-D2 (in-progress screen `1089:19410` reconciled)** — `GoldenInProgressScreen` composes, in the
  master's order: `StatusBar` → `GoldenHero` (gold-texture two-card: timer + prize pool) → the guess
  `BoardCard` (heading `game.guessTheCode`, `EmojiSlots`, `GuessActions`) → the **dark** in-room CTA
  (`Button variant="default"`, **not** gilded) → the `EmojiKeyboard` card → the standings
  (`BoardTabs defaultActive="leaderboard"` over `GoldenLeaderboard`) → `GameRules` → `ShareKeys`. The
  gild is the gold **texture** on the hero, not the action.
- **CMD.1-D3 (finished screen `1108:27589` reconciled)** — `GoldenFinishedScreen` composes:
  `StatusBar` → `GoldenHero` (timer `00:00:00`) → `GoldenAnswerReveal` (the revealed secret as filled
  `EmojiTile`s on a gold-texture banner) → the dark CTA → standings → `GameRules` → `ShareKeys`. The
  answer reveal appears **only** on the finished screen.
- **CMD.1-D4 (overrides recorded)** — the deliberate golden divergences from the master are written as
  decisions in this rung's ledger and as a table in [`cmd.1.llms.md`](cmd.1.llms.md): the dark in-room
  CTA (the gold treatment is the hero/answer/standings, never the action); the gold-texture treatment
  via the `--gold-texture` token (the `bg-gold-texture` utility); the Main-Blue points bar in the standings; the
  board-gradient screen background. Each is preserved, not reverted.
- **CMD.1-D5 (golden masters extracted)** — `figma/golden/manifest.json` + `reference/*.png` for
  `1089:19410` and `1108:27589` via `bin/codemoji-design extract`, at @2x, so `structure-diff` runs on
  golden (today only `overlay` does, because golden has whole-screen PNGs only). **Blocked on the
  Windows figma-local plugin reload for true @2x**; the extraction itself (manifest + 1× references) is
  not blocked and lands now, with the @2x refresh a one-command follow-up (`reexport-references golden`)
  after the reload.
- **CMD.1-D6 (canon reconcile — boost-class → tournament)** — the reconcile **direction** is recorded:
  the `GoldenHero` `boost` prop (doc'd "the `gold_multiplier` applied to the base pool") + the
  `golden.prizePoolBoost` label, and the `screens.data.mjs` "boost-class" labels, encode the **removed**
  economy (`gold_multiplier` deleted, `D-16`). The approved canon is the buy-in **tournament**
  (`codemojex.design.md`). The recorded direction: **the canon supersedes the (pre-recalibration)
  master** — the boost framing is drift to retire — flagged for Operator confirmation because it is a
  visible divergence from the Figma master.
- **CMD.1-D7 (residual reconcile decisions logged)** — three master-vs-build questions are logged with
  a recommended resolution, for the Operator: the **top-chrome** gap (`NavPhonePanel` + `BalancePill` +
  `StatCards` in the masters vs only `StatusBar` live — the largest residual drift); the **finished-CTA
  copy** (the master's open-room phrasing vs `gameOverDialog.playAgain`); the **prize-unit**
  inconsistency (`GoldenHero` pool renders `💎` while `GOLDEN_STANDINGS` prizes render `$`/`🔑`).
- **CMD.1-D8 (verification)** — for each screen, `pnpm build-storybook` → `pnpm shoot screens-golden-game--…`
  → `pnpm overlay` (and `structure-diff` once D5's manifest exists) against a fresh `export-node`, with
  the side-by-side read and the residual drift named. The recorded gate is the **rendered** comparison,
  not the build or a string grep.

## Invariants

- **CMD.1-INV1 (overrides are not drift)** — the recorded deliberate divergences (D4) are preserved on
  every pass. A reconcile that reverts the dark in-room CTA to gold, the Main-Blue bar to the master's
  colour, or the gold texture to a flat fill **fails** this rung. The `DriftView` shows role-drift; it
  does not authorize erasing it.
- **CMD.1-INV2 (the blind/sealed contract is visible)** — the in-progress screen renders **no**
  per-guess score signal and **no** answer reveal; `GoldenAnswerReveal` appears **only** on the finished
  screen. The components cannot show what a golden game withholds before close — mirroring
  `Codemojex.View` widening the privacy gate for a golden game (the engine contract in
  [`../../codemojex-tma.roadmap.md`](../../codemojex-tma.roadmap.md)).
- **CMD.1-INV3 (localized — RU canonical, EN added)** — no golden component contains a hard-coded
  string; every visible string resolves through `react-i18next`; the existing RU values are preserved
  **verbatim** (byte-identical) and EN is added beside them. A new key adds both locales.
- **CMD.1-INV4 (tokens single-source)** — the gold treatment is the `--gold-texture` token (and the
  `bg-gold-texture` utility) plus the `--gold-*` family, never a colour literal or an inline gradient in a golden
  component; a new golden colour lands in `tokens/tokens.mjs`, not in a `.tsx`.
- **CMD.1-INV5 (verified in rendered pixels)** — the gate is a built-then-shot side-by-side against the
  exported master (`overlay`, and `structure-diff` after D5); a green `tsc`/`build-storybook` alone does
  not satisfy the rung.
- **CMD.1-INV6 (the canon wins over a stale master)** — where the master (`1089`/`1108`) predates the
  Golden Room economy recalibration, the **approved tournament canon** is the reconcile target; the
  boost-class framing (D6) is retired, and the divergence from the master is recorded for the Operator,
  not silently kept.
- **CMD.1-INV7 (boundary)** — the change stays inside `node/codemoji-design/`; no token-pipeline file
  changes unless a missing golden token forces it (then in `tokens/tokens.mjs`); the Operator's
  out-of-band working-tree files are untouched; the commit is pathspec-only.

## As-built surface (reconcile capture — keeper sync)

Recorded from the as-built tree so the next rung reconciles against truth. Much of `cmd.1`'s match
**shipped earlier in this session**; this section names the concrete surface, and the Deliverables
above carry the residual open items (D5 @2x, D6 canon, D7 the three logged decisions).

- **The two screens** — `stories/golden-game/GoldenScreen.tsx` exports `GoldenInProgressScreen`
  (`1089:19410`) and `GoldenFinishedScreen` (`1108:27589`) as plain components (not stories), so they
  back both the `Golden Game/Overview` story and the `Screens/Golden Game` drift view
  (`stories/screens/GoldenGame.stories.tsx`). Sample data: `GOLDEN_STANDINGS`, `GOLDEN_ANSWER`.
- **Golden-specific surfaces** —
  - `GoldenHero.tsx` — the gold-texture two-card hero (timer + `board.roundEnds`; pool
    `{prizePool} 💎` + `golden.prizePoolBoost`) over a `golden.roomTitle` / `golden.readRules` banner;
    the gild is `bg-gold-texture` + a clip-text fill on `--gold-texture`. **Carries the stale `boost`
    prop (D6).**
  - `GoldenAnswerReveal.tsx` — the finished-screen secret reveal: `golden.correctAnswer` + the code as
    filled `EmojiTile`s on `bg-gold-texture` (INV2 — finished only).
  - `GoldenLeaderboard.tsx` + its story — the golden standings (avatar + handle + code + prize),
    shown through the shared `BoardTabs` opened on the leaderboard tab.
- **Reused from the board** (the Golden Game IS the board with a gold treatment) — `StatusBar`,
  `EmojiSlots`, `GuessActions`, `EmojiKeyboard`, `BoardTabs`, `GameRules`, `ShareKeys`, `lib/BoardCard`.
- **CTAs reconciled to the masters** — both in-room CTAs are `Button variant="default"` (dark), not
  gilded: the in-progress "view winners" (`golden.viewWinners`) and the finished "play again"
  (`gameOverDialog.playAgain`). Recorded override D4 (the action is never the gold surface).
- **Localization** — the `golden.*` and shared `board.*` keys exist in
  `stories/i18n/locales/{ru,en}/translation.json` with RU canonical + EN. (The session verified the
  shared `gameRules.tipFrom` / `board.shareKeys.tip` values are intact — "Совет от Mr. Freeman:" — a
  reported corruption was a false alarm.)
- **References on disk** — whole-screen 1× PNGs at `gameplay/assets/golden-room-in-progress-1089-19410.png`
  and `…finished-1108-27589.png`; **no `figma/golden/` manifest yet** (D5 closes this). The
  `screens.data.mjs` catalogue derives `goldenInProgress` (`game_state: 'open'`) and `goldenFinished`
  (`game_state: 'settled'`) from the gameplay manifest, flagged via `GOLDEN_SCREEN_IDS` — and still
  labels them **"boost-class"** (D6 drift).
- **Toolchain available** — `extract`, `figma-export` (@2x), `shoot`, `compare`, `overlay`,
  `structure-diff`, `reexport-references` (@2x), `drift`; the @2x chain inert pending the Windows plugin
  reload.

## Definition of Done

- [ ] `GoldenInProgressScreen` (`1089:19410`) composes the master's section order with the gold-texture
      hero, the score-less in-room state, and the **dark** in-room CTA; a built-then-shot side-by-side
      against `export-node 1089:19410` reads as the master, with residual drift named (CMD.1-D2, D8,
      INV5).
- [ ] `GoldenFinishedScreen` (`1108:27589`) composes the answer reveal (finished-only) + the dark CTA;
      the side-by-side against `export-node 1108:27589` reads as the master (CMD.1-D3, INV2).
- [ ] Every golden string resolves through `react-i18next`; RU is byte-verbatim and EN is present; no
      hard-coded copy in a golden component (CMD.1-D1, INV3).
- [ ] The deliberate overrides (dark CTA, gold texture, Main-Blue bar, board-gradient background) are
      recorded as decisions and preserved — no revert toward the master (CMD.1-D4, INV1).
- [ ] The gold treatment is the `--gold-texture` token (`bg-gold-texture`), not a component literal
      (CMD.1-INV4).
- [ ] `figma/golden/manifest.json` + `reference/*.png` exist for both masters (extraction lands now;
      @2x refresh is a one-command follow-up after the plugin reload) (CMD.1-D5).
- [ ] The boost-class → tournament canon drift is recorded with its direction (canon supersedes the
      stale master) and flagged for the Operator (CMD.1-D6, INV6).
- [ ] The three residual decisions (top-chrome, finished-CTA copy, prize-unit) are logged with a
      recommendation for the Operator (CMD.1-D7).
- [ ] The change stays inside `node/codemoji-design/`; the Operator's out-of-band files are untouched;
      the commit is pathspec-only (CMD.1-INV7).
- [ ] Every deliverable maps to a user story and every invariant is exercised by a check (see
      [`cmd.1.stories.md`](cmd.1.stories.md)).

---

Stories: [`cmd.1.stories.md`](cmd.1.stories.md) · Agent brief: [`cmd.1.llms.md`](cmd.1.llms.md) ·
Design roadmap: [`../codemojex.design.roadmap.md`](../codemojex.design.roadmap.md) · Rendering roadmap:
[`../../codemojex-tma.roadmap.md`](../../codemojex-tma.roadmap.md) · Game-design canon:
[`../../../codemojex/codemojex.design.md`](../../../codemojex/codemojex.design.md) · The design system:
`node/codemoji-design/` (`README.md` · `THEMING.md` · `visual/README.md`).
