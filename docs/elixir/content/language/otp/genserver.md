# F3.08.1 — The GenServer behaviour (dive)

- Route (served): `/elixir/language/otp/genserver`
- File: `elixir/language/otp/genserver.html`
- Place in the chapter: the first of the three F3.08 dives, part 1 of 3. It opens the OTP arc — the GenServer behaviour and its callbacks — before F3.08.2 (call & cast) and F3.08.3 (supervisors). It turns the hand-written `receive` loop of F3.07 into a behaviour with named callbacks.
- Accent: elixir (purple) — `--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F3.08 · part 1 of 3`

H1 (verbatim): `The GenServer behaviour`

Hero lede (verbatim):

> A GenServer is a behaviour (F3.06) that abstracts the receive loop (F3.07). You implement callbacks — `init/1` sets the starting state, `handle_call/3` answers synchronous requests, `handle_cast/2` handles asynchronous ones — and the framework runs the loop, the mailbox, and the replies. The state you return threads into the next callback.

Kicker (verbatim):

> The portal's hand-written tally becomes a GenServer. Each callback returns a tagged tuple that tells the framework what to reply and what the next state is. Select a callback and read its return and its effect on the state.

## Sections

In order:

1. `#callbacks` — "The callbacks and their returns" — one teaching section built around the interactive callback picker. Prose: `init/1` returns `{:ok, state}`; `handle_call/3` returns `{:reply, value, state}`; `handle_cast/2` returns `{:noreply, state}`.
2. `#module` — "The whole module" — the advanced/applied section. Shows the full `Portal.Tally` module verbatim, then a `bridge` (F3.07 hand-written loop → `use GenServer`) and a `.note` linking to call & cast.

Running example: `Portal.Tally`, a GenServer wrapping a counter.

Real Elixir code shown (the full module, verbatim from the page):

```
defmodule Portal.Tally do
  use GenServer

  # client API
  def start_link(n), do: GenServer.start_link(__MODULE__, n)

  # callbacks
  @impl true
  def init(n), do: {:ok, n}

  @impl true
  def handle_call(:get, _from, count), do: {:reply, count, count}

  @impl true
  def handle_cast(:inc, count), do: {:noreply, count + 1}
end
```

## The interactives

One interactive figure: `figure.fig`, labelled by `#gsTitle` "The callback · select one". Control group `#gsSel` (role `group`, aria-label "The callback"), three buttons:
- `data-k="init"` `data-c="elixir"` (active by default) — label `init/1`
- `data-k="call"` `data-c="blue"` — label `handle_call/3`
- `data-k="cast"` `data-c="sage"` — label `handle_cast/2`

SVG element ids: three callback rows `#gsR0`/`#gsR1`/`#gsR2` with selected-markers `#gsM0`/`#gsM1`/`#gsM2`; the RETURNS field `#gsRet`; the STATE field `#gsState`. Live code block `#gsCode` and readout `#gsOut` are rewritten on each pick.

Pure function: `pick(k)` looks up `CASES[k]`, highlights the matching row (`SAGE` stroke on `gsR<match>`, opacity 1 on `gsM<match>`), and sets `#gsRet`, `#gsState`, `#gsCode`, and `#gsOut`.

Per-case values VERBATIM:
- `init` — `match: 0`, RETURNS `{:ok, 0}`, STATE `starts at 0`. Code: `def init(_arg) do` / `  {:ok, 0}        # initial state: the tally starts at 0` / `end`. Out: "`init/1` runs once when the server starts and returns `{:ok, state}`. The tally begins at 0, and that value becomes the state passed to the first message."
- `call` — `match: 1`, RETURNS `{:reply, count, count}`, STATE `count → count`. Code: `def handle_call(:get, _from, count) do` / `  {:reply, count, count}   # reply with count, keep it` / `end`. Out: "`handle_call/3` answers a synchronous request. `{:reply, value, new_state}` sends `value` back to the caller and keeps `new_state`. Here it replies with the count and leaves it unchanged."
- `cast` — `match: 2`, RETURNS `{:noreply, count + 1}`, STATE `count → count + 1`. Code: `def handle_cast(:inc, count) do` / `  {:noreply, count + 1}  # no reply, new state` / `end`. Out: "`handle_cast/2` handles an asynchronous message with no reply. `{:noreply, new_state}` updates the state silently. Here it increments the count."

Static default in markup: row 0 (`init(arg)`) is the selected row (`#gsM0` opacity 1, sage stroke); RETURNS shows `{:ok, 0}` and STATE shows `starts at 0` before JS runs.

Takeaway (`.take`, verbatim): "The return tuple is the whole contract with the framework: its tag decides whether the caller gets a reply, and its last element becomes the state handed to the next message."

Degrade behaviour: the figure carries its `init`-case defaults in the static SVG markup, so it reads without JS. The `.reveal` references section is shown immediately when `IntersectionObserver` is absent or `prefers-reduced-motion: reduce`.

Footer build-stamp decoder: `#stamp` holds id `TSK0NbRgFVmqq8`; `decodeBranded` splits namespace `TSK` from the base-62 Snowflake with `EPOCH_MS = 1704067200000`. The static fallback timestamp in markup is `2026-05-31 17:34:23 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `GenServer` — Elixir documentation — `https://hexdocs.pm/elixir/GenServer.html` — the stateful server behaviour and its callbacks.
- Mix & OTP: GenServer — Elixir documentation — `https://hexdocs.pm/elixir/genservers.html` — building one step by step.
- `Supervisor` — Elixir documentation — `https://hexdocs.pm/elixir/Supervisor.html` — fault tolerance and restarts.

Related in this course:
- `/elixir/language/otp` — F3.08 · OTP: GenServer & supervisors
- `/elixir/language/processes` — F3.07 · Processes & the actor model
- `/elixir/language/protocols/behaviours` — F3.06 · Behaviours

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `language` `/` `otp` `/` `genserver` — `elixir`, `language`, `otp` link to `/elixir`, `/elixir/language`, `/elixir/language/otp`; `genserver` is the current segment (`.rcur`).
- crumbs (verbatim): `F3` (→ `/elixir/language`) `/` `F3.08` (→ `/elixir/language/otp`) `/` `genserver` (here).
- toc-mini: `#callbacks` "The callbacks and their returns"; `#module` "The whole module".
- pager: prev → `/elixir/language/otp` label `← F3.08 · otp`; next → `/elixir/language/otp/call-cast` label `Next · call & cast →`.
- footer columns: Chapters — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). The course — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta: `<title>` = `The GenServer behaviour — F3.08.1 · jonnify`; `<meta name="description">` = "A GenServer abstracts the receive loop into a behaviour: init/1 sets the state, handle_call/3 answers synchronous requests, handle_cast/2 handles asynchronous ones, and each return tuple threads the next state."

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the trailing two `<script>` blocks (the figure picker plus the Branded-Snowflake decoder, and the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling on this chapter accent; the model sibling to copy from is the companion dive `elixir/language/otp/call-cast.html` (same F3.08 dive layout — hero `crumbs` + `eyebrow` + `lede` + `kicker`, one `solid-select` figure with a live `pre.code#…Code` plus `geo-readout`, a code-only applied section with a `bridge`, then refs + pager). Change only `<title>` / `<meta description>`, the `route-tag` (current segment `genserver`), the `crumbs`/`eyebrow`, and the `<main>` body. No-invent guards: use only the real OTP surfaces as written — `use GenServer`, `init/1`, `handle_call/3`, `handle_cast/2`, the return tuples `{:ok, state}` / `{:reply, value, state}` / `{:noreply, state}`, `GenServer.start_link/2`, and the running example `Portal.Tally`; cite the linked HexDocs GenServer page for behaviour internals and do not re-teach them; do not invent a route, id, readout string, code token, or reference URL. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
