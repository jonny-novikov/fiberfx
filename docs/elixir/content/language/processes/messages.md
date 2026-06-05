# F3.07.2 — Sending & receiving messages (dive)

- Route (served): `/elixir/language/processes/messages`
- File: `elixir/language/processes/messages.html`
- Place in the chapter: the second of three dives under the F3.07 processes hub. It teaches the actor protocol — `send` into a mailbox, `receive` to pattern-match out, and carrying `self()` so the server can reply. It follows F3.07.1 (spawn) and leads into F3.07.3 (state). Teaching arc: spawn → messages → state.
- Accent: elixir (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F3.07 · part 2 of 3`

Hero h1 (verbatim): Sending & receiving messages

Lede (verbatim):

> Processes share no memory, so they coordinate by messages. `send(pid, term)` drops any term into the target's mailbox and returns at once; `receive` pattern-matches messages out of the mailbox, one at a time. A message can carry a PID, which is how the receiver knows where to reply. That is the entire actor protocol.

Kicker (verbatim):

> The portal runs a small summary server: send it a request with your own PID, and it sends a result back. Choose a message and watch which `receive` clause matches — and what happens to a message that matches none.

## Sections

In order:
1. `#mailbox` "The mailbox and receive" — the teaching section. The server loops on a `receive` with two clauses; a matching message is pulled and handled, a non-matching one stays queued for a later receive (selective receive). Carries the interactive figure.
2. `#reply` "Replying with self()" — `send` is one-way, so a request that wants an answer includes the caller's PID from `self/0`; two one-way sends make a round trip. Carries the static code block + the `.bridge`.

Running example: the Portal's small summary server (`Portal.Summary.summarize/1`), answering `{:summarize, …}` and `{:ping, from}`.

Real Elixir code shown (the `#reply` static `pre.code`, verbatim):

```
# caller side
send(server, {:summarize, user, self()})
receive do
  summary -> summary        # => "ada@portal.dev · student"
end

# server side, inside its loop
receive do
  {:summarize, entity, from} ->
    send(from, Portal.Summary.summarize(entity))
end
```

## The interactives

### Figure — "The incoming message · select one" (`#srTitle`)
- `<figure class="fig">` with control group `#srSel` (`role="group"`, label `The incoming message`). Buttons by `data-k`/`data-c`/label:
  - `data-k="summarize"` `data-c="elixir"` (active) — `{:summarize, …}`
  - `data-k="ping"` `data-c="blue"` — `{:ping, from}`
  - `data-k="unknown"` `data-c="sage"` — `{:delete, 7}`
- SVG element ids: `#srMbox` / `#srMsg` (the incoming message at the front of the mailbox), the two clause rows `#srC0` / `#srC1` with match markers `#srM0` / `#srM1` (the `matched` tag), `#srReply` (the reply sent to the caller). A live code block `#srCode` (`pre.code`) and readout `#srOut` (`.geo-readout`), both `aria-live="polite"`.
- Static clause text in the markup: clause 0 `{:ping, from} -> send(from, :pong)`; clause 1 `{:summarize, e, from} -> send(from, Summary.summarize(e))`.
- Driver: `pick(k)` reads the `CASES` table — `match` selects which clause row highlights (`1`, `0`, or `-1` for none) and sets the message stroke, reply text, code, and readout.
- Incoming `#srMsg` strings VERBATIM: `summarize` → `{:summarize, %User{email: "ada@portal.dev"}, from}`; `ping` → `{:ping, from}`; `unknown` → `{:delete, 7}`.
- Reply `#srReply` strings VERBATIM: `summarize` → `"ada@portal.dev · student"`; `ping` → `:pong`; `unknown` → `no clause matches — message kept in the mailbox`.
- Readout `#srOut` strings VERBATIM:
  - `summarize`: "The message matches the `{:summarize, e, from}` clause. The server runs `Portal.Summary.summarize/1` and sends the result to the PID carried in `from`."
  - `ping`: "A `{:ping, from}` matches the first clause and the server replies `:pong` to the caller. A health check costs one send each way."
  - `unknown`: "The tuple `{:delete, 7}` matches no clause, so it is left in the mailbox rather than dropped. The next `receive` with a matching clause will pick it up."
- Live code block `#srCode` per case (decoded from `CASES.code`) VERBATIM:
  - `summarize`: `receive do` / `  {:summarize, entity, from} ->` / `    send(from, Portal.Summary.summarize(entity))` / `end` / `# the caller receives: "ada@portal.dev · student"`
  - `ping`: `receive do` / `  {:ping, from} -> send(from, :pong)` / `end` / `# the caller receives: :pong`
  - `unknown`: `receive do` / `  {:ping, from} -> send(from, :pong)` / `  {:summarize, e, from} -> send(from, Summary.summarize(e))` / `end` / `# {:delete, 7} matches neither clause` / `# it stays in the mailbox for a later receive`
- Takeaway (verbatim): "Selective receive is the quiet detail: a message that no clause matches waits in the mailbox rather than being dropped. A process reads exactly the messages it is ready for, in the order it chooses."

### Degrade behaviour
- The figure ships static `summarize`-case markup (mailbox text the `%User{…}` tuple, clause 1 marked `matched` with `opacity="1"`, reply `"ada@portal.dev · student"`); `pick('summarize')` runs on load. `#reply` shows a full static code block needing no JS. `.reveal` content is visible without JS; `prefers-reduced-motion: reduce` disables the `.arc-flow` and reveal transitions.

### Footer build-stamp decoder
- Stamp id: `TSK0NbQWlP0hZg`. Namespace `TSK`; the branded-Snowflake decoder (base-62, epoch `1704067200000`) fills the panel. Markup-printed `#st-ts` timestamp: `2026-05-31 17:18:15 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/elixir/processes.html` — Processes — Elixir documentation — spawn, send, receive.
- `https://en.wikipedia.org/wiki/Actor_model` — Actor model — Wikipedia — the concurrency model.
- `https://erlang.org/download/armstrong_thesis_2003.pdf` — Armstrong, J. (2003). *Making reliable distributed systems in the presence of software errors* — concurrency-oriented programming: isolation and message passing.

Related in this course:
- `/elixir/language/processes` — F3.07 · Processes & the actor model
- `/elixir/language/processes/state` — Holding state in a loop
- `/elixir/language/otp` — F3.08 · OTP: GenServer & supervisors

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/ ` `language` `/ ` `processes` `/ ` `messages` (with `messages` as the current `.rcur` segment; `elixir`, `language`, `processes` are links).
- crumbs (verbatim): `F3` `/` `F3.07` `/` `messages` (the last is `.here`).
- toc-mini: `#mailbox` "The mailbox and receive"; `#reply` "Replying with self()".
- pager: prev → `/elixir/language/processes/spawn` "F3.07.1 · spawn"; next → `/elixir/language/processes/state` "Next · state loop".
- footer columns:
  - Chapters: `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework).
  - The course: `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta:
  - `<title>`: `Sending & receiving messages — F3.07.2 · jonnify`
  - `<meta name="description">`: `send/2 appends a term to a mailbox and returns; receive pattern-matches messages out, leaving unmatched ones queued; a message carries self() so the server can reply — the whole actor protocol.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, the `header`, the `footer`, and the trailing two `<script>` blocks (branded-Snowflake decoder + reveal observer) verbatim from a recent BUILT sibling on this chapter accent — the closest model is its own sibling `/elixir/language/processes/state` (`elixir/language/processes/state.html`), the F3.07.3 dive with the identical dive anatomy (eyebrow `part N of 3`, two teaching sections, a `select-one` figure with `#…Sel`/`CASES`/match-highlighted clause rows/live `pre.code`+`.geo-readout`, a `.bridge`, References, pager). Change only `<title>`/`<meta description>`, the `route-tag`, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written (`Portal.Summary.summarize/1`, a summary server) and the real BEAM primitives (`send/2`, `receive`, `self/0`, selective receive, `#PID<…>`); the platform is a branded event-sourced store behind ONE `Portal` facade fronting a Phoenix web app — cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of *just*/*simply*/*obviously*.
