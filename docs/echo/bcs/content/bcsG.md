# BCS · Appendix G — Objects on the Bus: the Claim Check, Measured

<show-structure depth="2"/>

Appendix F priced the canon's codec at the native boundary; the sharper question stands behind it: when a message *is* an object, what does the bus carry? This appendix measures the two answers on one lane (`bcs_rung_busobjects_check.out`, `PASS 6/6`). The **snapshot** strategy serializes the object into the payload — `term_to_binary` out, `binary_to_term` in, bytes and a decode on every message. The **claim check** is what this series has shipped since Chapter 4.2 without naming it: the object lives in the declared table, and the payload is `Coherence.payload/2` — fourteen bytes of branded id, one separator, fourteen of version, twenty-nine bytes constant, forever. Hohpe's pattern in one line — "Store message data in a persistent store and pass a Claim Check" [2] — and the series' addition to it is the fence: the claim carries a *version*, so a stale message cannot deliver the past as the present. One design rule frames every number below, stated once and held throughout: the bus path admits regular-scheduler work only — nanoseconds to microseconds, nothing heavier — and both strategies measured here live inside it.

## The field

One object in two sizes, both moved through the same `Lanes` and `Consumer` path. The small object is eight fields of ids, floats, and short strings — `152` bytes as a snapshot. The big one carries a sixty-item list — `3337` bytes, so its every message hauls more than sixty claims' worth of wire. The claim is `29` bytes for both, because the claim does not know how big the object is, which is the point.

## The producer's side

Per message over a thousand each: claim `58.2` µs, small snapshot `65.7`, big snapshot `101.1`. All three are one enqueue script on the same wire — the spread is bytes and the encode. The encode alone prices the scaling: `446.6` ns to serialize the small object, `7741.0` ns the big one, paid on every message the snapshot strategy sends. The claim's producer pays something the snapshot does not: one table put per object *version* — `42` µs median, an L2 SET on the same wire — the luggage checked once so that every message referencing that version travels at twenty-nine bytes. That cost is not hidden in a footnote; it is the input to the crossover arithmetic below.

## The consumer's side, where the id earns the chapter

The snapshot's handler pays `binary_to_term` per message: `434.0` ns small, `12059.0` ns big — the decode scales with the object and repeats on every delivery, every consumer, every retry. The claim's handler resolves through a term cache keyed by the `(id, version)` pair, and lands at `232.0` ns warm — constant, object size irrelevant.

The reason that cache is trivial to operate is the BCS property this appendix exists to demonstrate. The pair `(id, version)` is **immutable by construction**: a version never changes meaning, a new state is a new version, so a decoded term cached under that key is correct forever. There is no invalidation story, no TTL tuning, no coherence protocol for the term cache — old versions stop being referenced and age out. The snapshot strategy cannot build this cache at all, because a snapshot has no identity to key on: it is anonymous bytes that must be decoded to learn what they were. This is where the id-as-cache approach excels on the bus exactly as it excelled in Chapter 4.5's tables: the key arrives already serialized, already typed, already fenced, and the expensive work — one fetch, one decode — happens once per version per node instead of once per message.

## End to end, warm and cold

Fifty wakes each through the live lane, medians: claim warm `183` µs, small snapshot `202`, big snapshot `185`, claim cold `498`. The warm claim tracks the lane's committed shape with its 29 bytes and its 232-nanosecond resolve. The cold claim — the node's first sight of a version, term cache and L1 both empty — pays its fetch through the table's owner to the wire and its one decode *inside* the wake latency, and the row prints as the loss it is: the pattern's stated price is roughly one extra round trip on first contact, after which that version is warm for every subsequent message on the node. The two snapshot medians sit within run-to-run spread of each other on this loopback wire; the snapshot's true per-message scaling lives in the producer and handler rows, where it is unambiguous.

## The staleness law

The row no latency number can buy. An object was published at v1, then updated to v2 (px `222.5`) — and a v1 message was still in flight, as messages always are. The snapshot consumer decoded its payload and saw px `101.25`, with no vocabulary to notice that v2 exists: the copy is the truth, and the copy is wrong. The claim consumer hit the coherence door with v1 and was answered `:stale` — the mint-ordered fence of 4.2 doing on the bus what it does in the cache — and its fetch returned the current object. A reference with a fence cannot deliver the past as the present; a copy cannot do anything else. For a trading surface, this single row is the argument: the bus that carries snapshots is a bus that can execute on stale prices by design.

## The verdict, and the crossover

The committed table, verbatim:

```
verdict: per message            claim check | small snapshot | big snapshot
verdict: bytes on the bus       29 | 152 | 3337
verdict: producer us            58.2 | 65.7 | 101.1
verdict: handler ns             232.0 warm (constant) | 434.0 | 12059.0
verdict: e2e median us          183 warm, 498 cold | 202 | 185
verdict: staleness defense      :stale at the door, fetch returns current | none, the copy is the truth | none
verdict: once per version       put 42 us -- amortized after ~5.3 small or ~0.8 big messages
```

The crossover is arithmetic on measured cells, not a claim: the version's `42` µs put amortizes against the snapshot's per-message encode-and-bytes premium, and on these cells the luggage check pays for itself after `~5.3` small messages or `~0.8` big ones — for the big object, the very first message is already cheaper as a claim. Below the crossover — a tiny object referenced exactly once — the snapshot is the right call, and the table says so. Everything above it, and everything with fan-out, retries, or replay (where the snapshot re-pays its decode every time and the claim's term cache pays nothing), belongs to the claim.

## Where the native boundary sits in this

Nowhere on the object path, by construction — and that is the answer to the language question for the bus. The only native code near this lane is Appendix F's codec shim: plain `erl_nif.h` and libc-class C over the contract core, regular-scheduler calls in the hundred-nanosecond class, accelerating the fourteen-byte ids the claim is made of. The object itself never needs a native serializer because the design removed the object from the messages; the BEAM's own `term_to_binary` [1] remains the store-side encoder, paid once per version at `446.6`–`7741.0` ns where the snapshot strategy would pay it per message. A faster serializer optimizes the strategy this appendix measured out of the hot path.

## Boundaries

One box, one scheduler, loopback wire: the e2e medians carry container variance and the snapshot pair's ordering within it; the unambiguous scaling rows are bytes, producer, and handler. The cold-claim price assumes the table holds the version — a true miss falls to the table's loader, whose cost is the loader's business and was not staged here. The term cache as built is unbounded by version; production sizing is an eviction policy on `(id, version)` keys, which the immutability makes safe but not free. And the crossover arithmetic prices this wire and this put — a slower store moves it up, fan-out moves it down, and the formula travels with the table so the reader can re-cut it on their own cells.

## Companion files

`runtimes/elixir/bcs_rung_busobjects_check.exs` and its committed record `bcs_rung_busobjects_check.out`; the claim itself — `lib/echo_cache/coherence.ex` (`payload/2`, `parse/1`, the fence) and `lib/echo_cache/table.ex` as 4.1–4.2 shipped them; the codec under the claim — Appendix F ([`bcsF.md`](bcsF.md)) and its committed record; the lane — `lib/echo_mq/lanes.ex` and `lib/echo_mq/consumer.ex` unchanged.

## References

1. Erlang/OTP documentation — External Term Format (term_to_binary and binary_to_term over the tagged external format; the snapshot strategy's encoder and the store-side encoder both): [erlang.org/doc/apps/erts/erl_ext_dist.html](https://www.erlang.org/doc/apps/erts/erl_ext_dist.html)
2. Hohpe & Woolf — Claim Check, Enterprise Integration Patterns (store the data, pass the check, enrich on retrieval — the pattern this lane runs with a version fence the original does not carry): [enterpriseintegrationpatterns.com/patterns/messaging/StoreInLibrary.html](https://www.enterpriseintegrationpatterns.com/patterns/messaging/StoreInLibrary.html)
