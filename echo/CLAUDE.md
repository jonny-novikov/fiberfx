# CLAUDE.md — the Echo / Portal umbrella

This file guides a fresh session working in `/Users/jonny/dev/jonnify/echo`. It documents the **Portal engine umbrella** — its layout, the one invariant that must not break, the build/test gotchas, the real API surface, and the F5→F6 arc — so the conventions and footguns are learnable without re-deriving them from the code.

## Scope of this file

This is **not** the repo-root `CLAUDE.md`. That file documents the Go `jonnify` web server and explicitly declares other modules out of scope; this umbrella is one of them, so its conventions live here. The two trees overlap on disk only — `echo/` is an Elixir Mix umbrella that happens to sit under the `jonnify` git repository (`git rev-parse --show-toplevel` reports `/Users/jonny/dev/jonnify`); it is **not** a Go module and is **not** listed in the repo's `go.work` `use` block.

The **specs** are the source of truth, not this file. They live in `docs/elixir/specs/pragmatic/` (`f5.N.{md,stories.md,llms.md}` triads + the append-only `f5.progress.md` retrospective + `decider-pattern.md`). This file records *how to build* against those specs; the specs record *what* to build. When the two disagree, the specs win.

## 1. What this is

A Mix umbrella (`Echo.MixProject`, `apps_path: "apps"`, no umbrella-level deps) holding two apps, built rung by rung along the F5 *"Pragmatic Programming"* value ladder. It is the **live target of the `/elixir` course migration** — the static-HTML course documented in the repo-root `CLAUDE.md` is being reframed onto this Phoenix/Portal engine.

| App | Module root | What it is | Deps |
|---|---|---|---|
| `apps/echo_data` | `EchoData` | A **pure library app** — the id primitives `EchoData.Snowflake` (time-ordered 64-bit ints, custom epoch `2024-01-01`) and `EchoData.Base62` (the `0-9A-Za-z`, width-11 transport encoding). No processes, no siblings. | none |
| `apps/portal` | `Portal` | The **framework-free engine**: branded ids, the `Portal.Engine` boundary, the Accounts/Catalog/Learning domain over `Portal.Store`, and a thin **Bandit + Plug** web layer. | `echo_data` (in-umbrella), `bandit ~> 1.5`, `plug ~> 1.16`, `jason ~> 1.4`, `stream_data ~> 1.0` (test only) |

**No Phoenix and no Ecto** are in the dependency tree — by design, and this is load-bearing (see §2). They arrive only at F6, as a new `apps/portal_web` Phoenix app that replaces the Bandit/Plug layer above the boundary.

Toolchain (`.tool-versions`, asdf): **Elixir 1.18.4**, **Erlang/OTP 28.1**. Both app `mix.exs` files pin `elixir: "~> 1.18"`, share `../../_build`, `../../config/config.exs`, `../../deps`, and `../../mix.lock`.

## 2. The master invariant (do not break this)

> **The domain core is framework-free and depends on nothing above it. The web layer calls only the `Portal.Engine` boundary and never reaches into the contexts, the store, or the core.**

Concretely: `Portal.Web.Router` (a `Plug.Router`) parses a request, calls **only** `Portal.Engine.dispatch/1` (writes) or `Portal.Engine.query/2` (reads), and formats the response — no domain logic, and it names nothing below the boundary (`apps/portal/lib/portal_web/router.ex`). The contexts and `Portal.Store` are reached *through* the engine GenServer, never directly from the web.

This invariant is **compiler-enforced**, not merely documented: `apps/portal/mix.exs` lists no Phoenix, so the core *cannot* call it — illegal coupling fails to compile. F6 swaps Bandit→Phoenix **above** the boundary without touching anything below it. When adding code, keep the dependency arrow pointing one way (web → boundary → contexts → store); never let the core reach upward.

## 3. Build / run / test — the gotchas (read these first)

All commands run from the umbrella root `/Users/jonny/dev/jonnify/echo`.

- **`TMPDIR=/tmp` for `mix test` — the one that actually bites.** The harness tmp overlay can reach 0 MB free (ENOSPC), which surfaces as *spurious mid-suite ExUnit I/O failures* unrelated to any logic error. Running tests with `TMPDIR=/tmp` avoids it. This footgun is recorded in the F5.4 and F5.5 retrospectives.
- **The determinism gate is a MULTI-RUN loop, not just multi-seed.** A single green `mix test` run is **not** evidence of determinism. Multi-seed (`mix test --seed N` across several seeds — `0`, `1`, `42`, `312540`, `999999`) varies *test ordering* and catches order-dependent bugs, so keep it as a complement. But the real ratification for any **Store- or process-touching** suite is a **repeated full-suite loop** — 100+ iterations, e.g. `for i in $(seq 1 150); do TMPDIR=/tmp mix test || break; done` — because the hazard that actually bit this codebase is *same-millisecond mint contention WITHIN a run* (see §4), which re-seeding does not reproduce: a new seed reshuffles order but does not re-create the timing collision, whereas a repeated full-suite run gives the rare same-ms mint many independent chances to fire. This is not hypothetical — the arc hit the **same** id-collision flake three times (F5.4 seed-`312540`, F5.6 `enroll_slice`, F5.7 `learning_test`), and **each was caught only by the independent multi-run loop**, never by the implementer's single (even multi-seed) run. Treat the independent loop, not the implementer's report, as the gate.
- **`GOWORK=off` — harmless, conventional, and irrelevant to `mix`.** The repo-root `CLAUDE.md` requires `GOWORK=off` for *Go* commands (the repo's `go.work` references uninitialized submodules). `GOWORK` is a Go-toolchain variable; **`mix` ignores it entirely** — a bare `mix compile` / `mix test` works here with `GOWORK` unset. Prepending `GOWORK=off` to `mix` invocations is a no-op carryover from the Go side; it does no harm and keeps muscle memory consistent across the repo, but it is **not** required for `mix` to function. Do not document it as mandatory.

```bash
cd /Users/jonny/dev/jonnify/echo
mix deps.get                       # resolves bandit/plug/jason/stream_data into ../../deps
mix compile --warnings-as-errors   # the clean-compile gate
mix format                         # the formatter; `mix format --check-formatted` to verify
TMPDIR=/tmp mix test               # the suite
TMPDIR=/tmp mix test --seed 42     # one seed of the multi-seed gate (repeat across seeds)
iex -S mix                         # boots the app; Bandit answers HTTP on :4000 (PORT overridable)
mix run --no-halt                  # same, without the shell
```

A green suite today is **echo_data: 2 tests**, **portal: 5 doctests, 4 properties, 45 tests**, 0 failures; a live node answers on `:4000`. The supervision tree starts **data → compute → web**: `Portal.Store`, then `Portal.Engine`, then `{Bandit, plug: Portal.Web.Router, port: …}`, under `:one_for_one` (`apps/portal/lib/portal/application.ex`).

## 4. The latent id-collision constraint (test-only hazard)

`EchoData.Snowflake.generate/1` *defaults* its `worker_id` to `:erlang.phash2(self(), 1024)` — a **per-process** value — and keeps its 12-bit sequence counter in the **process dictionary** (`Process.get/put(:echo_data_snowflake_sequence, …)`, `apps/echo_data/lib/echo_data/snowflake.ex`). But `Portal.ID.new/1` **overrides that default**, passing a hardcoded `worker_id: @node` where `@node = 1` (`apps/portal/lib/portal/id.ex`). The override defeats the primitive's per-PID distinction, so two *different* processes minting in the **same millisecond** can produce the **same** branded id.

- **In production this cannot happen:** all mints serialize through the single-writer `Portal.Engine` GenServer, so there is only ever one minting process at a time.
- **In multi-process tests it can:** a freshly-minted "nonexistent" id in one test can equal another test's stored id. Mitigate **per suite**, not by changing `id.ex`: `use ExUnit.Case, async: false`, and a `setup` that calls `Portal.Store.reset/0` to start each test from an empty store. `Portal.EnrollContractTest` is the worked example, and `Portal.Store.reset/0`'s own moduledoc records the rationale.
- **The per-test-reset convention is error-prone, and a case template is the proposed fix.** A test that mints without a `Portal.Store.reset/0` (or `EventLog`/`Engine.reset/0`) `setup` flakes only *probabilistically*, so the missing reset is **invisible until a flake fires** — which is exactly how the same hazard slipped into three different tests across the arc. The proposed systemic fix (a carried follow-up, **not yet built**) is a shared ExUnit case template — `Portal.StoreCase` / `Portal.EngineCase` — that performs the reset in its own `setup`, so every Store- or fold-touching test `use`s it instead of hand-rolling the isolation, turning "remember to reset" into "cannot forget."

**Do not "fix" `Portal.ID` to dodge this** — production is single-writer and correct as-is. `id.ex` already flags the eventual change (`@node = 1` … "F6.8 derives it per machine"). A future multi-writer runtime or a multi-process test harness is what would force a per-process / scheduler-derived `worker_id` or moving the sequence out of the process dictionary.

## 5. The Portal surface (the real API — cite, never invent)

This is the as-built public surface. When authoring against it, match these arities and shapes exactly; do not redefine them.

| Module | Public functions | Notes |
|---|---|---|
| `Portal.ID` | `new/1`, `valid?/1`, `namespace/1`, `snowflake/1`, `at/1` | Branded id = 3-letter uppercase namespace + 11-char Base62 (14 bytes). `valid?/1` enforces the **full** format — a bare `"USR1"` passes `namespace/1` but **fails** `valid?/1`. The integer snowflake is canonical; the string is transport. |
| `Portal.Engine` | `dispatch/1`, `query/2`, `reset/0` | The boundary GenServer (the master-invariant seam) and, since **F5.6**, the runtime home of the F5.5 pure core. `init/1` folds the live `Portal.EventLog` (`Core.replay(EventLog.all())`) into the held state and re-projects the Store read-model; a command runs `Core.authorize → decide → evolve → EventLog.append → project`, a query reads the held fold. `dispatch/1` takes a **map** command (`%{type: :enroll, user_id: …, course_id: …}`) → `{:ok, %Enrollment{}} \| :ok \| {:error, %Portal.Error{} \| atom}` (the shell maps `authorize`'s bare atom → `%Portal.Error{}` via `Portal.Error.new/1`, and stamps the occurrence `at`). `query/2` is `(name_atom, arg)` → `{:ok, term} \| :error \| [term]` (`:lesson` = catalog read, `:courses_of` = the Store-projection list, `:enrollments` = the folded read aliased behind it). The Store `%Enrollment{}` rows are a **dual-write** projection of the fold (the fold is the source of truth) kept so the F5.3/F5.4 web is byte-for-byte unchanged; `reset/0` re-folds the held state from the current (caller-emptied) log for test isolation, sharing its body with `init/1`. **Since F5.8 (`b099eee`):** `dispatch/1`/`query/2` are renamed to `command/1`/`query/1`, the web reaches them only through the `Portal` facade (`enroll/2`·`deliver_lesson/2`·`progress_of/1`·`courses_of/1` + a `lesson/1` passthrough), and the command path is **append-before-evolve** — `decide → append` (the `EventStore` port) `→ evolve → project`; a failed append aborts, leaving the held fold AND the dual-write Store byte-unchanged. |
| `Portal.Engine.Core` | `initial_state/0`, `decide/2`, `authorize/2`, `evolve/2`, `replay/1`, `query/2` | The **F5.5 pure Decider** — plain functions, no process, no I/O, no clock. Commands here are **4-tuples** (`{:enroll, user_id, course_id, at}`), distinct from the live engine's map command. See §6. |
| `Portal.EventLog` | `all/0`, `append/1`, `reset/0` | The in-memory append-only event log (**F5.6**) — the source of truth `Portal.Engine` folds. A **separate** process started **before** the Engine, so an Engine crash re-folds the CURRENT log (a supervisor evaluates a child's args once; a static `{Engine, events}` arg would re-fold a stale boot snapshot). `all/0` returns events in append order; `append/1` records on each successful command; `reset/0` is the test-isolation hook. In-memory ⇒ empties on a full app restart; the durable, swappable `EventStore` port swaps in behind this surface at **F5.8**. **Since F5.8 (`b099eee`) `Portal.EventLog` is superseded** — the engine reads/appends through the `Portal.EventStore` port and `application.ex` starts `EventStore.adapter()` (`InMemory` in dev/test, `Postgres` stub in prod) instead, so `EventLog` is retained but **unstarted and uncalled** (dead code, a cleanup candidate for a later rung). |
| `Portal.Store` | `get/2`, `all/2`, `put/1`, `reset/0` | In-memory, namespace-partitioned `%{namespace => %{id => struct}}`, GenServer-owned. The stand-in for the F4 branded CHAMP — same `get/all/put` surface, so the real CHAMP swaps in with zero caller change. **Empties on restart.** `reset/0` is the test-isolation hook (§4). |
| `Portal.Error` | `new/1` | Closed expected-failure vocabulary: `%Portal.Error{code, message}`, `@enforce_keys [:code, :message]`, closed `@type code :: :course_not_found \| :already_enrolled`. `new/1` maps a **bare code** → the struct. **F5.8 (`b099eee`) extended it** to the final four-code union (`:already_enrolled`/`:course_not_found`/`:lesson_locked`/`:invalid_progress` — only the first two have producers; the rest reserved) + optional `:field` + a no-catch-all `from/1`; still **no** `Jason.Encoder`. |
| `Portal.Accounts` · `Portal.Catalog` · `Portal.Learning` | context functions (e.g. `Learning.enroll/2`, `Learning.courses_of/1`, `Catalog.course/1`, `Catalog.lesson/1`) | The three bounded contexts. Each owns its entities and references other contexts only by branded id. `Learning.enroll/2` is the F5.4 contract `with`-chain. |

**The seven entities** (each a struct with `@enforce_keys`, `@type t`, and a `@derive Jason.Encoder`), with their id namespaces:

| Entity | Module | Namespace |
|---|---|---|
| User | `Portal.Accounts.User` | `USR` |
| Session | `Portal.Accounts.Session` | `SES` |
| Course | `Portal.Catalog.Course` | `CRS` |
| Lesson | `Portal.Catalog.Lesson` | `LSN` |
| Page | `Portal.Catalog.Page` | `PGE` |
| Enrollment | `Portal.Learning.Enrollment` | `ENR` |
| Progress | `Portal.Learning.Progress` | `PRG` |

`@derive Jason.Encoder` keeps the web layer dumb — entities serialize themselves; no struct→map mapping leaks domain shape into the router.

## 6. The Decider pattern

The engine's write path is the functional **Decider** (`decide`/`evolve`), spread across three rungs: F5.4 owns the contract and the closed reasons, F5.5 the pure core, F5.6 the runtime home. The reference write-up is `docs/elixir/specs/pragmatic/decider-pattern.md`.

- **`decide/2` proposes facts.** Pure, **events-only**: `(state, command) -> [event]`. It is reached only for an admissible command and emits the event(s) to record; it carries **no error channel**. The occurrence time `at` arrives as the command tuple's **4th element**, supplied by the boundary, so `decide` holds no clock and is a deterministic function of `(state, command)`.
- **`authorize/2` decides admissibility.** The F5.4 contract at the boundary: it runs the reference checks, a single catalog read (`Portal.Catalog.course/1` — the *only* call-out in `Portal.Engine.Core`), and the not-already-enrolled check **against the folded state**, returning a **closed `{:error, reason}`** (bare atom) *before* `decide` runs. The F5.6 shell maps that atom → `%Portal.Error{}` via `Portal.Error.new/1` (the existing seam).
- **`evolve/2` folds one event** into state (`(event, state) -> state`, the `Enum.reduce/3` arg order); **`replay/1`** is the left fold of `evolve` over `initial_state/0`, so **state is exactly the fold of the log**.

Event-sourcing is **scoped**: enrollment/progress is event-sourced; the **catalog is plain CRUD** (reference data does not belong in the log). Two command shapes coexist by design — the live `Portal.Engine.dispatch/1` takes a map (F5.3), the pure `Portal.Engine.Core` takes a 4-tuple (F5.5); F5.6 reconciled them when the GenServer adopted the core (`dispatch/1`'s shell translates the web map → a 4-tuple core command and stamps `at`).

## 7. Specs are the source of truth — and the *body* is authoritative

The specs in `docs/elixir/specs/pragmatic/` drive the build. Each rung is a triad — `f5.N.md` (the spec body), `f5.N.stories.md` (user stories), `f5.N.llms.md` (the agent brief) — plus the append-only `f5.progress.md` retrospective.

> **Rule: the `f5.N.md` body is authoritative. The `.llms.md` agent brief and the `.stories.md` stories can LAG the resolved body.** Verify `decide`/contract shapes against the body **and** `decider-pattern.md` §2.1 before trusting the brief.

This is not a theoretical caution — it has bitten twice. In F5.5 the `.llms.md` brief, taken literally, would have directed construction of a **non-canonical** Decider (`decide` with an error channel, the contract inside `decide`, `at` omitted), while the body and `decider-pattern.md` §2.1 already specified the canonical form (`decide` events-only, the contract at the boundary, `at` boundary-supplied). The correct build proceeded from the body and its binding decisions, and the lagging surfaces were brought up to it afterward. When the brief and the body disagree, the body is what gets built.

A larger instance hit F5.8/F5.9 (2026-06-03): **unbuilt** triads drift from the core in *lockstep* when authored ahead of the build. F5.8/F5.9 assumed a `command/1`+`query/1` boundary and a creatable `Portal`, but F5.4–F5.7 settled `dispatch/1`+`query/2`, the `Portal` stub, the separate `EventLog`, and the dual-write — and the downstream triads were not re-synced as each rung landed, so the fix compounded into a **14-delta reconciliation** across six files. **Discipline: re-sync an unbuilt rung's triad at the close of each preceding rung** (fold that rung's surface changes forward), keeping the lag at one rung. When a re-sync is unavoidable, the harness that makes it auditable: a **ground-facts surface** (a read-from-code inventory of the real module surface + a numbered delta list, each `stale-claim → correction → owner`), **one-owner-per-file** partitioning (bodies / briefs / stories — no two editors share a file), and an independent **cross-file verify** before the single commit (every Deliverable → a story; every brief Requirement cites a real arity; no `create` verb for a module that already exists).

## 8. The F5 → F6 arc

| Rung | What it adds | Status |
|---|---|---|
| F5.1–F5.3 | The walking skeleton: a supervised app on `:4000`; branded Snowflake ids; the `Portal.Engine` boundary; the Accounts/Catalog/Learning domain over `Portal.Store`; `enroll` wired end to end. | done |
| F5.4 | The enroll **contract** + the closed `%Portal.Error{}` vocabulary (`:course_not_found \| :already_enrolled`); fail-fast `with`-chain; `Portal.Store.reset/0`. | done |
| F5.5 | The **pure Decider core** (`Portal.Engine.Core`: `decide`/`evolve`/`replay`/`authorize`/`query`) + the past-tense events `LearnerEnrolled` / `LessonDelivered`; property-tested. | done |
| F5.6 | The engine's **runtime home**: a supervised `Portal.Engine` GenServer that holds the folded state, recovers by **replay at `init`** from a separate `Portal.EventLog` process, routes `dispatch`/`query` through the fold, and maps `authorize`'s atom → `%Portal.Error{}`. Keeps the Store `%Enrollment{}` as a dual-write projection so the web is byte-for-byte unchanged; `:enrollments` is aliased behind the live `:courses_of` (the canonical name is an F6 pick). | done |
| F5.7 | Pragmatic testing — the weighted pyramid (doctests + properties on the pure core, one process smoke at the tip). | done |
| F5.8 | A durable **`EventStore`** port (swaps in behind `EventLog`'s `all/0`/`append/1` surface) + the `Portal` facade (the `dispatch/1`+`query/2` → `command/1`+`query/1` rename, **populated** into the reserved stub); **append-before-evolve** (the fallible-port inversion of F5.6); extends `%Portal.Error{}` (adds `:field`, the final four-code union, no-catch-all `from/1`). | **shipped 2026-06-03 (`b099eee`)** |
| F5.9 | The assembled lab: the four-child tree (only `EventLog → EventStore.adapter()` swapped — `Portal.Store` + Bandit retained), the append-before-evolve command path, the facade, a **compile-only** `EnrollmentLive` sketch; states the F6 handoff. | **shipped 2026-06-03 (`220ce05`); the F5 "Pragmatic" arc COMPLETE — next is F6.1** |
| F6 | **Phoenix** in `apps/portal_web` replaces the Bandit/Plug web layer above the boundary; deploy. The domain, ids, store, and engine boundary are **preserved** — nothing below the boundary changes; F6.1 adds only `PortalWeb.Endpoint`. ⚠ Open: `f6.1.md`'s tree omits the `Portal.Store` its `courses_of/1` needs — reconcile at F6. | planned |

The build discipline throughout is the tracer bullet: every layer is touched and grown one thin vertical slice at a time, the skeleton always running. New work extends the current rung's surface — check `f5.progress.md` for the latest ratified state and the carried-forward gaps before starting.
