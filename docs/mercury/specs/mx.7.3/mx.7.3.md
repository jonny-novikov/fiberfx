# mx.7.3 · SUB-EPIC — input / selection composites (split into 7.3.1 · 7.3.2 · 7.3.3)

> **Status: SUB-EPIC — Operator-ruled SPLIT 2026-06-30.** Batch 3 of the mx.7 import epic was over-band
> (~7–8 units, the mx.7 §1 rebalance flag), dominated by the two date machines. The Operator **sheds the date
> pair into their own focused batches, one machine each**, and keeps the four selection composites + the two
> folds together:
>
> | Sub-batch | Scope | Net-new / folds | Effort | Risk |
> |---|---|---|---|---|
> | **[mx.7.3.1](../mx.7.3.1/mx.7.3.1.md)** | **`DateField`** — the segmented mm/dd/yyyy spinbutton | 1 net-new | ~2–3 | NORMAL-to-ELEVATED (stateful keyboard machine) |
> | **[mx.7.3.2](../mx.7.3.2/mx.7.3.2.md)** | **`Calendar`** — the month-grid picker | 1 net-new | ~2–3 | NORMAL-to-ELEVATED (stateful grid + paging) |
> | **[mx.7.3.3](../mx.7.3.3/mx.7.3.3.md)** | `CheckboxGroup` · `CheckboxCards` · `RadioGroup` · `RadioCards` + folds `Textarea`/`ToggleGroup` | 4 net-new + 2 folds | ~4 | NORMAL (pure-presentational wrappers) |
>
> Net effect on the epic is unchanged: **6 net-new + 2 folds** reach `@mercury/ui`, now across three in-band
> ships with the Operator in the seat between each. This file is the **SUB-EPIC FRAME** (like the mx.7 epic) — it
> routes the shared forks to the sub-batch that owns them and carries nothing buildable. **There is no
> `.stories.md` / `.llms.md` at this sub-epic level** — each lives with its buildable sub-batch.

Parent epic: [`../mx.7/mx.7.md`](../mx.7/mx.7.md) · canon: [`../../mercury.design.md`](../../mercury.design.md) ·
prior batch: [`../mx.7.2/mx.7.2.md`](../mx.7.2/mx.7.2.md) · contract template:
[`../../contracts.md`](../../contracts.md).

---

## Why the split (Operator's between-batch rebalance)

The mx.7 epic §1 carried a standing **available rebalance**: *"mx.7.3 (~7–8u) is over-band, dominated by
`Calendar`+`DateField`; shedding those into their own date batch would leave 7.3 squarely in-band."* The
Director's pre-build grounding **sharpened** that into the decision:

- The bundle date prototypes are **simple and native** — `DateField` is 78 lines over a `{month,day,year}` string
  model + `parseInt` wrap; `Calendar` is a month grid over native `Date`. **Neither imports
  `@internationalized/date`.**
- `@mercury/core` carries **1519 lines of locale-aware date-field *machinery*** (`internal/date-time/field/*`)
  built on `@internationalized/date` — **but no `useDateField` / `useCalendar` React hook exists**. So the "reuse
  core" arm (A2 arm (a)) is **a from-scratch headless-hook build**, not "surface a ready hook" — genuinely the
  heaviest item in the original batch.

Each date machine is also an independent stateful keyboard surface (the elevated-verify focus). Giving each its
own batch lets the date-lib fork (§A·A2, below) be ruled and verified **per machine, in band**, instead of buried
in a six-component ship.

## The forks — routed to the sub-batch that owns them

The mx.7 epic's four **cross-batch** forks (I styling-idiom · II token/font additive · III name-collision policy ·
IV bundle git-fate) are inherited unchanged by all three sub-batches. The **batch-specific** calls from the
original mx.7.3 §A are routed:

| Call | Routed to | Steward (Operator rules at that sub-batch's ship) |
|---|---|---|
| **A1 — `*Cards` composition** (compose the live `Checkbox`/`Radio` in a card shell vs a standalone card-select impl) | **mx.7.3.3** | compose the live primitive |
| **A2 — the date primitives' lib** (build a curated `@mercury/core` date hook · ui takes `@internationalized/date` directly · native `Date`/string segments) | **mx.7.3.1** (DateField) **+ mx.7.3.2** (Calendar) | ruled per machine — see the grounded reframe in each sub-batch's §A·A2. **Hard invariant either way (INV-6): `@mercury/ui` must NOT `import "@internationalized/date"` directly.** |
| **A3 — the `ToggleGroup` collision** (fold into live `ToggleGroup`; no new export, no folder) | **mx.7.3.3** | fold (forced by the master invariant — a 2nd `ToggleGroup` export is a build break) |
| **TextArea fold** (epic Cross-fork III row — enrich live `Textarea` with `size`; no new export) | **mx.7.3.3** | fold |

> **A2 is ruled per machine, not once.** DateField and Calendar have *different* date-math needs (a segmented
> typed value vs a month-grid `Date`), so the Operator may rule them the same or differently. Each sub-batch
> frames A2 with the grounded cost (the from-scratch-hook reality) and the Operator rules at that ship.

## The cadence (mx.7 epic §2, per sub-batch)

Operator sharpens the sub-batch triad → **Trio** (Director + architect/`venus` + implementor/`mars` two-pass;
the date sub-batches may add `apollo` for the keyboard machine) reconciles + builds + verifies + hardens →
Operator reviews the new Storybook home(s) + the gate, carries lessons forward, releases the next sub-batch.
Feedback edits the spec, never the code directly.

## What every sub-batch inherits (from the mx.7 epic §5 — not re-stated)

The translation idiom (`.mx-*` + `cx` + tokens), the 4-file home, the additive barrel (master invariant,
resolved export set not a text-diff), the additive-only token/font policy, **design flows DOWN** (no
`/design-sync`/`DesignSync`), the gate (`pnpm --filter` typecheck/build · apps `!@mercury/storybook` · `sb:typecheck`
· `sb:build` · the barrel-diff + idiom/hex/framing greps), and the commit hygiene (bundle out of the pathspec;
`mercury/…` pathspec only; never `git add -A`; never `pnpm -r`).

## Map

The three buildable sub-batches: [`../mx.7.3.1/mx.7.3.1.md`](../mx.7.3.1/mx.7.3.1.md) (DateField) ·
[`../mx.7.3.2/mx.7.3.2.md`](../mx.7.3.2/mx.7.3.2.md) (Calendar) ·
[`../mx.7.3.3/mx.7.3.3.md`](../mx.7.3.3/mx.7.3.3.md) (the selection composites + folds). Parent epic:
[`../mx.7/mx.7.md`](../mx.7/mx.7.md). Next epic batches: [`../mx.7.4/mx.7.4.md`](../mx.7.4/mx.7.4.md) ·
[`../mx.7.5/mx.7.5.md`](../mx.7.5/mx.7.5.md).
