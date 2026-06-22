# R8 · Production & Operations — Research Reasoning Chain

> Research-support note (NOT a course page — no route). The complete reasoning trail behind
> `_research-bank.md`: what was asked, how the `/deep-research` fan-out ran, where it failed, which
> verdicts to trust, and the resulting authoring plan for the three articles. Written 2026-06-08 so the
> R8 author (you, or a `redis-expert` fan-out) inherits the *why*, not just the *what*.

## Step 0 — The question

Gather references/links to author R8 ("Production & Operations") markdown in
`docs/redis-patterns/markdown`, specifically to:
1. add more real **case studies** (existing: Pinterest, Twitter/X, Uber);
2. prepare three "You might not need X" articles —
   - **You might not need Kafka** (does EchoMQ's `emq.md` advanced story solve it?),
   - **Queues done right** (Redis & EchoMQ),
   - **You might not need microservices** (Elixir Cluster + Redis Cluster).

Judged specific enough to research directly — deliverable, existing studies, and three theses were all
named. No clarifying questions needed.

## Step 1 — Decomposition (5 search angles)

The fan-out split the question into five angles, each a parallel WebSearch agent:
1. broad / case-study sourcing
2. contrarian — Redis vs Kafka
3. practitioner — durable Redis queues
4. contrarian — monolith vs microservices
5. technical — Redis Cluster operations

This maps 1:1 onto the deliverables: angle 1 → new case studies; angles 2+3 → the two queue articles;
angles 4+5 → the microservices article and the R8 ops body.

## Step 2 — Search & fetch

21 sources fetched (after URL-dedup dropped 2), 104 falsifiable claims extracted, top 25 sent to
verification (7 dropped on budget). Source mix: 8 primary (redis.io, antirez, Uber, Abnormal, Inngest),
1 secondary (ByteByteGo), the rest opinion-tier blogs + 1 HN thread.

## Step 3 — Verification, and where it BROKE (the load-bearing caveat)

The design is 3-vote adversarial verification per claim (need 2/3 refutes to kill). **It did not run as
designed.** Almost every verifier agent crashed with:

    parallel[N] failed: agent({schema}): subagent completed without calling StructuredOutput

This is the known `workflow-heavy-agent-no-schema` failure mode (see MEMORY): a verifier given a strict
schema finished its reasoning as prose without emitting the StructuredOutput tool call, so its vote was
lost. Result: most claims resolved to **`0-0 (3 abstain)`** — *nobody voted* — and were then bucketed as
"killed."

### What this means for trust

- **`3-0` confirmations are real.** Five claims (Uber GRL ×3, Abnormal ×2) had all three verifiers vote.
  These are trustworthy. → They became the two verified case studies.
- **`0-0` "kills" are NOT refutations.** They are abstentions caused by the crash. The claims in this
  bucket are mostly **standard, true Redis facts** (16,384 hash slots / CRC16, AOF `everysec` ≈1s window,
  RPOPLPUSH reliable queue, hash-tag co-location, async-replication write-loss). Treat as
  *"needs a trusted re-grounding pass,"* never as *"disproven."* Re-ground from primary redis.io docs.
- **`1-0` is the only real refute signal.** Exactly one claim — Abnormal's "340 TB / 500 shards / ~500×"
  multiplier — got a genuine refute vote. That one, and only that one, is dropped.

Final tally reported: 25 verified → 5 confirmed, 20 "killed" (≈18 of which are abstention-artifacts, not
refutations). Read "killed" as "unvoted," with the single 1-0 exception.

## Step 4 — Synthesis decisions

1. **Promote the two `3-0` studies to R8 case-study slots.** Uber GRL (microservices spine), Abnormal
   (Cluster scale-out). Both first-party, recent enough, with verbatim figures.
2. **Demote the queue/Kafka web claims to leads, not facts.** The verify stage can't be trusted for them,
   AND — more importantly — the course's standing mandate is to ground queue mechanics in real code, not
   web prose. So the two queue articles ground in `echo/apps/echomq` + `docs/echomq`, with the web blogs
   as opinion-tier "voices."
3. **Honor the scope mismatch.** The only surviving studies are a **rate-limiter** (Uber) and a
   **counts/anti-abuse store** (Abnormal) — neither is a queue or a Kafka replacement. So:
   - *You might not need microservices* — **strongest**, stands on both verified studies + the `echo`
     umbrella's real Distributed-Erlang/libcluster work.
   - *You might not need Kafka* / *Queues done right* — ground the **mechanics** in-repo; the web supplies
     only the framing debate.
4. **Keep the article theses honest.** A "You might not need X" piece is only credible if it concedes when
   you *do* need X. The Uber GRL study is itself a "Redis-as-central-state was the wrong call" data point —
   embrace that tension rather than hiding it.

## Step 5 — The four open questions (carry into authoring)

From the report, still unresolved and worth closing before publishing:
1. Which `docs/echomq` emq.md advanced stories + `echo/apps/echomq` scripts concretely ground the
   Kafka/queue articles? (Reuse the R3 grounding bank: `moveToActive-11.lua`, `moveStalledJobsToWait-8.lua`,
   `moveToFinished-14.lua`, `EchoMQ.Keys.dedup/marker`, `EchoMQ.Backoff`.)
2. Is there a **queue/messaging-shaped** Redis production study (Redis Streams or BullMQ at scale) to
   anchor the Kafka-replacement narrative? (None survived this run — a targeted second search may find one;
   Inngest is the closest lead.)
3. Should Uber GRL be framed as a **caution** (Redis deliberately rejected at extreme scale) rather than a
   Redis win — and how does that reconcile with the course's "Redis applied" thesis? (Recommendation: yes,
   as an honest boundary — it strengthens the microservices article.)
4. What **current (2026)** ElastiCache instance / Redis-Cluster shard limits should replace Abnormal's 2022
   636 GB / 500-shard figures so R8 isn't stale?

## Step 6 — Authoring plan (next task, via `/redis-write`)

For R8 under `docs/redis-patterns/markdown/production/` + the served `html/redis-patterns/production/`:

1. **Case studies:** add **Abnormal AI** (vertical-wall → Redis Cluster) alongside the existing
   Pinterest/Twitter/Uber-resilience; add the **Uber GRL** angle inside the microservices article.
2. **You might not need microservices:** verified Uber GRL + Abnormal + the `echo` umbrella's
   Elixir-Cluster (libcluster, per-machine `worker_id`) + Redis Cluster sharding. Concede: when you
   genuinely need independent deploy/scaling boundaries or polyglot teams.
3. **You might not need Kafka:** ground in `docs/echomq/emq.md` advanced stories + EchoMQ's Lua corpus;
   frame Streams-vs-Kafka from the opinion blogs; concede: log compaction, very-long retention, massive
   fan-out consumer groups.
4. **Queues done right:** reuse the R3 grounding (the reliable-queue family in `echo/apps/echomq`); cite
   antirez + redis.io job-queue + persistence docs for the canonical mechanics.

Every external figure is cited as the source's own framing; every mechanic is proven in real code
(no-invent discipline — verify against `echo/apps/echomq`, never a prose table). See `_research-bank.md`
for the exact URLs and verified quotes.
