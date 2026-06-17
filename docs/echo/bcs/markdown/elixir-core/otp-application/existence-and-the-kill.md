# B2.1.2 · Existence and the Kill — what restarts, what survives

> Route: `/bcs/elixir-core/otp-application/existence-and-the-kill` (dive 2 of B2.1). The route-mirror
> source-of-record. Teaches `content/bcs2.1.md` (R2 + R3); every figure verbatim from the committed
> `bcs_rung_2_1_check.out`. Build stamp: `BCS0NuRxoCr3WS`.

## Hero

Kicker: `B2.1 · dive — existence and the kill`. Title: **Existence restored, data not.** Lede — R2 kills the
portfolio store mid-flight: the supervisor restores the process, and the row written before the kill is gone.
The BEAM guards data, not existence; the supervision tree guards existence; and a private ETS table dies with
its owner — by design. R3 then recovers the row the only legitimate way. Heronote — source:
`content/bcs2.1.md`, quoting `bcs_rung_2_1_check.out`; the store's init is committed at
`lib/echo_data/bcs/property_store.ex`.

### The kill, step by step (interactive SVG)

The R2/R3 sequence drawn as a timeline. Select a step to read what the rung recorded at that point:

1. **put** — a row written through the boundary; the id gates before the table is touched.
2. **read back** — the row read through the API; this copy is the checkpoint R3 spends later.
3. **kill** — the owner dies mid-flight; the private table dies with it.
4. **restart** — the supervisor restores the process: `existence restored, data not: fresh table after kill`.
5. **re-put** — R3: `recovered through the boundary, not the heap: re-put from a read-back row`.

Degrades to a static numbered list without JavaScript.

## §1 · The transcript (#transcript)

The full committed record (`bcs_rung_2_1_check.out`), verbatim; this dive reads R2 and R3:

```text
boot: two stores under one_for_one; native codec self-check passed at each init
R1 surface ok -- exports: six domain functions plus OTP callbacks, nothing else -- no table, no pid, no internals
R2 existence ok -- existence restored, data not: fresh table after kill -- durability is a different chapter's job
R4 radius ok -- sibling untouched (one_for_one): ord_store pid stable, row intact through prt_store's crash
R3 checkpoint ok -- recovered through the boundary, not the heap: re-put from a read-back row
R5 gate ok -- prt_store refuses an ORD name with {:error, :namespace} -- admitted kinds are per-boundary
PASS 5/5
```

## §2 · R2 — existence is the supervisor's; data is deliberately not (#r2)

Source: `content/bcs2.1.md` · What. R2 kills the portfolio store mid-flight: the supervisor restores the
process, and the row written before the kill is gone — `existence restored, data not: fresh table after kill`.
This is the Part I correction matured into policy. The BEAM guards data, not existence; the supervision tree
guards existence; and a private ETS table dies with its owner [2] — *by design*, because durability is a
different chapter's job: the manuscript routes it to the deferred persistence adapter (Chapter 2.6, planned)
and to replay from the bus (Part III, planned). A restart is a clean slate unless the design said otherwise.
The fresh table is the init path re-running, committed verbatim in `property_store.ex`:

```elixir
def init(ns) do
  {:ok, _mode} = BrandedId.self_check!()
  table = :ets.new(:bcs_props, [:ordered_set, :private])
  {:ok, %{ns: ns, table: table}}
end
```

The boot line carries the other inheritance: `native codec self-check passed at each init` — a store refuses
to exist before the canon proves itself, which is clause three applied to startup. The one recorded exception
to the clean slate — the heir-held table, an ETS table that survives its owner via an inheritor — trades the
clean-slate guarantee for warm-cache latency, and the trade deserves its sentence too. None of the systems in
this part make it.

## §3 · R3 — checkpoints are rows, not memories (#r3)

Source: `content/bcs2.1.md` · What. R3 reads a row back through the API before the kill, loses it in the
crash, and recovers it the only legitimate way — `recovered through the boundary, not the heap: re-put from a
read-back row`. State that must survive a process lives in a store: this system's, another system's, or the
bus's log. Process state is working memory; anything load-bearing in it is a checkpoint that has not been
written yet. R3 is the only recovery path the architecture recognizes.

### Custody (interactive)

A pure lookup over the chapter's custody table. Select a thing the running system holds; the readout names its
guardian and the transcript line that proves it:

- **the process** — guarded by the supervision tree; R2's restart.
- **the table's rows** — guarded by nothing across a crash, by design; R2's fresh table.
- **a read-back row** — a checkpoint; recovered by re-put through the boundary; R3.
- **durability** — a different chapter's job; routed to rows, not heaps (Chapter 2.6 planned, Part III
  planned).

Static verdicts are printed below the control for the no-JS reading.

## References (#refs)

Sources: Erlang/OTP — the ets module (`https://www.erlang.org/doc/apps/stdlib/ets.html`) · Erlang/OTP — the
supervisor behaviour (`https://www.erlang.org/doc/apps/stdlib/supervisor.html`).
Related: `/bcs/elixir-core/otp-application` (B2.1 — the module hub) · `/bcs/elixir-core` (B2 — the chapter
landing) · `/bcs` (course home) · `/elixir` (the umbrella where `echo_data` lives).

## Pager

Previous: `/bcs/elixir-core/otp-application/the-export-list` — The Export List. Next:
`/bcs/elixir-core/otp-application/the-blast-radius` — The Blast Radius.
