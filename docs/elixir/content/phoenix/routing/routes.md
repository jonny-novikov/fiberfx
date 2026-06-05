# F6.02.1 — Routes & verbs (dive)

- Route (served): `/elixir/phoenix/routing/routes`.
- File: `/Users/jonny/dev/jonnify/elixir/phoenix/routing/routes.html`.
- Place in the chapter: the first of the three F6.02 dives (routes → pipelines → plugs). It teaches how a verb and a path map to one controller action, the join that the later pipelines and plugs sit in front of.
- Accent: blue (the F6 · Phoenix chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.02 · part 1 of 3`

Hero h1 (verbatim): Routes & `verbs`

Hero lede (verbatim): "A route is a single, declarative line that says "this verb and this path run that action." `get "/courses/:id", CourseController, :show` reads as: a **GET** to a path with an `:id` segment dispatches to `CourseController.show/2`, with the segment delivered in the action's params. Phoenix gives you the HTTP verbs directly (`get`, `post`, `put`, `delete`), `resources` for the seven RESTful routes of a noun, and `live` to point a URL at a LiveView. And because routes are compiled, the `~p` sigil checks every path you build against the router at compile time — a typo in a link is a warning, not a 404 in production."

Kicker (verbatim): "See the four route kinds, read a route's anatomy part by part, then a real router. Each route still ends at a thin controller that calls the facade."

## Sections

In order:
1. `#kinds` — **Four kinds of route**: `get`, `post`, `resources`, `live`. Interactive selector. Takeaway: "Reach for the plain verb first; it is the clearest mapping from a request to your code. `resources` is a shorthand worth using only when a noun really has the full set of actions."
2. `#anatomy` — **A route, part by part**: the four parts (verb, path with `:segments`, controller module, action atom). Static decomposition figure. Takeaway: "The `:id` segment is the join to the engine: it arrives in the action's params, becomes the branded id you pass to a facade call, and is decoded by the same `Portal.ID` from F4 and F5."
3. `#code` — **A real router**: the real Elixir code block (below). Closes with a `.bridge` (a verb and a path → a checked link) and a `.note` pointing to pipelines.

Running example: the catalog routes (`/courses`, `/courses/:id`, `/enroll`) on the `PortalWeb` router.

Real Elixir code shown (`#code`, verbatim):
```
scope "/", PortalWeb do
  pipe_through :browser

  get  "/courses",      CourseController, :index   # list
  get  "/courses/:id",  CourseController, :show    # one — :id is a param
  post "/enroll",       EnrollmentController, :create  # write

  resources "/lessons", LessonController, only: [:show]
  live "/enroll/:id", EnrollmentLive           # a LiveView (F6.06)
end

# verified ~p paths are checked against the router at compile time
def course_path(course), do: ~p"/courses/#{course.id}"   # typo => compile warning
```

## The interactives

Figure 1 — `Route kinds · select one` (`#rvTitle`).
- Control group `#rvSel` (`role="group"`, `aria-label="Route kind"`), buttons `data-k`: `get` (active default), `post`, `resources`, `live`.
- SVG element ids: `#rvBox`, `#rvKind`, `#rvLine`, `#rvHint`; readouts `#rvOut`, `#rvRole`, `#rvResult`.
- Pure function: `pick(k)` writes the verb label, the route line, the hint, and the readout from the `KINDS` table; `pick('get')` runs on load.
- Readout strings (verbatim from `KINDS`):
  - `get` — `read → an action` / line `get "/courses/:id", CourseController, :show` / hint `a read: the verb dispatches to one controller action` / "A GET points a path at an action that reads. The :id segment arrives in params and becomes the branded id passed to a facade query."
  - `post` — `write → an action` / line `post "/enroll", EnrollmentController, :create` / hint `a write: the action issues a facade command` / "A POST points a path at an action that writes. The action builds no domain logic — it calls a Portal command and maps the result onto a redirect."
  - `resources` — `seven RESTful routes` / line `resources "/lessons", LessonController` / hint `expands to index, show, new, create, edit, update, delete` / "One line expands into the standard seven routes for a noun. Use only: or except: to keep only the actions a resource actually needs."
  - `live` — `a URL → a LiveView` / line `live "/enroll/:id", EnrollmentLive` / hint `hands the connection to a LiveView, not a controller` / "A live route points a URL at a LiveView instead of a controller action. The LiveView mounts over the socket the endpoint declared, and still calls only the facade (F6.06)."
- `#rvOut` template (verbatim): `<b>{name}</b> — {maps}. {desc}`.

Figure 2 — static, `get · /courses/:id · CourseController · :show` (`#rvAnatomyTitle`). No controls; the SVG decomposes the route into VERB / PATH · `:id` is a param / CONTROLLER / ACTION, with the foot text `params: %{"id" => "CRS0KHTOWnGLuC"} arrives in show(conn, params)`.

Footer build-stamp decoder: the real id is `TSK0NdO316fvpA`. Its decoded timestamp is `2026-06-01 21:38:46 UTC` (`#st-ts`). The `#stamp` decodes namespace/snowflake/node/seq/timestamp via the inline base-62 + epoch `1704067200000` decoder.

Degrade behaviour: all content is visible without JS (the SVGs carry the default state in markup; the `.reveal` references section is shown on load when JS is off). `prefers-reduced-motion: reduce` disables the scroll-reveal transition.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/phoenix/routing.html` — Routing — Phoenix documentation — verbs, paths, and scopes.
- `https://hexdocs.pm/phoenix/controllers.html` — Controllers — Phoenix documentation — actions and rendering.
- `https://hexdocs.pm/plug/readme.html` — `Plug` — documentation — the composable middleware spec.

Related in this course:
- `/elixir/phoenix/routing` — F6.02 · Routing, controllers & plugs
- `/elixir/phoenix/routing/pipelines` — Pipelines & scopes
- `/elixir/phoenix/routing/plugs` — Plugs

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `phoenix` `/` `routing` `/` `routes` (the last segment `routes` is the current `.rcur`; `elixir`, `phoenix`, `routing` are links to `/elixir`, `/elixir/phoenix`, `/elixir/phoenix/routing`).
- crumbs (verbatim): `F6` (→ `/elixir/phoenix`) `/` `F6.02` (→ `/elixir/phoenix/routing`) `/` `routes` (the `.here`).
- toc-mini (verbatim): `#kinds` "Four kinds of route"; `#anatomy` "A route, part by part"; `#code` "A real router".
- pager: prev → `/elixir/phoenix/routing` label `← F6.02 · overview`; next → `/elixir/phoenix/routing/pipelines` label `Next · pipelines & scopes →`.
- footer columns (verbatim): brand column with foot-tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir." · **Chapters** — `/elixir/algebra` F1 · Algebra; `/elixir/functional` F2 · Functional Programming; `/elixir/language` F3 · The Elixir Language; `/elixir/algorithms` F4 · Algorithms & Data Structures; `/elixir/pragmatic` F5 · Pragmatic Programming; `/elixir/phoenix` F6 · Phoenix Framework · **The course** — `/elixir` Course home; `/elixir/course` Contents & history; `/elixir/algebra/functions` Start · F1.01.
- Page meta — `<title>` (verbatim): `Routes & verbs — F6.02.1 · jonnify`. `<meta description>` (verbatim): "How a verb and a path map to one controller action: get and post, resources for the seven RESTful routes, and live for a LiveView. Route params arrive in the action's params map, and verified ~p paths are checked against the router at compile time so a typo is a warning, not a broken link."

## Build instruction

To rebuild this dive, copy the `head…</style>`, the `header.site`, the `footer.site-foot`, and the trailing `<script>` blocks verbatim from a recent built sibling on this blue chapter accent — the model sibling is `/Users/jonny/dev/jonnify/elixir/phoenix/routing/pipelines.html` (the adjacent F6.02.2 dive, identical shell). Change only the `<title>`/`<meta description>`, the `route-tag`, and the `<main>` body (eyebrow, h1, lede, the two/three teaching sections, the interactive ids, and the one real code block). Use only the real Portal surfaces as written — `CourseController`, `EnrollmentController`, the branded `:id`/`Portal.ID`, the single `Portal` facade, the closed `%Portal.Error{}` set; cite the companion course for OTP internals rather than re-teaching, and invent no route, id, readout string, code token, or reference URL. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
