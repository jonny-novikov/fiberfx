# F3.08 — OTP: GenServer & supervisors (module hub)

- Route (served): `/elixir/language/otp`
- File: `elixir/language/otp/index.html`
- Place in the chapter: the eighth module of F3 · The Elixir Language and the chapter's OTP capstone. It follows F3.07 (`/elixir/language/processes`, the hand-written `receive` loop) and frames three dives that turn isolated processes into a self-recovering system; the next module is F3.09, the playground lab (`/elixir/language/playground`).
- Accent: elixir (purple) — `--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F3 · OTP · module 8`

H1 (verbatim): `OTP: GenServer & supervisors`

Hero lede (verbatim):

> OTP is the framework the BEAM grew up on — tested patterns for the actor model. A **GenServer** wraps the spawn, receive, and loop you wrote by hand into a behaviour with callbacks. A **Supervisor** watches a set of processes and restarts them when they crash. Together they turn isolated processes into a system that recovers on its own.

Kicker (verbatim):

> The portal's hand-written tally becomes a GenServer; talking to it splits into synchronous `call` and asynchronous `cast`; and a supervisor keeps it and its siblings alive. This module builds OTP from three pieces — the server, the client API, and the supervision tree.

## What the page frames

The hub is not a `.mods` grid; it frames three dives as full-width cards under "Three deep dives", in pedagogical order. Each card carries a number, title, one-line summary, route, and accent-coloured left border.

- F3.08.1 — The GenServer behaviour — `use GenServer` hides the loop; you fill in `init/1`, `handle_call/3`, and `handle_cast/2`, and the state threads between them. Route: `/elixir/language/otp/genserver`. Built (accent left-border: `--elixir`).
- F3.08.2 — Synchronous call, asynchronous cast — `call` blocks until the server replies; `cast` returns `:ok` at once. One routes to `handle_call`, the other to `handle_cast`. Route: `/elixir/language/otp/call-cast`. Built (accent left-border: `--blue`).
- F3.08.3 — Supervisors & restart strategies — A supervisor restarts crashed children by strategy — `:one_for_one`, `:one_for_all`, `:rest_for_one`. This is "let it crash". Route: `/elixir/language/otp/supervisors`. Built (accent left-border: `--gold`).

A `bridge` block frames the F3.07 → F3.08 transition: left cell `F3.07 · a hand-written loop` ("A process held state by tail-calling a `receive` loop, alone and unsupervised."), right cell `F3.08 · GenServer & a supervisor` ("The loop becomes callbacks, the messages become call and cast, and a supervisor restarts the server when it dies."). A closing `.note` directs the reader through the three dives in order and names the next module, F3.09.

## The interactives

Two interactive figures.

1. Hero figure — `figure.hero-fig`, labelled by `#lcTitle` "Let it crash · the restart loop". A supervisor (`:one_for_one`) watches one GenServer child. Controls (no control-group select; two direct buttons):
   - `#lcBtn` — label `▸ step the lifecycle` (the play glyph is `&#9656;`).
   - `#lcReset` — label `reset`.
   - SVG element ids: `#lcChild` (the redrawn child group), `#lcStage1`, `#lcStage2`, `#lcStage3` (the three lifecycle lines), and the readout `#lcCap`.
   - Pure functions (inline IIFE): `el`/`label`/`box` build the SVG child group; `render(isNew)` redraws the child and the caption for the current `stage` (0 running · 1 crashed · 2 restarted), cycling `stage = (stage + 1) % 3`.
   - Readout strings VERBATIM (the three `#lcCap` states):
     - stage 0: `[ running · state = 7 ]` / `The child holds its own state and answers messages.` (button text `▸ step the lifecycle`)
     - stage 1: `[ crashed · state lost ]` / `An unhandled error stops the process; its state is gone.` (button text `▸ supervisor restarts it`)
     - stage 2: `[ restarted · state = 0 ]` / `The supervisor starts a fresh process; init/1 sets the state anew.` (button text `▸ run it again`)
   - Static lifecycle lines in markup: `1 · running`, `2 · crash`, `3 · restart → state = 0`.
   - Degrade behaviour: the static initial state (`running` / `state = 7`) is in the markup and visible without JS. The `.hp-row.hp-new` entrance animation `hpIn` runs only `@media (prefers-reduced-motion: no-preference)` and is disabled under `reduce`.

2. "An OTP system in three pieces" figure — `figure.fig`, labelled by `#opTitle` "The piece · select one". Control group `#opSel` (role `group`, aria-label "The piece"), three buttons:
   - `data-k="genserver"` `data-c="elixir"` (active by default) — label `GenServer`
   - `data-k="callcast"` `data-c="blue"` — label `call & cast`
   - `data-k="supervisor"` `data-c="gold"` — label `Supervisor`
   - SVG element ids recoloured/relabelled on pick: `#opSup`, `#opSupLink`, `#opSupHead`, `#opSupLbl`, `#opGen`, `#opMsg`, `#opMsgHead`, `#opMsgLbl`, `#opClient`, `#opRole`; the readout is `#opOut`.
   - Pure function: `pick(k)` looks up `PIECES[k]` and rewrites the stroke/fill of each SVG part, the `#opRole` text, and the `#opOut` HTML.
   - Role + readout strings VERBATIM:
     - `genserver` — role `use GenServer · init/1 · handle_call/3 · handle_cast/2`; out: "A **GenServer** is a process running the GenServer behaviour. It holds state and answers messages through callbacks — `init/1`, `handle_call/3`, `handle_cast/2` — while the framework runs the loop and the mailbox."
     - `callcast` — role `GenServer.call → a reply · GenServer.cast → :ok`; out: "A **client** reaches the server two ways: `GenServer.call` sends a request and waits for a reply; `GenServer.cast` sends one and returns at once. The client only needs the server PID."
     - `supervisor` — role `Supervisor.start_link · child specs · :one_for_one`; out: "A **supervisor** starts its children and watches them. When a child crashes, the supervisor restarts it according to a strategy — the recovery that the actor model is built to allow."
   - Takeaway (`.take`, verbatim): "The three pieces are layered, not separate: a GenServer is a process with a behaviour, a supervisor is a process that starts and watches others, and the client is any process holding a PID."

Footer build-stamp decoder: `#stamp` holds id `TSK0NbRgF8nLIu`; the inline `decodeBranded` splits namespace `TSK` from the base-62 Snowflake, with `EPOCH_MS = 1704067200000`. The static fallback timestamp in markup is `2026-05-31 17:34:23 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `GenServer` — Elixir documentation — `https://hexdocs.pm/elixir/GenServer.html` — the stateful server behaviour.
- Mix & OTP: GenServer — Elixir guide — `https://hexdocs.pm/elixir/genservers.html` — building one step by step.
- `Supervisor` — Elixir documentation — `https://hexdocs.pm/elixir/Supervisor.html` — fault tolerance and restarts.

Related in this course:
- `/elixir/language/processes` — F3.07 · Processes & the actor model
- `/elixir/language/otp/supervisors` — Supervisors & restart strategies
- `/elixir/language/playground` — F3.09 · The process playground

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `language` `/` `otp` — `elixir` links `/elixir`, `language` links `/elixir/language`, `otp` is the current segment (`.rcur`).
- crumbs (verbatim): `F3 · The Elixir Language` (→ `/elixir/language`) `/` `F3.08 · otp` (here).
- toc-mini: `#system` "An OTP system in three pieces"; `#dives` "Three deep dives".
- pager: prev → `/elixir/language/processes` label `← F3.07 · processes`; next → `/elixir/language/otp/genserver` label `Start · the GenServer behaviour →`.
- footer columns: Chapters — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). The course — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta: `<title>` = `OTP: GenServer &amp; supervisors — F3.08 · jonnify`; `<meta name="description">` = "OTP wraps the actor model in tested patterns: a GenServer holds state behind callbacks, a Supervisor restarts crashed children — an OTP system as a small tree of server, client, and supervisor."

## Build instruction

To rebuild this hub, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the trailing two `<script>` blocks (the Branded-Snowflake decoder plus the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling on this chapter accent — the closest model is the F3.07 processes hub at `elixir/language/processes/index.html` (a same-shape F3 hub with a hero concept figure plus a `solid-select` piece-picker figure); change only `<title>` / `<meta description>`, the `route-tag` (set the current segment to `otp`), and the `<main>` body. No-invent guards: use only the real Elixir/OTP surfaces as written — `GenServer` (`init/1`, `handle_call/3`, `handle_cast/2`), `GenServer.call`/`GenServer.cast`, `Supervisor` and the three strategy atoms `:one_for_one`/`:one_for_all`/`:rest_for_one`, and the running example `Portal.Tally` — and cite the linked HexDocs pages for OTP internals rather than re-teaching them; do not invent a route, id, readout string, or reference URL. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
