# F3.07 — Processes & the actor model (module hub)

- Route (served): `/elixir/language/processes`
- File: `elixir/language/processes/index.html`
- Place in the chapter: the seventh module of F3 · The Elixir Language. It introduces the BEAM process and the actor model, framing three dives — `spawn`, `messages`, `state` — that build the actor from its primitives. It follows F3.06 (protocols & behaviours) and leads into F3.08 (OTP: GenServer & supervisors), which wraps this whole pattern in a behaviour.
- Accent: elixir (purple) — `--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F3 · The actor model · module 7`

Hero h1 (verbatim): Concurrency: `processes` & the actor model

Lede (verbatim):

> A process is the BEAM's unit of concurrency — a lightweight, isolated worker with its own heap and its own mailbox, scheduled across every core. Processes share no memory. They coordinate only by sending messages. That is the actor model, and it is how Elixir does concurrency, state, and fault isolation all at once.

Kicker (verbatim):

> The portal runs work in processes: a session server here, a notifier there. This module builds the actor from three primitives — spawn a process, send and receive messages, then loop to hold state. F3.08 wraps the whole pattern in a `GenServer`.

## What the page frames

This hub does not use the `.mods`/`.dives` card grid; the three children are presented as a stacked list of full-width dive cards under the `#dives` section ("Three deep dives"), each with a coloured left border.

- F3.07.1 · Spawning a process — `spawn/1` starts a function as a new process and returns its PID at once; the child runs concurrently, with its own heap and crash boundary. Route: `/elixir/language/processes/spawn`. Built. (left border `--elixir`)
- F3.07.2 · Sending & receiving messages — `send/2` drops a term in a mailbox; `receive` matches it out. A message can carry a PID, so the receiver can reply. Route: `/elixir/language/processes/messages`. Built. (left border `--blue`)
- F3.07.3 · Holding state in a loop — State is the argument to a recursive `receive` loop; the process tail-calls itself with updated state — the pattern `GenServer` abstracts. Route: `/elixir/language/processes/state`. Built. (left border `--gold`)

The page also carries a teaching section `#actor` ("The actor in three moves") above the dives, and a `.bridge` connecting F3.06 (a module's contract — a behaviour, a static shape) → F3.07 (a running process — spawn that module and it comes alive). Running example throughout: a learning Portal (a session server, a notifier, a summary server).

## The interactives

### Hero figure — "Why a crash stays put"
- `<figure class="hero-fig">` labelled by `#isTitle` with `.fc-lbl` text `Why a crash stays put`.
- Caption banner text in the SVG: `TWO PROCESSES · SHARED NOTHING`.
- Left process group `#isLeft` (`#PID<0.118.0>`), its private heap `#isHeapL` / `#isHeapLt` (`{count: 7}`) / `#isStateL` (`alive`).
- Right process group `#isRight` (`#PID<0.119.0>`), heap text `{count: 7}`, state `#isStateR` (`alive`) — untouched.
- Message channel `#isChannel` (`#isLine`, `#isHead`, `#isMsg` = `:ping`); fault-boundary readout `#isBound` (`no shared state to corrupt`).
- Controls: `#isBtn` (`▸ crash the left process`, toggles to `▸ restart the left process`) and `#isReset` (`reset`).
- Caption `#isCap` (`aria-live="polite"`) readout strings VERBATIM:
  - default: `[ 0.118.0 alive · 0.119.0 alive ]` / `Two heaps, no shared memory; one message channel between them.`
  - crashed: `[ 0.118.0 crashed · 0.119.0 alive ]` / `The fault wiped one heap; the neighbour kept its own state.`
- On crash: left heap stroke `#c4504c`, heap text `× gone`, state `crashed`, boundary text `left heap wiped · right untouched`.
- This figure is a hand-toggled state machine (no pure compute function); a `crashed` boolean drives `render()`.

### Section figure — "The move · select one" (`#prTitle`)
- `<figure class="fig">` with control group `#prSel` (`role="group"`, label `The move`). Buttons by `data-k`/`data-c`/label:
  - `data-k="spawn"` `data-c="elixir"` (active) — `spawn`
  - `data-k="message"` `data-c="blue"` — `send / receive`
  - `data-k="loop"` `data-c="gold"` — `loop`
- SVG element ids: `#prM0` (mailbox front), `#prIn` / `#prInHead` (incoming arrow), `#prProc` (the process rect), `#prPid` (`#PID<0.118.0>`), `#prLoop` / `#prLoopHead` / `#prLoopLbl` (the loop arrow + label), `#prProp` (the properties line). Readout `#prOut` (`.geo-readout`, `aria-live="polite"`).
- Driver: `pick(k)` reads the `MOVES` table and sets stroke/fill/properties/readout. The properties line `#prProp` strings VERBATIM:
  - `spawn`: `isolated · own heap · scheduled on any core`
  - `message`: `asynchronous · pattern-matched · one mailbox each`
  - `loop`: `tail-recursive · state as an argument`
- Readout `#prOut` strings VERBATIM (HTML inline):
  - `spawn`: "`spawn/1` starts a function as a new process with its own heap and its own crash boundary, and hands back a PID right away. The new actor runs concurrently with the caller."
  - `message`: "Work reaches a process as messages in its `mailbox`. `send` appends a term; `receive` pattern-matches one out at a time, leaving the rest queued."
  - `loop`: "To stay alive and remember, a process `loops`: after handling a message it tail-calls itself with updated state. The state lives in a function that never returns."
- Takeaway (verbatim): "Concurrency, state, and isolation are not three features here — they are one idea. A process runs on its own, remembers by looping, and a crash stays inside its boundary."

### Degrade behaviour
- The hero figure ships a static initial state in the markup (left/right heaps `{count: 7}`, channel `:ping`, both `alive`); no JS needed to read it. The section figure defaults to `spawn` markup (active button), and `pick('spawn')` runs on load. `.reveal` content is visible without JS (`html.js` gates the animation only). Animations honour `prefers-reduced-motion: reduce` (the `.hp-row.hp-new` slide-in and `.arc-flow` are disabled).

### Footer build-stamp decoder
- Stamp id: `TSK0NbQWkalhYG`. Namespace `TSK`; the JS branded-Snowflake decoder (base-62, epoch `1704067200000`) fills `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts`. Markup-printed `#st-ts` timestamp: `2026-05-31 17:18:15 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/elixir/processes.html` — Processes — Elixir documentation — spawn, send, receive.
- `https://en.wikipedia.org/wiki/Actor_model` — Actor model — Wikipedia — the concurrency model.
- `https://erlang.org/download/armstrong_thesis_2003.pdf` — Armstrong, J. (2003). *Making reliable distributed systems in the presence of software errors.* — concurrency-oriented programming: isolation and message passing.

Related in this course:
- `/elixir/language/processes/state` — Holding state in a loop — the recursive receive loop a process keeps state in.
- `/elixir/language/protocols` — F3.06 · Protocols & behaviours — the module contract a process brings to life.
- `/elixir/language/otp` — F3.08 · OTP: GenServer & supervisors — where this pattern becomes a behaviour with supervision.

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/ ` `language` `/ ` `processes` (with `processes` as the current `.rcur` segment; `elixir` and `language` are links).
- crumbs (verbatim): `F3 · The Elixir Language` `/` `F3.07 · processes` (the last is `.here`).
- toc-mini: `#actor` "The actor in three moves"; `#dives` "Three deep dives".
- pager: prev → `/elixir/language/protocols` "F3.06 · protocols"; next → `/elixir/language/processes/spawn` "Start · spawning a process".
- footer columns:
  - Chapters: `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework).
  - The course: `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta:
  - `<title>`: `Processes & the actor model — F3.07 · jonnify`
  - `<meta name="description">`: `A process is the BEAM's isolated unit of concurrency, coordinating only by messages — the actor model built from three primitives: spawn a process, send and receive messages, and loop to hold state.`

## Build instruction

To rebuild this hub, copy the `head…</style>`, the `header`, the `footer`, and the trailing two `<script>` blocks (the branded-Snowflake decoder + the reveal-on-scroll observer) verbatim from a recent BUILT sibling on this chapter accent — the closest model is `/elixir/language/protocols` (`elixir/language/protocols/index.html`), the F3.06 module hub on the same elixir-purple accent and module-hub anatomy. Change only `<title>`/`<meta description>`, the `route-tag`, and the `<main>` body (the hero, the `#actor` figure, the three `#dives` cards, the `.bridge`, the References, the pager). No-invent guards: use only the real Portal surfaces as written (a `Portal.Work.run/1` job, a `Portal.Summary.summarize/1` server, a tally loop) and the real Elixir/BEAM primitives (`spawn/1`, `self/0`, `Process.alive?/1`, `send`, `receive`, the recursive `loop`); the F5 engine is a branded event-sourced store behind ONE `Portal` facade fronting a Phoenix web app — cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of *just*/*simply*/*obviously*.
