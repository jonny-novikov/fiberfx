# F6.07.3 — Channels & presence (dive)

- Route (served): `/elixir/phoenix/pubsub/presence`
- File: `elixir/phoenix/pubsub/presence.html`
- Place in the chapter: the third and last of F6.07's dives (broadcast → subscribe → presence). It covers the channel primitive beneath LiveView and `Presence` for who is on a topic, completing the module; the `.note` then points forward to F6.08 (deployment).
- Accent: blue (F6 · Phoenix). The dive card on the hub carries a sage left-border.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.07 · part 3 of 3`

`h1` (verbatim): `Channels & presence`

Lede (verbatim):

> Two real-time tools sit around PubSub, and it helps to know what each is for. A **channel** is the lower-level primitive Phoenix has always had — a bidirectional topic a client joins, with explicit `join/3` and `handle_in/3` callbacks and the ability to push messages out. LiveView is built on top of channels; you reach for a channel directly when you need a **custom protocol** over the socket — a native mobile client, a game, a hardware feed — where you control the wire rather than rendering HTML. Most web UI uses LiveView, so channels are the exception, not the default. **Presence** is the other tool: it answers "who is on this topic right now?" You call `track/3` when a process joins, Presence keeps the set of who is present, and — the part that makes it special — it **syncs that set across every node** in a cluster using a CRDT, so the count is correct whether your users are connected to one server or ten. A change in presence broadcasts a `"presence_diff"` you handle like any other message, which is how a live "`N` people viewing" indicator stays accurate as people come and go.

Kicker (verbatim):

> Four parts: the three real-time tools, how Presence stays correct across a cluster, a minimal channel in code, and tracking viewers to show a live count.

## Sections

In order (the `toc-mini`):

1. `#tools` · **Channel, Presence, track** — a channel is a bidirectional topic any client can join and speak on; Presence reports who is subscribed to a topic, synced across nodes; `track/3` registers the current process as present. Interactive `solid-select`.
2. `#presence` · **Presence across a cluster** — each node tracks its local processes; nodes merge their views with a CRDT, so `Presence.list(topic)` on any node returns the full set. Static two-node diagram.
3. `#code` · **A minimal channel** — a module with `join/3` (who may join) and `handle_in/3` (client messages); this one accepts a join on `"catalog:lobby"` and replies to `"ping"`. Code block.
4. `#track` · **A live viewer count** — `track/3` on the connected mount registers the viewer; a `"presence_diff"` arrives in `handle_info/2`, and counting `Presence.list/1` gives the live number. Code block, `.bridge`, `.note`.

Running example: a `PortalWeb.CatalogChannel` on `"catalog:lobby"`, and a LiveView that tracks viewers on `"courses"` via `PortalWeb.Presence` to show a live count.

Real Elixir code shown (two blocks):
- `defmodule PortalWeb.CatalogChannel do` — `use PortalWeb, :channel`, `@impl true def join("catalog:lobby", _payload, socket) do {:ok, socket} end`, and `@impl true def handle_in("ping", _payload, socket) do {:reply, {:ok, %{pong: true}}, socket} end`.
- `def mount(_params, _session, socket)` — `if connected?(socket)` calls `Portal.subscribe("courses")` and `PortalWeb.Presence.track(self(), "courses", socket.id, %{})`, then `{:ok, assign(socket, courses: Portal.list_courses(), viewers: 0)}`; and `# Presence broadcasts a diff whenever anyone joins or leaves` — `def handle_info(%{event: "presence_diff"}, socket)` → `count = map_size(PortalWeb.Presence.list("courses"))`, `{:noreply, assign(socket, viewers: count)}`.

## The interactives

### Figure — `Real-time tools · select one` (`#tools`)
- `<figure class="fig">`, title id `prTitle` (`Real-time tools · select one`).
- Control group `#prSel` (`role="group"`, label `Real-time tool`), buttons: `data-k="channel"` (label `a channel`, active), `data-k="presence"` (label `Presence`), `data-k="track"` (label `track/3`).
- SVG rows: `#prRow_channel`, `#prRow_presence`, `#prRow_track`.
- Readout `#prOut` (`aria-live="polite"`), plus `tool:` `#prRole` and `is:` `#prResult`. Pure function `pick(k)` repaints the selected row and writes the readout from the `P` table.
- Readout `is` strings VERBATIM: channel → `a bidirectional topic for any client`; presence → `who is subscribed, synced across nodes`; track → `register this process on a topic`. Each appends its `desc`, e.g. track: "Presence.track(self(), topic, key, meta) registers the current process as present. Joining or leaving broadcasts a presence_diff you handle in handle_info to update a count."
- Take (verbatim): `If you are rendering HTML, you almost certainly want LiveView, not a raw channel. Channels earn their place when the other end is not a browser and you need to define the message protocol yourself.`

### Figure — `two nodes → CRDT merge → one shared set` (`#presence`)
- `<figure class="fig">`, title id `prPresTitle`. Static diagram (no controls): `NODE 1` (tracks: A, B) and `NODE 2` (tracks: C) joined by a dashed `CRDT sync (order-independent merge)` line, merging into `list("courses") = A, B, C` (`same answer on either node`).
- Take (verbatim): `This is the BEAM's distribution story showing through again: the same code that works on one node works on a cluster, because presence merges rather than coordinates. You write track and list; the convergence is handled.`

Code-section takes (verbatim):
- `#code`: `Notice handle_in/3 is the channel's version of handle_event, and a channel can push to its client the way a LiveView diffs to a browser. LiveView is a refinement of this primitive, not a separate system.`
- `#track` `.bridge`: `track on join` ("track/3 registers this viewer; Presence syncs the set.") → `count on diff` ("A presence_diff updates the live count, correct cluster-wide.").

### Footer build-stamp decoder
- `#stamp` / `#stampId` real id: `TSK0NdYA7a0WVU`. Decoded: namespace `TSK`, snowflake `319988564525842432`, node `0`, seq `0`, timestamp `2026-06-02 00:00:18 UTC` (matches the static `st-ts`). Shared branded-Snowflake decoder.

## References (#refs, verbatim)

This dive has **no References section** (`#refs`). The only `refs` token in the file is the CSS rule comment `/* ---- references ---- */`; there is no `<h2>References</h2>` block, no Sources list, and no "Related in this course" list. Cross-links instead live inline in the `#track` `.note` (back to `/elixir/phoenix/pubsub` and `/elixir/phoenix`) and in the pager/footer (below).

## Wiring

- route-tag (verbatim): `/ elixir / phoenix / pubsub / presence` — `<a href="/elixir">elixir</a> / <a href="/elixir/phoenix">phoenix</a> / <a href="/elixir/phoenix/pubsub">pubsub</a> / <span class="rcur">presence</span>`.
- crumbs (verbatim): `F6` → `/elixir/phoenix`, `F6.07` → `/elixir/phoenix/pubsub`, then `presence` (`here`).
- toc-mini: `Channel, Presence, track` (`#tools`), `Presence across a cluster` (`#presence`), `A minimal channel` (`#code`), `A live viewer count` (`#track`).
- pager: prev → `/elixir/phoenix/pubsub/subscribe` (`F6.07.2 · subscribing a LiveView`); next → `/elixir/phoenix/pubsub` (`Back to F6.07 · overview`).
- footer: column **Chapters** — `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. Column **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand line links `/elixir`.
- Page meta — `<title>`: `Channels &amp; presence — F6.07.3 · jonnify`. `<meta name="description">`: `Channels are the lower-level real-time primitive LiveView is built on, with explicit join and handle_in for custom client protocols. Presence tracks who is subscribed to a topic, synced across nodes by a CRDT, which is how a live viewer count stays correct across a cluster.`

## Build instruction

To (re)build this dive, copy the `head`…`</style>`, the `header.site`, the `footer.site-foot`, and the trailing `<script>` blocks verbatim from a recent BUILT F6.07 sibling on the blue accent; change only `<title>`/`<meta>`, the `route-tag`, the `crumbs`, and the `<main>` body. Keep the dive anatomy: hero (eyebrow → `h1` → lede + kicker → `toc-mini`) and four sections — a `solid-select` figure, a static cluster `fig`, and two `pre.code` sections — each with a `.take`, then a closing `.bridge` + `.note` (which closes F6.07 and points to F6.08 deployment), the pager, and the footer build-stamp (this dive carries no `#refs` block — do not add one). No-invent guards: use only the real Portal surfaces as written — `Phoenix` channels (`use PortalWeb, :channel`, `join/3`, `handle_in/3`, `{:reply, {:ok, %{pong: true}}, socket}`), `PortalWeb.Presence` with `track/3` and `list/1`, the `"presence_diff"` event, `Portal.subscribe/1`, `Portal.list_courses/0`, `connected?/1`, `mount/3`, and `handle_info/2`; cite the companion course for BEAM distribution / CRDT internals rather than re-teaching them. Voice: no first person, no exclamation marks, no emoji, none of just/simply/obviously. Model sibling to copy from: `elixir/phoenix/pubsub/subscribe.html` (same module, same blue accent, identical dive anatomy).
