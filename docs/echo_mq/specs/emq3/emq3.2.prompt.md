# EMQ3.2 · the build orchestration runbook — THE WRITER LAW: `EchoMQ.Stream`, append == mint order (S1 the writer, part 2)

> The authoritative run scope for shipping emq3.2 via `/echo-mq-ship` (Flat-L2, Director-supervised). The body
> ([`emq3.2.md`](emq3.2.md)) is the contract; the acceptance is [`emq3.2.stories.md`](emq3.2.stories.md); the Mars
> brief is [`emq3.2.llms.md`](emq3.2.llms.md). This runbook binds them to the pipeline stages + the gate ladder +
> the risk tier. **The forks are RULED (the design-phase consensus — D-1..D-4 + ADR-3/ADR-4); nothing is left open
> here.** The design phase (dual-architect) is closed; the Operator ruled the id mapping (A1), the kind door (host
> raise, `EVT`), the count delta (+1, 74→75), the label (`2.6.1`), and the risk tier (NORMAL+).
>
> **Framing law (propagated).** Third person for any agent; no gendered pronouns for agents; no perceptual or
> interior-state verbs for agents or software; no first-person narration. Bind this same clause in any sub-brief.

## The tier in one paragraph

EchoMQ 3.0 — the Stream Tier ([`../../emq.streams.md`](../../emq.streams.md), the Operator-blessed ladder) builds
**event streams on the certified wire under the v2 laws, no second protocol**, across six dependency-ordered rungs
in three milestones: **S1 the writer** (emq3.1 the verb floor — SHIPPED `7b44dc97`; emq3.2 `EchoMQ.Stream` the
writer law, branded record ids, append == mint — THIS rung) → **S2 the readers** (emq3.3 consumer groups + the
polyglot seam; emq3.4 retention as policy) → **S3 the memory** (emq3.5 the archive folded to the `Graft` engine;
emq3.6 time-travel + hydration). The tier hard-gates on `emq.0` ONLY (met) and stands on the closed BCS substrate —
no Stream rung depends on the parked emq.6/7/8 families. The version plane is additive-minor; the `echomq:3.0.0`
MAJOR is a DEFERRED cutover ratification. emq3.2 rides the proven verb floor; emq3.3–3.6 each ride the proven
writer.

## The rung in one paragraph

emq3.2 builds the **writer LAW** above the verb floor: the `EchoMQ.Stream` module — per-key hash-tagged streams,
branded record ids appended in mint order, wrong-kind refused at the door. The crux is the **order theorem** (stream
order == id sort == mint order), reasoned to the ground (the body §1): the branded record id maps to an EXPLICIT
XADD id by field correspondence (D-1, A1) — `"#{Snowflake.unix_ms(snow)}-#{snow &&& 0x3FFFFF}"` (the real Unix-ms
field via `unix_ms`, the 22-bit `node|seq` tail as the seq field), with the 14-byte branded string stored as the
stream `id` field. The order theorem holds BY CONSTRUCTION (base62 byte order == int order within one NS; the
snowflake packs ms high / tail low-22 with no overlap), single-writer EVERY TIME (the `:atomics` CAS is strictly
monotone), and multi-writer surfaces `{:error, :nonmonotonic}` on XADD's `id≤top` rejection (NEVER swallowed — the
F-A liveness check). The kind door is a HOST-SIDE raise (one brand `EVT`, symmetric with `Keyspace.job_key/2`; no
new script, no new wire class — D-2). The append is `XADD` issued direct (NO new Lua — a no-new-script rung). The
readers (consumer groups, `XREADGROUP`/`XACK`/`XAUTOCLAIM`) are emq3.3, NOT this rung — emq3.2's `read/3..6` is the
minimal un-grouped read-back that GATES the order theorem. All under the v2 master invariant (braced keyspace ·
branded ids gated at the writer's door · declared keys [vacuous — no new script] · the server clock where leases are
touched [none here] · inline `Script.new/2` [none added] · additive-minor conformance 74→75 · additive registration
is a protocol minor, `@wire_version` frozen `echomq:2.4.2`).

## Mode

**Flat-L2, Director-supervised.** Venus (reconcile/author the triad — DONE; loaded `echo-mq-architect`) → Mars-1
(build to the brief — loads `echo-mq-implementor`) → Director solo review (an independent gate re-run on Valkey 6390
+ an adversarial probe of the order theorem + a net-zero mutation spot-check) → Mars-2 (remediate + harden) →
Director ship (one LAW-4 pathspec commit). **Apollo** (`echo-mq-evaluator`) is an **OPTIONAL fast-finisher** on the
ruled NORMAL+ arm (closure + stories) — NOT a ship precondition (emq3.2 is not a new process/lease surface, not a
destructive at-rest op, not a frozen-line touch). **The Operator MAY upgrade Apollo to mandatory** given ADR-1's
order-theorem correctness is the rung's whole risk — a reasonable call; if upgraded, Apollo runs the post-build
reconcile + the adversarial order-theorem verification before the Director ships.

## Risk tier — NORMAL+ (a MINT surface)

emq3.2 MINTS branded record ids (the append's whole point), so the determinism posture is the **≥100 determinism
loop, MANDATORY** (the same-millisecond branded-id mint hazard — unlike emq3.1, which minted nothing → a multi-seed
sweep). But the rung:

- touches **NO frozen line** — ZERO `echo_wire` edit (the writer rides the shipped connector `command/3`/
  `pipeline/3`, inheriting emq3.1's FORK-3.1-A ground); `@wire_version` frozen `echomq:2.4.2`.
- adds **NO new script** — the append is `XADD` issued direct, not via Lua (`grep -c redis.call` on the `lib/` diff
  = 0; every shipped `Script.new/2` byte-identical). NO declared-keys / byte-freeze-Lua exposure (vacuous).
- performs **NO destructive at-rest op** — append-only (retention is emq3.4). NO blast-radius mutation battery.
- adds **NO new wire class** — the kind door is a host raise (the closed registry `{EMQKIND, EMQSTALE}`
  byte-unchanged). NO wire break.

**The gate is the order-theorem property test + the ≥100 loop** — NOT the blast-radius mutation battery (no
destructive op) and NOT the frozen-touch HIGH (no frozen line). The single elevated property is the **id mint** (the
order theorem must be PROVEN, not asserted), carried by the property test + the loop.

## Pipeline stages

### Stage 1 — Venus (DONE)

The triad is authored to the ruled consensus: [`emq3.2.md`](emq3.2.md) (the body, §1 the order-theorem proof) +
[`emq3.2.stories.md`](emq3.2.stories.md) (US1–US6 + EMQ3.2-US-GATE + the coverage map) + [`emq3.2.llms.md`](emq3.2.llms.md)
(the Mars brief — References · Requirements 1–8 · the topology DAG · AS-1..AS-6). The lag-1 reconcile re-probed every
cited surface (`Snowflake.unix_ms`/`next`/`min_for`, `BrandedId.decode`/`valid?`/`namespace`, `Base62` order,
`Keyspace.queue_key`/`job_key`/`slot`, the emq3.1 verb floor, the conformance count 74) + the engine facts
(valkey.io/commands/xadd + streams-intro). The one reconcile FINDING surfaced: `stream_data` is NOT in echo_mq's
`mix.exs` `deps/0` → the order-theorem property test is specced as a deterministic ExUnit enumeration (no new dep),
with the StreamData arm named (a one-line `deps/0` add the Operator may accept — do NOT add silently).

### Stage 2 — Mars-1 (build to the brief)

Build to [`emq3.2.llms.md`](emq3.2.llms.md), the topology DAG order: (1) the pure `EchoMQ.Stream.Id` core (the A1
mapping, doctested) → (2) the pure-core proof (`test/stream_id_test.exs` — doctests + the order-theorem property
test, the deterministic enumeration over many sequences incl. forced same-ms) → (3) the `EchoMQ.Stream` writer
(`append/4` + the host-raise kind door + the `:nonmonotonic` mapping + the branded receipt; `read/3..6`; optional
`append_batch/4`) → (4) the `:valkey` writer proof (`test/stream_test.exs`) → (5) the `stream_append` conformance
scenario + the count re-pin (74→75) → (6) the label `2.6.1`. Cite the spec line for every public call; invent
nothing (the substrate is `Snowflake`/`BrandedId`/`Base62`/`Keyspace`; the engine is cited valkey.io). NO new Lua
(the append is `XADD` direct). NO `echo_wire` edit. Run the gate ladder before reporting.

### Stage 3 — Director solo review

An independent gate re-run on Valkey 6390 + an **adversarial probe of the order theorem** (does the read-back order
equal the mint order over a same-ms burst? does a non-order-preserving mapping fail the property? does the kind raise
leave NO key written? does the `:nonmonotonic` surface NOT swallow?) + a net-zero mutation spot-check (the prior 74
conformance scenarios byte-unchanged, git-verified; `echo_wire` diff empty; `grep -c redis.call` on the `lib/` diff
= 0). Findings → Mars-2.

### Stage 4 — Mars-2 (remediate + harden)

Address the Director's findings; re-run the full gate ladder + the ≥100 loop. (If the Director found zero defects,
Mars-2 collapses — the emq.5.1 precedent.)

### Stage 5 — Director ship

One LAW-4 pathspec commit (`git commit -F <msg> -- <the emq3.2 paths>`; never `git add -A`; re-verify `git diff
--cached --name-only` is purely the rung — the Operator commits out-of-band, so exclude any `AM`-status foreign
work). The post-build reconcile syncs the body to the as-built surface (the forks were RULED pre-build, so the body
is already on the consensus; the sync trues any arity/return-shape drift). Re-pin the conformance count in both
pinning tests as part of the rung diff.

## The gate ladder (run from inside `echo/apps/echo_mq`, before reporting)

```bash
cd /Users/jonny/dev/jonnify/echo/apps/echo_mq
asdf current erlang                                   # re-probe the toolchain (do not hardcode)
redis-cli -p 6390 ping                                # → PONG (Valkey on 6390, not the default 6379)
TMPDIR=/tmp mix compile --warnings-as-errors          # the pure Stream.Id + the Stream writer — clean
TMPDIR=/tmp mix test --include valkey                 # the :valkey stream suite + the pure-core suite (doctests + the property test)
# the order-theorem property test is green (a deterministic ExUnit enumeration over many sequences incl. forced same-ms)
# Conformance: EchoMQ.Conformance.run/2 → {:ok, 75} (75 lines printed on the truth row)
for i in $(seq 1 100); do TMPDIR=/tmp mix test --include valkey || break; done   # the ≥100 determinism loop — MANDATORY (the rung MINTS branded ids)
# byte-freeze: git diff echo/apps/echo_wire/ EMPTY · grep -c redis.call on the lib/ diff = 0 · git diff keyspace.ex EMPTY · {emq}:version = echomq:2.4.2 · mix.exs:7 = 2.6.1
```

- **`TMPDIR=/tmp` for ALL `mix`** — the harness tmp overlay hits ENOSPC and surfaces as spurious mid-suite I/O
  failures unrelated to any logic error.
- **The ≥100 determinism loop is MANDATORY** (NOT a multi-seed sweep) — emq3.2 MINTS branded record ids in the
  append path; a same-millisecond mint collision flakes only across runs. The loop must OWN the machine (no
  concurrent liveness server, no sibling heavy I/O — a load-gated pre-existing test forges a failure the rung did
  not cause).
- **The conformance run** prints 75 lines and returns `{:ok, 75}` on the truth row (Valkey on 6390); the prior 74
  are byte-unchanged (git-verified); both pinning tests re-pinned (`conformance_run_test.exs:61` `{:ok, 75}` +
  `conformance_scenarios_test.exs:38` `@run_order`).
- **Honest-row reporting** — the gate claims are against Valkey on 6390; a host without Valkey runs the probes
  elsewhere and reports them as that row, never the truth row.

## The boundary (load-bearing)

- **Edit ONLY `echo/apps/echo_mq`** — the NEW `lib/echo_mq/stream.ex` + `lib/echo_mq/stream/id.ex` + the two NEW
  tests + `conformance.ex` + the two pinning tests + `mix.exs`. NO third app.
- **`echo_wire` is UNTOUCHED** (the writer rides the shipped connector). NO new/edited Lua. `keyspace.ex` unedited.
  `apps/echomq` (the frozen v1 reference) untouched.
- **`mix.lock` excluded** UNLESS the Operator accepts the StreamData property arm (the one named exception — a
  one-line `deps/0` add `{:stream_data, "~> 1.3", only: :test}`). The default (a deterministic ExUnit enumeration)
  needs NO dep edge.
- **Agents run NO git** — the Director commits once at the close, by pathspec.

## Definition of done (the rung is shippable when)

- The pure `EchoMQ.Stream.Id` core (the A1 mapping) + the `EchoMQ.Stream` writer (`append/4`, `read/3..6`, optional
  `append_batch/4`) are built; the order theorem is proven THREE ways (the in-scenario read-back + the property test
  + the ≥100 loop).
- The kind door host-raises wrong-kind before any wire (no key written); the `:nonmonotonic` liveness surfaces the
  `id≤top` rejection (never swallowed).
- Byte-freeze holds (`echo_wire` diff empty; `grep -c redis.call` on the `lib/` diff = 0; every shipped
  `Script.new/2` byte-identical; `keyspace.ex` diff empty; `@wire_version` `echomq:2.4.2`).
- The conformance count steps 74→75 (`stream_append` registered with its probe; the prior 74 byte-unchanged; both
  pins re-pinned; `run/2 → {:ok, 75}`).
- The label reads `2.6.1`; the gate ladder + the ≥100 loop green on Valkey 6390; honest-row reporting.
- INV1–INV8 verified as runnable checks; the body [`emq3.2.md`](emq3.2.md) is authoritative (synced to the as-built
  post-build). Apollo OPTIONAL (the Operator may upgrade it).

## Map

The contract: [`emq3.2.md`](emq3.2.md) · the acceptance: [`emq3.2.stories.md`](emq3.2.stories.md) · the Mars brief:
[`emq3.2.llms.md`](emq3.2.llms.md) · the prior rung (the verb floor): [`emq3.1.md`](emq3.1.md) · the tier:
[`../../emq.streams.md`](../../emq.streams.md) · the design canon: [`../../emq.design.md`](../../emq.design.md) (§0/§2
the order theorem · §6 grammar · §12 engine ADRs) · the roadmap: [`../../emq.roadmap.md`](../../emq.roadmap.md) · the
program law: `.claude/skills/echo-mq-program.md` · the as-built map: `.claude/skills/echo-mq-surface.md`.
