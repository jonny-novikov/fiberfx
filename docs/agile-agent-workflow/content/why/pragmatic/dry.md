# A1.02.1 — The single source of truth (DRY)

- **Route:** `/course/agile-agent-workflow/why/pragmatic/dry`
- **File:** `html/agile-agent-workflow/why/pragmatic/dry.html`
- **Place in the module:** the first dive of A1.02 — the *knowledge* principle. Where does a fact live when an
  agent will happily write it in five places?
- **Accent word (`.ex`):** "truth".

## Lead

DRY — Don't Repeat Yourself — was never about typing; it was about knowledge. Every piece of knowledge should
have one authoritative representation. When an agent generates code, duplication becomes free to produce and
the same price to reconcile — so the principle inverts from a typing convenience into the discipline that keeps
a fact from drifting.

## Definition

- **DRY** — every piece of knowledge has a single, authoritative, unambiguous representation in the system
  (Hunt & Thomas). The opposite is the same fact restated in many places.
- **single source of truth** — the one representation every reader derives from, so a change happens in exactly
  one place and reaches every reader at once.
- **drift** — when copies of one fact stop agreeing because a change reached some and not others.
- The agent-era inversion: generation makes the *k−1* duplicate copies free to create. The reconciliation cost
  — finding and updating every copy when the fact changes — is unchanged, and the human pays it, not the agent.

## Why it matters — the two costs of a duplicated fact

1. **Drift surface.** A fact in *k* places has *k−1* sites that can fall out of agreement. With one source there
   is nothing to keep in sync.
2. **Reconciliation cost.** Changing the fact means editing every copy; the more copies, the lower the
   confidence that all of them were found and updated consistently.

## Worked Portal example

The branded id format — "a 14-character `TSK…` id that decodes to a type" — is one fact. It must live in one
place: the `Portal.ID` module. The store, the Telegram bot, and the student dashboard all call `Portal.ID`;
none re-derives the format. Ask the agent for "an id" in three surfaces and it will re-derive "14 chars" three
times; change the format later (say to 15) and the two surfaces it forgot break silently. The single-source fix
is not cleverness — it is pointing the agent at `Portal.ID` as the authority. Use only the established API
(`Portal.ID.generate/1`, `Portal.ID.decode/1`); do not invent new functions.

## The two interactives (different teaching moves)

- **Hero figure — change the fact, watch it drift (the SHAPE).** One `.solid-select` 2-button toggle `state`:
  "in sync" / "fact changed", and one `.fold-ctrl` slider `copies` (1…8). The SVG draws `copies` blocks: block 0
  is the gold **source of truth**; blocks 1…copies−1 are duplicates, drawn blue when `state=sync` and burgundy
  ("stale") when `state=changed`. Readout is computed from two pure functions:
  `driftSurface(copies) = copies - 1`, `stale(copies, changed) = changed ? copies - 1 : 0`.
  - copies=1: "One source of truth — nothing to keep in sync" (sync) / "The source changed; every reader sees it
    at once — 0 stale sites" (changed).
  - copies=k>1, sync: "k copies of one fact. While they agree all is well — but k−1 sites must change together."
  - copies=k>1, changed: "The fact changed in 1 place. k−1 copies now disagree — each a stale site to hunt down."
  - element ids: `#dryState` (button group), `#dryCopies`/`#dryCopiesVal` (slider), `#dryBlocks` (svg group),
    `#dryOut` (aria-live readout).
- **Content figure — the reconciliation bill (the CONSEQUENCE).** One `.fold-ctrl` slider `r` = times the same
  knowledge was regenerated into separate sites (1…10). Pure functions: `edits(r) = r` (a change touches every
  site) and `consistency(r) = round(100 · 0.9^(r−1))` (each extra copy is one more chance to miss one; the 0.9
  is stated in the readout as the assumption). A confidence meter bar fills to `consistency(r)%`; `r` bars draw,
  one gold "source" and r−1 burgundy "duplicate". Readout: "Regenerated into r sites: a change touches r places;
  confidence they stay consistent ≈ X%. Generation made the copies free to create — reconciliation is the bill,
  and you pay it, not the agent." element ids: `#dryReg`/`#dryRegVal` (slider), `#dryMeter` (meter rect),
  `#dryCost` (aria-live readout).

## Bridge / recap / references

- **bridge:** principle — every fact has one authoritative representation → Portal — the id format lives in
  `Portal.ID`; every surface calls it, none re-derives it.
- **take:** duplication is no longer a typing cost the agent saves you; it is a drift surface the agent creates
  for free and you reconcile by hand. One authority is the only price that does not grow.
- **sources (real):** Hunt & Thomas, *The Pragmatic Programmer* ("DRY — The Evils of Duplication", the single
  source of truth); Parnas, *On the Criteria To Be Used in Decomposing Systems into Modules* (one place for one
  decision).
- **related:** A1.02.2 contracts, A1.02.3 orthogonality, the A1.02 hub, A1.01.1 vibe-coding (compounding
  entropy), A1.

## Wiring

- route-tag `/course/agile-agent-workflow/why/pragmatic/dry`; crumbs jonnify / AAW / A1 (`/why`) /
  A1.02 (`/why/pragmatic`) / here. Pager: prev → A1.02 hub (`/why/pragmatic`); next → A1.02.2 contracts
  (`/why/pragmatic/contracts`).
- `.hero-split`: hero text beside the hero interactive. Copy head/header/footer/scripts from thin-slices.html.
