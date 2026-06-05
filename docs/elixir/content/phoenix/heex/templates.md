# F6.05.1 — Templates & assigns (dive)

- Route (served): `/elixir/phoenix/heex/templates`
- File: `elixir/phoenix/heex/templates.html`
- Place in the chapter: the first of the three F6.05 dives (part 1 of 3), in the arc write → slice → order at the module level — here, the view's single input. It teaches that a HEEx template is a pure function of its assigns, and hands off to F6.05.2 (function components & slots), the natural next step once the `<li>` markup is a candidate for extraction.
- Accent: blue (F6 chapter accent; `<h1>` highlight `assigns` carries `.ex` elixir-purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F6.05 · part 1 of 3`

`<h1>`: Templates & `assigns`

Hero lede (verbatim):

> A HEEx template has exactly one input: its **assigns**. The controller builds a map — `%{courses: [...]}` — and the template reads it through `@courses`, which is sugar for `assigns.courses`. Everything the template can show comes from that map; it does not call a context, query a table, or reach into process state. That constraint is what makes a template a **pure function of its assigns** — same assigns, same HTML — and it is the property F6.06 will exploit to render only what changed. Inside the markup you have three workhorses: curly **interpolation** to render a value, the `:for` attribute to loop over a list, and the `:if` attribute to show markup conditionally. Values are **HTML-escaped by default**, so a course title containing a tag is shown as text, not executed — the cross-site-scripting hole closes without you doing anything. Links use the verified `~p` sigil from F6.02, so a typo in a route path is a compile error rather than a broken anchor.

Kicker (verbatim):

> Four parts: the constructs a template uses, how an assign becomes rendered markup, a real index template, and the discipline that keeps queries out of it.

## Sections

In order (four sections, two teaching figures + two code blocks; HEEx fully escaped):

1. `#use` "Three constructs" — interpolation, `:for`, `:if`. Carries the `#tpSel` interactive. Takeaway: `:for` and `:if` are attributes on a real element, not block tags.
2. `#render` "An assign, rendered" — `@courses` (a list of two structs) → `:for` → a static `<ul>` with dynamic contents. Carries the static `#tpRenderTitle` figure. Takeaway: an assign is the whole contract between controller and template.
3. `#code` "A real template" — the running example: an `index.html.heex` for the catalog. First `pre.code` block (HEEx, escaped).
4. `#data` "Where the data comes from" — fetch in the controller through `Portal`, render in the template; a query in HEEx welds markup to storage. Second `pre.code` block (Elixir, RIGHT/WRONG contrast) + a `.bridge`.

Running example: the catalog index template over `@courses`.

Real Elixir/HEEx code shown (verbatim, `#code`):
```
<%!-- lib/portal_web/controllers/course_html/index.html.heex --%>
<h1>Courses</h1>

<ul class="courses">
  <li :for={course <- @courses} class="course">
    <.link navigate={~p"/courses/#{course.id}"}>{course.title}</.link>
    <span :if={course.published} class="badge">published</span>
  </li>
</ul>

<p :if={@courses == []}>No courses yet.</p>
```

Real Elixir code shown (verbatim, `#data`, the controller fetch contrast):
```
# RIGHT — the controller fetches through the facade; the template only renders
def index(conn, _params) do
  render(conn, :index, courses: Portal.list_courses())   # assign from the facade
end

# WRONG — a query inside the template couples markup to storage and the DB
#   <li :for={c <- Portal.Repo.all(Course)}>{c.title}</li>
# the template should receive @courses, never build the list itself
```

## The interactives

### `#use` figure — "HEEx constructs · select one" (`#tpTitle` / `#tpSel`)

- `<figure class="fig" aria-labelledby="tpTitle">`, `<h4 id="tpTitle">` = "HEEx constructs · select one".
- Control group `.solid-select#tpSel` (role="group", `aria-label="HEEx construct"`), three buttons (no `data-c`):
  - `data-k="interp"` — label "interpolation" — starts `active`
  - `data-k="for"` — label ":for"
  - `data-k="if"` — label ":if"
- SVG (`viewBox="0 0 720 170"`) rect ids: `#tpRow_interp`, `#tpRow_for`, `#tpRow_if`.
- Readouts: `.geo-readout#tpOut` (`aria-live="polite"`), `#tpRole`, `#tpResult`.
- Pure function: `pick(k)` over `C {interp, for, if}` — toggles each `#tpSel` button's `active` + `aria-pressed`; sets each row's `stroke`/`stroke-width`/`fill` (on = `#5a87c4`/`2`/`#11203a`, off = `#3a4263`/`1.3`/`#10162b`); writes `x.name` to `#tpRole`, `x.does` to `#tpResult`, and `'<b>…</b> — ' + x.does + '. ' + x.desc` to `#tpOut`. `ORDER = ['interp','for','if']`; initial `pick('interp')`.
- `C` data (verbatim `name`/`does`/`desc`):
  - interp: name "Interpolation", does "render an assign's value", desc "Curly braces render an expression into the markup — {course.title}. The value is HTML-escaped by default, so a title with a tag in it is shown as text, not executed."
  - for: name ":for", does "loop over a list", desc ":for={course <- @courses} repeats the element it is on once per item in a list assign — the HEEx way to render a collection, with no surrounding block tag."
  - if: name ":if", does "show markup conditionally", desc ":if={course.published} includes the element only when the condition is truthy. An attribute on the node itself, so the markup still reads as HTML."
- Static labels in the readout block: `construct: Interpolation`, `does: render an assign's value`.
- Degrade: default `interp` state is set by `pick('interp')` on load; the static SVG already shows `#tpRow_interp` highlighted. No browser storage. `prefers-reduced-motion` is respected globally (scroll + reveal only; this figure has no animation).

### `#render` figure — "@courses → :for → rendered list" (`#tpRenderTitle`)

A static `<figure class="fig" aria-labelledby="tpRenderTitle">` (`viewBox="0 0 720 178"`). No controls, no readout; three boxes (`@courses` assign → TEMPLATE applies `:for` → rendered `<li>OTP</li>` / `<li>Ecto</li>`) with the caption "the static list shell is compiled once; only the titles vary per render".

### Footer build-stamp decoder (`#stamp`)

- Stamp id `#stampId` = `TSK0NdT0r4fhZ2`; panel `#st-ts` hard-codes "2026-06-01 22:48:15 UTC".
- Decoded: namespace `TSK`, snowflake `319970430129537024`, node `0`, seq `0`, timestamp `2026-06-01 22:48:15 UTC` (matches the hard-coded value).
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` (`ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, `EPOCH_MS = 1704067200000`). Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (#refs, verbatim)

This dive has no `#refs` / References section. The chapter's References block lives on the F6.05 hub (`/elixir/phoenix/heex`). The dive instead carries an inline `.note` at the end of `#data` (verbatim): "Next: **function components & slots** — the `<li>` markup above is a candidate to extract into a reusable `<.course_card>`." (link → `/elixir/phoenix/heex/components`).

## Wiring

- route-tag (verbatim, segmented): `/ elixir / phoenix / heex / templates` — `<a href="/elixir">elixir</a>` / `<a href="/elixir/phoenix">phoenix</a>` / `<a href="/elixir/phoenix/heex">heex</a>` / `<span class="rcur">templates</span>`.
- crumbs: `F6` → `/elixir/phoenix` · sep `/` · `F6.05` → `/elixir/phoenix/heex` · sep `/` · here `templates` (no link).
- toc-mini: `#use` ("Three constructs") · `#render` ("An assign, rendered") · `#code` ("A real template") · `#data` ("Where the data comes from").
- pager: prev → `/elixir/phoenix/heex` ("← F6.05 · overview"); next → `/elixir/phoenix/heex/components` ("Next · function components & slots →").
- footer (3-column `foot-nav`): Brand → `/elixir` + the standard tag; Chapters column `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`; The course column `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01"). Header brand → `/elixir`; header nav `Contents` → `/elixir/course`.
- Page meta: `<title>` "Templates & assigns — F6.05.1 · jonnify"; `<meta description>` "A HEEx template renders the assigns a controller set — @courses, @course — using :for and :if as attributes, curly interpolation for values, and verified ~p routes for links. The template holds no business logic and never queries the database; it is a pure function of its assigns."

## Build instruction

To (re)build this dive, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent built F6.05 dive on the blue accent, then change only the `<title>`/`<meta description>`, the segmented `.route-tag`, and the `<main>` body. Use the lesson-hero `.lede` styling (upright, not the italic landing deck). No-invent guards: show only the real Portal surfaces as written — the branded store, the event-sourced engine behind the one `Portal` facade, and the Phoenix web app; name `Portal.list_courses()`, `~p`, `:for`, `:if`, `<.link>`, and `%Course{}` only as the live page uses them, and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/phoenix/heex/components.html` (F6.05.2, blue accent — the same four-section dive shape with `#tpSel`-style `.solid-select` interactive, two figures, two `pre.code` blocks).
