# B1.2 · The Identity Contract, Read as Architecture

> Route: `/bcs/ideas/identity-contract` (module hub, B1.2). The route-mirror source-of-record. Teaches
> `content/bcs1.2.md`, with constants per `content/contract.md` + `content/vectors.json`. Build stamp:
> `BCS0NtMmO5CTdg`.

## Hero

Kicker: `B1.2 · THE IDENTITY CONTRACT, READ AS ARCHITECTURE — manuscript chapter 1.2`. Title: **One document.
Two readings.** Lede — the contract is one document with two readings. An implementer reads it for *how to
compute* — the alphabet, the bit layout, the vectors a port must reproduce. An architect reads it for *what
systems may rely on* — and since the law admits exactly one value across every boundary, that second reading is
the architecture's entire interface definition. Heronote — this module performs the second reading: each
property, the failure it retires, the committed evidence that it holds, and how Elixir and Go each carry it.

### The contract sheet (interactive SVG)

Four property blocks — typed · ordered · placed · canonical — drawn as one sheet. Select a property to read
what systems may rely on, the failure it retires, and its evidence figure in the readout. Degrades to a static
labelled sheet without JavaScript.

- typed — the namespace, carried twice; retires **the silent join**; evidence: one compiler error, the
  `200 / 400 / 400 / 404` gate row, the substrate's `{:error, :namespace}`.
- ordered — string order is mint order; retires **the second clock**; evidence: `page_desc(2000)` == byte-sort
  desc, the `40960`-entry streams window.
- placed — hash32, arithmetic anyone may run; retires **the routing table**; evidence: `234878118` reproduced
  by seven runtimes, `0.9586` ns in pure Go.
- canonical — one Rust source, one C reference, one vector file, a conformance suite per runtime; retires
  **the dialect**; membership is passing the suite.

## §1 · The wire form first (#form)

The wire form is fixed-width before it is anything else: three uppercase letters and eleven base62 characters,
fourteen bytes, always. `USR0KHTOWnGLuC` is the canonical vector, and `AzL8n0Y58m7` is the largest payload the
alphabet may carry — 62¹¹ exceeds 2⁶³, which is why the range gate exists. Fixed width is itself architectural:
comparators are bytewise over a known length, parsers index instead of scan, and the storage layer rewards the
shape — 65 bytes per key on the measured table, with the encode at 5.14 nanoseconds in the canon's own Rust.

Frozen (content/contract.md · the normative vectors):

    encode("USR", 274557032793636864)        = "USR0KHTOWnGLuC"
    base62(2^63 − 1)                         = "AzL8n0Y58m7"   ← MAX_PAYLOAD, the range gate's ceiling

## §2 · Four properties, four failures retired (#properties)

- **typed** — the namespace rides in the first three bytes and in the type. A wrong-kind identity cannot cross
  a declared boundary silently. Retired: the silent join.
- **ordered** — string order equals numeric order equals mint order. A table keyed by branded ids is a
  timeline with no clock in the process. Retired: the second clock.
- **placed** — any holder of an id computes where its row lives: trie slot, cache shard, partition, queue
  lane. No directory, no rendezvous. Retired: the routing table.
- **canonical** — every runtime means the same thing by the same fourteen bytes, proven by suite. Retired:
  the dialect.

## §3 · The boundary's error vocabulary (#gates)

Length, namespace, charset, range — four refusals a gate may speak, so a 400 can say *why* without leaking
*what*. One runtime speaks it coarsely: the BEAM's parser reports `:invalid` without subclassification — a
Chapter 1.1 decision that refused a second parser.

Frozen (content/contract.md §9 · the reject vectors):

    reject "USRzzzzzzzzzzz"                  → range
    reject "usr0KHTOWnGLuC"                  → namespace
    reject "USR0KHTOWnGLu"                   → length
    reject "USR0KHTOWnGL!C"                  → charset

## §4 · One authority per fact (#authority)

There is deliberately no `bcs1.2.specs.md`. The one authority is the contract with `vectors.json` beside it;
the manuscript chapter cites it and adds no second normative text, because a paraphrase of a spec-of-record is
a drift surface. The module inherits the same discipline: it reads the contract, it does not restate it.

## §5 · The four dives (#dives)

- **the-namespace-discriminant** — typed: the discriminant carried twice; one compiler error; the
  `200 / 400 / 400 / 404` row; the substrate's `{:error, :namespace}`.
- **the-order-theorem** — Snowflake's "roughly sortable" hardened to exact per node; keys as timelines; the
  `40960`-entry window.
- **placement-not-security** — hash32's one finalizer round; `234878118` everywhere; the hard edge.
- **the-minting-law-and-the-canon** — burst-borrow with node bits excluded; the four-refusal taxonomy; suite
  membership.

## References (#refs)

Sources: Appleby — SMHasher/MurmurHash3 (`https://github.com/aappleby/smhasher`) · King — Announcing Snowflake
(`https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake`). The canon itself is
`content/contract.md` + `content/vectors.json`, named in prose.
Related: `/bcs/ideas` (the chapter) · `/bcs` (the course home) · `/echomq` · `/redis-patterns` · `/elixir`.

## Pager

Previous: `/bcs/ideas` — B1 · Ideas Behind. Next: dive 1 ·
`/bcs/ideas/identity-contract/the-namespace-discriminant`.
