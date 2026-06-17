# A7 · orientation dive 1 — why an end-to-end exemplar

- **Route:** `/course/agile-agent-workflow/portal/why` (`portal/why.html`)
- **Eyebrow:** `A7 · orientation dive 1`
- **Crumbs:** `jonnify / Agile Agent Workflow / A7 · Portal exemplar / Why an exemplar` (four-element dive form;
  the `A7 · Portal exemplar` segment links `/portal`).
- **Accent:** gold on interactive accents; `h1 .ex` stays elixir-purple.
- **Pager:** prev `= /course/agile-agent-workflow/portal` (landing), next `= /course/agile-agent-workflow/portal/what`.

## Reverse-verification echo (open with this)

A6 makes each rung production-grade. A7 exists because the method is proven only when the whole loop runs end to end
on a real system — a sequence of hardened rungs is not the same as a demonstrated, composed run. The failure A7
prevents: techniques taught in isolation that never compose into a shipped system.

## Lead

A7 is the single uninterrupted run of the whole loop on the Portal — zero to production. The prior Parts each proved
one move on a worked fragment; A7 proves the moves compose. A method is demonstrated by one whole run, not by seven
separate lessons.

## Interactive 1 (hero figure) — isolated-moves-vs-composed-run

- **Element ids:** `mvSel` (`.solid-select`, gold; two buttons: "taught in isolation" / "run as one loop"),
  `mvOut` (`.geo-readout`), SVG node `mv-ship` (the ship/no-ship verdict cell), step row nodes `mv-0`…`mv-6`.
- **Fixed dataset:** the seven Parts A1–A7 as moves `{id, move}`. Each is a real technique taught by a built chapter.
- **Pure fns:** `composes(mode)` → boolean: `false` in `"isolation"` mode, `true` in `"loop"` mode; `ships(mode)` →
  whether a shipped system results (true only when the moves run as one loop); `readoutFor(mode)` → readout string.
- **Sample readout ("loop"):** `Run as one loop — the 7 moves compose into one uninterrupted run; the system ships
  to production. A method is proven by one whole run, not seven separate lessons.`
- **Sample readout ("isolation"):** `Taught in isolation — 7 separate lessons, each proven on its own fragment; no
  composed run, so no shipped system. The moves are correct but never assembled.`
- **Take:** seven correct lessons do not add up to a shipped system; one composed run does.

## Interactive 2 (main content) — the seam from A6 to A7

- **Element ids:** `seamSel` (`.solid-select`, gold; selects one of three: "hardened rungs", "a composed run",
  "a shipped system"), `seamOut` (`.geo-readout`), SVG cells `sm-have`, `sm-gap`, `sm-need`.
- **Fixed dataset:** three states `{id, label, has}` where `has` is what each delivers — A6 delivers hardened rungs;
  A7's composed run is the missing step; the shipped system is the output.
- **Pure fns:** `stateAt(i)`; `gapClosed(i)` → whether selecting this state closes the A6→A7 seam; `readoutFor(i)`.
- **Sample readout (composed run):** `A composed run — the step A6 leaves open. Hardened rungs exist; a run that
  assembles them into a shipped system does not, until A7 runs the loop end to end.`
- **Take:** A6 hardens each rung; A7 assembles the hardened rungs into one shipped run — that assembly is the gap.

## Bridge

- **Principle:** a sequence of correct techniques is not a demonstrated method; the method is the whole loop run once.
- **Portal practice:** A7 runs decompose → roadmap → spec → brief → build → harden → accept once on the Portal,
  shipping the multi-surface platform from an empty repository to production.
- **Take:** the exemplar closes the chain by running the loop end to end, not by adding another technique.

## References

**Sources:**
- Extreme Programming Explained — `https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/`
  — the inspect-and-adapt loop run whole, not as separate ceremonies.
- The Pragmatic Programmer — `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`
  — the walking skeleton: an end-to-end system before the rest of the backlog lands.
- Continuous Delivery — `https://continuousdelivery.com/` — releasable at every increment; the production bar the
  composed run holds.

**Related in this course:** `/portal`, `/roadmap`, `/decomposition`, `/spec`, `/elixir/phoenix`, `/elixir/course`.
(`/reliability` named in prose only — unbuilt this batch.)
