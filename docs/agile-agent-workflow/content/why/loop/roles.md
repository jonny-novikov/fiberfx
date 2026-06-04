# A1.03.1 — The two roles

- **Route:** `/course/agile-agent-workflow/why/loop/roles`
- **File:** `html/agile-agent-workflow/why/loop/roles.html`
- **Place in the module:** the first dive of A1.03 — *who*. The division of labour the whole loop runs on.
- **Accent word (`.ex`):** "roles".

## Lead

The loop has two roles and a hard line between them. The Operator decides what to build and whether it is done;
the Author produces the spec and the code. Neither crosses: the Operator never writes the code, and the Author
never decides the goal. The pairing is the course thesis made concrete.

## Definition (ground in A0.2.3 — do not redefine)

- **Operator** — the human: the source of **intent, judgement, and acceptance**. Sharpens the next rung, demos,
  reviews, gives feedback, decides done. Never writes the code; their scarce, valuable input is judgement.
- **Author** — the Claude agent: the source of **production**. Turns the sharpened rung into a spec, builds the
  increment from the spec and brief, ships it — fast and exact. Never decides the goal.
- **the line** — the Operator owns *what* and *whether it is done*; the Author owns *how* (the spec and the code).
  The spec is where they meet — the Operator's sharpened intent, authored into the contract the Author builds from.
- The thesis: an agent has throughput and patience a person cannot match, but no taste for what matters; a person
  has judgement and accountability, but limited tolerance for repetition. The two roles keep each on its strength.

## Why the split works — the multiplier

The Author's throughput converts into accepted value only as fast as the Operator can accept. That makes cheap
acceptance — a contract, a test (A1.02.2) — the multiplier: when each rung carries its own acceptance, the
Operator accepts many per cycle; when acceptance means re-reading every line, the Operator accepts few, and the
throughput is wasted.

## Worked Portal example

On the Portal the Operator decides the next rung — "one branded id", then "store one event" — and what done means
(the id contract: 14-char `TSK…`, decodes to its type, unique within a node-ms). The Author turns that into a spec
and implements `Portal.ID.generate/1` to satisfy it, then ships. The Operator demos (the id decodes), reviews
(against the contract), and accepts. The Operator never writes `generate/1`; the Author never decides that an id
is the right next rung. Use only the established API; do not invent.

## The two interactives (different teaching moves)

- **Hero figure — who owns what (the IDEA).** A `.solid-select` button group `#rlView` with three views:
  "what the Operator owns" (data-k="op", data-c="gold", active), "what the Author owns" (data-k="au",
  data-c="blue"), "where they meet" (data-k="spec", data-c="elixir"). The SVG is a two-column board — Operator
  (left), Author (right) — with a central `spec` node. Tasks as small nodes: Operator column = decide the goal,
  sharpen the rung, demo, review, accept/decide done; Author column = author the spec, build the increment, ship
  it; centre = the spec. The chosen view highlights that role's nodes (or the spec); the others dim. Readout
  `#rlOut` states the boundary for the chosen view. Pure: a fixed owner map, no computation beyond highlight.
  Initial static state = "what the Operator owns". element ids: `#rlView`, task nodes `#t-*`, `#n-spec`, `#rlOut`.
- **Content figure — the acceptance multiplier (the CONSEQUENCE).** A `.fold-ctrl` slider `#rlCost` = the
  Operator's acceptance cost per rung (1…10, where 1 = check a contract, 10 = re-read every line). Fixed review
  budget `B = 10` units per cycle. Pure function: `accepted(cost) = Math.floor(B / cost)`. A bar/meter shows
  accepted rungs per cycle; the Author's "produced" rungs are drawn as a fixed larger row so the gap (produced but
  not yet acceptable) is visible. Readout `#rlMul`: "With acceptance cost c per rung, the Operator accepts ⌊10/c⌋
  rungs per cycle. The Author's throughput becomes accepted value only as fast as the Operator can accept — so
  cheap acceptance (a contract, a test) is the multiplier." element ids: `#rlCost`/`#rlCostVal`, produced/accepted
  node rows, `#rlMeter`, `#rlMul`.

## Bridge / recap / references

- **bridge:** principle — the deciding role and the producing role, each on its strength → Portal — Operator picks
  the rung and the contract; Author specs and builds `Portal.ID.generate/1` to it.
- **take:** the line is the design: the Operator decides what and whether it is done, the Author produces how —
  and the spec is the one place they meet.
- **sources (real):** Brooks, F. — *The Mythical Man-Month* (conceptual integrity; the architect vs the builder);
  Beck, *Extreme Programming Explained* (the customer/programmer roles and the planning game); Anthropic,
  "Building effective agents" (human direction, agent production).
- **related:** A1.03.2 turn, A1.03.3 adapt, the A1.03 hub, A1.02.2 contracts (cheap acceptance), A0.2.3, A1.

## Wiring

- route-tag `/course/agile-agent-workflow/why/loop/roles`; crumbs jonnify / AAW / A1 (`/why`) / A1.03
  (`/why/loop`) / here. Pager: prev → A1.03 hub (`/why/loop`); next → A1.03.2 turn (`/why/loop/turn`).
- `.hero-split`: hero text beside the role-board interactive. Copy head/header/footer/scripts from
  `html/agile-agent-workflow/why/pragmatic/dry.html`.
