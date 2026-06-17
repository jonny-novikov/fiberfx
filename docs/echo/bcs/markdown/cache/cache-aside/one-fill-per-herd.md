# B4.1.2 · One Fill per Herd

> Dive 2 of B4.1 · route `/bcs/cache/cache-aside/one-fill-per-herd` · teaches `content/bcs4.1.md` §"One fill
> per herd" + §"Hits at ETS speed" · transcript lines `derive (herd)`, `E3`, `derive (speed)`, `E4` of
> `bcs_rung_4_1_check.out`.

Two hundred misses, one load.

Misses route through the table's owner, and concurrent misses on one key coalesce onto a single flight — the
first caller's flight checks L2, falls through to the loader, writes both layers, and the owner replies to
every waiter with the one answer. The drill is the gate: "200 concurrent cold readers, loader runs 1,
coalesced waiters 199, every reader holding the one answer". And the hit path that makes the cache worth
having is priced on the same record: `1311621 hit reads per second (762 ns each)` against `31 us per L2 GET`
on the same wire — the L1 hit is `40 times cheaper` than the round trip it replaces.

Source: `content/bcs4.1.md`, quoting `bcs_rung_4_1_check.out`; the module is committed at
`runtimes/elixir/lib/echo_cache/table.ex`.

Interactive 1 (hero): the herd coalescer — the derive line's counterfactual ("200 concurrent cold readers
without single-flight run 200 loads") against the law's outcome (loader runs 1, coalesced waiters 199 — the
split computed live as 200 − 1), each side quoting its verbatim line.

## §1 The transcript

This dive reads the two derive lines and the gates they bound, E3 and E4 (source:
`content/echo_data/runtimes/elixir/bcs_rung_4_1_check.out`):

```
derive (herd): 200 concurrent cold readers without single-flight run 200 loads; the law demands the misses coalesce onto one flight -- expect loader runs 1 and 199 coalesced waiters
E3 herd ok -- the thundering herd survived with one fill: 200 concurrent cold readers, loader runs 1, coalesced waiters 199, every reader holding the one answer
derive (speed): a hit is a caller-side lookup on a public read-concurrency set plus the kind gate and a counter bump -- expect 250,000 to 1,500,000 hit reads per second on this core; an L2 GET pays a loopback round trip, and Appendix A committed 29,456 sequential round trips per second, near 34 us each -- expect the L1 hit at least 10 times cheaper than the wire
E4 speed ok -- measured: 1311621 hit reads per second (762 ns each) against 31 us per L2 GET on the same wire -- the L1 hit is 40 times cheaper than the round trip it replaces, inside the derived band
PASS 6/6
```

(The full record holds E1–E2 and E5–E6; dive 1 and dive 3 read them, and the hub freezes the record whole.)

## §2 The flight

The first caller's flight checks L2, falls through to the loader, writes both layers, and the owner replies to
every waiter with the one answer. The pattern has a name in the Go world — singleflight, "a duplicate function
call suppression mechanism" — and the Go port's fill discipline already has its idiom:
`golang.org/x/sync/singleflight` is one-fill-per-herd as a library.

The decision: flights are processes, not owner code. A slow loader blocks its own flight, never the owner —
other keys keep filling, puts keep landing. A crashed flight is a monitored event: every waiter gets a typed
error, nobody hangs. And loader errors are not cached — a broken upstream surfaces immediately instead of
being memorized; negative caching is a deliberate omission, revisitable under its own gate.

Two hundred simultaneous cold readers at the open are the normal case in this domain, and the gate says they
cost one load. The manuscript plans the referee chapter — **B4.5 · The Cache Referee** — to hold the
comparison set to this drill.

## §3 The priced pair

A hit is a caller-side lookup against a public, read-concurrency ETS table, plus the kind gate and one atomic
counter bump. The read path never enters the owner's process — the owner is consulted only when there is
owner's work to do; that is the whole architecture. Derived first — "expect 250,000 to 1,500,000 hit reads per
second on this core" and "expect the L1 hit at least 10 times cheaper than the wire", with Appendix A's
committed `29,456 sequential round trips per second, near 34 us each` as the wire's floor — then measured:
"1311621 hit reads per second (762 ns each) against 31 us per L2 GET on the same wire -- the L1 hit is 40
times cheaper than the round trip it replaces, inside the derived band".

This is what makes 762 ns a hit (against its 31 µs pair on the wire), and it is why stats ride `:counters`
instead of `GenServer.call`. The boundary travels with the number: one core, loopback, this container — the
ratios travel, the absolutes describe this machine.

Interactive 2: the hit-vs-wire cost bar — the two committed costs drawn to scale on one nanosecond axis
(762 ns beside 31 µs), with the per-second rates (`1311621` hit reads per second; Appendix A's `29,456`
sequential round trips per second) and the derive band on their own readouts; every figure verbatim from the
record.

## References

Sources:

- Go x/sync — singleflight — https://pkg.go.dev/golang.org/x/sync/singleflight (duplicate function call
  suppression: the named prior art for one fill per herd, and the Go port's idiom for it)
- Erlang/OTP — ets — https://www.erlang.org/doc/apps/stdlib/ets.html (public `read_concurrency` tables: the
  caller-side hit path)

Related:

- /bcs/cache/cache-aside — B4.1 · Cache-Aside at ETS Speed, the module hub; the full rung in context
- /bcs/cache — B4 · EchoCache, the chapter landing
- /bcs/bus — B3 · The Bus, the wire whose loopback floor prices the comparison
- /bcs/elixir-core/property-stores — B2.2 · Property Stores, the stores behind the loader
- /redis-patterns — Redis Patterns Applied, the caching substrate patterns
- /echomq — EchoMQ, the bus protocol in rung-level depth

Pager: previous `/bcs/cache/cache-aside/declared-not-discovered` · next
`/bcs/cache/cache-aside/the-jittered-clock`.
