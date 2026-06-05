# F6.09.1 — Build the dashboard (dive)

- **Route (served):** `/elixir/phoenix/live-dashboard/build`
- **File:** `elixir/phoenix/live-dashboard/build.html`
- **Place in the chapter:** the first of three dives under the F6.09 capstone module (`/elixir/phoenix/live-dashboard`). It is "part 1 of 3" — the static groundwork: the dashboard as an accurate-on-load LiveView read model, before F6.09.2 makes it live and F6.09.3 serves many clients.
- **Accent:** blue (F6 · Phoenix). The `<h1>` accent word `dashboard` carries `class="ex"`; figures use the `--blue` family.
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.09 · part 1 of 3`.

`<h1>`: "Build the `dashboard`" (the word `dashboard` is the `.ex` accent span).

Hero lede (`.lede`, verbatim):

> Before anything is live, the dashboard is an ordinary LiveView with a carefully chosen **read model** on its socket. A read model is derived state — numbers and a list you compute from the domain, not a new place data lives. Here it is three things: the metric **counts** (how many courses, how many enrollments), a **viewers** number, and a capped **feed** of recent activity. `mount/3` seeds the counts by asking the F6.04 contexts — `Catalog.count_courses/0`, `Enrollment.count/0` — so the page is correct the instant it loads, and it initialises a **stream** for the feed, which keeps a long, append-only list out of socket memory exactly as in F6.06.3. `render/1` then draws metric cards from the assigns and the feed from the stream. There is deliberately no event handling yet: this dive builds a dashboard that is accurate on load but static, so the live part in F6.09.2 has a clean shape to plug into. The discipline to hold is that the dashboard *reads* — every number traces back to the contexts, and the socket is a cache of derived values, never a source of truth.

Kicker (`.kicker`, verbatim):

> Four parts: the three pieces of the read model, the dashboard as a projection, seeding it in `mount/3`, and rendering cards and a feed in HEEx.

## Sections

The dive runs four `<section>`s (the toc-mini order):

1. **`#what` — "Metrics, feed, assigns"** — the three pieces of the read model, with the `#dbSel` selector figure.
2. **`#shape` — "A read model, not a store"** — the dashboard as a projection over the domain; the static `#dbShapeTitle` diagram (contexts read side → mount seeds → the socket → `render/1`).
3. **`#mount` — "Seeding it at mount"** — code block 1: the `mount/3` `assign`/`stream` pipeline.
4. **`#render` — "Rendering cards and a feed"** — code block 2: the HEEx template (metric cards + a `phx-update="stream"` feed).

Running example: the operations dashboard's read model — `courses_count`, `enrollments_count`, `viewers`, and a `stream(:events)` feed seeded at mount from the `Catalog`/`Enrollment` contexts.

Code block 1 (`mount/3`, real Elixir, verbatim):

```
def mount(_params, _session, socket) do
  socket =
    socket
    |> assign(:courses_count, Catalog.count_courses())
    |> assign(:enrollments_count, Enrollment.count())
    |> assign(:viewers, 0)
    |> stream(:events, [])      # filled by broadcasts in F6.09.2

  {:ok, socket}
end
```

Code block 2 (the HEEx template, fully escaped in markup, verbatim):

```
<div class="dashboard">
  <section class="metrics">
    <article><h3>Courses</h3><p>{@courses_count}</p></article>
    <article><h3>Enrollments</h3><p>{@enrollments_count}</p></article>
    <article><h3>Watching</h3><p>{@viewers}</p></article>
  </section>

  <ul id="feed" phx-update="stream">
    <li :for={{dom_id, event} <- @streams.events} id={dom_id}>
      {event.label}
    </li>
  </ul>
</div>
```

## The interactives

Two figures: the `#dbSel` selector and the static `#dbShapeTitle` diagram. Plus the footer build-stamp decoder. There are no `.fold-ctrl` sliders.

### Section figure — "The read model · select one" (`#dbSel` selector + `#dbOut` readout)

- **`<figure class="fig" aria-labelledby="dbTitle">`** (`#what` section); inner `<h4>` "The read model · select one".
- **Control group `#dbSel`** (`.solid-select`, `role="group"`, `aria-label="Read model piece"`), three `<button data-k>`:
  - `data-k="metrics"` — label "metrics" — starts `active`
  - `data-k="feed"` — label "the feed"
  - `data-k="assigns"` — label "assigns"
- **SVG row ids:** `#dbRow_metrics`, `#dbRow_feed`, `#dbRow_assigns`.
- **Pure function:** `pick(k)` toggles the active button + `aria-pressed`, sets each row's `stroke`/`stroke-width`/`fill` (active = `#5a87c4`/`2`/`#11203a`, else `#3a4263`/`1.3`/`#10162b`), writes `#dbRole`/`#dbResult`, and renders `#dbOut.innerHTML` as `<b>{name}</b> — {is}. {desc}`. Initial call `pick('metrics')`. Dataset `P` (verbatim `name` · `is` · `desc`):
  - metrics · "counts seeded from contexts" · "The metric counts — courses, enrollments — are read from the F6.04 contexts at mount, so the first paint shows real numbers with no loading state."
  - the feed · "a capped stream of recent events" · "The activity feed is a stream under a phx-update=\"stream\" container, which keeps a long append-only list in the DOM rather than in socket memory — the F6.06.3 pattern."
  - assigns · "the socket holds the read model" · "The socket assigns hold the derived state: the counts, the viewer number, and the feed stream. It is a cache computed from the domain, never a source of truth."
  - Markup defaults: `#dbRole` "metrics", `#dbResult` "counts seeded from contexts"; `#dbOut` is empty until `pick('metrics')` fills it.
- **Take (`.take`, verbatim):** "Keeping the feed in a stream rather than an assign matters as much here as in F6.06.3: a busy dashboard could see thousands of events, and a stream holds them in the DOM, not in the process's memory."

### Static figure — "contexts (read side) → mount seeds → the socket" (`#dbShapeTitle`)

- **`<figure class="fig" aria-labelledby="dbShapeTitle">`** (`#shape` section); `<svg viewBox="0 0 720 188">`, no controls. Shows `Catalog.count_courses()` + `Enrollment.count()` → `mount` → socket assigns (`courses_count · enrollments_count`, `viewers`, `stream(:events) — starts empty`) → `render/1` (metric cards + feed), with the strip "a projection over the domain — if the process restarts, it re-seeds from the contexts".
- **Take (`.take`, verbatim):** "Because the read model is derived, it is disposable, and that is a feature: there is no migration, no separate store to keep consistent. The contexts remain the single source of truth, and the dashboard is one view of them."

### Footer build-stamp decoder (`#stamp`)

- **Stamp id:** `TSK0NdeUSQStYe` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-02 01:28:51 UTC".
- **Pure functions:** `b62decode(s)` (base62 over `"0123…XYZabc…xyz"`); `pad2(x)`; `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`. Decoding `TSK0NdeUSQStYe` yields `ns=TSK`, `snow=320010849315979264`, `node=0`, `seq=0`, timestamp `2026-06-02 01:28:51 UTC` (matches the hard-coded panel). Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (`#refs`, verbatim)

This dive carries **no** `References` section in the body (no `#refs` block; the `.refs` CSS exists in the shared `<style>` but is not instantiated). The dive's cross-links are carried by the `.bridge` and the section `.note` instead.

- `.bridge` (verbatim): left "seed from contexts" / "`mount/3` reads counts; the feed stream starts empty." → right "render the read model" / "Cards from assigns, feed rows from the stream — accurate, but still static."
- `.note` (verbatim): "Next: [**broadcast engine events**](/elixir/phoenix/live-dashboard/stream) — the shape is ready; now subscribe to the domain and fold each event into these counts and this feed."

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/phoenix">phoenix</a><span class="rsep">/</span><a href="/elixir/phoenix/live-dashboard">live-dashboard</a><span class="rsep">/</span><span class="rcur">build</span>`.
- **crumbs:** `F6` → `/elixir/phoenix` · sep `/` · `F6.09` → `/elixir/phoenix/live-dashboard` · sep `/` · here `build` (no link).
- **toc-mini:** `#what` ("Metrics, feed, assigns") · `#shape` ("A read model, not a store") · `#mount` ("Seeding it at mount") · `#render` ("Rendering cards and a feed").
- **pager:** prev → `/elixir/phoenix/live-dashboard` ("← F6.09 · overview"); next → `/elixir/phoenix/live-dashboard/stream` ("Next · broadcast engine events →").
- **footer (`foot-nav`, three columns):** identical to the hub — Brand → `/elixir`; Chapters column `/elixir/algebra`…`/elixir/phoenix`; The course column `/elixir`, `/elixir/course`, `/elixir/algebra/functions`. Header `.brand` and footer `.foot-logo` both point at `/elixir`.
- **Page meta:** `<title>` "Build the dashboard — F6.09.1 · jonnify"; `<meta name="description">` "The dashboard is a LiveView that holds a read model on its socket: metric counts seeded from the F6.04 contexts at mount, plus a capped stream for a live activity feed. render/1 draws metric cards and the feed, and the socket holds derived state rather than anything stored."

## Build instruction

To rebuild this dive, copy the `<head>`…`</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built F6 (blue accent) dive — the model sibling is `elixir/phoenix/live-dashboard/stream.html` (same module, same four-section shape, two figures + two code blocks, HEEx fully escaped); change only `<title>`/`<meta>`, the route-tag (current segment `build`), the crumbs, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — the contexts `Catalog.count_courses/0` and `Enrollment.count/0`, LiveView `mount/3` / `assign/3` / `stream/3` / `render/1`, the `phx-update="stream"` container; the dashboard reads through the F6.04 contexts and writes nothing, and any error stays in the closed `%Portal.Error{}` set. Cite the companion course for OTP internals (streams, the BEAM read model) — do not re-teach them. Voice: no first person, no exclamation marks, no emoji, and none of "just"/"simply"/"obviously".
