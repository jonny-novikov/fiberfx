# F6.09.3 — Many clients, live (dive)

- **Route (served):** `/elixir/phoenix/live-dashboard/multi-client`
- **File:** `elixir/phoenix/live-dashboard/multi-client.html`
- **Place in the chapter:** the third and final dive under the F6.09 capstone module (`/elixir/phoenix/live-dashboard`) — and the last lesson of the F6 chapter and of the course. It is "part 3 of 3" — one broadcast fans out to every dashboard, a Presence viewer count, and the read-only wiring that ties the whole course together, clustered for production.
- **Accent:** blue (F6 · Phoenix). The `<h1>` accent word `live` carries `class="ex"`; figures use the `--blue` family.
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.09 · part 3 of 3`.

`<h1>`: "Many clients, `live`" (the word `live` is the `.ex` accent span).

Hero lede (`.lede`, verbatim):

> A dashboard is most useful when a whole team watches it, and that is where the work from F6.07 pays off completely. Because a broadcast on `"events"` fans out to *every* subscribed process, every open dashboard receives the same event and folds it independently — ten browsers, ten mailboxes, ten diffs, all from one publish. No dashboard knows about the others; the runtime delivers to all of them. To show how many people are looking, the dashboard uses **Presence**: it `track`s itself on a `"dashboard"` topic at mount, and a `"presence_diff"` message — arriving in `handle_info/2` like any other — lets it recompute the viewer count from `Presence.list/1`. The whole thing stays **read-only**: the dashboard seeds from the contexts, folds broadcasts, and reports presence, but it never writes — it is a projection, not a participant. And because all of this rides on the BEAM's distribution, **clustering** from F6.08 makes it correct across nodes for free: a viewer on one server and a write on another still meet, because PubSub and Presence span the cluster. One publish, every screen, an honest count — and the same code on one node or ten.

Kicker (`.kicker`, verbatim):

> Four parts: the fan-out and what is read-only, how one event reaches every dashboard across a cluster, tracking viewers with Presence, and the read-only wiring that ties the whole course together.

## Sections

The dive runs four `<section>`s (the toc-mini order):

1. **`#what` — "Fan-out, Presence, read-only"** — the three ideas that finish the lab, with the `#mcSel` selector figure.
2. **`#fanout` — "One event, every dashboard"** — the static `#mcFanTitle` cluster diagram (one publish → every dashboard across nodes).
3. **`#presence` — "Counting the viewers"** — code block 1: the `mount/3` subscribe + `Presence.track`, and the `"presence_diff"` `handle_info/2` clause.
4. **`#wrap` — "The read-only wiring"** — code block 2: the `live_session` route under the F6.08 auth, plus the read-only recap comments.

Running example: a team watching the same dashboard — one context broadcast fans out via PubSub to dashboards A/B/C across two clustered nodes, and `PortalWeb.Presence` reports the live viewer count.

Code block 1 (Presence track + `presence_diff`, real Elixir, verbatim):

```
def mount(_params, _session, socket) do
  if connected?(socket) do
    Portal.subscribe("events")
    PortalWeb.Presence.track(self(), "dashboard", socket.id, %{})
  end

  {:ok, seed(socket)}
end

# Presence broadcasts a diff whenever a viewer joins or leaves
def handle_info(%{event: "presence_diff"}, socket) do
  {:noreply, assign(socket, viewers: map_size(PortalWeb.Presence.list("dashboard")))}
end
```

Code block 2 (the read-only route + recap, verbatim):

```
# routed like any LiveView, protected by the F6.08 auth
live_session :authenticated,
  on_mount: [{PortalWeb.UserAuth, :ensure_authenticated}] do
  live "/dashboard", DashboardLive
end

# the dashboard only reads:
#   mount seeds counts from the contexts (F6.04)
#   handle_info folds broadcasts into assigns + a stream (F6.09.2)
#   Presence reports viewers; clustering (F6.08) spans nodes
# it never writes — a projection over the event stream
```

## The interactives

Two figures: the `#mcSel` selector and the static `#mcFanTitle` diagram. Plus the footer build-stamp decoder. There are no `.fold-ctrl` sliders.

### Section figure — "Many clients · select one" (`#mcSel` selector + `#mcOut` readout)

- **`<figure class="fig" aria-labelledby="mcTitle">`** (`#what` section); inner `<h4>` "Many clients · select one".
- **Control group `#mcSel`** (`.solid-select`, `role="group"`, `aria-label="Multi-client piece"`), three `<button data-k>`:
  - `data-k="fanout"` — label "fan-out" — starts `active`
  - `data-k="presence"` — label "Presence"
  - `data-k="readonly"` — label "read-only"
- **SVG row ids:** `#mcRow_fanout`, `#mcRow_presence`, `#mcRow_readonly`.
- **Pure function:** `pick(k)` toggles the active button + `aria-pressed`, sets each row's `stroke`/`stroke-width`/`fill` (active = `#5a87c4`/`2`/`#11203a`), writes `#mcRole`/`#mcResult`, and renders `#mcOut.innerHTML` as `<b>{name}</b> — {is}. {desc}`. Initial call `pick('fanout')`. Dataset `P` (verbatim `name` · `is` · `desc`):
  - fan-out · "one broadcast, every dashboard" · "A broadcast on \"events\" is delivered by PubSub to every subscribed dashboard, so each one folds the same event and diffs to its own browser. The publisher fires once; the runtime reaches all of them."
  - Presence · "a live count of who is watching" · "The dashboard tracks itself on a \"dashboard\" topic and recomputes map_size(Presence.list(...)) on each presence_diff, giving a viewer count that stays correct across the cluster."
  - read-only · "the dashboard observes, never writes" · "The dashboard seeds from the contexts, folds broadcasts, and reports presence — but it has no write path. It is a projection over the event stream, safe to open anywhere."
  - Markup defaults: `#mcRole` "fan-out", `#mcResult` "one broadcast, every dashboard".
- **Take (`.take`, verbatim):** "Read-only is not a limitation here — it is what makes the dashboard safe to open anywhere by anyone with access. It cannot corrupt state because it has no path to write; it can only show what the domain already decided."

### Static figure — "one publish → every dashboard, across nodes" (`#mcFanTitle`)

- **`<figure class="fig" aria-labelledby="mcFanTitle">`** (`#fanout` section); `<svg viewBox="0 0 720 212">`, no controls. Shows `context broadcast "events"` → `PubSub (spans the cluster)` → NODE 1 (dashboards A, B; fold → diff) and NODE 2 (dashboard C; "same event, same result"), with the strip "one publish, every dashboard on every node — the same code whether you run one server or ten".
- **Take (`.take`, verbatim):** "Scaling the number of viewers or the number of servers does not change the publishing code at all. That invariance — one node or a cluster, one viewer or a thousand, the same broadcast — is the payoff of building on the BEAM from F5 onward."

### Footer build-stamp decoder (`#stamp`)

- **Stamp id:** `TSK0NdeUSwFy7s` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-02 01:28:52 UTC".
- **Pure functions:** `b62decode(s)`; `pad2(x)`; `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`. Decoding `TSK0NdeUSwFy7s` yields `ns=TSK`, `snow=320010849785741312`, `node=0`, `seq=0`, timestamp `2026-06-02 01:28:52 UTC` (matches the hard-coded panel). Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (`#refs`, verbatim)

This dive carries **no** `References` section in the body (no `#refs` block). The dive's cross-links are carried by the `.bridge` and the section `.note` instead.

- `.bridge` (verbatim): left "one publish" / "Fans out to every dashboard, on every node, and Presence counts them." → right "the whole course, live" / "Engine, contexts, LiveView, PubSub, and the deploy, in one read-only screen."
- `.note` (verbatim): "That completes F6.09 — and the course. From the F5 engine and its supervision tree, through contexts, routing, Ecto, templates, LiveView, PubSub, and deployment, to this dashboard that watches it all in real time, you have built one coherent system on the BEAM. Back to [the module overview](/elixir/phoenix/live-dashboard), the [F6 chapter](/elixir/phoenix), or the [course contents](/elixir/course)."

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/phoenix">phoenix</a><span class="rsep">/</span><a href="/elixir/phoenix/live-dashboard">live-dashboard</a><span class="rsep">/</span><span class="rcur">multi-client</span>`.
- **crumbs:** `F6` → `/elixir/phoenix` · sep `/` · `F6.09` → `/elixir/phoenix/live-dashboard` · sep `/` · here `multi-client` (no link).
- **toc-mini:** `#what` ("Fan-out, Presence, read-only") · `#fanout` ("One event, every dashboard") · `#presence` ("Counting the viewers") · `#wrap` ("The read-only wiring").
- **pager:** prev → `/elixir/phoenix/live-dashboard/stream` ("← F6.09.2 · broadcast engine events"); next → `/elixir/phoenix/live-dashboard` ("Back to F6.09 · overview →").
- **footer (`foot-nav`, three columns):** identical to the hub — Brand → `/elixir`; Chapters column `/elixir/algebra`…`/elixir/phoenix`; The course column `/elixir`, `/elixir/course`, `/elixir/algebra/functions`. Header `.brand` and footer `.foot-logo` both point at `/elixir`.
- **Page meta:** `<title>` "Many clients, live — F6.09.3 · jonnify"; `<meta name="description">` "One broadcast reaches every connected dashboard at once, so all viewers update together, and Presence reports a live count of who is watching. The dashboard only reads and folds — a projection over the event stream — and clustering from F6.08 spans nodes in production."

## Build instruction

To rebuild this dive, copy the `<head>`…`</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built F6 (blue accent) dive — the model sibling is `elixir/phoenix/live-dashboard/stream.html` (same module, same four-section shape, two figures + two code blocks); change only `<title>`/`<meta>`, the route-tag (current segment `multi-client`), the crumbs, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — `Portal.subscribe/1` on `"events"`, `PortalWeb.Presence.track/4` and `PortalWeb.Presence.list/1` on the `"dashboard"` topic, the `%{event: "presence_diff"}` `handle_info/2` clause, the `live_session :authenticated` route under `PortalWeb.UserAuth` `:ensure_authenticated`, and `DashboardLive`; the dashboard is read-only — it seeds from the F6.04 contexts, folds broadcasts, reports presence, and writes nothing below the facade, with errors confined to the closed `%Portal.Error{}` set. Cite the companion course for OTP internals (Presence, PubSub fan-out, BEAM distribution/clustering) — do not re-teach them. Voice: no first person, no exclamation marks, no emoji, and none of "just"/"simply"/"obviously".
