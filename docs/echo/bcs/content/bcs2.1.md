# BCS · Chapter 2.1 — A system is an OTP application

<show-structure depth="2"/>

Chapter 1.1 built the skeleton and promised the full treatment; this chapter delivers it without changing a line of the skeleton — which is the claim. The substrate's three modules (`runtimes/elixir/lib/echo_data/bcs.ex`, `bcs/property_store.ex`, `bcs/supervisor.ex`) already *are* an OTP application in everything but the `Application` callback module, and a new five-gate rung (`bcs_rung_2_1_check.exs`, committed output ending `PASS 5/5`) puts the architectural content on stage: the export list as the boundary, existence versus data under a kill, blast radius under `one_for_one`, checkpoint recovery through the boundary, and the per-store namespace gate. Boundary, tree, ownership, restart semantics — each is a decision this chapter makes explicit, with the trading domain supplying the stakes.

## Why

"System" was Part I's load-bearing noun, and OTP is where the noun acquires a runtime shape: a supervised process owning a table behind an export list. The stakes are not abstract on a trading platform — when the position store crashes at 14:30 with the book open, *what restarts, what survives, and what cascades* is a design decision with money attached, and a design decision that was never written down is still a design, only an accidental one. This chapter writes the defaults down and proves each on stage, so that every Part II system after it inherits decisions rather than accidents.

## What

**The boundary is the export list.** A system exports functions over identities and exports nothing else — the sentence from the part preface, now gated. R1 inspects the store module's actual surface and finds `exports: six domain functions plus OTP callbacks, nothing else` — `start_link/1`, `put/3`, `get/2`, `page_desc/2`, `record_entity/2`, `placement/1`, and the behaviour's own callbacks; no table reference escapes, no pid is handed out, no internal record leaks its shape. What a system never exports is the more important half: the table (`protection: :private` in the substrate's own gate record) and anything whose shape would couple a caller to a representation.

**Existence is the supervisor's; data is deliberately not.** R2 kills the portfolio store mid-flight: the supervisor restores the process, and the row written before the kill is gone — `existence restored, data not: fresh table after kill`. This is the Part I correction matured into policy. The BEAM guards data, not existence; the supervision tree guards existence; and a private ETS table dies with its owner [2] — *by design*, because durability is a different chapter's job (the deferred Ecto adapter in 2.6, replay from the bus in Part III). A restart is a clean slate unless the design said otherwise, and the design says otherwise in exactly one way:

**Checkpoints are rows, not memories.** R3 reads a row back through the API before the kill, loses it in the crash, and recovers it the only legitimate way — `recovered through the boundary, not the heap`. State that must survive a process lives in a store: this system's, another system's, or the bus's log. Process state is working memory; anything load-bearing in it is a checkpoint that has not been written yet.

**Restart strategy is a blast-radius statement.** R4 crashes the portfolio store while the order store holds a position row: `sibling untouched (one_for_one): ord_store pid stable, row intact through prt_store's crash`. Under `one_for_one`, when a child terminates, "only that child process is affected" [1] — and choosing anything wider is therefore a written claim that the named children die together. The supervisor's start order is the dependency declaration in the same key: children start left to right and stop in reverse [1], so the list in `EchoData.Bcs.Supervisor` is documentation the runtime enforces.

**The boundary declares its kinds.** R5 offers the portfolio store an `ORD` name and is refused with `{:error, :namespace}` — admitted namespaces are a per-boundary property, checked at every ingress, exactly as Chapter 1.2 placed clause three. One system, one table, one declared kind set; the silent join has no door here.

## Who

System authors, for whom this chapter is the template: each trading system — positions, orders, risk — is one application-shaped unit with these five properties gated before its first feature. Operators, for whom the supervision tree is the runbook: the strategy column answers "what cascades," the start order answers "what depends on what," and both are code. And agents, for whom R1's surface is the whole callable world: what the export list does not say, an agent may not want.

## When

Give state a system the moment it acquires an owner, a lifecycle, or an admitted kind set — before that, it is a module's private business. Choose `one_for_one` by default and depart only with a written reason: stores with shared startup assumptions earn `rest_for_one`, and a genuine die-together cluster earns `one_for_all`, each departure a sentence in the design, not a flag in the code. And reach for the heir-held table — an ETS table that survives its owner via an inheritor — only as the part preface's recorded exception: it trades the clean-slate guarantee for warm-cache latency, and the trade deserves its sentence too. None of the systems in this part make it.

## Where

The modules are the substrate's, unchanged, at their committed paths; the evidence is two rung records side by side — `bcs_rung_1_1_check.out` for the skeleton's six gates and `bcs_rung_2_1_check.out` for this chapter's five. The supervisor in the tree is `EchoData.Bcs.Supervisor`, `one_for_one` over named stores; the proper `Application` callback module arrives with the umbrella adoption rung, where a Mix project exists to declare it in.

## How — the shape, in Elixir and in Go

**Elixir.** The chapter's How *is* the committed code, and one detail deserves the spotlight: the pure-core guideline is visible in the store's callbacks, which contain a gate call, a table operation, and nothing clever — `walk_desc/3` does the paging as a pure function the shell calls. The boot line of the new record shows the other inheritance: `native codec self-check passed at each init` — a store refuses to exist before the canon proves itself, which is clause three applied to startup.

**Go.** The application shape translates without OTP: a package whose `Start(ctx)` spawns the owner goroutine from Chapter 1.1 and returns a handle of typed methods — the export list, enforced by the package boundary — and whose supervisor is a restart loop:

```go
func supervise(ctx context.Context, run func(context.Context) error) {
    backoff := 100 * time.Millisecond
    for ctx.Err() == nil {
        if err := runRecovering(ctx, run); err != nil {
            time.Sleep(backoff) // existence restored next loop;
            backoff = min(backoff*2, 2*time.Second)
            continue // data was the goroutine's locals: gone, by design
        }
        return
    }
}
```

Existence guarded by the loop, data by nothing — the same statement R2 gates, made in a language with no supervisor behaviour. One loop per system is the `one_for_one` analog; a shared loop over several owners would be `one_for_all` and should be exactly as deliberate.

## Decisions

**Data dies with the owner, by design.** R2 is policy, not accident: the clean slate is the default restart semantics for every Part II store, and durability claims route to rows.

**Checkpoints are rows.** Anything that must survive a crash is written through a boundary before it is needed — R3 is the only recovery path the architecture recognizes.

**`one_for_one` is the default; wider is a written claim.** A strategy is the sentence "these die together," and sentences get reviewed.

**The export list is the boundary contract.** Adding an export is an architecture change with R1 as its gate, not a convenience landing in a diff.

## Boundaries

Restart intensity defaults (the supervisor's maximum restart frequency [1]) are untested at their limit here — the gates kill twice, far under it. The stage uses named processes for clarity; production naming on the umbrella is the registry's business and stays plain prose until that rung. Single node, as everywhere in this part; distribution is the bus's chapter.

## Companion files

`runtimes/elixir/bcs_rung_2_1_check.exs` and its committed record `bcs_rung_2_1_check.out`; the substrate modules and `bcs_rung_1_1_check.out` from Chapter 1.1.

## References

1. Erlang/OTP stdlib — `supervisor` behaviour (restart strategies with `one_for_one` as default and its single-child blast radius; start order and reverse shutdown; restart intensity): [erlang.org/doc/apps/stdlib/supervisor.html](https://www.erlang.org/doc/apps/stdlib/supervisor.html)
2. Erlang/OTP stdlib — `ets` (table protection levels including `private`; table lifetime bound to the owning process): [erlang.org/doc/apps/stdlib/ets.html](https://www.erlang.org/doc/apps/stdlib/ets.html)
