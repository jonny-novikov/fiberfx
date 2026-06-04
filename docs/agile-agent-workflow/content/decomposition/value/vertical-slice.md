# A2.01.3 · The vertical slice

- **Route:** `/course/agile-agent-workflow/decomposition/value/vertical-slice`
- **File:** `html/agile-agent-workflow/decomposition/value/vertical-slice.html`
- **Model copied from:** `html/agile-agent-workflow/why/two-layers/spec.html`
- **Accent:** gold
- **Position:** A2.01 · Value, not tasks · dive 3

## Lead

Value cuts *through* the layers. A story is a thin vertical thread — store, domain, surface —
that a role can use end to end. Its opposite is a horizontal slice: one whole layer, finished in
isolation, that no role can demo. Vertical slices are how value, not effort, becomes the unit of
work.

## Definition

- **layers** — the Portal stacks a store (data + ids), a domain core (the framework-free rules),
  and a surface (the web app, the bot, the dashboard).
- **horizontal slice** — one layer across the whole system: "all the tables," "the whole domain,"
  "the entire web layer." Each is large, each is real work, and none is demoable on its own —
  there is no end-to-end thread a role can pull.
- **vertical slice** — one thin thread through every layer for a single story: enough store, enough
  domain, enough surface to let a role do one new thing. Demoable, because it is end to end.

A vertical slice is the tracer-bullet shape: thin but complete, top to bottom, proving the path
before it is widened.

## Worked Portal example

"A learner browses the catalogue of courses" is a vertical slice. It touches the store (a few
courses to list), the domain (the rule that only published courses appear), and the surface (the
page that renders them) — a thread thin enough for one rung, complete enough to demo. The
horizontal alternative — build every table, then the whole domain, then the whole UI — finishes
three big chores and demos nothing until the last one lands. The vertical slice demos on day one
and widens story by story:

```
vertical:  store ─ domain ─ surface   (one thread, one story: "browse the catalogue")  → demoable
horizontal: store ───────────────────  (every table, no thread)                         → not demoable
            domain ──────────────────  (whole core, no thread)                          → not demoable
            surface ─────────────────  (whole UI, no thread)                            → not demoable
```

## Hero interactive — vertical thread vs. horizontal layer

**Toggle a Portal increment between a vertical slice and a horizontal layer and read whether it
demos.** Fixed dataset: a 3×3 grid of cells (layers × stories). A two-state toggle (`vertical` /
`horizontal`) selects which cells are lit; the readout reports how many layers the lit set spans
for one story, and whether a role-usable thread exists. Pure: `select(grid, mode)` →
`[…cells]`; `spans(cells)` → `{layers, threadComplete:boolean}`. Sample readout (vertical): "Vertical
slice: store + domain + surface for 'browse the catalogue.' Spans 3 of 3 layers for one story → a
complete thread, demoable." (horizontal): "Horizontal layer: the store across all stories. Spans 1
of 3 layers, no story end to end → no thread, nothing to demo."

## Content interactive — widen story by story

**Add Portal stories one at a time and watch the demoable surface grow vertically.** Fixed
dataset: the four learner stories in dependency order, each a vertical thread. Buttons add the next
story (1…4); the readout reports how many complete threads exist and what a learner can now do.
Pure: `threadsUpTo(level)` → `[…stories]`; `capability(threads)` → string. Sample readout (level 2):
"Two vertical slices in: browse, then enrol. A learner can find a course and join it. Two complete
threads, both demoed — value accruing one thread at a time, not one layer at a time." This teaches a
*different* move from the hero: the hero contrasts one slice's shape; this one shows the system
growing by stacking thin threads.

## Bridge (principle → Portal practice)

Principle: value is a thin vertical thread through the layers, not a finished horizontal layer; a
slice that no role can pull end to end is a chore. → Portal: "browse the catalogue" is one thread
through store, domain, and surface — demoable now; "build all the tables" is a horizontal layer
that demos nothing until the threads cross it.

## Recap

Value cuts down through the layers, not across one of them. A story is a thin vertical thread a
role can use end to end and therefore demo; a horizontal layer is real work with no thread and no
demo. The system grows by stacking thin vertical slices, value accruing one thread at a time. This
closes A2.01: a unit of work is a unit of demonstrable value — named for a role, ordered by value,
cut vertically.

## References — Sources (real, vetted)

- The Pragmatic Programmer → pragprog.com — tracer bullets: a thin, complete, end-to-end thread first.
- User Stories Applied → mountaingoatsoftware.com — slicing stories so each delivers value end to end.
- Specification by Example → gojko.net — a vertical slice is specified and accepted by concrete example.

Related: A2.01 hub; A2.01.2 who-benefits; A1.04.2 spec layer; A2 landing; `/elixir/course`.

## Pager

- prev = A2.01.2 `/course/agile-agent-workflow/decomposition/value/who-benefits`
- next = A2.01 hub `/course/agile-agent-workflow/decomposition/value` (back to the hub; A2.02
  connextra is the parallel sibling, linked only as a forward pointer)
