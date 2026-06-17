# Valkey: The Connection Core, Toward BCS, With OSS in Mind

The EchoMQ protocol identity: ValKey-native, an owned wire, the `emq:{q}:<type>` keyspace with the queue hashtag applied transparently, the braced `{emq}:` reserve for cross-queue keys, every Lua key declared, and the `echomq:2.0.0` fence behind which the v1 line froze. This chapter designs the piece that decision makes both possible and necessary: a custom connection layer inside EchoMQ Core, written first against Valkey, that turns the transport into a Branded Component System in its own right and gives the project its open source (OSS) posture. Everything below is a plan with gates, in the series convention: surfaces the roadmap builds, not references to code that exists.

## Why Valkey

Nothing here reopens the standing decision. The observation is structural: the client tuning that engine rewards.

What Valkey adds is the reason to bother: it is the posture an OSS release of EchoMQ Core needs. A library published for strangers cannot make its conformance suite, its examples, or its default docker-compose depend on a BSL engine alone. 
Valkey is BSD-3 under foundation governance, installable from every distribution, runnable in any CI for free, with no vendor able to move the terms [1]. Valkey is the OSS posture, the engine the published conformance table (bcs15's subject) runs on in public, and the durability posture where AOF plus WAIT matter (chapter 3).

## Why an owned connection, not a general client

A general-purpose client is a fine tool optimized for someone else's problem. The connection core earns its existence on five counts, each a place where EchoMQ's protocol wants behavior a generic client cannot promise.

The boot fence is a handshake, not a query. EchoMQ fence is two-way and typed; the transport's startup is HELLO 3, identification, server fingerprint, scripting probe, bundle verification, fence exchange, in that order, and the connection is not usable until the sequence completes. Folding this into supervised connection startup makes an unfenced connection unrepresentable, which is the point of a fence.

The push lane is structural. Chapter 2 made client tracking a third lane beside commands and blocking consumers; RESP3 push frames arrive out of band and must route to EchoCache's coherence layer without touching request/response state. Owning the protocol loop makes the push lane a supervised child instead of a callback bolted to a client built around request/response.

Lanes are first-class. Park-don't-poll means connections whose job is to be blocked; the core models them as owned children of their group lanes with re-arm-on-reconnect semantics, not as pool members that happen to be busy.

Placement is computable from identity. EchoMQ knows its entire keyspace shape, every key carries `{q}` reserve, so cluster routing needs no generic slot map of arbitrary keys; it needs one function from queue identity to slot. A general cluster client solves the hard problem; the core gets to solve the trivial one.

The fifth count is the probe obligation Valkey itself created: since 9.1 the Lua engine is a module [2], so a transport that assumes scripting is a transport that boots into a runtime error. The fence absorbs this as a named check.

## References

1. https://www.linuxfoundation.org/press/linux-foundation-launches-open-source-valkey-community
2. https://valkey.io/blog/valkey-9-1-delivers-improvements-in-security-performance-and-more/
3. https://valkey.io/blog/introducing-valkey-9/
