# Codemoji · Telegram bot stack — sources, decision matrix, optimal choice

The Telegram Bot API is at **9.5** (released March 1, 2026), with later-2026 additions including guest mode and opt-in bot-to-bot communication, so "current API support" below means tracking the 9.x line. 
Telegram Bot API 9.5 is fully supported — member tags, date_time entities, and can_manage_tags admin rights, and on May 7, 2026, Telegram… enable[d] native, direct communication between autonomous AI bots… expand[ing] the Telegram Bot API to allow what the company calls "bot-to-bot communication mode."

---

## 1. Sources (numbered · categorized · abstracts)

### 1.1 FP correctness & specification (replacing Meyer/DbC)
1. **Scott Wlaschin — "Railway Oriented Programming"** · https://fsharpforfunandprofit.com/rop/ — The canonical FP error-handling model: chain `Result`-returning steps that short-circuit on failure; maps directly onto Elixir `with` + `{:ok,_}|{:error,_}`.
2. **Scott Wlaschin — "Against Railway-Oriented Programming"** · https://fsharpforfunandprofit.com/posts/against-railway-oriented-programming/ — The author's own caution that `Result` is not a universal hammer; use it for uniform ok/error pipelines, not everywhere.
3. **Alexis King — "Parse, don't validate"** · https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/ — Encode constraints in types and parse untrusted input once at the boundary, preserving the proof downstream; the FP form of a precondition.
4. **Yaron Minsky — "Effective ML" (make illegal states unrepresentable)** · https://vimeo.com/14313378 — Model domains so impossible states can't be constructed; the FP form of an invariant-by-construction.
5. **Gary Bernhardt — "Boundaries" / Functional Core, Imperative Shell** · https://www.destroyallsoftware.com/talks/boundaries — Pure decide/evolve core (many fast tests, no doubles) wrapped by a thin effectful shell; the architecture spine for Codemoji's contexts and the bot adapter.
6. **Castagna, Duboc & Valim — "The Design Principles of the Elixir Type System" (2024)** · https://arxiv.org/pdf/2306.06391 — The set-theoretic type system now shipping incrementally in Elixir; today it infers warnings from patterns/guards, with user signatures a later milestone (status: incomplete).
7. **whatyouhide — StreamData** · https://github.com/whatyouhide/stream_data — Property-based testing for Elixir; state invariants (streak monotonicity, scoring totality) and let generators + shrinking find counterexamples.

### 1.2 Testing developer experience (Elixir)
8. **Mox — "Mocks and explicit contracts" (José Valim)** · https://dashbit.co/blog/mocks-and-explicit-contracts · https://hexdocs.pm/mox/Mox.html — Behaviour-based, `async`-safe mocking defined in `setup_all`; "mock" is a noun, not a verb.
9. **Ecto.Adapters.SQL.Sandbox** · https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html — Concurrent, isolated DB tests via the `start_owner!`/`stop_owner` ownership pattern.
10. **Phoenix.LiveViewTest** · https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html — Drives LiveView interactions (`render_click`, `has_element?`, `render_async`) for the live quiz UI.
11. **PhoenixTest** · https://hexdocs.pm/phoenix_test/PhoenixTest.html — One API spanning static + LiveView pages for thin E2E coverage.

### 1.3 Pragmatic & iterative delivery
12. **Hunt & Thomas — "The Pragmatic Programmer" (20th Anniv.)** · https://pragprog.com/titles/tpp20/ — Tracer bullets / walking skeleton: ship a thin end-to-end slice, then flesh it out.
13. **Eric Ries — "The Lean Startup"** · https://theleanstartup.com/book — MVP + Build-Measure-Learn; ship to learn each iteration.
14. **Kent Beck — "Extreme Programming Explained," 2nd ed.** · ISBN 9780321278654 — "Small Releases" as a primary practice.
15. **Humble & Farley — "Continuous Delivery"** · https://continuousdelivery.com/ — The automated deployment pipeline behind "ship every iteration."
16. **`mix phx.gen.auth`** · https://hexdocs.pm/phoenix/mix_phx_gen_auth.html — Generates an `Accounts` context; Phoenix 1.8 defaults to magic-link/passwordless auth with a per-user `Scope` — the spine for one-click auth.
17. **`mix phx.gen.live`** · https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Live.html — Scaffolds a full vertical slice (context+schema+LiveView+tests) — a tracer bullet in one command.
18. **Tate & DeBenedetto — "Programming Phoenix LiveView"** · https://pragprog.com/titles/liveview/ — The reference for LiveView-first product building.

### 1.4 Stories, specs & agent workflow
19. **Mike Cohn — "User Stories Applied"** · https://www.mountaingoatsoftware.com/books/user-stories-applied — The Connextra story canon used by the spec system.
20. **Bill Wake — INVEST** · https://xp123.com/invest-in-good-stories-and-smart-tasks/ — Independent/Negotiable/Valuable/Estimable/Small/Testable story heuristics.
21. **Cucumber — Gherkin reference** · https://cucumber.io/docs/gherkin/reference/ — Given/When/Then acceptance criteria.
22. **Dan North — "Introducing BDD"** · https://dannorth.net/blog/introducing-bdd/ — Origin of the Given-When-Then template.
23. **Gojko Adzic — "Specification by Example"** · https://gojko.net/books/specification-by-example/ — Living, executable specs.
24. **llms.txt** · https://llmstxt.org/ — Curated, low-noise Markdown map for agents (community convention; adoption uneven).
25. **Anthropic — "Building Effective Agents"** · https://www.anthropic.com/research/building-effective-agents — Workflow vs agent; choose the simplest sufficient design.
26. **Anthropic — "Best practices for Claude Code"** · https://code.claude.com/docs/en/best-practices — Verifiable checks (test/build/lint exit codes) as agent stop-conditions — the proof gates in `f6.N.llms.md`.

### 1.5 Real-time on the BEAM & job queues
27. **Phoenix.PubSub** · https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html — Clustered pub/sub for live quiz/leaderboard fan-out.
28. **Phoenix.Presence** · https://hexdocs.pm/phoenix/Phoenix.Presence.html — CRDT-based presence for live participant counts.
29. **Oban** · https://github.com/oban-bg/oban — Postgres-backed jobs with transactional enqueue, cron, retries — the BEAM-native engine for streak rollovers and scheduled notifications. Oban… peaks at around 17,699 jobs/sec and finishes one million jobs in 57s on a single node.

### 1.6 Node interop
30. **echomq** · — Redis (ValKey) backed Node EchoMQ implementation (delayed/repeatable jobs, rate limiting); the substrate under your EchoMQ and the clean bridge to Node workers.
31. **npm trends — grammy/telegraf/node-telegram-bot-api** · https://npmtrends.com/grammy-vs-node-telegram-bot-api-vs-telegraf — Download/stars trend source used for the ranking below.

### 1.7 Telegram platform & passwordless auth
32. **Telegram Bot API changelog** · https://core.telegram.org/bots/api-changelog — Authoritative version history (currently 9.5 + later 2026 updates).
33. **Telegram — "Log In With Telegram" / Login Widget** · https://core.telegram.org/bots/telegram-login · https://core.telegram.org/widgets/login — One-tap login; **validate server-side** by recomputing the HMAC-SHA256 with the bot token before trusting any field.
34. **Telegram Mini Apps — `initData` validation** · https://docs.telegram-mini-apps.com/platform/init-data — Sort pairs, derive `HMAC(bot_token,"WebAppData")`, verify `hash`; the WebApp one-click-auth path.

### 1.8 Telegram bot libraries (the repos compared)
35. **rockneurotiko/ex_gram (Elixir)** · https://github.com/rockneurotiko/ex_gram — Telegram Bot API low level API and framework… Automatic API Generation — Always up-to-date… Multiple Bots — Run multiple different bots… in a single application; 223 stars, latest release 0.64.0 … Mar 23, 2026.
36. **grammyjs/grammY (TypeScript)** · https://github.com/grammyjs/grammy · https://grammy.dev — grammy 1.42.0 which has 1,264,063 weekly downloads and 3,560 GitHub stars; All grammY packages… run natively on Deno… compiling every codebase to still run on Node.js… especially useful for running bots on Cloudflare Workers.
37. **telegraf/telegraf (TypeScript/JS)** · https://github.com/telegraf/telegraf — ~9.1k stars (telegraf… TypeScript 9,148); maintenance-mode: Telegraf v4 will be supported until February 2025… New API updates will only focus on ensuring compatibility with the latest Telegram Bot API. No new convenience features will be added to Telegraf v4… we plan to release Telegraf v5 (v5 still unshipped; main repo last substantive update ~Jan 2025).
38. **yagop/node-telegram-bot-api (JS)** · https://github.com/yagop/node-telegram-bot-api — node-telegram-bot-api 0.67.0 which has 230,597 weekly downloads and 9,140 GitHub stars; untyped EventEmitter, slower to track new API.
39. **telegex/telegex (Elixir)** · https://github.com/telegex/telegex — Telegram bot framework and API client written in Elixir… an advanced processing model based on "chains"; ~160 stars and last updated Adapt to Bot API 7.11… November 5, 2024 (stale).
40. **gramiojs/gramio (TypeScript)** · https://github.com/gramiojs/gramio · https://gramio.dev — Most API-current Node option and agent-friendly: Bot API 9.5… CLAUDE.md generation in create-gramio.

### 1.9 Gamification (streaks/quiz/notifications)
41. **Duolingo Blog — "Improving the streak"** · https://blog.duolingo.com/improving-the-streak/ — First-party evidence: learners who reach a streak of 7 are 2.4 times more likely to continue using Duolingo the next day than learners without a streak; separating daily-goal and streak mechanics produced a 3.3% increase in Day 14 retention… a 1% increase in our overall daily active learners; and, in just 20 days, a 10.5% increase in the percentage of daily learners on a streak.

---

## 2. Top 5 bot libraries for Codemoji (sorted by stars)

This spans both ecosystems because the decision *is* "Node lib vs Elixir-native." Stars/dates are June 2026.

| # | Library · runtime | Stars | Bot API tracking | Last updated | Multi-bot | License | One-line verdict |
|---|---|---|---|---|---|---|---|
| 1 | **telegraf** · Node (TS/JS) | ~9.1k | latest, **compat-only** | ~Jan 2025 (v4 frozen; v5 unshipped) | per-instance | MIT | Huge ecosystem but **stalled**; risky to start new work on in 2026. |
| 2 | **node-telegram-bot-api** · Node (JS) | ~9.1k | partial/community | slow (0.67.x) | manual | MIT | Easiest to read; **untyped EventEmitter**, lags the API — not for a typed, growing product. |
| 3 | **grammY** · Node/Deno/Bun/Workers (TS) | ~3.5k | **current (9.x)** | active (2026) | yes (runner) | MIT | **Best modern Node choice**: TS-first, plugins (sessions, conversations, menus), runner for concurrency. |
| 4 | **ex_gram** · Elixir/BEAM | 223 | **current (auto-gen)** | **Mar 2026 (0.64)** | **native** | Beer-Ware | **Best in-BEAM choice**: OTP-supervised, calls the `Codemoji` facade in-process. |
| 5 | **telegex** · Elixir/BEAM | ~160 | 7.11 | **Nov 2024 (stale)** | yes | MIT | "Chains" framework, doc-generated API, but not updated since late 2024. |

**Honorable mention — GramIO** (Node/Bun/Deno, TS): smaller community but the **most API-current** (9.5) and uniquely ships **CLAUDE.md generation**, which matters for your agent-driven spec workflow. If you go Node *and* lean hard on coding agents, shortlist grammY **and** GramIO.

**Takeaways:** the two highest-star Node libs are the two you should *not* build new work on (telegraf is frozen; node-telegram-bot-api is untyped and laggy). The live contest is **grammY (Node)** vs **ex_gram (Elixir)** — stars favor grammY, recency/maintenance favor both grammY and ex_gram, and *topology fit* favors ex_gram.

---

## 3. Decision matrix — Fastify (Node) worker vs Elixir-native multi-bot

Both keep the master invariant ("the bot calls only the `Codemoji` facade"); the difference is **whether that facade call is an in-process function or a network/EchoMQ hop**.

| Dimension (weight) | **Fastify worker** (grammY + EchoMQ/BullMQ) | **Elixir-native** (ex_gram in the BEAM) |
|---|---|---|
| Time-to-first-ship (MVP) ★★★ | △ must build the EchoMQ request/reply contract, idempotency, timeouts before story 1 ships | ✓ bot is an adapter over `Codemoji`; first quiz ships same day |
| Topology / ops complexity ★★★ | ✗ +1 runtime, +1 deploy, +Redis on the bot's critical path | ✓ one release, one supervision tree, no extra infra for the bot |
| Latency: bot → domain ★★ | △ network + Redis round-trip per enroll/answer/streak | ✓ direct function call (µs) |
| Failure modes / consistency ★★ | ✗ queue + two runtimes ⇒ retries, partial failures, eventual consistency to design | ✓ in-process; OTP supervision; `Ecto.Multi` for atomic answer→streak→notify |
| Correctness boundary ★★★ | △ master invariant now spans a network seam you must spec | ✓ invariant is a pure in-VM call |
| Real-time (LiveView/PubSub/Presence) ★★ | ✗ cross-runtime bridge needed to share live quiz state | ✓ bot publishes/subscribes the same PubSub topics as LiveView |
| Scheduled notifications ★★ | △ BullMQ in Node (separate from BEAM jobs) | ✓ Oban cron (already BEAM-native) |
| One-click auth (initData/Login HMAC) ★★ | ✓ trivial in TS | ✓ trivial pure function in Elixir |
| Code/type sharing with domain ★ | ✗ models + validation duplicated across runtimes | ✓ shares the Codemoji domain and tests |
| Library / plugin ecosystem ★★ | ✓ grammY plugins (sessions, conversations, menus, i18n) | △ smaller; build menus/sessions yourself or with light helpers |
| Multi-bot ★ | ✓ grammY runner | ✓ native in ex_gram |
| Independent horizontal scale ★ | ✓ scale the bot tier separately via Node cluster | △ scales with the BEAM (usually plenty for a bot) |
| Team-skills fit ★★ | ✓ your stated Fastify/Node/EchoMQ expertise | △ Elixir, but you already run the BEAM for Codemoji |
| Testing DX ★★ | △ contract tests across the queue; two test stacks | ✓ ExUnit + Mox + LiveViewTest in one stack |
| **Net for an MVP that ships every iteration** | Stronger **later**, at scale or for Node-only needs | **Stronger now**: fewer moving parts, correct by construction, fastest to a demo |

---

## 4. The optimal choice of Elixir-native Telegram bot

**Ship the Telegram bot Elixir-native with `ex_gram`, in the BEAM — and keep grammY + Fastify + EchoMQ as a documented, pre-designed scale-out seam.**

Why this is optimal for *your* stated goal (ship a product every iteration; first users are on Telegram; features = one-click auth, quiz, streaks, notifications):

- **It collapses the topology.** The bot becomes "just another caller of `Codemoji`," exactly like a controller or LiveView. No second runtime, no Redis hop on the critical path, no cross-runtime consistency problem to solve before your first quiz ships. That is the shortest tracer bullet to a live feature [12, 17].
- **It's correct by construction.** The master invariant stays a pure in-VM call; `Ecto.Multi` makes "record answer → bump streak → enqueue notification" atomic [29]; PubSub/Presence already carry live quiz state to both LiveView and the bot [27, 28]. Validation of Telegram `initData`/Login is a pure HMAC function regardless of runtime [33, 34].
- **`ex_gram` is genuinely ready.** Current auto-generated API, native multi-bot, OTP-supervised, released March 2026 [35] — the maintenance/recency risk that sinks telegraf [37] and telegex [39] doesn't apply.

**The seam that protects your Node/EchoMQ vision.** Because the bot only ever calls `Codemoji`, moving it to a Fastify/grammY worker later is a **boundary swap, not a rewrite**: the Node bot becomes a *remote* adapter that reaches `Codemoji` over EchoMQ instead of in-process. 
Adopt that exactly when a real trigger appears — a grammY-only plugin you need, a Telegram **Mini App** (TS) backend that grows large enough to own the bot, or a need to scale the bot tier independently of the BEAM. 
If/when you do, use **grammY** (current, TS-first, plugins, runner) [36] — and consider **GramIO** for its CLAUDE.md generation [40] — never telegraf or node-telegram-bot-api for new work.

**One-line rule:** *the `Codemoji` facade is the contract; where the bot process runs is an implementation detail you can change later for free.*

---

## 5. The choice in 5W

- **Why** — The goal is to ship value every iteration to users who are already on Telegram. The Elixir-native bot removes the EchoMQ/Redis hop, the second runtime, and the cross-runtime consistency work from the path of the *first* feature, so iteration 1 (one-click auth + a quiz) ships fastest and stays correct by construction.
- **What** — A `Codemoji.Telegram` bot built with `ex_gram` as a supervised adapter that calls **only** the `Codemoji` facade; streaks/quiz state flow through the existing domain + PubSub; notifications run on Oban; Telegram Login/`initData` is HMAC-validated server-side into a Codemoji session. grammY + Fastify + EchoMQ is documented as the scale-out replacement behind the same facade.
- **Who** — Telegram learners (the first user segment) get one-click auth, quizzes, streaks, and notifications; you (the BEAM/Node architect) keep one deploy and one test stack now, with a clean path to a Node bot tier later; coding agents get a single in-VM contract to implement against (fewer ways to misread the spec).
- **When** — Now, for the MVP and early iterations. Flip to the Fastify/grammY worker over EchoMQ only on a real trigger: a Node-only library need, a substantial Telegram Mini App backend, or independent bot-tier scaling.
- **Where** — Inside the Codemoji release's OTP supervision tree as a bot adapter directly above the `Codemoji` facade (no network boundary); EchoMQ/BullMQ and Fastify workers stay reserved for genuinely Node-side workloads until that trigger fires, at which point the bot moves out behind the same facade contract.

A caveat to keep visible: the **BullMQ-vs-Oban throughput claims are vendor-published and configuration-dependent**, and Elixir's **set-theoretic types are still warning-only** [6] — so lean on property tests [7] and `Ecto.Multi` for the gamification invariants rather than assuming compile-time enforcement. If you'd like, I can fold this recommendation into the F6 spec set as `specs/telegram/` (an F-series spec + `.stories.md` + `.llms.md`) with the facade-seam invariant written as a checkable gate.