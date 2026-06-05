# F3.08.2 — Synchronous call, asynchronous cast (dive)

- Route (served): `/elixir/language/otp/call-cast`
- File: `elixir/language/otp/call-cast.html`
- Place in the chapter: the second of the three F3.08 dives, part 2 of 3. It sits between F3.08.1 (the GenServer behaviour) and F3.08.3 (supervisors), teaching the two ways a client reaches the callbacks F3.08.1 defined.
- Accent: elixir (purple) — `--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F3.08 · part 2 of 3`

H1 (verbatim): `Synchronous call, asynchronous cast`

Hero lede (verbatim):

> Two ways to message a GenServer. `GenServer.call` sends a request and blocks until the server replies, returning the value — a round trip. `GenServer.cast` sends a request and returns `:ok` at once, without waiting — fire and forget. `call` routes to `handle_call`, `cast` to `handle_cast`.

Kicker (verbatim):

> Choose based on whether the caller needs an answer. A read wants `call`; a fire-and-forget update wants `cast`. Select each and watch where it routes and what the client gets back.

## Sections

In order:

1. `#route` — "Where each one routes" — the teaching section around the interactive request picker. Prose: `call` makes the caller wait for the reply; `cast` lets it move on immediately; the cost of `call` is the wait — past the timeout the caller exits.
2. `#api` — "A clean client API" — the applied section. Shows the wrapped client API verbatim, then a `bridge` ("ask and wait" vs "tell and move on") and a `.note` linking to supervisors.

Running example: `Portal.Tally` reached through wrapper functions `Tally.get/1` (sync) and `Tally.inc/1` (async).

Real Elixir code shown (the `#api` block, verbatim from the page):

```
defmodule Portal.Tally do
  # ... use GenServer, init, handle_call, handle_cast ...

  def get(pid), do: GenServer.call(pid, :get)   # sync: returns the count
  def inc(pid), do: GenServer.cast(pid, :inc)   # async: returns :ok
end

Tally.inc(tally)   # => :ok   (fire and forget)
Tally.inc(tally)   # => :ok
Tally.get(tally)   # => 2     (waits for the reply)
```

## The interactives

One interactive figure: `figure.fig`, labelled by `#ccTitle` "The client request · select one". Control group `#ccSel` (role `group`, aria-label "The client request"), three buttons:
- `data-k="call"` `data-c="elixir"` (active by default) — label `call :get`
- `data-k="cast"` `data-c="blue"` — label `cast :inc`
- `data-k="timeout"` `data-c="sage"` — label `call (timeout)`

SVG element ids recoloured/relabelled on pick: `#ccClient` / `#ccClientT` (the client lane), `#ccArr` / `#ccArrHead` / `#ccArrLbl` (the routing arrow), `#ccServer` / `#ccServerT` (the routed-to callback lane), `#ccRet` / `#ccRetT` (the "client receives" box). Live code block `#ccCode` and readout `#ccOut` are rewritten on each pick.

Pure function: `pick(k)` looks up `CASES[k]` and sets every lane's stroke/fill/text, plus `#ccCode` and `#ccOut`.

Per-case values VERBATIM:
- `call` — client text `blocks until the server replies`; arrow label `call (sync)`; server text `handle_call(:get, _from, count)`; client receives `2`. Code: `count = GenServer.call(tally, :get)` / `# blocks until handle_call replies` / `# => 2`. Out: "A `call` routes to `handle_call/3`, which returns `{:reply, value, state}`. The caller waits for that reply and receives the value — here, the count 2."
- `cast` — client text `returns :ok at once, does not wait`; arrow label `cast (async)`; server text `handle_cast(:inc, count)`; client receives `:ok`. Code: `:ok = GenServer.cast(tally, :inc)` / `# returns at once; handle_cast runs after` / `# => :ok`. Out: "A `cast` routes to `handle_cast/2`, which returns `{:noreply, state}`. The caller does not wait and gets `:ok` — no value, no confirmation that the work has run yet."
- `timeout` — client text `waits, then exits :timeout`; arrow label `call · 1000 ms`; server text `still working — no reply yet`; client receives `** (exit) :timeout`. Code: `GenServer.call(slow, :report, 1_000)` / `# no reply within 1000 ms` / `# ** (exit) {:timeout, {GenServer, :call, ...}}`. Out: "A `call` waits at most for its timeout, 5000 ms by default and 1000 ms here. If the server has not replied by then, the caller exits with `:timeout`. The server itself keeps running."

Static default in markup: the `call` case — client text `blocks until the server replies`, arrow `call (sync)`, server `handle_call(:get, _from, count)`, client receives `2`.

Takeaway (`.take`, verbatim): "A `cast` is faster for the caller but tells you nothing — not even that the server is alive. A `call` confirms the work and returns a value, at the price of waiting. The choice is about whether you need the answer, not about speed alone."

Degrade behaviour: the figure renders its `call`-case defaults from the static SVG markup with no JS. The `.reveal` references section shows immediately when `IntersectionObserver` is absent or under `prefers-reduced-motion: reduce`.

Footer build-stamp decoder: `#stamp` holds id `TSK0NbRgFsmMNM`; `decodeBranded` splits namespace `TSK` from the base-62 Snowflake with `EPOCH_MS = 1704067200000`. The static fallback timestamp in markup is `2026-05-31 17:34:24 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `GenServer` — Elixir documentation — `https://hexdocs.pm/elixir/GenServer.html` — the stateful server behaviour, `call` and `cast`.
- Mix & OTP: GenServer — Elixir documentation — `https://hexdocs.pm/elixir/genservers.html` — building one step by step.
- `Supervisor` — Elixir documentation — `https://hexdocs.pm/elixir/Supervisor.html` — fault tolerance and restarts.

Related in this course:
- `/elixir/language/otp` — F3.08 · OTP: GenServer & supervisors
- `/elixir/language/otp/genserver` — GenServer, the server behaviour
- `/elixir/language/otp/supervisors` — Supervisors & restart strategies

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `language` `/` `otp` `/` `call-cast` — `elixir`, `language`, `otp` link to `/elixir`, `/elixir/language`, `/elixir/language/otp`; `call-cast` is the current segment (`.rcur`).
- crumbs (verbatim): `F3` (→ `/elixir/language`) `/` `F3.08` (→ `/elixir/language/otp`) `/` `call-cast` (here).
- toc-mini: `#route` "Where each one routes"; `#api` "A clean client API".
- pager: prev → `/elixir/language/otp/genserver` label `← F3.08.1 · genserver`; next → `/elixir/language/otp/supervisors` label `Next · supervisors →`.
- footer columns: Chapters — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). The course — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta: `<title>` = `Synchronous call, asynchronous cast — F3.08.2 · jonnify`; `<meta name="description">` = "GenServer.call sends a request and blocks for the reply, routing to handle_call; GenServer.cast returns :ok at once, routing to handle_cast; a clean client API wraps both so callers never touch the raw message tags."

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the trailing two `<script>` blocks (the figure picker plus the Branded-Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling on this chapter accent; the model sibling to copy from is the adjacent dive `elixir/language/otp/genserver.html` (the same F3.08 dive layout — hero `crumbs`/`eyebrow`/`lede`/`kicker`, one `solid-select` figure with a live `pre.code` plus `geo-readout`, a code-only applied section with a `bridge`, then refs + pager). Change only `<title>` / `<meta description>`, the `route-tag` (current segment `call-cast`), the `crumbs`/`eyebrow`, and the `<main>` body. No-invent guards: use only the real OTP surfaces as written — `GenServer.call/2`, `GenServer.call/3` (with a timeout), `GenServer.cast/2`, the return tuples `{:reply, value, state}` / `{:noreply, state}`, the `:timeout` exit, and the running example `Portal.Tally` with its wrapper functions `get/1` and `inc/1`; cite the linked HexDocs GenServer page for call/cast internals and do not re-teach them; do not invent a route, id, readout string, code token, or reference URL. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
