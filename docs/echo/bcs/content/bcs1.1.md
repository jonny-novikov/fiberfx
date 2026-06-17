# BCS · Chapter 1.1 — The system substrate

<show-structure depth="2"/>

The law of Part I, executable. This chapter presents the smallest faithful BCS system — a boundary gate, a property store that owns its table outright, a supervisor — built and transcript-proven in Elixir, and designed in Go as the same shape in different ownership clothing. The rung behind it is bcs1.1 (spec at [`bcs1.1.specs.md`](bcs1.1.specs.md), agent guide at [`bcs1.1.llms.md`](bcs1.1.llms.md)); every figure below is verbatim from the committed [`bcs_rung_1_1_check.out`](../../runtimes/elixir/bcs_rung_1_1_check.out).

## Why

Three failures motivate the substrate, and the trading system this series builds makes each concrete. The **reach-through**: a risk engine that reads the position table directly works until the position system changes its representation, at which point risk breaks in a file the position team does not own — and in the meantime every "optimization" that touches the table is an undesigned consistency protocol. The **traveling object**: an order struct serialized across services forks the truth — the copy ages while the original moves — or, worse, a remote reference rebuilds distributed shared memory with none of its guarantees. The **silent join**: a `TXN` id reaching the `AST` table compiles fine in untyped-id systems and fails at runtime if the system is lucky, with cross-entity data if it is not. The substrate exists to make all three impossible by construction rather than discouraged by review.

## What

Three modules and a proof. `EchoData.Bcs` is the boundary discipline: `gate/2` admits ids of one namespace and returns `{:ok, snowflake}` or `{:error, :namespace | :invalid}`, with a raising twin for call sites that prefer crashes. `EchoData.Bcs.PropertyStore` is a GenServer owning one ETS table created `:ordered_set, :private`, keyed by the 14-byte branded string — every id-accepting call gates before touching the table, ids are accepted as binaries only, and paging is a `prev` walk from the table's end. `EchoData.Bcs.Supervisor` runs named stores `one_for_one`. The committed transcript:

```text
G1 reach-through ok -- outside lookup -> ArgumentError, insert -> ArgumentError; info reports protection: :private (metadata visible, data refused)
G2 traveling-object ok -- map/tuple/integer ids -> FunctionClauseError 3/3; inter-store message carried {:entity, id} only; :burned recorded BRL0NsHLqGoDbd
G3 typed ok -- rejects 4/4 as :invalid; GRD id on BRL store -> {:error, :namespace}; raising twin -> NamespaceError
G4 ordered ok -- page_desc(2000) == byte-sort desc over 2000 minted ids; store holds no clock
G5 placed ok -- placement(USR0KHTOWnGLuC) -> 234878118
G6 canon ok -- self_check! -> {:ok, :native} (init gates on the same check)
PASS 6/6
```

Each line is one attempted crime refused: the VM itself rejects outside data access on the private table while permitting metadata introspection; non-id shapes die in pattern matching before any store code runs; the wrong namespace is a typed refusal in both tuple and exception form; two thousand minted ids page newest-first from byte comparison alone; placement is the contract's arithmetic; and a store that cannot prove its codec refuses to start.

## Who

For the engineer or agent standing up a new system on BCS — the position store, the risk-envelope store, the order book. The companion [`bcs1.1.llms.md`](bcs1.1.llms.md) is the agent-facing form of this chapter: exact arities, fences, and a build prompt for adding a system (a `PRT` positions store is its worked example). The substrate is deliberately small enough that "who" includes an agent given one brief and no further conversation.

## When

Reach for a property store when one system is the single writer of some state and chronology should come from the keys — positions by `PRT` id, fills by `ORD` id, alerts by `RSK` id. Do not reach for it when the question spans systems (that is a message over the bus, Part III's subject), when durability is required (persistence is deferred by standing decision — the store is rebuildable state), or when state must answer commands with new events rather than hold current values — that is the decider's shape, and Part VIII rethinks it on this substrate [1].

## Where

In the tree: `runtimes/elixir/lib/echo_data/bcs.ex`, `bcs/property_store.ex`, `bcs/supervisor.ex`, the check script `bcs_rung_1_1_check.exs`, and its committed output beside it. The Go counterpart targets `runtimes/go/`, where the pure-Go contract package (`brandedid`) already supplies parse and hash conformance; the store itself is designed below and lands as its own rung.

## How

**Elixir, as built.** Ownership is a process property: the table is `:private`, created in `init`, its identifier never returned from any call — the BEAM refuses outside reads at the VM layer, which is the same mechanism that enforces memory safety [2]. The gate adds no second parser: `BrandedId.parse/1` returns `{:ok, ns, snow}` or `:error`, so classification beyond the namespace collapses to `:invalid` by design. Ordering costs nothing: `:ordered_set` sorts by Erlang term order, binaries compare bytewise, and byte order on branded ids is mint order — `page_desc` is a `prev` walk from `:ets.last`, no clock anywhere in the process [2]. Init runs the canon's `self_check!` and aborts on mismatch.

**Go, as designed.** Go states the same first clause as doctrine: do not communicate by sharing memory; share memory by communicating — a goroutine that owns a data structure guarantees sequential access by construction [3]. The substrate translates directly: one owner goroutine per store holding the map, a channel as the boundary, the namespace gate at the channel's receiving edge, and — because Go maps are unordered — an explicit sorted key slice so byte order keeps supplying mint order:

```go
// Designed counterpart — lands as its own rung. The gate package exists.
type op struct {
	kind  byte      // put | get | page
	id    string    // 14-byte branded id; gated before the table
	value any
	reply chan any
}

func propertyStore(ns string, ops <-chan op) {
	props := map[string]any{} // owned by this goroutine alone
	var keys []string         // kept sorted: byte order == mint order
	for o := range ops {
		// gate via the existing pure-Go contract package (brandedid),
		// refuse wrong namespace, then mutate props/keys and reply.
		_ = ns
		o.reply <- nil
	}
}
```

The shapes differ in enforcement, not in law: the BEAM refuses the reach-through at the VM; Go removes the shared reference so there is nothing to reach through. Both put the gate at the one place identities enter.

## Decisions

**The platform corrected the spec, in that order.** The draft expected `:ets.info` on a private table to refuse outsiders alongside `lookup`; the platform returned full metadata — `protection: :private` included — to a process that cannot read one row. The spec was amended first, the gate rewritten as a positive assertion, and the clause came out sharper: a system's state is unreachable from outside; a system's existence is nobody's secret. The BEAM guards data, not existence, and hiding metadata would cost supervisors and telemetry their visibility for nothing.

**No second parser.** The Elixir gate's taxonomy is coarser than the wire contract's four atoms because `parse/1` reports `:error` without subclassification, and the rung refused to reimplement parsing to refine it. If the taxonomy ever sharpens on the BEAM, it sharpens in `BrandedId`, once.

**Numbering.** This chapter is 1.1 under the adopted part.chapter layout; the rung that built it shares the number, and its spec and agent guide sit beside this file as `bcs1.1.specs.md` and `bcs1.1.llms.md`.

## References

1. Chassaing, J. — Functional Event Sourcing Decider (the decide/evolve pattern Part VIII rethinks on BCS): [thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider](https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider)
2. Erlang/OTP — `ets` module documentation, stdlib (table protection levels including `private`; `ordered_set` term order; `prev`/`last` traversal): [erlang.org/doc/apps/stdlib/ets.html](https://www.erlang.org/doc/apps/stdlib/ets.html)
3. The Go Project — Codewalk: Share Memory By Communicating (the owner-goroutine pattern; sequential access by construction): [go.dev/doc/codewalk/sharemem](https://go.dev/doc/codewalk/sharemem/)
