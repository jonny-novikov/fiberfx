# CMD.1 · user stories

> Who wants the Golden Room screens reconciled to Figma, what they need, and how we will know it
> works. Connextra stories with Given/When/Then acceptance criteria; together they cover every
> deliverable in [`cmd.1.md`](cmd.1.md). The "test" for a design rung is a **rendered side-by-side**
> (build → shoot → overlay/structure-diff against the exported master), plus a static check for the
> copy and the boundary.

## CMD.1-US1 — See the in-progress Golden Room as designed

As a **player**, I want the in-progress Golden Room to look like its Figma design in my language, so
that the launch tournament reads as intended.

Acceptance criteria
- Given the `Screens/Golden Game` in-progress drift view, when it renders, then the section order is
  `StatusBar → GoldenHero → guess card → CTA → keyboard → standings → rules → share`, the hero is the
  gold-texture two-card (timer + prize pool), and the copy is Russian.
- Given a built-then-shot capture, when it is overlaid on `export-node 1089:19410`, then it reads as
  the master (residual drift named, not silently passed).
- Given the in-room CTA, when it renders, then it is the **dark** default button, not gilded.

INVEST — valuable on its own (the launch screen); testable by a rendered overlay + a composition
check; encodes CMD.1-INV5.
Priority: must · Size: 3 · Implements: CMD.1-D2, CMD.1-D8.

## CMD.1-US2 — See the finished Golden Room with the sealed reveal

As a **player**, I want the finished Golden Room to reveal the answer and let me play again, so that
I learn the secret only at settlement.

Acceptance criteria
- Given the finished drift view (`1108:27589`), when it renders, then `GoldenAnswerReveal` shows the
  revealed secret as filled emoji tiles on the gold-texture banner, above the dark "play again" CTA.
- Given a built-then-shot capture, when it is overlaid on `export-node 1108:27589`, then it reads as
  the master.
- Given the **in-progress** screen, when it renders, then **no** answer reveal and **no** per-guess
  score appear (the blind contract).

INVEST — independent of the in-progress screen; testable by a rendered overlay + a presence/absence
check; encodes CMD.1-INV2.
Priority: must · Size: 3 · Implements: CMD.1-D3, CMD.1-INV2.

## CMD.1-US3 — Localize every golden string

As a **player (RU) and a reviewer (EN)**, I want all golden copy to come from the locale files with
Russian preserved verbatim and English added, so that the screens read natively and a reviewer can
read them too.

Acceptance criteria
- Given any golden component, when it is searched, then it contains no hard-coded visible string —
  every string resolves through `react-i18next` (`golden.*` / `board.*` / `gameOverDialog.*`).
- Given the locale files, when the `golden.*` keys are diffed against HEAD, then the existing RU
  values are byte-verbatim and an EN value exists for each key.
- Given a newly added key, when it lands, then both `ru` and `en` carry it.

INVEST — independent; testable by a static grep + a locale diff; encodes CMD.1-INV3.
Priority: must · Size: 2 · Implements: CMD.1-D1, CMD.1-INV3.

## CMD.1-US4 — Keep the deliberate overrides from being "fixed"

As a **design-system maintainer**, I want the intentional golden divergences recorded as decisions, so
that a later reconcile pass does not revert them toward a stale master.

Acceptance criteria
- Given this rung's ledger and [`cmd.1.llms.md`](cmd.1.llms.md), when they are read, then the dark
  in-room CTA, the gold-texture treatment, the Main-Blue standings bar, and the board-gradient
  background are each recorded as a deliberate override with its reason.
- Given a reconcile pass, when it touches a recorded override, then it preserves it (a revert to the
  master fails the rung).
- Given the gold treatment, when a component is inspected, then it uses the `--gold-texture` token
  (the `bg-gold-texture` utility), not a colour literal.

INVEST — independent; testable by reading the record + a token grep; encodes CMD.1-INV1, INV4.
Priority: must · Size: 2 · Implements: CMD.1-D4, CMD.1-INV1, CMD.1-INV4.

## CMD.1-US5 — Make golden verifiable element-by-element

As a **design-system maintainer**, I want the golden masters extracted to a manifest, so that
`structure-diff` can quantify which golden element drifted, not just `overlay`.

Acceptance criteria
- Given `bin/codemoji-design extract` on `1089:19410` and `1108:27589`, when it runs, then
  `figma/golden/manifest.json` + `reference/*.png` exist (the figure list + renders).
- Given the manifest, when `structure-diff golden screens-golden-game--…` runs, then it prints Δpos/Δsize
  per golden figure (today only `overlay` is available for golden).
- Given the @2x chain, when the references are still 1×, then the tooling says so and a single
  `reexport-references golden` after the Windows plugin reload refreshes them to @2x.

INVEST — independent of the screen edits; testable by the manifest's existence + a `structure-diff`
run; encodes CMD.1-INV5.
Priority: should · Size: 2 · Implements: CMD.1-D5.

## CMD.1-US6 — Retire the removed boost economy from the design

As the **Operator**, I want the design's Golden Room economy to match the approved tournament canon,
not the removed `gold_multiplier`, so that the launch screens do not advertise a deleted mechanic.

Acceptance criteria
- Given the `GoldenHero` `boost` prop / `golden.prizePoolBoost` label and the `screens.data.mjs`
  "boost-class" labels, when they are reviewed, then the rung records them as drift from the approved
  tournament canon (`gold_multiplier` removed, `D-16`).
- Given the recorded reconcile direction, when it is read, then it states the **canon supersedes the
  pre-recalibration master**, and the divergence from the Figma master is flagged for Operator
  confirmation (not silently kept).
- Given Operator confirmation, when granted, then the boost framing is retired from the golden
  components and the catalogue labels (the edit itself may be a follow-up rung if the Operator defers).

INVEST — independent; testable by the recorded decision + a follow-up grep once confirmed; encodes
CMD.1-INV6.
Priority: must · Size: 2 · Implements: CMD.1-D6, CMD.1-INV6.

## CMD.1-US7 — One decision surface for the residual master-vs-build questions

As the **Operator**, I want the remaining golden master-vs-build differences logged with a
recommendation, so that I can settle them in one place.

Acceptance criteria
- Given the rung, when its decisions are read, then the **top-chrome** gap (`NavPhonePanel` +
  `BalancePill` + `StatCards` vs only `StatusBar`), the **finished-CTA copy** (open-room phrasing vs
  `gameOverDialog.playAgain`), and the **prize-unit** inconsistency (hero `💎` vs standings `$`/`🔑`)
  each appear with a recommended resolution.
- Given a logged decision, when the Operator rules, then the ruling is recordable as a follow-up
  without reopening the reconcile.

INVEST — independent; testable by reading the logged decisions; supports CMD.1-D7.
Priority: should · Size: 1 · Implements: CMD.1-D7.

## CMD.1-US8 — A reconcile that stays in its lane

As the **Operator**, I want the reconcile confined to the design system and committed by pathspec, so
that it cannot sweep my out-of-band working-tree changes.

Acceptance criteria
- Given the change, when `git status --short` is inspected, then every changed path is under
  `node/codemoji-design/`; no token-pipeline file changed unless a missing golden token forced it.
- Given the commit, when it is made, then it is `git commit -- <exact golden paths>` (never
  `git add -A`), and `git diff --cached --name-only` was verified to be purely the rung first.
- Given the Operator's pre-staged files, when the rung commits, then they are untouched.

INVEST — independent; testable by a status check + the commit form; encodes CMD.1-INV7.
Priority: must · Size: 1 · Implements: CMD.1-INV7.

---

Coverage: D1→US3 · D2→US1 · D3→US2 · D4→US4 · D5→US5 · D6→US6 · D7→US7 · D8→US1,US2 ·
INV1→US4 · INV2→US2 · INV3→US3 · INV4→US4 · INV5→US1,US5 · INV6→US6 · INV7→US8. Spec:
[`cmd.1.md`](cmd.1.md) · Agent brief: [`cmd.1.llms.md`](cmd.1.llms.md).
