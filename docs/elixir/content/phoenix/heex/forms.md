# F6.05.3 — Forms & inputs (dive)

- Route (served): `/elixir/phoenix/heex/forms`
- File: `elixir/phoenix/heex/forms.html`
- Place in the chapter: the third and final F6.05 dive (part 3 of 3), the point where the view layer hands control back to the domain. It follows F6.05.2 (function components & slots) — `<.form>` and `<.input>` are components exactly like the ones built there — and closes the module; the next module, F6.06 (LiveView), makes these same templates live over a socket.
- Accent: blue (F6 chapter accent; `<h1>` highlight `inputs` carries `.ex` elixir-purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F6.05 · part 3 of 3`

`<h1>`: Forms & `inputs`

Hero lede (verbatim):

> A form is where the view layer hands control back to the domain, and Phoenix builds it on the changeset you already wrote in F6.03. `to_form/1` wraps a changeset in a `%Phoenix.HTML.Form{}` — a structure that knows the field names, their current values, and any errors. `<.form for={@form}>` renders the `<form>` element with a CSRF token included automatically, and `<.input field={@form[:title]}>` renders one field, reading its value and its errors straight off the form. The loop closes on submit: the params arrive at a controller action, which calls the context's `create_course/1`; on `{:ok, course}` you redirect, and on `{:error, changeset}` you call `to_form` on the invalid changeset and re-render — now the inputs show the F6.03 validation messages inline. You write the changeset once; it powers both the write and the form's error display. The CSRF token and HTML escaping are handled for you, so the common security mistakes are closed by default.

Kicker (verbatim):

> Four parts: the three building blocks of a form, the round trip from changeset to submit and back, a real form in code, and how validation errors reach the screen.

## Sections

In order (four sections, two figures + two code blocks; HEEx fully escaped):

1. `#parts` "Three building blocks" — `to_form/1`, `<.form>`, `<.input>`. Carries the `#fmSel` interactive. Takeaway: `<.input>` is itself a function component with declared attrs — the kind built in F6.05.2.
2. `#cycle` "The form round trip" — changeset → form → submit → context → ok | errors; success redirects, failure re-wraps and re-renders. Carries the static `#fmCycleTitle` figure. Takeaway: the error path returns to the same template with the same form variable.
3. `#code` "A real form" — the running example: the `new` action and `new.html.heex`. First `pre.code` block (Elixir + HEEx, escaped).
4. `#errors` "How errors reach the screen" — the `create` action; `{:ok}` redirects, `{:error, changeset}` re-renders with errors inline. Second `pre.code` block + a `.bridge`.

Running example: the course create form — the `new` and `create` controller actions over the `Catalog` context.

Real Elixir/HEEx code shown (verbatim, `#code`):
```
# controller — build a form from a changeset (F6.03)
def new(conn, _params) do
  changeset = Catalog.change_course(%Course{})
  render(conn, :new, form: to_form(changeset))
end

<%!-- new.html.heex — render the form and its inputs --%>
<.form for={@form} action={~p"/courses"}>
  <.input field={@form[:title]} label="Title" />
  <.input field={@form[:published]} type="checkbox" label="Published" />
  <.button>Save</.button>
</.form>
```

Real Elixir code shown (verbatim, `#errors`):
```
# create — params flow to the context; an invalid changeset re-renders with errors
def create(conn, %{"course" => params}) do
  case Catalog.create_course(params) do
    {:ok, course} ->
      conn
      |> put_flash(:info, "Course created")
      |> redirect(to: ~p"/courses/#{course.id}")

    {:error, %Ecto.Changeset{} = changeset} ->
      render(conn, :new, form: to_form(changeset))   # errors now on the form
  end
end
```

## The interactives

### `#parts` figure — "Form building blocks · select one" (`#fmTitle` / `#fmSel`)

- `<figure class="fig" aria-labelledby="fmTitle">`, `<h4 id="fmTitle">` = "Form building blocks · select one".
- Control group `.solid-select#fmSel` (role="group", `aria-label="Form building block"`), three buttons (no `data-c`):
  - `data-k="toform"` — label "to_form" — starts `active`
  - `data-k="form"` — label "<.form>"
  - `data-k="input"` — label "<.input>"
- SVG (`viewBox="0 0 720 170"`) rect ids: `#fmRow_toform`, `#fmRow_form`, `#fmRow_input`.
- Readouts: `.geo-readout#fmOut` (`aria-live="polite"`), `#fmRole`, `#fmResult`.
- Pure function: a `pick(k)`-style handler over the three building blocks — toggles each `#fmSel` button's `active` + `aria-pressed`, sets each row's `stroke`/`stroke-width`/`fill` (on = `#5a87c4`/`2`/`#11203a`, off = `#3a4263`/`1.3`/`#10162b`), and writes the block name/role/description into `#fmRole`, `#fmResult`, and `#fmOut`. Initial state is `to_form` (the `active` button).
- Static labels in the readout block: `block: to_form/1`, `does: changeset becomes a form`.
- Degrade: the static SVG already shows `#fmRow_toform` highlighted; the default state is applied on load. No browser storage. `prefers-reduced-motion` respected globally (no figure animation).

### `#cycle` figure — "changeset → form → submit → context → ok | errors" (`#fmCycleTitle`)

A static `<figure class="fig" aria-labelledby="fmCycleTitle">` (`viewBox="0 0 720 200"`). No controls, no readout; the round-trip boxes `changeset` (F6.03) → `<.form> renders` → `submit` (params) → `Catalog.create`, branching to `{:ok} → redirect` (sage) and `{:error, cs} → to_form → re-render` (burgundy), with the error path looping back to the form ("errors back to the form").

### Footer build-stamp decoder (`#stamp`)

- Stamp id `#stampId` = `TSK0NdT0s6p2xc`; panel `#st-ts` hard-codes "2026-06-01 22:48:15 UTC".
- Decoded: namespace `TSK`, snowflake `319970431077449728`, node `0`, seq `0`, timestamp `2026-06-01 22:48:15 UTC` (matches the hard-coded value).
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` (`ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, `EPOCH_MS = 1704067200000`). Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (#refs, verbatim)

This dive has no `#refs` / References section. The chapter's References block lives on the F6.05 hub (`/elixir/phoenix/heex`). The dive closes with an inline `.note` at the end of `#errors` (verbatim): "That completes F6.05. The view layer renders assigns, reuses components, and edits through changeset-backed forms — all server-rendered. The next module, **F6.06 — LiveView**, makes these same templates live, updating over a socket without a full page reload. Back to [the module overview](/elixir/phoenix/heex) or the [F6 chapter](/elixir/phoenix)."

## Wiring

- route-tag (verbatim, segmented): `/ elixir / phoenix / heex / forms` — `<a href="/elixir">elixir</a>` / `<a href="/elixir/phoenix">phoenix</a>` / `<a href="/elixir/phoenix/heex">heex</a>` / `<span class="rcur">forms</span>`.
- crumbs: `F6` → `/elixir/phoenix` · sep `/` · `F6.05` → `/elixir/phoenix/heex` · sep `/` · here `forms` (no link).
- toc-mini: `#parts` ("Three building blocks") · `#cycle` ("The form round trip") · `#code` ("A real form") · `#errors` ("How errors reach the screen").
- pager: prev → `/elixir/phoenix/heex/components` ("← F6.05.2 · function components & slots"); next → `/elixir/phoenix/heex` ("Back to F6.05 · overview →").
- footer (3-column `foot-nav`): Brand → `/elixir` + the standard tag; Chapters column `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`; The course column `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01"). Header brand → `/elixir`; header nav `Contents` → `/elixir/course`.
- Page meta: `<title>` "Forms & inputs — F6.05.3 · jonnify"; `<meta description>` "A form is a changeset turned into a form with to_form/1. <.form for={@form}> and <.input field={@form[:title]}> render fields and surface the F6.03 changeset errors inline, and the submitted params flow back to the context's create or update function, closing the loop from view to domain."

## Build instruction

To (re)build this dive, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent built F6.05 dive on the blue accent, then change only the `<title>`/`<meta description>`, the segmented `.route-tag`, and the `<main>` body. Use the lesson-hero `.lede` styling (upright, not the italic landing deck). No-invent guards: show only the real Portal surfaces as written — the branded store, the event-sourced engine behind the one `Portal` facade, and the Phoenix web app; name `to_form/1`, `<.form>`, `<.input>`, `<.button>`, `~p`, `Catalog.change_course/1`, `Catalog.create_course/1`, `%Phoenix.HTML.Form{}`, and `%Ecto.Changeset{}` only as the live page uses them, and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/phoenix/heex/components.html` (F6.05.2, blue accent — the same four-section dive shape, `.solid-select` selector figure, static second figure, two `pre.code` blocks, identical header/footer/scripts).
