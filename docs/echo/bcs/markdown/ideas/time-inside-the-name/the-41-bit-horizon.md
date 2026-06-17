# B1.5.1 · The 41-Bit Horizon — dive

Route: `/bcs/ideas/time-inside-the-name/the-41-bit-horizon` · teaches manuscript chapter `content/bcs1.5.md`
(the arithmetic + the horizon decision).

## Hero

Kicker: B1.5 · dive — the 41-bit horizon

H1: September **2093**, recorded.

Lede: The layout grants 41 bits of milliseconds above a 2024-01-01 epoch (`1704067200000`); 2^41 milliseconds
is about 69.7 years, so the timestamp field exhausts in September 2093. **The horizon is recorded here rather
than discovered later** — seventy years is enough runway to make the successor epoch a planned chapter, never
an incident.

Heronote: Source: content/bcs1.5.md · What and Decisions; the epoch and the layout are the contract's
(content/vectors.json: epoch_ms 1704067200000, timestamp_bits 41).

Hero interactive: **the horizon, stepped** — a four-stop timeline (the epoch · the field · the exhaustion ·
the successor), each stop a readout of what the contract grants at that point. Pure lookup; SVG timeline;
static text readable without JS.

## §1 — The arithmetic, stated plainly (content/bcs1.5.md · What)

41 bits of milliseconds above `1704067200000` (2024-01-01). 2^41 milliseconds ≈ 69.7 years. The field exhausts
in September 2093. Nothing here is an estimate of load or a guess about growth — the horizon is a property of
the layout, computable on the day the contract was signed.

Frozen evidence (content/vectors.json · epoch_ms + layout):

```
epoch_ms        1704067200000
timestamp_bits  41
node_bits       10
sequence_bits   12
```

## §2 — The field, consumed (interactive)

A budget computer over three fixed checkpoints, all from committed sources: the epoch itself (zero
milliseconds consumed), the canonical decode vector's millisecond (`1780512970164` — `vectors.json` reads it
from `USR0NgWEfAEJfs`), and the field's last millisecond (2^41 − 1 above the epoch). For each checkpoint the
readout computes milliseconds above the epoch and the fraction of the 41-bit field consumed — pure BigInt
arithmetic over the contract's constants.

Static reading: the canonical vector sits 76,445,770,164 ms above the epoch — about 3.5 percent of the field;
the remaining 96.5 percent runs to September 2093.

## §3 — The successor epoch, planned (content/bcs1.5.md · Decisions)

A successor epoch is a contract amendment with a wire-version bump and a drain-and-switch lane — the same
shape the EchoMQ migration already uses. The decision of record: **the horizon is 2093 and recorded; the
successor epoch is a planned amendment riding the existing wire-version lane, not an emergency.** Where the
drain-and-switch lane itself is taught — versioned wire formats, two-way fences — the depth belongs to the
EchoMQ course.

## References

Sources:
- Lamport — Time, Clocks, and the Ordering of Events in a Distributed System (1978):
  https://dl.acm.org/doi/10.1145/359545.359563 — the foundation the next dive stands on.
- Valkey documentation — Streams introduction: https://valkey.io/topics/streams-intro/ — stream entry ids
  carry the millisecond; the same 41-bit reasoning applies to their range arithmetic.

Related:
- `/bcs/ideas/time-inside-the-name` — the module hub.
- `/bcs/ideas/identity-contract` — B1.2, the layout and the minting law the horizon is computed from.
- `/echomq` — the migration lane the successor epoch rides.

## Pager

prev: `/bcs/ideas/time-inside-the-name` (B1.5 · The Time Inside the Name) · next:
`/bcs/ideas/time-inside-the-name/the-law-of-two-clocks` (B1.5.2 · The Law of Two Clocks)

Stamp: `BCS0NtfEw21nI8` (decoded ts 2026-06-11 17:01:02 UTC)
