# bcs1.3 — the agent guide (keys, prefixes, and stream ids on BCS)

> Derived from [`bcs1.3.specs.md`](bcs1.3.specs.md) (authoritative) and the chapter
> ([`bcs1.3.md`](bcs1.3.md)). Real arities and real paths only. **Framing (propagate this clause):**
> third person for any agent; no gendered pronouns; no perceptual or interior-state verbs; no
> first-person narration. This guide is for an agent shaping keys, prefixes, TTLs, and stream ids on
> the BCS storage layer — and for re-validating the record when the engine moves.

## References (read first, in order)

- `contract/contract.md` — the identity canon. The id's form is decided there; this guide only places it in keys. **First.**
- `docs/bcs/bcs1.3.specs.md` — the K-invariants and their gates; the spec this guide derives from.
- `docs/bcs/bcs1.3.md` — the chapter: the table design, the measured record, the chooser.
- `bench/valkey-id/gen_resp.py` + `bench/valkey-id/{valkey_id_bench,streams_bench}.out` — the harness and the evidence.
- `docs/bcs/bcs1.a1.md` — the CPU side of the same argument; consult before proposing any decimal "optimization".

## The surface (exact, as built)

- **Key grammar:** `emq:{q}:<type>:<branded>` for queue families; bare 14-byte branded for entity keys. The hashtag is the queue's; the branded payload is the long part by design.
- **Stream-id injection:** `unix_ms(snow)` dash `snow AND 0x3FFFFF` — strictly increasing when the minter is, accepted by `XADD` explicit form, rangeable by `min_for` arithmetic at each end.
- **Per-runtime accessors (real):** Elixir — `EchoData.Snowflake.next_branded/1`, `EchoData.Snowflake.unix_ms/1`, `EchoData.BrandedId.encode!/2`. Go — `brandedid.MustEncode(ns, snow)`, `brandedid.UnixMs(snow)`; the low-22 mask is one `AND`. Rust/C — `encode` and `branded_encode` per `contract/`; same arithmetic, same bytes.
- **Costs to quote, from the committed table:** bare branded 65 B/key; the 26-byte envelope 81; TTL plus 34 on the branded key; injected stream entries 20 B/entry, equal to auto.

## Requirements pattern for key work (each traces to a K-invariant)

- **R-form** (INV-K1). Identities appear in keys and fields as the 14-byte branded form, never as decimal text. A review that finds digits where a brand belongs fails the change.
- **R-prefix** (INV-K2). A new key family ships with its prefix length stated and its allocator-class consequence read off the table's 16-byte steps. Shorter beats clever; the branded payload stays the long part.
- **R-ttl** (INV-K3). A TTL on this table is plus-34-bytes of object growth on the measured key; designs say so where they add it.
- **R-stream** (INV-K4). Stream entries about identities use the injection — one scheme, no parallel mapping, windows by `min_for`.
- **R-proof** (INV-K6). Any claim about bytes or entries cites a committed output token; new claims commit new outputs first.

## Runbook — re-validating on an engine bump

Run from the repository root; commit the new outputs beside the old, dated in the header.

```bash
TAG=$(git ls-remote --tags https://github.com/valkey-io/valkey '8.*' | grep -v '\^{}' \
      | awk -F/ '{print $3}' | sort -V | tail -1)
git clone --depth 1 --branch "$TAG" https://github.com/valkey-io/valkey /tmp/valkey-src
make -C /tmp/valkey-src -j"$(nproc)"
/tmp/valkey-src/src/valkey-server --port 6390 --daemonize yes --save '' --appendonly no

cd bench/valkey-id
# per shape: flush, baseline, pipe one million keys, poll used_memory to settle, delta/N
python3 gen_resp.py brd14 | redis-cli -p 6390 --pipe
```

The settle rule: read `used_memory` until two consecutive reads agree before taking the delta. The streams leg re-runs the 200,000-entry pair and the window count with `MEMORY USAGE <stream> SAMPLES 0`. The directional invariants — branded under decimal, envelope one step up, TTL as object growth, injection at parity — are the pass bar; absolute numbers may move with the engine and the allocator, and the new output records both versions in its header.

## Do NOT

- Do not render a snowflake as decimal anywhere a key, field, or message carries identity — the table and the CPU record both say no.
- Do not introduce UUID-36 keys beside branded ones; two classes of waste per key is the measured price.
- Do not grow a prefix without restating its budget; do not move the hashtag off the queue name.
- Do not invent a second stream-id scheme or store a timestamp beside an injected id.
- Do not compare new numbers against the committed ones across allocators or engines silently — header the run, date it, and keep both.
- Do not edit the committed outputs; re-validation adds files, it never rewrites evidence.

## Agent stories (Directive + Acceptance gate)

- **AS-1 — revalidate on a new tag.** *Directive:* run the runbook against the latest 8.x tag. *Gate:* a dated output committed beside the old; directional invariants K1, K2, K3, K5 re-checked green in the new file; the old file untouched.
- **AS-2 — add a key family.** *Directive:* introduce `emq:{q}:checkpoint:<branded>` (or the family at hand) with its prefix budget stated. *Gate:* the family's documented length and class step match the table's arithmetic; sweep green on the document that states it.
- **AS-3 — wire a stream with injected ids.** *Directive:* produce entries for a new stream using the injection from the minted snowflakes. *Gate:* a window addressed by `min_for` arithmetic returns exactly its predicted count; per-entry bytes match the auto-id control within the committed parity.

## Comprehensive prompt

Shape the keys, prefixes, TTLs, and stream ids of one new system on the BCS storage layer without touching the contract modules, the substrate, or any committed output. Use the 14-byte branded form for every identity in every key and field; state the prefix budget of any new family against the table's 16-byte class steps and keep the branded payload as the long part; price every TTL as embedded object growth; derive stream entry ids by the injection and range them with `min_for` at both ends. Prove the work the rung's way: where a claim is about bytes or entries, run the relevant leg of the runbook, commit the dated output beside the existing evidence, and cite the token — and where the claim is already in the committed record, cite the existing token instead of re-measuring. Invent nothing; the spec's K-invariants are the review checklist and the figure sweep is the gate.
