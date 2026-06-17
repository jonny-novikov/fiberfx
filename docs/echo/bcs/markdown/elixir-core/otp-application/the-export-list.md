# B2.1.1 · The Export List — the boundary, and the kinds it admits

> Route: `/bcs/elixir-core/otp-application/the-export-list` (dive 1 of B2.1). The route-mirror
> source-of-record. Teaches `content/bcs2.1.md` (R1 + R5); every figure verbatim from the committed
> `bcs_rung_2_1_check.out`. Build stamp: `BCS0NuRxo7Sg3E`.

## Hero

Kicker: `B2.1 · dive — the export list`. Title: **Six functions, and a wall.** Lede — a system exports
functions over identities and exports nothing else — the sentence from the Part II preface, now gated. R1
inspects the store module's actual surface; R5 proves the surface refuses kinds it never declared. Heronote —
source: `content/bcs2.1.md`, quoting `bcs_rung_2_1_check.out`; the substrate modules are committed at
`lib/echo_data/bcs/`.

### The surface, exported and not (interactive SVG)

The export list drawn as a wall with six openings; the private table behind it. Select an entry to read its
exact surface in the readout:

- `start_link/1` — boots the store under a name and a namespace; the supervisor calls it, callers never hold
  the pid that comes back.
- `put/3` — writes a value under a branded id; the id gates before the table is touched.
- `get/2` — reads a value by branded id; the same gate runs first.
- `page_desc/2` — newest-first paging, a `prev` walk from the table's end; no clock in the process.
- `record_entity/2` — the cast that records an entity id; the gate runs in the handler, a refused id is a
  no-op.
- `placement/1` — the contract's arithmetic: parse, then `hash32` over the snowflake.
- **never exported** — the table (`protection: :private`), any pid, any internal record shape.

Degrades to a static labelled diagram without JavaScript.

## §1 · The transcript (#transcript)

The full committed record (`bcs_rung_2_1_check.out`), verbatim; this dive reads R1 and R5:

```text
boot: two stores under one_for_one; native codec self-check passed at each init
R1 surface ok -- exports: six domain functions plus OTP callbacks, nothing else -- no table, no pid, no internals
R2 existence ok -- existence restored, data not: fresh table after kill -- durability is a different chapter's job
R4 radius ok -- sibling untouched (one_for_one): ord_store pid stable, row intact through prt_store's crash
R3 checkpoint ok -- recovered through the boundary, not the heap: re-put from a read-back row
R5 gate ok -- prt_store refuses an ORD name with {:error, :namespace} -- admitted kinds are per-boundary
PASS 5/5
```

## §2 · R1 — the boundary is the export list (#r1)

Source: `content/bcs2.1.md` · What. R1 inspects the store module's actual surface and finds `exports: six
domain functions plus OTP callbacks, nothing else` — `start_link/1`, `put/3`, `get/2`, `page_desc/2`,
`record_entity/2`, `placement/1`, and the behaviour's own callbacks; no table reference escapes, no pid is
handed out, no internal record leaks its shape. What a system never exports is the more important half: the
table (`protection: :private` in the substrate's own gate record) and anything whose shape would couple a
caller to a representation. For agents, R1's surface is the whole callable world: what the export list does
not say, an agent may not call. The export list is the boundary contract — adding an export is an architecture
change with R1 as its gate, not a convenience landing in a diff; **Property Stores on ETS** (B2.2) performs
that review once, on stage.

## §3 · R5 — the boundary declares its kinds (#r5)

Source: `content/bcs2.1.md` · What; the gate is `EchoData.Bcs.gate/2`, committed at `lib/echo_data/bcs.ex`. R5
offers the portfolio store an `ORD` name and is refused with `{:error, :namespace}` — admitted namespaces are
a per-boundary property, checked at every ingress, exactly as Chapter 1.2 placed clause three. One system, one
table, one declared kind set; the silent join has no door here. The committed gate, verbatim:

```elixir
def gate(id, ns) when is_binary(id) and is_binary(ns) do
  case BrandedId.parse(id) do
    {:ok, ^ns, snow} -> {:ok, snow}
    {:ok, _other, _snow} -> {:error, :namespace}
    :error -> {:error, :invalid}
  end
end
```

No second parser: classification beyond the namespace collapses to `:invalid`, exactly as
`EchoData.BrandedId.parse/1` reports it.

### The kind gate, exercised (interactive)

A pure model of `gate/2` on `prt_store`, whose declared kind set is `PRT`. Select a presented kind: a `PRT`
name is admitted `{:ok, snowflake}`; an `ORD` name — the rung's own crime — refuses `{:error, :namespace}`; an
`AST` or `TXN` name refuses the same way, per-boundary; a non-id shape collapses to `{:error, :invalid}`.
Static verdicts are printed below the control for the no-JS reading.

## References (#refs)

Sources: Erlang/OTP — the supervisor behaviour (`https://www.erlang.org/doc/apps/stdlib/supervisor.html`) ·
Erlang/OTP — the ets module (`https://www.erlang.org/doc/apps/stdlib/ets.html`).
Related: `/bcs/elixir-core/otp-application` (B2.1 — the module hub) · `/bcs/elixir-core` (B2 — the chapter
landing) · `/bcs` (course home) · `/elixir` (the umbrella where `echo_data` lives).

## Pager

Previous: `/bcs/elixir-core/otp-application` — B2.1 · the hub. Next:
`/bcs/elixir-core/otp-application/existence-and-the-kill` — Existence and the Kill.
