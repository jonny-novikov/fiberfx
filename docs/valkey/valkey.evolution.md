# EchoMQ 2.0. backed by Valkey: Evolution and the Ideas Behind It

On March 20, 2024, Redis Ltd. moved Redis from BSD to a dual RSALv2/SSPLv1 model, and within hours Madelyn Olson, an AWS principal engineer with years as a Redis core maintainer, created a fork under the deliberately temporary name placeholderkv, joined by maintainers including Alibaba's Zhou Zhou [1]. 
Eight days later, on March 28, the Linux Foundation announced Valkey: a continuation of Redis 7.2.4 under BSD-3, backed by AWS, Google Cloud, Oracle, Ericsson, and Snap [2]. The first release, 7.2.5, shipped in mid-April 2024. This chapter traces what the project has become since, and the ideas that distinguish its path from both Redis and Dragonfly.

## The founding idea: governance is architecture

Valkey's first design decision was not technical. Placing the project under a foundation with a multi-company technical steering committee was a structural answer to the event that created it: no single vendor can change the license, and the Linux Foundation's framing at launch made the point explicitly, promising community-driven development without surprise license changes [2]. 
The maintainers were not newcomers building a competitor; they were the people who had been building Redis OSS, continuing under a name they could trust.

That founding shape explains the engineering posture that followed. 
A fork inherits its users' production deployments on day one, so compatibility is not a feature, it is the covenant. Where Dragonfly rewrote the engine and chased the protocol, Valkey kept the engine and earned the right to change it incrementally. Every release since has followed the same grammar: hold semantics fixed, attack performance and memory at the edges, and let the cluster grow up.

## The threading thesis: parallelize the edges, not the data plane

Command execution stays on the main thread, preserving the single-threaded semantics that fifteen years of application code assumes, while everything around execution, socket reads, protocol parsing, response writes, moves to asynchronous I/O threads that run concurrently with the main thread.

Valkey 8.0 (September 2024) delivered the first major version of this design, with offloading, command batching, and a measured result on a c7g.16xlarge: throughput rising from roughly 360 thousand to 1.19 million RPS, around 230 percent, with average latency dropping 69.8 percent [3][4]. The companion mechanism is memory prefetching: because I/O threads hand the main thread batches of parsed commands, the engine can prefetch the dictionary entries those commands will touch before executing them, hiding DRAM latency behind useful work [4]. Valkey 9.1 (May 2026) redesigned the threading communication model again, adding up to 17 percent on top and pushing a single server to 2.1 million RPS with nine I/O threads and pipelined load [5].

Valkey buys total semantic continuity and a low-risk upgrade for the installed base, at the price of an execution ceiling, one core ultimately executes commands, where Dragonfly buys per-core data-plane scaling at the price of a transactional coordination layer and a compatibility surface it must chase. Neither is the better idea in general; they are different answers to which property of the 2009 design was sacred.

## The memory plane, modernized release by release

The quieter through-line of Valkey's evolution is memory layout. Valkey 8.0 trimmed per-key overhead in cluster mode by embedding what had been a separate dictionary allocation, about 16 bytes per entry [6]. Valkey 8.1 (April 2025) replaced the chained dict outright with a cache-line hashtable: 64-byte buckets holding up to seven entries with embedded metadata, eliminating the dictEntry allocation, so a lookup costs two memory accesses, bucket then object. The measured result was roughly 20 bytes saved per key without TTL, up to 30 with TTL, and about 10 percent more pipeline throughput from fewer random memory accesses [7][8]. The same release brought SIMD work (hyperloglog merges around 12x faster, BITCOUNT up to 514 percent on AVX2) and an active-defrag rework that cut tail latencies into the sub-millisecond range [7].

Valkey 9.0 (October 2025) continued in kind, zero-copy responses for large replies, SIMD spreading to more commands, Multipath TCP support, and reported around 40 percent more throughput over 8.1 [9][10].

## The cluster grows up

The launch press release promised more reliable slot migration and dramatic scalability work, and 9.0 delivered the centerpiece: atomic slot migration, replacing key-by-key cluster resharding, whose partially migrated states produced redirects, degraded performance, and at worst lost data, with a snapshot-and-stream design where traffic switches over at completion [2][9][11]. 
Alongside it, 9.0 added multiple logical databases in cluster mode and hash-field expiration, and the project demonstrated a 2,000-node cluster sustaining over one billion RPS [9]. Valkey 9.1 added CLUSTERSCAN for cluster-wide key iteration and per-database access controls [5].

For this series, two of these have outsized weight. Hash-field expiration gives per-field TTL inside a hash, a natural carrier for declarative job-metadata lifetimes. Atomic slot migration changes the risk profile of running a sharded store under a queue, because resharding under load is precisely the operation a queue's hot keyspace punishes.

## Extensibility chose modules

Where Redis pulled its module ecosystem through license changes and Dragonfly reimplements selected functionality natively, Valkey built an official module line: JSON, Bloom filters, and vector search arrived as Valkey modules around 8.1 and 9.0 [10][12], and in 9.1 the project moved its own Lua scripting engine into a module [5]. 
That last item is architecturally interesting beyond the security rationale: the scripting engine is now a component with a boundary, and a client cannot assume its presence, it must probe. Chapter 4 turns that obligation into a boot-fence step.

## The license landscape, from this side

Redis added AGPLv3 back with Redis 8 in May 2025, an OSI license restored after fourteen months [13][14], but the fork had already absorbed the distributions, the cloud-managed offerings (ElastiCache and Memorystore among them [15]), and a large share of the contributor base. Valkey's BSD-3 plus foundation governance is the one combination no competitor in the field offers, and it is held by the engine with the most conservative compatibility story. That combination, not raw throughput, is Valkey's deepest moat, and it is the property chapter 4 leans on when EchoMQ Core considers what an OSS release may depend on.

## What the evolution tells us

Three ideas distill. First, a fork's competitive advantage is trust, so Valkey spends its innovation budget where trust is not at stake: I/O, memory layout, SIMD, cluster operations, never command semantics. Second, mechanical sympathy does not require a rewrite; the cache-line hashtable and prefetching recover much of what shared-nothing designs claim, inside the old execution model. Third, governance compounds: every Valkey release since the fork has widened the gap between what a community can promise and what a single vendor can. The next chapter takes the threading model to the client side, where the tuning advice from the Dragonfly series inverts in instructive ways.

## References

1. https://www.thestack.technology/redis-fork-valkey-linux-foundation/
2. https://www.linuxfoundation.org/press/linux-foundation-launches-open-source-valkey-community
3. https://valkey.io/blog/valkey-8-0-0-rc1/
4. https://valkey.io/blog/unlock-one-million-rps/
5. https://valkey.io/blog/valkey-9-1-delivers-improvements-in-security-performance-and-more/
6. https://valkey.io/blog/valkey-memory-efficiency-8-0/
7. https://valkey.io/blog/valkey-8-1-0-ga/
8. https://valkey.io/blog/new-hash-table/
9. https://www.linuxfoundation.org/press/valkey-9.0-delivers-performance-and-resiliency-for-real-time-workloads
10. https://redis.io/blog/what-is-valkey/
11. https://valkey.io/blog/introducing-valkey-9/
12. https://aws.amazon.com/about-aws/whats-new/2025/07/amazon-elasticache-valkey-8-1
13. https://redis.io/blog/agplv3/
14. https://lwn.net/Articles/1019686/
15. https://cloud.google.com/blog/products/databases/memorystore-for-valkey-9-0-is-now-ga
