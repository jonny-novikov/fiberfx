# Redis Patterns

A curated, LLM-first knowledge base of Redis **design patterns** — not an API reference.
Each document answers *"what problem does this solve, how do I solve it in Redis, what are
the trade-offs, and when should I reach for it?"* — the judgement layer that raw command
docs leave out.

> **Scope note.** These patterns are specific to **Redis** ([redis.io](https://redis.io)).
> They may not hold for Redis-compatible forks (Valkey, KeyDB, Dragonfly); verify against the
> fork's docs before relying on them.

---

## What is authored here (the content worth keeping)

The authored work is **31 files (~560 KB)**: one index, one machine map, and **30 pattern
documents**. Everything else in `content/commands/` is a *scraped mirror* (see the boundary
section below) and is **not** authored.

| Path | What it is |
|---|---|
| `content/course.html` | Human-facing landing page — the patterns grouped into three sections, with one-line descriptions and links to each doc's `html` + `markdown` form. |
| `content/llms.txt` | Machine-facing entry point ([llmstxt.org](https://llmstxt.org) convention). An agent fetches this **first**, reads the one-line description of every pattern, then retrieves only the `.md` files it needs. |
| `content/fundamental/` | **20 core architectural patterns** (see list below). |
| `content/community/` | **6 community use-case patterns.** |
| `content/production/` | **4 real-world case studies** (Pinterest, Twitter/X, Uber, kernel tuning). |

Every pattern ships as a **pair**: `name.html` (styled, for humans) and `name.md.txt` (raw
Markdown, for agents). The `.md.txt` extension is a **serving trick** — a static host returns
it as `text/plain`, so an agent fetches clean Markdown instead of an HTML download. It is *not*
a sign of machine-generation; the `.md` is the source of record.

### The 30 patterns

**Fundamental (20):** atomic-updates · cache-aside · cache-stampede-prevention ·
client-side-caching · cross-shard-consistency · delayed-queue · distributed-locking ·
hash-tag-colocation · lexicographic-sorted-sets · memory-optimization ·
probabilistic-data-structures · rate-limiting · redis-as-primary-database · redlock ·
reliable-queue · streams-consumer-patterns · streams-event-sourcing · vector-sets ·
write-behind · write-through

**Community (6):** bitmap-patterns · geospatial · leaderboards · pubsub ·
session-management · vector-search-ai

**Production (4):** kernel-tuning · pinterest-task-queue · twitter-internals · uber-resilience

### Anatomy of a pattern document

Every `.md` follows the same shape — chosen deliberately for machine consumption:

```
# <Pattern Name>
<one-line summary — identical to its llms.txt description>
<intro paragraph: the trade-off space and what the doc covers>

## <Technique A>
<prose>

    INCR ratelimit:user123:1706648400          ← 4-space-indented command block,
    EXPIRE ratelimit:user123:1706648400 60        plain text, copy-pasteable, no lang tag

**Advantage**: ...
**Disadvantage**: ...

## <Technique B>
...
```

The docs are **self-contained**: Redis commands appear as inline code, never as links; the only
outbound links are to the index (`../index.html`) and to sibling patterns. So a pattern doc
stands alone — an agent that fetches one needs nothing else to act on it.

---

## Why write Redis patterns *for LLMs*? — the 5W1H

This is the rationale for the project: why a curated, agent-oriented pattern library is worth
authoring at all, and what makes it beneficial.

### Why (the core reason)

LLM coding agents already *know Redis commands* — but they reach for the wrong **pattern**.
Training data is a mix of generations and dialects, so an unguided agent will: suggest
`SETEX`/`GETSET` where `SET … NX PX` is now idiomatic; implement a "distributed lock" that a
single node failure silently breaks; promise Redlock guarantees it doesn't provide; fan keys
across cluster slots and then call `MULTI` on them (a cross-slot error); or pick a fixed-window
rate limiter without knowing the boundary-burst flaw. The commands aren't the gap — the
**decision and the trade-off awareness** are. A curated pattern library **grounds the agent in
correct, current, trade-off-aware usage**, which is exactly what cuts hallucination and the
"plausible but wrong at scale" failure mode.

### Who

The primary reader is an **LLM coding agent** generating or reviewing Redis code; the secondary
reader is the **human developer** steering it (the `course.html` view is for them). Both consume
the *same* source — there is one set of patterns, rendered two ways.

### What

**Patterns, not API docs.** Each file is a problem→solution→trade-offs→when-to-use unit, written
as plain Markdown with inline command blocks and explicit Advantage/Disadvantage callouts. The
content is the part an agent *can't* reliably reconstruct from its weights: which approach fits
which workload, and why.

### When

At **code-generation and code-review time.** The intended loop: the agent fetches `llms.txt`,
scans the one-line descriptions, pulls the one or two `.md` files relevant to the task, and
writes Redis code grounded in them. On the authoring side, patterns are revised when Redis ships
a better primitive (e.g. native Vector Sets in Redis 8) or a pattern's guidance changes.

### Where

The patterns live in this directory and are served as **static `text/plain`** — no build step,
no database, no API. That makes them **fetchable by any agent from any host**, and trivially
embeddable in a RAG index or shipped alongside an app. Self-contained docs travel well.

### How

1. **One entry point** — `llms.txt` lists every pattern with a description, so an agent spends
   one fetch to decide what to read, not N fetches to discover what exists.
2. **Plain Markdown, inline commands** — no Hugo/templating shortcodes, no link-chasing. What the
   agent reads is what it runs.
3. **Decision-framed** — every technique carries Advantage / Disadvantage / when-to-use, so the
   agent picks rather than guesses.
4. **Self-contained + cross-linked** — each doc works alone, and related patterns link to each
   other so an agent can widen scope deliberately.

---

## Authored content vs. the scraped mirror (operational boundary)

`content/commands/` (~118 MB, ~7,000 files) is **not authored** — it is a verbatim crawl of the
official Redis docs repo ([github.com/redis/docs](https://github.com/redis/docs)). The tell:
those `.md.txt` files still contain unrendered Hugo shortcodes like
`{{< relref "/commands/acl-cat" >}}`, which only the upstream build pipeline renders. It is
**regenerable from upstream** and carries the mp4 screencasts, PNG screenshots, and fonts that
make this directory heavy.

| Layer | Size | In git? | Source |
|---|---|---|---|
| **Authored patterns** — `course.html`, `llms.txt`, `fundamental/`, `community/`, `production/` | ~560 KB | **keep** | hand-written here |
| **Mirror** — `content/commands/` + `content/**/static/` media | ~118 MB+ | **ignore** | scraped from `github.com/redis/docs` (re-fetchable) |

> **Dependency note.** The 30 pattern docs cite commands as *inline code*, so they do **not**
> depend on the local mirror. Only `course.html`'s "Commands Reference" block links into
> `content/commands/`; repointing those few links to `https://redis.io/commands/` fully decouples
> the authored course from the mirror, after which the mirror can be dropped with zero breakage.
