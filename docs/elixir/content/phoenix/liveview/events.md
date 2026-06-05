# F6.06.2 — handle_event & state (dive)

- Route (served): `/elixir/phoenix/liveview/events`
- File: `elixir/phoenix/liveview/events.html`
- Place in the chapter: the second of the three F6.06 (LiveView) deep dives. With the initial assigns set in F6.06.1, this dive turns a browser event into new state via `handle_event/3` — the seam the rest of the chapter builds on (F6.06.3 sends only the changed assigns as a diff; F6.07 reuses the same `handle_*` family for PubSub broadcasts). It belongs to the "make it live" arc of Milestone 2.
- Accent: blue (F6 · Phoenix; `<h1 .ex>` word "state" in `--elixir-bright`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.06 · part 2 of 3`

`<h1>` (verbatim): handle_event & `state` (the word "state" is the `.ex` accent span).

Hero lede (`.lede`, verbatim):

> Interaction in LiveView is a message, not a request. A binding names the event; the socket carries it; `handle_event/3` returns new state.

Kicker (`.kicker`, verbatim):

> A page element is annotated with a **binding** — `phx-click`, `phx-change`, `phx-submit` — that names an event. The client sends that name and a map of params over the socket, and `handle_event/3` receives the three: the name, the params, and the socket. It transforms the assigns and returns `{:noreply, assign(socket, ...)}`; the changed state re-renders the view and the diff travels back, with no DOM code on either side. The discipline is the F5 one exactly — a message arrives, new state is computed, the new state is returned — so a search box that filters the catalog, a button that toggles a panel, and a form that creates a record are each one `handle_event` clause over the **same** `Portal` context from F6.04 and the **same** changeset from F6.03. The domain does not change; it is reached over a socket, and the result is a live UI without a page reload.

## Sections

Teaching sections in order:

1. `#bindings` — "Three bindings, one callback". Carries the binding-selector interactive.
2. `#flow` — "The event loop". A static SVG figure of `event → handle_event → assign → diff`.
3. `#search` — "A live search box, computed". Carries the live-filter interactive.
4. `#code` — "The handler in Elixir". Two `pre.code` blocks: the search clause + context, and the template form.
5. `#form` — "A live create form". A `pre.code` of the `"create"` clause branching on the closed result.
6. `#downstream` — "Why it matters downstream". A `.bridge` (F5 `handle_call`/`handle_cast` → LiveView `handle_event`).
7. `#recap` — "Recap". A `.deflist` of the bindings and callbacks, plus the closing `.note`.

Running example: a live search box bound `phx-change="search"` over a fixed seed of `Portal.list_courses/0` data, plus a live create form bound `phx-submit="create"` over `Portal.create_course/1`.

Real Elixir code shown:
- Search clause block — `@impl true`; `def handle_event("search", %{"q" => q}, socket) do {:noreply, assign(socket, courses: Portal.search_courses(q), query: q)} end`; `defdelegate search_courses(query), to: Portal.Catalog, as: :search`; `def search(query)` with `q = String.downcase(String.trim(query))` and `list_courses() |> Enum.filter(fn c -> String.contains?(String.downcase(c.title), q) end)`; closing comments `# Portal.Catalog.search("live") # => [%Course{title: "LiveView Patterns"}]` and `# Portal.Catalog.search("") # => all courses (an empty query matches every title)`.
- Template block — `<form phx-change="search">` with `<input type="text" name="q" value={@query} placeholder="Search courses" />`, then `<.course_card :for={course <- @courses} course={course} />`.
- Create clause block — `@impl true`; `def handle_event("create", %{"course" => params}, socket)` with a `case Portal.create_course(params)` matching `{:ok, _course}` (`put_flash(:info, "Course created")` then `assign(courses: Portal.list_courses(), query: "")`) and `{:error, %Ecto.Changeset{} = changeset}` (`assign(socket, form: to_form(changeset))`); closing comments `# valid params # => {:noreply, socket} (flash set, @courses reloaded, @query cleared)` and `# invalid params # => {:noreply, socket} (@form carries the changeset, inputs show errors)`.

## The interactives

### Figure 1 — "Event bindings · select one" (`#evSel` + `#evOut`)

- `<figure class="fig" aria-labelledby="evTitle">`; `<h4 id="evTitle">` text "Event bindings · select one".
- Control group `.solid-select#evSel` (role="group"), three buttons with `data-k`: `click` (starts `active`), `change`, `submit`. (No `data-c` attributes on these buttons.)
- SVG row ids: `#evRow_click`, `#evRow_change`, `#evRow_submit`. Below the figure: readout `.geo-readout#evOut`, plus `#evRole` (default `phx-click`) and `#evResult` (default `a click sends an event`).
- Pure function: `pick(k)` toggles the active button + `aria-pressed`, re-strokes the three rows (active gets `stroke #5a87c4`, width `2`, fill `#11203a`), and writes `#evRole`, `#evResult`, `#evOut`. Initial call `pick('click')`.
- `B` data (`name` / `fires` / `desc`, verbatim):
  - click: name `phx-click`, fires "a click sends an event", desc "A click on a bound element sends the named "toggle" event to handle_event/3, which updates assigns and re-renders — no onclick handler in JavaScript."
  - change: name `phx-change`, fires "input change sends an event", desc "phx-change="search" on a form sends the "search" event on every input change, with the field values as params. It is the binding behind live filtering and validation as the query is typed."
  - submit: name `phx-submit`, fires "form submit sends an event", desc "phx-submit="create" sends the "create" event when the form is submitted, with all field values. The handler calls the context and re-renders with the result or the changeset errors."
- `#evOut` default in markup (verbatim): "A click on a bound element sends the named "toggle" event to `handle_event/3`, which updates assigns and re-renders — no onclick handler in JavaScript."
- Degrade: the SVG and the default `#evOut` text render statically; `pick('click')` re-applies the default on load. No storage; `prefers-reduced-motion` respected globally.

### Figure 2 — "phx-change="search" · live filter over the catalog" (`#lsInput` + `#lsOut`)

- `<figure class="fig" aria-labelledby="lsTitle">`; `<h4 id="lsTitle">` text `phx-change="search" · live filter over the catalog`.
- Control: a real `<input id="lsInput" class="ls-input" type="text" name="q">` (placeholder "Search course titles…", `aria-controls="lsList lsOut"`), with a `.ls-binding` label "phx-change="search"".
- Element ids: result list `#lsList` (seeded with six `.ls-card` rows); readout `.geo-readout#lsOut`. Default `#lsOut` (verbatim): `query "" · 6 of 6 courses match — the full catalog, before any keystroke`. A static line below names the handler: `handle_event("search", %{"q" => q}, socket)` → `assign(socket, courses: Portal.search_courses(q), query: q)`.
- Seed (`COURSES`, `title` / `published`): "Functional Foundations" (true), "Processes & OTP" (true), "Phoenix in Practice" (true), "Ecto & Persistence" (false), "LiveView Patterns" (false), "Pattern Matching Deep Dive" (true). The `published` flag drives the F6.05.2 `course_card` "Published" badge.
- Pure functions: `searchCourses(query)` — the JavaScript mirror of `Portal.Catalog.search/1`, a case-insensitive substring match on the title (`q = String(query).trim().toLowerCase()`, then `COURSES.filter(... indexOf(q) !== -1)`); `renderSearch(query)` rebuilds `#lsList` and writes `#lsOut`. Wired on the input's `input` event; called once on load to sync to the static markup.
- Readout strings (`renderSearch`, verbatim): empty-query tail " match — the full catalog, before any keystroke"; non-empty tail " match the typed query"; the output is `query <span>{shown}</span> · <b>{hits}</b> of {COURSES.length} courses{tail}`. The no-match list message: `no course title contains "{query}" — handle_event re-assigns an empty @courses`.
- Degrade: the six static `.ls-card` rows and the default `#lsOut` ("6 of 6") render without JS; `renderSearch` enhances on load. No browser storage; `prefers-reduced-motion` respected globally.

### Footer build-stamp decoder (`#stamp`)

- Stamp id `TSK0NdUKuHerp2` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-01 23:06:46 UTC".
- Decoded: `ns=TSK`, `snowflake=319975090689146880`, `node=0`, `seq=0`, timestamp `2026-06-01 23:06:46 UTC` (epoch `EPOCH_MS = 1704067200000`).
- Functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` (`ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`). Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (#refs, verbatim)

Intro line: "Primary sources for the bindings and the event callback, and where this dive connects in the course."

Sources
- `https://hexdocs.pm/phoenix_live_view/bindings.html` — Phoenix LiveView — Bindings — `phx-click`, `phx-change`, `phx-submit`.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_event/3` — `handle_event/3` — Phoenix.LiveView — the callback contract and return values.
- `https://hexdocs.pm/phoenix_live_view/form-bindings.html` — Phoenix LiveView — Form bindings — live validation and submission with `to_form/1`.

Related in this course
- `/elixir/phoenix/liveview` — F6.06 · Phoenix LiveView fundamentals
- `/elixir/phoenix/liveview/mount` — F6.06.1 · mount & assigns — where `@courses` and `@query` are first set.
- `/elixir/phoenix/liveview/render` — F6.06.3 · render & diffs — how a re-assign becomes a diff.
- `/elixir/phoenix/contexts` — F6.04 · Contexts — the catalog the handler calls.

## Wiring

- route-tag (verbatim, segmented): `/` `elixir` `/` `phoenix` `/` `liveview` `/` `events` (the `events` segment is the current `.rcur`; `elixir`, `phoenix`, `liveview` are links).
- crumbs (verbatim): `F6` → `/elixir/phoenix` · sep `/` · `F6.06` → `/elixir/phoenix/liveview` · sep `/` · here `events` (no link).
- toc-mini: `#bindings` ("Three bindings") · `#flow` ("The event loop") · `#search` ("A live search box") · `#code` ("The handler in Elixir") · `#downstream` ("Why it matters").
- pager: prev → `/elixir/phoenix/liveview/mount` ("← F6.06.1 · mount & assigns"); next → `/elixir/phoenix/liveview/render` ("Next · render & diffs →").
- footer (`.foot-nav`, three columns):
  - brand: `.foot-logo` → `/elixir`; `.foot-tag` "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters: `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix` (F1–F6, same labels as the hub).
  - The course: `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta: `<title>` "handle_event & state — F6.06.2 · jonnify"; `<meta description>` "Bindings like phx-click, phx-change, and phx-submit send events to handle_event/3, which transforms the socket assigns and returns {:noreply, socket}. A live search box filtering the course list and a live create form reuse the same Portal contexts and changesets from F6.04 and F6.05, each event re-rendering the process with no page reload."

## Build instruction

To rebuild this page, copy the `<head>`…`</style>`, `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT F6 (blue-accent) dive, then change only the `<title>`/`<meta description>`, the segmented `.route-tag`, and the `<main>` body. The model sibling is `/elixir/phoenix/liveview/mount` (`elixir/phoenix/liveview/mount.html`) — the same lesson-hero `.lede`/`.kicker`, the same blue accent, and the same deeper-standard section anatomy (it adds a `.ls-input` live-filter shell, which `mount`'s `.fold-ctrl` slider does not, so reuse the `.solid-select`/`.geo-readout` shells already in the shared `<style>`). No-invent guards: use only the real Portal surfaces as written — `Portal.search_courses/1` (`defdelegate … to: Portal.Catalog, as: :search`), `Portal.list_courses/0`, `Portal.create_course/1`, `Portal.Catalog`, the `%Ecto.Changeset{}`/`to_form/1`/`put_flash` and `phx-click`/`phx-change`/`phx-submit`/`handle_event/3` LiveView surfaces, and the F6.05.2 `course_card` component — over the branded store / one-facade / event-sourced engine model; cite the F5 companion for `handle_call`/`handle_cast` GenServer internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
