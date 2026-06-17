# B2.1.3 · The Blast Radius — restart strategy as a written claim

> Route: `/bcs/elixir-core/otp-application/the-blast-radius` (dive 3 of B2.1). The route-mirror
> source-of-record. Teaches `content/bcs2.1.md` (R4 + start order + the Go `supervise` loop); every figure
> verbatim from the committed `bcs_rung_2_1_check.out`. Build stamp: `BCS0NuRxoJfQe0`.

## Hero

Kicker: `B2.1 · dive — the blast radius`. Title: **These die together — or not.** Lede — R4 crashes the
portfolio store while the order store holds a position row: `sibling untouched (one_for_one): ord_store pid
stable, row intact through prt_store's crash`. A restart strategy is a blast-radius statement, and choosing
anything wider than `one_for_one` is a written claim that the named children die together. Heronote — source:
`content/bcs2.1.md`, quoting `bcs_rung_2_1_check.out`; the supervisor is committed at
`lib/echo_data/bcs/supervisor.ex`.

### The crash, on the tree (interactive SVG)

`EchoData.Bcs.Supervisor`, `one_for_one` over two named stores, drawn as the tree the rung booted. Select the
crash to read what R4 recorded: prt_store dies and restarts alone; ord_store's pid is stable and its row is
intact. Under `one_for_one`, when a child terminates, "only that child process is affected" [1]. Degrades to a
static labelled diagram without JavaScript.

## §1 · The transcript (#transcript)

The full committed record (`bcs_rung_2_1_check.out`), verbatim; this dive reads R4 and the boot line:

```text
boot: two stores under one_for_one; native codec self-check passed at each init
R1 surface ok -- exports: six domain functions plus OTP callbacks, nothing else -- no table, no pid, no internals
R2 existence ok -- existence restored, data not: fresh table after kill -- durability is a different chapter's job
R4 radius ok -- sibling untouched (one_for_one): ord_store pid stable, row intact through prt_store's crash
R3 checkpoint ok -- recovered through the boundary, not the heap: re-put from a read-back row
R5 gate ok -- prt_store refuses an ORD name with {:error, :namespace} -- admitted kinds are per-boundary
PASS 5/5
```

## §2 · Start order is the dependency declaration (#order)

Source: `content/bcs2.1.md` · What/Where. Children start left to right and stop in reverse [1], so the list in
`EchoData.Bcs.Supervisor` is documentation the runtime enforces. The supervisor, committed verbatim:

```elixir
def init(stores) do
  children =
    for {name, ns} <- stores do
      Supervisor.child_spec({EchoData.Bcs.PropertyStore, [name: name, namespace: ns]},
        id: name
      )
    end

  Supervisor.init(children, strategy: :one_for_one)
end
```

The proper `Application` callback module arrives with the umbrella adoption rung, where a Mix project exists
to declare it in. Restart intensity defaults (the supervisor's maximum restart frequency [1]) are untested at
their limit here — the gates kill twice, far under it.

## §3 · Strategy is a written claim (#strategy)

Source: `content/bcs2.1.md` · What/When/Decisions. Under `one_for_one`, when a child terminates, "only that
child process is affected" [1] — and choosing anything wider is therefore a written claim that the named
children die together. Choose `one_for_one` by default and depart only with a written reason: stores with
shared startup assumptions earn `rest_for_one`, and a genuine die-together cluster earns `one_for_all`, each
departure a sentence in the design, not a flag in the code. For operators, the supervision tree is the
runbook: the strategy column answers "what cascades," the start order answers "what depends on what," and both
are code.

### The radius, computed (interactive)

A pure function over a fixed three-child tree (the stores in start order). Select a strategy and a crashed
child; the readout lists the restart set the strategy declares: `one_for_one` restarts the crashed child
alone; `rest_for_one` restarts the crashed child and every child started after it; `one_for_all` restarts all
three [1]. Static verdicts are printed below the control for the no-JS reading.

## §4 · The Go counterpart — the supervise loop (#go)

Source: `content/bcs2.1.md` · How. The application shape translates without OTP: a package whose `Start(ctx)`
spawns the owner goroutine from Chapter 1.1 and returns a handle of typed methods — the export list, enforced
by the package boundary — and whose supervisor is a restart loop, quoted verbatim:

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

Existence guarded by the loop, data by nothing — the same statement R2 gates, made in a language with no
supervisor behaviour. One loop per system is the `one_for_one` analog; a shared loop over several owners would
be `one_for_all` and should be exactly as deliberate.

## References (#refs)

Sources: Erlang/OTP — the supervisor behaviour (`https://www.erlang.org/doc/apps/stdlib/supervisor.html`) ·
Erlang/OTP — the ets module (`https://www.erlang.org/doc/apps/stdlib/ets.html`).
Related: `/bcs/elixir-core/otp-application` (B2.1 — the module hub) · `/bcs/elixir-core` (B2 — the chapter
landing) · `/bcs` (course home) · `/elixir` (the umbrella where `echo_data` lives).

## Pager

Previous: `/bcs/elixir-core/otp-application/existence-and-the-kill` — Existence and the Kill. Next:
`/bcs/elixir-core/otp-application` — B2.1 · the hub.
