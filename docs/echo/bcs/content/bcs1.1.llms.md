# bcs1.1 — the agent guide (building systems on top of BCS)

> Derived from [`bcs1.1.specs.md`](bcs1.1.specs.md) (authoritative) and the chapter
> ([`bcs1.1.md`](bcs1.1.md)). Real arities only — every surface below exists in the tree at the cited
> path. **Framing (propagate this clause):** third person for any agent; no gendered pronouns; no
> perceptual or interior-state verbs; no first-person narration. This guide is for an agent adding a
> NEW system on the substrate — not for rebuilding the substrate itself.

## References (read first, in order)

- `contract/contract.md` — the identity canon: namespaces, the order theorem, hash32, gate taxonomy. **First.**
- `docs/bcs/bcs1.md` — the part preface: the law and the design guidelines a new system must satisfy.
- `docs/bcs/bcs1.1.md` + `docs/bcs/bcs1.1.specs.md` — the substrate's chapter and its authoritative spec.
- `runtimes/elixir/lib/echo_data/bcs.ex` · `bcs/property_store.ex` · `bcs/supervisor.ex` — the implementation to build ON, not to edit.
- `runtimes/elixir/bcs_rung_1_1_check.exs` + `bcs_rung_1_1_check.out` — the gate script pattern and the proof shape a new system imitates.

## The surface (exact, as built)

- `EchoData.Bcs.gate(id, ns)` → `{:ok, snowflake} | {:error, :namespace | :invalid}`; raising twin raises `EchoData.Bcs.NamespaceError` on namespace mismatch, `ArgumentError` on malformed input.
- `EchoData.Bcs.PropertyStore.start_link(name: atom, namespace: <<_::24>>)` — one store, one namespace, pinned at start.
- `PropertyStore.put(store, id, value)` · `get(store, id)` · `page_desc(store, n)` · `record_entity(store, id)` · `placement(id)` — ids are binaries in every head; values are the system's own terms.
- Minting: `EchoData.Snowflake.start(node_id \\ nil)` once per runtime, then `Snowflake.next_branded(ns)`; never construct id strings by hand.
- Script loading order (when a check script loads the library raw): `base62` → `native` → `snowflake` → `branded_id` → the bcs modules. The order is settled; do not reorder.

## Requirements pattern for a new system (each traces to an invariant)

- **R-own** (INV-A). One GenServer owns the system's table: `:ordered_set, :private`, created in `init`, identifier never returned. No `:public`, no `:protected`, no named table, no `:ets.give_away`.
- **R-gate** (INV-C). The namespace is pinned at `start_link` and every id-accepting call gates before any table access. The system adds no parser — `EchoData.Bcs.gate/2` or `EchoData.BrandedId.parse/1`, nothing else.
- **R-ids** (INV-B). Function heads accept ids as binaries only; messages between systems carry ids and plain values, never structs, pids-as-payload, or table references.
- **R-canon** (INV-F). `init` runs `EchoData.BrandedId.self_check!/0` and aborts on mismatch.
- **R-order** (INV-D). Chronology comes from byte order on the key — `prev` walks, synthetic cursors — never from a stored timestamp or a clock read.
- **R-place** (INV-E). Placement is `PropertyStore.placement/1` (or `BrandedId.hash32/1` on a parsed snowflake) — no modulo schemes, no routing maps.
- **R-prove**. The system ships with a check script in the `bcs_rung_1_1_check.exs` pattern — one printed line per gate, exit nonzero on failure, output committed beside it.

## Execution topology

A new system is a child of `EchoData.Bcs.Supervisor` — extend its store list with `{name, namespace}` (for example `{:positions, "PRT"}`) or start a sibling supervisor with the same shape. Boot order per runtime: `Snowflake.start/1` once, then stores (each store's `init` self-checks the codec). Restart semantics are `one_for_one` and a restarted store returns empty by standing decision — rebuildable state arrives with the bus in Part III; the system must tolerate an empty table after a crash.

## Do NOT

- Do not edit the substrate modules, the contract modules, or the committed check outputs — a new system is additive.
- Do not write a second parser, hash, clock, or base62 — the canon is single-source (the no-second-parser rule is load-bearing).
- Do not let any table identifier, pid-wrapped state, or struct cross a boundary — identities and plain values only.
- Do not store timestamps beside branded keys; do not call any clock inside a store.
- Do not add dependencies, `Mix.install`, application-env configuration, or persistence.
- Do not print exclamation marks or forbidden-voice words in check output lines a chapter may later quote.

## Agent stories (Directive + Acceptance gate)

- **AS-1 — stand up the `PRT` positions store.** *Directive:* add `{:positions, "PRT"}` under the supervisor; extend a copy of the check script with put/get/page over freshly minted `PRT` ids. *Gate:* the script prints the new lines green, exits zero, and the substrate's own six gates still pass unchanged.
- **AS-2 — one legitimate exchange.** *Directive:* from an `AST` system, cast `record_entity(:positions, prt_id)`-shaped notifications about `PRT` ids only. *Gate:* the message demonstrably carries the id and plain values; the receiving store records under its own gate; nothing shaped like a struct crossed.
- **AS-3 — the negative probe.** *Directive:* drive a structurally valid id of a foreign namespace and the contract's malformed vectors at every new public call. *Gate:* `{:error, :namespace}` and `{:error, :invalid}` exactly; the raising twin raises `NamespaceError`; no call reaches the table.

## Comprehensive prompt

Add one new BCS system on the substrate — the `PRT` positions store is the canonical first — without editing the substrate, the contract modules, or any committed output. Create the store as a supervised `EchoData.Bcs.PropertyStore` child (`name: :positions, namespace: "PRT"`), mint ids only through `Snowflake.next_branded/1`, gate every public call through the existing surface, take chronology from byte order and placement from the contract hash, and keep every cross-system message to identities and plain values. Prove it the substrate's way: a check script in the `bcs_rung_1_1_check.exs` pattern, one line per gate covering R-own through R-place plus the AS-1..AS-3 probes, exit zero, output committed beside the script — and leave the substrate's own transcript byte-identical. Cite the spec section or the source path for every surface touched; invent nothing.
