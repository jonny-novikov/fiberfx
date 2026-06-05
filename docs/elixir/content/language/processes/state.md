# F3.07.3 — Holding state in a loop (dive)

- Route (served): `/elixir/language/processes/state`
- File: `elixir/language/processes/state.html`
- Place in the chapter: the third and final dive under the F3.07 processes hub. It closes the actor arc — state as the argument to a recursive `receive` loop, tail-called forward after each message — and bridges into F3.08 (OTP), where the hand-written loop becomes `handle_call/3` under a supervisor. It follows F3.07.2 (messages). Teaching arc: spawn → messages → state.
- Accent: elixir (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F3.07 · part 3 of 3`

Hero h1 (verbatim): Holding state in a loop

Lede (verbatim):

> A process has no variables that outlive a single message. What it has is a recursive loop: after handling a message, the process tail-calls itself with updated state. The state is the loop's argument, living in a function that never returns. This recursive `receive` is exactly what `GenServer` abstracts in F3.08.

Kicker (verbatim):

> The portal runs a tally process that counts events. It loops on a count, answers `:inc` and `{:get, from}`, and carries the running total forward. Step through three messages and watch the state move through the loop.

## Sections

In order:
1. `#loop` "State through the loop" — the teaching section. Each turn of the loop receives one message, computes the next state, and recurses with it; `:inc` raises the count, `{:get, from}` replies and keeps the count the same. Carries the interactive figure.
2. `#server` "The whole server" — start the loop with an initial state, then drive it with messages; the recursion is in tail position so memory stays steady. This is a hand-written `GenServer`. Carries the static code block + the `.bridge`.

Running example: the Portal's tally (counter) process — `loop(count)` answering `:inc` and `{:get, from}`.

Real Elixir code shown (the `#server` static `pre.code`, verbatim):

```
def loop(count) do
  receive do
    :inc         -> loop(count + 1)
    {:get, from} -> send(from, count); loop(count)
  end
end

counter = spawn(fn -> loop(0) end)   # starts holding 0
send(counter, :inc)
send(counter, :inc)
send(counter, {:get, self()})
receive do n -> n end                  # => 2
```

## The interactives

### Figure — "Message in the sequence · select one" (`#lpTitle`)
- `<figure class="fig">` with control group `#lpSel` (`role="group"`, label `Message in the sequence`). Buttons by `data-k`/`data-c`/label:
  - `data-k="s1"` `data-c="elixir"` (active) — `msg 1 · :inc`
  - `data-k="s2"` `data-c="blue"` — `msg 2 · :inc`
  - `data-k="s3"` `data-c="gold"` — `msg 3 · {:get}`
- SVG element ids: `#lpInBox` / `#lpIn` (state in — `loop(count)`), `#lpMsgBox` / `#lpMsg` (message received), the two clause rows `#lpC0` / `#lpC1` (clause taken — match-highlighted), `#lpNext` (next loop), `#lpReply` (reply). A live code block `#lpCode` (`pre.code`) and readout `#lpOut` (`.geo-readout`), both `aria-live="polite"`.
- Static clause text in the markup: clause 0 `:inc -> loop(count + 1)`; clause 1 `{:get, from} -> send(from, count); loop(count)`.
- Driver: `pick(k)` reads the `CASES` table — `match` selects which clause row highlights (`0` for `:inc`, `1` for `{:get}`) and sets the state-in text, the message + its stroke, next-loop text, reply, code, and readout.
- State-in `#lpIn` strings VERBATIM: `s1` → `count = 0`; `s2` → `count = 1`; `s3` → `count = 2`.
- Message `#lpMsg` strings VERBATIM: `s1` → `:inc`; `s2` → `:inc`; `s3` → `{:get, from}`.
- Next-loop `#lpNext` strings VERBATIM: `s1` → `loop(1)`; `s2` → `loop(2)`; `s3` → `loop(2)`.
- Reply `#lpReply` strings VERBATIM: `s1` → `—`; `s2` → `—`; `s3` → `2 sent to the caller`.
- Readout `#lpOut` strings VERBATIM:
  - `s1`: "The message `:inc` matches the first clause, which recurses with `count + 1`. The state goes from 0 to 1 with no variable reassigned — a new call holds the new value."
  - `s2`: "A second `:inc` arrives at `loop(1)` and recurses to `loop(2)`. Each message is one turn of the loop, and the count accumulates across them."
  - `s3`: "The `{:get, from}` clause sends the current count, 2, to the caller and recurses with the same value. A read replies without changing the state."
- Live code block `#lpCode` per case (decoded from `CASES.code`) VERBATIM:
  - `s1`: `# current call: loop(0)` / `receive do` / `  :inc -> loop(count + 1)     # 0 + 1` / `end` / `# tail-calls loop(1)`
  - `s2`: `# current call: loop(1)` / `receive do` / `  :inc -> loop(count + 1)     # 1 + 1` / `end` / `# tail-calls loop(2)`
  - `s3`: `# current call: loop(2)` / `receive do` / `  {:get, from} ->` / `    send(from, count)          # sends 2` / `    loop(count)              # state unchanged` / `end` / `# caller receives 2; loop continues as loop(2)`
- Takeaway (verbatim): "Nothing mutates. Each message produces a fresh state value handed to the next call, and the process stays alive because the loop never returns — it only recurses."

### Degrade behaviour
- The figure ships static `s1`-case markup (state `count = 0`, message `:inc`, clause 0 highlighted, next `loop(1)`, reply `—`); `pick('s1')` runs on load. `#server` shows a full static code block needing no JS. `.reveal` content is visible without JS; `prefers-reduced-motion: reduce` disables the `.arc-flow` and reveal transitions.

### Footer build-stamp decoder
- Stamp id: `TSK0NbQWloYbHU`. Namespace `TSK`; the branded-Snowflake decoder (base-62, epoch `1704067200000`) fills the panel. Markup-printed `#st-ts` timestamp: `2026-05-31 17:18:15 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/elixir/processes.html` — Processes — Elixir documentation — spawn, send, receive.
- `https://en.wikipedia.org/wiki/Actor_model` — Actor model — Wikipedia — the concurrency model.
- `https://erlang.org/download/armstrong_thesis_2003.pdf` — Armstrong, J. (2003). *Making reliable distributed systems in the presence of software errors.* — isolation and message passing.

Related in this course:
- `/elixir/language/processes` — F3.07 · Processes & the actor model
- `/elixir/language/processes/spawn` — Spawning a process
- `/elixir/language/otp` — F3.08 · OTP: GenServer & supervisors

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/ ` `language` `/ ` `processes` `/ ` `state` (with `state` as the current `.rcur` segment; `elixir`, `language`, `processes` are links).
- crumbs (verbatim): `F3` `/` `F3.07` `/` `state` (the last is `.here`).
- toc-mini: `#loop` "State through the loop"; `#server` "The whole server".
- pager: prev → `/elixir/language/processes/messages` "F3.07.2 · messages"; next → `/elixir/language` "Back to F3 · The Elixir Language".
- footer columns:
  - Chapters: `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework).
  - The course: `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta:
  - `<title>`: `Holding state in a loop — F3.07.3 · jonnify`
  - `<meta name="description">`: `A process holds state as the argument to a recursive receive loop, tail-calling itself with the updated value after each message — a hand-written GenServer, and the bridge into OTP.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, the `header`, the `footer`, and the trailing two `<script>` blocks (branded-Snowflake decoder + reveal observer) verbatim from a recent BUILT sibling on this chapter accent — the closest model is its own sibling `/elixir/language/processes/messages` (`elixir/language/processes/messages.html`), the F3.07.2 dive with the identical dive anatomy (eyebrow `part N of 3`, two teaching sections, a `select-one` figure with `#…Sel`/`CASES`/match-highlighted clause rows/live `pre.code`+`.geo-readout`, a `.bridge`, References, pager). Change only `<title>`/`<meta description>`, the `route-tag`, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written (the tally/counter `loop(count)`) and the real BEAM primitives (`spawn/1`, `send`, `receive`, tail-recursion, `self/0`); the platform is a branded event-sourced store behind ONE `Portal` facade fronting a Phoenix web app — cite the companion course for `GenServer`/OTP internals (`handle_call/3`, supervision) rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of *just*/*simply*/*obviously*.
