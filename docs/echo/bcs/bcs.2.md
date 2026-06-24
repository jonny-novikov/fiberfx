# BCS · B2 — The Elixir BCS Core
<show-structure depth="2"/>

B2 is the crucial chapter, and it is built differently: a landing over six modules, each module three dives — except B2.1, the foundation, which runs to six. The chapter is served at `/bcs/elixir-core`; module B2.1 at `/bcs/elixir-core/otp-application`, with its dives under `/bcs/elixir-core/otp-application/`. The remaining modules — B2.2 through B2.6 — follow.

B2 is the crucial chapter: the BCS law, landed on OTP and ETS, in six modules. A system is an OTP application with an export-list boundary (B2.1); its state lives in property stores on ETS keyed by the branded id (B2.2); those values are held in a CHAMP persistent map whose snapshots are structurally shared (B2.3); entity types are composed from archetypes by a pure fold, with no class diamond (B2.4); relations between systems are themselves systems, the edges store keyed by the pair (B2.5); and every ingress is gated by namespace before it touches a tier, where the native codec earns its place (B2.6). Each module is three dives; B2.1, the foundation, runs to six — three on the shape and three walking the source. Read top to bottom, it is the Elixir core that the bus, the cache, the floor — and the Codemojex game running on all of them — stand on.

## The six modules

- **B2.1 · A System Is an OTP Application** (6 dives) — Boundary, supervision, ownership, and the source behind them: the export list is the surface, the table is `:private`, the supervisor owns existence. Six dives — three on the shape, three walking the real code.
- **B2.2 · Property Stores on ETS** (3 dives) — Three stores under one tree, the 14-byte branded id the only key, chronology read off the ordered keyspace with no timestamp column — `page_desc` and `window`. A player's state, addressed by name.
- **B2.3 · The CHAMP Property Database** (3 dives) — A persistent hash-array-mapped trie: structural sharing as the snapshot mechanism, the contract hash as the placement function, the crossover against a flat table stated both ways. Game snapshots shared, not copied.
- **B2.4 · Archetypes and Composition** (3 dives) — Property inheritance as data under an archetype namespace, the composite read at request time by a pure fold — reuse without a class diamond. A tile or a player composed from parts.
- **B2.5 · Relations Are Systems** (3 dives) — The edges store: tuple-keyed relations, both ends gated, dual private indexes for traversal from either end. Player-in-room and tile-owned-by-player, each a system of its own.
- **B2.6 · Gates and Acceleration at the Boundary** (3 dives) — The namespace gate that admits one kind and collapses the rest to invalid, and an optional native codec that accelerates the contract with a pure-Elixir fallback proven equal at boot. The hot path of a live game.

Every module draws from real source under `echo_data`, and B2.1 shows three of those files in full. The only contract figure on these pages is the placement vector the runtime checks at boot, `placement(USR0KHTOWnGLuC) = 234878118`; where a measured line is claimed, it rides a committed benchmark, not the page.

## B2.1 · A System Is an OTP Application

B2.1 reads OTP as architecture, then reads the architecture in source. A BCS system is an OTP application: a module whose export list is its boundary, a process that owns its state in a `:private` table, and a supervisor that owns the process's existence but not its data. The first three dives take the shape apart; the last three walk the real code that implements it — `application.ex`, `supervisor.ex`, and the whole of `property_store.ex` — and point each line at the room Codemojex will supervise.

### B2.1.1 · The boundary is the export list

In BCS a system is a module, and the module's exported functions are the whole of its surface. `EchoData.Bcs.PropertyStore` exports `put/3`, `get/2`, `window/3`, `page_desc/2`, and `placement/1` — and that list is the system. Everything else is private: the ETS table the store owns is opened `:private`, so no other process can read or write it, not even by accident.

The boundary decides what may cross, and only two things may. A branded id crosses — the 14-byte name that is the table's only key — and a message about that id crosses: put this value, get that one, give me the window between these two. A reference to the state never crosses, because there is no reference to hand out; the state lives behind the export list, reachable only by asking the owner.

This is the Part I law made concrete in a single Elixir module. Codemojex draws the same line around a room: the room exports `join`, `guess`, `leave` — commands naming a player and a round — and never exposes its board. A caller plays the game by sending messages about ids, and the system that owns the board is the only thing that touches it.

### B2.1.2 · The supervision tree

A system does not run loose; it runs under a supervisor. `EchoData.Bcs.Supervisor` is `one_for_one` over named property stores: it starts one `PropertyStore` child per `{name, namespace}` pair, each a GenServer with its own private table. The supervisor is the system's parent, and the tree is the shape a deployment starts.

`one_for_one` is a containment strategy. If one store crashes — a bad message, an unexpected value — the supervisor restarts that one child and leaves its siblings untouched; a fault in the orders store never disturbs the players store. This is let-it-crash as architecture: a process that reaches a state it cannot handle dies, and a clean one takes its place, rather than corruption spreading through shared memory.

Codemojex inherits the tree. Each room is a supervised child, so a crash in one room never takes down another; the command workers that drain `EchoMQ.Lanes` are supervised the same way, restarted on failure without losing the lane. The supervision tree is how a system of many rooms stays up while any one room is allowed to fail.

### B2.1.3 · The supervisor owns existence, not data

A supervisor owns one thing and deliberately not another. It owns existence — when a child starts, when it restarts, when it shuts down — the lifecycle of the process. It does not own the child's data: the private ETS table belongs to the GenServer, not to the supervisor, and the supervisor neither reads it nor restores it. Existence and state are split on purpose.

The split is what makes restart safe. When a store crashes and the supervisor brings back a fresh process, that process starts with an empty table — the supervisor did not, and must not, carry the old state forward, because the old state is exactly what may have been corrupt. Durable state is recovered from below, not from the supervisor: the system rehydrates from the store and the floor, which are the things designed to survive a process.

Codemojex makes the recovery visible. A restarted room is a brand-new process with an empty board, and its durable state — the round, the scores, the wallet — is rehydrated from `EchoStore` and the persistence floor of B5, keyed by the room's branded id. The supervisor guarantees the room exists again; the store and the floor guarantee it remembers. Existence is the supervisor's; memory is the system's.

### B2.1.4 · The application boots the contract

The OTP application is a system's first breath, and `EchoData.Application.start/2` does three things in order. It starts the lock-free Snowflake so ids can be minted; it runs the branded-id self-check, which proves the codec-and-hash contract before a single system exists; and only then does it root a `one_for_one` supervisor. The boot proves the contract or it refuses to start — thirteen lines, and the order is the point.

The self-check is the contract made executable. It mints, encodes, decodes, and hashes a known id and asserts the result against a committed vector — the same `placement(USR0KHTOWnGLuC) = 234878118` the figures cite — and returns the codec mode, native or the pure-Elixir fallback, so the log records which path served. A node that cannot reproduce the vector never reaches its first message.

Codemojex starts the same way. Before a room can be supervised, the application has proven that every node mints and decodes branded ids identically; a room on one machine and a worker on another agree on what a player's id means because the contract was checked at boot, not assumed. The application is where the law stops being a claim and becomes a running guarantee.

_echo_data/lib/echo_data/application.ex — complete, 13 lines_

```elixir
defmodule EchoData.Application do
  @moduledoc false
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    :ok = EchoData.Snowflake.start()
    {:ok, mode} = EchoData.BrandedId.self_check!()
    Logger.info("EchoData: contract self-check passed, codec=#{mode}")
    Supervisor.start_link([], strategy: :one_for_one, name: EchoData.Supervisor)
  end
end
```

### B2.1.5 · The supervisor names the systems

`EchoData.Bcs.Supervisor` turns a list of systems into a running tree. Its `init` takes a list of `{name, namespace}` pairs and, for each, builds a child spec for a `PropertyStore` — passing the name and namespace as start arguments, and using the name as the child `id`. The supervisor is where the system topology is declared, and it is declared as data.

The strategy is `one_for_one`, and setting the child `id` to the name is what makes restarts addressable: each store is known to the supervisor by its name, so a crash restarts exactly that store and no other. Because the tree is a comprehension over a list, adding a system means adding a pair — not editing the supervisor.

Codemojex's rooms take the same shape. A supervisor over room pairs brings up one store per room, each named by the room's branded id; a new room is a new pair, a crashed room is one restarted child, and the command workers that drain the lanes hang off the same tree. The supervisor is how a game of many rooms becomes one supervised topology.

_echo_data/lib/echo_data/bcs/supervisor.ex — complete, 19 lines_

```elixir
defmodule EchoData.Bcs.Supervisor do
  @moduledoc "one_for_one over named property stores. Rung bcs1.1."

  use Supervisor

  def start_link(stores), do: Supervisor.start_link(__MODULE__, stores, name: __MODULE__)

  @impl true
  def init(stores) do
    children =
      for {name, ns} <- stores do
        Supervisor.child_spec({EchoData.Bcs.PropertyStore, [name: name, namespace: ns]},
          id: name
        )
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

### B2.1.6 · The property store, in full

`EchoData.Bcs.PropertyStore` is the whole system in one file. `start_link/1` reads its name and namespace; `init/1` proves the contract once more for this process, then opens a single `:ets` table as `:ordered_set` and `:private`; and the state is two fields, the namespace and the table. The export list — `put`, `get`, `window`, `page_desc`, `record_entity`, `placement` — is the boundary B2.1.1 described.

Every write and read crosses the gate first. Each `handle_call` and the one `handle_cast` ask `Bcs.gate` to admit the id's namespace before touching the table, so an id of the wrong namespace is refused at the door, not stored and found wrong later. `window/3` gates both bounds and runs an `:ets.select` over the half-open range; `page_desc/2` walks descending from the table's last key. One function stands apart: `placement/1` is pure, parsing and hashing the id with no call to the process at all.

This is the file Codemojex's rooms are built from. A room is a property store keyed by player and round ids, its writes gated by the room's namespace, its recent history read straight off the ordered keyspace by `page_desc` — no timestamp column, because the id carries the time. Read it once and the rest of the core is variations on it: the CHAMP map, the edges store, and the gates are this same discipline, specialized.

_echo_data/lib/echo_data/bcs/property_store.ex — complete, 103 lines_

```elixir
defmodule EchoData.Bcs.PropertyStore do
  @moduledoc """
  A BCS system in skeleton: a GenServer owning one private ordered_set
  property table keyed by the 14-byte branded string. Rung bcs1.1.
  """

  use GenServer

  alias EchoData.{BrandedId, Bcs}

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    ns = Keyword.fetch!(opts, :namespace)
    GenServer.start_link(__MODULE__, ns, name: name)
  end

  def put(store, id, value) when is_binary(id), do: GenServer.call(store, {:put, id, value})

  def get(store, id) when is_binary(id), do: GenServer.call(store, {:get, id})

  def page_desc(store, n) when is_integer(n) and n > 0,
    do: GenServer.call(store, {:page_desc, n})

  def record_entity(store, id) when is_binary(id), do: GenServer.cast(store, {:entity, id})

  @doc """
  Ascending ids in [lo, hi) — Chapter 1.5's synthetic cursors landed on the
  ordered_set. Bounds are branded ids (synthetic via min_for or real) and are
  gated like any ingress. Added by the Chapter 2.2 architecture review.
  """
  def window(store, lo, hi) when is_binary(lo) and is_binary(hi),
    do: GenServer.call(store, {:window, lo, hi})

  @spec placement(binary()) :: {:ok, non_neg_integer()} | {:error, :invalid}
  def placement(id) when is_binary(id) do
    case BrandedId.parse(id) do
      {:ok, _ns, snow} -> {:ok, BrandedId.hash32(snow)}
      :error -> {:error, :invalid}
    end
  end

  @impl true
  def init(ns) do
    {:ok, _mode} = BrandedId.self_check!()
    table = :ets.new(:bcs_props, [:ordered_set, :private])
    {:ok, %{ns: ns, table: table}}
  end

  @impl true
  def handle_call({:put, id, value}, _from, s) do
    case Bcs.gate(id, s.ns) do
      {:ok, _snow} ->
        :ets.insert(s.table, {id, value})
        {:reply, :ok, s}

      {:error, _} = err ->
        {:reply, err, s}
    end
  end

  def handle_call({:get, id}, _from, s) do
    case Bcs.gate(id, s.ns) do
      {:ok, _snow} ->
        case :ets.lookup(s.table, id) do
          [{^id, value}] -> {:reply, {:ok, value}, s}
          [] -> {:reply, {:error, :not_found}, s}
        end

      {:error, _} = err ->
        {:reply, err, s}
    end
  end

  def handle_call({:window, lo, hi}, _from, s) do
    with {:ok, _} <- EchoData.Bcs.gate(lo, s.ns),
         {:ok, _} <- EchoData.Bcs.gate(hi, s.ns) do
      spec = [{{:"$1", :_}, [{:>=, :"$1", {:const, lo}}, {:<, :"$1", {:const, hi}}], [:"$1"]}]
      {:reply, {:ok, :ets.select(s.table, spec)}, s}
    else
      {:error, _} = err -> {:reply, err, s}
    end
  end

  def handle_call({:page_desc, n}, _from, s) do
    {:reply, {:ok, walk_desc(s.table, :ets.last(s.table), n)}, s}
  end

  @impl true
  def handle_cast({:entity, id}, s) do
    case Bcs.gate(id, s.ns) do
      {:ok, _snow} -> :ets.insert(s.table, {id, true})
      {:error, _} -> :ok
    end

    {:noreply, s}
  end

  defp walk_desc(_table, :"$end_of_table", _n), do: []
  defp walk_desc(_table, _key, 0), do: []

  defp walk_desc(table, key, n),
    do: [key | walk_desc(table, :ets.prev(table, key), n - 1)]
end
```

## B2.2 · Property Stores on ETS

B2.2 reads the property store as a data structure. Its one ETS table is an `:ordered_set` keyed only by the 14-byte branded id, and because Snowflakes are minted in time order, the keyspace is already chronological — latest-N, windows, and cursors are range operations on the key, with no timestamp column and no secondary index. Three dives: the branded id as the sole key, key-order-is-time-order and the reads that fall out of it, and TTL made structural by deriving a bucket from the id itself. Grounded in `property_store.ex`, `timeline.ex`, and `buckets.ex`, and pointed at the stores a Codemojex room keeps.

### B2.2.1 · The branded id is the only key

A property store keeps one ETS table, and that table has exactly one key: the 14-byte branded id. There is no surrogate integer, no separate timestamp column, no secondary index — the key is the identity, and the row is the key and its value, nothing more. `EchoData.Timeline` states the same shape from the other side: it keys by the raw snowflake with the branded form at the edges, and adds no column the key already carries.

The key is not opaque; it is structured. The first three bytes are the namespace, and the remaining eleven are base62 of a 64-bit snowflake — so the key already carries who-this-is, what-kind, and when-it-was-minted. A store that keys by the branded id is keying by all of that at once, which is why the rows need nothing beside the value.

Codemojex keys every store this way. A player's record sits under a `PLR` id, a room's under a `ROM` id, a round's under its own; the store never asks which player with a join against a name table, because the name is the key. Identity is the address, and the address is the whole of the row's left-hand side.

### B2.2.2 · Key order is time order

Snowflakes are minted in time order, and base62 preserves that order byte for byte, so the ordered_set's key order is chronological order — for free, with no clock column and no sort. `EchoData.Timeline` turns this into its whole API: latest-N, cursor pagination, and time-window counts are all range operations on the key.

Three reads fall out of one property. Latest-N walks back from the table's last key; a window is an `:ets.select` over a half-open range of ids; and a time bound needs no stored id at all, because `EchoData.Snowflake.min_for` mints a synthetic cursor for any instant — everything since two o'clock becomes a key comparison. The branded id even doubles as the public pagination token: opaque-looking, URL-safe, and exact to resume from.

Codemojex reads its history this way. A room's recent guesses are latest-N off the keyspace; a leaderboard over the last hour is a window between two synthetic cursors; a feed resumes from the last id the client saw. None of it stores a timestamp, because the id is the timestamp, and the keyspace is already sorted.

### B2.2.3 · TTL as structure, not bookkeeping

Expiry is usually per-entry bookkeeping — a stored deadline on every row, a sweep that visits them. `EchoData.Buckets` removes the bookkeeping by deriving a bucket straight from the snowflake: a right shift of the id groups entries into fixed time windows, so dropping everything older than a cutoff is dropping whole buckets — an operation in the number of buckets, touching no individual entry.

The id carrying its own creation time is what makes this structural. The bucket of any id is computable, never searched for, so a fetch is a couple of map hops and an expiry is a handful of bucket deletions. Sessions, presence, rate-limit windows, ephemeral caches — anything whose lifetime is minted-less-than-X-ago — pays nothing per entry for its TTL.

Codemojex leans on this for everything short-lived. Presence and rate-limit windows live in buckets and age out by the shift; a finished round's ephemeral state is dropped a bucket at a time, not row by row. Because the id already encodes when it was made, time-to-live stops being data the system maintains and becomes a property of where the entry sits.

## B2.3 · The CHAMP Property Database

B2.3 reads the CHAMP property database — a persistent branded-id map over a forest of tries, one per namespace. A new version shares every untouched subtree with the old, so snapshots are the old root kept; placement within a trie is decided by the one contract hash, identical across Elixir, the native tables, and any Go or Node consumer; and the structure is an L0 memory tier, rebuildable from the Graft floor rather than a source of truth. Three dives: structural sharing, the contract hash as the placement function, and the tier-not-truth discipline. Grounded in `branded_champ.ex`, `champ_node.ex`, and `champ_view.ex`, and pointed at the game snapshots Codemojex re-derives.

### B2.3.1 · Structural sharing

A CHAMP is a persistent map: updating it returns a new version while the old one stays valid and unchanged. It does this by sharing — a new version copies only the nodes on the path from the root to the change, and points at every untouched subtree the old version already held. A snapshot, then, is the old root kept; taking one costs nothing.

The node layout is what keeps the sharing tight. Each node carries two 32-bit bitmaps over one compact tuple — a `datamap` marking inline key-value pairs and a `nodemap` marking child nodes — with five-bit fragments of the hash driving 32-way branching down a handful of levels. A change rewrites a short spine of small nodes, not the map; the rest is reused by reference.

Codemojex wants this every time it shows or rewinds a game. A snapshot of a room for a spectator, a round preserved for replay, an undo of the last move — each is a cheap new root over a shared structure, not a copy of the board. The old state remains exactly itself, which is what makes versioning and broadcast affordable.

### B2.3.2 · The contract hash is the placement

`EchoData.BrandedChamp` is a forest — one trie per namespace, dispatched on the three-byte prefix — and the position of a key within a trie is decided by one function: `EchoData.BrandedId.hash32`. The same hash that answers `placement(USR0KHTOWnGLuC) = 234878118` places the key in the trie, and the node code computes it from a single source, never defining its own.

One hash from one source is what lets placement be a contract rather than an implementation detail. The same `hash32` positions a key here, in the BEAM's native tables, and in any Go or Node consumer reading the structure, so the tree shape is identical across runtimes. That is the reason to reach for CHAMP over the default map: when the in-trie placement itself is part of the contract, or when the shape must be instrumented, persisted, or mirrored.

Codemojex spans runtimes, so this matters. A `PLR` or `ROM` id lands in the same slot whether the Elixir room, a Go worker, or a Node view computes it; a structure mirrored from one to another agrees without a translation step. Placement is fixed by the id and the contract hash, not by which language happens to hold the map.

### B2.3.3 · A tier, not a source of truth

CHAMP is fast in-heap state, and the layered design is firm about what that makes it: an L0 memory tier whose contents are rebuildable from the durable floor, never a separate source of truth. `EchoData.ChampView` is that rule as code — it folds a stream of decoded entries from a Graft volume into a fresh map, so a view can be re-derived after a crash with no bespoke recovery path.

The default is the other map. `EchoData.BrandedMap` rides the BEAM's native hash-array-mapped tries and wins the general case, so it is what a store reaches for unless it has a reason not to; CHAMP earns its place only where placement-as-contract or cross-runtime mirroring is the point. Stated plainly: choose the native map for speed, the branded CHAMP for a placement you can pin and rebuild.

Codemojex treats its CHAMP views as derived. The players or rooms map is an in-memory projection; after a crash a server swaps in a whole map re-folded from the Graft commit log, atomically, and play resumes. The floor of B5 is the truth; the trie is a tier over it that any node can rebuild.

## B2.4 · Archetypes and Composition

B2.4 reads archetypes as data and composition as a pure fold. An archetype is an entity in the `ARC` namespace whose value is a property bundle, optionally extending one parent through an `:extends` key; an entity carries an archetype's id plus its own overrides; and the composed view is computed at read time by folding the chain — base first, descendants after, overrides last. Three dives: archetypes as data rather than code, composition as a pure fold whose boundary is injected, and the single `:extends` link that makes inheritance a bounded, cycle-checked chain with no class diamond. Grounded in `EchoData.Bcs.Archetypes`, and pointed at the tile and player kinds Codemojex grows at runtime.

### B2.4.1 · Archetypes are data

An archetype is not a class; it is an entity. It lives in the `ARC` namespace and its value is a property bundle — a plain map — that optionally names one parent through an `:extends` key. There are no behaviour modules and no hierarchy of code; inheritance is a stored pointer from one bundle to another, data all the way down.

An entity that uses an archetype carries two things: the archetype's id and an overrides map of its own. The archetype supplies the shared defaults, the overrides carry what is particular to this one entity, and neither is baked into a type — both are values a store holds and a fetch returns. Reuse is a reference, not a subclass.

Codemojex models its kinds this way. A tile type is an `ARC` bundle; a power-up tile is a bundle that extends it; a placed tile is an entity carrying that archetype's id plus the overrides for this square. Adding a kind is writing a bundle, not deploying code, so the set of types is data the game can grow at runtime.

### B2.4.2 · Composition is a pure fold

The composed view does not exist until it is read. `compose/2` takes a chain of bundles and a map of overrides, folds the chain with `Map.merge` — base first, each descendant after — then merges the overrides last and drops the `:extends` key. Right-most wins: a descendant overrides its parent, and the entity's overrides override them all.

Resolution stays pure by taking its boundary as an argument. `resolve/3` walks the `:extends` chain root-first through a `fetch` function the caller supplies, then hands the chain to `compose/2`; whether `fetch` reads a property store or a snapshot, the composing logic is the same pure fold. The side effect is injected, so the merge itself touches nothing outside its arguments.

Codemojex composes a tile's effective properties at the moment it needs them. The base tile, the power-up that extends it, and the placed tile's overrides fold into one map on read — not stored pre-merged, not stale when the base changes. Change the base bundle and every entity that extends it shows the change the next time it is composed.

### B2.4.3 · One parent, no diamond

A bundle extends at most one parent. That single `:extends` link makes inheritance a chain, never a lattice, so the diamond problem — two parents disagreeing about the same property — cannot arise. Where class systems need rules to break ties between multiple bases, an archetype chain has one order and one answer.

The walk that gathers the chain is bounded and guarded. It carries a depth cap, so a chain longer than the limit is refused with `:depth` rather than run forever; and it carries a set of the ids it has seen, so a bundle that extends back into its own ancestry is refused with `:cycle`. Resolution always terminates, and it terminates with a reason when the data is malformed.

Codemojex can layer kinds without fear of ambiguity. A special tile extends a power-up that extends a base, three links in a line, and the resolved properties are deterministic; a mistake that pointed a bundle at its own descendant is caught at resolve time, not discovered as a hang. Composition is reuse with a single, ordered, terminating answer.

## B2.5 · Relations Are Systems

B2.5 reads a relation as a system. `EchoData.Bcs.EdgeStore` is one owning process for one kind of edge, keyed by the tuple of names `{subject, object}` rather than a list embedded in either endpoint; both ends are gated against their namespaces before any write; and the store owns two `:private` ordered sets — a forward index for traversal from the subject and a reverse index for traversal from the object — maintained together by the single owner. Three dives: the relation as its own system, both ends gated at every door, and the dual private indexes that answer traversal both ways without a scan. Grounded in `EchoData.Bcs.EdgeStore` — with the same composite-key-is-the-index idea in `EchoData.Edges` — and pointed at the membership and ownership graphs a Codemojex room keeps.

### B2.5.1 · A relation is a system

A relation is not a field on either thing it relates; it is a system of its own. `EchoData.Bcs.EdgeStore` is one owning process for one kind of edge, and the edge is a row keyed by the tuple of names — `{subject, object}` — carrying its own properties. Portfolio holds asset, player in room: a row in a store, not a list embedded in the portfolio or the room.

Keeping the relation outside both endpoints is what keeps the endpoints clean. A subject does not grow a list of its objects and an object does not grow a list of its subjects; neither has to be rewritten when a membership changes, and neither can drift out of step with the other. The single fact — this subject relates to this object — lives in one place, owned by one process.

Codemojex makes each relationship its own store. Player-in-room is one EdgeStore, tile-ownership another; a room crashing does not touch the ownership graph, and a new kind of relation is a new supervised store rather than a new field threaded through every entity. A relation is a system, supervised and addressed like any other.

### B2.5.2 · Both ends are gated

Every door into an edge checks both ends. A store is created for a relation between two namespaces — a subject namespace and an object namespace — and `link` gates the subject against the first and the object against the second before it writes anything. An endpoint of the wrong namespace is refused at the door, so a malformed edge is never stored and found wrong later.

The gate is the single point of admission. Only once both ends pass does the store form the `{subject, object}` key and write the row in both directions; reads gate the same way, so `props`, `from`, `to`, and `degree` all refuse a wrong-namespace argument before they touch a table. The boundary B2.6 will name in full is already standing at every entry here.

Codemojex relies on this to keep its graphs sound. A player-in-room edge gates a `PLR` id as the subject and a `ROM` id as the object; a stray id from another namespace cannot slip into the membership graph, because the store rejects it before the write. The type of each end is enforced at the relation's edge, not hoped for.

### B2.5.3 · Dual private indexes

Traversal in both directions wants two orderings, so the store keeps two tables. A forward `:ets` `ordered_set` is keyed `{subject, object}` and answers `from` — the objects of a subject, ascending; a reverse table is keyed `{object, subject}` and answers `to` — the subjects of an object. `degree` counts a subject's forward rows without listing them.

Both tables are `:private` and maintained together. A single owner writes the forward and reverse rows in the same `link`, deletes both in the same `unlink`, and exports neither, so the two indexes cannot disagree — there is no path by which one is updated and the other is not. The store hands out answers to `from` and `to`, never a table to read.

Codemojex reads its membership both ways without a scan. From a player, the rooms they are in; from a room, the players in it; the count of a player's rooms without walking them — each a bounded key walk on one of the two tables. The same composite-key-is-the-index idea runs the parent-to-children hierarchy in `EchoData.Edges`, where a `{parent, child}` snowflake pair keeps a parent's children contiguous and in creation order.

## B2.6 · Gates and Acceleration at the Boundary

B2.6 closes the core with the boundary itself. `EchoData.Bcs.gate(id, ns)` admits an id of exactly one namespace and refuses everything else — `:namespace` for the wrong kind, `:invalid` for the unparseable — adding no second parser beyond `BrandedId.parse/1`. Behind that boundary, `EchoData.Native` accelerates the hot codec and hash with a Rust core and a C shim, falling back to pure Elixir when the build is absent, and the boot self-check asserts both paths produce the committed vector before a node serves. Three dives: the gate that admits one kind, the native codec with its pure fallback, and the one contract proven at the boundary. Grounded in `EchoData.Bcs`, `EchoData.Native`, and `EchoData.BrandedId`, and pointed at the gated, accelerated hot path of a live Codemojex game.

### B2.6.1 · The gate admits one namespace

Every BCS system sits behind one function. `EchoData.Bcs.gate(id, ns)` parses an id once and admits it only if its namespace is the one the system declared: a match returns `&#123;:ok, snowflake&#125;`, another namespace returns `&#123;:error, :namespace&#125;`, and an unparseable id returns `&#123;:error, :invalid&#125;`. Two failure modes, named, and nothing admitted by accident.

The gate adds no second parser. Classification beyond the namespace collapses to `:invalid`, exactly as `EchoData.BrandedId.parse/1` reports it, so there is one authority on what an id is and the gate defers to it. The property store, the edges store, the timeline — each crosses this gate before it touches a tier, which is why a malformed write is refused at the door rather than stored and discovered wrong on a read.

Codemojex puts the gate in front of every command. A move names a player and a room, and the room's gate admits only its own kind on each end before the board is touched; an id from another namespace is turned away with `:namespace`, never written and never trusted. The boundary the whole course has described is, in the end, this one call.

### B2.6.2 · A native codec with a pure fallback

The codec and the hash are the hot path — every id crossing a boundary is parsed, and many are hashed to place a key — so `EchoData.Native` offers a native core for exactly those operations: `decode`, `decode_hash`, `encode`, and `hash32`, backed by Rust through a C shim. It is optional: when the shared object is absent, every call falls back to the pure Elixir implementations, so the library runs with or without the native build.

One module owns the codec, and it chooses the path. `EchoData.BrandedId` checks `Native.loaded?` and routes to the native function or the pure one, and `loaded?/0` reports which is active; everything else — the tries, the maps, the persistence type, the web layer — calls through `BrandedId` and never sees the difference. The acceleration is a swap behind a single door, not a change to any caller.

Codemojex runs the pure path in development and the native path in production from the same code, and a node's log records which served. A move is gated and a key is placed at native speed where the build is present, and the game still runs unchanged on a machine where it is not — the hot path made fast where it counts, correct everywhere.

### B2.6.3 · One contract, proven at the boundary

Two implementations of the same contract are only safe if they agree, so the boot proves it. The self-check mints, encodes, decodes, and hashes a known id down both paths and asserts the committed vector — the same `placement(USR0KHTOWnGLuC) = 234878118` — then returns the mode that served. A node whose native core disagrees with the pure one never reaches its first message.

This is what lets the native path be an optimization rather than a fork. Because the contract is pinned by a vector and checked at start, the question of native or pure is a question of speed, never of meaning: an id placed by the Rust core lands in the same slot the Elixir core would choose, in the tries, in the tables, and in any other runtime that computes the same hash. The boundary is where speed is allowed to vary and meaning is not.

Codemojex spans machines and builds, and this is why they agree. A room on a native node and a worker on a pure node resolve a player's id to the same value because both proved the contract at boot, not because they happen to share a binary. The gate decides what may enter; the contract decides that everyone who enters is understood the same way.

## References

- [Erlang/OTP — the gen_server behaviour](https://www.erlang.org/doc/apps/stdlib/gen_server.html) — a system as a process: one mailbox, one private state, a message-only surface.
- [Erlang/OTP — the ets module](https://www.erlang.org/doc/apps/stdlib/ets.html) — the :private :ordered_set table a property store owns behind its boundary.
- [The Go Blog — Share Memory By Communicating](https://go.dev/doc/codewalk/sharemem/) — no shared state across a boundary: pass a message, never a reference.
- [Erlang/OTP — the supervisor behaviour](https://www.erlang.org/doc/apps/stdlib/supervisor.html) — one_for_one over named stores: the tree that owns a system's existence.
- [Helland — Life Beyond Distributed Transactions (CIDR 2007)](https://ics.uci.edu/~cs223/papers/cidr07p15.pdf) — durable entities a restarted system rehydrates by name.
- [Erlang/OTP — the application behaviour](https://www.erlang.org/doc/apps/kernel/application.html) — the start/2 callback that boots a system's contract before it serves.
- [King — Announcing Snowflake (2010)](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake) — the lock-free, time-ordered id the codec wraps.
- [Steindorfer & Vinju — CHAMP (OOPSLA 2015)](http://michael.steindorfer.name/publications/oopsla15.pdf) — the persistent hash-array-mapped trie holding a store's values.
- [Kreps — The Log (LinkedIn Engineering)](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying) — time-ordered, append-only data and rebuilding state by replaying it.
