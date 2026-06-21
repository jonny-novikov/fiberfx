# EchoMQ — Changelog (shipped deliverables)

The single backward source-of-record: what each rung delivered, in order. The forward plan is the
[roadmap](./emq.roadmap.md); the EchoMQ 3.0 stream tier is [`emq.streams.md`](./emq.streams.md).

**Provenance.** Each rung's authoritative ship record is its frozen ledger under
[`specs/progress/`](./specs/progress/) (the `Z-1 — SHIPPED` entry: verbs, gate tally, mutation
battery, commit). This changelog is the consolidated record; where a ledger recorded a commit sha it is cited (the
Operator commits the surface by pathspec out-of-band, so ship commits are bundled, not 1:1 with a
rung). The closed **Movement I** per-rung ledgers are being retired into this changelog; in-flight
ledgers (Movement II, the wire program) remain under [`specs/progress/`](./specs/progress/). The **conformance count is the program's
deliverable-closed metric** — each rung registers ≥1 new scenario, so it climbs monotonically and is
re-pinned in two tests.

## The conformance spine

```text
14  baseline           emq.0 · emq.1            the founding floor (scheduler + retry on the substrate)
24  +read plane        emq.2.1                  (18 as-built floor → 24)
32  +operator plane    emq.2.2
37  +watch plane       emq.2.3
43  +parity closer     emq.2.4                  ── Movement I parity floor complete
45  +flow open         emq.3.1
46  +child reads       emq.3.2
47  +cross-queue       emq.3.3
50  +failure/bulk      emq.3.4
52  +grandchildren     emq.3.5                  ══ MOVEMENT I CLOSED (52/52)
54  +fair-lanes ctl    emq.4.1                  ── Movement II opens · wire fence echomq:2.4.1
55  +group recovery    emq.4.2                  wire fence echomq:2.4.2 — FROZEN here on (labels climb, the wire defers the cutover)
57  +pool enqueue      ewr.2.5                  client floor (pool-fronted enqueue) · wire/keyspace/Lua unchanged
59  +native expiry     ewr.2.6                  native lock field on the job hash (HFE) · wire unchanged
59  =metronome (+0)    emq.4.3                  a BEAM process/lease property, not a wire trace — count byte-unchanged · label 2.4.3
61  +weighted rotation emq.4.4                  the groups capstone (weighted_proportion + starvation_drill) · label 2.4.4 · ══ emq.4 PARITY-COMPLETE
64  +batch claim       emq.5.1                  the batches spine (batch_claim · batch_claim_short · batch_partial_failure, +3) · label 2.5.0 · ══ emq.5 batches OPEN
```

The **`ewr.1.x` client-core** registers no conformance scenario — that count was emq-owned and
byte-stable across those rungs (`ewr.1.4` reflected `{:ok, 55}` and froze no number). The later
**`ewr.2.x` bench line** is distinct: it ships *into* `echo_mq` (pool-fronted enqueue · native
expiry, `[echo_mq]` commits) and DID register four scenarios (55→59), recorded in the spine above and
on its own ladder ([`ewr4.roadmap.md`](./wire/ewr4.roadmap.md)). The **two version planes** hold from
emq.4.2 on: the wire `@wire_version` is FROZEN at `echomq:2.4.2` (the connector constant, read on
connect), while the `mix.exs` **rung label** climbs (2.4.3 at emq.4.3, 2.4.4 at emq.4.4, 2.5.0 at emq.5.1 — the batches family opens) — an additive
rung defers the shared-`:6390` fence cutover by design.

## Foundation

| Rung | Date | Delivered | Commit |
|---|---|---|---|
| [emq.0](./specs/emq1/emq.0/emq.0.md) | 2026-06-13 | Movement 0 — the BCS migration: the `echo_wire` extraction, the pluggable store shadow, and the §5 test/coverage pass over `echo_mq`/`echo_store`/`echo_data`. The founding floor (baseline 14). | `a2d599c8` |
| [emq.1](./specs/emq1/emq.1/emq.1.md) | 2026-06-13 | Scheduler + retry — `Jobs.enqueue_at/5`·`enqueue_in/5` (`@schedule`), `Jobs.promote/3` (`@promote`), `EchoMQ.Repeat.register` + the `Pump` cadence; the retry/dead-letter host half. | `e0fa9b03` |

## Movement I · The Core — CLOSED (52/52)

The v1 surface rewritten state-of-the-art inside `echo_mq` under the v2 laws; nothing migrated.

| Rung | Date | Delivered | Δ | Risk | Commit |
|---|---|---|---|---|---|
| [emq.2.1](./specs/emq1/emq.2/emq.2.rungs/emq.2.1.md) | 2026-06-13 | The **read** plane — `EchoMQ.Metrics`: `get_counts`/`get_job`/`get_job_state`/`get_metrics`/`get_deduplication_job_id`, the `EMQRATE` rate-limit read-and-gate, `lane_depth(s)`. | 18→24 | NORMAL | `7d98ef86` |
| [emq.2.2](./specs/emq1/emq.2/emq.2.rungs/emq.2.2.md) | 2026-06-14 | The **operator** plane — `EchoMQ.Admin` (pause/resume/drain/obliterate) + 6 `Jobs` mutation verbs (update_data/update_progress/add_log/get_job_logs/remove_job/reprocess_job) + the queue-wide pause gate; new `EMQLOCK`/`EMQSTATE` classes. | 24→32 | NORMAL | `76fc947c` |
| [emq.2.3](./specs/emq1/emq.2/emq.2.rungs/emq.2.3.md) | 2026-06-14 | The **watch** plane — `EchoMQ.Events` (host pub/sub) · `EchoMQ.Meter` (telemetry tree) · `Jobs.extend_lock/5`·`extend_locks/4` (lease-extension, `EMQSTALE` fence) · `Locks` · `Stalled` · `Cancel`; 3 new Lua. | 32→37 | HIGH | `3c6461ff` |
| [emq.2.4](./specs/emq1/emq.2/emq.2.rungs/emq.2.4.md) | 2026-06-15 | The parity **closer** — the obliterate grouped-row fix, the C1 byte-identical renames, the 5 depth suites + the committed `emq_2_4_check.sh` harness. | 37→43 | HIGH | `3298e4bc` (+ `92a8f042` fix) |
| [emq.3.1](./specs/emq1/emq.3/emq.3.rungs/emq.3.1.md) | 2026-06-14 | The **flow family** opens — single-queue parent/child: `Flows.add/3` + `@enqueue_flow` (atomic parent+children on one slot); fan-in folded into `@complete` (idempotent, gated). | 43→45 | HIGH | `f9849efe` |
| [emq.3.2](./specs/emq1/emq.3/emq.3.rungs/emq.3.2.md) | 2026-06-15 | Child-result reads — `Flows.children_values/3` + `dependencies/3`; real-result completion threaded through `complete/5` (the `@complete` Lua byte-unchanged). | 45→46 | NORMAL | `0f14b1b2` |
| [emq.3.3](./specs/emq1/emq.3/emq.3.rungs/emq.3.3.md) | 2026-06-15 | Cross-queue flow — the outbox-on-child-slot (`emq:{q}:flow:outbox`) + a `Pump` sweep pass + the idempotent `@flow_deliver` on the parent slot (effectively-once via `HSETNX`). | 46→47 | HIGH | `7de4e90a` |
| [emq.3.4](./specs/emq1/emq.3/emq.3.rungs/emq.3.4.md) | 2026-06-15 | Flow failure-policy + bulk — `add_bulk/3` + `ignored_failures/3` + `policy_token/1`; the additive `@retry` dead-letter branch + `@flow_fail_deliver`; fail-parent / ignore-dependency policies. | 47→50 | HIGH | BUILD-GRADE |
| [emq.3.5](./specs/emq1/emq.3/emq.3.rungs/emq.3.5.md) | 2026-06-15 | Grandchildren / deep recursion — `add_tree/3` (`validate_tree/4` acyclic + depth-8 cap), recursive failure hook; **all 19 `Script.new/2` bodies byte-identical** (no new Lua). **Closes Movement I.** | 50→52 | NORMAL | BUILD-GRADE |

## Movement II · The Extension (the 2.x runway) — emq.4 groups family CLOSED (4.1–4.4) · emq.5 batches OPEN (5.1 the spine shipped)

| Rung | Date | Delivered | Δ | Risk | Commit · fence |
|---|---|---|---|---|---|
| [emq.4.1](./specs/emq2/emq.4/emq.4.rungs/emq.4.1.md) | 2026-06-18 | The fair-lanes operator **control plane** — `Lanes.reassign/4` + `@greassign` (atomic lane move + ring re-shape) and `Lanes.drain/3` + `@gdrain` (lane-scoped wipe, blast-radius contained); 5 lane scripts byte-frozen. | 52→54 | HIGH | `6bca0d6d` · `echomq:2.4.1` |
| [emq.4.2](./specs/emq2/emq.4/emq.4.rungs/emq.4.2.md) | 2026-06-18 | Group-aware **recovery** — `reap_group/4` + `@greap_group` (the group-scoped stalled-sweep); the first rung under the **climbing fence**. | 54→55 | NORMAL | [ledger](./specs/progress/emq-4-2.progress.md) · `echomq:2.4.2` |
| [emq.4.3](./specs/emq2/emq.4/emq.4.rungs/emq.4.3.md) | 2026-06-19 | The park-don't-poll **metronome** — `EchoMQ.Metronome` (a supervised process per queue owning the single `BLPOP emq:{q}:wake` block + an idle-consumer registry; fans readiness over BEAM messages, one byte-frozen `@gclaim` per idle consumer per wake; a pure `Metronome.Core`, owns no Valkey lease) + `EchoMQ.Consumer` rewired (register-idle → claim-once). **No conformance scenario** (a BEAM process/lease property, not a wire trace) — proven by the ≥100 determinism loop + a multi-consumer fairness harness. `@gclaim` / §6 grammar / `echo_wire` logic all unedited. | 59→59 | HIGH (Apollo) | `174e1d7f` · label `echomq:2.4.3` |
| [emq.4.4](./specs/emq2/emq.4/emq.4.rungs/emq.4.4.md) | 2026-06-19 | Weighted/deficit **rotation + the starvation drill** (Fork B → Arm 2, additive multi-pop) — `@gwclaim` serves a serviceable lane `K = min(weight, ZCARD, glimit headroom)` heads per ring rotation on one server-clock lease; weight rides `emq:{q}:gweight` (a new `g`-segment HASH, an existing shape, no grammar edit) via `weight/4`, served by `wclaim/3`; `@gclaim`/`claim/3` byte-frozen so equal round-robin coexists. **Closes the emq.4 groups family.** | 59→61 | NORMAL+ | `361fd663` · label `echomq:2.4.4` |
| [emq.5.1](./specs/emq2/emq.5/emq.5.rungs/emq.5.1.md) | 2026-06-20 | The **batch-claim spine** — `@bclaim` (a count-variant `ZPOPMIN emq:{q}:pending` loop ×N *inside* the script, the non-grouped generalization of `@gwclaim`: one `TIME`, one batch lease, per-member attempts; design §6.2, never a client `LMPOP`/`ZMPOP`) + `Jobs.claim_batch/4` (the manual-pull host API; an under-fill is a short batch, non-blocking; partial-failure isolation a tested property over the byte-frozen `@complete`/`@retry`). `@claim` + every shipped script byte-frozen. **Opens the emq.5 batches family.** | 61→64 | NORMAL | `bca36d0c` · label `echomq:2.5.0` |

> *Fence note:* the per-rung climbing-fence numbering (`2.4.1`/`2.4.2`) was ratified at **emq.4.2-D3**
> (superseding the earlier "fence frozen at `echomq:2.0.0`" framing); emq.4.1's own ledger predates the
> renumbering. From **emq.4.3 on the two planes split** (emq.4.3-D4): the wire `@wire_version` holds at
> `echomq:2.4.2` (the deferred cutover) while only the `mix.exs` **rung label** climbs (2.4.3 · 2.4.4) —
> see the conformance-spine note above. `echomq:3.0.0` is reserved for the Stream Tier
> ([`emq.streams.md`](./emq.streams.md)).

## The wire program · EchoWire client-core (`ewr.1.x`) — built

Ergonomic construction over the owned wire; above the conformance boundary (no scenario registered).

| Rung | Date | Delivered | Commit |
|---|---|---|---|
| [ewr.1.1](./wire/specs/ewr.1/ewr.1.1.md) | 2026-06-18 | `EchoWire.Pipe` — the threaded `\|>` pipeline (`%Pipe{conn,via,timeout,cmds}`, curated six-family verbs, the `command/2` escape hatch, `exec`/`exec_txn`/`exec_noreply`); conn-or-pool opaque dispatch. | [ledger](./wire/specs/progress/ewr-1-1.progress.md) |
| [ewr.1.2](./wire/specs/ewr.1/ewr.1.2.md) | 2026-06-18 | `EchoWire.Cmd` (fluent builder + `run/2`) + `EchoWire.Command` (immutable `%Command{parts,flags,slot}`, the `cf` bitfield + predicates + CRC16 slot); one additive `Pipe.command/2` head. | `7551f118` |
| [ewr.1.3](./wire/specs/ewr.1/ewr.1.3.md) | 2026-06-18 | `EchoWire.Result` — the two-tier error classifier (`classify/1`/`non_valkey_error/1`/`error/1`/`server_errors/1`), a pure reader over a frozen `exec/1`. | `7551f118` |
| [ewr.1.4](./wire/specs/ewr.1/ewr.1.4.md) | 2026-06-18 | Movement I **closer** — `echo_mq` adopts the wire-core (`Jobs.enqueue_many/3` rebuilt on `EchoWire.Pipe`) + the version-reflection rule (echo_wire ⟺ connector `@wire_version` ⟺ echo_mq = one number) and its guard test. | [spec](./wire/specs/ewr.1/ewr.1.4.md) |

---

Map: the forward [roadmap](./emq.roadmap.md) · the [progress dashboard](./emq.progress.md) · the
[design canon](./emq.design.md) (the 2.x line) · the [stream tier](./emq.streams.md) (EchoMQ 3.0) ·
the frozen per-rung ledgers under [`specs/progress/`](./specs/progress/).
