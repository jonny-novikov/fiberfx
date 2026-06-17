# B2 · The Elixir BCS Core — the reference implementation

> Route: `/bcs/elixir-core` · chapter landing · manuscript Part II (`content/bcs2.md`–`bcs2.5.md`).
> Md mirror of `html/bcs/elixir-core/index.html`.

**The law, landed on OTP.** Part I argued; Part II builds. This is the manuscript's reference implementation of
a *system* — the noun the law's first clause is about — on the platform where that clause is the language's
native shape rather than a discipline imposed on it. On the BEAM, a system is an OTP application: the
supervision tree is the boundary, the owning process is the encapsulation, and restart semantics are part of
the design rather than an accident of it.

## The arc — six chapters in reading order

The interactive arc figure carries the six modules; selecting a node reads its thesis.

- **B2.1 · A System Is an OTP Application** (`otp-application`, `bcs2.1.md`) — boundary, supervision tree,
  ownership, restart semantics as architecture. The export list is the boundary; existence is the supervisor's
  and data is deliberately not; checkpoints are rows; `one_for_one` is a blast-radius statement. Rung
  `bcs_rung_2_1_check.out`, `PASS 5/5`.
- **B2.2 · Property Stores on ETS** (`property-stores`, `bcs2.2.md`) — three stores under one tree, `AST`/`PRT`/
  `ORD`, the branded id the only key, chronology a property of the keyspace. `get/2`, `page_desc/2`, and the
  reviewed `window/3`. Rung `bcs_rung_2_2_check.out`, `PASS 5/5`.
- **B2.3 · The CHAMP Property Database** (`champ`, `bcs2.3.md`) — structural sharing as the snapshot mechanism,
  the contract hash as the trie's placement function, the crossover against the flat table stated both ways.
  Rung `PASS 7/7`. Route `/bcs/elixir-core/champ`.
- **B2.4 · Archetypes and Composition** (`archetypes`, `bcs2.4.md`) — property inheritance as data under the
  `ARC` namespace; the composite instrument without a class diamond; composition at read time. Rung `PASS 5/5`.
  Route `/bcs/elixir-core/archetypes`.
- **B2.5 · Relations Are Systems** (`relations`, `bcs2.5.md`) — the edges store: tuple-keyed relations, both
  ends gated, dual private indexes; normalization performed in a gate. Rung `PASS 5/5`. Route
  `/bcs/elixir-core/relations`.
- **B2.6 · Gates and Acceleration at the Boundary** (`boundary-acceleration`) — every ingress gated by
  namespace, the deferred persistence adapter, the native codec and the measured line where it pays. The
  manuscript plans this chapter; its rung is on file, its prose is not. *Manuscript pending.*

## The seven design guidelines

Part II adds seven guidelines, applied before the first GenServer is written, with the trading vocabulary
(`AST` instruments, `PRT` portfolios, `ORD` orders, `RSK` envelopes) supplying the examples: one application
per system, the tree is the boundary; the store process owns the table, sharing is a recorded exception; pure
core, process shell; crash on contract violation, refuse on domain grounds; a snapshot is a structure, not a
copy; relations are systems, not fields; archetypes are data.

## The floor under the floor — the evidence

Part II is manuscript-ready, and each written chapter is backed by a rung — an executable check script and a
frozen transcript. The five rung records on file:

```
bcs_rung_2_1_check.out  ·  a system is an OTP application   PASS 5/5
bcs_rung_2_2_check.out  ·  property stores on ETS           PASS 5/5
bcs_rung_2_3_check.out  ·  the CHAMP property database       PASS 7/7
bcs_rung_2_4_check.out  ·  archetypes and composition        PASS 5/5
bcs_rung_2_5_check.out  ·  relations are systems            PASS 5/5
```

## Up next

B3 · The Bus (EchoMQ, Valkey-native), then Parts IV–VIII — the near-cache, Go, Node, production on Fly, and the
trading capstone, built as the manuscript ships.

## The doors

- `/echomq` — the bus B3 narrates, taught rung by rung.
- `/redis-patterns` — the substrate patterns under the bus and the stores.
- `/elixir` — the Portal engine and the umbrella where `echo_data`, the production identity library, lives.

## References

### Sources

- Erlang/OTP — the `supervisor` behaviour: <https://www.erlang.org/doc/apps/stdlib/supervisor.html> — restart
  strategies, the `one_for_one` blast radius, start order and reverse shutdown.
- Erlang/OTP — the `ets` module: <https://www.erlang.org/doc/apps/stdlib/ets.html> — `ordered_set` term-order
  traversal, match specifications, table protection levels.
- Steindorfer & Vinju — Optimizing Hash-Array Mapped Tries (OOPSLA 2015):
  <https://dl.acm.org/doi/10.1145/2814270.2814312> — the two-bitmap CHAMP node B2.3 integrates.

### Related

- `/bcs` — the course home: the law, the id anatomy, the chapter map.
- `/bcs/ideas` — B1 · Ideas Behind: the conceptual floor Part II builds on.
- `/echomq` — the far side of the B3 door.
- `/elixir` — the umbrella where `echo_data` lives.
