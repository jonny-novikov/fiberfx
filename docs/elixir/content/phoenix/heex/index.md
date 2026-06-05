# F6.05 — Templates, components & HEEx (module hub)

- Route (served): `/elixir/phoenix/heex`
- File: `elixir/phoenix/heex/index.html`
- Place in the chapter: the fifth module of F6 · Phoenix Framework — the view layer. It follows F6.04 (`/elixir/phoenix/contexts`) and frames three dives — templates and assigns, function components and slots, and forms and inputs — rendering the data the contexts expose, never the database directly. The next module, F6.06, makes these same templates live with LiveView.
- Accent: blue (the F6 chapter accent; `<h1>` highlight word `HEEx` carries `.ex` elixir-purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F6 · the architecture · module 5`

`<h1>`: Templates, components & `HEEx`

Hero lede (verbatim):

> F6.01 ended with a controller returning a response; HEEx is how that response becomes HTML. **HEEx** — HTML+EEx, written in the `~H` sigil or a `.html.heex` file — is a template language that compiles to a structure the server can render and, later, diff. A template is a **pure function of its assigns**: the controller sets `@courses` from data the `Catalog` context exposed, and the template renders it with `:for`, `:if`, and curly interpolation. Repeated markup becomes a **function component** — a function from assigns to markup, declared with `attr` and `slot` so its inputs are checked at compile time. And a **form** is a changeset turned into a form, so the F6.03 validation surfaces as inline errors and the submitted params flow back to the context. HEEx also escapes interpolated values by default, which closes the most common injection hole without any ceremony.

Kicker (verbatim):

> Three dives: templates and the assigns they render, function components and slots, and changeset-backed forms — the view half of everything the controllers and contexts already built.

## What the page frames

The landing has no `.mods` grid; the three children are presented as full-width dive cards in the `#dives` section (each an `<a>` with a coloured left border). All three are built and published.

- F6.05.1 · Templates & assigns — the `~H` sigil, rendering `@assigns` with `:for` and `:if`, curly interpolation, and verified `~p` routes. Route: `/elixir/phoenix/heex/templates`. Built. (left border `--blue`)
- F6.05.2 · Function components & slots — `attr` and `slot`, a reusable `<.course_card>`, and `render_slot/1` for wrapping content. Route: `/elixir/phoenix/heex/components`. Built. (left border `--gold`)
- F6.05.3 · Forms & inputs — `to_form/1` over a changeset, `<.form>` and `<.input>`, and F6.03 errors shown inline. Route: `/elixir/phoenix/heex/forms`. Built. (left border `--sage`)

Two framing teaching sections precede the dives:

- `#pieces` "Three pieces of the view" — a template renders assigns, a component is reusable markup with a typed interface, a form is a changeset rendered for editing. Carries the `#hxSel` interactive.
- `#pipeline` "Where the view sits" — the view receives data, it does not fetch it. Carries the `facade → assigns → HEEx → HTML` figure (`#hxPipeTitle`, static, no controls).

The `#dives` section closes with a `.bridge` ("F6.01 returned" → "F6.05 renders it") and a `.note` pointing the reader at the three dives in order, naming F6.04 (`/elixir/phoenix/contexts`) as the predecessor and F6.06 as the next module.

## The interactives

### Hero figure — "Assigns render into markup" (`#hpTitle` / `#hpScene`)

- `<figure class="hero-fig" aria-labelledby="hpTitle">`, `.fc-lbl#hpTitle` = "Assigns render into markup".
- SVG (`viewBox="0 0 320 312"`) maps the `@course` assigns block into a `<.course_card course={@course} />` call, then into a rendered HTML card. Tspan/text ids: `#hpAsgTitle`, `#hpAsgLessons` (the assigns), `#hpOutTitle`, `#hpOutLessons` (the rendered card), wrapped in `.hp-rendered`.
- Controls (`.hp-ctrls`): `<button id="hpNext">▸ next assigns</button>`, `<button id="hpReset" class="ghost">reset</button>` (no `data-k`; plain id buttons).
- Pure functions: `render(i, prev)` swaps the assigns to `STATES[i]` and flashes (via `flash(el)`, which removes/re-adds `hp-changed` to restart the animation) only the spans whose assign differs from the previous state; `flash(el)` forces reflow with `getBBox()`. `STATES` array: `{title:'Algebra', lessons:6}`, `{title:'Functional', lessons:6}`, `{title:'Functional', lessons:9}`, `{title:'Phoenix', lessons:12}`.
- Caption `#hpCap` (`aria-live="polite"`), default in markup (verbatim):
  - `@course = %{title: "Algebra", lessons: 6}`
  - `Change one assign and only the markup that reads it re-renders.`
- The `render` note string is chosen by which assign changed (verbatim): "Both assigns changed — both bound spans re-render." · "Only the title changed — the lessons count is left untouched." · "Only the lessons count changed — the heading is left untouched." · "Change one assign and only the markup that reads it re-renders."
- Degrade: the static SVG already shows state 0 (`Algebra` / `6`) rendered into the card; there is no render on load. `prefers-reduced-motion: reduce` disables `.hp-rendered` transition and the `hp-changed` animation. No browser storage.

### `#pieces` figure — "The view layer · select a piece" (`#hxTitle` / `#hxSel`)

- `<figure class="fig" aria-labelledby="hxTitle">`, `<h4 id="hxTitle">` = "The view layer · select a piece".
- Control group `.solid-select#hxSel` (role="group", `aria-label="View piece"`), three buttons (no `data-c`; default to cream-soft active):
  - `data-k="template"` — label "template" — starts `active`
  - `data-k="component"` — label "component"
  - `data-k="form"` — label "form"
- SVG (`viewBox="0 0 720 170"`) rect ids: `#hxRow_template` (tagged F6.05.1), `#hxRow_component` (F6.05.2), `#hxRow_form` (F6.05.3).
- Readouts: `.geo-readout#hxOut` (`aria-live="polite"`), `#hxRole`, `#hxResult`.
- Pure function: `pick(k)` over `PIECES {template, component, form}` — toggles each `#hxSel` button's `active` class + `aria-pressed`; for each row sets `stroke`/`stroke-width`/`fill` (on = `#5a87c4`/`2`/`#11203a`, off = `#3a4263`/`1.3`/`#10162b`); writes `P.name` to `#hxRole`, `P.is` to `#hxResult`, and `'The <b>…</b> piece — ' + P.is + '. ' + P.desc` to `#hxOut`. `ORDER = ['template','component','form']`; initial call `pick('template')`.
- `PIECES` data (verbatim `name`/`is`/`desc`):
  - template: name "Template", is "render the assigns", desc "A ~H sigil or .html.heex file that renders the assigns a controller set — @courses, @course — with :for, :if, and curly interpolation. A pure function of its assigns, with no data access of its own."
  - component: name "Component", is "reuse markup", desc "A function from assigns to markup, declared with attr and slot so its inputs are validated at compile time. One <.course_card> replaces markup copied across templates."
  - form: name "Form", is "a changeset, rendered", desc "to_form/1 turns a changeset into a form; <.form> and <.input> render the fields and surface the F6.03 validation errors inline. Submitted params flow back to the context."
- Static labels in the readout block: `piece: Template`, `is: render the assigns`.

### `#pipeline` figure — "facade → assigns → HEEx → HTML" (`#hxPipeTitle`)

A static `<figure class="fig" aria-labelledby="hxPipeTitle">` (`viewBox="0 0 720 168"`). No controls, no readout; four boxes (`Portal facade` → `controller` → `HEEx template` → `HTML`) with the caption "the template receives assigns and renders — it never queries the database". Not JS-driven.

### Footer build-stamp decoder (`#stamp`)

- Stamp id `#stampId` = `TSK0NdT0qiFOHw`; panel `#st-ts` hard-codes "2026-06-01 22:48:15 UTC".
- Decoded: namespace `TSK`, snowflake `319970429798187008`, node `0`, seq `0`, timestamp `2026-06-01 22:48:15 UTC` (matches the hard-coded value).
- Pure functions: `b62decode(s)` (base62 over `"0123…XYZabc…xyz"` → BigInt); `pad2(x)`; `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`. Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (#refs, verbatim)

Intro line: "HEEx, function components, and forms in reference form."

**Sources**
- [Phoenix — Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) — the `~H` sigil, `attr`, and `slot`.
- [Phoenix — Components and HEEx](https://hexdocs.pm/phoenix/components.html) — templates and function components in a Phoenix app.
- [Phoenix — HTML.Form](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html) — the form data structure behind `<.form>`.
- [Phoenix — Form bindings](https://hexdocs.pm/phoenix_live_view/form-bindings.html) — forms, changesets, and inputs.

**Related in this course**
- [F6.05.1 · Templates & assigns](/elixir/phoenix/heex/templates)
- [F6.05.2 · Function components & slots](/elixir/phoenix/heex/components)
- [F6.05.3 · Forms & inputs](/elixir/phoenix/heex/forms)
- [F6.03.2 · Changesets](/elixir/phoenix/ecto/changesets) — what a form renders.
- [F6 · Phoenix Framework](/elixir/phoenix)

## Wiring

- route-tag (verbatim, segmented): `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/phoenix">phoenix</a><span class="rsep">/</span><span class="rcur">heex</span>` — `/ elixir / phoenix / heex`.
- crumbs: `F6 · Phoenix Framework` → `/elixir/phoenix` · sep `/` · here `F6.05 · heex` (no link).
- toc-mini: `#pieces` ("Three pieces of the view") · `#pipeline` ("Where the view sits") · `#dives` ("Three deep dives").
- pager: prev → `/elixir/phoenix/contexts` ("← F6.04 · contexts"); next → `/elixir/phoenix/heex/templates` ("Start · templates & assigns →").
- footer (3-column `foot-nav`):
  - Brand column: `.foot-logo` → `/elixir`; tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters column: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course column: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
  - Header brand `.brand` → `/elixir`; header nav `Contents` → `/elixir/course`.
- Page meta: `<title>` "Templates, components & HEEx — F6.05 · jonnify"; `<meta description>` "HEEx is the view half of the request a controller returns: a template renders the assigns the controller set, function components make markup reusable and compile-checked, and forms are backed by changesets. Three dives: templates and assigns, function components and slots, and forms and inputs — all rendering data the contexts expose, never the database directly."

## Build instruction

To (re)build this hub, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent built F6 sibling on the blue accent — the model page is `elixir/phoenix/heex/index.html` itself (this hub), or another F6 module hub such as `elixir/phoenix/contexts/index.html`. Change only the `<title>`/`<meta description>`, the segmented `.route-tag`, the crumbs/eyebrow/`<h1>`/lede/kicker, the `#pieces` and `#pipeline` figures, the `#dives` card trio, the `#refs` block, the pager, and the build stamp id. No-invent guards: render only the real Portal surfaces as written — the branded store, the event-sourced engine behind the one `Portal` facade, and the Phoenix web app; name `Catalog`, `~p`, `to_form/1`, `<.course_card>`, `render_slot/1`, and `%Ecto.Changeset{}` only as the live pages use them, and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/phoenix/heex/index.html` (this module hub, blue accent).
