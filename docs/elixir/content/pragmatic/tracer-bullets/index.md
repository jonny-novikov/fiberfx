# F5.03 — Tracer bullets: a walking skeleton (module hub)

- Route (served): `/elixir/pragmatic/tracer-bullets`
- File: `elixir/pragmatic/tracer-bullets/index.html`
- Place in the chapter: third module of F5 · Pragmatic Programming. It sits after F5.01 (foundations / the thin server) and F5.02 (the domain model), and wires those two parts together by driving one use case end to end. The hub frames three dives — `prototypes`, `skeleton`, `iterating` — and hands off to F5.04 (Design by contract).
- Accent: burgundy (`--burgundy: #c4504c`, the F5 · Pragmatic chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5 · the engine · module 3`

Hero title (verbatim): `Tracer bullets: a walking skeleton` (the word `skeleton` carries the `.ex` elixir-italic span).

Hero lede (verbatim):

> A running server and a domain model are still two separate things until one request travels the whole way between them. F5.03 fires a **tracer bullet**: it takes a single use case — enroll a learner — and drives it end to end through every layer at once, each layer present but minimal. A route on the thin server calls one function on the Learning context, which builds an `%Enrollment{}` and puts it in the store, and the handler answers. That thin vertical slice is the **walking skeleton**: real code, not a throwaway, and the frame every later feature drops into. Once it walks, the system grows by iterating the slice.

Kicker (verbatim, `.kicker`):

> One use case cutting straight down the stack. Select a layer the slice passes through to see what it does — minimal, but real.

## What the page frames

This is a hub. The teaching body has two sections (`#slice` "A vertical slice", `#dives` "Three deep dives"), then the three dive cards (rendered as inline-styled `<a>` blocks, not a `.mods` grid):

- F5.03.1 — **Tracer bullets vs prototypes** — "Both are built fast; one is real code you keep and build on, the other is throwaway code to answer a question." — route `/elixir/pragmatic/tracer-bullets/prototypes` — built (burgundy left-border).
- F5.03.2 — **The walking skeleton** — "Enroll a learner end to end: `post "/enroll"` → `Learning.enroll/2` → `%Enrollment{}` → store → 201." — route `/elixir/pragmatic/tracer-bullets/skeleton` — built (blue left-border).
- F5.03.3 — **Iterating the slice** — "Grow the skeleton one thin vertical slice at a time — deliver a lesson, record progress — always running." — route `/elixir/pragmatic/tracer-bullets/iterating` — built (gold left-border).

A `.bridge` block frames the arc: `F5.01 + F5.02 · parts` ("A thin server that runs, and a domain model with a shape — but no request has crossed between them yet.") → `F5.03 · one slice through both` ("Drive enroll-a-learner end to end, thin at every layer, so the design is proven and the frame is set.").

## The interactives

One hero concept figure and one in-body figure.

Hero figure — `figure.hero-fig` titled (`#ghTitle`) `Once it walks, it grows by iterating`.
- SVG ids: `#ghChain` (the slice-row container), `#ghStatus` (status line). The static (no-JS) initial markup shows slice 1 only — `enroll a learner` / `slice 1 · the walking skeleton` — with status `running end to end · 1 slice`.
- Controls (`.hp-ctrls`): `#ghBtn` button labelled `▸ iterate the slice`, `#ghReset` button labelled `reset`. Caption element `#ghCap` (`aria-live="polite"`).
- The slice data drives three rows in order: `{ label: 'enroll a learner', sub: 'slice 1 — the walking skeleton', tag: 'enroll' }`, `{ label: 'deliver a lesson', sub: 'slice 2 — a new vertical path', tag: 'deliver' }`, `{ label: 'record progress', sub: 'slice 3 — another path, same frame', tag: 'progress' }`.
- The `render(newIdx)` function rebuilds the chain, sets the status to `running end to end · ` + N + ` slice`/` slices`, and writes the caption. Initial caption (verbatim): `[ slice 1 · enroll ]` then `One thin slice, alive end to end. Add the next and the frame holds.` As slices grow it reads `[ slice N · <tag> ]` then either `Add the next slice and the frame holds. Always running: <tags joined by ·>.` or, when full, `Three vertical paths through one frame, the skeleton grown without a rewrite.` When all shipped the button disables and reads `▸ all slices shipped`.
- Degrade: the static one-row markup is visible without JS. Row entry uses the `hpIn` keyframe under `prefers-reduced-motion: no-preference`; under `prefers-reduced-motion: reduce` that animation is set to `none`.

In-body figure — `figure.fig` titled (`#tbTitle`) `The enroll slice · select a layer`.
- Control group `#tbSel` (`role="group"`, `aria-label="Slice layer"`) with four buttons, `data-k`/label: `web`/`web`, `api`/`context API` (default `active`), `struct`/`struct`, `store`/`store`.
- SVG layer rects: `#tbL_web`, `#tbL_api`, `#tbL_struct`, `#tbL_store`. Readout container `#tbOut` (`aria-live="polite"`); footnote spans `#tbRole` (layer) and `#tbResult` (does).
- The pure `pick(k)` function highlights the selected layer rect (burgundy stroke `#c4504c`, fill `#1d1320`), sets `#tbRole` to the layer name and `#tbResult` to its `does` string, and writes `#tbOut`. Initial call is `pick('api')`.
- Layer table (`name` / `does` / `desc`, verbatim from the script):
  - `web` — `Thin web server` / `post "/enroll"` / `The slice starts at the thin server from F5.01: one route, one handler, no extra middleware. Real, but only this single path is wired.`
  - `api` — `Context API` / `Learning.enroll/2` / `The handler calls one public function on the Learning context from F5.02. Real validation and a real return value — only the one use case.`
  - `struct` — `Domain struct` / `%Enrollment{}` / `enroll/2 builds one real struct, keyed by a branded id. The actual domain type from F5.02, not a stand-in or a map.`
  - `store` — `The store` / `Store.put(enrollment)` / `The enrollment is kept in the F4 store. Real persistence for this one entity; the rest of the schema is added later, slice by slice.`
- Readout string template (`#tbOut`, verbatim): `At the <b>{name}</b> layer the slice does one real thing — <code class="inl">{does}</code>. {desc}`

Takeaway (`.take`, verbatim): `A walking skeleton is the whole system in miniature: thin everywhere, finished nowhere, but alive end to end. It turns "does this design hold together" into a question you answer on day one.`

Footer build-stamp decoder: stamp id `TSK0NctaLqsS4e`, hard-coded `st-ts` `2026-06-01 14:32:29 UTC`. Decoded: namespace `TSK`, snowflake `319845668208246784`, node `0`, seq `0`, timestamp `2026-06-01 14:32:29 UTC` (B62 over the branded id, epoch `1704067200000`).

## References (#refs, verbatim)

Intro line: `Building a system end to end first, as a thin slice that runs.`

Sources:
- `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/` — Hunt & Thomas — *The Pragmatic Programmer* — tracer bullets and prototypes.
- `https://wiki.c2.com/?WalkingSkeleton` — Alistair Cockburn — Walking Skeleton — a thin slice that runs end to end.
- `https://martinfowler.com/bliki/WalkingSkeleton.html` — Martin Fowler — Walking Skeleton — the same idea, with iteration.

Related in this course:
- `/elixir/pragmatic/tracer-bullets/prototypes` — F5.03.1 · Tracer bullets vs prototypes
- `/elixir/pragmatic/tracer-bullets/skeleton` — F5.03.2 · The walking skeleton
- `/elixir/pragmatic/tracer-bullets/iterating` — F5.03.3 · Iterating the slice
- `/elixir/pragmatic/foundations` — F5.01 · Start thin — the server the slice starts at.
- `/elixir/pragmatic/domain` — F5.02 · Modeling the Portal domain — the context the slice calls.

## Wiring

- route-tag (verbatim): `/ ` `elixir` ` / ` `pragmatic` ` / ` `tracer-bullets` (links: `elixir` → `/elixir`, `pragmatic` → `/elixir/pragmatic`, current segment `tracer-bullets` in `.rcur`).
- crumbs (verbatim): `F5 · Pragmatic Programming` (→ `/elixir/pragmatic`) `/` `F5.03 · tracer-bullets` (`.here`).
- toc-mini: `#slice` → `A vertical slice`; `#dives` → `Three deep dives`.
- pager: prev → `/elixir/pragmatic` label `← F5 · overview`; next → `/elixir/pragmatic/tracer-bullets/prototypes` label `Start · tracer bullets vs prototypes →`.
- The closing `.note` (verbatim): `Start with tracer bullets vs prototypes, then the walking skeleton, then iterating the slice. The next module, F5.04 — Design by contract, hardens the commands the slice runs. For the runtime path through the engine, see the design brief: the command & event flow.` (links: `/elixir/pragmatic/tracer-bullets/prototypes`, `/elixir/pragmatic/tracer-bullets/skeleton`, `/elixir/pragmatic/tracer-bullets/iterating`, `/elixir/pragmatic/flow`.)
- footer: three columns. **Chapters** — `F1 · Algebra` (`/elixir/algebra`), `F2 · Functional Programming` (`/elixir/functional`), `F3 · The Elixir Language` (`/elixir/language`), `F4 · Algorithms & Data Structures` (`/elixir/algorithms`), `F5 · Pragmatic Programming` (`/elixir/pragmatic`), `F6 · Phoenix Framework` (`/elixir/phoenix`). **The course** — `Course home` (`/elixir`), `Contents & history` (`/elixir/course`), `Start · F1.01` (`/elixir/algebra/functions`). Foot tag: `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta: `<title>` = `Tracer bullets: a walking skeleton — F5.03 · jonnify`. `<meta name="description">` = `With a running server and a domain model in hand, F5.03 wires them together by driving one use case — enroll a learner — through every layer at once: route, context API, struct, store, and back. That thin end-to-end slice is the walking skeleton, real production code rather than a throwaway prototype, and once it runs the system grows by iterating the slice. Three dives on tracer bullets, the skeleton, and iteration.`

## Build instruction

To rebuild this hub, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks verbatim from a recent built sibling on the burgundy F5 accent — the model sibling is the dive `elixir/pragmatic/tracer-bullets/skeleton.html` (same chapter, same stamp epoch, same script shape) — changing only the `<title>`/`<meta description>`, the route-tag, and the `<main>` body. Keep the hero-figure (`#ghChain` iterate-the-slice) and the layer figure (`#tbSel`/`#tbOut`) wiring exactly as authored: pure `pick`/`render` functions, no framework. No-invent guards: use only the real Portal surfaces as written — the branded store (`Portal.Store`, `Portal.ID.new("ENR")`), the event-sourced engine behind the one `Portal` facade, the `Learning` context, the `%Enrollment{}` struct — and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
