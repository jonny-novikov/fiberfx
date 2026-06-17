# bcs1.1 · The system substrate — design and implementation (specs)

<show-structure depth="2"/>

> Authoritative for rung bcs1.1. The chapter ([`bcs1.1.md`](bcs1.1.md)) narrates it; the agent guide
> ([`bcs1.1.llms.md`](bcs1.1.llms.md)) derives from it. Acceptance stories are folded into this file —
> the former three-file triad under `specs/bcs/` is superseded and removed; this file is its successor
> of record. Feedback edits this file, not the implementation.
> **Status: built.** Output committed at `runtimes/elixir/bcs_rung_1_1_check.out`, exit zero.

## Invariants

- **INV-A — data unreachable.** The property table is `:ordered_set, :private`, created in the owner's `init`; its identifier never leaves the process through any public call. Outside `lookup`/`insert` raise `ArgumentError`; `:ets.info` may report metadata (amended — see G1).
- **INV-B — ids-only surface.** Every id parameter is a binary in the function head; maps, tuples, and integers in the id position fail the clause before store code runs. Inter-store messages carry ids and plain values only.
- **INV-C — namespace gate.** Every id-accepting call gates on the store's namespace before any table access; wrong namespace yields `{:error, :namespace}` (raising twin: `EchoData.Bcs.NamespaceError`); malformed yields `{:error, :invalid}` — no second parser beyond `EchoData.BrandedId.parse/1`.
- **INV-D — order without a clock.** Paging is byte order over the branded key (`:ets.prev` from `:ets.last`); the store holds no clock and no timestamp.
- **INV-E — placement in-contract.** `placement/1` is `BrandedId.hash32/1` over the parsed snowflake; the reference id answers 234878118.
- **INV-F — one canon.** `init` runs `BrandedId.self_check!/0` and aborts the store on mismatch.

## Deliverables

- `runtimes/elixir/lib/echo_data/bcs.ex` — `EchoData.Bcs` (`gate/2`, the raising twin, `NamespaceError`).
- `runtimes/elixir/lib/echo_data/bcs/property_store.ex` — `EchoData.Bcs.PropertyStore`.
- `runtimes/elixir/lib/echo_data/bcs/supervisor.ex` — `EchoData.Bcs.Supervisor` (`one_for_one` over named stores).
- `runtimes/elixir/bcs_rung_1_1_check.exs` — the gate script; loads dependencies via `Code.require_file` in the settled order (`base62`, `native`, `snowflake`, `branded_id`, then the rung modules).
- `runtimes/elixir/bcs_rung_1_1_check.out` — the committed transcript of a passing run; definition of done.

## Surface, pinned (as built)

```elixir
EchoData.Bcs.gate(id :: binary(), ns :: binary())
  :: {:ok, non_neg_integer()} | {:error, :namespace | :invalid}

EchoData.Bcs.PropertyStore.start_link(name: atom(), namespace: binary())
put(store, id :: binary(), value :: term()) :: :ok | {:error, atom()}
get(store, id :: binary())                  :: {:ok, term()} | {:error, :not_found | atom()}
page_desc(store, n :: pos_integer())        :: {:ok, [binary()]}
record_entity(store, id :: binary())        :: :ok            # cast; gated on receipt
placement(id :: binary())                   :: {:ok, non_neg_integer()} | {:error, :invalid}
```

Values are unconstrained terms — the system's own state. Identifiers are constrained absolutely.

## Gates

| Gate | Invariant | Check | Pass criterion |
| --- | --- | --- | --- |
| G1 | INV-A | Outside process attempts `lookup` and `insert` on the table; reads `info` | Both raise `ArgumentError`; `info` reports `protection: :private`. *(Amended during build: the platform returns metadata to any process; the draft expected `info` to raise. The BEAM guards data, not existence.)* |
| G2 | INV-B | Map, tuple, integer in the id position; one store casts `{:entity, id}` to another | `FunctionClauseError` 3/3; the message demonstrably carries the id only; the receiver records under its own gate |
| G3 | INV-C | The contract's four malformed vectors through `gate/2`; a valid id of the wrong namespace | Rejects 4/4 as `:invalid`; wrong namespace `{:error, :namespace}` and `NamespaceError` from the twin |
| G4 | INV-D | Two thousand minted ids stored, then `page_desc(2000)` vs the byte-sorted descending list | Exact equality |
| G5 | INV-E | `placement/1` on the reference id | 234878118 |
| G6 | INV-F | Store init self-check | `{:ok, :native}` or `{:ok, :pure}`; init aborts otherwise |

## Acceptance stories (folded)

**US-1 — ownership is by construction.** As the owner of a system's state, the builder wants outside access refused by the VM, so that encapsulation does not depend on review.
- **Given** a started store, **When** another process attempts `:ets.lookup` or `:ets.insert` with the extracted table id, **Then** both raise `ArgumentError` (G1, INV-A).
- **Given** the same table, **When** `:ets.info` is read from outside, **Then** metadata returns and includes `protection: :private` — existence is visible, data is not (G1).

**US-2 — only identities cross.** As a neighboring system, the builder wants the boundary to accept nothing shaped like an object, so that no reference into foreign memory can form.
- **Given** the store's API, **When** a map, tuple, or integer arrives in the id position, **Then** the call dies at the function clause (G2, INV-B).
- **Given** two stores, **When** one notifies the other about an entity, **Then** the message carries the 14-byte id and an atom, and the receiver writes only its own table under its own gate (G2).

**US-3 — the contract holds at the boundary.** As a consumer of identities, the builder wants the typed, ordered, placed, canonical contract enforced where ids enter.
- **Given** malformed and wrong-namespace ids, **When** they meet the gate, **Then** refusals are typed exactly as INV-C states (G3).
- **Given** two thousand mints, **When** the newest page is requested, **Then** byte order alone returns mint order — no clock consulted (G4, INV-D).
- **Given** any holder of an id, **When** placement is computed, **Then** it is the contract hash and nothing else (G5, INV-E); **Given** a store boot, **When** the codec cannot self-prove, **Then** the store refuses to start (G6, INV-F).

## Non-goals

Cross-node distribution; persistence (deferred by standing decision — a restarted store returns empty, rebuildable-state arrives with the bus); archetypes and relations (Part II rungs); supervision strategies beyond `one_for_one`; performance gates (the measured record for ETS stores already exists in the structures article); any gate-taxonomy refinement on the BEAM (belongs to `BrandedId` if anywhere).

## Definition of done and coverage

Done is the committed transcript: six gates printed as specified, exit zero, the file beside the script. Coverage closure — `bcs.ex` is exercised by G3; `property_store.ex` by G1, G2, G4, G5, G6; `supervisor.ex` by the script's start sequence; each invariant INV-A through INV-F is named by exactly the gate row above; each deliverable is realized by at least one story, and each story names its gates.
