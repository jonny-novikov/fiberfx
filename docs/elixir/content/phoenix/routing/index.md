# F6.02 — Routing, controllers & plugs (module hub)

- Route (served): `/elixir/phoenix/routing`.
- File: `/Users/jonny/dev/jonnify/elixir/phoenix/routing/index.html`.
- Place in the chapter: the second module of F6 · Phoenix Framework. It follows `F6.01` (the request lifecycle) and builds out the middle of that lifecycle — the match — before `F6.03` puts Ecto behind the facade. The hub frames three dives, in the arc routes → pipelines → plugs.
- Accent: blue (the F6 · Phoenix chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6 · the architecture · module 2`

Hero h1 (verbatim): Routing, controllers & `plugs`

Hero lede (verbatim): "F6.01 showed the request lifecycle as one composed pipeline; this module builds out its middle. A **route** maps a verb and a path to one controller action. A **pipeline** is a named, reusable stack of **plugs** that runs before the action — fetch the session, reject a forged request, require a logged-in user — and a **scope** runs a group of routes through it. The single idea underneath all three is the plug: a function that takes a connection and returns a connection, so routing, pipelines, and your own middleware all compose the same way. Get this layer right and cross-cutting concerns live in one place instead of being copied into every action."

Kicker (verbatim): "This module covers the three pieces of the match: routes and verbs, named pipelines and scopes, and writing a plug of your own — all of which sit in front of the thin controller from F6.01."

## What the page frames

The hub presents the three dives in a vertical card list (not the `.mods` grid; this is a module hub linking dives), each on its own accent stripe:

- **F6.02.1 · Routes & verbs** — `get`, `post`, `resources`, and `live`; route params and verified `~p` paths. Route: `/elixir/phoenix/routing/routes`. Built. (card left-border accent: blue)
- **F6.02.2 · Pipelines & scopes** — a pipeline is a named stack of plugs; a scope runs routes through it. `:browser`, `:api`, and auth as a pipeline. Route: `/elixir/phoenix/routing/pipelines`. Built. (card left-border accent: gold)
- **F6.02.3 · Writing a plug** — `init/1` and `call/2`, conn in and conn out, and `halt/1` to stop the pipeline early. Route: `/elixir/phoenix/routing/plugs`. Built. (card left-border accent: sage)

A `.bridge` figure frames the chapter arc: `F6.01 · the lifecycle` ("A request reaches a thin controller that calls the facade. The router is the plug that put it there.") → `F6.02 · the match` ("Routes, pipelines, and plugs shape what runs before the action — in one place, not copied per action."). A `.note` directs readers to start with routes, then pipelines, then plugs, naming F6.01 as the prior module and F6.03 (Ecto) as the next.

## The interactives

The hub carries two interactive figures.

Figure 1 — hero figure, `figcaption` title `One request, matched to one action` (id `hpTitle`).
- Buttons: `#hpRun` labelled `▸ match the request`; `#hpReset` labelled `reset` (class `hp-btn ghost`).
- SVG/probe element ids: `#hpProbe`, rows `#hpRow0`/`#hpRow0box`/`#hpMark0`, `#hpRow1`/`#hpRow1box`/`#hpMark1`, `#hpRow2`/`#hpRow2box`/`#hpMark2`, dispatch group `#hpAction` with `#hpParam`, live caption `#hpCap`.
- Pure functions: `run()` walks the probe top to bottom testing each router entry; `resolved()` mirrors the static resolved end-state. The three rows model `POST /courses :create` (miss — `verb POST does not match GET`), `GET /courses :index` (miss — `path /courses has no :id segment`), and `GET /courses/:id :show` (match — `verb and path both match`).
- Readout strings (verbatim): the rest caption is `GET /courses/42` → `GET /courses/:id` / `First verb-and-path match wins — here, the :show action with id = 42.`; while testing, `testing N of 3 — <why>`. The resolved action shows `CourseController, :show` and `params: %{"id" => "42"}`. Footer SVG text (verbatim): `top to bottom · first match wins` and `verb and path together pick the action`.
- Degrade: the static SVG already shows the request resolved to `:show`; there is no render on load. `prefers-reduced-motion: reduce` removes the probe transition and the hit animation; the run still resolves with `step = 0`.

Figure 2 — `The routing layer · select a piece` (`#roTitle`).
- Control group `#roSel` (`role="group"`, `aria-label="Routing piece"`), buttons `data-k`: `route` (active default), `pipeline`, `plug`.
- SVG row ids: `#roRow_route`, `#roRow_pipeline`, `#roRow_plug` (carrying the dive tags `F6.02.1`, `F6.02.2`, `F6.02.3`).
- Pure function: `pick(k)` highlights the selected row and writes the readout from the `PIECES` table. Readouts: `#roRole`, `#roResult`, `#roOut`.
- Readout strings (verbatim from `PIECES`):
  - `route` — `Route` / `verb + path → an action` / "One line maps an HTTP verb and a path to a single controller action: get "/courses/:id", CourseController, :show. The route is the only place that names the action."
  - `pipeline` — `Pipeline` / `a named stack of plugs` / "A reusable, ordered stack of plugs that runs before the action — fetch session, protect from forgery, require auth. A scope runs a group of routes through one with pipe_through."
  - `plug` — `Plug` / `conn in, conn out` / "The contract everything shares: call(conn, opts) takes a connection and returns one. The endpoint, each pipeline step, and the router are all plugs — which is why they compose."
- `#roOut` template (verbatim): `A <b>{name}</b> — {is}. {desc}`. Default selection on load is `route` (via `pick('route')`).

Footer build-stamp decoder: the real id is `TSK0NdO30mo0ie` (namespace `TSK`, branded Snowflake). Its decoded timestamp is `2026-06-01 21:38:46 UTC` (shown verbatim in `#st-ts`). Clicking/keying the `#stamp` decodes namespace/snowflake/node/seq/timestamp via the inline base-62 + epoch `1704067200000` decoder.

## References (#refs, verbatim)

Intro line: "Routing, controllers, and the plug contract the whole pipeline is built from."

Sources:
- `https://hexdocs.pm/phoenix/routing.html` — Phoenix — Routing — verbs, paths, resources, and scopes.
- `https://hexdocs.pm/phoenix/Phoenix.Router.html` — Phoenix — Router — the router macros in reference form.
- `https://hexdocs.pm/phoenix/controllers.html` — Phoenix — Controllers — actions, params, and rendering.
- `https://hexdocs.pm/plug/readme.html` — Elixir — Plug — the composable connection-in, connection-out contract.

Related in this course:
- `/elixir/phoenix/routing/routes` — F6.02.1 · Routes & verbs
- `/elixir/phoenix/routing/pipelines` — F6.02.2 · Pipelines & scopes
- `/elixir/phoenix/routing/plugs` — F6.02.3 · Writing a plug
- `/elixir/phoenix/lifecycle` — F6.01 · Architecture & the request lifecycle — the pipeline this module fills in.
- `/elixir/phoenix` — F6 · Phoenix Framework

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `phoenix` `/` `routing` (the last segment `routing` is the current, un-linked `.rcur`; `elixir` → `/elixir`, `phoenix` → `/elixir/phoenix`).
- crumbs (verbatim): `F6 · Phoenix Framework` (→ `/elixir/phoenix`) `/` `F6.02 · routing` (the `.here`).
- toc-mini (verbatim): `#concepts` "Three pieces, one idea"; `#dives` "Three deep dives".
- pager: prev → `/elixir/phoenix/lifecycle` label `← F6.01 · the request lifecycle`; next → `/elixir/phoenix/routing/routes` label `Start · routes & verbs →`.
- footer columns (verbatim): brand column with foot-tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir." · **Chapters** — `/elixir/algebra` F1 · Algebra; `/elixir/functional` F2 · Functional Programming; `/elixir/language` F3 · The Elixir Language; `/elixir/algorithms` F4 · Algorithms & Data Structures; `/elixir/pragmatic` F5 · Pragmatic Programming; `/elixir/phoenix` F6 · Phoenix Framework · **The course** — `/elixir` Course home; `/elixir/course` Contents & history; `/elixir/algebra/functions` Start · F1.01.
- Page meta — `<title>` (verbatim): `Routing, controllers & plugs — F6.02 · jonnify`. `<meta description>` (verbatim): "The plug pipeline that carries a request to a controller: routes map a verb and path to an action, named pipelines are reusable stacks of plugs, and scopes run a group of routes through one. Three dives — routes and verbs, pipelines and scopes, and writing a plug — building out the match in the middle of the F6.01 lifecycle."

## Build instruction

To rebuild this hub, copy the `head…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks verbatim from a recent built sibling on this blue chapter accent — the model sibling is `/Users/jonny/dev/jonnify/elixir/phoenix/lifecycle/index.html` (the prior F6 module hub) or this same `routing/index.html`. Change only the `<title>`/`<meta description>`, the `route-tag`, and the `<main>` body. Use only the real Portal surfaces as written — the branded store, the event-sourced engine behind one `Portal` facade, the Phoenix web app calling only that facade and rendering only the closed `%Portal.Error{}` set; cite the companion course for OTP internals rather than re-teaching them, and invent no route, id, readout string, or reference. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Name the model sibling page to copy from as the F6.02.1 dive `/Users/jonny/dev/jonnify/elixir/phoenix/routing/routes.html` for the dive shape, and this hub for the hub shape.
