# Valkey: Architecture, Operations, and the Second Posture

A four-part series on Valkey, the BSD-licensed, Linux Foundation-governed fork of Redis 7.2.4. 
The ideas behind the engine, its multi-threading model seen from BEAM clients, two concrete Fly.io topologies, and a closing chapter that designs the custom Valkey connection inside EchoMQ Core, moving the transport toward the Branded Component System with open source (OSS) in mind.

The series inherits the standing decisions that EchoMQ is ValKey-native, speaks its own wire (`emq:{q}:<type>` keyspace, the braced `{emq}:` reserve, every Lua key declared, the `echomq:2.0.0` fence), and persistence is deferred with primary storage focus on Dragonfly. Nothing here reverses that. 
The argument of chapter 4 is narrower and stronger: the v2 discipline, declared keys and per-queue hashtags, is exactly what the Redis-cluster lineage requires, so the same wire stands on Valkey unchanged, and that second posture is what an OSS release of EchoMQ Core needs.

Version context: Valkey 9.1 (May 2026) on the 9.x line, with 9.0.4 the patch current on 9.0; Dragonfly 1.x; Redis 8 under its tri-license.

## Chapters

| # | Topic file | Scope |
|---|------------|-------|
| 1 | `valkey.evolution.md` | The fork as a founding idea, governance as architecture, and the engineering thesis: evolve the proven core, thread the edges, modernize the memory plane release by release |
| 2 | `valkey.beam.md` | Valkey's I/O-threading model from the BEAM: why pipelines outrank pool size, where the Dragonfly tuning advice inverts, RESP3 push frames and client tracking |
| 3 | `valkey.fly.md` | Dedicated Valkey machine plus colocated local replica on Fly.io: AOF durability, replication churn under deploys, memory economics of the 8.1+ hashtable |
| 4 | `valkey.core.md` | The custom Valkey connection as EchoMQ Core: the transport as a BCS system, identity-driven placement, the vkc rungs under emq.7, and the OSS posture |

## Reading order

Read in sequence, or read chapter 4 alone if the question is how EchoMQ Core should connect. Chapters cross-reference the Dragonfly series (`dragonfly.md` and its chapters) where the engines diverge; the contrasts are the point. Chapter 4 assumes the BCS preface's law in three clauses and the v2 protocol break as given.

## Scope notes

Identifiers in code samples follow the branded Snowflake convention (`VAL0KHTOWnGLuC` style, contract vectors in `contract.md` with `vectors.json` beside it). 
Surfaces the roadmap will build are written as plans, never as existing references, per series conventions.
