# B4.4.3 · Coverage and the Price

> Dive 3 of B4.4 · route `/bcs/cache/the-lane-that-remembers/coverage-and-the-price` · teaches H5–H6 of
> `content/bcs4.4.md`, quoting `bcs_rung_4_4_check.out`.

The same predicate that drives replay retires the outbox: an intent is deletable when its name carries an
applied version at least as new — coverage, not acknowledgment. The H5 gate runs it: "all 50 intents retired by
coverage in one pass, the applied memory kept its 50 names … the outbox empties, the memory does not." The H6
gate prices the whole arrangement and closes the module: `143 us per record-and-mark pair at the writer's edge,
and a remembered lane end-to-end median of 524 us against the bare lane's committed 148 us -- 3.5 times the
latency buys an outbox, a last word per name, and a replay that survives the bus`.

## §1 The transcript

This dive reads the compaction derive, H5, the price derive, H6, and the close (source:
`content/echo_data/runtimes/elixir/bcs_rung_4_4_check.out`; the record opens with H1–H4 — the hub holds it
whole):

```
derive (compaction): an intent is retired when its name carries an applied version at least as new -- coverage, not acknowledgment -- so after H4 all 50 intents are deletable, the applied memory keeps all 50 names, replay finds nothing, and a reopen still remembers
H5 compaction ok -- all 50 intents retired by coverage in one pass, the applied memory kept its 50 names, replay over the compacted journal found nothing to do, and a fresh open of the same file still answers the last word -- the outbox empties, the memory does not
derive (price): on prepared-once statements -- the single writer's privilege, with bind resetting the statement -- the writer's pair is two WAL commits and one cached rowid read at synchronous=NORMAL, so expect between 20 and 250 us on this disk; the remembered lane's end-to-end median should land between 200 us and 2 ms against the bare lane's committed 148 us: dearer, bounded, and the chapter's reason the journal is declared per group rather than assumed
H6 price ok -- the memory's price on this disk: 143 us per record-and-mark pair at the writer's edge, and a remembered lane end-to-end median of 524 us against the bare lane's committed 148 us -- 3.5 times the latency buys an outbox, a last word per name, and a replay that survives the bus
PASS 6/6
```

## §2 Compaction is coverage

**Coverage, not acknowledgment.** An intent is retired when its name carries an applied version at least as
new. The hot path pays no per-intent completion write; replay and compaction share one predicate; and the
applied table does double duty as the dedup floor and the retention rule. After H4's drill, all 50 intents are
deletable; the gate retires them in one pass, the applied memory keeps its 50 names, replay over the compacted
journal finds nothing to do, and a fresh open of the same file still answers the last word.

The retention verb (source: `content/bcs4.4.md`, How):

```elixir
{:ok, retired} = Journal.compact(:limits_journal)
```

Run `compact` on a timer sized to the replay-window appetite: intents are small, coverage is one SQL pass, and
an outbox kept under a few thousand rows replays in milliseconds.

## §3 The price, and how the gate improved the code

The first measurement of the writer's pair came in at 224 microseconds against a derivation that priced WAL
commits — the gap was per-call statement preparation, "three SQL parses per pair". The fix is the single
writer's privilege: the five hot statements are prepared once at journal start and rebound per call (exqlite's
bind resets the statement), and the pair fell to the committed `143 us per record-and-mark pair`. At
`synchronous=NORMAL` the WAL issues no per-commit sync — "the checkpoint is the only operation to issue an I/O
barrier" — so the pair is two log appends and a cached rowid read.

End to end, the priced pair, always on one row: `a remembered lane end-to-end median of 524 us against the bare
lane's committed 148 us -- 3.5 times the latency buys an outbox, a last word per name, and a replay that
survives the bus`. Declare a journal per group when losing that group's queued coherence to a bus restart costs
more than 143 microseconds per write ever will — and skip it for surfaces where the TTL floor was always
acceptable; the broadcast lane, in particular, gains nothing from an outbox it would only drop.

The toolchain fact behind the header: the runtime's mix project grew its **first compiled dependency** —
`exqlite` and its build chain vendored as path deps under `runtimes/elixir/vendor/` (tarballs from the package
mirror, the NIF compiled from the bundled SQLite amalgamation, no system SQLite consulted) — and the rung runs
under `MIX_ENV=prod mix run`, the first cache rung to do so, with the plain-script tower untouched.

Boundaries, stated honestly: `synchronous=NORMAL` is a stated trade — every process crash, consumer kill, and
bus restart in this part is fully covered, and a machine power loss may trim the unsynced tail of the WAL. The
layer that closes that gap is "Litestream-shaped … referenced and deliberately not implemented here": a separate
process streaming the journal off the box, outside this codebase by the same separation D-2 already taught. The
journal is per-group and per-node; replay is at-least-once by construction and harmless by comparison. And the
microseconds carry their header — one scheduler, this container's disk, a 29-byte payload; "the 3.5 multiple
travels better than the 143." The manuscript plans the measured comparison set — **B4.5 · The Cache Referee** —
and until that chapter ships, no comparative figure exists.

## References

Sources:

- Richardson, C. — Pattern: Transactional outbox —
  https://microservices.io/patterns/data/transactional-outbox.html (the pattern whose price this gate states)
- SQLite — Write-Ahead Logging — https://www.sqlite.org/wal.html (the commit path and the NORMAL trade — the
  checkpoint as the sole sync barrier)
- Litestream — How it works — https://litestream.io/how-it-works/ (the off-box durability layer, named and
  deliberately not implemented)

Related:

- /bcs/cache/the-lane-that-remembers — B4.4 · The Lane That Remembers, the module hub; the full rung in context
- /bcs/cache — B4 · EchoCache, the chapter landing
- /bcs/cache/coherence-by-mint-time — B4.2 · Coherence by Mint Time, the bare lane's committed 148 us
- /bcs/cache/cache-aside — B4.1 · Cache-Aside at ETS Speed, the declared table the journal stands behind
- /bcs/bus — B3 · The Bus, the volatile substrate D-2 keeps
- /echomq — EchoMQ, the protocol in rung-level depth
- /redis-patterns — Redis Patterns Applied, the substrate
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/cache/the-lane-that-remembers/the-bus-dies-the-lane-replays` · next
`/bcs/cache/the-lane-that-remembers` (back to the hub).
