# F6.07.1 — Broadcasting engine events (dive)

- Route (served): `/elixir/phoenix/pubsub/broadcast`
- File: `elixir/phoenix/pubsub/broadcast.html`
- Place in the chapter: the first of F6.07's three dives, in the arc broadcast → subscribe → presence. It teaches where a broadcast originates — the context, after a successful write — and hands off to F6.07.2 (subscribing a LiveView).
- Accent: blue (F6 · Phoenix). The dive card on the hub carries a blue left-border.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.07 · part 1 of 3`

`h1` (verbatim): `Broadcasting engine events`

Lede (verbatim):

> `Phoenix.PubSub` is a publish/subscribe registry running as a named process tree in your application. You publish with `broadcast(server, topic, message)` and it delivers that message to every process subscribed to the **topic** — a plain string like `"courses"`. The message is any term; the convention is a tagged tuple naming a domain event, `{:course_created, course}`, so a handler can pattern-match it. The design question is not how to call broadcast — it is one line — but **where**. The answer follows the F6.04 boundary: the **context** broadcasts, right after a successful write, because creating a course is a domain fact and the rest of the system should hear about it regardless of who triggered it. The web layer never broadcasts; it would couple the domain's events to one delivery path. A small piece of plumbing keeps this clean: a `broadcast/2` helper that fires only on `{:ok, _}` and passes errors through untouched, and a facade wrapper so the **server name** and the topics live in one place rather than scattered through the codebase.

Kicker (verbatim):

> Four parts: the three pieces of a broadcast, where it belongs in the layers, broadcasting from a context in code, and the facade wrapper plus supervision setup.

## Sections

In order (the `toc-mini`):

1. `#what` · **Server, topic, message** — the three things a broadcast names: the PubSub server (named registry), the topic (string channel), and `broadcast/3` (the call). Interactive `solid-select`.
2. `#where` · **Where the broadcast belongs** — the broadcast lives in the context, right after the write; any caller (web form, live form, import script) emits the same event for free. Static layer diagram.
3. `#code` · **Broadcasting from a context** — `create_course/1` pipes the insert result into a private `broadcast/2` helper that fires only on success and returns the result unchanged. Code block.
4. `#wrap` · **The facade wrapper** — the `Portal` facade wraps `subscribe`/`broadcast` so `Portal.PubSub` appears once; the server is started in the application supervision tree. Code block, `.bridge`, `.note`.

Running example: creating a course (`Portal.Catalog.create_course/1`) and broadcasting `{:course_created, course}` on the `"courses"` topic.

Real Elixir code shown (two blocks):
- `# Portal.Catalog — broadcast a domain event after the write` — `def create_course(attrs)` building `%Course{}` and threading the result through a private `broadcast/2` helper (success-only).
- `# Portal facade — one home for the PubSub server name and topics` — `def subscribe(topic)` → `Phoenix.PubSub.subscribe(Portal.PubSub, topic)`, `def broadcast(topic, message)` → `Phoenix.PubSub.broadcast(Portal.PubSub, topic, message)`, with the supervision note `children = [{Phoenix.PubSub, name: Portal.PubSub}, ...]`.

## The interactives

### Figure — `A broadcast · select one` (`#what`)
- `<figure class="fig">`, title id `bcTitle` (`A broadcast · select one`).
- Control group `#bcSel` (`role="group"`, label `Broadcast piece`), buttons: `data-k="broadcast"` (label `broadcast/3`, active), `data-k="topic"` (label `a topic`), `data-k="server"` (label `the PubSub server`).
- SVG rows: `#bcRow_broadcast`, `#bcRow_topic`, `#bcRow_server`.
- Readout `#bcOut` (`aria-live="polite"`), plus `piece:` `#bcRole` and `does:` `#bcResult`. Pure function `pick(k)` repaints the selected row and writes the readout from the `P` table (HTML-escaping `<`/`>` in the description).
- Readout `does` strings VERBATIM: broadcast → `send a message to all subscribers`; topic → `the string a message is sent on`; server → `the named process that routes`. Each appends its `desc`, e.g. topic: "A topic is an agreed string such as "courses". Subscribers join it by name; you can scope per resource with "course:" <> id, or use a broad topic for the whole collection."
- Take (verbatim): `A topic is only an agreed string, so naming it is a design choice. Per-resource topics like "course:" <> id let a subscriber listen to one record; a broad "courses" topic carries every change to the collection.`

### Figure — `caller → context (writes & broadcasts) → PubSub` (`#where`)
- `<figure class="fig">`, title id `bcWhereTitle`. Static diagram (no controls): `ANY CALLER` (web form / live form / import script) → `CONTEXT · create_course/1` (`Repo.insert() → {:ok, course}` then `broadcast {:course_created, course}`) → `PubSub "courses"`.
- Take (verbatim): `This mirrors F5 exactly: the engine recorded an event when a fact occurred, independent of any caller. PubSub is the live delivery of that same idea — the event is born in the domain and travels outward.`

Code-section takes (verbatim):
- `#code`: `Threading the broadcast through the pipeline keeps the happy path readable and the error path…` (the `.take` continues in the markup).
- `#wrap` `.bridge`: `domain emits` ("The context broadcasts the event after a successful write.") → `facade hides the server` ("One wrapper holds Portal.PubSub; topics stay domain concepts.").

### Footer build-stamp decoder
- `#stamp` / `#stampId` real id: `TSK0NdYA6xgfwm`. Decoded: namespace `TSK`, snowflake `319988563959611392`, node `0`, seq `0`, timestamp `2026-06-02 00:00:18 UTC` (matches the static `st-ts`). Shared branded-Snowflake decoder.

## References (#refs, verbatim)

This dive has **no References section** (`#refs`). The only `refs` token in the file is the CSS rule comment `/* ---- references ---- */`; there is no `<h2>References</h2>` block, no Sources list, and no "Related in this course" list. Cross-links instead live inline in the `#wrap` `.note` (forward to `/elixir/phoenix/pubsub/subscribe`) and in the pager/footer (below).

## Wiring

- route-tag (verbatim): `/ elixir / phoenix / pubsub / broadcast` — `<a href="/elixir">elixir</a> / <a href="/elixir/phoenix">phoenix</a> / <a href="/elixir/phoenix/pubsub">pubsub</a> / <span class="rcur">broadcast</span>`.
- crumbs (verbatim): `F6` → `/elixir/phoenix`, `F6.07` → `/elixir/phoenix/pubsub`, then `broadcast` (`here`).
- toc-mini: `Server, topic, message` (`#what`), `Where the broadcast belongs` (`#where`), `Broadcasting from a context` (`#code`), `The facade wrapper` (`#wrap`).
- pager: prev → `/elixir/phoenix/pubsub` (`F6.07 · overview`); next → `/elixir/phoenix/pubsub/subscribe` (`Next · subscribing a LiveView`).
- footer: column **Chapters** — `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. Column **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Brand line links `/elixir`.
- Page meta — `<title>`: `Broadcasting engine events — F6.07.1 · jonnify`. `<meta name="description">`: `Phoenix.PubSub is process-to-process publish/subscribe over a string topic. The domain broadcasts an event after a successful write — the context emits it, not the web layer — and a thin facade wrapper keeps the PubSub server name and the topics in one place, started in the application supervision tree.`

## Build instruction

To (re)build this dive, copy the `head`…`</style>`, the `header.site`, the `footer.site-foot`, and the trailing `<script>` blocks verbatim from a recent BUILT F6.07 sibling on the blue accent; change only `<title>`/`<meta>`, the `route-tag`, the `crumbs`, and the `<main>` body. Keep the dive anatomy: hero (eyebrow → `h1` → lede + kicker → `toc-mini`) and four sections, each a `solid-select` or static `fig` with a `.take` or a `pre.code` block, then a closing `.bridge` + `.note`, the pager, and the footer build-stamp (this dive carries no `#refs` block — do not add one). No-invent guards: use only the real Portal surfaces as written — `Phoenix.PubSub`, `broadcast(server, topic, message)`, `Portal.PubSub` (the named server in the supervision tree), the private success-only `broadcast/2` helper, the `Portal` facade `subscribe/1` + `broadcast/2`, `Portal.Catalog.create_course/1`, and the `{:course_created, course}` event tuple; cite the companion course for OTP supervision/message-passing internals rather than re-teaching them. Voice: no first person, no exclamation marks, no emoji, none of just/simply/obviously. Model sibling to copy from: `elixir/phoenix/pubsub/subscribe.html` (same module, same blue accent, identical dive anatomy with a `solid-select` figure + code blocks).
