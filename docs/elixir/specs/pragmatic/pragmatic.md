# F5 · Pragmatic Programming — Portal build guide

> A spec-first build guide for the **Portal**, the learning-platform engine this chapter constructs in Elixir.
> Each module guide carries the content, the specs, the actionables, and the copy-paste **build prompts** that take
> the system from nothing to a running, contract-checked slice. Read a guide, run its prompts in order, verify
> against its definition of done, then move to the next.

This is part of the jonnify course toolkit. The companion HTML modules teach the ideas; these markdown guides build
the system. The workflow is always **markdown first, presentation second**: the spec and prompts below are the source
of truth a slide deck is generated from.

## How to use these guides

1. Open the module guide and read **What you'll build** and **Concepts**.
2. Work through **Build it** — the numbered actionables, with commands and code.
3. When you want an agent to generate the code, paste the matching block from **Build prompts**; each prompt already
   carries the spec and the acceptance criteria.
4. Check every box in **Definition of done** before moving on. The Portal stays runnable after every module.

## The development roadmap

The Portal travels one path across the course. F5 owns the middle of it.

| Stage | What it delivers | Where |
| --- | --- | --- |
| HTML templating | EEx renders pages | earlier (done) |
| Simple web server | a thin Elixir server answers requests | **F5.01** |
| Portal logic | the engine: domain, contracts, events, state | **F5.02 – F5.09** |
| Phoenix | replace the thin server with Phoenix + LiveView | F6 |
| Fly production | deploy and run it live | upcoming, out of scope |

Start thin and grow: the system runs from day one, and each module leaves it running.

## Conventions

**Stack.** Elixir (OTP) · `Plug` + `Bandit` for the thin web layer (Phoenix replaces it in F6) · the F4 branded
CHAMP store (`Portal.Store`) for persistence · `Jason` for JSON. Prefer pure functions; keep side effects at the
edges.

**Layers.** Four, top to bottom: the **web** layer (route + handler), the **engine facade** (`Portal.Engine`,
consolidated in F5.08), the **domain core** (bounded contexts, structs, commands, events), and the **store** (F4).
The web never reaches past the boundary into the core.

**Identifiers.** Every entity is identified by a **Snowflake** — a 64-bit, time-ordered integer that is the canonical
identity (the value a column or store key holds). Its transport form is a **branded id**: a three-letter namespace
prefix plus the Base62-encoded snowflake.

```text
branded id:  ENR0KHTOWnGLuC
namespace:   ENR                       (Enrollment)
snowflake:   274557032793636864        (the canonical integer id)
created at:  2026-01-27 15:11:37 UTC   (decoded from the snowflake)
```

Snowflake layout (epoch `2024-01-01T00:00:00Z`, i.e. `1704067200000` ms): `timestamp = snowflake >>> 22`,
`node = (snowflake >>> 12) &&& 0x3FF`, `seq = snowflake &&& 0xFFF`. Namespaces in the Portal: `USR`, `SES`, `CRS`,
`LSN`, `PGE`, `ENR`, `PRG`.

`Portal.ID` is the one module that mints and decodes them:

```elixir
@type snowflake :: non_neg_integer()   # canonical identity, time-ordered
@type branded   :: String.t()          # namespace(3) <> Base62(snowflake)

Portal.ID.new(namespace)      :: branded     # mint a fresh branded id, e.g. new("ENR")
Portal.ID.snowflake(branded)  :: snowflake   # decode to the raw integer
Portal.ID.namespace(branded)  :: String.t()  # "ENR"
Portal.ID.at(branded)         :: DateTime.t() # creation time from the snowflake
```

## Modules

### F5.01 · Start thin: a running Portal from day one → [guide](f5-01-start-thin.md)

Stand the Portal up behind a minimal `Plug.Router` served by `Bandit`, with a stubbed `Portal.Engine` boundary and
the `Portal.ID` generator. The deliverable is a supervised app that answers real HTTP on port 4000 and a web layer
thin enough that Phoenix replaces it in F6 untouched. **Build target:** `mix run` and `curl` reach a live route.

### F5.02 · Modeling the Portal domain → [guide](f5-02-domain.md)

Model the entities as plain structs with typespecs, group them into the **Accounts**, **Catalog**, and **Learning**
bounded contexts, and give each context a small public API. Contexts reference one another only by branded id.
**Build target:** valid structs that raise on missing keys, and context APIs ready to call.

### F5.03 · Tracer bullets: a walking skeleton → [guide](f5-03-tracer-bullets.md)

Wire one use case — enroll a learner — end to end through every layer: route → context API → struct → store → 201.
Then grow the skeleton one thin vertical slice at a time (deliver a lesson). **Build target:** a real `curl` enroll
produces a stored enrollment.

### F5.04 · Design by contract → [guide](f5-04-contracts.md)

Harden the enroll command with a contract: a precondition the caller meets, a postcondition the command guarantees,
and an invariant always true of the state — asserted with guards, a `with` chain, tagged tuples, and `raise`, and
failing fast at the boundary. **Build target:** invalid input is rejected at the door with the right status, and
nothing downstream is corrupted.

### F5.05 · Commands, queries & events → [guide](f5-05-cqrs.md)

Separate writes from reads and record every change as a past-tense event, collapsing the engine to two pure
functions: `decide` turns a command into events, `evolve` folds one event into state, and `replay` derives the current
state from the log. **Build target:** commands return `:ok`/`{:error, _}`, queries return data, and state is the fold
of an event log.

### F5.06 · Where engine state lives → [guide](f5-06-state.md)

Keep the folded state alive between requests in a process: `Portal.Engine`, a GenServer whose `init/1` replays the log
once, with a command `handle_call` that runs `decide`/`evolve` and a query `handle_call` that reads — supervised so a
crash restarts and re-folds. **Build target:** a supervised engine that holds state and rebuilds it from the log on
restart.

### F5.07 · Pragmatic testing → [guide](f5-07-testing.md)

Test the pure core with plain example tests (no processes, no mocks), state invariants as StreamData properties, turn
the F5.04 contract into contract tests, and keep docs honest with doctests — one thin process smoke test at the tip.
**Build target:** a fast suite weighted to the pure base, with a single command→query process test.

### F5.08 · Boundaries & integration seams → [guide](f5-08-boundaries.md)

Draw the engine's edges: a driven `Portal.EventStore` port with interchangeable in-memory and Postgres adapters chosen
by config, the driving `Portal` facade as the only surface the web calls, and a closed `Portal.Error` vocabulary
consumed exhaustively by the UI. **Build target:** the core depends only on ports, callers only on the facade, and
failures cross as typed errors.

### F5.09 · Lab: assemble the Portal engine, LiveView-ready → [guide](f5-09-engine-lab.md)

Wire the parts into one running system: the `EventStore` port and its in-memory and Postgres adapters, the `Portal`
facade over the engine, the closed `%Portal.Error{}` contract, the supervision tree whose engine replays its log on
boot, and a LiveView mount sketch that touches only the facade. Then state the F6 handoff. **Build target:**
`mix run` boots the app, an enroll persists an event, and a restart of the engine replays to the same state.

## Global build sequence

To build the Portal end to end, run each module's build prompts in order. Each lives in its module guide.

1. `f5-01` — Scaffold the app · the thin router · `Portal.ID` · a replaceable web layer · the roadmap · run & verify.
2. `f5-02` — Entity structs · bounded contexts · public APIs · typespecs · enforced boundaries · cross-context
   composition.
3. `f5-03` — Tracer bullet vs prototype · the walking skeleton (enroll end to end) · keep every layer thin · a second
   slice · grow by adding slices.
4. `f5-04` — The enroll contract (precondition/postcondition/invariant) · named checks · a second contracted command ·
   fail-fast: what crashes vs what returns a typed error.
5. `f5-05` — Command/query separation · past-tense domain events · `decide/2` (contract + emit) · `evolve/2` +
   `replay/1` · a second use case · state is derived from the log.
6. `f5-06` — Choose where state lives · the engine GenServer folding at `init` · command and query `handle_call`s ·
   supervise the engine · verify a restart re-folds.
7. `f5-07` — Example-test the pure core · test the fold · a StreamData property · contract tests from F5.04 · doctests ·
   one process smoke test.
8. `f5-08` — The driven `EventStore` port · two adapters by config · core calls the port only · the `Portal` facade ·
   the closed `Portal.Error` contract · exhaustive consumption (the F6 seam).
9. `f5-09` — Assemble the engine: the port + adapters, the facade, the error contract, the supervised tree, and the
   LiveView mount sketch · verify boot, a command, and a restart that replays.

After the lab the Portal runs as a supervised engine behind a stable facade, mounted under a LiveView sketch, and is
ready for F6 (replace the thin server with Phoenix + LiveView).

---

> Part of the jonnify toolkit. Branded build-stamp id format: `TSK` + Base62(snowflake), e.g. `TSK0KHTOWnGLuC`.
> Markdown is the source; the presentation is generated from it.
