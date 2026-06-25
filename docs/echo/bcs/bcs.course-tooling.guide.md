# The `bcs-*` family — calibrating the consumer courses to the new BCS manuscript

> A usage guide. The new Branded Component System manuscript (`docs/echo/bcs/bcs.N.md`, B0–B8) changed the direction
> of the two courses that door into it — **Redis Patterns Applied** (`/redis-patterns`) and **EchoMQ, In Depth**
> (`/echomq`). The `bcs-*` family is the tooling that brings those courses to the new direction **consistently, from
> one source of truth**, without editing each course's craft skill by hand.

## What changed (why this family exists)

The manuscript was reorganized and extended. Five cross-cutting facts now differ from what the older course tooling
assumes — the **five calibration deltas**:

| # | Delta | Old (stale) | New (canon) |
|---|---|---|---|
| 1 | **Figure source** | `docs/echo/bcs/content/bcs3.*` · `bcs4.*` · `bcsA.md` (**directory now absent**) | `docs/echo/bcs/bcs.N.md` (B0–B8) |
| 2 | **The near-cache** | `EchoCache` (`echo/apps/echo_cache`) | **`EchoStore`** (`echo/apps/echo_store`) |
| 3 | **The worked consumer** | Exchange (`echo/apps/exchange`, **deleted**) | **codemojex** (`echo/apps/codemojex`, manuscript B7) |
| 4 | **The persistence floor** | — (volatile tiers only) | a **new durable tier** (`EchoStore.Graft.*`/CubDB · `echo_graft`/Fjall · Tigris; the durability dial) + a **new door `/echo-persistence`** |
| 5 | **The branded-id canon** | loosely stated | 3-char ns + 11 Base62, epoch `1704067200000`, the boot vectors (`placement("USR0KHTOWnGLuC")=234878118`, …) |

The full, verbatim-grounded statement of each delta lives in the **`bcs-writer`** skill — this guide is the map, the
skill is the law.

## The three pieces

| Piece | Kind | Role |
|---|---|---|
| **`bcs-writer`** | skill (`.claude/skills/bcs-writer/`) | The cross-course **calibration overlay** — owns only the five deltas + the canon digest (chapter map, figure inventory, door map, numbering). Loaded **on top of** a per-course craft skill; never re-skins a page. |
| **`/bcs-reconcile`** | command | Bring **existing** pages of either course to the new direction. Mixed tokens, one run: `R<N>` = redis, `E<N>` = echomq. |
| **`/bcs-author`** | command | Author **new** pages of either course, **born** in the new direction (the greenfield sibling). |

Both commands **route per chapter token** to that course's existing expert + craft skill + identity, then overlay the
`bcs-writer` calibration. They do **not** replace the per-course families — they compose over them.

### How it composes (the layering)

```
  bcs-writer  ── the cross-cutting BCS direction (the 5 deltas, the figure source, the door map)
      │  composed ON TOP OF
      ▼
  redis-course-writer   (R-chapter)        echo-mq-writer   (E-chapter)
      │  contract-sheet identity                │  dark-editorial identity
      ▼                                          ▼  + the [RECONCILE] md shadow
  redis-expert agent                        echo-mq-expert agent  (→ general-purpose fallback)
```

Disagreement rule: on a **cross-cutting fact** (a surface name, the figure source, a door) **`bcs-writer` wins**; on
**identity/craft** (tokens, layout, re-skin vs dark-editorial) the **per-course skill wins**.

## The numbering (and the one collision to know)

- **`R<N>`** → `/redis-patterns`: `R1 caching · R2 coordination · R3 queues · R4 time-delay-priority · R5
  streams-events · R6 flow-control · R7 data-modeling · R8 production-operations` (R0 overview).
- **`E<N>`** → `/echomq`: `E0 overview · E1 protocol · E2 queue · E3 bus · E4 cache · E5 proof`.
- **`B<N>`** → the **manuscript** chapter you ground IN (`docs/echo/bcs/bcs.N.md`) — **the source, never a target**.

> ⚠ **Collision:** `/redis-reconcile` aliases `B<N> → R<N>` (an Operator may write redis-caching as "B1"). In the
> `bcs-*` family that alias is **off**: `B<N>` is always the manuscript, redis is always `R<N>`. So
> `bcs-reconcile R1` means redis-caching; `B1` would mean the manuscript's *Ideas* chapter (a source, not a run).

## Worked invocations

```text
/bcs-reconcile R3 R4 E3
    → redis R3 (queues) + R4 (time-delay-priority): re-skin to contract-sheet (if still dark-editorial) + apply the
      5 deltas + door the durability frontier to /echo-persistence.
    → echomq E3 (the Bus): html/echomq/bus is unbuilt → BUILD-TO-TARGET fresh (dark-editorial, the echo-mq-writer
      model), grounded in EchoMQ.Events + the stream-tier canon, archive folding down to /echo-persistence.

/bcs-reconcile R1
    → redis caching only: EchoCache→EchoStore, Exchange→codemojex, content/bcs4.*→bcs.4.md, EchoStore.Graft door.

/bcs-author echomq bus events-log time-travel archive
    → author the Bus pillar's three modules greenfield, born in the new direction.

/bcs-author R5 streams-events stream-add consumer-groups
    → author redis R5 modules greenfield (born reframed + calibrated).
```

When a chapter is built → `/bcs-reconcile`. When it is entirely new → `/bcs-author`. An **unbuilt echomq pillar**
(like the Bus today) is handled by **either**: `/bcs-reconcile` build-to-target follows the `echo-mq-writer` "rebuild
to target" model; `/bcs-author` is the cleaner choice if there is nothing on disk to bring forward.

## What the family will and won't touch

- **Targets:** `html/redis-patterns/**` + `html/echomq/**` + their md mirrors + each course's TOC/roadmap/door-map/
  llms.txt + the per-chapter `<chapter>.prompt.md`.
- **Source of truth (read-only):** `docs/echo/bcs/bcs.N.md`, the as-built `echo/apps/{echo_mq,echo_store,echo_wire,
  echo_graft,codemojex}` code.
- **Never:** runs `git` (the Operator commits batches out-of-band); the frozen `echo/apps/echomq` (no underscore);
  the deleted `echo/apps/exchange`; a `.out` rung transcript as a figure; the retired `docs/echo/bcs/content/`.
- **Gate:** `go/jonnify-cms/bin/cms` (built `GOWORK=off`), with `--routes-from /echo-persistence=html/echo-persistence`
  added so the new door resolves.

## Disambiguation — three "bcs … writer" names

To avoid confusion among similar names:

- **`bcs-writer`** (this family) = the **cross-course calibration overlay** for `/redis-patterns` + `/echomq`. **It is
  not a course-page craft skill** and does not build `/bcs` pages.
- **`bcs-course-writer`** = the (referenced-but-currently-absent) craft skill for building the **`/bcs` course** pages
  themselves; the **`bcs-expert`** agent names it. The `/bcs` course is the **source** here, not a target of this
  family — building `/bcs` pages is a separate concern. *(Known gap: `bcs-expert` references `bcs-course-writer`, which
  is not present in `.claude/skills/`; restoring it is out of scope for this family.)*
- **`bcs-expert`** = the agent that authors `/bcs` course pages (loads `bcs-course-writer`). Not used by this family.

## Related / owed

- The **per-course families stay** (`/redis-write` · `/redis-reconcile` · `redis-course-writer` · `redis-expert`;
  `/echo-mq-write` · `/echo-mq-reconcile` · `echo-mq-writer`). The `bcs-*` family is the **cross-cutting** layer over
  them; use a per-course command directly when a run is **not** about the BCS direction.
- **Owed corpus cascade (separate, flagged):** the `EchoCache → EchoStore` rename still has to reach the **`/bcs`,
  `/mesh`, `/art`** courses and the manuscript corpus through their own skills — not via a redis/echomq run. The
  `echo-store-rename` memory tracks it.
- **Authority:** the skill `.claude/skills/bcs-writer/SKILL.md` + its `references/bcs-canon.md`. When this guide and
  the skill disagree, the **skill wins**.
