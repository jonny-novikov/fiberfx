# Jonnify Course Series

## The Agile Agent Workflow

AAW framework and MCP server.

## Functional Programming in Elixir

A bridge from the algebra you already know to real-time systems on the BEAM.

## Redis Patterns, Applied

The judgement layer above the command reference — thirty Redis design patterns, each shown working in a real system. 
Taught as problem → solution → trade-off → when-to-use, then shown where the BCS architecture applies it.

## EchoMQ In Depth

One Valkey, three runtimes, one wire you own — a job queue that is a protocol, not a library.

## The Branded Component System

Boundaries around systems. Identity as a contract.

---
Encapsulation boundaries are drawn around systems, not objects. 
The only values that cross are identities, and messages about identities. 
And identity is a contract — the 14-byte branded snowflake: typed by its namespace, ordered by its mint time, placed by its hash, identical in meaning across five runtimes against one canon.

## The Art of BCS

The runtime is the platform.
The brand carries the state.

---
The Branded Component System taught the law; this course tests it in production. 
For a stateful, soft-real-time system run by one organization, the BEAM subsumes the four systems a production exchange is conventionally built around — a coordinator, a log broker, a message broker, and an orchestrator — and the branded identity carries the system’s state across every store and language. 
The case is built, part by part, to EchoMesh.

The senior continuation of /bcs, taught from one working exchange platform. 
Every figure on every page is a committed gate transcript or a cited source. 
The claim is narrow on purpose: the regulated ledger, deep retention, and the observability sink stay outside the runtime by design. 
EchoMesh, the destination, is a forward concept the course introduces — introduced and built toward, not yet shipped.

## EchoMesh, In Depth