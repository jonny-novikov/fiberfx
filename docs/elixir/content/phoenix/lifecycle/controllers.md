# F6.01.3 — Controllers, views & the facade seam (dive)

- **Route (served):** `/elixir/phoenix/lifecycle/controllers`
- **File:** `elixir/phoenix/lifecycle/controllers.html`
- **Place in the chapter:** the third and last of the F6.01 dives (part 3 of 3). After part 1 traced the request and part 2 placed the endpoint in the tree, this dive reaches the seam where the web layer meets the F5 engine — the controller that names only `Portal`. It closes F6.01 and hands forward to F6.02 (routing).
- **Accent:** blue (F6 · Phoenix; hero `.ex` accent on "seam"; interactive highlights `--blue` / `--blue-bright`).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.01 · part 3 of 3`

`h1` (verbatim): `Controllers, views & the facade seam` ("seam" is the accent `.ex` span).

Hero lede (`.lede`, verbatim):

> This is where your code lives in the lifecycle, and it is the place the whole F5/F6 split pays off. A **controller action** receives the matched request, calls the `Portal` facade, branches on the closed `%Portal.Error{}` contract, and hands a **view** its data; the view turns that data into markup. The rule is one sentence: a controller names only `Portal` and its error struct — never `Portal.Engine`, never a repo, never a `GenServer.call`. Keep that rule and the controller stays a thin translation between HTTP and the engine, which is exactly what let the F5.09 lab promise that F6 would change nothing below the facade.

Kicker (`.kicker`, verbatim):

> See the three players and the one-way seam between them, then read a real controller and the view it renders.

## Sections

In order:

1. **Three players** (`#players`) — the controller, the view, and the facade, each doing one job; only the controller touches the facade, only the view touches markup. Carries the player-selector figure and a `.take`.
2. **The seam, one direction** (`#seam`) — the relationships point only one way: the controller calls down into the facade and hands data sideways to the view; neither calls back. Carries the one-way seam figure and a `.take`.
3. **A controller and its view** (`#code`) — a write action shows the shape (call `Portal.enroll/2`, map its two outcomes); the view module embeds templates and the HEEx renders only from `assigns`. Carries two Elixir code blocks, a `.bridge`, and a closing `.note`.

**Running example:** an enroll write — `Portal.enroll/2` mapping `:ok` / `{:error, %Portal.Error{}}` onto a redirect with a flash message — plus a `CourseHTML` view rendering `course_html/show.html.heex`.

**Real Elixir code shown** (two `pre.code` blocks — the controller, then the view module + HEEx):

```elixir
# the controller: call the facade, branch on the contract, redirect
defmodule PortalWeb.EnrollmentController do
  use PortalWeb, :controller

  def create(conn, %{"user" => uid, "course" => cid}) do
    case Portal.enroll(uid, cid) do
      :ok ->
        conn |> put_flash(:info, "Enrolled") |> redirect(to: ~p"/courses/#{cid}")

      {:error, %Portal.Error{message: msg}} ->
        conn |> put_flash(:error, msg) |> redirect(to: ~p"/courses")
    end
  end
end
```

```elixir
# the view module: embed the templates for this controller
defmodule PortalWeb.CourseHTML do
  use PortalWeb, :html
  embed_templates "course_html/*"
end

# course_html/show.html.heex — renders only from assigns, calls no engine
<h1>{@course.title}</h1>
<progress value={@progress} max="100"></progress>
<.link navigate={~p"/courses"}>All courses</.link>
```

(The HEEx template lines are fully escaped in the markup — `&lt;h1&gt;…` etc.)

## The interactives

### Figure 1 — "The seam · select a player" (`#cvTitle`)

- **`<figure class="fig">`**, heading `#cvTitle` "The seam · select a player". Control group `.solid-select#cvSel` (role `group`, label "Player") with three buttons by `data-k`: `controller` (starts `.active`), `view`, `facade`. SVG `viewBox="0 0 720 170"` with rows `#cvRow_controller`, `#cvRow_view`, `#cvRow_facade`. Readout `.geo-readout#cvOut`; spans `#cvRole` (default "Controller") and `#cvResult` (default "calls the facade, picks a view").
- **Pure function:** `pick(k)` over `ORDER = ['controller','view','facade']` — toggles `#cvSel` button `.active`/`aria-pressed`; restrokes the matching `PLAYERS[id].row` rect (`BLUE_MUTE`/`2`/`#11203a` on, `#3a4263`/`1.3`/`#10162b` off); sets `#cvRole`←`P.name`, `#cvResult`←`P.does`, writes "The <b>name</b> — does. desc" into `#cvOut.innerHTML`. Initial call `pick('controller')`.
- **`PLAYERS` dataset (`name` · `does` · `row` · `desc`, verbatim):**
  - controller — "Controller" · "calls the facade, picks a view" · `cvRow_controller` · "The action receives the matched request, calls Portal.* (a command or a query), branches on the closed %Portal.Error{} contract, and renders a view. It is the only player that touches the facade."
  - view — "View / HEEx" · "renders assigns to markup" · `cvRow_view` · "A view module embeds templates; the HEEx renders from assigns and calls no engine. Built out in F6.05, and rendered live under LiveView in F6.06."
  - facade — "Portal facade" · "the only call the web makes" · `cvRow_facade` · "enroll/2, courses_of/1, progress_of/1 from F5.08 — the engine's one public edge. The controller calls it; nothing in the web layer reaches past it to Portal.Engine or a repo."
- **`.take` (verbatim):** "A fat controller is the usual way a web app rots: domain logic leaks into actions until the engine and the web are tangled. The facade rule keeps the controller honest — if a line is not a facade call, a branch on the result, or a render, it does not belong here."

### Figure 2 — "Controller in the middle, calls down, renders sideways" (`#cvSeamTitle`)

- **`<figure class="fig">`**, heading `#cvSeamTitle` "Controller in the middle, calls down, renders sideways". Static `<svg viewBox="0 0 720 188">` — no controls, no JS — the `CONTROLLER ACTION` node ("decide & delegate") with a `calls` arrow down to `PORTAL FACADE · F5` ("dispatch / query") and an `assigns` arrow sideways to `VIEW / HEEx · F6.05` ("renders assigns"); both arrows point away from the controller.
- **`.take` (verbatim):** "One-way dependencies are the whole game. The controller knows the facade and the view; neither knows the controller. Replace the caller and everything it called stays exactly as it was."

### Degrade behaviour

The static one-way seam figure needs no JS. The `#cvSel` player selector renders all three buttons and rows in markup; `pick('controller')` paints the default `#cvOut`/`#cvRole`/`#cvResult` on load but the controls and SVG are intact without JS. The `.arc-flow` animation and `html.js .reveal` are motion-gated (reveal content is visible without JS). No browser storage.

### Footer build-stamp decoder (`#stamp`)

- **Stamp id:** `TSK0NdLjFwjgoa` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-01 21:06:19 UTC".
- **Pure functions:** `b62decode(s)` (base62 → BigInt), `pad2(x)`, `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`; fills `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts`. Toggle on click / Enter / Space sets `.open` and `aria-expanded`. Decoding `TSK0NdLjFwjgoa` resolves to the panel timestamp 2026-06-01 21:06:19 UTC.

## References (`#refs`, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

**Sources**
- [Overview — Phoenix documentation](https://hexdocs.pm/phoenix/overview.html) — the framework at a glance.
- [Request life-cycle — Phoenix documentation](https://hexdocs.pm/phoenix/request_lifecycle.html) — endpoint to view, where the controller sits.

**Related in this course**
- F6.01 · Architecture & the request lifecycle → `/elixir/phoenix/lifecycle`
- The endpoint — the lifecycle's entry plug → `/elixir/phoenix/lifecycle/endpoint`
- F6.02 · Routing, controllers & plugs → `/elixir/phoenix/routing`

## Wiring

- **route-tag (verbatim):** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/phoenix">phoenix</a><span class="rsep">/</span><a href="/elixir/phoenix/lifecycle">lifecycle</a><span class="rsep">/</span><span class="rcur">controllers</span>` — `/ elixir / phoenix / lifecycle / controllers`, current segment `controllers`.
- **crumbs (verbatim):** `F6` → `/elixir/phoenix` · sep `/` · `F6.01` → `/elixir/phoenix/lifecycle` · sep `/` · here `controllers` (no link).
- **toc-mini:** `#players` ("Three players") · `#seam` ("The seam, one direction") · `#code` ("A controller and its view").
- **pager:** prev → `/elixir/phoenix/lifecycle/endpoint` ("← F6.01.2 · the endpoint"); next → `/elixir/phoenix/lifecycle` ("Back to F6.01 · overview →").
- **footer (`.foot-nav`, 3 columns):**
  - Brand: `.foot-logo` → `/elixir`; `.foot-tag` "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
- **Page meta:** `<title>` "Controllers, views & the facade seam — F6.01.3 · jonnify"; `<meta description>` "Where your code lives in the lifecycle: a thin controller calls only the Portal facade, branches on the closed error contract, and picks a view; the view renders assigns to markup. The controller is the seam between HTTP and the engine, and the rule is that it names only Portal and %Portal.Error{}."

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent BUILT blue-accent F6 sibling — the model page is `elixir/phoenix/lifecycle/endpoint.html` (the adjacent F6.01.2 dive, identical chrome and a structurally identical `.solid-select` three-row figure) — then change only the `<title>`/`<meta description>`, the `.route-tag` (current segment `controllers`), and the `<main>` body. Keep the blue interactive palette and fully escape every HEEx template line in the `pre.code` (`&lt;h1&gt;…`). No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind the one `Portal` facade (`Portal.enroll/2`, `Portal.courses_of/1`, `Portal.progress_of/1`), the closed `%Portal.Error{}` set, and the Phoenix web modules `PortalWeb.EnrollmentController` / `PortalWeb.CourseHTML` with verified `~p` paths; a controller names only `Portal` and its error struct — never `Portal.Engine`, a repo, or a `GenServer.call`. Cite the companion F5 course for the facade/engine internals (`/elixir/pragmatic/engine-lab`) rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
