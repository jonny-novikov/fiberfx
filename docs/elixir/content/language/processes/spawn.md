# F3.07.1 — Spawning a process (dive)

- Route (served): `/elixir/language/processes/spawn`
- File: `elixir/language/processes/spawn.html`
- Place in the chapter: the first of three dives under the F3.07 processes hub. It starts the actor arc — what a spawn buys you over a plain call (concurrency, an own heap, a crash boundary) — and hands off to F3.07.2 (messages). Teaching arc: spawn → messages → state.
- Accent: elixir (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F3.07 · part 1 of 3`

Hero h1 (verbatim): Spawning a process

Lede (verbatim):

> `spawn/1` takes a function, starts it as a new process on the BEAM, and returns a PID at once. The caller does not wait. The child runs concurrently, on its own heap, inside its own crash boundary — the three things that make a process more than a function call.

Kicker (verbatim):

> The portal hands slow work to spawned processes so a request never blocks on it. Compare a plain call with a spawn, and see what happens to the caller when the new process crashes.

## Sections

In order:
1. `#run` "Call, spawn, or crash" — the teaching section. A direct call runs inside the caller and blocks; `spawn` returns a PID and leaves the caller free; an isolated crash does not reach the caller. Carries the interactive figure.
2. `#prims` "The spawn primitives" — `self/0` for a process's own PID, `Process.alive?/1` to check any PID; a spawned process ends when its function returns or raises, without disturbing anyone else. Carries the static code block + the `.bridge`.

Running example: the learning Portal hands slow work to spawned processes (`Portal.Work.run/1`).

Real Elixir code shown (the `#prims` static `pre.code`, verbatim):

```
parent = self()                       # this process's own PID

pid = spawn(fn ->
  Portal.Work.run(job)         # runs in the new process
end)

Process.alive?(pid)   # => true, until run/1 returns
pid                          # => #PID<0.118.0>
```

## The interactives

### Figure — "How the work runs · select one" (`#spTitle`)
- `<figure class="fig">` with control group `#spSel` (`role="group"`, label `How the work runs`). Buttons by `data-k`/`data-c`/label:
  - `data-k="call"` `data-c="elixir"` (active) — `direct call`
  - `data-k="spawn"` `data-c="blue"` — `spawn`
  - `data-k="crash"` `data-c="sage"` — `spawn that crashes`
- SVG element ids: `#spCaller` / `#spCallerT` (caller lane), `#spArr` / `#spArrHead` / `#spArrLbl` (the spawn arrow), `#spChild` / `#spChildT` (spawned-process lane), `#spRet` / `#spRetT` (what the caller receives). A live code block `#spCode` (`pre.code`, `aria-live="polite"`) and readout `#spOut` (`.geo-readout`, `aria-live="polite"`).
- Driver: `pick(k)` reads the `CASES` table and sets each lane's text/stroke, the returned-value text, the code, and the readout.
- Caller-lane text `#spCallerT` strings VERBATIM: `call` → `runs run/1 inline, blocks until it returns`; `spawn` → `continues at once, does not wait`; `crash` → `unaffected, keeps running`.
- Child-lane text `#spChildT` strings VERBATIM: `call` → `(no separate process)`; `spawn` → `runs run/1 concurrently`; `crash` → `raises, then dies`.
- Returned-value `#spRetT` VERBATIM: `call` → `42`; `spawn` → `#PID<0.118.0>`; `crash` → `#PID<0.119.0>`.
- Readout `#spOut` strings VERBATIM:
  - `call`: "A direct call runs inside the caller and blocks until it returns. There is no new process and no isolation — a crash here would take the caller down with it."
  - `spawn`: "`spawn/1` starts the function in a new process and returns its PID at once. The caller keeps going; the child runs on its own heap, scheduled independently."
  - `crash`: "The spawned process raises and dies, but the crash stays inside its boundary — the caller is untouched. This isolation is what later lets a supervisor restart only the failed process."
- The live code block `#spCode` per case (decoded from the `CASES.code` strings) VERBATIM:
  - `call`: `result = Portal.Work.run(job)` / `# blocks until run/1 returns a value` / `# => 42`
  - `spawn`: `pid = spawn(fn -> Portal.Work.run(job) end)` / `# returns immediately; work runs elsewhere` / `# => #PID<0.118.0>`
  - `crash`: `pid = spawn(fn -> raise "boom" end)` / `# the child crashes in isolation` / `# [error] Process #PID<0.119.0> raised an exception` / `# the caller is untouched`
- Takeaway (verbatim): "The PID is the whole handle to a process. A spawn returns one even when the work later fails, and that returned address is how another process will send to it, link to it, or restart it."

### Degrade behaviour
- The figure ships static `call`-case markup (caller "runs run/1 inline, blocks until it returns", return `42`); `pick('call')` runs on load. `#prims` shows a full static code block that needs no JS. `.reveal` content (the References section) is visible without JS; `prefers-reduced-motion: reduce` disables the `.arc-flow` and reveal transitions.

### Footer build-stamp decoder
- Stamp id: `TSK0NbQWl0JbG4`. Namespace `TSK`; the branded-Snowflake decoder (base-62, epoch `1704067200000`) fills the panel. Markup-printed `#st-ts` timestamp: `2026-05-31 17:18:15 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/elixir/processes.html` — Processes — Elixir documentation — spawn, send, and receive.
- `https://en.wikipedia.org/wiki/Actor_model` — Actor model — Wikipedia — the concurrency model behind isolated processes.
- Armstrong, J. (2003). *Making reliable distributed systems in the presence of software errors* — concurrency-oriented programming: isolation and message passing. (no link on this page)

Related in this course:
- `/elixir/language/processes` — F3.07 · Processes & the actor model
- `/elixir/language/processes/messages` — Sending & receiving messages
- `/elixir/language/otp` — F3.08 · OTP: GenServer & supervisors

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/ ` `language` `/ ` `processes` `/ ` `spawn` (with `spawn` as the current `.rcur` segment; `elixir`, `language`, `processes` are links).
- crumbs (verbatim): `F3` `/` `F3.07` `/` `spawn` (the last is `.here`).
- toc-mini: `#run` "Call, spawn, or crash"; `#prims` "The spawn primitives".
- pager: prev → `/elixir/language/processes` "F3.07 · processes"; next → `/elixir/language/processes/messages` "Next · messages".
- footer columns:
  - Chapters: `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework).
  - The course: `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta:
  - `<title>`: `Spawning a process — F3.07.1 · jonnify`
  - `<meta name="description">`: `spawn/1 starts a function as a new process and returns a PID at once; the child runs concurrently on its own heap, and a crash stays inside its boundary — the isolation a supervisor later builds on.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, the `header`, the `footer`, and the trailing two `<script>` blocks (branded-Snowflake decoder + reveal observer) verbatim from a recent BUILT sibling on this chapter accent — the closest model is its own sibling `/elixir/language/processes/messages` (`elixir/language/processes/messages.html`), the F3.07.2 dive with the identical dive anatomy (eyebrow `part N of 3`, two teaching sections, a `select-one` figure with `#…Sel`/`CASES`/live `pre.code`+`.geo-readout`, a `.bridge`, References, pager). Change only `<title>`/`<meta description>`, the `route-tag`, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written (`Portal.Work.run/1`) and the real BEAM primitives (`spawn/1`, `self/0`, `Process.alive?/1`, `#PID<…>`); the platform is a branded event-sourced store behind ONE `Portal` facade fronting a Phoenix web app — cite the companion course for OTP/supervisor internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of *just*/*simply*/*obviously*.
