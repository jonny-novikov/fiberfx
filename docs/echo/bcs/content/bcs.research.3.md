# BCS · Research 3 · Composition in Distributed Systems, the Decider Pattern, and Putting It All Together

<show-structure depth="2"/>

## When the handle crosses the wire

[`bcs.research.2.md`](bcs.research.2.md) ended at a wall: the generational-index handle is an index into an array owned by one system in one address space, and it means nothing on the other side of a socket, a save file, or a foreign store. Distributed composition begins exactly where the pointer dies. This chapter traces how the field composes systems when references cannot be shared, develops the Decider pattern as the unit of distributed business logic, sketches an advanced Decider design for a trading engine keyed by branded identities, and closes with the synthesis that states the appendix's thesis.

## Helland's entities and idempotence

Pat Helland's "Life beyond Distributed Transactions: an Apostate's Opinion" (2007, reprinted in ACM Queue 2016) is the foundational text. Helland argues that at scale you cannot have transactions that span entities, so the unit of atomicity shrinks to a single entity — a collection of keyed data with a unique key, living in one scope of serializability. Anything that must affect another entity does so by sending a message, and because messages can be retried, the receiving entity must be idempotent. Helland's mechanism is memory: the entity is, in the paper's words, "designed to remember" the messages it has already absorbed, so a duplicate is harmless [11]. The manuscript's chapter 3.5 cites this paper, and EchoMQ's provenance guards — every row remembering the job names it has absorbed — are a direct implementation of Helland's remembering.

Helland's later "Immutability Changes Everything" (ACM Queue 2015/2016) supplies the other half: as storage gets cheaper we increasingly store and send immutable data, because, in his framing, immutability is what lets systems "coordinate at a distance" without locks [26]. An immutable event, once written, can be replicated, cached, and replayed without coordination. This is the conceptual ground under event sourcing and under EchoCache's snowflake-versioned newer-wins coherence (manuscript Part IV), where a version is a mint-ordered identity and the newer one always wins without a lock.

## The log as a unifying abstraction

Jay Kreps' "The Log: What every software engineer should know about real-time data's unifying abstraction" (LinkedIn Engineering, 2013) reframes composition itself. A log is, in Kreps' definition, "an append-only, totally-ordered sequence of records ordered by time." If every system publishes its changes to a shared log and every consumer reads from it, then systems are composed by the log rather than by direct calls: producers and consumers are decoupled, can be added independently, and can replay history to rebuild state. Kreps notes that the one domain where real-time stream processing already had traction was finance, where real-time data streams were the norm and processing had become the bottleneck [27]. EchoMQ is a log-flavored bus: the manuscript's fair lanes, fencing tokens, and park-don't-poll consumers compose systems by messages on a shared substrate, which is the log idea applied to a job bus.

## Event sourcing, CQRS, and the Decider

Event sourcing stores the sequence of events that happened rather than the current state, and rebuilds state by folding the events. CQRS separates the write path that decides what happens from the read path that serves queries. The Decider pattern is the functional distillation of the write path, and it is the centerpiece of this chapter.

Jérémie Chassaing introduced the Decider in "Functional Event Sourcing Decider" (thinkbeforecoding.com, 2021). A Decider is three types and four elements:

```
type Command
type Event
type State
initialState : State
decide : Command -> State -> Event list
evolve : State -> Event -> State
isTerminal : State -> bool
```

`decide` takes a command and the current state and returns the events that should happen; `evolve` takes a state and an event and returns the next state; `initialState` is the state before anything has happened; `isTerminal` marks a state past which no command is accepted. Chassaing's framing starts from a system as a function of inputs over time, and the Decider is the shape that falls out [28]. Oskar Dudycz, in "How to effectively compose your business logic" (event-driven.io), describes why this shape matters for composition: the Decider "groups business logic, state evolution and rebuild together with the initial state," and because it is built on functional composition it lets the developer focus on the business process rather than on wiring [29]. Both authors note the property that makes the Decider distributable: it is a pure function. Given the same command and state it yields the same events, so it can run anywhere the state can be reconstructed, and the events it emits are immutable facts in Helland's sense.

A Decider is also composable in the large. Chassaing's post shows many small Deciders combined into one, and the same machinery expresses a process manager — a Decider whose commands and events are the events and commands of other Deciders [28]. This is the bridge from a single aggregate to a composed system.

## An advanced Decider sketch for a trading engine

The manuscript's worked domain is a trading system with the namespaces ORD (orders), PRT (portfolios), STR (strategies), and JOB (jobs). The following sketch keys each Decider by a branded identity and lets commands and events carry identities and parameters as their only cargo — no shared state, no pointers, in the spirit of Helland's entities. State lives in system-owned stores (manuscript 2.2); the bus (EchoMQ, manuscript 3.5) routes commands and events with exactly-once effect via provenance.

An order-lifecycle Decider, keyed by an ORD identity:

```elixir
# state: :new | {:placed, qty} | {:partially_filled, filled, qty}
#        | :filled | :cancelled
def decide({:place, ord_id, qty}, :new),
  do: [{:placed, ord_id, qty}]
def decide({:fill, ord_id, n}, {:placed, qty}) when n <= qty,
  do: [{:filled, ord_id, n}]
def decide({:cancel, ord_id}, {:placed, _qty}),
  do: [{:cancelled, ord_id}]
def decide(_cmd, _terminal), do: []   # isTerminal => no events

def evolve(:new, {:placed, _id, qty}), do: {:placed, qty}
def evolve({:placed, qty}, {:filled, _id, n}) when n == qty, do: :filled
def evolve({:placed, qty}, {:filled, _id, n}), do: {:partially_filled, n, qty}
def evolve(_s, {:cancelled, _id}), do: :cancelled
```

A portfolio/position Decider, keyed by a PRT identity, consumes the order's `filled` events as its own commands — this is the process-manager composition:

```elixir
def decide({:apply_fill, prt_id, ord_id, n, price}, %Position{} = pos) do
  # provenance guard: has this PRT already absorbed this ORD fill?
  if MapSet.member?(pos.absorbed, ord_id),
    do: [],
    else: [{:position_changed, prt_id, ord_id, n, price}]
end

def evolve(%Position{} = pos, {:position_changed, _prt, ord_id, n, price}) do
  %{pos | qty: pos.qty + n,
          cost: pos.cost + n * price,
          absorbed: MapSet.put(pos.absorbed, ord_id)}
end
```

A risk Decider, keyed by an STR identity, decides whether a placement is allowed before the order Decider ever sees it, and emits a rejection event rather than throwing:

```elixir
def decide({:check, str_id, ord_id, qty, limit}, %Risk{exposure: e})
    when e + qty > limit,
  do: [{:rejected, str_id, ord_id, :limit_breached}]
def decide({:check, str_id, ord_id, qty, _limit}, %Risk{}),
  do: [{:approved, str_id, ord_id, qty}]
```

Three observations connect the sketch to the manuscript. The commands and events carry only branded identities (ORD, PRT, STR) plus scalar parameters, never references to in-memory state — the identity is the only thing that crosses the boundary between Deciders. The provenance guard in the portfolio Decider is Helland's idempotence: the position remembers the ORD identities it has absorbed, matching EchoMQ's row-level provenance. And the composition between Deciders is by message on the bus, not by call — the order Decider's `filled` event becomes the portfolio Decider's `apply_fill` command, routed by the bus with the fencing and fair-lane guarantees of manuscript 3.3 and 3.4.

## LMAX: a data-driven business-logic processor

The trading domain also supplies the canonical data-driven composition example. Martin Fowler's "The LMAX Architecture" (2011) describes a retail financial exchange whose Business Logic Processor, in Fowler's words, "can handle 6 million orders per second on a single thread," running entirely in memory using event sourcing. The processor is single-threaded business logic surrounded by Disruptors — ring-buffer queues that pass events between stages without locks. Fowler attributes the headline figure to its conditions — a 3 GHz dual-socket quad-core Nehalem-based Dell server with 32 GB of RAM — a caveat worth repeating since the number is often quoted bare [30]. LMAX is the proof that the Decider shape scales: pure, in-memory business logic fed by an ordered stream of events, with input and output composed as queues. The manuscript's EchoMQ ring-rotation fair lanes (3.4) and single-owner consumers are the same architecture in a different substrate — composition by an ordered buffer feeding owned logic.

LMAX also demonstrates the immutability lesson: because the business logic is fed by an ordered, replayable event stream and holds state only in memory, recovery is replay, and the same input stream feeds replicas deterministically. This is Helland's immutability and Kreps' log meeting in a production exchange.

## Putting it all together

The appendix can now state its thesis as a conclusion rather than a claim.

Across fifty years and two independent lineages — the object/game lineage of [`bcs.research.1.md`](bcs.research.1.md) and the database/distributed lineage of this chapter — every composition approach resolves into the same three roles: identity names the thing, data holds its state, behavior runs over it. The approaches differ only in where they draw the encapsulation boundary and what they let cross it. Class inheritance drew the boundary around the object and let structure cross by being inherited. Object composition drew it around each collaborator and let behavior cross by reference. The ECS family drew it around the component store and let the entity index cross — but only within one process, because the index is a slot in a privately owned array. Helland drew it around the entity and let messages cross, requiring idempotence because messages repeat. The Decider drew it around a pure function and let events cross as immutable facts.

BCS draws the boundary around the system and lets only the identity cross. That is the whole design, and the research shows it is the limit point of the entire tradition: take the ECS generational handle, which dies at the process boundary, and promote it into a value that survives every boundary. The branded snowflake is that promotion — the distributed generational index.

Each property of the branded snowflake answers a role the literature assigned to a different mechanism. It is typed by a three-character namespace prefix (ORD, PRT, JOB, STR), which is the kind law that traits and component types carried inside the process, now carried in the name itself. It is ordered by mint time through order-preserving base62 encoding, so lexicographic order equals mint order — chronology without a timestamp column, which is Kreps' totally-ordered log property folded into the key. It is placed by a hash32 function, which is Weissflog's system-owned-array idea generalised: the name tells you where the data lives without a central map. And it is contracted identically across Elixir, Node, Go, Rust/C, PostgreSQL, and WebAssembly, so the same name resolves in every runtime — the one thing the in-process handle could never do.

The substrate completes the picture. Valkey is the shared ground on which the systems are composed: the job bus (manuscript 3.1–3.5) is systems composed by messages, with fencing tokens for safety and fair lanes for liveness, which is the log and the Disruptor in one; the caches (Part IV) are composition-safe read paths whose snowflake-versioned newer-wins coherence is Helland's immutability applied to reads. The manuscript's stores (2.2, 2.3) are the component tables of the ECS-as-database framing, owned by OTP processes in the actor lineage (2.1), composed as data folds rather than storage-class moves (2.4), with relations themselves treated as systems (2.5) in the spirit of Codd.

The reader should take from this appendix a single corrective. The ECS literature is often read as advice about memory layout. Read across the whole tradition, its real subject is the boundary: what is a system, what does it own, and what is allowed to leave it. BCS's answer is that a system owns its state and behavior outright and exposes nothing but names, and that a name engineered to carry kind, chronology, and placement, and to mean the same thing in every runtime, is enough to compose anything. The branded snowflake is not a smaller pointer. It is the pointer that survived being thrown across the network, the disk, and the language barrier, and came back still meaning what it meant.

### References

11. Helland — Life beyond Distributed Transactions (entities, messaging, idempotence by remembering): [ics.uci.edu](https://ics.uci.edu/~cs223/papers/cidr07p15.pdf)
26. Helland — Immutability Changes Everything (immutable data to coordinate at a distance): [queue.acm.org](https://queue.acm.org/detail.cfm?id=2884038)
27. Kreps — The Log: What every software engineer should know (the log as a totally-ordered unifying abstraction): [engineering.linkedin.com](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying)
28. Chassaing — Functional Event Sourcing Decider (decide/evolve/initialState/isTerminal): [thinkbeforecoding.com](https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider)
29. Dudycz — How to effectively compose your business logic (Decider as composed business logic): [event-driven.io](https://event-driven.io/en/how_to_effectively_compose_your_business_logic/)
30. Fowler — The LMAX Architecture (single-threaded business-logic processor, 6M TPS, Disruptors): [martinfowler.com](https://martinfowler.com/articles/lmax.html)
