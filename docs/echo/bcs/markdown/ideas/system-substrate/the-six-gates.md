# B1.1 · The Six Gates — six crimes, six refusals

> Route: `/bcs/ideas/system-substrate/the-six-gates` (dive 1 of 3, module B1.1). The route-mirror
> source-of-record. Teaches the transcript of `content/bcs1.1.md` line by line; every figure verbatim from the
> committed `bcs_rung_1_1_check.out`. Build stamp: `BCS0NtMiKNpHcm`.

## Hero

Kicker: `B1.1 · DIVE — THE SIX GATES`. Title: **Six crimes, six refusals.** Lede — the rung's check script
attempts the architecture's canonical crimes on stage and records each refusal; the committed transcript
closes `PASS 6/6`. This dive reads it line by line. Heronote — source `content/bcs1.1.md`, quoting
`bcs_rung_1_1_check.out`; the check script is `bcs_rung_1_1_check.exs`.

### Interactive 1 — the gate stepper (hero)

Six cells, G1–G6, drawn as an SVG strip. Select a gate to read its verbatim transcript line in the readout,
plus the one-sentence reading of what was attempted and what refused it. Degrades to the static transcript
below.

## §1 · The transcript (#transcript)

The full committed output, verbatim (seven lines):

```text
G1 reach-through ok -- outside lookup -> ArgumentError, insert -> ArgumentError; info reports protection: :private (metadata visible, data refused)
G2 traveling-object ok -- map/tuple/integer ids -> FunctionClauseError 3/3; inter-store message carried {:entity, id} only; :burned recorded BRL0NsHLqGoDbd
G3 typed ok -- rejects 4/4 as :invalid; GRD id on BRL store -> {:error, :namespace}; raising twin -> NamespaceError
G4 ordered ok -- page_desc(2000) == byte-sort desc over 2000 minted ids; store holds no clock
G5 placed ok -- placement(USR0KHTOWnGLuC) -> 234878118
G6 canon ok -- self_check! -> {:ok, :native} (init gates on the same check)
PASS 6/6
```

## §2 · Reading the lines (#reading)

- **G1 — the reach-through.** An outside process attempts `lookup` and `insert` on the store's table; the VM
  refuses both with `ArgumentError`. `info` reports full metadata — `protection: :private` included — to a
  process that cannot read one row: metadata visible, data refused. The ownership dive reads the mechanism.
- **G2 — the traveling object.** Map, tuple, and integer ids die in pattern matching — `FunctionClauseError`
  3/3 — before any store code runs. The inter-store message carried `{:entity, id}` only; the receiving store
  recorded `:burned` under `BRL0NsHLqGoDbd`. Identities cross the boundary; objects do not.
- **G3 — typed.** Four malformed inputs reject 4/4 as `:invalid`; a `GRD` id presented to the `BRL` store is a
  typed refusal, `{:error, :namespace}`; the raising twin raises `NamespaceError`. The taxonomy is coarser than
  the wire contract's four atoms by decision — no second parser.
- **G4 — ordered.** `page_desc(2000)` equals byte-sort descending over 2000 minted ids; the store holds no
  clock. Chronology comes from the keys.
- **G5 — placed.** `placement(USR0KHTOWnGLuC)` → `234878118` — the contract's canonical vector, reproduced by
  the store's arithmetic.
- **G6 — canon.** `self_check!` → `{:ok, :native}`; init gates on the same check, so a store that cannot prove
  its codec refuses to start.

## §3 · Interactive 2 — the gate, exercised (#exercise)

A model of the boundary path — shape check, parse, namespace check, in that order — run as a pure function
over five fixed candidates presented to a `BRL` store:

- `BRL0NsHLqGoDbd` (the id G2 recorded) → admitted, `{:ok, snowflake}`.
- `USR0KHTOWnGLuC` (the contract's canonical `USR` vector) → `{:error, :namespace}` — parses cleanly, wrong
  namespace for this store.
- `{:entity, 42}` (a tuple, not a binary) → `FunctionClauseError` — refused before the gate runs.
- `BRL-NOT-AN-ID!` (14 bytes, bad charset) → `{:error, :invalid}`.
- `BRL0NsHLqGo` (11 bytes) → `{:error, :invalid}` — length is part of the contract: 14 bytes, fixed.

The readout names the check that fired. The classification collapses everything past the namespace to
`:invalid`, exactly as `parse/1` reports it. Degrades to this static list.

## References (#refs)

Sources: Erlang/OTP — the ets module (`https://www.erlang.org/doc/apps/stdlib/ets.html`) · The Go Project —
Share Memory By Communicating (`https://go.dev/doc/codewalk/sharemem/`) · Chassaing — Functional Event
Sourcing Decider (`https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider`).
Related: `/bcs/ideas/system-substrate` (the B1.1 hub) · `/bcs/ideas` (B1 · Ideas Behind) · `/bcs` (course
home).

## Pager

Previous: `/bcs/ideas/system-substrate` — B1.1 · the hub. Next:
`/bcs/ideas/system-substrate/ownership-on-the-beam` — Ownership on the BEAM.
