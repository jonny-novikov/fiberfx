# The immutable core

> Route: `/redis-patterns/overview/patterns-become-protocol/the-immutable-core` · Module R0.3 · dive 2 ·
> Grounding: `docs/echo/bcs/content/bcs3.1.md` (the grammar and the fence) · `bcs3.2.md` (the row and the
> enqueue script, verbatim) · `bcs3.3.md` (the four sets and the fencing token) · `bcsA.md` (the fence on the
> wire) · `docs/echo_mq/emq.design.md` (the reserve, the change rules, the wire classes).

The core of the protocol is small enough to hold in one hand: a closed key grammar, a reserve of exactly four
deployment keys, a job row of exactly three fields, and four sorted sets. What keeps it stable is not a pinned
upstream commit — it is governance the protocol carries itself: a two-way typed **version fence**, written
change rules, and a closed registry of wire classes. This dive walks the owned core, then the machinery that
holds it still.

## §1 · The closed grammar and the reserve

Every key in the system parses. Per-queue keys are `emq:{q}:<type>` — `emq:{orders}:pending`,
`emq:{orders}:active`, `emq:{orders}:schedule`, `emq:{orders}:dead`. Job rows compose the grammar with the
identity canon: `emq:{orders}:job:ORD0NgWEfAEJfs` is seventeen bytes of grammar before a fourteen-byte branded
payload. And the braced base is reserved for facts about the deployment itself: at the current wire version the
`{emq}:` reserve holds **exactly four members** — `{emq}:version`, `{emq}:locks`, `{emq}:bundle`,
`{emq}:migration:<q>`. A per-queue key begins `emq:{` and a reserve key begins `{emq}:` — disjoint at the first
byte, so any key classifies by parse.

Two laws ride the grammar. **The hashtag is the queue name**: every key of one queue answers one cluster slot,
so every per-queue transition script is single-slot legal by grammar. And **wellformedness lives at the key,
policy at the script**: the key builder refuses anything that does not parse as a fourteen-byte branded id,
while *kind* policy — which namespaces a queue admits — belongs to the enqueue script.

## §2 · The row, the sets, and the admission law

A job is a hash of three fields — `state`, `attempts`, `payload` — and deliberately nothing more. No
`enqueued_at` exists because mint time already lives inside the identity; server-time facts belong to leases.
The four sorted sets each earn their score semantics: `pending` stays score-zero forever, so equal-score lex
order is mint order — the set is the FIFO, the browse index, and the time-range index at once; `active` is
scored by lease deadline, so it is simultaneously the in-flight roster and the expiry index; `schedule` is
scored by run-at — the separate set that keeps mixed scores out of the lex law; `dead` is score-zero again, so
the morgue browses newest-first like everything else.

Admission is one idempotent script, and the order of its three acts is a decision — policy before existence
before write (`bcs3.2`, verbatim):

```lua
if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
  return redis.error_reply('EMQKIND job id must be JOB-namespaced')
end
if redis.call('EXISTS', KEYS[1]) == 1 then
  return 0
end
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
redis.call('ZADD', KEYS[2], 0, ARGV[1])
return 1
```

The committed line for the refusal reads: `an ORD id in the job position answers EMQKIND on the wire -- the key
let it pass, the law did not`. Duplicates are a success shape — `first call enqueued, second answered
duplicate, the row untouched and pending holds 1` — because an at-least-once producer retries on any doubt and
the id is the receipt.

> **Notes on Valkey.** The admission lands whole because script execution is atomic — "all of the script's
> effects either have yet to happen or had already happened" —
> [valkey.io/topics/programmability](https://valkey.io/topics/programmability/).

## §3 · Governance — frozen by fence, not by pin

What keeps the core immutable is the protocol's own machinery, in three parts.

**The fence.** At every connect the connector reads `{emq}:version`, claims it on a fresh keyspace, verifies
the read-back, and refuses any other value with a typed error — `{:error, {:version_fence, got}}` at boot, a
stop the supervisor records on reconnect. The committed line reads: `GET {emq}:version answers echomq:3.0.0
through the fenced connector itself` — the read travels through a connection that could not exist had the
fence not held.

**The change rules.** The wire version is recorded monotonically and changes only under written rules: additive
registration — a new key type, a new reserve member with its probe, a new wire class with its probe — is a
**minor**; a wire break or a field repurpose is a **major**. A break is the rare event the rules exist to make deliberate; additive registration is the everyday path.

**The wire classes.** Every refusal a bundle script issues leads with its class word — a closed registry of
two: `EMQKIND` (kind refusal at enqueue) and `EMQSTALE` (fencing-token refusal). A refusal that names its class
is parseable policy, not a stringly accident.

## §4 · The fencing token

The protocol's quiet center is one integer doing two jobs. The claim script increments `attempts` with
`HINCRBY` — monotonic per job by construction, because only claim increments it — and every later transition
verifies the token before touching anything (`bcs3.3`, verbatim):

```lua
local att = redis.call('HGET', KEYS[2], 'attempts')
if att ~= ARGV[2] then return redis.error_reply('EMQSTALE complete token mismatch') end
```

The committed lines stage both outcomes. The right token: `complete with the right token retires the row --
nothing remains`. The zombie: a consumer holding token 1 watches an impostor's complete with token 99 earn
`EMQSTALE; the lease holder's work survives the zombie's complete`. And across a retry, the schedule, and a
promote, the next claim hands out token 2 — `one job, two lives, one counter`.

**The pattern → its EchoMQ application.** Write the convention down exactly, version it, and let the protocol
police itself. EchoMQ's core is a closed grammar, a four-member reserve, a three-field row, and four sets —
held still by the two-way fence, the written change rules, and typed refusals on the wire.

## References

### Sources
- [Valkey — Sorted sets](https://valkey.io/topics/sorted-sets/) — the equal-score lexicographic family behind the score-zero decision.
- [Valkey — ZRANGE](https://valkey.io/commands/zrange/) — the REV and BYLEX forms behind newest-first browse.
- [Valkey — Programmability](https://valkey.io/topics/programmability/) — atomic script execution; the admission lands whole.
- [Redis — Documentation](https://redis.io/docs/) — the hash and sorted-set commands the row and the sets compose.

### Related in this course
- [R0.3 · Patterns become protocol](/redis-patterns/overview/patterns-become-protocol) — the module hub.
- [R0.3.1 · The four layers](/redis-patterns/overview/patterns-become-protocol/the-four-layers) — the stack this core sits in.
- [R0.3.3 · The door to EchoMQ](/redis-patterns/overview/patterns-become-protocol/the-door-to-echomq) — the next dive: the contract, and the doors.
- [/echomq](/echomq) — the protocol in depth: the grammar, the bundle, the fence, rung by rung.
- [/bcs](/bcs) — the architecture the bus is built inside.
