# A0.2.1 deep dive — Anatomy of a roadmap.md

- **Route:** `/course/agile-agent-workflow/what/two-layer-model-roadmap-anatomy`
- **File:** `html/agile-agent-workflow/what/two-layer-model-roadmap-anatomy.html`
- **Place in the module:** a deep dive off A0.2.1 "The two-layer model" (label on the page: "A0.2.1 deep dive").
  It dissects the delivery layer — the roadmap.md — into its three parts.
- **Accent word (`.ex`):** "roadmap.md".

## Lead

The roadmap is the delivery layer in one plain file. It answers *what ships, and in what order* — never how a thing
behaves. Three parts carry it: **milestones** that name shippable outcomes, the **rungs** that climb to each one,
and a **definition of done** every rung must meet. Select a part to see what it holds.

(Lede verbatim from the hero `.lede`.)

## Definition

The parts of a roadmap (from the `.deflist` in the "The parts of a roadmap" section, verbatim):

- **Milestone** — A shippable outcome a person would notice. Groups the rungs that, together, deliver one increment
  of value.
- **Rung** — One thin, provable step toward a milestone. Valuable on its own, ordered in the climb, and pointed at
  the spec that defines it.
- **Definition of done** — Stated once, for every rung: stories pass, invariants hold, quality gates green. "Done"
  is a closure over checks, not a feeling.

Prose framing (from the `#parts` section): a roadmap.md is short on purpose. It holds three kinds of thing and
nothing else — milestones (shippable outcomes a person would notice, like "a learner finishes a lesson", not
internal tasks like "add a table"); the rungs that climb to a milestone, each a thin slice of value that points at
the spec defining it; and a definition of done that says, once, what finishing any rung means. **Behaviour lives in
the specs the rungs point at — never here.** Read top to bottom, the rungs are the build order; each is small enough
to ship on its own and ordered so the earliest ones already deliver something; the milestone is reached when its
rungs are all done.

## Why it matters

Read top to bottom, the rungs are the build order. Each is small enough to ship on its own and ordered so the
earliest ones already deliver something; the milestone is reached when its rungs are all done. The roadmap keeps
behaviour out — it answers only *what ships, and in what order*, deferring how a thing behaves to the specs the
rungs point at. ("Thin but robust" — see below — is the line a roadmap aims for when it sizes each rung.)

## Worked Portal example

A concrete skeleton roadmap.md (the `pre.code` block in `#parts`, verbatim):

```
# Portal — roadmap

## Milestone 1 · a learner finishes a lesson
goal: a person can enrol and complete one lesson, end to end

- [ ] R1.1  enrol a learner          → spec: enrolment.md
- [ ] R1.2  deliver the first lesson → spec: delivery.md
- [ ] R1.3  record completion        → spec: completion.md

## Definition of done (every rung)
stories pass · invariants hold · quality gates green
```

(The `goal:`, the `→ spec: …` pointers, and the `(every rung)` are styled as `.cmt` comments in the page.)

## The two interactives

### Hero figure — "A roadmap.md · select a part" (the PARTS)

- **Control:** `.solid-select` `#rmSel` (role="group", aria-label "A part of the roadmap"), three buttons:
  - `data-k="mile"` `data-c="gold"` → "milestones"
  - `data-k="rung"` `data-c="blue"` `class="active"` → "rungs" (initial active)
  - `data-k="done"` `data-c="sage"` → "done"
- **SVG region ids highlighted by the pick:** `#rmMile` (milestone block), `#rmRung` (rungs R1.1–R1.3 block),
  `#rmDone` (definition-of-done block).
- **Readout:** `.geo-readout` `#rmOut` (aria-live="polite").
- **Pure function:** `pickRm(k)` — for each key in `RM = { mile:'rmMile', rung:'rmRung', done:'rmDone' }`, sets the
  matching `<rect>`'s stroke/stroke-width/fill: when `key === k` it applies the on-colours from
  `RM_C` (`mile:{stroke:'#f0cd7f',fill:'#1a1407'}`, `rung:{stroke:'#9fc0ea',fill:'#15203a'}`,
  `done:{stroke:'#a7c9b1',fill:'#13201a'}`) with stroke-width `2.5`, otherwise the off state stroke `#2a3252`,
  stroke-width `1.5`, fill `#10162b`. Toggles `.active` + `aria-pressed` on the `#rmSel` buttons by `data-k`, and
  sets `#rmOut.innerHTML = RM_OUT[k]`. Initialised with `pickRm('rung')`.
- **Readout strings (`RM_OUT`, verbatim):**
  - `mile`: "A milestone is a shippable outcome, not a task — "a learner finishes a lesson", not "add a table". It
    groups the rungs that, together, deliver one increment of value."
  - `rung`: "Rungs are the thin, ordered steps that ship the milestone — each one valuable, each one provable, each
    pointing at the spec that defines it. The arc is the build order; start at the top." (also the static default in
    the markup)
  - `done`: "The definition of done is a closure over checks: a rung is finished only when its stories pass, its
    invariants hold, and the quality gates are green. "Done" is not a feeling."

### Content figure — "The cut · select one" (the CONSEQUENCE: thin but robust)

- **Control:** `.solid-select` `#slSel` (role="group", aria-label "A way to cut a rung"), three buttons:
  - `data-k="robust"` `data-c="sage"` `class="active"` → "thin & robust" (initial active)
  - `data-k="thin"` `data-c="blue"` → "too thin"
  - `data-k="fat"` `data-c="gold"` → "too fat"
- **SVG elements driven:** `#sliceRect` (the slice overlay; x/y/width/height/fill/stroke change) and `#sliceTag`
  (the label text + its x position + fill). The three fixed layer rows are surface · UI / API, logic · the engine,
  data · the store.
- **Readout:** `.geo-readout` `#slOut` (aria-live="polite").
- **Pure function:** `pickSl(k)` — looks up `SLICE[k]` and rewrites `#sliceRect`'s x/y/width/height/fill/stroke and
  `#sliceTag`'s text/x/fill; toggles `.active` + `aria-pressed` on `#slSel` buttons; sets
  `#slOut.innerHTML = SL_OUT[k]`. Initialised with `pickSl('robust')`.
- **`SLICE` dataset (verbatim):**
  - `robust`: `{ x:70, y:22, w:86, h:178, fill:'#7ba387', stroke:'#a7c9b1', tag:'one rung', tx:113 }`
  - `thin`: `{ x:70, y:22, w:86, h:50, fill:'#c4504c', stroke:'#e0938f', tag:'façade only', tx:113 }`
  - `fat`: `{ x:70, y:22, w:360, h:178, fill:'#d4a85a', stroke:'#f0cd7f', tag:'too much at once', tx:250 }`
- **Readout strings (`SL_OUT`, verbatim):**
  - `robust`: "Thin but robust: a narrow slice that still reaches every layer, so the rung works end to end. Small
    enough to prove, complete enough to ship — the size a roadmap aims for." (also the static default in the markup)
  - `thin`: "Too thin: the slice touches only the surface, so it demos but does nothing real. A rung that does not
    reach the data is not shippable value."
  - `fat`: "Too fat: the slice is wide across every layer — a big batch no one can review or prove in one pass. Split
    it into several thin-but-robust rungs."

The two interactives teach different moves: the hero names the *parts* of a roadmap; the content figure proves the
*consequence* — that a rung must be thin but robust (narrow yet reaching every layer).

## Bridge / recap / references

- **Take (`.take`, closing the "Thin but robust" section, verbatim):** "A roadmap is a ladder of thin-but-robust
  rungs. Size each so it proves something and ships something; the spec it points at says what "works" means."
- **Note on this page:** there is no `.bridge` block on this page (it is a deep dive, not a concept pairing).
- **Sources (real, from `#refs` › Sources, verbatim):**
  - `roadmap.md` — the delivery artifact this page dissects.
  - Hunt, A. & Thomas, D. — *The Pragmatic Programmer* — tracer bullets and walking skeletons.
  - Beck, K. — *Extreme Programming Explained* — small, shippable increments.
- **Related in this course (from `#refs` › Related, verbatim labels + hrefs):**
  - A0.2.1 · The two-layer model → `/course/agile-agent-workflow/what/two-layer-model`
  - A0.2.2 · The four artifacts → `/course/agile-agent-workflow/what/four-artifacts`
  - A0 · chapter overview → `/course/agile-agent-workflow/intro`

## Wiring

- **route-tag on page:** `/course/agile-agent-workflow/what/two-layer-model-roadmap-anatomy`
- **Crumbs (as found in the hero `.crumbs`):**
  - `<a href="/course/agile-agent-workflow/what/two-layer-model">` — "A0.2.1 · the two-layer model"
  - separator `/`
  - `<span class="here">` — "deep dive · roadmap anatomy" (current)
- **toc-mini:** `#parts` "The parts" · `#thin` "Thin but robust" · `#refs` "References"
- **Pager:**
  - prev (`.btn ghost`): "A0.2.1 · the two-layer model" → `/course/agile-agent-workflow/what/two-layer-model`
  - next (`.btn`): "A0 · chapter overview" → `/course/agile-agent-workflow/intro`
- **Footer links (chapters/course columns):** A0 → `/course/agile-agent-workflow/intro`, A1 → `/course/agile-agent-workflow/why`,
  Course home → `/course/agile-agent-workflow`, A0.2.1 Two-layer model → `/course/agile-agent-workflow/what/two-layer-model`,
  Companion → `/elixir/course`, jonnify home → `/elixir`. Brand link → `/elixir`.
- **Build stamp:** `#stampId` = `TSK0NgQDY05yPg`; static `#st-ts` = `2026-06-03 17:31:57 UTC`.

### Known anomaly (record as-is — do NOT fix)

The pager "next" link and the `#refs` › Related "A0 · chapter overview" link both point at
`/course/agile-agent-workflow/intro`, which is now a 404. The crumb parent (`/course/agile-agent-workflow/what/two-layer-model`)
also assumes A0.2.1 lives at `…/what/two-layer-model`. These are preserved exactly as found; no correction applied.
