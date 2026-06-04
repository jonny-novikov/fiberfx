# A1.03.3 — Adapt: feedback edits the spec

- **Route:** `/course/agile-agent-workflow/why/loop/adapt`
- **File:** `html/agile-agent-workflow/why/loop/adapt.html`
- **Place in the module:** the third dive and the module's resolution — *how it adapts*. The return arc that makes
  the loop a loop, and why feedback edits the spec rather than the code.
- **Accent word (`.ex`):** "spec".

## Lead

The dashed return in the loop has a name: adapt. It carries one rule that holds the whole workflow together —
feedback edits the **spec**, not the code. The spec is the single source of truth (A1.02.1); route a change
through it and the next rung is rebuilt correctly, route it around the spec and the spec and code fork.

## Definition

- **adapt** — the return from feedback to the next sharpen: the team responds to what it learned by editing the
  spec, then the loop runs again on the next rung.
- **the rule** — feedback edits the spec, never the code directly. The Author rebuilds from the edited spec; the
  spec stays the one authoritative representation both roles meet on.
- the agent-era reason: an agent will happily hot-patch the code where the feedback landed. Do that and the spec
  no longer describes the code — the exact DRY drift of A1.02.1, now between the spec and the system it specifies.

## Why it compounds

Because every change enters through the spec, the spec and the code never fork: drift stays at zero by
construction. And because each turn is accepted before the next begins, confidence accumulates rung over rung —
the mirror of vibe coding's compounding entropy. The loop's product is two things kept in lock-step: a growing set
of accepted rungs and a spec refined by every round of feedback.

## Worked Portal example

Feedback on the Portal — "ids should also sort by time" — edits the spec of `Portal.ID` (its contract), in one
place. The Author regenerates `generate/1` from the edited spec; every surface that calls `Portal.ID` derives the
new behaviour, because the format lives once (A1.02.1). The wrong move is to hot-patch the sort into the store, the
bot, and the dashboard — three edits, a forked truth, and the spec now lying about the code. Use only the
established API; do not invent.

## The two interactives (different teaching moves)

- **Hero figure — where does feedback go? (the IDEA).** A `.solid-select` `#adWhere`: "edit the spec"
  (data-k="spec", data-c="sage", active) / "patch the code" (data-k="code", data-c="burg"). The SVG shows a `spec`
  node and three `code` surface nodes (store / bot / dashboard). In "edit the spec": the spec node lights, an arrow
  flows spec → all three surfaces (regenerated), drift indicator `#adDrift` reads 0. In "patch the code": the three
  surfaces are edited directly and diverge from the spec, drift indicator reads 3 (spec disagrees with code).
  Pure: `drift(where) = where === 'code' ? 3 : 0`. Readout `#adOut` states which path keeps the single source of
  truth. Initial static state = "edit the spec" (drift 0). element ids: `#adWhere`, `#n-spec`, surfaces
  `#c-store/-bot/-dash`, `#adDrift`, `#adOut`.
- **Content figure — the loop ledger (the CONSEQUENCE).** A `.fold-ctrl` slider `#adCycles` = turns completed
  (1…8). Pure functions: `rungs(c) = c`, `specEdits(c) = c`, `drift = 0` (always, because feedback routes through
  the spec). Two rising stacks draw locked together — accepted rungs and spec versions — and a drift readout pinned
  at 0. Readout `#adLedger`: "After c turns: c accepted rungs, the spec edited c times, code-vs-spec drift 0 —
  because every change entered through the spec. Confidence compounds; the truth never forks." element ids:
  `#adCycles`/`#adCyclesVal`, rung stack `#lr-*`, spec stack `#ls-*`, `#adLedger`.

## Bridge / recap / references

- **bridge:** principle — adapt by editing the single source of truth, not its copies → Portal — feedback edits
  the `Portal.ID` contract once; the Author regenerates; every surface derives the change.
- **recap (synthesis of the module):** two roles meet on a spec; one turn carries a rung through six owned stages;
  adapt sends feedback back through the spec. The loop is the workflow's motion — repeatable, accountable, and
  compounding, because the spec it turns on never forks from the code.
- **take:** feedback edits the spec, not the code — the one rule that keeps the loop's truth single and lets the
  whole thing compound.
- **sources (real):** Hunt & Thomas, *The Pragmatic Programmer* (DRY; the single source of truth; feedback);
  Beck, *Extreme Programming Explained* (embrace change; the feedback loop); Schwaber & Sutherland, *The Scrum
  Guide* (the retrospective: inspect and adapt).
- **related:** A1.03.1 roles, A1.03.2 turn, the A1.03 hub, A1.02.1 dry (single source of truth), A1.01.3
  thin-slices (compounding correctness), A1.

## Wiring

- route-tag `/course/agile-agent-workflow/why/loop/adapt`; crumbs jonnify / AAW / A1 (`/why`) / A1.03 (`/why/loop`)
  / here. Pager: prev → A1.03.2 turn (`/why/loop/turn`); next → A1.03 hub (`/why/loop`, "module overview"). A
  closing recap closes the module.
- `.hero-split`: hero text beside the feedback-routing interactive. Copy head/header/footer/scripts from
  `html/agile-agent-workflow/why/loop/roles.html` (same module — exact design-system parity).
