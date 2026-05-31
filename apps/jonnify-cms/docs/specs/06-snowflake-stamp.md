# 06 — The branded Snowflake stamp

This document specifies `internal/snowflake` and the `cms stamp mint` / `cms stamp decode`
commands. The branded stamp is the 14-character build id every course page carries in its
footer and the cross-system pivot-key convention the course uses (the subject of module
F4.07). It is a 3-character namespace prefix followed by a base62 encoding of a 64-bit
Snowflake. This is a direct port of the Snowflake functions in `build_page.py`.

## 1. Constants

```go
const (
    // EpochMS is the custom epoch: 2024-01-01T00:00:00Z, in milliseconds.
    EpochMS int64 = 1_704_067_200_000

    // B62 is the base62 alphabet: digits, uppercase, then lowercase.
    B62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

    // B62Width is the fixed left-zero-padded width of the encoded Snowflake.
    B62Width = 11

    // Bit layout shifts and masks.
    TSShift   = 22      // timestamp occupies bits 63..22
    NodeShift = 12      // node occupies bits 21..12
    NodeMask  = 0x3FF   // 10 bits
    SeqMask   = 0xFFF   // 12 bits

    // NSWidth is the namespace prefix length.
    NSWidth = 3
)
```

The alphabet order is significant: `0-9` (values 0–9), `A-Z` (10–35), `a-z` (36–61). It is the
canonical base62 ordering and must not be reordered, or ids will not round-trip with the
on-page decoder or the Python source.

## 2. Bit layout

A Snowflake is a 64-bit unsigned integer composed from a millisecond timestamp relative to the
epoch, a 10-bit node id, and a 12-bit sequence:

```
 63                         22 21        12 11         0
┌─────────────────────────────┬───────────┬────────────┐
│   relative_ms  (41 bits)    │ node (10) │  seq (12)  │
└─────────────────────────────┴───────────┴────────────┘

snowflake = (relative_ms << 22) | ((node & 0x3FF) << 12) | (seq & 0xFFF)
relative_ms = unix_ms - EpochMS
```

41 bits of relative milliseconds covers roughly 69.7 years from the epoch (to ~2093),
comfortably beyond any course-content horizon. `node` and `seq` default to `0` for build ids;
they exist so the same scheme can mint collision-resistant ids across machines and within a
millisecond when used as a general pivot key.

## 3. Encode and decode

### 3.1 base62

Port of `b62_encode` / `b62_decode`.

```go
// EncodeB62 encodes a non-negative integer in base62, left-zero-padded to width.
func EncodeB62(n uint64, width int) string

// DecodeB62 decodes a base62 string to its integer value.
func DecodeB62(s string) (uint64, error)
```

- `EncodeB62`: for `n == 0` the core is `"0"`; otherwise repeatedly `divmod` by 62, prepending
  `B62[r]`. Left-pad with `'0'` to `width` (`B62Width = 11` for Snowflakes). A negative input
  is impossible (`uint64`); the Python `ValueError("snowflake must be non-negative")`
  corresponds to the type constraint.
- `DecodeB62`: fold `n = n*62 + indexOf(ch)` over the string. A character not in `B62` is an
  error (`invalid base62 character %q`). Decoding ignores width — it reads however many
  characters are given (the 11-char body, after the namespace is split off).

### 3.2 Snowflake compose/decompose

```go
// Snowflake composes a 64-bit id from a millisecond timestamp, node, and seq.
func Snowflake(tsMS int64, node, seq uint64) (uint64, error)
```

Port of `snowflake`: `rel := tsMS - EpochMS`; if `rel < 0` return an error
(`timestamp predates the snowflake epoch`); else
`(uint64(rel) << TSShift) | ((node & NodeMask) << NodeShift) | (seq & SeqMask)`.

Decomposition (used by decode): `ts := snow >> TSShift`,
`node := (snow >> NodeShift) & NodeMask`, `seq := snow & SeqMask`, and the absolute time is
`EpochMS + ts` milliseconds.

### 3.3 branded mint / decode

```go
// Mint produces a branded id: a 3-char namespace + base62(snowflake) padded to 11 = 14 chars.
func Mint(ns string, node, seq uint64, at time.Time) (string, error)

// DecodeBranded reverses a branded id to its parts.
func DecodeBranded(branded string) (Decoded, error)

type Decoded struct {
    Branded   string `json:"branded"`
    Namespace string `json:"namespace"`
    Snowflake uint64 `json:"snowflake"`
    Node      uint64 `json:"node"`
    Seq       uint64 `json:"seq"`
    Timestamp string `json:"timestamp"` // "YYYY-MM-DD HH:MM:SS UTC"
}
```

- `Mint` (port of `mint`): require `len(ns) == NSWidth` (else error
  `namespace prefix must be exactly 3 characters`). Convert `at` to UTC, compute
  `tsMS = at.UnixMilli()`, then `ns + EncodeB62(Snowflake(tsMS, node, seq), B62Width)`. When the
  caller passes the zero `time.Time`, the command layer substitutes `time.Now().UTC()` (the
  Python `at or now` default; the package function takes an explicit time so it stays
  deterministic and testable).
- `DecodeBranded` (port of `decode`): split into `ns = branded[:3]` and `body = branded[3:]`;
  `snow = DecodeB62(body)`; decompose into `ts`, `node`, `seq`; format the absolute time as
  `EpochMS + ts` milliseconds in UTC, `"2006-01-02 15:04:05 UTC"`. A branded id shorter than 4
  characters, or a body with an invalid base62 character, is an error.

Timestamp formatting: convert `(EpochMS + ts)` ms to a `time.Time` in UTC and format with the
layout `2006-01-02 15:04:05` plus a literal ` UTC` suffix — reproducing the Python
`strftime("%Y-%m-%d %H:%M:%S UTC")`.

## 4. Canonical vector

The reference value, from `build_page.py` and the course brief, must round-trip exactly:

| Field | Value |
|---|---|
| Branded id | `TSK0KHTOWnGLuC` |
| Namespace | `TSK` |
| Snowflake | `274557032793636864` |
| Node | `0` |
| Seq | `0` |
| Timestamp | `2026-01-27 15:11:37 UTC` |

So `Mint("TSK", 0, 0, 2026-01-27T15:11:37Z) == "TSK0KHTOWnGLuC"` and
`DecodeBranded("TSK0KHTOWnGLuC")` yields the row above. This vector is the package's primary
golden test. Note the example also demonstrates the 14-char width: `TSK` (3) +
`0KHTOWnGLuC` (11).

## 5. `cms stamp mint`

```
cms stamp mint [--ns TSK] [--node 0] [--seq 0] [--at ISO8601]
```

Port of `cmd_id` mint branch.

- `--ns` (default `TSK`): the 3-character namespace prefix. A non-3-character value is an error
  (exit `2`).
- `--node` (default `0`): the 10-bit node id (masked to 10 bits).
- `--seq` (default `0`): the 12-bit sequence (masked to 12 bits).
- `--at` (default: now): an ISO-8601 timestamp, e.g. `2026-01-27T15:11:37Z`. Parsed and
  converted to UTC; absent, `time.Now().UTC()` is used. The Python accepts
  `datetime.fromisoformat`; the Go parser accepts RFC 3339 (`time.RFC3339`) and, for parity
  with `fromisoformat`, a space-separated variant — document RFC 3339 as the supported form.

Output: the 14-character branded id on a single line (matching the Python, which prints the
id alone).

```
$ cms stamp mint
TSK7Q2vHs3kQ9P
$ cms stamp mint --ns TSK --at 2026-01-27T15:11:37Z
TSK0KHTOWnGLuC
```

Exit `0` on success; `2` on a bad `--ns` (wrong length), an unparseable `--at`, or an `--at`
before the epoch.

## 6. `cms stamp decode`

```
cms stamp decode BRANDED
```

Port of `cmd_id` decode branch. Decode the branded id and print each field as `key: value`,
the key left-padded to 11 (matching the Python `f"{k:<11}: {v}"`):

```
$ cms stamp decode TSK0KHTOWnGLuC
branded    : TSK0KHTOWnGLuC
namespace  : TSK
snowflake  : 274557032793636864
node       : 0
seq        : 0
timestamp  : 2026-01-27 15:11:37 UTC
```

Field order: `branded`, `namespace`, `snowflake`, `node`, `seq`, `timestamp`. Exit `0` on
success; `2` on a malformed id (too short, invalid base62 character, or an epoch-relative
timestamp that overflows the layout).

## 7. On-page decoder parity

Every built page renders the build id in a footer **stamp** widget (`.stamp`) that decodes the
id **client-side** to its timestamp, so the page is self-describing without the tool. The
on-page JavaScript decoder must produce the same namespace/snowflake/node/seq/timestamp that
`cms stamp decode` does, from the same constants:

- the same epoch (`1704067200000`),
- the same base62 alphabet and ordering,
- the same shifts/masks (`>> 22`, `>> 12 & 0x3FF`, `& 0xFFF`),
- the same UTC timestamp format.

This is a parity requirement, not a separate implementation owned by `cms`: the page script,
the Python source, and `internal/snowflake` are three encoders of one scheme and must agree on
the canonical vector in §4. `cms build` injects the id (`{{BUILD_ID}}`) and its decoded
timestamp (`{{BUILD_TS}}`) at assembly time (`docs/specs/05-build-validate.md` §3), and the
on-page decoder re-derives the same timestamp at view time; a mismatch between the two is a
parity bug in whichever encoder diverged.

## 8. Determinism and safety

- `Mint` is deterministic given an explicit `at`; only the default (now) is time-varying. CLI
  output is reproducible with `--at`.
- All arithmetic is on `uint64`/`int64`; the 41-bit relative-ms field cannot overflow 64 bits
  for any in-range time, and `node`/`seq` are masked, so a caller cannot corrupt adjacent
  fields by passing an over-wide value.
- No allocation-heavy or locale-dependent formatting: base62 uses the fixed ASCII alphabet and
  the timestamp uses a fixed UTC layout, so output bytes are stable across platforms.
