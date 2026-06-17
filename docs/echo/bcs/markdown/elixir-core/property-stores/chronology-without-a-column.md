# B2.2.2 · Chronology Without a Column — the order theorem as a read path

> Route: `/bcs/elixir-core/property-stores/chronology-without-a-column` (dive 2 of 3, module B2.2). The
> route-mirror source-of-record. Teaches P3–P4 of `content/bcs2.2.md`; every figure verbatim from the committed
> `bcs_rung_2_2_check.out` and the real `property_store.ex`. Build stamp: `BCS0NuRyZggxVY`.

## Hero

Kicker: `B2.2 · DIVE 2 — CHRONOLOGY WITHOUT A COLUMN`. Title: **The order theorem as a read path.** Lede —
three hundred `ORD` mints across real wall time; the newest five by byte order equal the last five minted, and
a half-open window `[lo, hi)` built from two synthetic cursors returns `100 of 100 expected, ascending by
key`. No timestamp column. No sort call. Heronote — source `content/bcs2.2.md`, quoting
`bcs_rung_2_2_check.out` (lines P3, P4); the select runs in `property_store.ex`, grown by `window/3`.

### Interactive 1 — the tail walk (hero)

A model: twelve mints across four minutes of one afternoon, 14:29–14:33 UTC (the rung's own run minted three
hundred). Each instant is encoded into a real `ORD` id by the contract's arithmetic — `ts << 22`, Base62,
11 chars — and the twelve keys are drawn as an SVG tape in byte order. Choose `page_desc(3)`, `page_desc(5)`,
or `page_desc(8)`: the readout walks the table tail and shows the newest page, computed by comparing the
encoded keys as bytes — no timestamp consulted. The newest n by byte order equal the last n minted. Degrades
to the static tape plus a static description.

## §1 · The transcript (#transcript)

Lines P3 and P4 of the committed output, verbatim:

```text
P3 order ok -- newest five by byte order equal the last five minted: no timestamp column consulted
P4 window ok -- window [tA,tB) by synthetic cursors returned 100 of 100 expected, ascending by key
```

P3: three hundred `ORD` mints spread across real wall time, then the newest five — `page_desc/2` walking the
table tail, the order theorem as a read path. P4 is the chapter's center: two wall-clock instants captured
mid-mint, two synthetic cursors built by the same `min_for` arithmetic every runtime shares (Chapter 1.5), and
the new `window/3` answering — exactly the mints between the instants, by construction and by gate.

## §2 · The match spec (#spec)

The implementation is a gated match specification, verbatim from `property_store.ex`:

```elixir
def handle_call({:window, lo, hi}, _from, s) do
  with {:ok, _} <- EchoData.Bcs.gate(lo, s.ns),
       {:ok, _} <- EchoData.Bcs.gate(hi, s.ns) do
    spec = [{{:"$1", :_}, [{:>=, :"$1", {:const, lo}}, {:<, :"$1", {:const, hi}}], [:"$1"]}]
    {:reply, {:ok, :ets.select(s.table, spec)}, s}
  else
    {:error, _} = err -> {:reply, err, s}
  end
end
```

Both bounds pass through the gate first — window bounds are ingress, and a bound in the wrong namespace is
refused before the table is touched. Term order over binaries is byte order, so the theorem does the sorting
and the guards do the cutting; the result order is the table's, not a sort call's. Correctness is gated; range
*cost* is not — `:ets.select` with comparison guards is not promised to seek to the lower bound, so very large
tables earn a seeded `:ets.next/2` walk from `lo` as the optimization lane, carried as a follow-up rather than
smuggled into this rung.

## §3 · Interactive 2 — the window, exercised (#window)

Over the same twelve model mints: pick a half-open window and read what `[lo, hi)` returns. The two cursors
are synthesized by `min_for` — the floor id of the instant, node 0, seq 0 — and the membership test is two
byte comparisons per key, `lo <= key < hi`:

- `[14:30, 14:32)` → 8 of 12, ascending by key.
- `[14:29, 14:30)` → 2 of 12 — the half-open right end excludes the 14:30 floor itself.
- `[14:31, 14:33)` → 6 of 12.
- `[14:31, 14:31)` → 0 — `[lo, lo)` is empty by construction.

The readout prints both synthesized cursors and the returned keys. Degrades to this static list.

## §4 · The Go counterpart (#go)

Verbatim from `content/bcs2.2.md` — the owner goroutine from Chapter 1.1 keeps its keys in a sorted slice,
and the window is two binary searches and a copy:

```go
lo := brandedid.MustEncode("ORD", minFor(t0))
hi := brandedid.MustEncode("ORD", minFor(t1))
i := sort.SearchStrings(keys, lo)
j := sort.SearchStrings(keys, hi)
window := append([]string(nil), keys[i:j]...) // [lo, hi), ascending
```

Same grammar, same bytes, same half-open contract on both sides of the bus.

## References (#refs)

Sources: Erlang/OTP — the ets module (`https://www.erlang.org/doc/apps/stdlib/ets.html`; ordered_set
term-order traversal, select/2 and match specifications). Related: `/bcs/elixir-core/property-stores` (the
B2.2 hub) · `/bcs/elixir-core` (B2 · The Elixir BCS Core) · `/bcs` (course home) · `/redis-patterns` (the
storage economics under the keyspace).

## Pager

Previous: `/bcs/elixir-core/property-stores/the-only-key` — B2.2.1 · The Only Key. Next:
`/bcs/elixir-core/property-stores/the-review-performed` — B2.2.3 · The Review, Performed.
