# B1.1 · Ownership on the BEAM — the VM holds the boundary

> Route: `/bcs/ideas/system-substrate/ownership-on-the-beam` (dive 2 of 3, module B1.1). The route-mirror
> source-of-record. Teaches the Elixir enforcement story of `content/bcs1.1.md`; every figure verbatim from
> the committed `bcs_rung_1_1_check.out`. Build stamp: `BCS0NtMiKTmrM8`.

## Hero

Kicker: `B1.1 · DIVE — OWNERSHIP ON THE BEAM`. Title: **The VM holds the boundary.** Lede — ownership is a
process property: the table is `:private`, created in `init`, its identifier never returned from any call.
The BEAM refuses outside reads at the VM layer — the same mechanism that enforces memory safety. Heronote —
source `content/bcs1.1.md` · How (Elixir, as built) and Decisions; surfaces verified in
`lib/echo_data/bcs/property_store.ex`.

### Interactive 1 — who reaches the table (hero)

An SVG of the owner process (holding the table) and an outside process. Four attempts, run as a pure lookup
over the transcript's recorded outcomes:

- **owner lookup** — the owning process reads its own row; the table answers.
- **outside lookup** — `ArgumentError`. The VM refuses.
- **outside insert** — `ArgumentError`. The VM refuses.
- **outside info** — full metadata returned, `protection: :private` included. Metadata visible, data refused.

Degrades to the static diagram plus this list.

## §1 · The private table (#private)

The table is created in `init` as `:ordered_set, :private`; its identifier never leaves the process. The G1
line, verbatim: `outside lookup -> ArgumentError, insert -> ArgumentError; info reports protection: :private
(metadata visible, data refused)`. The recorded correction (`content/bcs1.1.md` · Decisions): the draft
expected `:ets.info` on a private table to refuse outsiders alongside `lookup`; the platform returned full
metadata to a process that cannot read one row. The spec was amended first, the gate rewritten as a positive
assertion, and the clause came out sharper — a system's state is unreachable from outside; a system's
existence is nobody's secret. **The BEAM guards data, not existence**, and hiding metadata would cost
supervisors and telemetry their visibility for nothing.

## §2 · Order without a clock (#order)

`:ordered_set` sorts by Erlang term order; binaries compare bytewise; byte order on branded ids is mint order.
`page_desc` is a `prev` walk from `:ets.last` — no clock anywhere in the process. The G4 line, verbatim:
`page_desc(2000) == byte-sort desc over 2000 minted ids; store holds no clock`.

### Interactive 2 — byte order is mint order

A fixed dataset of six `BRL` ids, minted in sequence by the contract's minter for this page (oldest first):
`BRL0NtMkPRv5VY` · `BRL0NtMkUBQK0G` · `BRL0NtMkYw3x1E` · `BRL0NtMkdnnYHo` · `BRL0NtMkiWjaWO` ·
`BRL0NtMknH5cPI`. Two pure operations: **mint order** lists them as minted; **page_desc** byte-sorts
descending — the readout shows the sorted list and verifies it equals newest-first, the same comparison the
store's `prev` walk rides. Degrades to the static list.

## §3 · The init gate, and no second parser (#init)

`init` runs the canon's `self_check!` and aborts on mismatch — the G6 line, verbatim: `self_check! ->
{:ok, :native} (init gates on the same check)`. A store that cannot prove its codec refuses to start. And the
gate adds no second parser: `BrandedId.parse/1` returns `{:ok, ns, snow}` or `:error`, so classification
beyond the namespace collapses to `:invalid` by design. If the taxonomy ever sharpens on the BEAM, it sharpens
in `BrandedId`, once.

## References (#refs)

Sources: Erlang/OTP — the ets module (`https://www.erlang.org/doc/apps/stdlib/ets.html`) · The Go Project —
Share Memory By Communicating (`https://go.dev/doc/codewalk/sharemem/`) · Chassaing — Functional Event
Sourcing Decider (`https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider`).
Related: `/bcs/ideas/system-substrate` (the B1.1 hub) · `/bcs/ideas` (B1 · Ideas Behind) · `/elixir` (the
umbrella where `echo_data` lives).

## Pager

Previous: `/bcs/ideas/system-substrate/the-six-gates` — The Six Gates. Next:
`/bcs/ideas/system-substrate/the-owner-goroutine` — The Owner Goroutine.
