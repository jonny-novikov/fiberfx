# A1.02.3 — Orthogonality and blast radius

- **Route:** `/course/agile-agent-workflow/why/pragmatic/orthogonality`
- **File:** `html/agile-agent-workflow/why/pragmatic/orthogonality.html`
- **Place in the module:** the third dive of A1.02 — the *structure* principle, and the module's resolution.
  Knowledge has one home (DRY); a unit has a precise contract (DbC); orthogonality keeps those units independent
  so a change stays reviewable.
- **Accent word (`.ex`):** "radius".

## Lead

Two components are orthogonal when changing one does not change the other. The Pragmatic Programmer's argument
was that orthogonal systems are easier to change and test. For an agent it becomes sharper: orthogonality bounds
a change's blast radius, and a bounded blast radius is the difference between a diff a human can review and one
they cannot.

## Definition

- **orthogonality / decoupling** — independent components, each changeable without rippling into the others.
  Achieved by depending on a facade, not on another component's internals (information hiding).
- **blast radius** — the set of modules a change can affect: the changed module plus everything that depends on
  it, transitively.
- **facade** — a stable interface a surface depends on, so its internals can change without touching callers.
- The agent-era reading: a human reviews a bounded amount. A change with a small blast radius produces a diff
  inside that bound — reviewable, acceptable. Coupling makes the blast radius unbounded, and the agent's diff
  unreviewable, however correct each line looks.

## Worked Portal example

The Portal has five surfaces: the **store**, the event-sourced **events** engine, the **web** app (Phoenix),
the Telegram **bot**, and the student **dashboard**. Orthogonal wiring: each surface depends on the events
facade, and events depends on the store — no surface reaches into another surface's internals. A change to the
dashboard touches the dashboard alone. Couple them — let the bot read the web's internals, the dashboard read
the bot's — and a change to one surface risks the others, so its diff can no longer be reviewed in isolation.
Keep the facades conceptual; do not invent module function names or arities.

## The two interactives (different teaching moves)

- **Hero figure — orthogonal vs coupled (the SHAPE).** One `.solid-select` 2-button toggle `#orMode`:
  "orthogonal" / "coupled". The SVG draws the five surfaces as nodes (store, events, web, bot, dash) and the
  dependency edges for the chosen mode, then highlights the **blast radius of changing `web`** (a leaf surface)
  in burgundy, with `web` itself in gold. Two fixed, precomputed scenarios (no live graph search needed):
  - **orthogonal** edges: web→events, bot→events, dash→events, events→store. Nothing depends on `web`, so the
    blast radius of changing `web` is **just `web` — 1 of 5**.
  - **coupled** edges: the orthogonal set plus bot→web and dash→web (bot and dash reach into web's internals).
    Now changing `web` risks bot and dash, so the blast radius is **{web, bot, dash} — 3 of 5**.
  Readout `#orOut` states the mode, the highlighted set, and the count. element ids: `#orMode`, node rects
  `#n-store/-events/-web/-bot/-dash`, edge group `#orEdges`, `#orOut`.
- **Content figure — the blast-radius bill (the CONSEQUENCE).** One `.fold-ctrl` slider `c` = how many other
  modules the changed module is coupled to (0…5, out of five others). Pure function: `blast(c) = 1 + c` (the
  module itself, plus the c that may break with it). Six module nodes draw; the changed one gold, c of the
  others burgundy ("in blast"). A meter `#orMeter` fills to `blast(c)/6`. Readout `#orCost`: "A module coupled
  to c others has a blast radius of 1+c modules. The agent's diff is acceptable only while that radius fits in a
  review. Orthogonal (c=0): radius 1 — the change is itself." (Prose notes the linear count is the direct
  radius; transitive coupling makes it worse.) element ids: `#orC`/`#orCVal`, node rects `#m-0`…`#m-5`,
  `#orMeter`, `#orCost`.

## Bridge / recap / references

- **bridge:** principle — orthogonal components change without rippling → Portal — surfaces behind the events
  facade; a change to one surface keeps its blast radius to one.
- **recap (synthesis of the module):** DRY gives a fact one home; Design by Contract gives a unit a precise
  spec; orthogonality keeps the units independent. Together they are why an agent's work stays *ownable*: one
  authority to point at, one contract to accept against, one bounded diff to review.
- **take:** orthogonality is not tidiness — it is the property that keeps an agent's diff inside what a human can
  review.
- **sources (real):** Hunt & Thomas, *The Pragmatic Programmer* ("Orthogonality"); Parnas, D.L. — *On the
  Criteria To Be Used in Decomposing Systems into Modules* (CACM 1972, information hiding); Meyer, B. —
  *Object-Oriented Software Construction* (modularity).
- **related:** A1.02.1 dry, A1.02.2 contracts, the A1.02 hub, A1.01.3 thin-slices, A1.

## Wiring

- route-tag `/course/agile-agent-workflow/why/pragmatic/orthogonality`; crumbs jonnify / AAW / A1 (`/why`) /
  A1.02 (`/why/pragmatic`) / here. Pager: prev → A1.02.2 contracts (`/why/pragmatic/contracts`); next → A1.02 hub
  (`/why/pragmatic`, "module overview"). A closing recap closes the module.
- `.hero-split`: hero text beside the graph hero interactive. Copy head/header/footer/scripts from
  `html/agile-agent-workflow/why/pragmatic/dry.html` (same module — exact design-system parity).
