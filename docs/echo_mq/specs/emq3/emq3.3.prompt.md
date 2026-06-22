# EMQ3.3 · the build orchestration runbook — THE READER LAW: `EchoMQ.StreamConsumer`, the BEAM consumer group + the polyglot seam (S2 the readers, part 1)

> The authoritative run scope for shipping emq3.3 via `/echo-mq-ship` (Flat-L2, Director-supervised). The body ([`emq3.3.md`](emq3.3.md)) is the contract; the acceptance is [`emq3.3.stories.md`](emq3.3.stories.md); the Mars brief is [`emq3.3.llms.md`](emq3.3.llms.md). This runbook binds them to the pipeline stages + the gate ladder + the risk tier. **The forks are RULED (the design-phase convergence — D-2..D-7); nothing is left open here.** The dual-architect design-ahead (two opposite-optimizing lenses, [`../../kb/streams-tier/`](../../kb/streams-tier/)) converged on EVERY emq3.3 fork; the Director synthesized; the Operator ruled "ship emq3.3 now" (AskUserQuestion, 2026-06-22). There is NO open Operator decision for this rung — the one divergence (F3.4-A, the retention-trim cadence) is an emq3.4 decision emq3.3 forecloses nothing of.
>
> **Framing law (propagated).** Third person for any agent; no gendered pronouns for agents; no perceptual or interior-state verbs for agents or software; no first-person narration. Bind this same clause in any sub-brief.

## The tier in one paragraph

EchoMQ 3.0 — the Stream Tier ([`../../emq.streams.md`](../../emq.streams.md), the Operator-blessed ladder) builds **event streams on the certified wire under the v2 laws, no second protocol**, across six dependency-ordered rungs in three milestones: **S1 the writer** (emq3.1 the verb floor — SHIPPED `7b44dc97`; emq3.2 `EchoMQ.Stream` the writer law — SHIPPED, conf 75) → **S2 the readers** (emq3.3 the `EchoMQ.StreamConsumer` consumer group + the polyglot seam — THIS rung; emq3.4 retention as policy) → **S3 the memory** (emq3.5 the archive folded to the `EchoStore.Graft` engine; emq3.6 time-travel + hydration). The tier hard-gates on `emq.0` ONLY (met) and stands on the closed BCS substrate — no Stream rung depends on the parked emq.6/7/8 families. The version plane is additive-minor; the `echomq:3.0.0` MAJOR is a DEFERRED cutover ratification. emq3.3 rides the proven writer; emq3.4–3.6 each ride this proven reader (the handler shape emq3.3 freezes is the fold's and the hydration's handler too — the forward-compatibility thread).

## The rung in one paragraph

emq3.3 builds the **reader LAW** above the writer law: the `EchoMQ.StreamConsumer` module — a NEW supervised sibling (a `spawn_link` loop holding a PRIVATE connector lane, the `EchoMQ.Consumer`/`BatchConsumer` precedent) that reads a consumer group via `XREADGROUP GROUP … >` on its own blocking lane, at-least-once with idempotent handlers, crash → re-delivery. The blocking-read tension (does `XREADGROUP BLOCK` stall the single-owner socket?) is retired one tier down by the shipped law "blocking verbs get their own lane" (`consumer.ex:1-12`, Appendix B) — the `StreamConsumer` holds a private lane exactly as the job `Consumer` holds one for `BLPOP`. The group door is LAZY-ensure-on-start (`XGROUP CREATE … MKSTREAM`, swallow ONLY `BUSYGROUP`, the start position a DECLARED `:group_start` option, NO destructive verb). Recovery is TWO complementary mechanisms, both NAMED: drain-PEL-first (`XREADGROUP … 0`) recovers SELF on (re)start; the `XAUTOCLAIM` beat recovers dead PEERS. The handler is the EXACT mirror of the job `Consumer`'s `%{id, payload, attempts, group}` → `:ok | {:error, reason}`, with `attempts` carrying the `XPENDING` delivery-count (a NAMED invariant, not assumed). The polyglot seam is proven by a raw-connector parity test (the stored `id` field is the canonical receipt a stock client redeems). The order-theorem PEL exception is NAMED (a re-claimed entry returns out of real-time delivery order — the honest at-least-once cost). The conformance set grows +1 (`stream_group`, 75→76, a POSITIVE re-delivery proof). All under the v2 master invariant (braced keyspace · branded ids the writer minted · declared keys [vacuous — no new script] · the server clock where leases are touched [the PEL idle-time is server-side, no host clock] · inline `Script.new/2` [none added] · additive-minor conformance 75→76 · additive registration is a protocol minor, `@wire_version` frozen `echomq:2.4.2`).

## Mode

**Flat-L2, Director-supervised.** Venus (reconcile/author the triad — DONE; loaded `echo-mq-architect`) → Mars-1 (build to the brief — loads `echo-mq-implementor`) → Director solo review (an independent gate re-run on Valkey 6390 + the **deepened HIGH-risk verify**: the ≥100 determinism loop on the consumer suite + the full mutation battery + an adversarial probe of recovery-completeness, the PEL-exception, and the polyglot parity + a net-zero spot-check) → Mars-2 (remediate + harden) → **Apollo (MANDATORY — HIGH risk)** the post-build reconcile + the §11.2 adversarial verification (the order-theorem PEL-exception probe, the recovery-completeness probe, the polyglot-parity probe) → Director ship (one LAW-4 pathspec commit + the Stage-6 fold). **Apollo is a SHIP PRECONDITION** on this rung (a new process/lease surface) — NOT an optional fast-finisher.

## Risk tier — HIGH (a new supervised PROCESS + a blocking-read surface + a lease-like PEL recovery)

emq3.3 is the rung emq3.2 explicitly was NOT — it crosses three of the HIGH-risk triggers at once:

- **A NEW supervised process** — a `spawn_link` loop (the `EchoMQ.Consumer` shape), not a host fn. A process surface carries the same-ms branded-id mint hazard AND a process-timing race → the **≥100 determinism loop is MANDATORY** (one green run is not proof; a same-ms collision or a timing race flakes only across runs; the loop OWNS the machine).
- **A blocking-read surface** — `XREADGROUP … BLOCK` holds the socket; it rides the consumer's PRIVATE lane (the `consumer.ex:170` `BLPOP` precedent), so the single-owner socket of the rest of the system is never stalled. The read `stream_verbs_test.exs:21-23` explicitly DEFERRED to this rung.
- **A lease-like recovery** — the PEL drain + the `XAUTOCLAIM` reclaim recover un-acked work across a crash (a lease-like at-least-once recovery). The Director's verify exercises recovery-completeness (every entry delivered ≥1 under crash injection) + the mutation battery.

But the rung touches **NO frozen line** — ZERO `echo_wire` edit (the consumer rides the shipped connector `command/3` on its own lane; `@wire_version` frozen `echomq:2.4.2`) — adds **NO new script** (the group verbs are issued direct, not via Lua — `grep -c redis.call` on the `lib/` diff = 0; every shipped `Script.new/2` byte-identical), performs **NO destructive at-rest op** (NO `group_destroy`/`XGROUP DESTROY` — the destructive surface stays UNFROZEN for the retention/archive family, the emq.4.1 `drain/3` precedent), and adds **NO new wire class** (the verbs are issued direct, no script to issue a wire class — the closed registry `{EMQKIND, EMQSTALE}` stands).

**The gate is the ≥100 determinism loop on the consumer suite + the deepened HIGH-risk verify (recovery-completeness under crash injection + the mutation battery) + Apollo mandatory** — NOT the blast-radius mutation battery for a destructive op (there is none) and NOT a frozen-touch HIGH (no frozen line). The elevated properties are the PROCESS + the recovery-completeness + the at-least-once exactness, carried by the loop + the crash-injection integration tests + Apollo.

## Pipeline stages

### Stage 1 — Venus (DONE)

The triad is authored to the ruled convergence: [`emq3.3.md`](emq3.3.md) (the body, §1 the order-theorem PEL exception, §2 the recovery design) + [`emq3.3.stories.md`](emq3.3.stories.md) (US1–US8 + EMQ3.3-US-GATE + the coverage map) + [`emq3.3.llms.md`](emq3.3.llms.md) (the Mars brief — References · Requirements 1–9 · the topology DAG · AS-1..AS-6). The lag-1 reconcile re-probed every cited surface (`EchoMQ.Consumer` the `spawn_link`/`start_link`/`stop`/handler/`check_control`/private-lane shape; `EchoMQ.BatchConsumer` the sibling precedent; `EchoMQ.Stream` `append/4`/`read/3..6`/`stream_key/2`; `Stream.Id` `kind/0`/`evt?/1`/`xadd_id/1`; `Connector.command/3`/`pipeline/3`; `Keyspace.queue_key/2`; the emq3.1 group-verb round-trips + the deferred `XREADGROUP BLOCK`; the conformance count 75) + the engine facts (valkey.io `xreadgroup`/`xgroup`/`xautoclaim`/`xack`/`xpending`). The one reconcile FINDING surfaced (carried from emq3.2): `stream_data` is NOT in `echo_mq`'s `mix.exs` `deps/0` → the deep proofs are deterministic ExUnit integration tests + the ≥100 loop (no new dep), with the StreamData arm named (do NOT add silently).

### Stage 2 — Mars-1 (build to the brief)

Build to [`emq3.3.llms.md`](emq3.3.llms.md), the topology DAG order: (1) the consumer skeleton (`child_spec`/`start_link`/`stop`, trap-exits + `check_control`, the `:conn`/`:connector` lane) → (2) the lazy-ensure group door (`XGROUP CREATE … MKSTREAM`, `BUSYGROUP`-only swallow, the declared `:group_start` raise, NO destructive verb) → (3) the loop (drain-PEL-first → `>` BLOCK on the private lane → `XAUTOCLAIM` reclaim on the beat → settle via the handler verdict → the raise→survive discipline) → (4) the `:valkey` consumer proof (`test/stream_consumer_test.exs` — group drain, crash/PEL recovery, `XAUTOCLAIM` reclaim, the `attempts`↔delivery-count, the polyglot parity, the order-theorem PEL exception) → (5) the `stream_group` conformance scenario + the count re-pin (75→76) → (6) the label `2.6.2`. Cite the spec line for every public call; invent nothing (the precedent is `EchoMQ.Consumer`/`BatchConsumer`; the writer is `EchoMQ.Stream`; the engine is cited valkey.io). NO new Lua (the group verbs are issued direct). NO `echo_wire` edit. NO `keyspace.ex` edit (no new application subkey — the group is server-side stream state). NO `EchoStore.Graft` touch (the COEXIST law — the archive fold is emq3.5). Run the gate ladder + the ≥100 loop before reporting.

### Stage 3 — Director solo review (DEEPENED — HIGH risk)

An independent gate re-run on Valkey 6390 + the **deepened HIGH-risk verify**: (a) the **≥100 determinism loop** on the consumer suite (a process + a same-ms mint hazard); (b) **recovery-completeness under crash injection** (does every entry get delivered ≥1 under a handler-raise / a process-kill at deterministic points? does the PEL-drain recover the consumer's OWN backlog FIRST? does the `XAUTOCLAIM` beat recover a dead PEER?); (c) **the full mutation battery** (does swapping `>` for `0`, or dropping the PEL-drain, or acking on `{:error, _}`, fail a test? does dropping the `BUSYGROUP`-only-swallow let a `WRONGTYPE` pass silently?); (d) **the PEL-exception probe** (a re-claimed entry IS delivered out of mint order — the body's named exception is real, not prose); (e) **the polyglot-parity probe** (a raw-connector read recovers the EXACT branded receipt; a raw `XACK` settles the same group state); (f) **a net-zero spot-check** (the prior 75 conformance scenarios byte-unchanged, git-verified; `echo_wire` diff empty; `grep -c redis.call` on the `lib/` diff = 0; `keyspace.ex` diff empty). Findings → Mars-2.

### Stage 4 — Mars-2 (remediate + harden)

Address the Director's findings; re-run the full gate ladder + the ≥100 loop. (If the Director found zero defects, Mars-2 collapses — the emq.5.1 precedent.)

### Stage 5 — Apollo (MANDATORY — HIGH risk)

The post-build reconcile (does the as-built `EchoMQ.StreamConsumer` satisfy the body's promises? are all cited surfaces synced?) + the §11.2 adversarial verification applied to the consumer: the order-theorem PEL-exception probe (is the re-claim re-ordering real and named?), the recovery-completeness probe (is every entry delivered ≥1 under crash, both mechanisms?), the polyglot-parity probe (is the stored `id` field the canonical receipt across runtimes?). Apollo syncs the body to what shipped (the forks were RULED pre-build, so the body is already on the convergence; the sync trues any arity/return-shape drift) and mentors the architect/implementor skills from the consolidated findings. **Apollo is a SHIP PRECONDITION** on this HIGH-risk rung.

### Stage 6 — Director ship

One LAW-4 pathspec commit (`git commit -F <msg> -- <the emq3.3 paths>`; never `git add -A`; re-verify `git diff --cached --name-only` is purely the rung — the Operator commits out-of-band, so exclude any `AM`-status foreign work). The Stage-6 fold updates the rollup (the Stream Tier row, the conformance count 76, the label `echomq:2.6.2`, emq3.3 SHIPPED → emq3.4 next). Re-pin the conformance count in both pinning tests as part of the rung diff.

## The gate ladder (run from inside `echo/apps/echo_mq`, before reporting)

```bash
cd /Users/jonny/dev/jonnify/echo/apps/echo_mq
asdf current erlang                                   # re-probe the toolchain (do not hardcode)
redis-cli -p 6390 ping                                # → PONG (Valkey on 6390, not the default 6379)
TMPDIR=/tmp mix compile --warnings-as-errors          # the EchoMQ.StreamConsumer — clean
TMPDIR=/tmp mix test --include valkey                 # the :valkey consumer suite (group drain · crash/PEL recovery · XAUTOCLAIM reclaim · the attempts↔delivery-count · the polyglot parity · the order-theorem PEL exception)
# Conformance: EchoMQ.Conformance.run/2 → {:ok, 76} (76 lines printed on the truth row)
for i in $(seq 1 100); do TMPDIR=/tmp mix test --include valkey || break; done   # the ≥100 determinism loop — MANDATORY (a NEW supervised PROCESS + a same-ms mint hazard)
# byte-freeze: git diff echo/apps/echo_wire/ EMPTY · grep -c redis.call on the lib/ diff = 0 · git diff keyspace.ex EMPTY · {emq}:version = echomq:2.4.2 · mix.exs = 2.6.2
# no destructive verb: grep -rE "XGROUP.*DESTROY|group_destroy" lib/ == 0
```

- **`TMPDIR=/tmp` for ALL `mix`** — the harness tmp overlay hits ENOSPC and surfaces as spurious mid-suite I/O failures unrelated to any logic error.
- **The ≥100 determinism loop is MANDATORY** (NOT a multi-seed sweep) — emq3.3 builds a NEW SUPERVISED PROCESS (a `spawn_link` loop + a private blocking lane + a lease-like PEL recovery); both a same-millisecond mint collision and a process-timing race flake only across runs. The loop must OWN the machine (no concurrent liveness server, no sibling heavy I/O — a load-gated pre-existing test forges a failure the rung did not cause).
- **The conformance run** prints 76 lines and returns `{:ok, 76}` on the truth row (Valkey on 6390); the prior 75 are byte-unchanged (git-verified); both pinning tests re-pinned (`conformance_run_test.exs:65` `{:ok, 76}` + `conformance_scenarios_test.exs:43` `@run_order` gains `stream_group`).
- **Honest-row reporting** — the gate claims are against Valkey on 6390; a host without Valkey runs the probes elsewhere and reports them as that row, never the truth row.

## The boundary (load-bearing)

- **Edit ONLY `echo/apps/echo_mq`** — the NEW `lib/echo_mq/stream_consumer.ex` + the NEW `test/stream_consumer_test.exs` + `conformance.ex` + the two pinning tests + `mix.exs`. NO third app.
- **`echo_wire` is UNTOUCHED** (the consumer rides the shipped connector `command/3` on a private lane). NO new/edited Lua (the group verbs are issued direct). `keyspace.ex` unedited (the group state is server-side stream state on the `{q}` slot — no new application subkey). `consumer.ex`/`batch_consumer.ex`/`stream.ex`/`stream/id.ex` are PRECEDENTS read, not edited.
- **`echo_store` (the `EchoStore.Graft` engine) is UNTOUCHED** — the COEXIST law; the archive fold is emq3.5. emq3.3 freezes the handler shape the fold rides, but folds nothing.
- **`apps/echomq` (the frozen v1 reference) untouched.** `mix.lock` excluded (no dep moved — the deep proofs are deterministic ExUnit integration tests + the ≥100 loop; the StreamData arm is the one named exception, an Operator-ruled one-line `deps/0` add).
- **Agents run NO git** — the Director commits once at the close, by pathspec.

## Definition of done (the rung is shippable when)

- The `EchoMQ.StreamConsumer` supervised sibling is built (the `spawn_link` loop, the private connector lane, `child_spec`/`start_link`/`stop/2`, trap-exits + settle-point control); it reads `XREADGROUP GROUP … >` with `BLOCK` on its own lane.
- The lazy-ensure group door host-ensures the group on start (`XGROUP CREATE … MKSTREAM`, `BUSYGROUP`-only swallow, a `WRONGTYPE` LOUD, the declared `:group_start` option raised-if-missing, NO destructive verb).
- Recovery is two complementary mechanisms, both NAMED: drain-PEL-first (`XREADGROUP … 0`) recovers SELF; the `XAUTOCLAIM` beat recovers dead PEERS; every entry delivered ≥1 under crash injection.
- The handler is the exact `%{id, payload, attempts, group}` → `:ok | {:error, reason}` mirror; `attempts` carries the `XPENDING` delivery-count (specced); `:ok` `XACK`s, `{:error, reason}`/raise leaves un-acked; the raise→survive discipline holds.
- The polyglot parity test proves the stored `id` field is the canonical receipt across runtimes; the order-theorem PEL exception is NAMED in the body and EXERCISED in a test (a re-claim delivered out of mint order).
- Byte-freeze holds (`echo_wire` diff empty; `grep -c redis.call` on the `lib/` diff = 0; every shipped `Script.new/2` byte-identical; `keyspace.ex` diff empty — no new application subkey; `@wire_version` `echomq:2.4.2`).
- The conformance count steps 75→76 (`stream_group` registered with its probe, a POSITIVE re-delivery proof; the prior 75 byte-unchanged; both pins re-pinned; `run/2 → {:ok, 76}`).
- The label reads `2.6.2`; the gate ladder + the ≥100 loop green on Valkey 6390; honest-row reporting.
- INV1–INV10 verified as runnable checks; the body [`emq3.3.md`](emq3.3.md) is authoritative (synced to the as-built post-build). **Apollo MANDATORY** (the post-build reconcile + the §11.2 adversarial verification before the Director ships).

## Map

The contract: [`emq3.3.md`](emq3.3.md) · the acceptance: [`emq3.3.stories.md`](emq3.3.stories.md) · the Mars brief: [`emq3.3.llms.md`](emq3.3.llms.md) · the rung ledger (the RULED forks): [`../progress/emq3-3.progress.md`](../progress/emq3-3.progress.md) · the design KB (the convergence): [`../../kb/streams-tier/streams.synthesis.md`](../../kb/streams-tier/streams.synthesis.md) + [`../../kb/streams-tier/streams.design.A-consumer-lens.md`](../../kb/streams-tier/streams.design.A-consumer-lens.md) + [`../../kb/streams-tier/streams.design.B-steward-lens.md`](../../kb/streams-tier/streams.design.B-steward-lens.md) · the prior rungs: [`emq3.1.md`](emq3.1.md) (the verb floor) + [`emq3.2.md`](emq3.2.md) (the writer law) · the tier: [`../../emq.streams.md`](../../emq.streams.md) · the design canon: [`../../emq.design.md`](../../emq.design.md) (§6 grammar · §10 seams · the closed wire-class registry) · the roadmap: [`../../emq.roadmap.md`](../../emq.roadmap.md) · the program law: `.claude/skills/echo-mq-program.md` · the as-built map: `.claude/skills/echo-mq-surface.md`.
