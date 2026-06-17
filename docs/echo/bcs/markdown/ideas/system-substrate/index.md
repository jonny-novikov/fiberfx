# B1.1 · The System Substrate — the law, executable

> Route: `/bcs/ideas/system-substrate` (module hub, B1.1). The route-mirror source-of-record. Teaches
> `content/bcs1.1.md`; every figure verbatim from the committed `bcs_rung_1_1_check.out`. Build stamp:
> `BCS0NtMiKH0uVE`.

## Hero

Kicker: `B1.1 · THE SYSTEM SUBSTRATE — manuscript chapter 1.1`. Title: **The law, executable.** Lede — the
smallest faithful BCS system: a boundary gate that admits one namespace, a property store that owns its table
outright, a supervisor that restarts stores independently. Built and transcript-proven in Elixir; designed in
Go as the same shape in different ownership clothing. Heronote — the chapter is `content/bcs1.1.md`; the rung
behind it is bcs1.1, and its committed transcript closes `PASS 6/6`.

### The smallest faithful system (interactive SVG)

Three parts — the gate, the store, the supervisor — drawn as the system's shape. Select a part to read its
exact surface in the readout:

- **gate** — `EchoData.Bcs.gate/2` admits ids of one namespace; returns `{:ok, snowflake}` or
  `{:error, :namespace | :invalid}`, with a raising twin (`gate!/2` → `NamespaceError` / `ArgumentError`).
- **store** — `EchoData.Bcs.PropertyStore`: a GenServer owning one ETS table created `:ordered_set, :private`,
  keyed by the 14-byte branded string; every id-accepting call gates before touching the table; paging is a
  `prev` walk from the table's end.
- **supervisor** — `EchoData.Bcs.Supervisor`: named stores, `one_for_one`.

Degrades to a static labelled diagram without JavaScript.

## §1 · Why — three failures (#why)

Source: `content/bcs1.1.md` · Why. The **reach-through**: a risk engine that reads the position table directly
breaks in a file the position team does not own the day the representation changes. The **traveling object**:
an order struct serialized across services forks the truth — the copy ages while the original moves. The
**silent join**: a `TXN` id reaching the `AST` table compiles fine in untyped-id systems and fails at runtime
if the system is lucky. The substrate makes all three impossible by construction rather than discouraged by
review.

## §2 · The proof (#proof)

The full committed transcript (`content/bcs1.1.md`, quoting `bcs_rung_1_1_check.out`), verbatim:

```text
G1 reach-through ok -- outside lookup -> ArgumentError, insert -> ArgumentError; info reports protection: :private (metadata visible, data refused)
G2 traveling-object ok -- map/tuple/integer ids -> FunctionClauseError 3/3; inter-store message carried {:entity, id} only; :burned recorded BRL0NsHLqGoDbd
G3 typed ok -- rejects 4/4 as :invalid; GRD id on BRL store -> {:error, :namespace}; raising twin -> NamespaceError
G4 ordered ok -- page_desc(2000) == byte-sort desc over 2000 minted ids; store holds no clock
G5 placed ok -- placement(USR0KHTOWnGLuC) -> 234878118
G6 canon ok -- self_check! -> {:ok, :native} (init gates on the same check)
PASS 6/6
```

Each line is one attempted crime refused: the VM rejects outside data access on the private table while
permitting metadata introspection; non-id shapes die in pattern matching before any store code runs; the wrong
namespace is a typed refusal in both tuple and exception form; two thousand minted ids page newest-first from
byte comparison alone; placement is the contract's arithmetic; a store that cannot prove its codec refuses to
start.

## §3 · The dives (#dives)

- **The Six Gates** (`the-six-gates`) — G1–G6, one refused crime each, read line by line from the transcript.
- **Ownership on the BEAM** (`ownership-on-the-beam`) — the private table as a VM-enforced boundary;
  `:ordered_set` byte order as mint order; `self_check!` at init; no second parser.
- **The Owner Goroutine** (`the-owner-goroutine`) — the Go design: a channel as the boundary, the gate at the
  receiving edge, a sorted key slice. Designed; lands as its own rung.

## References (#refs)

Sources: Erlang/OTP — the ets module (`https://www.erlang.org/doc/apps/stdlib/ets.html`) · The Go Project —
Share Memory By Communicating (`https://go.dev/doc/codewalk/sharemem/`) · Chassaing — Functional Event
Sourcing Decider (`https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider`).
Related: `/bcs/ideas` (B1 · Ideas Behind) · `/bcs` (course home) · `/echomq` (the bus, Part III's subject) ·
`/elixir` (the umbrella where `echo_data` lives).

## Pager

Previous: `/bcs/ideas` — B1 · Ideas Behind. Next: `/bcs/ideas/system-substrate/the-six-gates` — The Six Gates.
