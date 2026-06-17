# B2.1 · A System Is an OTP Application — the noun, given a runtime shape

> Route: `/bcs/elixir-core/otp-application` (module hub, B2.1). The route-mirror source-of-record. Teaches
> `content/bcs2.1.md`; every figure verbatim from the committed `bcs_rung_2_1_check.out` (`PASS 5/5`).
> Build stamp: `BCS0NuRxo0vu3k`.

## Hero

Kicker: `B2.1 · A SYSTEM IS AN OTP APPLICATION — manuscript chapter 2.1`. Title: **The noun, given a runtime
shape.** Lede — "system" was Part I's load-bearing noun, and OTP is where the noun acquires a runtime shape: a
supervised process owning a table behind an export list. Chapter 1.1 built the skeleton and promised the full
treatment; this chapter delivers it without changing a line of the skeleton — which is the claim. Heronote —
the chapter is `content/bcs2.1.md`; the rung behind it is bcs2.1, and its committed transcript closes
`PASS 5/5`. Boundary, tree, ownership, restart semantics — each a decision made explicit and gated on stage.

### The five gates, mapped to the dives (interactive SVG)

Five gates over the unchanged substrate, drawn in transcript order (R1, R2, R4, R3, R5). Select a gate to read
its verbatim line and the dive that teaches it:

- **R1** — `exports: six domain functions plus OTP callbacks, nothing else -- no table, no pid, no internals`
  → dive 1, The Export List.
- **R2** — `existence restored, data not: fresh table after kill -- durability is a different chapter's job`
  → dive 2, Existence and the Kill.
- **R4** — `sibling untouched (one_for_one): ord_store pid stable, row intact through prt_store's crash`
  → dive 3, The Blast Radius.
- **R3** — `recovered through the boundary, not the heap: re-put from a read-back row` → dive 2.
- **R5** — `prt_store refuses an ORD name with {:error, :namespace} -- admitted kinds are per-boundary`
  → dive 1.

Degrades to a static labelled diagram without JavaScript.

## §1 · Why — decisions, not accidents (#why)

Source: `content/bcs2.1.md` · Why. The stakes are not abstract on a trading platform — when the position store
crashes at 14:30 with the book open, *what restarts, what survives, and what cascades* is a design decision
with money attached, and a design decision that was never written down is still a design, only an accidental
one. This chapter writes the defaults down and proves each on stage, so that every Part II system after it
inherits decisions rather than accidents. Four written defaults: data dies with the owner, by design ·
checkpoints are rows · `one_for_one` is the default, wider is a written claim · the export list is the
boundary contract.

## §2 · The proof (#proof)

The full committed transcript (`content/bcs2.1.md`, quoting `bcs_rung_2_1_check.out`), verbatim — it prints in
the order boot, R1, R2, R4, R3, R5:

```text
boot: two stores under one_for_one; native codec self-check passed at each init
R1 surface ok -- exports: six domain functions plus OTP callbacks, nothing else -- no table, no pid, no internals
R2 existence ok -- existence restored, data not: fresh table after kill -- durability is a different chapter's job
R4 radius ok -- sibling untouched (one_for_one): ord_store pid stable, row intact through prt_store's crash
R3 checkpoint ok -- recovered through the boundary, not the heap: re-put from a read-back row
R5 gate ok -- prt_store refuses an ORD name with {:error, :namespace} -- admitted kinds are per-boundary
PASS 5/5
```

The substrate's three modules (`bcs.ex`, `bcs/property_store.ex`, `bcs/supervisor.ex`) already are an OTP
application in everything but the `Application` callback module — the proper callback module arrives with the
umbrella adoption rung, where a Mix project exists to declare it in. The boot line carries clause three applied
to startup: `native codec self-check passed at each init` — a store refuses to exist before the canon proves
itself. The evidence stands beside `bcs_rung_1_1_check.out`: the skeleton's six gates, re-running green under
the grown surface.

## §3 · The dives (#dives)

- **The Export List** (`the-export-list`) — R1: the boundary is the export list — `start_link/1`, `put/3`,
  `get/2`, `page_desc/2`, `record_entity/2`, `placement/1` plus OTP callbacks, nothing else; the private table
  never exported. R5: the boundary declares its kinds — `prt_store` refuses an `ORD` name with
  `{:error, :namespace}`.
- **Existence and the Kill** (`existence-and-the-kill`) — R2: existence restored, data not — the BEAM guards
  data, not existence; a private ETS table dies with its owner, by design. R3: recovered through the boundary,
  not the heap — checkpoints are rows.
- **The Blast Radius** (`the-blast-radius`) — R4: sibling untouched under `one_for_one`; start order as the
  dependency declaration; strategy as a written claim; the Go `supervise` loop.

## References (#refs)

Sources: Erlang/OTP — the supervisor behaviour (`https://www.erlang.org/doc/apps/stdlib/supervisor.html`) ·
Erlang/OTP — the ets module (`https://www.erlang.org/doc/apps/stdlib/ets.html`).
Related: `/bcs/elixir-core` (B2 · The Elixir BCS Core) · `/bcs` (course home) · `/elixir` (the umbrella where
`echo_data` lives).

## Pager

Previous: `/bcs/elixir-core` — B2 · The Elixir BCS Core. Next:
`/bcs/elixir-core/otp-application/the-export-list` — The Export List.
