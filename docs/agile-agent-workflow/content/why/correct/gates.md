# A1.05.3 · Gates — the mechanical checks that hold the closure and make "A+" repeatable

- **Route:** `/course/agile-agent-workflow/why/correct/gates`
- **File:** `html/agile-agent-workflow/why/correct/gates.html`
- **Chapter / module:** A1 · Why → A1.05 · Correct by definition · dive 3
- **Accent:** elixir-purple.

## Lead

A closure is only as trustworthy as the thing that re-runs it. If "every check passed" depends on a person
remembering to run every check, then "done" is back to being an opinion — held more carefully, but still an
opinion. A **quality gate** removes the person from the verdict: it runs the checks mechanically and returns
pass/fail, the same way, every time. The closure of A1.05.1 names *what* must be green; the gate is *how* you know
it is, on demand, without judgement.

That is what turns "A+" from praise into a repeatable result. "A+" is not a grade somebody awards; it is the state
of a page or a rung when every gate passes. Run the gate again tomorrow and the verdict is the same — because the
gate, not the mood of a reviewer, decides.

## Precise definition

- **Quality gate** — a mechanical check over an artifact that runs without human judgement and returns pass/fail.
  A suite of gates passes only when every gate passes; one failing gate fails the whole suite.
- **Holds the closure** — the gate re-runs the closure's checks on demand, so "every check is green" is verifiable
  at any moment, not a remembered claim.
- **Repeatable "A+"** — the same inputs through the same gates yield the same verdict every time; the grade is the
  output of a check, not the opinion of a grader.
- **Boundary (mention, do not re-teach):** the gates check *what is testable mechanically*. Taste, scope, and
  judgement stay with the Operator — the gate proves a route resolves, never that it is the right route (the
  course's own caveat). Reliability beyond the gate is A6.

## Worked example — two real gate suites

This is practised, not hypothetical, in two places the course already uses:

- **The course itself** runs the `cms` ten gates over every page: `containers`, `svg`, `no-future`, `voice`,
  `storage`, `motion`, `degrade`, `links`, `pager`, `refs`. A page ships only at STATUS: PASS — all ten green. The
  grade "A+" is exactly "ten gates pass." (This page passed that suite before it shipped.)
- **The Portal** runs its acceptance harness / CI over each rung. The "enrol" closure — including "enrol twice →
  no duplicate" — is re-run mechanically; the rung is accepted when the harness is green, not when someone says so.
  (The Portal's OTP internals are taught by the companion `/elixir` course; cite, do not re-teach.)

Both make the same move: the definition of done is a set of checks (A1.05.1), the checks are executed not asserted
(A1.05.2), and a gate re-runs them mechanically so the verdict is repeatable.

## Interactive 1 (hero figure) — the gate panel

A panel of the ten `cms` gates for a page. Toggle individual gates pass/fail; the panel computes the suite verdict.
STATUS: PASS lights only when all ten pass; any single failing gate flips the whole panel to FAIL and names the
first failing gate. Teaches "the suite passes only when every gate passes" — the closure rule applied to gates.

- Fixed dataset: the ten gate names in order.
- Pure function: `suiteVerdict(states) -> {passed, total, status, firstFail}` with `status = 'PASS' when passed ===
  total else 'FAIL'`.
- Readout (all pass): `10/10 gates pass · STATUS: PASS — A+ (repeatable: re-run for the same verdict)`
- Readout (voice fails): `9/10 gates pass · STATUS: FAIL — first failing gate: voice`

## Interactive 2 (main content) — opinion vs gate (repeatability)

A small experiment in repeatability. A "reviewer mood" slider (harsh ↔ generous) and a "run the gate" button over
a fixed artifact whose true gate result is fixed (say, 10/10 pass). The readout shows that the *opinion* verdict
swings with the mood while the *gate* verdict is constant across runs — same inputs, same output. The point: a gate
makes "A+" repeatable; an opinion does not.

- Fixed dataset: the artifact's true gate result (10/10 pass) is constant.
- Pure functions: `opinionGrade(mood) -> letter` (varies with mood); `gateGrade(artifact) -> 'A+'` (constant).
- Readout (mood harsh): `opinion: B− (mood-dependent) · gate: A+ (10/10, constant) — only the gate repeats`
- Readout (mood generous): `opinion: A (mood-dependent) · gate: A+ (10/10, constant) — only the gate repeats`

## Principle ↔ practice bridge

- **Principle:** a mechanical quality gate re-runs the closure's checks without judgement and returns pass/fail, so
  the suite passes only when every check is green and "A+" is a repeatable output, not an opinion.
- **On the Portal:** the acceptance harness / CI re-runs each rung's closure — "enrol twice → no duplicate"
  included — and accepts the rung only when green; the course itself runs the `cms` ten gates over every page.
- **Take:** gates hold the closure: they re-run every check mechanically, so "A+" is the repeatable output of a
  passing suite rather than an opinion laid on top.

## Forward / back (mention, do not re-teach)

- Back: A1.01 (provable completion of a thin slice) and A0.2.2 (the four artifacts) — the gate is how that
  provability is enforced.
- Forward: A4 (the spec layer the checks derive from) and A6 (reliability beyond the gate).

## References — Sources (real, vetted)

- Continuous Delivery → https://continuousdelivery.com/ — the deployment pipeline as a chain of automated gates; a
  candidate advances only when every stage is green.
- Extreme Programming Explained → https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/ —
  continuous integration and automated acceptance tests as the mechanical verdict.
- Specification by Example → https://gojko.net/books/specification-by-example/ — living documentation: the
  executable spec is re-run, so it cannot drift from the system.

## Related in this course

- `/course/agile-agent-workflow/why/correct` — the A1.05 hub.
- `/course/agile-agent-workflow/why/correct/proven-not-asserted` — the previous dive (proven vs asserted).
- `/course/agile-agent-workflow/why/failure-modes` — A1.01, provable completion of a thin slice.
- `/course/agile-agent-workflow/what/four-artifacts` — A0.2.2, the four artifacts the gates check.
- `/course/agile-agent-workflow/decomposition/acceptance` — A2.04, the checks a gate re-runs.
- `/course/agile-agent-workflow/why` — the chapter.

## Pager

- prev → `/course/agile-agent-workflow/why/correct/proven-not-asserted`
- next → `/course/agile-agent-workflow/why/correct` (back to the hub)
