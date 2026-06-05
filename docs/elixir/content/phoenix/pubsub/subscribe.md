# F6.07.2 — Subscribing a LiveView (dive)

- Route (served): `/elixir/phoenix/pubsub/subscribe`
- File: `elixir/phoenix/pubsub/subscribe.html`
- Place in the chapter: the second of F6.07's three dives (broadcast → subscribe → presence). The broadcast is out on the topic; here a LiveView joins it on its connected mount and reacts in `handle_info/2`. Hands off to F6.07.3 (channels & presence).
- Accent: blue (F6 · Phoenix). The dive card on the hub carries a gold left-border.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.07 · part 2 of 3`

`h1` (verbatim): `Subscribing a LiveView`

Lede (verbatim):

> A LiveView receives broadcasts the same way a GenServer receives any message: in `handle_info/2`. The two halves are **subscribe** and **handle**. You subscribe on the **connected mount** — behind the `connected?/1` guard from F6.06.1, so the throwaway first paint does not join — with one call to the facade's `Portal.subscribe("courses")`. From then on, any message broadcast on that topic lands in the LiveView process's mailbox and is delivered to `handle_info/2`, which pattern-matches the event tuple, updates the socket assigns, and returns `{:noreply, socket}` — triggering the usual re-render and diff. This is the distinction worth holding onto: `handle_event/3` handles messages from the *browser* (a click, a keystroke), while `handle_info/2` handles messages from *other processes* (a PubSub broadcast, a timer, a task result). Both end the same way — new assigns, a re-render — but they are different doorways into the LiveView, and keeping them straight is most of understanding real-time updates. Paired with streams from F6.06.3, a single broadcast inserts one row into every connected client.

Kicker (verbatim):

> Four parts: subscribe versus the two handlers, the path a broadcast takes into the LiveView, the mount-and-handle code, and driving a stream from a broadcast.

## Sections

In order (the `toc-mini`):

1. `#two` · **Two doorways** — `subscribe` opts into a topic; `handle_info/2` receives process messages (PubSub broadcasts, timers); `handle_event/3` receives browser events (clicks, input). Interactive `solid-select`.
2. `#flow` · **A broadcast arrives** — the message from F6.07.1 on `"courses"` lands in the subscribed LiveView's mailbox, the runtime calls `handle_info/2`, assigns update, `{:noreply, socket}`, render, diff to this browser. Static flow diagram.
3. `#code` · **Subscribe and handle** — `mount/3` subscribes once on the connected pass; `handle_info/2` matches `{:course_created, course}` and prepends it to `@courses` with `update/3`. Code block.
4. `#stream` · **Updating a stream** — with the stream from F6.06.3, `stream_insert/3` with `at: 0` prepends; a `:course_updated` clause replaces a row in place by id. Code block, `.bridge`, `.note`.

Running example: a live catalog `CatalogLive` subscribed to `"courses"`, updating either the `@courses` assign or a `:courses` stream when a `{:course_created, course}` broadcast arrives.

Real Elixir code shown (two blocks):
- `def mount(_params, _session, socket)` — `if connected?(socket), do: Portal.subscribe("courses")` then `{:ok, assign(socket, courses: Portal.list_courses())}`; and `def handle_info({:course_created, course}, socket)` returning `{:noreply, update(socket, :courses, fn courses -> [course | courses] end)}` (comment: `# a broadcast arrives as a process message, not a browser event`).
- `# with streams (F6.06.3): insert one row in every client's DOM` — `def handle_info({:course_created, course}, socket)` → `stream_insert(socket, :courses, course, at: 0)`; and `def handle_info({:course_updated, course}, socket)` → `stream_insert(socket, :courses, course)` (`# replaces the row by id`).

## The interactives

### Figure — `Subscribe and handlers · select one` (`#two`)
- `<figure class="fig">`, title id `sbTitle` (`Subscribe and handlers · select one`).
- Control group `#sbSel` (`role="group"`, label `Subscribe or handler`), buttons: `data-k="subscribe"` (label `subscribe`, active), `data-k="info"` (label `handle_info/2`), `data-k="event"` (label `handle_event/3`).
- SVG rows: `#sbRow_subscribe`, `#sbRow_info`, `#sbRow_event`.
- Readout `#sbOut` (`aria-live="polite"`), plus `callback:` `#sbRole` and `handles:` `#sbResult`. Pure function `pick(k)` repaints the selected row and writes the readout from the `P` table.
- Readout `handles` strings VERBATIM: subscribe → `join a topic on connected mount`; info → `receive a broadcast message`; event → `receive a browser event`. Each appends its `desc`, e.g. info: "handle_info/2 receives process messages — a PubSub broadcast, a timer tick, a task result. It pattern-matches the message, updates assigns, and returns {:noreply, socket} to re-render."
- Take (verbatim): `Mixing the two up is the classic beginner bug: trying to catch a broadcast in handle_event, or a click in handle_info. The cure is the one question — did this come from a browser or a process?`

### Figure — `PubSub → mailbox → handle_info → diff` (`#flow`)
- `<figure class="fig">`, title id `sbFlowTitle`. Static diagram (no controls): `PubSub "courses"` → `MAILBOX (this LiveView)` → `handle_info/2` (match event, update assigns, `{:noreply, socket}`) → `render → diff to this browser`, with a dashed note that `a browser click instead enters at handle_event/3` and `both paths end in a re-render`.
- Take (verbatim): `Nothing in the broadcast knows or cares which LiveViews are listening. The publisher fires once; the runtime fans the message out to every subscribed mailbox. Adding a tenth viewer changes nothing in the publishing code.`

Code-section takes (verbatim):
- `#code`: `update/3 transforms one assign from its current value, which is cleaner than reading and re-assigning. It is also exactly how you would evolve a GenServer's state — the LiveView is that pattern with a screen attached.`
- `#stream` `.bridge`: `subscribe once` ("On the connected mount, behind connected?/1.") → `handle every event` ("handle_info/2 updates a stream; all clients update together.").

### Footer build-stamp decoder
- `#stamp` / `#stampId` real id: `TSK0NdYA7Ghnf6`. Decoded: namespace `TSK`, snowflake `319988564240629760`, node `0`, seq `0`, timestamp `2026-06-02 00:00:18 UTC` (matches the static `st-ts`). Shared branded-Snowflake decoder.

## References (#refs, verbatim)

This dive has **no References section** (`#refs`). The only `refs` token in the file is the CSS rule comment `/* ---- references ---- */`; there is no `<h2>References</h2>` block, no Sources list, and no "Related in this course" list. Cross-links instead live inline in the `#stream` `.note` (forward to `/elixir/phoenix/pubsub/presence`) and in the pager/footer (below).

## Wiring

- route-tag (verbatim): `/ elixir / phoenix / pubsub / subscribe` — `<a href="/elixir">elixir</a> / <a href="/elixir/phoenix">phoenix</a> / <a href="/elixir/phoenix/pubsub">pubsub</a> / <span class="rcur">subscribe</span>`.
- crumbs (verbatim): `F6` → `/elixir/phoenix`, `F6.07` → `/elixir/phoenix/pubsub`, then `subscribe` (`here`).
- toc-mini: `Two doorways` (`#two`), `A broadcast arrives` (`#flow`), `Subscribe and handle` (`#code`), `Updating a stream` (`#stream`).
- pager: prev → `/elixir/phoenix/pubsub/broadcast` (`F6.07.1 · broadcasting engine events`); next → `/elixir/phoenix/pubsub/presence` (`Next · channels & presence`).
- footer: column **Chapters** — `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. Column **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand line links `/elixir`.
- Page meta — `<title>`: `Subscribing a LiveView — F6.07.2 · jonnify`. `<meta name="description">`: `A LiveView subscribes to a topic on its connected mount and receives broadcasts in handle_info/2 — the process-message callback, distinct from handle_event/3 for browser events. It updates assigns or a stream and re-renders, so a write by one client appears live for every connected client.`

## Build instruction

To (re)build this dive, copy the `head`…`</style>`, the `header.site`, the `footer.site-foot`, and the trailing `<script>` blocks verbatim from a recent BUILT F6.07 sibling on the blue accent; change only `<title>`/`<meta>`, the `route-tag`, the `crumbs`, and the `<main>` body. Keep the dive anatomy: hero (eyebrow → `h1` → lede + kicker → `toc-mini`) and four sections — a `solid-select` figure, a static flow `fig`, and two `pre.code` sections — each with a `.take`, then a closing `.bridge` + `.note`, the pager, and the footer build-stamp (this dive carries no `#refs` block — do not add one). No-invent guards: use only the real Portal surfaces as written — `Portal.subscribe/1`, `Portal.list_courses/0`, `connected?/1`, `mount/3`, `handle_info/2`, `handle_event/3`, `update/3`, `stream_insert/3` (with `at: 0`), and the `{:course_created, course}` / `{:course_updated, course}` event tuples; cite the companion course for GenServer/message-passing internals rather than re-teaching them. Voice: no first person, no exclamation marks, no emoji, none of just/simply/obviously. Model sibling to copy from: `elixir/phoenix/pubsub/broadcast.html` (same module, same blue accent, identical dive anatomy).
