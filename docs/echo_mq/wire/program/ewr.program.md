# EchoWire — the program operating manual

> **The HOW-WE-SHIP-IT.** The *what* lives in the canon: [`../design/ewr.design.md`](../design/ewr.design.md)
> (the ruled fork, Arm A), [`../ewr.roadmap.md`](../ewr.roadmap.md) (the delivery plan + rung ladder),
> [`../ewr.progress.md`](../ewr.progress.md) (the as-built dashboard), [`../ewr.features.md`](../ewr.features.md)
> (the valkey-go pattern catalog + the additive/MAJOR map), [`../ewr.testing.md`](../ewr.testing.md) (the
> testing posture). **This file is the program's OPERATING CONTRACT** — the AAW team, the recalibrated pipeline,
> the two-app gate ladder, the boundary, the durable footguns, the live frontier — and the home of the per-agent
> calibrations ([`./ewr.venus.md`](./ewr.venus.md), [`./ewr.mars.md`](./ewr.mars.md),
> [`./ewr.apollo.md`](./ewr.apollo.md)).
>
> **The wire program is a DELTA over the bus program.** It runs the same AAW Flat-L2 lead-team and the same
> recalibration (the 2026-06-17 D-1 split) as the EchoMQ bus; this manual records only what is **wire-specific**
> and cites the bus manual ([`../../program/emq.program.md`](../../program/emq.program.md)) for the shared rest.
> It is grounded in the founding rung `ewr.1.1` (`EchoWire.Pipe`), shipped through this pipeline and recorded in
> [`../specs/progress/ewr-1-1.progress.md`](../specs/progress/ewr-1-1.progress.md); every claim below cites a
> `D-n`/`L-n`/`Y-n`/`Z-n` of that ledger or a real `file:line`.

## The program in one paragraph

`echo/apps/echo_wire` is the **owned wire**: a single-owner `:gen_tcp` connector that auto-pipelines concurrent
callers (`EchoMQ.Connector`), a full RESP3 decoder (`EchoMQ.RESP`), EVALSHA-first scripting (`EchoMQ.Script`), a
round-robin pool (`EchoMQ.Pool`, in `echo_mq`), all behind a **frozen 11-verb facade** (`EchoWire`,
`lib/echo_wire.ex:19-31`). The **EchoWire client-core program** adds the one half the wire never owned — the
**construction** half: above `Connector.pipeline/3` a caller hand-writes nested `[[binary]]` literals and keeps
positional flags correct by eye, where the valkey-go (rueidis) client offers a fluent builder. The program ports
that construction ergonomics in idiomatic Elixir, **additively, never into the wire** ([`../ewr.roadmap.md`](../ewr.roadmap.md)).
One program, two movements: **Movement I** (the ergonomic core — `ewr.1.1` the threaded `|>` pipeline · `ewr.1.2`
the immutable command value · `ewr.1.3` the two-tier error split) and **Movement II** (server-assisted caching /
`CLIENT TRACKING` — PROPOSED, the single seam that may cut the frozen connector). The founding rung **`ewr.1.1`
shipped** (`Z-1`): `EchoWire.Pipe` (`echo/apps/echo_wire/lib/echo_wire/pipe.ex`), the `%Pipe{conn, via, timeout,
cmds}` accumulator threaded by `|>`, a comprehensive curated verb set across the six Valkey data families + a
`command/2` escape hatch, flushing once through an opaque conn-or-pool dispatch.

## The AAW team + the recalibrated pipeline (Flat-L2)

One rung per run through the aaw lead-team, **Director-orchestrated**, to one ratifying **LAW-4** commit. The
team and the role split are the **2026-06-17 (D-1) recalibration** — identical to the bus program's
([`../../program/emq.program.md`](../../program/emq.program.md), the AAW team). The roster as it ran for
`ewr.1.1`:

- **Venus — the architect / spec-steward / strawman author** ([`./ewr.venus.md`](./ewr.venus.md)). Authors the
  strawman triad, reconciles it against the as-built tree (lag-1 pre-build, SPECCED→BUILT post-build), and
  **frames the seam forks as four-part Arms** (Rationale / 5W / Steelman / Steward —
  [`../../../aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md)) for the Director to rule.
  Surfaces, never rules. For `ewr.1.1`: expanded the triad to the ruled Arm A — pool first-class, the six-family
  verb set, the BDD story layer — and reconciled SPECCED→BUILT after the ship (the `As-built reconcile` block,
  [`../specs/ewr.1/ewr.1.1.md`](../specs/ewr.1/ewr.1.1.md)). Edits ONLY the spec triad + the canon docs; never
  code; no git.
- **Director — the orchestrator + the verifier.** Rules each Arm/fork *with the Operator* via the **mandatory
  `AskUserQuestion` gate** (a fork is never decided silently); then **independently verifies code + invariants**
  — a fresh two-app gate re-run on Valkey `6390`, an adversarial read, a net-zero mutation spot-check; runs the
  REMEDIATE loop; **consolidates the rung's findings + learnings for Apollo**; lands the LAW-4 pathspec commit.
  For `ewr.1.1`: **two `AskUserQuestion` gates** — conn-or-pool first-class this rung (vs deferred), and the F-1
  ruling (wire dir + a generator filter); the independent verify **caught F-1** (the non-idempotent stories dir,
  `L-1`/`L-2`). Calls no Edit on production code except a net-zero mutation spot-check (LAW-1a).
- **Mars — the implementor + THE PRIMARY CODE-QUALITY GATE** ([`./ewr.mars.md`](./ewr.mars.md)). Builds the
  increment AND adversarially self-verifies (the gate ladder + the adapted adversarial battery + the
  story-generation coverage) **BEFORE reporting**. For `ewr.1.1`: Mars-1 built `EchoWire.Pipe` + the 8 BDD story
  tests (`Y-1`); Mars-2 remediated F-1 with the `--match` Mix-task filter and a twice-identical idempotent regen
  (`Y-2`). The Lua-specific battery items were **N/A and declared so** — `ewr.1.1` adds no Lua — reduced honestly
  to the order theorem + the frozen-floor proof + the module mutation kill-rate (`P-1`). Edits code + tests;
  never the spec; no git.
- **Apollo — the Mentor (exclusively), out of the pipeline** ([`./ewr.apollo.md`](./ewr.apollo.md)). Receives
  the Director's consolidated findings + learnings (`L-1..L-4`) and turns them into **better agents + a better
  process** — one guardrail per finding aimed at the implicated contract, sharpen-don't-stack, **PROPOSE-ONLY**.
  Keeper of this manual + the per-rung retrospective. No build, no verify, no story coverage (→ Mars), no closure
  reconcile (→ the Director / Venus).

**The pipeline:** Venus (strawman + Arms) → **Director (rules the Arms via `AskUserQuestion`)** → **Mars (build +
self-verify + stories)** → **Director (verify code + invariants + REMEDIATE)** → Mars-2 (remediate + harden) →
**Director (ship + consolidate findings)** → **Apollo (calibrate the agents)**. The verification floor = Mars's
adversarial self-verification **+** the Director's independent verify; Apollo is off the critical path — it makes
the *next* rung's agents better, not this rung's build slower. **LAW-1 (no role-play):** every peer is a REAL
`Agent` spawn that self-registers. **The persistence law:** a verifier records its verdict before going idle —
the wire program inherits both unchanged from the bus manual.

## The wire master invariant — additive above the conformance boundary

The wire client-core lives **above** the conformance boundary, and **every Movement-I rung is additive-minor by
construction** ([`../ewr.roadmap.md`](../ewr.roadmap.md), The master invariant). The frozen floor, re-proven
byte-stable each rung:

- `EchoMQ.Connector` / `RESP` / `Script` / `Pool` stay **frozen** — reuse, never edit. The new surface is a
  **new module** (`EchoWire.Pipe` this rung), never a facade delegate.
- The `EchoWire` facade stays fixed at exactly **11 verbs** (`lib/echo_wire.ex:19-31`, pinned by
  `echo_wire_facade_test.exs`). `EchoWire.Pipe` is NOT a 12th verb (`INV1`); it is NOT arity-frozen itself, so a
  curated verb's arity is the implementor's design-make (`D-5`), not a frozen `{fun, arity}` table.
- **No new Lua enters the wire** — `grep redis.call` on the lib diff is `0` (`INV2`, re-proven `Y-2`).
- The `echo_mq` **52-scenario conformance stays byte-stable** — `Conformance.run/2 → {:ok, 52}`
  (`echo/apps/echo_mq/test/conformance_run_test.exs:45`). Because the layer is **above** the conformance
  boundary, the additive-minor **registration** law is **not engaged**: no scenario is probe-registered, **no
  `registry.json` is written** (`INV2`; the ledger header records the absence). This is the sharpest delta from
  the bus, where every capability rung registers a conformance scenario — here the count is re-**pinned**
  byte-stable, never grown.

**The single exception** is Movement II's caching: the `CLIENT TRACKING ON [OPTIN|BCAST]` handshake must survive
reconnect, which needs a boot-step in the **frozen connector** (`boot_rest/4`, `connector.ex:436`) — the one
place the program may cut into the wire, gated as an explicit **MAJOR** with its own surfaced fork, never folded
into an additive rung ([`../ewr.features.md`](../ewr.features.md), The fault line). The additive/MAJOR fault line
is the wire program's central scoping fact: an additive façade over `pipeline/3` is a MINOR; a connector
boot-step is a MAJOR.

## The two-app gate ladder (the operating procedure) — and WHY it is two apps

The wire program's gate ladder is **per-app and spans TWO app dirs**, because the dependency direction forbids
one. The module + the pure construction pins live in **`echo_wire`** (the `deps: []` base); the BDD `:valkey`
stories live in **`echo_mq/test/stories/`** because `echo_mq` depends on `echo_wire`
(`echo/apps/echo_mq/mix.exs:31` `{:echo_wire, in_umbrella: true}`) — so a story test can drive `EchoWire.Pipe`,
where placing it in `echo_wire` would invert the dependency. The gate therefore runs from **both** app dirs
(`D-7`):

- **Re-probe `.tool-versions` from the app dir** — never hardcode the toolchain (inside `echo/` it resolves to
  Elixir 1.18.4 / Erlang 28.5.0.1, re-probed per app; `P-1`). `valkey-cli -p 6390 ping` → `PONG` (the live engine
  is Valkey on `6390`).
- **From `echo/apps/echo_wire/`:** `TMPDIR=/tmp mix compile --warnings-as-errors` clean; `TMPDIR=/tmp mix test`
  — the construction (offline) suite + the facade-freeze (`ewr.1.1`: **44/0**, facade still **11 verbs**).
- **From `echo/apps/echo_mq/`:** `TMPDIR=/tmp mix compile --warnings-as-errors` clean; `TMPDIR=/tmp mix test
  --include valkey` — the wire `:valkey` story suite on `6390` (`ewr.1.1`: **9/0**, 9 scenarios / 8 features);
  `Conformance.run/2 → {:ok, 52}` re-pinned byte-stable (the 3 pin tests green).
- **The frozen-floor proof (standing):** the facade-freeze test byte-identical to HEAD; conformance `{:ok, 52}`
  byte-stable; `grep redis.call` on the lib diff = `0`; `echo/mix.lock` unchanged; no `lib/echo_mq/` runtime
  edit, no facade edit (`Y-2` touch-set).
- **`TMPDIR=/tmp` on EVERY mix command** (the harness tmp overlay hits ENOSPC and surfaces as spurious mid-suite
  I/O failures — inherited from the bus manual's footguns).
- **Determinism posture (the honest delta).** A Movement-I rung adds **no id-mint, no new process, no lease** —
  the construction surface is synchronous pure functions and the round-trips are deterministic request/reply, so
  the same-millisecond branded-id mint hazard cannot arise and the **≥100 determinism loop is NOT run** (running
  it would forge load the rung does not introduce). The honest posture is a **multi-seed sweep**
  (`for s in 0 1 42 312540 999999; do TMPDIR=/tmp mix test --seed $s || break; done`) of both suites + this
  statement (`P-1`: 5/5 both suites). A later caching rung that introduces a tracking process re-engages the loop
  ([`../ewr.testing.md`](../ewr.testing.md), Determinism posture).

## The story-gen discipline — a committed artifact reproduces from ONE command (the F-1 lesson)

The BDD story layer is the same self-documenting-tests pipeline the bus owns: `EchoMQ.Story`
(`echo/apps/echo_mq/test/support/echo_mq/story.ex`) `:valkey` scenarios → `mix echo_mq.stories` (offline harvest
of `__stories__/0`) → `<feature>.stories.md` + a README catalogue. The wire program writes them into the **wire**
docs (`docs/echo_mq/wire/stories/`). The founding rung earned the program's standing discipline through F-1
(`L-1`/`L-2`):

- **The F-1 finding.** `mix echo_mq.stories` harvests over a **fixed glob** (`test/stories/*_story_test.exs`),
  so a bare `--out docs/echo_mq/wire/stories` swept ALL features — the bus's `flows`/`groups`/`flow-failure`
  included — into the wire dir. Mars-1 hand-pruned the over-produced bus features out, leaving a **non-idempotent
  artifact** (a re-gen re-pollutes) — a gate-invisible reproducibility hole the Director's independent verify
  caught in Stage-2.
- **The standing rule.** A committed generated artifact **must reproduce from one documented command,
  byte-for-byte**. The remediation (Operator-ruled, `Y-2`) is the **`--match <substring>` filter** on the Mix
  task (`echo/apps/echo_mq/lib/mix/tasks/echo_mq.stories.ex:35-101`): additive + backward-compatible (`match ==
  nil` → the default → byte-identical to today), filtering the harvested FILE SET by `Path.basename` containing
  the substring. The wire program's scoping command is therefore `mix echo_mq.stories --match wire_pipe --out
  docs/echo_mq/wire/stories` — a **pure generator output**, run twice and `diff -r` clean (`Y-2`). The
  generalized lesson lives as a guardrail in both peers' calibrations: the SPEC must name a reused tool's scoping
  semantics ([`./ewr.venus.md`](./ewr.venus.md), `L-1`), and a hand-pruned generator output is a finding to
  surface, not a step to absorb ([`./ewr.mars.md`](./ewr.mars.md), `L-2`).
- **The two story layers are distinct** (`INV8`): `specs/ewr.1/ewr.1.1.stories.md` is the **hand-authored USER
  stories** (the acceptance face a person signs); `docs/echo_mq/wire/stories/*.stories.md` is the **GENERATED
  proof** harvested from the as-built `_story_test.exs` — neither edited to fork from the body, both naming the
  same redis-pattern set.

## The boundary

`echo/apps/echo_wire` (the module + its pure tests) **plus** the ONE sanctioned `echo_mq` edit a wire rung makes
— the BDD story TOOLING: the story tests under `echo/apps/echo_mq/test/stories/` (test-only, the dep direction
demands it) and, for `ewr.1.1` only, the additive `--match` Mix-task edit
(`echo/apps/echo_mq/lib/mix/tasks/echo_mq.stories.ex` — build tooling, default byte-identical; `Z-1`/`Y-2`).
**Never** the frozen runtime (`lib/echo_mq/` connector/RESP/Script/Pool), **never** the facade, **never** a third
app, **never** `echo/mix.lock` unless a real dep moved (expect EXCLUDED). **Out-of-band — never in an ewr commit**
(the `git commit -- <pathspec>` law, never `git add -A`): the Operator pre-stages out-of-band — for `ewr.1.1`
`echo/README.md`, the staged `emq.*` spec edits, and `memory/` were all EXCLUDED from the LAW-4 commit as a
concurrent pre-stage (`Y-2` FLAG, `Z-1` EXCLUDED). Re-verify `git diff --cached --name-only` is purely the rung
boundary immediately before the commit; ABORT on any foreign path.

## The durable footguns (the lessons that cost us)

The wire program inherits the bus program's footguns ([`../../program/emq.program.md`](../../program/emq.program.md),
The durable footguns) — the mutation-revert footgun (revert by an inverse Edit, never `git checkout`), the
concurrent-index race (the guarded pathspec commit, proven again here — `echo/README.md` pre-staged mid-rung),
the persistence law, and records-freeze. Wire-specific additions earned on `ewr.1.1`:

1. **The shared-generator scoping trap (L-1 / L-2).** A reused generator with a fixed glob over-produces into a
   per-program output dir; a committed artifact that needed a hand-prune is non-idempotent. Reproduce from one
   documented command (the `--match` filter), or the tool enhancement is in-scope for the rung — see the
   story-gen discipline above.
2. **The conn-or-pool opacity → a carried dispatch module (L-3, affirm).** The "accept conn-or-pool, never
   inspect it" contract (`INV3`) is realized as `%Pipe{via}` carrying the dispatch module (default
   `EchoMQ.Connector`; `EchoMQ.Pool` via `opts[:via]`), `exec = via.pipeline(...)`, with **no**
   `is_struct`/`is_atom`/module-name guard (`pipe.ex:503-504`). This is the correct Elixir idiom for an opacity
   contract — carry the behaviour, do not detect the type — and propagates to every future conn-or-pool surface
   ([`./ewr.mars.md`](./ewr.mars.md), `L-3`).
3. **The order-theorem mutation is the standing proof of a positional-reply invariant (L-4).** Any "replies map
   1:1 in order" claim (`INV6`) is proven by a net-zero mutation: reverse/drop the accumulator and confirm a test
   **kills** it (`ewr.1.1`: reversing produced `[-2, nil, "OK"]` vs `["OK","alice",ttl]`, the cache-aside story
   died). Carried forward to `ewr.1.2`/`1.3` ([`./ewr.mars.md`](./ewr.mars.md) + [`./ewr.apollo.md`](./ewr.apollo.md),
   `L-4`).
4. **No-Lua rungs reduce the adversarial battery honestly.** The bus's Lua-specific probes (declared-keys grep,
   the `SCRIPT FLUSH` mutation kill-rate) are **N/A on a wire rung that adds no Lua** — declare them N/A rather
   than skip them silently, and run the battery that DOES apply (the order theorem + the frozen-floor proof + the
   module mutation kill-rate; `ewr.1.1`: kill-rate 5/5, `P-1`).

## The spec home + the file convention

- `specs/` holds the chapter triads `ewr.N.{md,stories.md,llms.md}`. Each chapter's **decomposition** — its
  `prompt` doc and its sub-rung quads — lives in a same-named folder **`specs/ewr.N/`** (e.g.
  [`../specs/ewr.1/`](../specs/ewr.1/)).
- The **run-ledgers** (`ewr-N-M.progress.md`) live in **`specs/progress/`** (e.g.
  [`../specs/progress/ewr-1-1.progress.md`](../specs/progress/ewr-1-1.progress.md)). A wire rung above the
  conformance boundary writes **no `registry.json`** (the ledger header records the absence).
- The **ruled design fork** is [`../design/ewr.design.md`](../design/ewr.design.md) (Arm A), beside the chapter
  spec, carrying the three-arm debate the Operator ruled.
- The **generated story catalog** is `docs/echo_mq/wire/stories/` — produced by `mix echo_mq.stories --match
  wire_pipe`; generated, NEVER hand-edited (it cannot drift from code).
- The **per-agent calibrations** are `program/ewr.{venus,mars,apollo}.md` (this folder).

## The live frontier (re-true at each rung close)

- **Movement I — `ewr.1.1` SHIPPED** (`Z-1`): `EchoWire.Pipe` (`echo/apps/echo_wire/lib/echo_wire/pipe.ex`) — the
  `%Pipe{conn, via, timeout, cmds}` accumulator; the curated six-family verb set + `command/2`;
  `exec`/`exec_txn`/`exec_noreply` over the `Connector.pipeline/3` family; conn-or-pool first-class (dispatch
  carried in `via`, `exec_txn`/`exec_noreply` Connector-only); the 9-scenario BDD story layer. Verified
  Director-independent on valkey `6390`.
- **NEXT — `ewr.1.2`** (PLANNED): the command vocabulary + the immutable command value — the rueidis `Completed`
  model (`internal/cmds/cmds.go:117`) ported as Elixir data, an immutable command carrying its parts plus
  bit-packed **advisory** flags (`cf`, `cmds.go:5-23`); the flags stay advisory in the upper layer until a
  retry/cluster-routing consumer gives them meaning (roadmap seam 4). It layers onto `ewr.1.1`'s accumulator and
  reconciles against the as-built `pipe.ex` floor.
- **THEN — `ewr.1.3`** (PLANNED): the two-tier error split — the rueidis `NonValkeyError()` vs `Error()`
  distinction (`message.go:149`/`:154`) as a result classifier over `pipeline/3`'s return, separating a transport
  failure (`{:error, term}`) from a server error carried in-band as `{:error_reply, _}` (`resp.ex:47`). It wraps
  `exec`'s return; the `{:error, :empty_pipeline}` this rung owns is its first typed member.
- **Movement II — `ewr.2.x`** (PROPOSED seam): CLIENT TRACKING / client-side caching — gated on a real caching
  consumer and a surfaced MAJOR fork for the frozen-connector boot-step.

---

Calibrations: [`./ewr.venus.md`](./ewr.venus.md) · [`./ewr.mars.md`](./ewr.mars.md) ·
[`./ewr.apollo.md`](./ewr.apollo.md) · Bus manual (the base this deltas):
[`../../program/emq.program.md`](../../program/emq.program.md) · Roadmap: [`../ewr.roadmap.md`](../ewr.roadmap.md)
· Founding-rung ledger: [`../specs/progress/ewr-1-1.progress.md`](../specs/progress/ewr-1-1.progress.md)
