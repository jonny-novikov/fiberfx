---
name: bcs-writer
description: "Use this skill to CALIBRATE the two BCS consumer courses — 'Redis Patterns Applied' (/redis-patterns) and 'EchoMQ, In Depth' (/echomq) — to the new Branded Component System manuscript at docs/echo/bcs/bcs.N.md (B0–B8, all built). It is a CROSS-COURSE calibration OVERLAY, not a per-course craft skill: it owns only the cross-cutting BCS direction (the bcs.N.md figure source, EchoStore, codemojex, the persistence floor, the refined branded-id canon, the cross-course door map) and is composed ON TOP OF the per-course writer skill (redis-course-writer for an R-chapter, echo-mq-writer for an E-chapter), which still owns each course's HTML craft + visual identity. Triggers: any cross-course reconcile or authoring run that re-grounds redis-patterns and/or echomq pages in the new BCS manuscript — the /bcs-reconcile and /bcs-author commands load this skill first; also 'calibrate the courses to the new BCS specs', 'apply the persistence-floor direction', 'ground this page in bcs.N.md'. The five calibration deltas it enforces: (1) figure source moved docs/echo/bcs/content/bcsN.* (RETIRED/absent) → docs/echo/bcs/bcs.N.md; (2) EchoCache → EchoStore (echo/apps/echo_store); (3) Exchange → codemojex (echo/apps/codemojex; manuscript B7); (4) the persistence floor is a NEW tier + a NEW door /echo-persistence (the durability dial; ETS → Valkey → CubDB EchoStore.Graft.* / Fjall echo_graft → Tigris; Oban the comparison); (5) the branded-id canon refined (3-char namespace + 11 Base62, epoch 1704067200000, the boot-asserted vectors). The single source of truth is docs/echo/bcs/bcs.N.md + the as-built echo/apps code; never invent, never cite a .out transcript, never the retired content/bcsN.* path. Do NOT use as a per-course craft skill (that is redis-course-writer / echo-mq-writer), to BUILD the /bcs course pages themselves (that is the bcs-expert agent + the /bcs course's own craft — the /bcs course is the SOURCE here, not a target), for the echo_mq library build (echo-mq-architect / echo-mq-implementor / echo-mq-evaluator), other jonnify courses, or generic documents."
---

# bcs-writer — the cross-course BCS calibration overlay

This skill is the **single source of truth for the new Branded Component System direction** as it lands on the two
**consumer courses** that door into it: **Redis Patterns Applied** (`/redis-patterns`) and **EchoMQ, In Depth**
(`/echomq`). The new direction is the reorganized manuscript at **`docs/echo/bcs/bcs.N.md`** (B0–B8, all built) — the
preface's added movement (the durable **persistence floor**), **EchoStore** as the near-cache, **codemojex** as the
worked project (B7), and a refined **branded-id contract**. This skill exists so both courses ground in that one
canon **consistently**, without each re-deriving it.

**It is an OVERLAY, not a craft skill.** It owns the *cross-cutting BCS direction* only. The *HTML craft and the
visual identity* still belong to the per-course skill, which you load **alongside** this one:

| Chapter token | Course | Per-course craft skill (load WITH this skill) | Identity it keeps |
|---|---|---|---|
| `R<N>` | `/redis-patterns` | **`redis-course-writer`** (+ `redis-expert` agent) | BCS **contract-sheet**, redis-red `#d6584f` |
| `E<N>` | `/echomq` | **`echo-mq-writer`** | **dark-editorial** + the `[RECONCILE]` md shadow |

> **Read order for any page:** (1) the per-course craft skill (the surface, the gates, the identity), (2) **this
> skill** (the new direction, the five deltas), (3) **[`references/bcs-canon.md`](references/bcs-canon.md)** (the
> chapter map, the figure inventory, the door map, the numbering), (4) the run's `<chapter>.prompt.md`. Where this
> skill and a per-course skill **disagree on a cross-cutting fact** (a surface name, the figure source, a door
> target), **this skill wins** — it is the newer calibration. Where they disagree on **craft or identity** (tokens,
> layout, the re-skin vs dark-editorial rule), the **per-course skill wins** — this overlay never re-skins a page.

## 0. The canon and the no-invent boundary

- **The manuscript is `docs/echo/bcs/bcs.N.md`** (B0–B8 + `bcs.preface.md` + `bcs.toc.md`). It is the **figure
  source** for both courses now. Quote a figure **verbatim** from the `bcs.N.md` chapter that owns it (see the
  inventory in the canon digest), or from the **as-built `echo/apps` code** the manuscript draws from.
- **The retired source.** `docs/echo/bcs/content/bcs3.*` / `bcs4.*` / `bcsA.md` is **gone** (the directory is
  absent). Any tooling, agent def, or page that still cites `content/bcsN.*` is **stale** — re-home the citation to
  `docs/echo/bcs/bcs.N.md`. The scrub `grep -rn 'bcs/content/bcs' <page>` must be **0**.
- **Never invent; never a `.out`.** Cite only a real `echo/apps` surface (verified on disk, with its real arity) or
  a verbatim `bcs.N.md` figure. Never fabricate a module, key, Lua script, field, or arity; never quote a `.out`
  rung transcript or a "PASS N/N" gate dump as a page figure. **Valkey is the only engine** named for the bus/store.

## 1. The five calibration deltas — apply per page, in BOTH courses

These are the cross-cutting facts the new manuscript changes. They override any older statement in a per-course
skill, agent def, command, or page. Each is verbatim-grounded in `bcs.N.md` + the as-built code.

1. **Figure source → `docs/echo/bcs/bcs.N.md`.** Re-home every `content/bcsN.*` citation to the `bcs.N.md` chapter
   that owns the figure (the [canon digest](references/bcs-canon.md) maps chapter → figure home). The branded-id
   vectors live in `bcs.0.md` / `bcs.2.md`; the store figures in `bcs.4.md`; the persistence floor in `bcs.5.md`;
   the codemojex surfaces in `bcs.7.md`.

2. **EchoCache → EchoStore.** The near-cache is **`EchoStore`** (`echo/apps/echo_store` — `Table` / `Ring` /
   `Journal` / `Coherence` / `Keyspace`, keyspace `ecc:{<table>}:<id>`). `EchoCache.*` and `echo/apps/echo_cache`
   are the **old names** (renamed 2026-06-18); the 1:1 module map and the functions/keyspace are unchanged. The
   scrub `grep -rniE 'EchoCache|echo/apps/echo_cache' <page>` is **0**.

3. **Exchange → codemojex.** The worked consumer is **codemojex** (`echo/apps/codemojex` — a Telegram
   emoji-guessing game on the same stack; manuscript chapter **B7**). The old **Exchange** consumer
   (`echo/apps/exchange`, `Exchange.{Gateway,OrderBook,Decider}`) is **deleted** — never cite it. Ground a consumer
   example in a **real `Codemojex.*` surface verified on disk** (`Codemojex.{Game,Board,Scoring,Ledger,Locks,
   RateLimiter,Store,Rooms,CommandWorker,NotificationWorker}` + the Phoenix `codemojex_web`), or in B7. The scrub
   `grep -rniE 'Exchange\.|echo/apps/exchange' <page>` is **0** (the common-noun "in exchange for" is fine).

4. **The persistence floor — a NEW tier and a NEW door.** The manuscript's added movement (`bcs.5.md`,
   `bcs.preface.md`) is the durable substrate beneath the volatile tiers: **ETS head → Valkey bus + L2 → a durable
   local page tier built twice (native Elixir `EchoStore.Graft.*` on CubDB, Rust twin `echo_graft` on Fjall) →
   Tigris remote** behind a create-only `If-None-Match` commit fence. Durability is a **dial** a system turns (hold
   nothing · a bounded in-heap window + checkpoint per K · commit-per-record + replicate off-box); the enqueue hot
   path touches only a small mostly-idle outbox. The comparison named is **Oban** (jobs in the same Postgres as the
   data → one transaction; Echo gives that up, buys an in-memory hot path + the dial). Where a redis or echomq page
   reaches the durability/archive frontier, **door out to `/echo-persistence`** (a real built course,
   `html/echo-persistence`, 14 modules) — `bcs.5.md` is the narrative of the same substrate. All the
   `EchoStore.Graft.*` + `echo_graft` surfaces are **real on disk** (verify before citing).

5. **The branded-id canon, refined.** A 14-character name: a **3-character uppercase namespace + 11 Base62**
   characters carrying a 63-bit snowflake `ts(41) | node(10) | seq(12)`, epoch **`1704067200000`** (2024-01-01).
   Four properties: **typed · ordered · placed · conformant**. The figures both courses may cite are the
   **boot-asserted vectors** (`self_check!` in `branded_id.ex`), **not benchmarks** — quote them verbatim:
   - `hash32(274557032793636864) → 234878118` — the **placed** property; native and pure agree (the snowflake `274557032793636864` encodes to the id `USR0KHTOWnGLuC`). The real surface is `EchoData.BrandedId.hash32/1`; `placement(id)` is conceptual shorthand for *parse → `hash32`* — there is **no** `placement/1` function to cite.
   - `parse("USR0NgWEfAEJfs") → {:ok, "USR", 320636799581945856}`
   - `decode("USRzzzzzzzzzzz") → :error` (an overflow is refused, not wrapped)

## 1a. Three standing disciplines (added by the 2026-06-25 reconcile — apply to every echomq run)

Cross-cutting facts the courses keep getting wrong; enforce them alongside the five deltas.

A. **Valkey 9 is the only engine — never Dragonfly.** The owned wire's placement story is **Valkey Cluster
   hash-slots**, not Dragonfly's thread-per-shard: every key of a queue carries the per-queue `{q}` hashtag, so all of
   a queue's keys hash (CRC16 of the brace bytes) to **one of 16384 hash slots** — which is exactly what keeps a
   multi-key Lua script legal (no CROSSSLOT) and co-located. Declared keys + the `{q}` hashtag exist FOR that. Cite
   `https://valkey.io/topics/cluster-spec/` (or `commands/cluster-keyslot/`), never a `dragonflydb.io` page or a
   `--lock_on_hashtags` flag. Scrub: `grep -riE 'dragonfly' <page>` is **0**.

B. **The wire version is `echomq:3.0.0`** — the as-built `@wire_version`
   (`echo/apps/echo_wire/lib/echo_mq/connector.ex:35`). The Stream Tier (EchoMQ 3.x) is shipped and the wire stamp
   has cut over, so `echomq:3.0.0` is the real constant; `echomq:2.0.0` (the retired fork label) and `echomq:2.4.2`
   (a superseded pin) are both **stale** — never teach them. echomq/redis/bcs prose carries **no version labels** (the
   echo-mq-writer as-shipped rule) — never "EchoMQ 2.0", "EchoMQ 3.0", "v1 line", "1.3.0", "three movements", or the
   v1→v2 break narrative in narrative; where a `@wire_version` constant must appear, use `echomq:3.0.0`. Scrub:
   `grep -nE 'echomq:2\.[0-9]\.[0-9]|EchoMQ [0-9]\.[0-9]|v1 line' <page>` is **0**.

C. **Reachability before reconcile — retire orphaned legacy, don't polish it.** A consumer course can carry an older
   generation of pages still *served but unlinked* (the retired echomq E0–E8 numbering left `core/` + `substrate/`
   trees citing the **deleted** Go port `apps/echomq-go` + the **frozen** `echo/apps/echomq`). Before reconciling an
   echomq pillar, check reachability — does any LIVE page (`html/echomq/index.html` + the built pillars) link in? If
   nothing does, the tree is orphaned: **retire it** (remove the html + the md mirror + the sitemap `<url>` blocks)
   rather than spend a reconcile polishing pages that describe deleted code — a blind `sed` "succeeds" on orphans and
   reports green while preserving the stale citations. The live spine is six pillars — **overview · protocol · queue**
   (built) · **bus · cache · proof** (soon); the routes `/echomq/{core,substrate,groups,batches,lifecycle,production}`
   are **gone** (retired 2026-06-25).

## 2. How to apply — compose, do not re-skin

For each page the run touches:

1. **Load the per-course craft skill first** (the table above) and obey its identity + gate rules. **This overlay
   never changes a page's visual identity** — redis re-skins to contract-sheet *per `redis-course-writer`*; echomq
   stays dark-editorial *per `echo-mq-writer`*. The deltas are **content + grounding**, not skin.
2. **Apply the five deltas** to every grounded figure, surface name, door, and id vector on the page. Re-verify each
   cited `echo/apps` surface on disk and each `bcs.N.md` figure in its chapter before shipping.
3. **Provenance discipline (the verbatim-figure rule).** The manuscript's worked examples are committed figures —
   keep them **verbatim** when quoting the manuscript (e.g. `bcs.2.md` teaches with the illustrative brands `PLR` /
   `ROM`). A page's **own** consumer example uses the **live app's real brands**, verified via `generate!` on disk —
   the cm.* rename made them `PLR` · `ROM` · `GAM` · `GES` · `JOB` · `TXN` · `SES` · `CMD` · `NOT` · `EMS`, so the
   live `PLR`/`ROM` **coincide** with bcs.2's illustrative `PLR`/`ROM` (`USR`/`RMM`/`RND` are pre-rename and NOT
   minted). Verify every page-own brand with `grep generate!("XXX") echo/apps/codemojex` rather than trusting a brand
   list — and real `Codemojex.*` surfaces likewise. Do not rewrite a quoted manuscript figure to the app's brands.
   (This is the same discipline that kept the committed worked-queue figures intact during the redis re-home.)
4. **Gate + scrub** with the BCS calibration scrubs (§3) on top of the per-course gate.

## 3. The calibration scrubs (run on every touched page, on top of the per-course gate)

```bash
P=<page-or-dir>
grep -rniE 'EchoCache|echo/apps/echo_cache'        $P && echo "DELTA2 FAIL" || echo "EchoStore OK"
grep -rniE 'Exchange\.[A-Z]|echo/apps/exchange'    $P && echo "DELTA3 FAIL" || echo "codemojex OK"
grep -rn  'bcs/content/bcs'                         $P && echo "DELTA1 FAIL (retired figure source)" || echo "bcs.N.md OK"
grep -rniE 'dragonfly'                              $P && echo "ENGINE FAIL (Valkey 9 only — §1a.A)" || echo "Valkey OK"
grep -rnE  'echomq:2\.[0-9]\.[0-9]|EchoMQ [0-9]\.[0-9]|v1 line'  $P && echo "VERSION FAIL (wire is echomq:3.0.0, no version label — §1a.B)" || echo "as-shipped OK"
grep -rnoE '(EchoStore|EchoMQ|EchoWire|Codemojex)\.[A-Za-z.]+' $P | sort -u   # re-find each on disk in echo/apps/
grep -rn  '234878118\|1704067200000\|USR0KHTOWnGLuC' $P   # id vectors, if cited, must be verbatim (delta 5)
```

A `/echo-persistence` door is gate-resolvable only with its mount — the commands add
`--routes-from /echo-persistence=html/echo-persistence`. If a course is not yet wired to door there, **`<strong>`-name
the destination, do not hard-link it** (the per-course manifest rule).

## 4. The family + the guide

- **`/bcs-reconcile R<N>… E<N>…`** — bring EXISTING pages of either course to the new direction (the cross-course
  reconcile engine; for an unbuilt echomq chapter it builds-to-target, the echomq model). Loads this skill.
- **`/bcs-author <course> <chapter> <module…>`** — author NEW pages to the new direction (the cross-course
  greenfield engine). Loads this skill.
- **The usage guide:** [`docs/echo/bcs/bcs.course-tooling.guide.md`](../../../docs/echo/bcs/bcs.course-tooling.guide.md)
  — what each piece is, when to reach for which, the numbering, and worked invocations.

**Never run git** in an authoring/reconcile agent — leave changes in the working tree; the Operator commits batches
out-of-band. **Never** touch the frozen `echo/apps/echomq` (no underscore) or `echo/apps/exchange` (deleted).
