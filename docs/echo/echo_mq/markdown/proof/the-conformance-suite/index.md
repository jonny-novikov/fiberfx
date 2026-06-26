# The conformance suite

> Route: `/echomq/proof/the-conformance-suite` · Pillar VI, The Proof · module 01 (hub).
> Grounded in `echo/apps/echo_mq` — `EchoMQ.Conformance` (`scenarios/0`, `run/2`). All real code. No Lua.

## Thesis

The bus contract is not asserted in prose — it is **run**. `EchoMQ.Conformance` is the protocol written as a
set of runnable **scenarios**: each is a name and a one-line contract that drives the public surface against a
**live server** and asserts the **externally visible verdict**. Where the contract *is* the wire, the scenario
issues raw commands. The suite is the **polyglot promise made testable**: any runtime that speaks the wire is
conformant exactly when it drives the same server to the same verdicts — the harness ports by translation, not
by faith.

## The shape (no hard count — the set grows)

`scenarios/0` returns a keyword list of `name: "one-line contract"` **in run order**. `run(conn, queue)` walks
that list, runs each scenario on a **per-scenario sub-queue** of `queue`, **purges what it mints**, prints one
`CONF` line per scenario plus a closing tally, and returns `{:ok, n}` when all pass or `{:error, failed_names}`
otherwise. The set is **not a fixed number** — it grows by additive minor (prior scenarios byte-frozen, each new
one probe-registered), so the page teaches the *shape*, never a count that goes stale.

## The three dives

1. **The scenarios** (`the-scenarios`) — `scenarios/0`: the names + one-line contracts in run order; each asserts
   an externally visible verdict (the fence, the row shape, idempotent admission, the kind law, the lex law, the
   token discipline, the schedule/morgue/reaper, the lanes, the read/operator/watch planes, the flow family,
   …). Each drives the public surface, or raw commands where the contract is the wire.
2. **Run and the verdict** (`run-and-the-verdict`) — `run/2`: the loop over per-scenario sub-queues, the purge,
   the one `CONF` line each, and the `{:ok, n}` / `{:error, failed_names}` verdict.
3. **The additive-minor law** (`the-additive-minor-law`) — how the set grows without breaking the wire: prior
   scenarios stay byte-frozen + git-verified, each new one is probe-registered, the count re-pinned. Additive
   registration is a protocol **minor**; a wire break is a **major**.

## Doors

- Reverse (`.applied`): the depth behind `/redis-patterns/coordination` (R2, the atomicity the suite proves) and
  `/redis-patterns/production-operations` (R8, running the tier) — both built, hard-linked.
- `/bcs/together` (B6) — the four libraries as one umbrella, the chapter the Proof shows holds.
- Within-course: `/echomq/proof`, `/echomq/queue`, `/echomq/bus`, `/echomq/protocol`.

## References

### Sources
- Kent Beck — *Test-Driven Development* — the verdict-asserting scenario as the contract.
- Valkey — *ZCARD* / *HGET* — the read commands a scenario asserts against.
- `:telemetry` — the standard metering surface the sibling module re-roots (named here as the next module).

### Related in this course
- `/echomq/proof` — the pillar landing.
- `/echomq/protocol` — the keyspace and branded-id gate every scenario asserts against.
- `/echomq/queue` — the first pillar the suite proves whole.
- `/bcs/together` (B6) — the manuscript chapter the Proof shows holds.
