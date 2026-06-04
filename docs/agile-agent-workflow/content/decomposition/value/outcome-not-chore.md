# A2.01.1 · Outcome, not chore

- **Route:** `/course/agile-agent-workflow/decomposition/value/outcome-not-chore`
- **File:** `html/agile-agent-workflow/decomposition/value/outcome-not-chore.html`
- **Model copied from:** `html/agile-agent-workflow/why/two-layers/spec.html`
- **Accent:** gold
- **Position:** A2.01 · Value, not tasks · dive 1

## Lead

A task names work to do. A story names a change in what someone can do once the work lands.
The difference is not wording — it is whether anything a role can use changed. The test that
separates them is **demonstrability**: a story can be demoed; a chore cannot.

## Definition

- **task / chore** — a unit of work to do. "Add the courses table." "Wire the LiveView socket."
  Real work, often necessary, but it changes nothing a role can observe on its own.
- **story** — a unit of value. "A learner browses the catalogue of courses." Once it lands, a
  role can do something it could not do before, and that change is observable.
- **the demonstrability test** — can you sit a role in front of the result and show the change?
  If yes, it is a story. If the only thing you can point at is a schema or a wired socket, it is
  a chore.

A chore can be *true* and *done* and still demo nothing, because demonstrability asks about an
observable change for a role, not about effort spent.

## Worked Portal example

Take the Portal rung "a learner browses the catalogue of courses." Underneath it sit chores:
add the courses table, seed it, wire the catalogue read. None of those, alone, is demonstrable —
a seeded table is not something a learner can use. The story is demonstrable: open the catalogue,
and every published course is listed. The acceptance check is its demo, written down:

```
Given a non-empty catalogue,
when a learner opens it,
then every published course is listed.
```

The chores are how the story is built; the story is what gets demoed and accepted.

## Hero interactive — the demonstrability test

**Sort eight Portal work items by whether they can be demoed.** A fixed dataset: four stories
(browse, enrol, open a lesson, track progress) and four chores (the courses table, the LiveView
socket, the `Portal.ID` module, a config refactor). Buttons pick a lens: `all`, `demoable`,
`not demoable`. The readout reports, over the fixed set, the count in the lens and restates the
rule. Pure: `partition(items)` → `{demoable:[…], chores:[…]}`; `tallyLens(items, lens)` →
`{count, total}`. Sample readout: "Lens: can be demoed · 4 of 8 items. Each names a change a role
can use — so each has a demo. The other 4 are chores: real work, nothing to show a role."

## Content interactive — rewrite a chore as the outcome it serves

**Toggle one item between its chore phrasing and its story phrasing.** A fixed pair set: each
chore ("add the courses table") maps to the story it serves ("a learner browses the catalogue").
A two-state toggle (`chore` / `story`) re-renders the card and the readout. Pure:
`render(pair, mode)` → `{title, demoable:boolean, line}`. Sample readout (story mode): "As a story:
'a learner browses the catalogue of courses.' Demoable: yes — open the catalogue, courses are
listed. The table is how it is built, not what is delivered." This teaches a *different* move from
the hero: the hero classifies; this one re-frames a chore upward into the value it serves.

## Bridge (principle → Portal practice)

Principle: a backlog item earns its place by being demonstrable — a change a role can use, not
work done. → Portal: "browse the catalogue" is the unit on the backlog; "add the courses table"
is a step inside building it, never a backlog item of its own.

## Recap

A task is work to do; a story is a change in what a role can do. Demonstrability is the line
between them: a story can be demoed, a chore cannot. Name the outcome, and the chores fall into
place beneath it as the means.

## References — Sources (real, vetted)

- User Stories Applied → mountaingoatsoftware.com — a story is a unit of value, not of work.
- Extreme Programming Explained → oreilly.com — the increment is demonstrated to the customer.
- The Pragmatic Programmer → pragprog.com — tracer bullets: build a thin, observable thread first.

Related: A2.01 hub; A2.01.2 who-benefits; A1.04.2 spec layer (`/why/two-layers/spec`);
A2 landing (`/decomposition`); `/elixir/course`.

## Pager

- prev = A2.01 hub `/course/agile-agent-workflow/decomposition/value`
- next = A2.01.2 `/course/agile-agent-workflow/decomposition/value/who-benefits`
