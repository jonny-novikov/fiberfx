# Never lose a job to a crash: list-based reliable queues

> R8.03.2 · Pinterest: task queues & partitioning — dive 2 · route `/redis-patterns/production-operations/pinterest-task-queue/list-based-reliable-queues`

A naive queue loses work to a crash. A worker pops a job off the work list, the process dies before the job
finishes, and the job is gone — it was removed from the list the instant it was popped, and the result was
never written. The list-based reliable-queue pattern closes that gap: the consumer **atomically moves** the
job onto a second list as it claims it, removes it only after a positive acknowledgement, and a recovery
worker re-queues anything left stranded by a crash. No job is lost between claim and ack.

Grounding: the Redis docs for `LMOVE` and `RPOPLPUSH` (the pattern and its processing-list recovery note),
Pinterest's PinLater (explicit acks + automatic retry at six million jobs per minute), and the real
`echo/apps/echo_mq` bus — which reaches the same guarantee with a **server-clock lease** plus an `attempts`
counter rather than a processing list.

This dive owns the **claim → ack → recovery** story. Functional partitioning (placement decided by identity)
is the previous dive; scaling out by making "add a shard" trivial is the next. This page references them, it
does not repeat them.

## §1 · The gap a naive pop leaves

A queue built on a single list is one command from losing work. The producer pushes a job with `LPUSH`; the
consumer takes one with `RPOP`. The job leaves the list the moment `RPOP` returns it. If the worker then
crashes — a deploy, an out-of-memory kill, a hardware fault — before the job's effect is durable, the job is
gone. Nothing on the server records that it was ever in flight.

The fix is to make claiming a job a move, not a removal. The job does not leave the system when a worker
takes it; it moves to a **second list** — a processing list — where it stays visible until the worker
confirms the job is done. A crash now leaves a trace: the job sits on the processing list, and a recovery
sweep can find it and put it back.

The whole pattern is three beats:

- **Claim** — atomically move one job from the work list to the processing list.
- **Ack** — when the work succeeds, remove that job from the processing list.
- **Recover** — a separate worker re-queues any job that has sat on the processing list too long.

## §2 · The atomic move on claim

The claim is one server-side operation, so there is no window in which the job belongs to neither list. The
original Redis primitive for this is `RPOPLPUSH`: it pops the tail of the source list and pushes it onto the
head of the destination list, returning the element, all in one step.

```redis
# the original primitive — pop the work tail, push it onto processing, atomically
RPOPLPUSH queue:work queue:processing
```

For a worker that should wait when the queue is empty rather than spin, the blocking form `BRPOPLPUSH`
blocks until an element arrives or a timeout elapses:

```redis
# block up to 5 seconds for a job, then move it onto processing
BRPOPLPUSH queue:work queue:processing 5
```

`RPOPLPUSH` and `BRPOPLPUSH` were **deprecated in Redis 6.2.0** in favour of `LMOVE` and `BLMOVE`, which take
an explicit direction on each end (`LEFT` or `RIGHT`) instead of fixing the ends. `LMOVE queue:work
queue:processing RIGHT LEFT` is the modern spelling of `RPOPLPUSH` — pop the right (tail) of the work list,
push to the left (head) of processing. Teach `LMOVE`/`BLMOVE` as today's primitive; `RPOPLPUSH` is the
original.

```redis
# the modern primitive (Redis 6.2.0+) — explicit ends, same atomic move
LMOVE  queue:work queue:processing RIGHT LEFT      # claim a job
BLMOVE queue:work queue:processing RIGHT LEFT 5    # block up to 5s, then claim
```

After the move, the worker holds the job *and* the job is recorded as in-flight on the processing list. There
is no instant at which a crash could lose it.

## §3 · The ack and the recovery worker

A worker that finishes a job removes it from the processing list with `LREM`. `LREM` deletes matching
elements by value; with a count of `1` it removes the first occurrence of the job from the head:

```redis
# on a positive ack — remove the finished job from the processing list
LREM queue:processing 1 "<the job payload>"
```

That is the only path off the processing list under normal operation. If the worker never reaches the
`LREM` — it crashed mid-job — the job stays on the processing list. A separate **recovery worker** scans the
processing list, finds entries that have sat there longer than a job should take, and moves them back onto
the work list with another `LMOVE` (processing → work). The crashed job is re-queued and a healthy worker
claims it again.

The cost of the pattern is exactly-once-versus-at-least-once: a worker that does its work and then crashes
*before* the `LREM` will have its job re-queued and run a second time. Reliable-queue work is therefore
**at-least-once**; the job handler must be idempotent. That is the trade the pattern makes — it would rather
run a job twice than lose it.

## §4 · Pinterest's PinLater — the same guarantee at six million jobs per minute

Pinterest's asynchronous job system, **PinLater**, names the same contract at production scale. PinLater is a
Thrift service whose three core actions are **enqueue, dequeue, and ACK**. Its reliability mechanism, in its
own words, is *"explicit acks and automatically retries with configurable delay."* A worker replies with a
positive or negative ACK depending on whether execution succeeded, and a job that is not positively
acknowledged is retried after a configurable delay — the recovery worker, generalized into the service.

PinLater ran *"more than 500 job queues processing north of six million jobs per minute"* across more than
ten clusters on EC2. The explicit-ack contract is what let it run at that rate without silently dropping
work: a job is not done until a worker says it is done.

PinLater offered two storage backends — MySQL and Redis — and used Redis as the high-throughput one. The
ack-and-retry guarantee is independent of the backend: the *list-in-RAM* form is fast, the durable form
trades some speed for a record that survives a restart. That tension is the next dive's punch line.

## §5 · The bus reaches the same goal with a lease

The `echo/apps/echo_mq` bus solves the identical problem — no lost job, bounded retries — but it does **not**
use a processing list. It uses a **server-clock lease** plus an **attempts** counter carried in the job's
own hash.

A job is an entity: its row is a hash at the job key, written when the job is enqueued. The enqueue script
sets three fields on that hash, `state`, `attempts`, and `payload`, in one atomic step:

```lua
-- echo_mq/lib/echo_mq/jobs.ex · the @enqueue script body (verbatim)
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
redis.call('ZADD', KEYS[2], 0, ARGV[1])
```

When a worker claims the job, the claim script reads the **server clock** and stamps a lease deadline, moves
the job from pending to active, and increments `attempts` — the fencing counter:

```lua
-- echo_mq/lib/echo_mq/jobs.ex · the @claim script, at the lease (verbatim)
local att = redis.call('HINCRBY', jk, 'attempts', 1)
...
local t = redis.call('TIME')   -- the server clock; the deadline is computed wire-side
```

The lease is the processing list's job, done by a clock rather than a second list. If the worker finishes, it
calls `complete` and the job's row is cleared. If the worker crashes, it never calls `complete`; the lease
deadline passes; a sweep finds the expired lease and the job is re-claimed — and because the claim does
`HINCRBY 'attempts' 1`, the retry count is already there to bound the retries. The reader does not scan a
processing list for stuck items; the deadline on the lease *is* the staleness signal, read from the same
`TIME` clock every claim, promote, and reap uses.

The owned wire still knows the list family — `EchoWire.Cmd.rpoplpush/2` ("Open an RPOPLPUSH builder") and
`blmove` (the blocking move) are both real builders in `echo_wire/lib/echo_wire/cmd.ex` — but the bus's
crash-safety is the lease, not a processing-list move. (The bus does run an `LMOVE` in `lanes.ex`, but that
one is `LMOVE KEYS[1] KEYS[1] 'LEFT' 'RIGHT'` — a single-key rotation of the *ring of lane names* for
round-robin fairness, not a source-to-processing move. Different operation, different purpose.)

**Bridge — the pattern → its EchoMQ application.** The pattern: claim a job by atomically moving it to a
processing list (`LMOVE`/`BLMOVE`), remove it on ack (`LREM`), and let a recovery worker re-queue items stuck
too long — no job lost to a crash. Its application: the bus stamps a **server-clock lease** (`TIME`,
`jobs.ex:64`/`:287`) and an `attempts` counter (`HSET … 'attempts' '0'`, `jobs.ex:22`; `HINCRBY … 'attempts'
1` on claim, `jobs.ex:285`) on the job's own hash, so a crash → lease expiry → re-claim with `attempts`+1 —
the lease-based equivalent of the processing list, same guarantee, different mechanism.

**Take.** A reliable queue refuses to lose a job between claim and ack. Redis's classic form does it with a
processing list, an `LREM` on ack, and a recovery sweep; the bus does it with a server-clock lease and an
`attempts` counter. Both are at-least-once, so both want an idempotent handler — they would rather run a job
twice than drop it.

## §Recap

The gap is the instant between a naive pop and a durable result; a crash in that instant loses the job. The
list-based reliable queue closes it by making the claim an atomic move onto a processing list, taking the job
off only on a positive ack, and re-queuing strays with a recovery worker. PinLater names the same contract —
explicit acks and configurable retry — at six million jobs per minute. The bus reaches the same goal with a
server-clock lease and an `attempts` counter instead of a processing list. The next dive turns to scale: how
"add a shard" becomes a configuration change, not a data migration, and where the in-RAM record gets made
durable.

## References

### Sources

- [Redis — `LMOVE`](https://redis.io/docs/latest/commands/lmove/) — the modern reliable-queue primitive; `RPOPLPUSH` was deprecated in 6.2.0 in its favour.
- [Redis — `RPOPLPUSH`](https://redis.io/docs/latest/commands/rpoplpush/) — the original pattern, with the processing-list recovery note for crash safety.
- [Pinterest Engineering — Open-sourcing PinLater](https://medium.com/pinterest-engineering/open-sourcing-pinlater-an-asynchronous-job-execution-system-d8ec4e39859a) — explicit acks + automatic retry with configurable delay, at scale.
- [GitHub — pinterest/pinlater](https://github.com/pinterest/pinlater) — the Thrift async-job service: enqueue, dequeue, ACK (Java, Apache-2.0; archived).

### Related in this course

- [R8.03.1 · Functional partitioning](/redis-patterns/production-operations/pinterest-task-queue/functional-partitioning) — the previous dive: placement decided by identity.
- [R8.03.3 · 1 → 1000+ scaling](/redis-patterns/production-operations/pinterest-task-queue/scaling-1-to-1000) — the next dive: making "add a shard" trivial, and the durability turn.
- [R8.03 · Pinterest: task queues & partitioning](/redis-patterns/production-operations/pinterest-task-queue) — the module hub.
- [/echomq/queue](/echomq/queue) — the Queue pillar: jobs, lanes, and the lease, in depth.
- [/echo-persistence](/echo-persistence) — the durability dial: where the in-flight job record is made to survive a restart.
