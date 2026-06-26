# The additive-minor law

> Route: `/echomq/proof/the-conformance-suite/the-additive-minor-law` · dive 03.
> Grounded in `EchoMQ.Conformance` (`scenarios/0`, `run/2`) + the conformance growth law (real code +
> `echo/apps/echo_mq` discipline). No Lua.

## The set grows — without breaking the wire

A conformance set is only useful if it can grow as the bus gains surface. The growth has a law: a new clause is
added **additively**. Three rules hold every time the set grows:

1. **Prior scenarios stay byte-frozen.** An existing clause's contract and its `apply_scenario` body do not
   change — git verifies it byte-for-byte against HEAD. A passing port stays passing.
2. **The new scenario is probe-registered.** It is appended to `scenarios/0` in run order with its own
   `apply_scenario` clause and asserts one new externally visible verdict on a live server.
3. **The count is re-pinned.** The live total `n` is re-pinned in both pinning tests — the `{:ok, n}` run test
   and the `@run_order` scenarios test — so the set's size is asserted, not assumed.

Because the page never prints a hard count, none of this dates the course: the *shape* is fixed (names +
contracts in run order → run on sub-queues → `{:ok, n}`), and the size is the bus's live total.

## Minor vs major — the version meaning

Additive registration is a protocol **minor**: a new clause adds a promise without changing an existing one, so a
prior port still conforms (it satisfies a subset). Changing an existing clause's verdict — the wire saying
something different than it said before — is a **major**: it breaks every port that passed the old set. The
conformance set is exactly the line between the two. A minor appends; a major rewrites.

## Conformance is the polyglot contract

The protocol lives **below the language line** — the keyspace plus the verbs, not the Elixir. A new runtime is
conformant precisely when it drives the same server to the same verdicts. The set is therefore the contract that
lets the bus be polyglot: the harness ports by translation, because each clause is wire-level. Add a runtime, and
you have not added trust — you have added a thing that must pass the same set.

## A minor, illustrated

Appending a clause leaves the prior set untouched and re-pins the count. The shape of an additive minor:

```elixir
# echo_mq — EchoMQ.Conformance
# An additive MINOR: the new clause is APPENDED in run order; every prior clause
# is byte-identical to HEAD (git-verified). The run total n grows by one and is
# re-pinned in both pinning tests. A prior port still conforms — it satisfies a subset.
def scenarios do
  [
    fence:        "the version fence is claimed before any work …",
    # … every prior clause unchanged, byte-for-byte …
    stream_retention: "retention as policy: trim/4 bounds a stream to a DECLARED window …",
    # ── the new clause, appended last, probe-registered ──
    stream_time_travel: "time-travel as a mint-time window read: a CLOSED [t0,t1] read EQUALS the id-filtered truth"
  ]
end
```

A wire-break **major**, by contrast, would *change an existing line's verdict* — e.g. `claim` mints token `0`
instead of `1`. Every port that passed the old `claim` now fails. That is the diff the additive-minor law forbids
on the same wire version: a minor adds a clause, a major rewrites one.

## Bridge

- Pattern (Redis Patterns Applied): a production protocol evolves by adding capability without breaking the
  clients already running against it — backward-compatible change. `/redis-patterns/production-operations` teaches
  running a tier as it grows.
- Implementation (echo_mq): the conformance set encodes that rule — append a clause (minor, prior set frozen),
  never rewrite one (major, the wire broke), with the count re-pinned each time.

## References

### Sources
- Kent Beck — *Test-Driven Development* — the scenario set as the executable contract that grows.
- Valkey — *ZCARD* — a read whose verdict a clause pins.
- `:telemetry` — the standard surface the sibling read-plane module re-roots.

### Related in this course
- `/echomq/proof/the-conformance-suite` — the module this dive belongs to.
- `/echomq/proof/the-conformance-suite/run-and-the-verdict` — where the count `n` is returned.
- `/echomq/protocol` — the wire the set is the contract for.
- `/redis-patterns/production-operations` (R8) — running the tier as it grows.
