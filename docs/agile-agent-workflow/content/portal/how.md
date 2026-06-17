# A7 · orientation dive 3 — how the loop runs here

- **Route:** `/course/agile-agent-workflow/portal/how` (`portal/how.html`)
- **Eyebrow:** `A7 · orientation dive 3`
- **Crumbs:** `jonnify / Agile Agent Workflow / A7 · Portal exemplar / How it runs`.
- **Accent:** gold on interactive accents; `h1 .ex` stays elixir-purple.
- **Pager:** prev `= /course/agile-agent-workflow/portal/what`, next `= /course/agile-agent-workflow` (the course
  home — A7 is the last chapter, so the loop closes back to the home, which resolves).

## Reverse-verification echo (open with this)

A6 makes each rung production-grade. A7's run is worth running only because each rung it ships was hardened first;
this dive shows how the loop runs once, uninterrupted, on the Portal — the Operator decomposes, roadmaps, specs,
briefs, and accepts; the Author builds and hardens; each rung is shipped to production quality before the next.

## Lead

A7 runs the Author/Operator loop once on the Portal, end to end. The roles do not change: the Operator owns
decomposition, judgement, and acceptance; the Author is the fast, well-specified implementer. The loop ships one
production-grade rung at a time, in dependency order, until the multi-surface Portal is deployed.

## The Portal's five surfaces (the only canonical set — invent no others)

- a branded store
- an event-sourced engine behind one facade
- a Phoenix web app
- a Telegram bot
- a student dashboard

They come up in dependency order; the companion `/elixir` course builds them for real (cited, never re-taught).
The only free Portal API is `Portal.ID.generate/1` and `Portal.ID.decode/1` (`.type`, `.timestamp`).

## Interactive 1 (hero figure) — the rung-by-rung ledger

- **Element ids:** `ledSel` (`.solid-select`, gold; a prev/next pair plus a position label, OR seven buttons for
  the seven steps), `ledOut` (`.geo-readout`), SVG ledger rows `ld-0`…`ld-6`, a "shipped" counter cell `ld-count`,
  a gate cell `ld-gate`.
- **Fixed dataset:** the seven steps A7.01–A7.07 as ledger rows `{id, phase, role}` where `role` is who owns the
  step (Operator / Author / both). Advancing the ledger reveals each rung shipped with its production-quality gate
  held.
- **Pure fns:** `shippedThrough(i)` → the number of rungs shipped through step index `i` (i + 1); `gateHeld(i)` →
  always `true` (each rung ships only at STATUS: PASS / production quality); `readoutFor(i)`.
- **Sample readout (advance to A7.06):** `Through A7.06 · Harden to production — 6 of 7 rungs shipped; the
  production-quality gate held at each. The loop ships one production-grade rung at a time, end to end.`
- **Take:** the ledger advances one rung at a time; the gate holds at every rung, so nothing un-hardened ships.

## Interactive 2 (main content) — who owns each step (Operator / Author)

- **Element ids:** `ownSel` (`.solid-select`, gold; seven buttons A7.01…A7.07), `ownOut` (`.geo-readout`), SVG
  lane cells `ow-op` (Operator lane), `ow-au` (Author lane), step marker `ow-mark`.
- **Fixed dataset:** the seven steps `{id, phase, owner}` — A7.01 Operator (decompose), A7.02 Operator (roadmap),
  A7.03 Operator (spec), A7.04 Operator (brief), A7.05 Author (build), A7.06 Author (harden), A7.07 Operator
  (accept & ship).
- **Pure fns:** `ownerAt(i)` → "Operator" | "Author"; `operatorSteps()` → count of Operator-owned steps;
  `readoutFor(i)`.
- **Sample readout (A7.05):** `A7.05 · Build the increment — owned by the Author. The Author is the fast,
  well-specified implementer; the Operator owns decomposition, judgement, and acceptance. 5 of 7 steps the Operator
  owns; the Author owns the build and the hardening.`
- **Take:** the human owns decomposition, judgement, and acceptance; the agent owns the build — the thesis holds
  across the whole run.

## Bridge

- **Principle:** run the whole loop once, uninterrupted, shipping a production-grade rung before the next — the
  Operator owns judgement and acceptance, the Author owns implementation.
- **Portal practice:** the Portal's five surfaces come up in dependency order; the Operator decomposes/roadmaps/
  specs/briefs/accepts, the Author builds and hardens; the increment's boundary parses untrusted input into a typed
  value (`Portal.ID.generate/1` / `decode/1`), and a supervisor isolates a crash.
- **Take:** the loop ships one production-grade rung at a time, end to end, with the roles unchanged.

## References

**Sources:**
- Continuous Delivery — `https://continuousdelivery.com/` — releasable at every increment; production quality held
  at each rung.
- The Pragmatic Programmer — `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`
  — tracer bullets: the system runs end to end, then the backlog fills in.
- Extreme Programming Explained — `https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/`
  — the inspect-and-adapt loop, one rung at a time.

**Related in this course:** `/portal`, `/portal/why`, `/roadmap`, `/spec`, `/decomposition`, `/elixir/phoenix`,
`/elixir/course`. (next pager points at `/course/agile-agent-workflow`, the course home — the loop closes.)
