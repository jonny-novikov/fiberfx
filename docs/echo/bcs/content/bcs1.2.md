# BCS · Chapter 1.2 — The identity contract, read as architecture

<show-structure depth="2"/>

The contract at [`contract.md`](../../contract/contract.md) is one document with two readings. An implementer reads it for *how to compute* — the alphabet, the bit layout, the vectors a port must reproduce. An architect reads it for *what systems may rely on* — and since the law of this part admits exactly one value across every boundary, that second reading is the architecture's entire interface definition. This chapter performs the second reading: each property of the contract, the failure it retires, the committed evidence that it holds, and how Elixir and Go each carry it. Every constant quoted is from [`vectors.json`](../../contract/vectors.json); every measured figure is verbatim from a committed output.

## Why

A property that nothing may rely on is a property the contract wasted; a reliance the contract never promised is a defect waiting for a port to expose it. The trading system makes the stakes concrete: a settlement message carries a `TXN` id and a `PRT` id and nothing else, so whether the receiving systems can type-check the pair, page positions without a clock, route to the right shard without asking, and trust a Go ingester to agree with the BEAM about all of it — every one of those is a clause in this document or it is folklore. The chapter exists to leave no clause as folklore.

## What — the contract, property by property

**The wire form is fixed-width before it is anything else.** Three uppercase letters and eleven base62 characters, fourteen bytes, always — `USR0KHTOWnGLuC` is the canonical vector, and `AzL8n0Y58m7` is the largest payload the alphabet may carry (62¹¹ exceeding 2⁶³ is why the range gate exists). Fixed width is itself architectural: comparators are bytewise over a known length, parsers index instead of scan, and the storage layer rewards the shape — 65 bytes per key on the measured table, with the encode at 5.14 nanoseconds in the canon's own Rust (Chapter 1.3 and Appendix 1.1 carry the full record).

**The namespace is a discriminant carried twice.** In the value — the first three bytes — and in the type, wherever the runtime can hold one. What systems may rely on: a wrong-kind identity cannot cross a declared boundary silently. The evidence stack runs the whole gauntlet: the deliberate negative test in the cross-runtime article is one compiler error — `BrandedId<"USR">` refused where `"CRS"` is required — the HTTP gate row reads 200 / 400 / 400 / 404 with the wrong-namespace refusal issued before any handler runs, and the substrate's typed gate refuses the malformed vectors 4/4 as `:invalid` while the wrong namespace earns its own `{:error, :namespace}`. The silent join is retired at compile time, at the schema, and at the store, in that order.

**The order theorem turns keys into chronology.** Because the payload is a fixed-width encoding of a strictly increasing integer, string order equals numeric order equals mint order. The lineage is worth naming: Twitter's 2010 generator promised ids that were uncoordinated, 64-bit, and roughly sortable — close ids for tweets posted close together [2]. The contract hardens *roughly* into *exactly* per node: the minting law below makes each node's sequence strictly monotonic, so a system's table keyed by branded ids is a timeline with no clock in the process. The substrate proved it at G4 — two thousand mints paged newest-first from byte comparison alone — and the streams experiment extended it across a second data structure: a ten-millisecond window addressed purely by id arithmetic returned its predicted 40960 entries, the first of them `1781000000010-28672`.

**The placement hash is arithmetic anyone may run.** `hash32` is one finalizer round from MurmurHash3 — xor-shift, the `fmix64` multiply constant, xor-shift, truncated to 32 bits — the constant carries Appleby's public-domain lineage [1], but the full finalizer's avalanche certificate does not transfer to a single round -- so the distribution this series relies on is measured directly over snowflake-shaped inputs in the committed hash audit. Architecturally that buys one sentence: any holder of an id computes where its row lives — trie slot, cache shard, partition, queue lane — with no directory and no rendezvous, at 0.9586 nanoseconds in pure Go and the same answer everywhere: 234878118 for the reference id, now reproduced by Elixir, Rust, C, TypeScript, wasm, Go, and SQL in this repository's committed outputs. The routing table is retired. The reliance has a hard edge, stated in the contract and repeated here: this is placement, not security — a non-cryptographic finalizer with no key is exactly the wrong tool wherever an adversary chooses inputs.

**The minting law records the defect it retires.** The generator's counter state is the timestamp and sequence only — node bits are excluded by normative text, so a same-millisecond burst borrows from the *next millisecond*, never from a neighbor node's space. The clause exists because an unfaithful port once folded node bits into the counter, and the contract chose to encode the lesson rather than merely fix the port. The architectural reading: uniqueness is per-node arithmetic plus fleet-wide node-id assignment, with zero coordination at mint time — the property Twitter's design bought [2] and this contract makes exact.

**The gate taxonomy is the boundary's error vocabulary.** Length, namespace, charset, range — four refusals a gate may speak, so that a 400 can say *why* without leaking *what*. One runtime speaks it coarsely: the BEAM's parser reports `:invalid` without subclassification, a Chapter 1.1 decision that refused a second parser; if the taxonomy ever sharpens there, it sharpens in `BrandedId` once.

**The canon makes "which language" a deployment detail.** One Rust source, one C reference, one vector file, and a conformance suite per runtime — membership in the fleet is passing the suite, not reimplementing carefully. The dialect is retired, and with it the translation layers that grow at every polyglot boundary. This is the property the law's second clause quietly spends: identities can be the only thing that crosses *because* they mean the same thing on every side.

## Who

Architects, who decide which of these properties a design may lean on and which leanings to forbid. Agents, whose guides ([`bcs1.1.llms.md`](bcs1.1.llms.md) is the pattern) compile each property into a fence or a free lunch. And the owners of the trading registry — `AST`, `TXN`, `PRT`, `ORD`, `RSK`, `STR` — who inherit every property at registration: a new entity kind costs three uppercase bytes and receives typing, chronology, placement, and cross-runtime identity without one line of per-kind design.

## When

Consult the **order theorem** when choosing keys, cursors, and replay windows — a feed is a descending walk and a window is two synthetic cursors, in a table or a stream alike. Consult **placement** when sharding anything — and only placement; a second routing scheme beside it is the drift the contract paid to remove. Consult the **namespace** when designing any boundary — route schemas, store gates, channel edges — and declare admitted namespaces where the toolchain checks them. Consult the **canon** when adding a runtime: the conformance suite is written first, and green is the membership card. And know when *not* to lean: an id names, it does not describe — kind and instant are the only facts readable from it, and everything else about an entity is a property in some system's table behind some system's gate.

## Where

The one authority is `contract/contract.md` with `vectors.json` beside it; this chapter cites it and adds no second normative text — there is deliberately no `bcs1.2.specs.md`, because a spec-of-record already exists and a paraphrase of it would be a drift surface. Enforcement points per runtime: `EchoData.BrandedId` and `EchoData.Bcs` on the BEAM with the `~b` sigil for literals; `runtimes/go/brandedid` in Go; the brand type, Fastify schemas, and the wasm codec in Node; the C ABI under `contract/`; the SQL domain in the historical record.

## How — the contract carried in Elixir and in Go

**Elixir.** The discriminant lives in binary pattern matching: a function head of `<<ns::binary-size(3), _::binary-size(11)>>` with the `is_branded` guard makes the function-clause system do the type system's work, and the `~b` sigil moves literal validation to compile time — an invalid id in source fails the build, not the request. The order theorem is the table's comparator: `:ordered_set` sorts binaries bytewise, so the theorem holds at every `prev` walk with no code at all. Placement and canon are one module deep — `hash32` through `BrandedId`, native NIF with the pure path proven byte-equal at every boot by the self-check the substrate's stores refuse to start without.

**Go.** The discriminant is nominal where Go can hold it and constructor-enforced where it cannot: the design pairs the existing `Encode`/`Parse`/`Hash32` surface with one defined type per registered namespace — `type PrtID string`, `type AstID string` — minted only by parsing constructors, so a `PrtID` does not assign where an `AstID` is required and the conversion that would defeat it is explicit, greppable, and reviewable. Weaker than a TS brand, and stated so; the load-bearing gate in Go remains the channel edge of the owner goroutine from Chapter 1.1, where every inbound id meets `Parse` before any map is touched. The order theorem is native — Go compares strings bytewise — and placement is five integer operations the inliner eats whole at the measured 0.9586 nanoseconds. The canon's presence is the conformance test in the module: the fleet card, renewed on every run.

## Decisions

**Contracts should record the defect classes they retire.** The minting law exists because a port drifted; writing the law into normative text turned one bug into a permanent test surface for every future port.

**Placement is never security.** The round's virtue is spread, not secrecy [1] -- the odd multiply and the xor-shift are both invertible, so truncation's 2^32 preimages are the only veil; the contract says so and this series will not blur it.

**Identities are opaque beyond the contract's accessors.** Namespace and mint instant are readable; nothing else is, by design — the moment business data rides inside an id, the id has become a record and the architecture has lost its one freely copyable value.

**One authority per fact.** This chapter reads the contract; it does not restate it normatively, and it ships no companion spec for that reason.

## References

1. Appleby, A. — SMHasher and MurmurHash3 (the public-domain finalizer family the placement hash draws its round and constant from; the finalization mix exists to "force all bits of a hash block to avalanche"): [github.com/aappleby/smhasher](https://github.com/aappleby/smhasher)
2. King, R. — Announcing Snowflake. Twitter Engineering, June 2010 (the uncoordinated, 64-bit, roughly-sortable id generator whose layout the contract hardens into exact per-node order): [blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake)
