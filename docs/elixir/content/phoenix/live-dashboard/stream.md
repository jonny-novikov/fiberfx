# F6.09.2 — Broadcast engine events (dive)

- **Route (served):** `/elixir/phoenix/live-dashboard/stream`
- **File:** `elixir/phoenix/live-dashboard/stream.html`
- **Place in the chapter:** the second of three dives under the F6.09 capstone module (`/elixir/phoenix/live-dashboard`). It is "part 2 of 3" — where the static read model from F6.09.1 comes alive by subscribing to the domain topic and folding each broadcast, before F6.09.3 serves many clients.
- **Accent:** blue (F6 · Phoenix). The `<h1>` accent word `events` carries `class="ex"`; figures use the `--blue` family.
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.09 · part 2 of 3`.

`<h1>`: "Broadcast engine `events`" (the word `events` is the `.ex` accent span).

Hero lede (`.lede`, verbatim):

> This is where the static dashboard from F6.09.1 comes alive, and it reuses F6.07 wholesale. The domain already broadcasts a tagged event on a topic the moment a write succeeds — `{:course_created, course}`, `{:enrolled, enrollment}` — so the dashboard does not need any new emission code; it only needs to **listen**. It subscribes to the `"events"` topic on its **connected mount** (the `connected?/1` guard again), and from then on every event arrives in `handle_info/2` as a process message. The key idea is the **fold**: each `handle_info/2` clause takes one event and applies it to the read model — bump the matching count with `update/3`, and `stream_insert/3` a row at the top of the feed. This is the same shape as reducing a list, except the "list" arrives over time and each step pushes a diff to the browser. The dashboard never recomputes from scratch and never re-queries the database on each event; it maintains its derived numbers incrementally from the stream of facts. That is exactly the event-sourcing intuition from F5, expressed as a live LiveView: the engine is the source of events, and the dashboard is a projection that folds them as they come.

Kicker (`.kicker`, verbatim):

> Four parts: subscribe versus handle versus the projection, the path an event folds along, subscribing at mount, and the `handle_info/2` clauses that do the folding.

## Sections

The dive runs four `<section>`s (the toc-mini order):

1. **`#what` — "Subscribe, handle, fold"** — the three ideas of the live update, with the `#bsSel` selector figure.
2. **`#flow` — "An event folds in"** — the static `#bsFlowTitle` path diagram (event → mailbox → `handle_info/2` fold → diff to browser).
3. **`#subscribe` — "Subscribing at mount"** — code block 1: the `mount/3` `connected?/1` subscribe + the comment naming the events the domain already emits.
4. **`#handle` — "Folding each event"** — code block 2: the per-event `handle_info/2` clauses (`:course_created`, `:enrolled`).

Running example: one enrollment traced end to end — the context broadcasts `{:enrolled, _}` on `"events"`, PubSub delivers it, `handle_info/2` bumps `enrollments_count` and `stream_insert`s a feed row.

Code block 1 (`mount/3` subscribe, real Elixir, verbatim):

```
# the dashboard joins the engine's event topic on the connected mount
def mount(_params, _session, socket) do
  if connected?(socket), do: Portal.subscribe("events")
  {:ok, seed(socket)}      # seed/1 sets counts + an empty feed (F6.09.1)
end

# the domain already emits these after a write (F6.07) — the dashboard only listens:
#   Portal.broadcast("events", {:course_created, course})
#   Portal.broadcast("events", {:enrolled, enrollment})
```

Code block 2 (the folding `handle_info/2` clauses, verbatim):

```
# each event folds into the read model: bump a count, prepend to the feed
def handle_info({:course_created, course}, socket) do
  {:noreply,
   socket
   |> update(:courses_count, fn n -> n + 1 end)
   |> stream_insert(:events, row("course created", course.title), at: 0)}
end

def handle_info({:enrolled, enrollment}, socket) do
  {:noreply,
   socket
   |> update(:enrollments_count, fn n -> n + 1 end)
   |> stream_insert(:events, row("enrolled", enrollment.id), at: 0)}
end
```

## The interactives

Two figures: the `#bsSel` selector and the static `#bsFlowTitle` diagram. Plus the footer build-stamp decoder. There are no `.fold-ctrl` sliders.

### Section figure — "The live update · select one" (`#bsSel` selector + `#bsOut` readout)

- **`<figure class="fig" aria-labelledby="bsTitle">`** (`#what` section); inner `<h4>` "The live update · select one".
- **Control group `#bsSel`** (`.solid-select`, `role="group"`, `aria-label="Live update piece"`), three `<button data-k>`:
  - `data-k="subscribe"` — label "subscribe" — starts `active`
  - `data-k="handle"` — label "handle_info"
  - `data-k="projection"` — label "the projection"
- **SVG row ids:** `#bsRow_subscribe`, `#bsRow_handle`, `#bsRow_projection`.
- **Pure function:** `pick(k)` toggles the active button + `aria-pressed`, sets each row's `stroke`/`stroke-width`/`fill` (active = `#5a87c4`/`2`/`#11203a`), writes `#bsRole`/`#bsResult`, and renders `#bsOut.innerHTML` as `<b>{name}</b> — {is}. {desc}`. Initial call `pick('subscribe')`. Dataset `P` (verbatim `name` · `is` · `desc`):
  - subscribe · "join the engine's topic at mount" · "Portal.subscribe(\"events\") opts the dashboard into the topic, behind connected?/1 in mount. The domain already broadcasts the events for F6.07; the dashboard is one more subscriber."
  - handle_info/2 · "fold an event into the read model" · "Each broadcast arrives as a process message in handle_info/2, which bumps the matching count with update/3 and prepends a feed row with stream_insert/3, then re-renders."
  - the projection · "counts + feed derived from events" · "The read model is a projection folded incrementally from the event stream — the count is bumped, not recomputed, and the feed gets one row, never a re-query. The F5 event-sourcing idea, live."
  - Markup defaults: `#bsRole` "subscribe", `#bsResult` "join the engine's topic at mount".
- **Take (`.take`, verbatim):** "The dashboard adds no broadcasting of its own. The domain was already emitting these events for F6.07; the dashboard is one more subscriber, which is why making a page live costs so little here."

### Static figure — "event → handle_info → bump count + insert row → diff" (`#bsFlowTitle`)

- **`<figure class="fig" aria-labelledby="bsFlowTitle">`** (`#flow` section); `<svg viewBox="0 0 720 188">`, no controls. Shows `broadcast {:enrolled, _}` → this dashboard's MAILBOX → `handle_info/2 — fold` (`update :enrollments_count`, `stream_insert feed, at: 0`) → diff to browser (count + row update), with the strip "incremental: the count is bumped, not recomputed; the feed gets one row, not a re-query".
- **Take (`.take`, verbatim):** "Folding rather than recomputing is what lets the dashboard stay cheap under load. A thousand events are a thousand small updates, each touching one count and inserting one row — never a thousand full re-reads of the database."

### Footer build-stamp decoder (`#stamp`)

- **Stamp id:** `TSK0NdeUSgMQqG` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-02 01:28:52 UTC".
- **Pure functions:** `b62decode(s)`; `pad2(x)`; `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`. Decoding `TSK0NdeUSgMQqG` yields `ns=TSK`, `snow=320010849550860288`, `node=0`, `seq=0`, timestamp `2026-06-02 01:28:52 UTC` (matches the hard-coded panel). Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (`#refs`, verbatim)

This dive carries **no** `References` section in the body (no `#refs` block). The dive's cross-links are carried by the `.bridge` and the section `.note` instead.

- `.bridge` (verbatim): left "subscribe once" / "On the connected mount; the domain already broadcasts the events." → right "fold each event" / "`handle_info/2` bumps a count and inserts a row — incrementally."
- `.note` (verbatim): "Next: [**many clients, live**](/elixir/phoenix/live-dashboard/multi-client) — one fold per dashboard, every viewer in sync, with a Presence count and clustering for production."

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/phoenix">phoenix</a><span class="rsep">/</span><a href="/elixir/phoenix/live-dashboard">live-dashboard</a><span class="rsep">/</span><span class="rcur">stream</span>`.
- **crumbs:** `F6` → `/elixir/phoenix` · sep `/` · `F6.09` → `/elixir/phoenix/live-dashboard` · sep `/` · here `stream` (no link).
- **toc-mini:** `#what` ("Subscribe, handle, fold") · `#flow` ("An event folds in") · `#subscribe` ("Subscribing at mount") · `#handle` ("Folding each event").
- **pager:** prev → `/elixir/phoenix/live-dashboard/build` ("← F6.09.1 · build the dashboard"); next → `/elixir/phoenix/live-dashboard/multi-client` ("Next · many clients, live →").
- **footer (`foot-nav`, three columns):** identical to the hub — Brand → `/elixir`; Chapters column `/elixir/algebra`…`/elixir/phoenix`; The course column `/elixir`, `/elixir/course`, `/elixir/algebra/functions`. Header `.brand` and footer `.foot-logo` both point at `/elixir`.
- **Page meta:** `<title>` "Broadcast engine events — F6.09.2 · jonnify"; `<meta name="description">` "The domain emits events after a write (F6.07) and the dashboard subscribes to the topic on its connected mount. handle_info/2 folds each event into the read model — bumping a count and prepending to the feed stream — so the numbers and the activity feed stay live without a reload."

## Build instruction

To rebuild this dive, copy the `<head>`…`</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built F6 (blue accent) dive — the model sibling is `elixir/phoenix/live-dashboard/build.html` (same module, same four-section shape, two figures + two code blocks); change only `<title>`/`<meta>`, the route-tag (current segment `stream`), the crumbs, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — `Portal.subscribe/1` and `Portal.broadcast/2` on the `"events"` topic, the tagged events `{:course_created, course}` / `{:enrolled, enrollment}`, LiveView `connected?/1` / `handle_info/2` / `update/3` / `stream_insert/3`; the dashboard only listens (the domain already emits for F6.07) and writes nothing below the facade. Cite the companion course for OTP internals (PubSub, event-sourcing folds from F5) — do not re-teach them. Voice: no first person, no exclamation marks, no emoji, and none of "just"/"simply"/"obviously".
