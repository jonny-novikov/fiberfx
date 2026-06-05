# F6.05.2 — Function components & slots (dive)

- Route (served): `/elixir/phoenix/heex/components`
- File: `elixir/phoenix/heex/components.html`
- Place in the chapter: the second of the three F6.05 dives (part 2 of 3). It follows F6.05.1 (templates & assigns), turning the `<li>` markup written once into a reusable `<.course_card>`, and hands off to F6.05.3 (forms & inputs), where Phoenix ships `<.form>` and `<.input>` as components exactly like these.
- Accent: blue (F6 chapter accent; `<h1>` highlight `slots` carries `.ex` elixir-purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F6.05 · part 2 of 3`

`<h1>`: Function components & `slots`

Hero lede (verbatim):

> A function component is the smallest reusable unit of markup, and it is exactly what its name says: a **function from assigns to a rendered template**. You define `def course_card(assigns)`, return a `~H` block, and call it in any template as `<.course_card course={course} />` — the leading dot marks a local component. What makes it more than a partial is its **typed interface**: `attr :course, :map, required: true` declares an input, and the compiler warns when a caller forgets it or passes an unknown attribute. A **slot** declares a hole the caller fills with content — `render_slot(@inner_block)` drops that content into place — so a component can wrap as well as render. The payoff is the same as extracting a function anywhere: the `<li>` you wrote once in F6.05.1 becomes a single `<.course_card>` used in the index, the search results, and the dashboard, and a change to the card is a change in one place.

Kicker (verbatim):

> Four parts: the three building blocks of a component, the interface it presents, a real card component in code, and composing it across templates with a slot.

## Sections

In order (four sections, two figures + two code blocks; HEEx fully escaped):

1. `#what` "Three building blocks" — `attr`, `slot`, `render_slot/1`. Carries the `#fcSel` interactive. Takeaway: declaring `attr` is the difference between a component and a bare partial.
2. `#interface` "The component interface" — two channels in (attrs + slot), one out (markup); attrs validated at compile time. Carries the static `#fcIntTitle` figure. Takeaway: because the interface is explicit, a component is documentation.
3. `#code` "A real component" — the running example: the `course_card` component. First `pre.code` block (Elixir + HEEx, escaped).
4. `#compose` "Composing and slots" — the F6.05.1 list collapses to one `<.course_card :for=...>`; a `panel` slot wrapper. Second `pre.code` block + a `.bridge`.

Running example: the reusable `course_card` component and a slot-based `panel`.

Real Elixir/HEEx code shown (verbatim, `#code`):
```
# in PortalWeb.CatalogComponents — `use Phoenix.Component`
attr :course, :map, required: true
attr :class, :string, default: ""

def course_card(assigns) do
  ~H"""
  <article class={["card", @class]}>
    <h3>{@course.title}</h3>
    <p :if={@course.published} class="badge">Published</p>
  </article>
  """
end
```

Real Elixir/HEEx code shown (verbatim, `#compose`):
```
<%!-- the F6.05.1 list, now one reusable component per row --%>
<ul>
  <.course_card :for={course <- @courses} course={course} />
</ul>

# a slot-based wrapper component
slot :inner_block, required: true

def panel(assigns) do
  ~H"""
  <section class="panel">{render_slot(@inner_block)}</section>
  """
end
#   call it:  <.panel><p>anything here</p></.panel>
```

## The interactives

### `#what` figure — "Component building blocks · select one" (`#fcTitle` / `#fcSel`)

- `<figure class="fig" aria-labelledby="fcTitle">`, `<h4 id="fcTitle">` = "Component building blocks · select one".
- Control group `.solid-select#fcSel` (role="group", `aria-label="Component building block"`), three buttons (no `data-c`):
  - `data-k="attr"` — label "attr" — starts `active`
  - `data-k="slot"` — label "slot"
  - `data-k="render"` — label "render_slot"
- SVG (`viewBox="0 0 720 170"`) rect ids: `#fcRow_attr`, `#fcRow_slot`, `#fcRow_render`.
- Readouts: `.geo-readout#fcOut` (`aria-live="polite"`), `#fcRole`, `#fcResult`.
- Pure function: `pick(k)` over `B {attr, slot, render}` — toggles each `#fcSel` button's `active` + `aria-pressed`; sets each row's `stroke`/`stroke-width`/`fill` (on = `#5a87c4`/`2`/`#11203a`, off = `#3a4263`/`1.3`/`#10162b`); writes `x.name` to `#fcRole`, `x.is` to `#fcResult`, and `'<b>…</b> — ' + x.is + '. ' + x.desc` to `#fcOut`. `ORDER = ['attr','slot','render']`; initial `pick('attr')`.
- `B` data (verbatim `name`/`is`/`desc`):
  - attr: name "attr", is "a typed, checked input", desc "attr :course, :map, required: true declares an input with a type and options. The compiler warns when a caller omits a required attr or passes one you never declared."
  - slot: name "slot", is "a placeholder for content", desc "slot :inner_block declares a region the caller fills with markup between the component tags. Named slots let a component accept several distinct content regions."
  - render: name "render_slot/1", is "fill the slot", desc "render_slot(@inner_block) drops the caller-supplied content into place. It is how a component wraps rather than only renders — the basis of layout and panel components."
- Static labels in the readout block: `block: attr`, `is: a typed, checked input`.
- Degrade: default `attr` state is set by `pick('attr')` on load; the static SVG already shows `#fcRow_attr` highlighted. No browser storage. `prefers-reduced-motion` respected globally (no figure animation).

### `#interface` figure — "attrs + slot → component → markup" (`#fcIntTitle`)

A static `<figure class="fig" aria-labelledby="fcIntTitle">` (`viewBox="0 0 720 188"`). No controls, no readout; ATTRS + SLOT feed into `course_card(assigns)` (attrs validated at compile time, `render_slot` fills the hole) which returns MARKUP, with the caption "attrs are checked; the slot is optional content; the output is plain escaped markup".

### Footer build-stamp decoder (`#stamp`)

- Stamp id `#stampId` = `TSK0NdT0reR9xA`; panel `#st-ts` hard-codes "2026-06-01 22:48:15 UTC".
- Decoded: namespace `TSK`, snowflake `319970430658019328`, node `0`, seq `0`, timestamp `2026-06-01 22:48:15 UTC` (matches the hard-coded value).
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` (`ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, `EPOCH_MS = 1704067200000`). Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (#refs, verbatim)

This dive has no `#refs` / References section. The chapter's References block lives on the F6.05 hub (`/elixir/phoenix/heex`). The dive carries an inline `.note` at the end of `#compose` (verbatim): "Next: **forms & inputs** — Phoenix ships `<.form>` and `<.input>` as components exactly like these, backed by a changeset." (link → `/elixir/phoenix/heex/forms`).

## Wiring

- route-tag (verbatim, segmented): `/ elixir / phoenix / heex / components` — `<a href="/elixir">elixir</a>` / `<a href="/elixir/phoenix">phoenix</a>` / `<a href="/elixir/phoenix/heex">heex</a>` / `<span class="rcur">components</span>`.
- crumbs: `F6` → `/elixir/phoenix` · sep `/` · `F6.05` → `/elixir/phoenix/heex` · sep `/` · here `components` (no link).
- toc-mini: `#what` ("Three building blocks") · `#interface` ("The component interface") · `#code` ("A real component") · `#compose` ("Composing and slots").
- pager: prev → `/elixir/phoenix/heex/templates` ("← F6.05.1 · templates & assigns"); next → `/elixir/phoenix/heex/forms` ("Next · forms & inputs →").
- footer (3-column `foot-nav`): Brand → `/elixir` + the standard tag; Chapters column `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`; The course column `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01"). Header brand → `/elixir`; header nav `Contents` → `/elixir/course`.
- Page meta: `<title>` "Function components & slots — F6.05.2 · jonnify"; `<meta description>` "A function component is a pure function from assigns to markup, declared with attr and slot so its inputs are validated at compile time. One <.course_card> replaces copied markup across templates, and render_slot/1 lets a component wrap caller-supplied content."

## Build instruction

To (re)build this dive, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent built F6.05 dive on the blue accent, then change only the `<title>`/`<meta description>`, the segmented `.route-tag`, and the `<main>` body. Use the lesson-hero `.lede` styling (upright, not the italic landing deck). No-invent guards: show only the real Portal surfaces as written — the branded store, the event-sourced engine behind the one `Portal` facade, and the Phoenix web app; name `attr`, `slot`, `render_slot/1`, `~H`, `<.course_card>`, `<.panel>`, and `%Course{}` only as the live page uses them, and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/phoenix/heex/templates.html` (F6.05.1, blue accent — the same four-section dive shape, `.solid-select` selector figure, static second figure, two `pre.code` blocks, identical header/footer/scripts).
