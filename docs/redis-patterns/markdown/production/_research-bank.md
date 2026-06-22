# R8 · Production & Operations — Citation Bank

> Research-support note (NOT a course page — no route). Source-of-record for the verified figures,
> source URLs, and in-repo grounding that the R8 case studies and the three "You might not need X"
> articles draw on. Produced by the `/deep-research` fan-out (5 angles → 21 sources → 104 claims →
> adversarial verify), 2026-06-08. Read the companion `_research-reasoning.md` for how these were
> selected and which verdicts to trust.

## How to use this file

Two tiers of citation, kept strictly separate:

- **VERIFIED (web).** Two production case studies that survived triple-vote adversarial verification.
  Cite the figures as the source's own framing; both are first-party engineering blogs.
- **IN-REPO (authoritative).** The queue/Kafka mechanics did **not** survive verification as web claims
  (the verifier stage crashed — see reasoning doc), so they are grounded where the course already
  mandates: the real code in `echo/apps/echomq` and the `docs/echomq` specs. This is the *stronger*
  grounding, not a fallback.

The external Kafka/microservices blogs below are **opinion-tier** — use them as "voices in the field,"
never as load-bearing fact.

---

## 1. Verified case studies (new R8 material)

### Uber — Global Rate Limiter (GRL)

- **URL:** https://www.uber.com/blog/ubers-rate-limiting-system/ (primary, Uber Eng, Feb 2026)
- **Corroboration:** https://www.infoq.com/news/2026/02/uber-openai-rate-limiting/ (secondary)
- **Verification:** 3 claims, each **3-0 confirmed**.
- **Verified figures (verbatim framing):**
  - Processes **~80 million requests/second across more than 1,100 services**.
  - Uber concluded that **"hundreds of Redis clusters would be required to maintain accurate global
    state in real time, adding operational complexity and new failure modes."**
  - **"A fully distributed architecture, where local proxies make enforcement decisions using
    aggregated load instead of a central counter, was the only way to achieve both low latency and
    global scalability."**
- **Serves:** *You might not need microservices* (distributed-vs-centralized spine).
- **Honest framing:** this is a case where centralized Redis state was **deliberately rejected** at
  extreme scale. It cuts both ways and *tempers* any "Redis solves everything" reading — that tension
  is what makes the article credible. Distinct from the existing R8 `uber-resilience` page (a different
  Uber artifact).

### Abnormal AI — scaling out Redis

- **URL:** https://abnormal.ai/blog/abnormal-adventures-scaling-out-redis (primary, John Rak, May 2022)
- **Verification:** 2 claims, each **3-0 confirmed**.
- **Verified figures (verbatim framing):**
  - **"our largest counts dataset was over 400 GB and growing. With our rapid growth, we were on track
    to hit the 636 GB limit in two months."**
  - **"we had no choice but to scale horizontally with Redis Cluster… the dataset is split into chunks,
    typically referred to as shards, and each chunk is managed by a separate Redis server."**
- **Serves:** *You might not need microservices* (Redis Cluster horizontal scale-out half); a clean
  vertical-wall → Cluster-Mode arc for the R8 body.
- **⚠️ Do NOT cite:** the "~340 TB across 500 shards / ~500× increase" multiplier — this was the **one
  claim that got a real refute vote (1-0)**. Drop the headline number.
- **Staleness:** 636 GB was the largest ElastiCache instance in **mid-2022** (a moving AWS target).
  Present it as a 2022 snapshot, or refresh against current ElastiCache limits before publishing.

---

## 2. Article citation map (candidate sources by article)

> Verify each opinion-tier source on disk/at-source before citing; the `/deep-research` verifier did not
> confirm these (its verify stage crashed). They are leads, not facts.

### "You might not need microservices" (Elixir Cluster + Redis Cluster)

| Source | Tier | Use for |
|---|---|---|
| `uber.com/blog/ubers-rate-limiting-system/` | primary ✓ | centralized-state rejection at scale |
| `abnormal.ai/blog/abnormal-adventures-scaling-out-redis` | primary ✓ | single-node ceiling → Cluster scale-out |
| `lakret.net/blog/2023-05-08-elixir-vs-microservices` | blog | BEAM distribution vs service tier |
| `dev.to/pierrelegall/about-elixir-and-the-microservices-architecture-37gi` | blog | Elixir-as-distributed-runtime thesis |
| `tjheeta.github.io/2016/12/16/dawn-of-the-microlith-monoservices-microservices-with-elixir/` | blog | the "microlith" framing |

In-repo spine: the **`echo` umbrella** (Distributed Erlang / libcluster — the F6.8.2 per-machine
`worker_id` + libcluster work in the Portal deploy chapter) is the Elixir-Cluster proof; Redis Cluster
is the data-sharding proof (Abnormal + the `cluster-spec` doc below).

### "You might not need Kafka" (does EchoMQ's emq.md advanced story solve it?)

| Source | Tier | Use for |
|---|---|---|
| `arcjet.com/replacing-kafka-with-redis-streams/` | blog | a real Kafka→Redis Streams swap |
| `dev.to/mtk3d/beyond-the-hype-why-we-chose-redis-streams-over-kafka-for-our-microservices-dmc` | blog | decision rationale |
| `codewithseb.com/blog/redis-streams-practical-guide-vs-kafka` | blog | Streams-vs-Kafka mechanics |
| `mattwestcott.org/blog/redis-streams-vs-kafka` | blog | trade-off table |
| `oneuptime.com/blog/post/2026-03-31-redis-streams-vs-kafka-detailed-comparison/view` | blog | comparison |
| `news.ycombinator.com/item?id=27547983` | forum | practitioner pushback (read for counter-arguments) |

In-repo spine (the real proof): `docs/echomq/emq.md` advanced stories + `echo/apps/echomq`. The honest
"when you DO need Kafka" section comes from the HN thread + the Streams limits (no log compaction across
arbitrary retention, consumer-group semantics differences).

### "Queues done right" (Redis & EchoMQ)

| Source | Tier | Use for |
|---|---|---|
| `redis.antirez.com/fundamental/reliable-queue.html` | primary | antirez's reliable-queue (RPOPLPUSH/LMOVE) |
| `redis.io/docs/latest/develop/use-cases/job-queue/` | primary | the documented job-queue pattern |
| `redis.io/docs/latest/operate/oss_and_stack/management/persistence/` | primary | AOF `everysec` ≈1s window; RDB window |
| `inngest.com/blog/sharding-high-throughput-redis-without-downtime` | primary | high-throughput Redis queue at scale |
| `medium.com/@anvannguyen/redis-message-queue-rpoplpush-vs-pub-sub-...` | blog | RPOPLPUSH vs pub/sub contrast |

In-repo spine (the proof): `echo/apps/echomq/priv/scripts/*.lua` — `moveToActive-11.lua` (RPOPLPUSH into
`emq:{queue}:active`), `moveStalledJobsToWait-8.lua` (reclaim), `moveToFinished-14.lua` (atomic
transition); `EchoMQ.Keys.dedup/2` / `marker/1` (idempotency + `BZPOPMIN` blocking wake);
`EchoMQ.Backoff.calculate/4` (retry math). This is the chapter's existing R3 grounding — reuse it.

### R8 body — Redis Cluster operations

| Source | Tier | Use for |
|---|---|---|
| `redis.io/docs/latest/operate/oss_and_stack/management/scaling/` | primary | 16,384 hash slots, CRC16, online reshard |
| `redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/` | primary | hash tags, async replication, failover |
| `blog.bytebytego.com/p/how-uber-uses-integrated-redis-cache` | secondary | Uber CacheFront (read-scale caching) |

> These Redis-Cluster mechanics (16,384 slots, CRC16, AOF everysec ≈1s, async-replication write-loss
> window, hash-tag co-location) are **standard, true Redis facts**. They appear in the `/deep-research`
> "refuted" list ONLY because the verifier stage crashed (0-0 abstentions), not because they were
> contradicted. Cite the primary redis.io docs directly.

---

## 3. Existing R8 case studies (already built — do not duplicate)

Under `docs/redis-patterns/content/production/`:
- `pinterest-task-queue` · `twitter-internals` · `uber-resilience` · `kernel-tuning`

New additions from this research: **Abnormal AI** (single-node ceiling → Cluster) and the **Uber GRL**
angle (distinct from `uber-resilience`, used for the microservices article).

---

## 4. Source quality ledger

- **Verified-primary (cite figures as own framing):** Uber GRL, Abnormal AI.
- **Primary-authoritative (mechanics):** all `redis.io` docs, `redis.antirez.com`, Inngest.
- **Opinion-tier (voices only):** the Streams-vs-Kafka and Elixir-vs-microservices blogs, HN.
- **Avoid:** Abnormal 340 TB / 500× multiplier (refuted 1-0).
