# F6.07 — PubSub, channels & real-time (module hub)

- Route (served): `/elixir/phoenix/pubsub`
- File: `elixir/phoenix/pubsub/index.html`
- Place in the chapter: the seventh module of F6 · Phoenix Framework, in milestone M2 ("make it live"). It follows F6.06 (LiveView), which made one LiveView live, and pushes that per-socket state across every client. It frames three dives — broadcast, subscribe, presence — and hands off to F6.08 (deployment).
- Accent: blue (the F6 · Phoenix chapter accent; the `<span class="ex">` highlight uses the `--elixir` lavender, as on every F6 hero).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6 · the architecture · module 7`

Hero `h1` (verbatim): `PubSub, channels & real-time`

Hero lede (verbatim):

> F6.06 made one LiveView live: its own socket, its own state, its own diffs. But a catalog has many viewers, and when one of them creates a course the others should see it without refreshing. That fan-out is **Phoenix.PubSub** — publish/subscribe between processes over a named **topic**. The shape is the OTP message passing the F5 engine already ran on: a process broadcasts a message, and every process subscribed to that topic receives it in its mailbox. The discipline that matters is *where* the broadcast comes from: the **domain** emits the event, in the context, right after a successful write — not the web layer. Each LiveView subscribes on its connected mount (the `connected?/1` guard from F6.06.1) and handles the message in `handle_info/2`, the callback for process messages as opposed to `handle_event/3` for browser clicks. Underneath LiveView sit **channels**, the raw real-time primitive for custom client protocols, and alongside them **Presence**, which tracks who is on a topic and stays correct across a whole cluster. One write becomes everyone's live update, and the domain never learns the web exists.

Kicker (verbatim):

> Three dives: broadcasting domain events from the context, subscribing a LiveView and handling the message, and the channels and presence beneath and beside it — real-time on the same message passing as F5.

## What the page frames

Two teaching sections precede the dives:

- `#pieces` · **Three parts of real-time** — `broadcast` publishes a domain event to a topic; `subscribe` joins a topic so a LiveView receives those events; `presence` tracks who is on a topic, across nodes.
- `#fanout` · **One write, many clients** — traces a single create: form submit → LiveView calls the context → context writes through the Repo → on success broadcasts `{:course_created, course}` on the `"courses"` topic → PubSub delivers to every subscribed LiveView.

The three dives (the `#dives` card list, each with its accent border):

- F6.07.1 · **Broadcasting engine events** — `Phoenix.PubSub`, topics, and broadcasting from the context after a write, with a facade wrapper for the server name. Route `/elixir/phoenix/pubsub/broadcast`. Built (blue left-border).
- F6.07.2 · **Subscribing a LiveView** — subscribe on the connected mount, then `handle_info/2` — process messages, not browser events — updating a stream. Route `/elixir/phoenix/pubsub/subscribe`. Built (gold left-border).
- F6.07.3 · **Channels & presence** — the channel primitive beneath LiveView, and `Presence` for who is on a topic, synced across a cluster. Route `/elixir/phoenix/pubsub/presence`. Built (sage left-border).

Bridge cell (verbatim): `F5 emitted events` ("the engine recorded domain events to its EventStore as the source of truth.") → `F6.07 broadcasts them` ("the same kind of event, published on a topic, drives every live screen.").

## The interactives

### Hero figure — `One write, many subscribers`
- `<figure class="hero-fig">`, `figcaption` id `hpTitle`, label `One write, many subscribers`.
- Controls: `#hpBroadcast` (button `▸ broadcast`) and `#hpReset` (ghost button `reset`).
- SVG element ids: scene `#hpScene`; the moving event token `#hpToken` (class `hp-token`); four fan-out lines `#hpFan_0`..`#hpFan_3`; four subscriber rows `.hp-sub` with `data-sub="0".."3"`, each carrying a `.hp-state` text.
- Logic: a three-state cycle in the inline script — `idle → live → joined → idle` — driven by the broadcast button (`paintSub`/`paintFan`/`paintFanSlot`/`flash`/`render`); no pure named function with a numeric return, the figure is state-machine driven.
- Readout (`#hpCap`, `aria-live="polite"`) strings VERBATIM:
  - idle: `idle — 3 LiveViews subscribed to "catalog:lobby", awaiting a broadcast` / `Press broadcast: the context publishes one event on the topic and every subscriber updates at once.`
  - live: `1 broadcast → 3 LiveViews updated` / `handle_info/2 ran in every subscribed process; broadcast again to add a newly-joined LiveView.`
  - joined: `new LiveView joined → 4 on "catalog:lobby"` / `A subscribe on the connected mount added the fourth; the next broadcast reaches all four. Reset to idle.`
- Degrade: the static SVG ships the idle state (3 stale subscribers, slot 4 not joined, token hidden) and no `render` runs on load; under `prefers-reduced-motion: reduce` the `.hp-token` transition and `.hp-changed` animation are disabled (CSS).

### Section figure — `Real-time · select a part` (`#pieces`)
- `<figure class="fig">`, title id `psTitle` (`Real-time · select a part`).
- Control group `#psSel` (`role="group"`), buttons `data-k="broadcast"` (active), `data-k="subscribe"`, `data-k="presence"`.
- SVG rows: `#psRow_broadcast`, `#psRow_subscribe`, `#psRow_presence` (each tagged `F6.07.1`/`F6.07.2`/`F6.07.3`).
- Readout `#psOut` (`aria-live="polite"`) plus `part:` `#psRole` and `does:` `#psResult`. The `pick(k)` function repaints the selected row and writes the readout from a `PARTS` table.
- Readout `does` strings VERBATIM: broadcast → `publish an event to a topic`; subscribe → `receive a topic's events`; presence → `track who is on a topic`. Each appends its `desc` (e.g. broadcast: "The context publishes a domain event — {:course_created, course} — on a topic after a successful write. PubSub delivers it to every subscribed process; the web layer never originates it.").
- Take (verbatim): `PubSub is not a web feature bolted on — it is the BEAM's native message passing exposed over a topic. The same broadcast reaches a LiveView, a background worker, or a process on another node, with no change to the caller.`

### Section figure — `write → broadcast → every subscriber` (`#fanout`)
- `<figure class="fig">`, title id `psFanTitle` (`write → broadcast → every subscriber`). Static diagram (no controls): `context write` → `PubSub topic "courses"` → `LiveView A/B/C` (`handle_info → diff`) → `3 browsers, all live`.
- Take (verbatim): `The author's own screen updates the same way as everyone else's — through the broadcast, not a special case in the create handler. That uniformity is what keeps real-time code small: there is one path, and every client is on it.`

### Footer build-stamp decoder
- `#stamp` / `#stampId` real id: `TSK0NdYA6ex9MW`. Decoded: namespace `TSK`, snowflake `319988563682787328`, node `0`, seq `0`, timestamp `2026-06-02 00:00:18 UTC` (matches the static `st-ts`). The decoder is the shared branded-Snowflake script (base-62, epoch `1704067200000`).

## References (#refs, verbatim)

Intro line: `PubSub, channels, the handle_info/2 callback, and Presence.`

Sources:
- `https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html` — Phoenix.PubSub — distributed publish/subscribe over topics.
- `https://hexdocs.pm/phoenix/channels.html` — Phoenix — Channels — the real-time primitive over WebSockets.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_info/2` — Phoenix.LiveView — handle_info/2 — handling process messages in a LiveView.
- `https://hexdocs.pm/phoenix/Phoenix.Presence.html` — Phoenix.Presence — cluster-wide presence tracking.

Related in this course:
- `/elixir/phoenix/pubsub/broadcast` — F6.07.1 · Broadcasting engine events
- `/elixir/phoenix/pubsub/subscribe` — F6.07.2 · Subscribing a LiveView
- `/elixir/phoenix/pubsub/presence` — F6.07.3 · Channels & presence
- `/elixir/phoenix/liveview/mount` — F6.06.1 · mount & assigns — where the subscribe goes.
- `/elixir/phoenix` — F6 · Phoenix Framework

## Wiring

- route-tag (verbatim): `/ elixir / phoenix / pubsub` — segmented `<a href="/elixir">elixir</a> / <a href="/elixir/phoenix">phoenix</a> / <span class="rcur">pubsub</span>`.
- crumbs (verbatim): `F6 · Phoenix Framework` → `/elixir/phoenix`, then `F6.07 · pubsub` (`here`).
- toc-mini: `Three parts of real-time` (`#pieces`), `One write, many clients` (`#fanout`), `Three deep dives` (`#dives`).
- pager: prev → `/elixir/phoenix/liveview` (`F6.06 · LiveView`); next → `/elixir/phoenix/pubsub/broadcast` (`Start · broadcasting engine events`).
- footer: column **Chapters** — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand line links `/elixir`.
- Page meta — `<title>`: `PubSub, channels &amp; real-time — F6.07 · jonnify`. `<meta name="description">`: `PubSub turns one LiveView into many that update together: the domain broadcasts an event on a topic after a write, every subscribed LiveView receives it in handle_info and re-renders, and one user's change becomes everyone's live update. Three dives: broadcasting engine events, subscribing a LiveView, and channels and presence — real-time built on the same OTP message passing as the F5 engine.`

## Build instruction

To (re)build this hub, copy the `head`…`</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the page IIFE with the branded-Snowflake decoder, then the `reveal`-on-scroll enhancer) verbatim from a recent BUILT F6 sibling on the blue chapter accent; change only `<title>`/`<meta>`, the `route-tag`, and the `<main>` body. Keep the module-hub anatomy: hero (eyebrow → `h1` → `hero-lede` italic-suppressed lede + kicker → `hero-fig` concept figure), the `#pieces` and `#fanout` teaching sections (a `solid-select` figure + a static fan-out diagram, each with a `.take`), the three-card `#dives` list, the `.bridge` and `.note`, the `#refs` block, the pager, and the footer build-stamp. No-invent guards: use only the real Portal surfaces as written — `Phoenix.PubSub`, `Portal.subscribe/1`, `Portal.broadcast/2`, `Portal.PubSub` (the named server), the closed `{:course_created, course}` / `{:course_updated, course}` domain-event tuples, `handle_info/2`, the branded store, the event-sourced engine behind the one `Portal` facade, and the Phoenix web app; cite the companion course for OTP/message-passing internals rather than re-teaching them. Voice: no first person, no exclamation marks, no emoji, none of just/simply/obviously. Model sibling to copy from: `elixir/phoenix/liveview/index.html` (the F6.06 hub, same blue accent and the same hub anatomy).
