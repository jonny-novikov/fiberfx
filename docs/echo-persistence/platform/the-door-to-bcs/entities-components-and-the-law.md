---
title: "Dive 14.2 — Entities, components & the law"
id: ep-m15-d2
status: established
route: "/echo-persistence/platform/the-door-to-bcs/entities-components-and-the-law"
kind: "module 15 · dive 14.2"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive reference-by-id-vs-embed SVG (the boundary law); no machine numbers."
grounded-in: "docs/echo/mesh/mesh.8.1.md (the law) · echo_data/bcs/archetypes.ex (components-as-data, :extends fold) · echo_data/bcs/edge_store.ex (relation as a system) · notifications.design.md §2 (RGP ref, never embed)"
renders-to: "platform/the-door-to-bcs/entities-components-and-the-law.html"
---

# Entities, components & the law { id="ep-m15-d2" }

> _With storage settled, BCS is a discipline about shape, and it is short. A thing is an identity — a branded id, nothing embedded. Its state is data — plain property bundles, never behaviour modules, so even an archetype is just a bundle composed at read time. And a system is a process that owns its private state and obeys one rule at its boundary: only identities and messages about identities may cross. Reference by id, never embed._

**Interactive figure.** A Broadcast (`BCA`) needs an audience owned by a RecipientGroup (`RGP`). In reference-by-id mode it holds the RGP id and only an id crosses the boundary — when the group changes, it stays fresh. In embed mode a copy of the list crosses in, and the moment the group changes, the copy is stale.

## §1 Components are data { id="data" }

BCS inherits the Entity-Component-System split — identity apart from data apart from behaviour — and sharpens it on the branded id. An **entity** is just a 14-byte id; it carries no record of its own. Its **components** are plain data, property bundles in the tables of the last dive, and crucially they are *only* data — there are no behaviour modules attached to an entity, no class hierarchy of code. This is what lets an **archetype** be data too: an archetype is an `ARC` entity whose value is a property bundle, optionally extending one parent via a single `:extends` link, and an instance carries its archetype's id plus an overrides map. The composed view is not a class lookup; it is a *fold computed at read time* — base bundle first, each descendant merged after, the instance's overrides merged last, right-most wins, at most one `:extends` deep. Inheritance becomes a `Map.merge` reduction over data, with the resolver taking a fetch function so the boundary stays wherever the definitions live. The payoff is that everything about an entity — its identity, its current state, its template lineage — is a value you can store in a table, ship in a message, and replay from a log. There is nothing else to serialize, because there is nothing else.

## §2 The law { id="law" }

The single rule that makes the whole thing compose is about boundaries. A **system** is a process that owns its private state, gated on a branded namespace, and *the only values that cross its boundary are identities and messages about identities* — never a copy of another system's data. So a Broadcast does not hold the recipient list; it holds the `RGP` id and resolves the audience from the group that owns it. A relation like "portfolio holds asset" is not an id list embedded in the portfolio; it is a row keyed by the pair of names `{subject, object}` in an owning `EdgeStore`, which maintains its own forward and reverse indexes and exports neither. The figure shows why the rule is not pedantry: reference by id and there is exactly one copy of the audience, so an edit to the group is seen by everyone who holds its id, instantly and for free; embed a copy and you have created a second source of truth that goes stale the moment the original changes — the dual-write divergence of Chapter 12, reborn at the data-model layer. The law is the same instinct the whole platform runs on: a branded id is the unit that crosses every boundary — between runtimes (Chapter 10), between replicas (Chapter 12), and now between systems — and the data stays home with its owner. That is BCS, and it is the shape the durable floor was built to carry.

## §3 References & sources { id="refs" }

Echo records:
- mesh.8.1.md — the law: a system owns gated private state; only identities and messages about identities cross — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo/mesh/mesh.8.1.md
- notifications.design.md — §2 components-as-data; the RGP referenced by id, never embedded (the BCS law) — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/codemojex/notifications/notifications.design.md
- echo_data/bcs/archetypes.ex — archetypes are data; :extends; the read-time right-most-wins fold — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/echo/apps/echo_data/lib/echo_data/bcs/archetypes.ex

External:
- Entity component system — identity / data / behaviour separation — https://en.wikipedia.org/wiki/Entity_component_system
- Single source of truth — why reference beats embed — https://en.wikipedia.org/wiki/Single_source_of_truth

---

_Pager: ← Dive 14.1 — Tables & Properties · Dive 14.3 — Codemoji on the substrate →_
