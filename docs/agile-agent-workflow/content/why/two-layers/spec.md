# A1.04.2 — The spec layer

- **Route:** `/course/agile-agent-workflow/why/two-layers/spec`
- **File:** `html/agile-agent-workflow/why/two-layers/spec.html`
- **Place in the module:** the second dive of A1.04 — *what we build and how we know it is right*. The middle layer:
  the single source of truth.
- **Accent word (`.ex`):** "spec".

## Lead

The spec layer is where correctness lives. For one rung it is the precise definition plus its proof — and it is the
hub the rest of the work derives from: the user stories, the agent brief, the code, and the tests all come from the
spec. It is the single source of truth, and only feedback edits it.

## Definition (ground in A0.2.1 — do not redefine)

- **spec layer** — answers *what we build and how we know it is right*. For each rung: the spec, its user stories,
  and the agent brief. The single source of truth; edited only by feedback.
- **derived artifacts** — the user stories and the agent brief are derived *from* the spec; the code and tests are
  built *to* the spec. Nothing edits the derived artifacts directly — change the spec and they are regenerated.
- **the same rung, two granularities** — a roadmap item is the coarse face of a rung (one line + a definition of
  done); its spec is the fine face (the full definition + acceptance). Same rung, two layers.
- The spec is fine and authoritative where the roadmap is coarse and mutable: it changes slowly and only through
  feedback, because everything downstream depends on it.

## Why it matters — one hub, everything derives

When the spec is the single source, a change happens in one place and reaches every derived artifact: regenerate the
stories, re-brief the agent, rebuild the code and tests from the new spec. When the spec is *not* the single source
— when a story or the code is edited directly — the derived artifact forks from the spec, and the spec becomes a
document that lies about the system (the A1.02.1 drift, between the spec and what it specifies).

## Worked Portal example

The spec for the rung "one branded id" is the id contract: a 14-character `TSK…` id, decodes to its type, unique
within a node-millisecond. From that one spec everything derives: the user story ("as a caller I receive a typed id
I can decode"), the agent brief that tells the Author how to build it, the implementation `Portal.ID.generate/1`,
and the tests that accept it. Change the contract — feedback says "also sort by time" — and all of them are
regenerated from the edited spec. Use only the established API (`Portal.ID.generate/1`, `Portal.ID.decode/1`); do
not invent functions.

## The two interactives (different teaching moves)

- **Hero figure — the spec is the hub (the IDEA).** A `.solid-select` `#spDerive` with three views: "the user
  stories" (data-k="stories", data-c="gold", active), "the agent brief" (data-k="brief", data-c="blue"), "the code
  and tests" (data-k="code", data-c="elixir"). The SVG shows the **spec** node at the centre with the derived
  artifacts around it (user stories, agent brief, code, tests); arrows point OUT from the spec to each. The chosen
  view highlights the spec → that artifact path. Readout `#spOut` states that the chosen artifact derives from the
  spec — nothing edits it directly. Pure: highlight only; a fixed derivation map. element ids: `#spDerive`,
  `#n-spec`, derived nodes `#d-stories`/`#d-brief`/`#d-code`/`#d-tests`, links `#sp-link-*`, `#spOut`. Initial
  static state = "the user stories".
- **Content figure — zoom: one rung, two granularities (the CONSEQUENCE).** A `.solid-select` `#spZoom`: "roadmap
  view" (data-k="road", data-c="blue", active) / "spec view" (data-k="spec", data-c="gold"). The SVG shows the SAME
  rung at two granularities: roadmap view = a single line ("a branded id · DoD: decodes to its type"); spec view =
  the full contract (pre/post/invariant fields). Pure: two fixed renderings of one rung. Readout `#spZoomOut`:
  "Same rung, two layers: the roadmap holds the coarse face (one line + a definition of done); the spec holds the
  fine face (the full definition and its acceptance). The spec is where correctness lives." element ids: `#spZoom`,
  `#spRung` (the rendered rung group), `#spZoomOut`. Initial static state = "roadmap view".

## Bridge / recap / references

- **bridge:** principle — define correctness once, in an authoritative spec everything derives from → Portal — the
  id contract is the spec; the user story, the agent brief, `Portal.ID.generate/1`, and its tests all derive from it.
- **take:** the spec is the single source of truth — the one fine, authoritative face of a rung that every other
  artifact is built from, and the only one feedback edits.
- **sources (real):** Cohn, M. — *User Stories Applied* (stories as the derived, negotiable face of a requirement);
  Adzic, G. — *Specification by Example* (the spec as executable, shared truth); Beck, K. — *Extreme Programming
  Explained* (stories and the customer's definition of done).
- **related:** A1.04.1 roadmap, A1.04.3 source, the A1.04 hub, A1.02.2 contracts (the spec's internal form),
  A1.02.1 dry (single source of truth), A1.

## Wiring

- route-tag `/course/agile-agent-workflow/why/two-layers/spec`; crumbs jonnify / AAW / A1 (`/why`) / A1.04
  (`/why/two-layers`) / here. Pager: prev → A1.04.1 roadmap (`/why/two-layers/roadmap`); next → A1.04.3 source
  (`/why/two-layers/source`).
- `.hero-split`: hero text beside the spec-hub interactive. Copy head/header/footer/scripts from
  `html/agile-agent-workflow/why/loop/roles.html` (the shell is identical across lessons).
