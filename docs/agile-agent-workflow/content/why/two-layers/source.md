# A1.04.3 — The single source of truth

- **Route:** `/course/agile-agent-workflow/why/two-layers/source`
- **File:** `html/agile-agent-workflow/why/two-layers/source.html`
- **Place in the module:** the third dive and the module's resolution — the rule that keeps the two layers stable,
  the two cadences they run at, and what conflating them costs.
- **Accent word (`.ex`):** "truth".

## Lead

One rule makes the two layers stable: the spec is the single source of truth, and only feedback edits it. The
roadmap points at the spec; the user stories and the agent brief derive from it. Because everything downstream
depends on the spec, the two layers run at different cadences — and keeping them apart is the whole discipline.

## Definition (ground in A0.2.1 — do not redefine)

- **the rule** — the spec is the single source of truth; only feedback edits it. The roadmap *points at* the spec;
  the user stories and the agent brief *derive from* it; nothing edits the derived artifacts directly.
- **two cadences** — the roadmap changes often and cheaply (re-planning delivery); the spec changes rarely and only
  through feedback (because everything downstream depends on it). Different rates, different reasons.
- **conflation** — collapsing the two layers. Bake specs into the roadmap and the roadmap becomes a frozen up-front
  specification (the big-bang spec, A1.01.2). Bake delivery order into the specs and the rungs can no longer be
  re-planned — coupling (A1.02.3), now between plan and definition.

## Why it matters — separate so each can change on its own terms

Two layers, two cadences, kept apart: delivery can be re-planned without touching what any rung means, and a spec
can be sharpened without re-planning delivery. That independence is exactly orthogonality (A1.02.3) applied to the
plan itself. Collapse the layers and you lose it: a change to one drags the other, and the cheap moves — re-order
the roadmap, sharpen one spec — become expensive ones.

## Worked Portal example

On the Portal the roadmap is re-ordered weekly as the loop learns — promote the read model, split the dashboard
rung — and not one spec moves. Separately, feedback on the id rung ("also sort by time") edits the id spec once, and
the roadmap order is untouched. Two cadences, two reasons. The wrong move is to write the full id contract into the
roadmap (now re-ordering means rewriting specs — big-bang) or to encode "ship the id before the event" inside the id
spec (now the spec cannot be re-planned — coupling). Keep Portal references conceptual; do not invent module APIs.

## The two interactives (different teaching moves)

- **Hero figure — two cadences (the SHAPE).** A `.solid-select` `#srWhat`: "re-prioritise delivery" (data-k="road",
  data-c="blue", active) / "feedback on a rung" (data-k="spec", data-c="gold"). The SVG is a two-track timeline:
  the top **roadmap** track carries many change-marks (frequent, cheap); the bottom **spec** track carries few
  (rare, only feedback). Choosing "re-prioritise delivery" lights a new mark on the roadmap track only (no spec
  mark); choosing "feedback on a rung" lights a mark on the spec track. Pure: two fixed mark-sets. Readout `#srOut`
  states which track changed and why the cadences differ. element ids: `#srWhat`, roadmap marks `#tr-road-*`, spec
  marks `#tr-spec-*`, `#srOut`. Initial static state = "re-prioritise delivery".
- **Content figure — what conflation costs (the CONSEQUENCE).** A `.solid-select` `#srMix`: "layers separate"
  (data-k="ok", data-c="sage", active) / "specs in the roadmap" (data-k="bigbang", data-c="burg") / "order in the
  specs" (data-k="coupled", data-c="burg"). The SVG shows the two-layer stack; "separate" shows the clean stack;
  "specs in the roadmap" merges the spec up into the roadmap (marked big-bang); "order in the specs" pushes delivery
  order down into the spec (marked coupled). Pure map of three states. Readout `#srMixOut` names the failure:
  separate → "two cadences, each cheap to change"; bigbang → "the roadmap is now a frozen up-front spec — A1.01.2";
  coupled → "the spec now encodes delivery order — coupling, A1.02.3". element ids: `#srMix`, stack nodes
  `#st-road`/`#st-spec`, `#srMixOut`. Initial static state = "layers separate".

## Bridge / recap / references

- **bridge:** principle — one authoritative spec, edited only by feedback, with the plan layered cleanly above it →
  Portal — the id spec is the single source; the roadmap re-orders above it; feedback edits it; stories and brief
  derive.
- **recap (synthesis of the module):** two layers — a roadmap that plans *how we deliver* and a spec that defines
  *what we build and prove* — kept apart by one rule: the spec is the single source of truth, edited only by
  feedback. The roadmap points at it; everything else derives from it; the two run at their own cadence. Separate,
  they are both cheap to change; conflated, neither is.
- **take:** the spec is the single source of truth and the roadmap rides above it — keep the layers apart and each
  changes on its own terms; collapse them and every change drags the other.
- **sources (real):** Hunt & Thomas — *The Pragmatic Programmer* (DRY; the single source of truth); Beck, K. —
  *Extreme Programming Explained* (embrace change; small, separable decisions); Schwaber & Sutherland — *The Scrum
  Guide* (one ordered backlog, distinct from the increment).
- **related:** A1.04.1 roadmap, A1.04.2 spec, the A1.04 hub, A1.02.1 dry, A1.02.3 orthogonality, A1.03.3 adapt, A1.

## Wiring

- route-tag `/course/agile-agent-workflow/why/two-layers/source`; crumbs jonnify / AAW / A1 (`/why`) / A1.04
  (`/why/two-layers`) / here. Pager: prev → A1.04.2 spec (`/why/two-layers/spec`); next → A1.04 hub
  (`/why/two-layers`, "module overview"). A closing recap closes the module.
- `.hero-split`: hero text beside the two-cadence interactive. Copy head/header/footer/scripts from
  `html/agile-agent-workflow/why/loop/roles.html` (the shell is identical across lessons).
