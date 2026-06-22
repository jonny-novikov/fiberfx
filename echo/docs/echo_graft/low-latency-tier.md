# The low-latency write tier (eg.5)

Object-storage commits are high-latency by design. The write tier puts a bounded,
durable local-fsync **group-commit buffer** in front of the remote commit: it accepts
hot-path writes, fsyncs the open batch once to a local durable medium, and rolls the
whole batch up into one remote `volume_push` (the eg.2 conditional-write fence). One
fsync amortized over a batch gives low-latency durable writes with few syscalls; the
async rollup gives replication. A per-call durability **mode** lets each caller trade
the loss window for latency, explicitly — never a hidden default. This lives in the
`echo_graft_backend` crate; the overview is [`../echo_graft.md`](../echo_graft.md), the
wire that carries the mode is [`wire.md`](wire.md).

## The shaping core — `shaper::Shaper`

*When* a batch flushes is the shaping decision, kept pure and clock-injected so the
trigger is deterministic under test (criterion 3: no dependence on real time). It
holds no records and no clock — it answers "should the open batch flush now?" from
the batch's size and age. The clock is a parameter (`now_ms`), never
`SystemTime::now()`.

| Function | Purpose |
|---|---|
| `Shaper::new(min_size, timeout_ms)` | a policy that flushes at `min_size` records OR `timeout_ms` of age (`min_size` 0 clamps to 1) |
| `should_flush(len, first_ms, now_ms)` | `Some(FlushReason)` or `None` — the `min(size, age)` trigger |
| `min_size` / `timeout_ms` | the bounds, surfaced (the loss-window report reads them) |

The trigger is `min(size_reached, age_reached)`: size is checked first, so a batch
that is simultaneously full and aged reports `FlushReason::Size` (a stable tie-break),
but either alone fires. An empty batch never flushes. This mirrors the `echo_mq`
program's `BatchShaper.Core` (the emq.5.2 precedent), realized in Rust.

## The buffer — `buffer::WriteBuffer`

A bounded, durable, per-Volume group-commit buffer over its **own** Fjall
`Database` + a single `pending` keyspace (the ruled A-3: the buffer "rides the
engine's existing durable Fjall store" — realized as an own-`Database` because the
engine's store is byte-frozen and private; the same durable medium, inside the
`echo_graft_backend` boundary). An fsync is `Database::persist(SyncAll)`.

| Function | Purpose |
|---|---|
| `open` / `open_temporary` | open the buffer; on reopen the `pending` keyspace recovers as-is and `seq` resumes past the highest key |
| `accept(write, now_ms)` | append a durable record (page-size-validated), record the batch's first-accept clock; returns the open-batch length |
| `should_flush(vid, now_ms)` | the `Shaper`'s verdict for a Volume's open batch |
| `persist` | the explicit async-ack fsync of the `pending` medium (`SyncAll`) |
| `flush(rt, vid)` | fsync → replay the batch through the engine in accept order → ONE `volume_push` → durably remove the flushed records; returns the post-push remote head |
| `recover` | the open batch still in `pending`, grouped by Volume in accept order — exactly what a crash-before-push left unaccounted |
| `loss_window(vid)` | the declared, queryable async bound: open-batch size + the shaper's max size/age |

Records key on `{vid}\0{seq:020}` with a monotone per-buffer `seq`, so the byte-sort
order within a `{vid}` prefix **is** accept order — a flush replays in that order and
the engine commits in that order, so committed order equals accept order (criterion
5). The record codec is the buffer's own small length-prefixed framing; the vid lives
in the key, not the value.

## The two durability modes

The mode is a **host ack-timing signal** — it chooses *when* the ack returns relative
to the remote rollup; it does not change what the engine does to a page. The 1:1
dispatch always performs the local commit; the mode's guarantee is enforced by *which
buffer path the host drives*.

| Mode | Acks when | Loss window | Guarantee on ack |
|---|---|---|---|
| `:async` | the local fsync of the open batch (`persist`) | exactly the open (not-yet-pushed) batch | durable **locally**, not yet replicated |
| `:sync` | only after `flush`'s `volume_push` returns | none beyond the engine's own fence | durable **and replicated** before the ack |

`:sync` is the client-API default (`EchoStore.GraftBackend.commit/5`), and the order
of operations proves the guarantee: `flush` fsyncs `pending`, commits each record
locally, then runs the remote `volume_push`, then returns the **post-push** remote
head — so a `:sync` ack carries a real remote LSN that advanced past where it started
(the buffer's `sync_flush_acks_downstream_of_the_remote_push` test pins this). An
`:async` ack returns at `persist` speed, before any push (the
`async_accept_is_durable_locally_before_any_push` test pins that the remote head is
still 0 at the ack).

### The async loss window — precisely what is at risk

Between an `:async` ack and the eventual remote commit, the records at risk are
**exactly the open batch**: every accepted-but-not-yet-flushed record, bounded by the
shaper's `min_size` and `timeout_ms` (whichever the next flush trips first). Those
records are durable on the local fsync'd medium — a process crash after the async ack
but before the push leaves them in `pending`, and `recover` reads precisely that set
on restart; a recovery flush rolls them up idempotently (a re-flush re-commits the
same content; a stale base loses to OCC, not a double-apply). Every
previously-**pushed** LSN is already durable in the engine and replicated to the
remote — outside the window (criterion 4). The bound is therefore declared and
queryable via `loss_window/1`, not an implicit default — the antidote to a hidden
loss window.

## The order of durability (S-4)

`flush` fsyncs `pending` **before** any remote work; the records are removed (and that
removal fsync'd) **after** the push acks. So:

- a crash **before** the push leaves the records in `pending` → recovered on restart;
- a crash **after** the push but **before** removal leaves them too → a recovery
  re-flush is idempotent on the engine, then they are removed.

At most the open batch is ever unaccounted; nothing pushed is ever lost.

## Admission + backpressure — `backpressure::Backpressure`

A per-Volume in-flight cap bounds a single hot Volume's admitted-but-unfinished
commands so a producer outrunning the engine cannot exhaust memory — **without**
stalling other Volumes (isolation is structural: each Volume's commands arrive on its
own `egraft:cmd:{vol}` lane).

| Function | Purpose |
|---|---|
| `Backpressure::new(max)` / `with_default` | a limiter with a per-Volume cap (default 64) |
| `admit(vol)` | `Some(Permit)` below the cap, `None` at it (the caller refuses with `unavailable`) |
| `in_flight(vol)` | the current admitted count for a Volume |

Over the cap, the policy is to **reject** (the proto `unavailable` kind), never buffer
without bound or block the dispatch thread; a rejected client retries. Admission
returns a `Permit` whose `Drop` releases the slot, so a slot is freed on every exit
path — success, error, or panic. The control lane is exempt by construction (it has no
`{vol}` to key a cap on, and its traffic is bounded — one handshake per session, one
open per Volume lifecycle). The cap is wired on the **live** request path — see
[`backend.md`](backend.md) for where `admit` is consulted (the criterion-8 "tested in
isolation ≠ wired in" close).
