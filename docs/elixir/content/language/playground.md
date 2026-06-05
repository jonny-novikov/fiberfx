# F3.09 — The process playground (lab)

- **Route (served):** `/elixir/language/playground`
- **File:** `elixir/language/playground.html`
- **Place in the chapter:** the ninth and final module of F3, a single-page capstone lab in the Concurrency movement (`F3.09`). It composes the parts taught in `F3.07` (processes & the actor model) and `F3.08` (OTP: GenServer & supervisors) into one supervised tree the reader drives end to end; it closes the chapter and hands off to `F4 · Algorithms & Data Structures`.
- **Accent:** elixir (purple); the `<h1>` accent word `playground` is the `<span class="ex">`.
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3 · OTP · capstone lab`

`<h1>`: The process `playground`

Lede (verbatim):

> A live sandbox for everything in this chapter. Send messages into a worker's mailbox and drain them through its receive loop; watch state accumulate; issue a synchronous `call` and read the reply; then crash a worker and watch the supervisor restart it under the strategy you pick. The whole actor model, in one board you drive.

Kicker (verbatim):

> This is a model of the BEAM's behaviour, not a running node, but it follows the same rules: messages queue in a mailbox, a process holds state between them, a crash stays inside one worker, and a supervisor decides who restarts. Each worker carries a branded `PRC` Snowflake PID, minted fresh on every restart.

## Sections

In order: `#lab` ("The playground" — the interactive), `#driving` ("What you are driving"), then a References section.

- **The playground (`#lab`):** the live supervision-tree lab figure.
- **What you are driving (`#driving`):** prose mapping each control to its GenServer mechanic (`send :inc` = a `cast` → `handle_cast`; `send :get` + processing = a `call` → `handle_call`), a static `pre.code` showing a `Portal.Worker` GenServer and a `Supervisor.init(children, strategy: :one_for_one)`, and a `.bridge` from "F3.07 & F3.08 · the parts" to "F3.09 · the whole running system".
- **Running example:** the learning **Portal** — the code block defines `Portal.Worker` (`use GenServer`, `init/1`, `handle_call(:get, …)`, `handle_cast(:inc, …)`) and a supervisor over `children = [Portal.Tally, Portal.Notifier, Portal.Cache]`. The three live worker tiles are Tally (counts `:inc`), Notifier (counts notices), Cache (counts entries).
- **Real Elixir code shown (verbatim, `pre.code`):**
  - `defmodule Portal.Worker do` / `use GenServer` / `def init(n), do: {:ok, n}` / `def handle_call(:get, _from, c), do: {:reply, c, c}` / `def handle_cast(:inc, c), do: {:noreply, c + 1}` / `end`
  - `children = [Portal.Tally, Portal.Notifier, Portal.Cache]` / `Supervisor.init(children, strategy: :one_for_one)`
- **`.take` (verbatim):** "Everything you see follows from three rules: a message waits in the mailbox until the process reads it, the state is whatever the last message left behind, and a crashed worker comes back clean while the strategy decides who comes back with it."
- **`.note` (verbatim):** "This is the final module of **F3 — The Elixir Language**. Next chapter: **F4 — Algorithms & Data Structures**, where recursion meets lists, trees, and big-O on the BEAM."

## The interactives

### Figure — "Live supervision tree · drive it yourself" (`#lab`)
- **Markup:** `<figure class="fig" aria-labelledby="pgTitle">` titled "Live supervision tree · drive it yourself"; an `<svg viewBox="0 0 720 282">` with a `#pgSup` supervisor box, a `#pgStratBadge` strategy badge, and three worker tiles `#pgNode0`/`#pgNode1`/`#pgNode2` (Tally / Notifier / Cache), each carrying `#pgPid{i}` (PID), `#pgSt{i}` (state), `#pgStat{i}` (status), and `#pgRs{i}` (restart count). Below the SVG: a `.pg-controls` block, a `.pg-panels` grid (mailbox + last call reply), and an event-log panel.
- **Control groups:**
  - `.solid-select#pgFocusSel` (Focused worker): three buttons `data-i="0/1/2" data-c="elixir"` — "Tally" (starts `active`), "Notifier", "Cache".
  - `.solid-select#pgStratSel` (Restart strategy): three buttons — `data-s="one_for_one" data-c="elixir"` (":one_for_one", starts `active`), `data-s="one_for_all" data-c="blue"` (":one_for_all"), `data-s="rest_for_one" data-c="gold"` (":rest_for_one").
  - `.pg-actions`: five `.pg-act` buttons — `#pgSendInc` ("send :inc"), `#pgSendGet` ("send :get"), `#pgStep` ("process next"), `#pgRun` ("run all"), `#pgCrash` ("crash worker", `.pg-danger`).
- **Panels (ids + default strings):** `#pgMboxName` ("Tally") · `#pgMbox` ("0") with `#pgMboxChips` showing `(empty)` (the `.pg-chip-empty` default); `#pgReply` (last call reply, default `—`); `#pgLog` (event log, newest first).
- **Pure functions:** `mint(node)` — builds a branded PID from a Snowflake (`ts = Date.now() - EPOCH_MS`, `snow = (ts << 22n) | ((node & 0x3FFn) << 12n) | (SEQ++ & 0xFFFn)`) and returns `'PRC' + b62encode(snow)` (the `PRC` namespace, minted fresh per restart). `render()` repaints every tile (focused tile stroke `#cdb8f0`, status fill gold `#f0cd7f` when "restarted" else sage `#a7c9b1`) and the mailbox/reply/log. `send(msg)` queues a message; `step()` drains one (`:inc` moves state, `:get` sets the reply); `run()` drains the whole mailbox; `crash()` faults the focused worker and applies the chosen strategy. `logEvent(t)` keeps the last 30 events; the log shows the newest 8 (`.pg-new` on the freshest). `WORKERS` dataset: Tally / Notifier / Cache, each `{ state: 0, status: 'alive', restarts: 0, mbox: [], pid: null }`; defaults `focused = 0`, `strategy = 'one_for_one'`, `reply = '—'`.
- **Event-log strings (verbatim samples):** `send <msg> → <name> (queued)`; `<name> handled :inc, state <old> → <new>`; `<name> handled :get, replied <n>`; `<name> mailbox empty — receive waits`; `<name> drained its mailbox, state now <n>`.
- **Degrades:** the SVG tree, the supervisor box, the three worker tiles (with static PID placeholders `PRC—`, state `0`, status `alive`, restart `0`), the strategy badge `:one_for_one`, the controls, and the `(empty)` mailbox / `—` reply defaults are all in static markup; JS animates the board but the structure and the `#driving` code/prose carry the lesson without it. No browser storage; `prefers-reduced-motion` respected globally.

### Footer build-stamp decoder (`#stamp`)
- **Stamp id:** `TSK0NbT03n85vk` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-31 17:52:51 UTC". The `decodeBranded` function (epoch `1704067200000`) decodes it to `ns=TSK · node=0 · seq=0 · 2026-05-31 17:52:51 UTC`, matching `#st-ts`. Toggle on click / Enter / Space. (Distinct from the per-worker `PRC` Snowflake PIDs minted live by `mint(node)`.)

## References (#refs, verbatim)

Intro line: "Primary sources for this lab, and where it connects in the course."

**Sources**
- `https://hexdocs.pm/elixir/processes.html` — Processes — Elixir documentation — the mailbox and message passing.
- `https://hexdocs.pm/elixir/Process.html` — `Process` — Elixir documentation — the process API.

**Related in this course**
- `/elixir/language/processes` — F3.07 · Processes & the actor model
- `/elixir/language/otp` — F3.08 · OTP: GenServer & supervisors

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/language">language</a><span class="rsep">/</span><span class="rcur">playground</span>`.
- **crumbs:** `F3 · The Elixir Language` → `/elixir/language` · sep `/` · here `F3.09 · playground` (no link).
- **toc-mini:** `#lab` ("The playground") · `#driving` ("What you are driving").
- **pager:** prev → `/elixir/language/otp` ("← F3.08 · otp"); next → `/elixir/language` ("Back to F3 · The Elixir Language →").
- **footer (`.foot-nav`, three columns):** Chapters → `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`; The course → `/elixir`, `/elixir/course`, `/elixir/algebra/functions`; brand + foot-logo both → `/elixir`.
- **Page meta:** `<title>` "The process playground — F3.09 · jonnify"; `<meta name="description">` "The F3 capstone lab: a live supervised tree you drive — send messages into a worker's mailbox, drain them through its receive loop to move state, issue a synchronous call, and crash workers to watch the supervisor restart them per strategy. Each worker carries a branded PRC Snowflake PID."

## Build instruction

To rebuild this lab, copy the `<head>`…`</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the elixir (purple) accent — for the standard shell and the `.refs`/`.reveal` References section, `elixir/language/values.html` is the model leaf; this lab additionally carries its own scoped `<style>` block (`.pg-controls`/`.pg-act`/`.pg-panel`/`.pg-chip`/`.pg-log`) and a bespoke board script, which copy verbatim from this page (`elixir/language/playground.html`) since it is the only F3 lab. Change only `<title>`/`<meta>`, the route-tag, and the `<main>` body. Keep the supervision-tree figure, the `mint`/`render`/`send`/`step`/`run`/`crash` engine, and both stamp decoders. Preserve clamp-spacing (`clamp(2.7rem,1.9rem + 4.2vw,5.1rem)`; spaces around `+` are load-bearing). No-invent guards: model only the real OTP behaviours taught in `F3.07`/`F3.08`, and use only the real learning `Portal` surfaces — a branded store, an event-sourced engine behind ONE `Portal` facade, a Phoenix web app — naming no other Portal modules; the worker code (`Portal.Worker`, `Portal.Tally`/`Notifier`/`Cache`) is the lab's own illustrative model, and OTP internals are cited from the companion course rather than re-taught. Voice: no first person, no exclamation marks, no emoji, and none of *just*/*simply*/*obviously*. Model sibling to copy from: `elixir/language/values.html` (shell + References), with the lab board copied from `elixir/language/playground.html`.
