---
title: "Module 15 — The door to BCS with Echo Persistence"
id: ep-m15-hub
status: established
route: "/echo-persistence/platform/the-door-to-bcs"
kind: "module 15 hub — Chapter IV finale, 3 dives"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive substrate-to-BCS stack SVG; no machine numbers."
grounded-in: "docs/echo/mesh/mesh.8.1.md (the BCS law) · docs/codemojex/notifications/notifications.design.md §2 (entity/component model) · echo_data/bcs (PropertyStore, Archetypes, EdgeStore) · graft.engine-split.design.md (EchoStore.Table + Coherence)"
renders-to: "platform/the-door-to-bcs/index.html"
---

# The door to BCS with Echo Persistence { id="ep-m15-hub" }

> _Thirteen modules built a durable floor: a versioned log, an L1 read cache, newer-wins coherence, replication, a bus — all keyed by one 14-byte branded id. That floor was never the point; it was the threshold. Step through it and the same primitives stop being plumbing for a queue and become the substrate for a way of building systems — the Branded Component System: entities are identities, components are data, and a system is a process that lets only identities cross its boundary._

**Interactive figure (hub).** Three stacked storeys: the durable substrate of EP1–13 (commit log, `EchoStore.Table`, newer-wins coherence, keyed by branded id), a door at the threshold, BCS in the middle (entities = ids, components = data, systems = processes), and the codemojex apps on top. Tap a storey to see what it contributes.

## §1 From plumbing to substrate { id="substrate" }

Look back at what the durable floor actually produced, and notice that none of it is queue-specific. A **versioned commit log** (Chapter III) gives every value a durable, replicated history. An **L1 read cache**, `EchoStore.Table` on ETS, gives lock-free reads of the current head. **Coherence**, `EchoStore.Coherence`, keeps that cache correct with a newer-wins rule whose version *is the 14-byte branded id* — because a branded id sorts lexicographically in mint order, "newer" is just "greater id," and the cache update is "a message about a name." Set those three side by side and they describe a general capability: durable, replicated, coherent state, addressed by identity, read without locks. That is not the description of a job queue; it is the description of a place to keep *any* system's state. The queue was simply the first thing the platform built on it — the load-bearing proof that the floor holds. That reading is one of two the platform deliberately holds open. Read the other way, the bus is not merely the first tenant of a finished floor but a co-equal member of the commit-LSN loop — the engine's commit drives the bus, and the archive fold makes the bus drive the engine's commit — and it is the platform's live development frontier (the Stream Tier, emq3.5). So the substrate framing here does not settle which member *leads* the development path: bus-led (finish the frontier, then this door) and engine-led (deepen the floor toward its durability north star) are both defensible, and that fork is staged for the Operator in the [`echo-bus-v3` KB](../../../echo_mq/kb/echo-bus-v3/) rather than resolved in this prose. Either way, everything past this point treats the floor as a given and asks a different question: if state is this cheap to keep and this safe to share, what is the right *shape* for the systems that keep it? The answer the platform commits to is BCS.

## §2 The three ideas of BCS { id="bcs" }

The Branded Component System is the successor to the Entity-Component-System pattern, re-centred on the branded id, and it is exactly three ideas. **Entities are identities**: a thing is a 14-byte branded id, `{ns}{base62}`, and nothing more — no embedded record, just a name that sorts by birth. **Components are data**: an entity's state is plain property bundles, never behaviour modules, so an archetype is itself just data (an `ARC` entity whose value is a bundle, optionally extending one parent via `:extends`, composed at read time as a right-most-wins fold). **Systems are processes**: a system owns its private state, gated on a namespace, and the only values that cross its boundary are *identities and messages about identities* — the law (`mesh.8.1`). That law is why a relation like "portfolio holds asset" is a row keyed by the pair of names in an owning `EdgeStore`, never an id list embedded in either endpoint; and why an audience is referenced by an `RGP` id, never copied inline. Read against Chapter 13, the fit is exact: the substrate already stores state by branded id and already speaks in "messages about a name" for coherence, so BCS is not a new runtime on top of the floor — it is the discipline the floor was shaped for. The three dives walk these in turn, and then stand Codemoji on them.

## §3 The three dives { id="dives" }

- **Dive 14.1 — Tables & Properties** — state keyed by identity: the property table (an ordered_set on the branded id), the `EchoStore.Table` L1, and newer-wins coherence where the id *is* the version — lock-free reads, recent-first pages. → `/echo-persistence/platform/the-door-to-bcs/tables-and-properties`
- **Dive 14.2 — Entities, components & the law** — entities are ids, components are data, archetypes fold at read time, and the law: a system passes only identities and messages about identities across its boundary. Reference by id, never embed. → `/echo-persistence/platform/the-door-to-bcs/entities-components-and-the-law`
- **Dive 14.3 — Codemoji on the substrate** — the worked example: the Broadcast system as four branded entities, where the `BDV` id *is* the chronological key, so compaction folds deliveries in mint order with no sort. The course closes. → `/echo-persistence/platform/the-door-to-bcs/codemoji-on-the-substrate`

## §4 Where to go from here { id="next" }

- **The course map** — all fourteen modules are built; open the full map and revisit any module or dive. → `/echo-persistence#map`
- **Begin again · Module 1 · The durability spectrum** — start over from the foundations, the one mechanism (records per fsync), now that you have seen where it leads. → `/echo-persistence/foundations/durability-spectrum`
- **Revisit · Module 14 · Why it beats classical scheduling** — the commit-log-as-outbox that made the substrate worth standing on. → `/echo-persistence/platform/beats-classical-scheduling`

## §5 References & sources { id="refs" }

Echo records:
- mesh.8.1.md — the BCS law: systems own private state; only identities and messages about identities cross — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo/mesh/mesh.8.1.md
- notifications.design.md — §2 the BCS entity / component model; brands BTP / BCA / BDV / RGP — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/codemojex/notifications/notifications.design.md
- graft.engine-split.design.md — EchoStore.Table (L1 ETS) + EchoStore.Coherence (newer-wins, a message about a name) — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md

External:
- Entity component system — the pattern BCS re-centres on the branded id — https://en.wikipedia.org/wiki/Entity_component_system
- Snowflake ID — the time-ordered id behind {ns}{base62} — https://en.wikipedia.org/wiki/Snowflake_ID

---

_Pager: ← Module 14 — Why it beats classical scheduling · Dive 14.1 — Tables & Properties →_
