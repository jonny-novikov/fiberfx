# A4 · The spec ladder — viewer (utility page)

> Source of record for `html/agile-agent-workflow/spec/specimens/index.html`.
> Route: `/course/agile-agent-workflow/spec/specimens`. Accent: elixir-purple. Stamp: `TSK0Ng9hnHJgW0`.
> Model copied verbatim: `spec/by-example/index.html` (hub head/header/footer + the two trailing scripts).
> Role: the **spec-ladder viewer** every `.specref` chip in chapter A4 links to. Not a module hub — a utility page
> with one framing interactive (the requirement is ≥1; this carries 2).

## Lead

A spec is a living document. It is edited by feedback, rung after rung, and version control records every edit.
This page reads that record: each stop on the slider is a shipped iteration of the Portal's web layer (F6.1–F6.6),
and the figure reports what the spec said at that point — the goal, the ship date, the routing surface, and the one
thing the rung changed. The instructive thread is the routing surface, because a route name is a decision a spec can
get wrong and later correct: F6.1's first-draft `/courses/:user_id` is **reconciled away into `/my/courses`** at
F6.5, and the catalog goes **live at `/courses`** at F6.6.

## The baked dataset (verbatim — from git + the real specs; invent nothing)

The F6 web ladder, the iteration axis (1-indexed, 6 stops):

1. `#f6-1` · **F6.1 · Bootstrap the Phoenix Portal** · shipped 2026-06-03 · goal: stand the headless F5 engine up as
   a Phoenix web app. ROUTES: `GET /courses/:user_id` (first-draft course page for a given user) · `GET /health`.
   changed: first draft — the `/courses/:user_id` route is introduced here.
2. `#f6-2` · **F6.2 · Routing & the access surface** · shipped 2026-06-04 · goal: a real routing surface on F6.1's
   endpoint. ROUTES: the access surface firms up (browser / api / require_auth pipelines). changed: pipelines and the
   route shape arrive.
3. `#f6-3` · **F6.3 · Persistence with Ecto** · shipped 2026-06-04 · goal: make the Portal durable without the core
   depending on a database. ROUTES: unchanged. changed: persistence behind the facade.
4. `#f6-4` · **F6.4 · Contexts & domain on the web** · shipped 2026-06-04 · goal: the real domain behind one
   web-facing surface — a Catalog context over the Ecto Course schema. ROUTES: the catalog becomes the spine.
   changed: the `Portal.Catalog` context arrives.
5. `#f6-5` · **F6.5 · Views with HEEx** · shipped 2026-06-04 · goal: server-render the catalog. ROUTES: catalog
   `GET /courses` · a course `GET /course/:course_tag` · own enrollments `GET /my/courses` (PROTECTED) — and
   `/courses/:user_id` RETIRES into `/my/courses`. changed: **THE RECONCILE** — `/courses/:user_id` retires into
   `/my/courses` (one honest name for a learner's own enrollments); the catalog is `/courses`.
6. `#f6-6` · **F6.6 · LiveView** · shipped 2026-06-05 · goal: make F6.5's catalog interactive without full reloads —
   `CatalogLive` streams the catalog and renders live search + create over the facade. ROUTES (as-built today):
   `live "/courses"` (the live catalog) · `/course/:course_tag` (a course) · `/my/courses` (a learner's own,
   protected). changed: the catalog goes live.

## Framing interactive (hero) — the git-iteration slider

A `.fold-ctrl` range slider, 6 stops, default = stop 1; also settable from `location.hash` (`#f6-1`…`#f6-6`) on
load and on `hashchange`. At each stop the SVG highlights the active stop on a six-dot axis and renders three route
rows (catalog · a single course · a learner's own), and the live `#slHeroOut` (`aria-live`) reports the rung id +
name, ship date, the ROUTES at that rung, and the "what changed" line.

Pure functions over the fixed `RUNGS` dataset: `rungAt(n)` → record, `readoutFor(n)` → string, `isReconciled(n)`
(`n >= 5`) — drives whether the learner row reads `/courses/:user_id` (blue) or the reconciled `/my/courses`
(elixir-purple). `stopFromHash()` maps the hash to a stop (default 1). Static default (stop 1): F6.1 readout, the
learner row reads `GET /courses/:user_id (first-draft course page)`.

## Second interactive — routes then (F6.1) vs now (F6.6)

A `.solid-select` over `ROUTE_VIEWS` (`then` / `now`). `then`: catalog `GET /courses`, learner `GET /courses/:user_id`
(a course page for a given user). `now`: catalog `live "/courses"`, learner `GET /my/courses` (PROTECTED, over
`Portal.Enrollment`, the authenticated learner's own id, no path parameter — a learner cannot see another's). Pure
`routeView(k)`; live `#slMainOut`. Teaches a different move from the slider: the slider walks all six rungs; this
holds the two ends of the one reconcile side by side.

## The `.specref` chip mechanics (defined here; reused course-wide)

The page's JS also binds every `.specref` chip on the page (build-stamp mechanics, bound by **class** not id, so
multiple chips coexist): click / Enter / Space toggles `.open` + `aria-expanded`; clicking the inner `.sr-link`
still navigates (the handler bails when `ev.target.closest('.sr-link')`). The chip text is static markup; JS only
adds the toggle. The CSS lives in the shared `<style>` (`.specref`, `.sr-tip`, `.sr-desc`, `.sr-link`).

## The bridge

- **Principle** — a spec is a living document; version control records its content across iterations, so a wrong
  early decision is visible and the right repair is to edit the spec, not paper over it in code.
- **Portal practice** — the F6 web ladder is six shipped rungs; `/courses/:user_id` was reconciled away at F6.5 into
  `/my/courses`, and the catalog went live at `/courses` at F6.6.

## References

Sources (real, vetted): Specification by Example (`gojko.net`), Continuous Delivery (`continuousdelivery.com`), The
Pragmatic Programmer (`pragprog.com`). Related: `/spec`, `/spec/by-example`, `/spec/by-example/living-documentation`,
`/elixir/phoenix`.

## Pager

prev = `/course/agile-agent-workflow/spec`; next = `/course/agile-agent-workflow/spec/by-example`.
