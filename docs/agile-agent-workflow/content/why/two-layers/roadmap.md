# A1.04.1 — The roadmap layer

- **Route:** `/course/agile-agent-workflow/why/two-layers/roadmap`
- **File:** `html/agile-agent-workflow/why/two-layers/roadmap.html`
- **Place in the module:** the first dive of A1.04 — *how we deliver*. The top layer: the coarse, re-orderable plan
  of rungs.
- **Accent word (`.ex`):** "roadmap".

## Lead

The roadmap is the plan of delivery: an ordered list of rungs, each a one-line intent plus a definition of done.
It answers *what next* and *in what order* — and nothing more. It points at the specs; it never defines behaviour.
Because it carries no behaviour, it is cheap to re-order as you learn.

## Definition (ground in A0.2.1 — do not redefine)

- **roadmap layer** — answers *how we deliver*: milestones, iterations, the Author/Operator loop. A coarse,
  ordered sequence of rungs. It **points at** the spec layer; it **never defines behaviour**.
- **rung (on the roadmap)** — a one-line intent plus a definition of done; not a spec. The spec is authored later,
  when the rung is sharpened (A1.03.2).
- **re-planning** — re-ordering the roadmap as value, risk, and dependencies become clearer. Cheap, because no
  behaviour is encoded in the order.
- The boundary: a roadmap item says *when* and *whether*; the spec says *what* and *how it is proven*. Put behaviour
  in the roadmap and it stops being a plan and becomes a frozen up-front specification — the big-bang spec (A1.01.2).

## Why it matters — a plan you can change

A roadmap holds no behaviour, so re-ordering it costs nothing: promote a rung, drop one, split another, and not a
single spec changes. That is the point of the layer — delivery can adapt to what the loop learns without disturbing
the definition of any rung. The moment the roadmap carries the behaviour itself, that cheap re-planning is gone.

## Worked Portal example

The Portal roadmap is a sequence: a branded id, then storing one event, then one read model, then a Telegram
command, then the dashboard. Each is one line plus a definition of done — "an id that decodes to its type" — not a
spec. As the loop runs, the order is re-planned: if the dashboard rung turns out to depend on the read model, the
read model is promoted ahead of it. No spec is touched; only the order. The id's behaviour lives in its spec, not
in the roadmap. Keep Portal references conceptual; do not invent module APIs.

## The two interactives (different teaching moves)

- **Hero figure — re-order the roadmap (the IDEA).** A `.solid-select` `#rdSort` with three orderings: "by value"
  (data-k="value", data-c="gold", active), "by risk" (data-k="risk", data-c="blue"), "by dependency"
  (data-k="dep", data-c="elixir"). A fixed set of five rungs each carry `{name, value, risk, dep}`. The SVG draws
  the five rungs as a row of cards in the current order; picking an ordering re-sorts them (a stable sort on the
  chosen key). Pure: `order(key)` returns the five rung indices sorted by that key. Readout `#rdOut`: "Re-ordered by
  K — the delivery plan changed; not one spec did. The roadmap points at specs; it never defines behaviour."
  element ids: `#rdSort`, rung cards `#rd-card-0`…`#rd-card-4` (with label children), `#rdOut`. Initial static
  state = "by value". (Re-ordering only repositions/relabels; do not animate beyond the `.dq rect` transition.)
- **Content figure — coarse, not behaviour (the CONSEQUENCE).** A `.solid-select` `#rdGrain`: "a one-liner + a
  definition of done" (data-k="coarse", data-c="sage", active) / "the full behaviour spec" (data-k="fine",
  data-c="burg"). The SVG shows one roadmap item rendered at the chosen granularity: coarse = a single line + a DoD
  tick (correct — points at a spec); fine = a full multi-field spec crammed into the roadmap (wrong — that is the
  spec layer's job, and a roadmap full of specs is the big-bang spec). Pure map of the two states. Readout
  `#rdGrainOut` names the consequence; in the "fine" case it states this is the big-bang spec (A1.01.2) — descriptive
  text. element ids: `#rdGrain`, `#rdItem` (the rendered item group), `#rdGrainOut`. Initial static state = "coarse".

## Bridge / recap / references

- **bridge:** principle — plan delivery in a coarse, re-orderable layer that points at specs → Portal — the rung
  sequence (id → event → read model → command → dashboard), re-ordered freely; each rung's behaviour lives in its
  spec, never in the order.
- **take:** the roadmap is a plan you can change because it holds order, not behaviour — the cheap re-planning is the
  whole reason the layer is separate.
- **sources (real):** Cohn, M. — *Agile Estimating and Planning* (release planning over a product backlog); Schwaber
  & Sutherland — *The Scrum Guide* (the ordered product backlog); Beck, K. — *Extreme Programming Explained* (the
  planning game).
- **related:** A1.04.2 spec, A1.04.3 source, the A1.04 hub, A1.01.2 big-bang-specs, A1.03.2 turn (sharpen authors
  the spec), A1.

## Wiring

- route-tag `/course/agile-agent-workflow/why/two-layers/roadmap`; crumbs jonnify / AAW / A1 (`/why`) / A1.04
  (`/why/two-layers`) / here. Pager: prev → A1.04 hub (`/why/two-layers`); next → A1.04.2 spec
  (`/why/two-layers/spec`).
- `.hero-split`: hero text beside the re-order interactive. Copy head/header/footer/scripts from
  `html/agile-agent-workflow/why/loop/roles.html` (the shell is identical across lessons).
