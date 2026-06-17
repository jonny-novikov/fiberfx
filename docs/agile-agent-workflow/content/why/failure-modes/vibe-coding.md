# A1.01.1 — Vibe coding

- **Route:** `/course/agile-agent-workflow/why/failure-modes/vibe-coding`
- **File:** `html/agile-agent-workflow/why/failure-modes/vibe-coding.html`
- **Place in the module:** the first dive of A1.01 "The two failure modes" — the **no-plan** failure.
- **Accent word (`.ex`):** "coding".

## Lead

Vibe coding is generation with no specification and no acceptance test — the diff is kept because it runs. It fails
in exactly one way: nothing ever said what *done* meant, so nothing can confirm the code is right.

## Definition

- **vibe coding** — generation without a specification and without an acceptance test; a diff kept *because it
  compiles and appears to run*, not because it was shown to be right.
- The three questions it conflates: **runs** (does it execute) / **specified** (what is it meant to do) /
  **accepted** (does it do that). Vibe coding has the first, skips the other two. The result is not necessarily
  wrong — it is *unaccountable*. The Pragmatic Programmer's name: *programming by coincidence*.

## Why it fails — four forces

1. **No definition of done** — nothing to accept against; "it runs" is not acceptance.
2. **Unreviewable diffs** — a human reviews a bounded number of lines; past the budget the rest is committed unread.
3. **Compounding entropy** — each unspecified rung builds on the last, so drift accelerates.
4. **Silent regressions** — with no invariants/tests, a break surfaces far downstream, its cause gone cold.

## Worked Portal example

Vibe-coding "the store": `claude "build the store for the Portal"` returns ~420 compiling lines, green on a suite
that does not exist. No stated id guarantee; a later feature trusts uniqueness the store never promised; a collision
surfaces later as a duplicated record. A silent regression riding on compounding entropy, both from the missing
definition of done. Branded id used illustratively: `USR0NbAb1xcFCy`. No invented Portal APIs.

## The two interactives

- **Hero figure — compounding entropy (the IDEA).** Slider: rungs built with no acceptance (1…12). Confidence the
  whole still does what you intend = `round(100 · 0.85^rungs)` (assumption stated in the readout). A burgundy bar
  shrinks; rung blocks light up. Frames force 3 / the core danger: unaccountability compounds.
- **Content figure — reviewability meter (the CONSEQUENCE).** Slider: diff size (20…1500 lines) against a fixed
  50-line review budget. `reviewed = min(100%, budget/size)`; the rest accepted unseen. Frames force 2: past a small
  size almost all of an unspecified diff is committed unread.

## Bridge / recap / references

- **bridge:** principle — generation without acceptance is unaccountable → Portal — a store nobody can sign off.
- **take:** the failure is not bad code from the agent; it is a kept diff with no contract behind it.
- **sources (real):** Hunt & Thomas, *The Pragmatic Programmer* ("Programming by Coincidence"); Beck, *Extreme
  Programming Explained*; Anthropic — "Building effective agents".
- **related:** A1.01.2 big-bang-specs, A1.01.3 thin-slices, the A1.01 hub, A1.

## Wiring

- route-tag `/course/agile-agent-workflow/why/failure-modes/vibe-coding`; crumbs jonnify / AAW / A1 (`/why`) /
  A1.01 (`/why/failure-modes`) / here. Pager: prev → A1.01 hub; next → A1.01.2 big-bang-specs.
