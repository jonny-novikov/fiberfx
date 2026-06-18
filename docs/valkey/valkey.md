# Valkey: Architecture, Operations, and the Second Posture

A four-part series on Valkey, the BSD-licensed, Linux Foundation-governed fork of Redis 7.2.4. 
The ideas behind the engine, its multi-threading model seen from BEAM clients, two concrete Fly.io topologies, and a closing chapter that designs the custom Valkey connection inside EchoMQ Core, moving the transport toward the Branded Component System with open source (OSS) in mind.

The series inherits the standing decisions that EchoMQ is ValKey-native, speaks its own wire (`emq:{q}:<type>` keyspace, the braced `{emq}:` reserve, every Lua key declared, the `echomq:2.0.0` fence), and persistence is deferred with primary storage focus on Dragonfly. Nothing here reverses that. 
The argument of chapter 4 is narrower and stronger: the v2 discipline, declared keys and per-queue hashtags, is exactly what the Redis-cluster lineage requires, so the same wire stands on Valkey unchanged, and that second posture is what an OSS release of EchoMQ Core needs.

Version context: Valkey 9.1 (May 2026) on the 9.x line, with 9.0.4 the patch current on 9.0; Dragonfly 1.x; Redis 8 under its tri-license.

Beside these four engine chapters runs a companion **library axis**: `valkey.go.md` surveys the valkey-go client library module by module — the dep-free core and its eleven satellites — and `valkey.proposals.md` turns that survey into a port order for the Echo ecosystem, where `echo_wire` is the core's BEAM-native peer. The engine axis is the server on `:6379`; the library axis is the shape of the client that talks to it.

## The engine axis — four chapters

| # | Topic file | Scope |
|---|------------|-------|
| 1 | `valkey.evolution.md` | The fork as a founding idea, governance as architecture, and the engineering thesis: evolve the proven core, thread the edges, modernize the memory plane release by release |
| 2 | `valkey.beam.md` | Valkey's I/O-threading model from the BEAM: why pipelines outrank pool size, where the Dragonfly tuning advice inverts, RESP3 push frames and client tracking |
| 3 | `valkey.fly.md` | Dedicated Valkey machine plus colocated local replica on Fly.io: AOF durability, replication churn under deploys, memory economics of the 8.1+ hashtable |
| 4 | `valkey.core.md` | The custom Valkey connection as EchoMQ Core: the transport as a BCS system, identity-driven placement, the vkc rungs under emq.7, and the OSS posture |

## Reading order

Read in sequence, or read chapter 4 alone if the question is how EchoMQ Core should connect. Chapters cross-reference the Dragonfly series (`dragonfly.md` and its chapters) where the engines diverge; the contrasts are the point. Chapter 4 assumes the BCS preface's law in three clauses and the v2 protocol break as given.

## The library axis

valkey-go is the official Valkey Go client (rueidis-derived); the Echo stack never depends on it, but its shape — a dep-free core plus down-only satellites — is the structural reference for `echo_wire`'s library ambition. Two companion chapters survey it and act on it.

| # | Topic file | Scope |
|---|------------|-------|
| 5 | `valkey.go.md` | The valkey-go module map: the dep-free core (auto-pipelining, RESP3, the command builder) and the eleven satellites (`om`, `valkeyaside`, `valkeylock`, `valkeylimiter`, `valkeyotel`, `valkeyprob`, …), each with its Echo peer and a port verdict — OWNED, BUILT, PROPOSE, ADAPT, or SKIP |
| 6 | `valkey.proposals.md` | The port order: the two flagships (EchoMQ streaming, server-assisted client-side caching), the clean additions with no current peer (a rate limiter, probabilistic admission), and the owned/adapted/skipped rest |

The construction core is already ported and shipped — the `ewr.*` client-core program's Movement I (`EchoWire.Pipe` and its command value + error split, adopted into `echo_mq`). These two chapters chart what remains.

## Scope notes

Identifiers in code samples follow the branded Snowflake convention (`VAL0KHTOWnGLuC` style, contract vectors in `contract.md` with `vectors.json` beside it). 
Surfaces the roadmap will build are written as plans, never as existing references, per series conventions.
