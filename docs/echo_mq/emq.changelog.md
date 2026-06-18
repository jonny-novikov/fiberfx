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
54  +fair-lanes ctl    emq.4.1                  ── Movement II opens · fence echomq:2.4.1
55  +group recovery    emq.4.2                  fence echomq:2.4.2  (live)
```

The wire program (`ewr.1.x`) registers no conformance scenario — the count is emq-owned and
byte-stable across the wire rungs; `ewr.1.4` reflects `{:ok, 55}` and freezes no number.

## Foundation

| Rung | Date | Delivered | Commit |
|---|---|---|---|
| [emq.0](./specs/emq.0/emq.0.md) | 2026-06-13 | Movement 0 — the BCS migration: the `echo_wire` extraction, the pluggable store shadow, and the §5 test/coverage pass over `echo_mq`/`echo_store`/`echo_data`. The founding floor (baseline 14). | `a2d599c8` |
| [emq.1](./specs/emq.1/emq.1.md) | 2026-06-13 | Scheduler + retry — `Jobs.enqueue_at/5`·`enqueue_in/5` (`@schedule`), `Jobs.promote/3` (`@promote`), `EchoMQ.Repeat.register` + the `Pump` cadence; the retry/dead-letter host half. | `e0fa9b03` |

## Movement I · The Core — CLOSED (52/52)

The v1 surface rewritten state-of-the-art inside `echo_mq` under the v2 laws; nothing migrated.

| Rung | Date | Delivered | Δ | Risk | Commit |
|---|---|---|---|---|---|
| [emq.2.1](./specs/emq.2/emq.2.rungs/emq.2.1.md) | 2026-06-13 | The **read** plane — `EchoMQ.Metrics`: `get_counts`/`get_job`/`get_job_state`/`get_metrics`/`get_deduplication_job_id`, the `EMQRATE` rate-limit read-and-gate, `lane_depth(s)`. | 18→24 | NORMAL | `7d98ef86` |
| [emq.2.2](./specs/emq.2/emq.2.rungs/emq.2.2.md) | 2026-06-14 | The **operator** plane — `EchoMQ.Admin` (pause/resume/drain/obliterate) + 6 `Jobs` mutation verbs (update_data/update_progress/add_log/get_job_logs/remove_job/reprocess_job) + the queue-wide pause gate; new `EMQLOCK`/`EMQSTATE` classes. | 24→32 | NORMAL | `76fc947c` |
| [emq.2.3](./specs/emq.2/emq.2.rungs/emq.2.3.md) | 2026-06-14 | The **watch** plane — `EchoMQ.Events` (host pub/sub) · `EchoMQ.Meter` (telemetry tree) · `Jobs.extend_lock/5`·`extend_locks/4` (lease-extension, `EMQSTALE` fence) · `Locks` · `Stalled` · `Cancel`; 3 new Lua. | 32→37 | HIGH | `3c6461ff` |
| [emq.2.4](./specs/emq.2/emq.2.rungs/emq.2.4.md) | 2026-06-15 | The parity **closer** — the obliterate grouped-row fix, the C1 byte-identical renames, the 5 depth suites + the committed `emq_2_4_check.sh` harness. | 37→43 | HIGH | `3298e4bc` (+ `92a8f042` fix) |
| [emq.3.1](./specs/emq.3/emq.3.rungs/emq.3.1.md) | 2026-06-14 | The **flow family** opens — single-queue parent/child: `Flows.add/3` + `@enqueue_flow` (atomic parent+children on one slot); fan-in folded into `@complete` (idempotent, gated). | 43→45 | HIGH | `f9849efe` |
| [emq.3.2](./specs/emq.3/emq.3.rungs/emq.3.2.md) | 2026-06-15 | Child-result reads — `Flows.children_values/3` + `dependencies/3`; real-result completion threaded through `complete/5` (the `@complete` Lua byte-unchanged). | 45→46 | NORMAL | `0f14b1b2` |
| [emq.3.3](./specs/emq.3/emq.3.rungs/emq.3.3.md) | 2026-06-15 | Cross-queue flow — the outbox-on-child-slot (`emq:{q}:flow:outbox`) + a `Pump` sweep pass + the idempotent `@flow_deliver` on the parent slot (effectively-once via `HSETNX`). | 46→47 | HIGH | `7de4e90a` |
| [emq.3.4](./specs/emq.3/emq.3.rungs/emq.3.4.md) | 2026-06-15 | Flow failure-policy + bulk — `add_bulk/3` + `ignored_failures/3` + `policy_token/1`; the additive `@retry` dead-letter branch + `@flow_fail_deliver`; fail-parent / ignore-dependency policies. | 47→50 | HIGH | BUILD-GRADE |
| [emq.3.5](./specs/emq.3/emq.3.rungs/emq.3.5.md) | 2026-06-15 | Grandchildren / deep recursion — `add_tree/3` (`validate_tree/4` acyclic + depth-8 cap), recursive failure hook; **all 19 `Script.new/2` bodies byte-identical** (no new Lua). **Closes Movement I.** | 50→52 | NORMAL | BUILD-GRADE |

## Movement II · The Extension (the 2.x runway) — building

| Rung | Date | Delivered | Δ | Risk | Commit · fence |
|---|---|---|---|---|---|
| [emq.4.1](./specs/emq.4/emq.4.rungs/emq.4.1.md) | 2026-06-18 | The fair-lanes operator **control plane** — `Lanes.reassign/4` + `@greassign` (atomic lane move + ring re-shape) and `Lanes.drain/3` + `@gdrain` (lane-scoped wipe, blast-radius contained); 5 lane scripts byte-frozen. | 52→54 | HIGH | `6bca0d6d` · `echomq:2.4.1` |
| [emq.4.2](./specs/emq.4/emq.4.rungs/emq.4.2.md) | 2026-06-18 | Group-aware **recovery** — `reap_group/4` + `@greap_group` (the group-scoped stalled-sweep); the first rung under the **climbing fence**. | 54→55 | NORMAL | [ledger](./specs/progress/emq-4-2.progress.md) · `echomq:2.4.2` |

> *Fence note:* the per-rung climbing-fence numbering (`2.4.1`/`2.4.2`) was ratified at **emq.4.2-D3**
> (superseding the earlier "fence frozen at `echomq:2.0.0`" framing); emq.4.1's own ledger predates the
> renumbering. The version climbs the 2.x line through Movement II; `echomq:3.0.0` is reserved for the
> Stream Tier ([`emq.streams.md`](./emq.streams.md)).

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
