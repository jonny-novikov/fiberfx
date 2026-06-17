# The Minting Law and the Canon

> Route: `/bcs/ideas/identity-contract/the-minting-law-and-the-canon` (dive 4 of 4, B1.2). Teaches the minting
> law, the gate taxonomy, and the *canonical* property of `content/bcs1.2.md`; normative text per
> `content/contract.md` §7–§10; rejects per `content/vectors.json`. Build stamp: `BCS0NtMmOrjssi`.

## Hero

Kicker: `B1.2 · DIVE 4 OF 4 — the minting law · the gates · the canon`. Title: **The law that records its own
defect.** Lede — the minting law exists because an unfaithful port once folded node bits into the counter, and
the contract chose to encode the lesson rather than merely fix the port. The counter state is timestamp and
sequence only; a drained sequence borrows from the node's own next millisecond, never from a neighbor node's
space. Heronote — uniqueness is per-node arithmetic plus fleet-wide node-id assignment, with zero coordination
at mint time — the property Twitter's design bought and this contract makes exact.

### The counter, stepped by hand (interactive SVG)

The minter's state as two fields — `(ts << 12) | seq` — with the node bits drawn outside the box. Three moves:
mint (same millisecond, sequence increments) · drain the window (sequence at 4095 carries into the timestamp
field — the burst borrow) · clock steps back (minting continues from `state + 1`; ids never repeat and never
decrease). A pure function replays the normative algorithm; the readout shows both fields after each move.
Degrades to a static diagram of the state layout.

## §1 · The minting law, frozen (#law)

Frozen (content/contract.md §7 · minting, normative):

    state MUST be timestamp ++ sequence — concretely (ts << 12) | seq — and MUST NOT embed the node bits.
    Burst borrow: past 4,096 ids in one millisecond, the carry runs from the sequence field into the
    timestamp field — the node borrows ids from its own next milliseconds, never a neighbor's space.
    Clock regression: when the wall clock moves backward, minting continues from state + 1;
    ids never repeat and never decrease.

A state layout with node bits inside the counter exhibits exactly the cross-node failure past sequence
exhaustion, and is non-conformant. One bug, encoded as a permanent test surface for every future port.

## §2 · The gate taxonomy, run by hand (#gates)

Interactive: the four-refusal classifier over the committed vectors. Five inputs —
`USR0KHTOWnGLuC` (accepted) · `USRzzzzzzzzzzz` → range · `usr0KHTOWnGLuC` → namespace · `USR0KHTOWnGLu` →
length · `USR0KHTOWnGL!C` → charset — replayed through a pure function in the contract's evaluation order:
length, namespace, charset, range. The readout names the gate, the C status (`BRANDED_ERR_LENGTH` ·
`BRANDED_ERR_NAMESPACE` · `BRANDED_ERR_CHARSET` · `BRANDED_ERR_RANGE`), and the BEAM's coarse `:invalid`.

Frozen (content/contract.md §9 · the reject vectors):

    reject "USRzzzzzzzzzzz"                  → range
    reject "usr0KHTOWnGLuC"                  → namespace
    reject "USR0KHTOWnGLu"                   → length
    reject "USR0KHTOWnGL!C"                  → charset

Length, namespace, charset, range — four refusals a gate may speak, so a 400 can say *why* without leaking
*what*. The BEAM speaks it coarsely as `:invalid` — the no-second-parser decision; if the taxonomy ever
sharpens there, it sharpens in `BrandedId` once.

## §3 · The canon (#canon)

One Rust source, one C reference, one vector file, and a conformance suite per runtime — membership in the
fleet is passing the suite, not reimplementing carefully. "Which language" becomes a deployment detail.

Frozen (content/contract.md §10 · the conformant suites):

    runtimes/elixir/verify.exs        pure and native paths, asserted against each other at boot
    contract/branded-id-rs            the crate suite (one-million-id roundtrip via make -C contract test)
    runtimes/node/bench.ts            + wasm_bench.ts
    runtimes/go/brandedid             tests
    runtimes/postgres/branded_sql.sql + the extension's reject and vector blocks

## §4 · What it retires (#retires)

The dialect — the translation layers that grow at every polyglot boundary. Identities can be the only thing
that crosses *because* they mean the same thing on every side; this is the property the law's second clause
quietly spends.

## References (#refs)

Sources: King — Announcing Snowflake
(`https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake`) · Appleby — SMHasher/MurmurHash3
(`https://github.com/aappleby/smhasher`).
Related: `/bcs/ideas/identity-contract` (the hub) · `/bcs/ideas` · `/bcs` · `/echomq` · `/elixir`.

## Pager

Previous: dive 3 · `/bcs/ideas/identity-contract/placement-not-security`. Next: back to the hub ·
`/bcs/ideas/identity-contract`.
