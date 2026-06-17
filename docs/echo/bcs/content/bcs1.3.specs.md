# bcs1.3 · The ID system under storage — design and implementation (specs)

<show-structure depth="2"/>

> Authoritative for the keyspace-economics rung behind Chapter 1.3. The chapter
> ([`bcs1.3.md`](bcs1.3.md)) narrates it; the agent guide ([`bcs1.3.llms.md`](bcs1.3.llms.md)) derives
> from it. The identity contract itself is owned by `contract/contract.md` — this spec governs only how
> identities appear as **keys and stream entries** in the storage layer, and how that appearance is
> measured. Feedback edits this file, not the harnesses.
> **Status: built.** Outputs committed under `bench/valkey-id/` and `bench/branding-vs-decimal/`.

## Invariants

- **INV-K1 — branded form only.** Every store key, field, and message that carries an identity carries the 14-byte branded form. A decimal rendering of a snowflake never appears in a key or field: it is five bytes longer, one allocator class more expensive (73 against 65 on the measured table), and slower to produce in every compiled runtime (Appendix 1.1).
- **INV-K2 — the prefix is budgeted.** Every byte of a key prefix rides every key of its family. The envelope grammar is `emq:{q}:<type>:<branded>`; the measured envelope (`emq26`, 26 bytes total) costs one 16-byte class step over the bare id (81 against 65). New key families declare their prefix length and its class consequence before shipping.
- **INV-K3 — TTL is priced as object growth.** On the 8.1 table an expire is an embedded field: plus 34 bytes on the measured branded key (65 to 99), not a second table's entry. Designs that sprinkle TTLs accept that price knowingly.
- **INV-K4 — stream ids use the injection.** A branded snowflake maps onto a stream entry id as `unix_ms(snow)-(snow AND 0x3FFFFF)` — order-preserving by construction, zero cost per entry (20 bytes either way, measured), and it makes `min_for` a stream cursor. No second stream-id scheme exists beside it.
- **INV-K5 — the chooser closes on branded.** Against the requirements (in-value and in-type discriminant, lexicographic mint order, in-contract placement, fixed width, cross-runtime canon), the branded snowflake is the only candidate with every column filled — and, on the measured table, the cheapest printable form, tying binary UUID-16 at 65 bytes.
- **INV-K6 — evidence is verbatim.** Every figure the chapter prints exists character-for-character in a committed output; the figure sweep enforces it.

## Deliverables (committed)

- `bench/valkey-id/gen_resp.py` — the RESP generator: six key shapes plus the TTL variant, one million keys per run, binary-safe pipe input.
- `bench/valkey-id/valkey_id_bench.out` — the per-key table: Redis 7.0.15 against Valkey 9.1.0, both jemalloc 5.3.0, `used_memory` delta per key after settle.
- `bench/valkey-id/streams_bench.out` — the streams experiment: 200,000 entries auto against injected ids, per-entry bytes, and the ten-millisecond window count.
- `bench/branding-vs-decimal/*.out` — the five-runtime CPU record Appendix 1.1 reads; cross-referenced, not restated.
- The engine recipe: Valkey built from its `8.1.x` tag with default jemalloc; the build tree reproduces with `make`.

## Gates (inspection against the committed outputs)

| Gate | Invariant | Inspectable fact | Token in the output |
| --- | --- | --- | --- |
| G-K1 | INV-K1 | Branded beats its own decimal on the new table | `brd14 14 88 65 23` and `u64dec 19 104 73 31` |
| G-K2 | INV-K2 | The 26-byte envelope lands one class up | `emq26 26 104 81 23` |
| G-K3 | INV-K3 | The TTL row prices the embedded expire | `brd14+ttl 14 128 99 29` |
| G-K4 | INV-K4 | Injected entries cost what auto entries cost; the window returns its prediction | `per-entry=20` twice; `40960 entries (expected 40960)`; first id `1781000000010-28672` |
| G-K5 | INV-K5 | Branded ties binary UUID-16 and undercuts UUID-36 by two classes | `uuid16 16 104 65 39` and `uuid36 36 120 97 23` |
| G-K6 | INV-K6 | The chapter's sweep passes with its figure list against these files | sweep exit zero |

## Acceptance stories (folded)

**US-K1 — the storage discount holds.** As the operator of the keyspace, the builder wants the branded form to be the cheap form, so that the contract's wire shape needs no apology at scale.
- **Given** the committed per-key table, **When** the branded row is compared to the decimal and UUID rows, **Then** branded is cheapest among printable forms and ties the binary form (G-K1, G-K5).

**US-K2 — streams carry the contract for free.** As the 3.0 horizon's designer, the builder wants entry ids that are branded-derived without a per-entry tax.
- **Given** 200,000 injected entries, **When** per-entry bytes are compared to auto-id entries and a `min_for` window is ranged, **Then** the bytes match and the window count equals its arithmetic prediction (G-K4).

**US-K3 — the record reproduces.** As a future maintainer on a newer engine, the builder wants a runbook, not an artifact of faith.
- **Given** the committed generator and the engine recipe, **When** the protocol in the agent guide is re-run on a new tag, **Then** a new dated output is committed beside the old and the directional invariants (K1, K2, K3, K5) are re-checked against it — the absolute numbers may move; the directions are the spec.

## Non-goals

Cluster-mode performance and slot behavior (a correctness argument in the protocol documents, not a number here); allocators other than jemalloc 5.3.0 (class edges move with the malloc); any engine other than the decided one (the earlier second-engine line is superseded — decision of record D-1 in [`bcs.progress.md`](bcs.progress.md)); CPU measurement (owned by Appendix 1.1 and its committed outputs).

## Definition of done and coverage

Done is the committed evidence set named above, with every gate's token present and the chapter's figure sweep green. Coverage closure: each invariant K1–K6 is named by exactly one gate row; each deliverable is read by at least one gate; each story names its gates; the chapter quotes only what the gates pin.
