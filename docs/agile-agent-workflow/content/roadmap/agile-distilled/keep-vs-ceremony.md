# A3.1.3 · Keep vs ceremony — dive (md source of record)

- **Route:** `/course/agile-agent-workflow/roadmap/agile-distilled/keep-vs-ceremony`
- **Pager:** prev `…/agile-distilled/inspect-and-adapt` · next `…/agile-distilled` (back to hub).

## Lead

Most Agile process exists to coordinate a team of people. A one-agent / one-reviewer pair is not a team, so a lot of
that process is ceremony here — not wrong, just answering a problem the pair does not have. This dive sorts the common
practices into keep, adapt, or drop, and shows that the kept ones each name a loop move while the dropped ones name
none.

## Definition

A practice is **kept** if it drives a move in the Author/Operator loop; **adapted** if its intent survives but its team
form is replaced by a one-pair form; **dropped** if it coordinates people the pair does not have. The test is a single
question: does it add a move the loop needs, or only process around it?

## Hero interactive — classify a practice: keep / adapt / drop

- **Intent:** frame the sort.
- **Control ids:** `keSel` (`.solid-select`, `data-k` = practice); SVG verdict lane nodes `ke-node-<k>`.
- **Readout id:** `keOut`.
- **Fixed dataset `PRACTICES`:** `{k, label, verdict: "keep"|"adapt"|"drop", form}`.
  - `short-iterations` — short iterations — keep — one thin rung per turn is the loop.
  - `acceptance-criteria` — acceptance criteria — keep — Given/When/Then is the rung's definition of done.
  - `continuous-feedback` — continuous feedback — keep — the `feedback → adapt` return runs every rung.
  - `retrospective` — retrospective — adapt — the per-rung review note replaces the team retro meeting.
  - `pair-programming` — pair programming — adapt — the Author/Operator pair is the pairing, across roles not seats.
  - `daily-standup` — daily standup — drop — a team sync the two-role pair does not need.
  - `velocity-tracking` — velocity tracking — drop — throughput metrics for staffing a multi-person team.
  - `planning-poker` — planning poker — drop — consensus estimation with no second estimator.
- **Pure functions:** `verdictOf(k)`, `tally() -> {keep, adapt, drop}`, `readoutFor(k)`.
- **Sample readout:** `daily standup — drop. It coordinates a team the one-agent / one-reviewer pair does not have;
  the loop's review is the standing checkpoint. Tally: 3 keep · 2 adapt · 3 drop.`

## Main interactive — kept practices drive moves; dropped ones drive none

- **Intent:** prove the consequence — as you include only kept practices, every selected practice maps to a loop move;
  including dropped ones adds count but no move.
- **Control ids:** `cvSet` (checkboxes / toggles per practice, ids `cv-<k>`); a `.geo-readout` `cvOut`.
- **Readout id:** `cvOut`.
- **Pure functions over the same `PRACTICES` set:**
  - `movesCovered(selected) -> Set` (union of loop moves the selected kept/adapted practices drive).
  - `deadCount(selected) -> int` (selected practices whose verdict is drop — they add no move).
  - `readout(selected) -> string`.
- **Sample readout:** `Selected 4 practices · 3 drive a loop move (sharpen, ship, adapt covered) · 1 is dropped
  ceremony that adds no move. Trim the dropped one and nothing the loop needs is lost.`

## Bridge

- **idea:** Keep the practices that drive a loop move; adapt the ones whose intent survives; drop the ceremony.
- **Portal:** F6 keeps short rungs, acceptance criteria, and continuous feedback; adapts the retro into a per-rung
  feedback note and pairing into the Author/Operator split; drops standups, velocity, and poker — and ships nine rungs
  without them.
- **take:** A practice earns its place by naming a move in the loop; the rest is ceremony the pair can drop.

## Sources

- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- Continuous Delivery — https://continuousdelivery.com/
