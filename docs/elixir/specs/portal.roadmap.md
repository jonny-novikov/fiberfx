# Portal · program roadmap

> The whole-Portal delivery plan — the roadmap of roadmaps. The Portal is one domain core surfaced through several
> adapters; this file sequences the chapters that build it (the engine, the web, the bot, and the reserved
> multi-runtime layers) into program milestones, shows how they stack over one facade and one master invariant, and
> hands off to each chapter's own roadmap for rung-level detail.

This is the program view above the per-chapter roadmaps ([`pragmatic/pragmatic.roadmap.md`](pragmatic/pragmatic.roadmap.md),
[`phoenix/phoenix.roadmap.md`](phoenix/phoenix.roadmap.md), [`bot/f10.roadmap.md`](bot/f10.roadmap.md)). The contract
for *how* any chapter is specced and proven is [`specs.approach.md`](specs.approach.md); this file is *what ships, in
what order, and why.*

## What the Portal is

The Portal is a learning platform: a supervised, event-sourced engine that holds courses, enrollments, and progress,
reachable by people on the web and from Telegram. There is one domain core, framework-free, behind a single facade
(`Portal`); every surface — a LiveView, a bot handler, a future worker — calls only that facade and renders only the
closed `%Portal.Error{}` set. The program grows by adding surfaces and capabilities over the unchanged core, never by
reaching into it.

## The program at a glance

| Chapter | Theme | Surface | Delivers | Status | Detail |
| --- | --- | --- | --- | --- | --- |
| F0 | Design system | — (rendering foundation) | the dark-editorial token system + the envelope/anatomy the web renders; static `/elixir` + the `jonnify-cms` content store, byte-parity proven | **shipped (static)** — static parity + the Portal static-parity pages (`/`, `/elixir`, `/course/agile-agent-workflow`) landed at F6.5.5; the dynamic-UI styling pass re-defers | [index](design/f0.md) · [roadmap](design/f0.roadmap.md) |
| F4 | Branded store | — (foundation) | the branded CHAMP store behind the facade's reads and writes (`get/2`, `all/2`, `put/1`) | given (in-memory stand-in ✓; branded CHAMP deferred) | — |
| F5 | The engine (`pragmatic/`) | headless core | a supervised, event-sourced learning engine behind one facade | **complete** — F5.1–F5.9 shipped, the ladder is closed (M1) | [index](pragmatic/pragmatic.md) · [roadmap](pragmatic/pragmatic.roadmap.md) |
| F6 | The web (`phoenix/`) | web | browse, enroll, and learn — server-rendered, live, authed, deployed | **shipping** — F6.1–F6.7 + F6.5.5 shipped; **F6.8.1 (auth) shipped** (`87ec6eb`); F6.8.2 (deploy) reconciled + config-pinned, next; F6.9 (dashboard) specced | [index](phoenix/phoenix.md) · [roadmap](phoenix/phoenix.roadmap.md) |
| F7–F9 | Multi-runtime | messaging & workers | candidate: an EchoMQ bus, a Fastify worker cluster, Go/Echo services | open (reserved) | — |
| F10 | The Telegram bot (`bot/`) | chat | the learner loop from Telegram (a vendored-fork multibot engine, in-BEAM) | **building** — F10.1 shipped (`2379a74`, `apps/echo_bot`); F10.2/F10.3 graduated to triads | [roadmap](bot/f10.roadmap.md) |

F7–F9 are reserved, not designed. The candidate themes are drawn from the program's stated architecture — EchoMQ (on
BullMQ) as the message bus between BEAM, Node, and Go runtimes, with Fastify worker clusters and Go services on the
Echo platform — but they are defined only when a real need (scale-out or a polyglot service) arrives. The bot's
scale-out seam (F10.9) is the first trigger for them.

## How the chapters compose

Each chapter is a value ladder whose rungs depend only downward (see [`specs.approach.md`](specs.approach.md)). The
chapters themselves stack the same way: the store grounds the engine, the engine exposes the facade, and every surface
sits on the facade.

```text
F4  Branded store (given)
     │  Portal.Store: get/2 · all/2 · put/1
     ▼
F5  The engine ───────────────▶  Portal facade  +  closed %Portal.Error{}
     │  decide/evolve · EventStore port · supervised by OTP
     │  (the one public surface — the boundary the master invariant protects)
     ├──────────────────┬──────────────────────────────┐
     ▼                  ▼                              ▼
F6  The web         F10 The bot                  F7–F9  Multi-runtime (open)
 (LiveView/HEEx)     (ex_gram, in-BEAM)            EchoMQ bus · Fastify/Go workers
     │                  │  F10.8 webhook leans on F6.1's endpoint
     └── both call only the facade ──┘  F10.9 scale-out seam ─▶ EchoMQ (F7–F9)
```

Two consequences shape the order. First, **F6 (web) and F10 (bot) are parallel surfaces over the same F5 facade** —
neither depends on the other for its core loop, so they are sequenced by product priority, not by a hard dependency
(the one soft link is F10.8's webhook delivery, which is fronted by F6.1's endpoint). Second, **the master invariant
threads through every chapter**: the web, the bot, and any future worker call only `Portal` and render only the closed
error set, so adding a chapter adds a surface and never changes the core. That single rule is what lets the program
grow cheaply.

## Program milestones

| Milestone | Chapters | What you can do at the end | Status |
| --- | --- | --- | --- |
| M1 · The engine | F5 | a correct, recoverable, testable learning engine answers commands and queries behind the facade | **complete** — F5.1–F5.9 shipped, the ladder is closed |
| M2 · The web platform | F6 | browse and enroll on a live, multi-client, authenticated, deployed web app | **shipping** — catalog ✓, live ✓, users ✓ (F6.8.1 auth); deploy (F6.8.2) reconciled + config-pinned, next; the dashboard (F6.9) is the capstone |
| M3 · The bot | F10 | run the learner loop (browse, enroll, learn, progress) from Telegram | **building** — F10.1 shipped; F10.2/F10.3 triaged; near-term to F10.5 |
| M4 · The multi-runtime platform | F7–F9 | scale surfaces out and add polyglot services over an EchoMQ bus | open (defined when needed) |

M2 and M3 are both surfaces over M1's facade; either can lead, and they can advance in parallel once the engine's
near-term slice is shipping. M4 is the program's reversible escape hatch — the in-BEAM-first choices in F6 and F10
keep their off-BEAM seams documented so moving a surface onto a worker is a planned migration, not a rewrite.

## How the program runs

The program runs the same Author/Operator loop the chapters use, one altitude up:

- **Operator (the human)** chooses the next chapter and rung to sharpen — by dependency (only downward) and by product
  priority — and reviews each shipped increment.
- **Author (Claude)** produces the chapter roadmap and the rung triads, built thin but robust, and self-checked against
  the quality gates.

The loop is **sharpen → build → ship → demo → review → feedback → adapt**, and feedback edits the specs, which are the
single source of truth. At program scale the planning unit is the chapter and its milestones; within a chapter it is
the rung, governed by that chapter's roadmap. One chapter's near-term rungs are usually in flight at a time, while
specced abstracts (the later rungs, the bot's ladder) can be sharpened ahead of their build.

## The near-term path

The engine and the web's first milestones have shipped — F5 is complete, F6 is live through F6.8.1 (auth), and F10.1
(the bot skeleton) has shipped. What remains:

1. **Ship the engine's slice.** ✅ **Done** — F5.1–F5.9 shipped (the whole ladder, not just the near-term slice): the
   supervised, canonical-Decider engine answers behind the facade, fully harnessed.
2. **Ship the web's first milestones.** ✅ **Done** — F6.1–F6.7 + F6.5.5 shipped: a persistent, server-rendered,
   **live** multi-client catalog (F6.6/F6.7) in the F0 design system (F6.5.5), with **auth** over the facade (F6.8.1 —
   the honest door).
3. **Deploy the web — the current frontier.** Build **F6.8.2** (deploy): the scoped umbrella release, the
   runtime/config split, `Portal.Release.migrate/0`, libcluster, and the distilled `fly.toml` (app `echo-portal`,
   1024 MB, region `fra`); the spec is reconciled + config-pinned, gate BUILD-LOCAL (the live `fly deploy` is the
   Operator's). Then **F6.9** — the read-only real-time dashboard, the capstone composing everything below.
4. **Advance the bot in parallel.** Continue **F10.2** (multi-bot) and **F10.3** (the games slice) per
   [`bot/f10.roadmap.md`](bot/f10.roadmap.md), over the same facade — F10.1 (a supervised bot that answers, from a
   vendored-fork wrap) has shipped and F10.2/F10.3 are triaged.
5. **Define F7–F9 when the need is real.** When the bot's traffic or a polyglot service warrants it, sharpen the
   multi-runtime chapters (the EchoMQ bus first), using F10.9 as the entry seam.

The earlier housekeeping is discharged: F6.2/F6.3 are in the triad format (the F6 chapter is uniform), and the bot
chapter now carries its own roadmap + graduated F10.1–F10.3 triads.

## Seams & open decisions

- **F7–F9 are undefined.** Candidate themes — an EchoMQ messaging chapter, a Fastify worker-cluster chapter, a Go/Echo
  services chapter — follow from the stated architecture but are decided when a concrete need appears, not before.
- **The multi-runtime story.** EchoMQ (on BullMQ) is the bus between the BEAM, Node, and Go runtimes. The program is
  in-BEAM-first (the web and the bot run in the engine's VM) with documented off-BEAM seams, so polyglot scale-out is
  reversible rather than assumed.
- **Deployment is shared.** F6.8 — split into **F6.8.1 (auth, shipped)** + **F6.8.2 (deploy, reconciled + config-pinned:
  app `echo-portal`, 1024 MB, region `fra`)** — establishes the release, runtime-config, and clustering substrate; later
  surfaces and workers deploy on the same foundation, and libcluster keeps PubSub and Presence correct across nodes.
- **The store is the floor.** F4's branded CHAMP store is the given foundation under F5; if it needs its own chapter
  later, it slots below the engine without disturbing the facade.

## Conventions

- **The master invariant** holds across the whole program: every surface calls only the `Portal` facade and renders
  only the closed `%Portal.Error{}` set; the domain core is framework-free and depends on nothing above it.
- **Branded Snowflake ids** for every identifier (integer column; branded transport form with a namespace prefix and
  base62 encoding, e.g. `TSK0KHTOWnGLuC`).
- **The spec system** is the contract: each chapter and rung conforms to [`specs.approach.md`](specs.approach.md), and
  every artifact passes the quality gates (voice, structure, traceability, fences, links) before it is presented.
- **A+ quality, Writerside-friendly markdown** throughout — prose over heavy formatting, clean voice, resolving links.

## Map

- Contract for the spec system: [`specs.approach.md`](specs.approach.md).
- F5 · the engine: index [`pragmatic/pragmatic.md`](pragmatic/pragmatic.md), roadmap
  [`pragmatic/pragmatic.roadmap.md`](pragmatic/pragmatic.roadmap.md), and the engine's core pattern
  [`pragmatic/decider-pattern.md`](pragmatic/decider-pattern.md).
- F6 · the web: index [`phoenix/phoenix.md`](phoenix/phoenix.md), roadmap [`phoenix/phoenix.roadmap.md`](phoenix/phoenix.roadmap.md).
- F10 · the bot: roadmap [`bot/f10.roadmap.md`](bot/f10.roadmap.md).

---

> Part of the jonnify toolkit. One core, many surfaces, one facade. The roadmaps plan; the specs define and prove;
> both are reviewed here before any implementation runs.
