# EchoMQ course (protocol + queue) — BCS-direction calibration brief (persistent prompt)

> **Who reads this & how.** A `general-purpose` agent (no `echo-mq-expert` is registered) calibrating ONE echomq
> chapter to the **new BCS direction**. Read **both** skills — **`echo-mq-writer`** (the dark-editorial craft; note its
> ⚠ BCS CALIBRATION banner) AND **`bcs-writer`** (`references/bcs-canon.md`). This is an **ADDITIVE, LIGHT** reconcile:
> the chapter is **already** grounded in real `echo/apps/echo_mq` code (EchoMQ.{Jobs,Keyspace,Lanes,Consumer,Stalled,
> Flows,Admin,…}) with **0 Exchange / 0 EchoCache / 0 content-bcs** and the correct stamp epoch. **Do NOT re-skin** (the
> course stays dark-editorial), **do NOT rebuild** clean pages, **do NOT add versions**. Apply only the two deltas that
> are genuinely missing, where they ground, and verify the rest. Engine: `/bcs-reconcile` (echomq E1/E2).

## The per-course discipline (unchanged — `echo-mq-writer`)
Dark-editorial; as-shipped voice, **no version labels**; extract-and-annotate (two-beat Lua, no `file:line`); the
**`[RECONCILE]`** marker lives **only in the md** at a claim ahead of as-built code; **never** the frozen
`echo/apps/echomq` (no underscore: `EchoMQ.Keys`/`LockManager`/`Scripts`/`Worker`/`moveToActive` → 0). Every page stays
gated A+; preserve every interactive/SVG/pager/crumb/footer + the `EMQ…` stamp.

## The two deltas to apply (additive — only where they ground)

**DELTA-4 — the persistence floor + the `/echo-persistence` door (the headline new-direction work, strongest on the QUEUE).**
The Bus/queue reaches a durable floor: a trimmed stream segment, a dead-lettered job, a checkpoint, an archived
completion lands on the durable page tier. Where a page teaches the **durability frontier** (completion + recovery,
dead-letter, lifecycle controls / checkpoints, the workshop, the chapter landing's "applied"/door area), add:
- a **`/echo-persistence` door** (a real hard link — the gate mounts `--routes-from /echo-persistence=html/echo-persistence`),
  named as "the durable floor, taught in full in Echo Persistence";
- a one-line grounding to **`EchoStore.StreamArchive`** (folds trimmed segments into the Graft floor) → **`EchoStore.Graft`**
  (CubDB) → **Tigris**, per `docs/echo/bcs/bcs.3.md` B3.3 / `bcs.5.md`. `EchoStore.StreamArchive` + `EchoStore.Graft`
  are **real on disk** (`echo/apps/echo_store/lib/echo_store/{stream_archive,graft}.ex`) — verify before citing.
- Where the Bus's **Stream Tier** depth (time-travel, the archive read-path) is specified in canon rather than on disk,
  keep the `[RECONCILE]` marker in the **md only** (the HTML reads as shipped). The archive *fold* itself is real code.
- **Do NOT force a door** onto a page with no durability frontier (pure admission/fairness/orchestration) — additive, not blanket.

**DELTA-5 — the refined branded-id canon (strongest on PROTOCOL / immutability-and-branded-ids).**
Where the page teaches the id contract, state it to the refined canon and cite the boot-asserted vectors verbatim:
- 14 characters = a **3-character uppercase namespace + 11 Base62** over a 63-bit snowflake `ts(41)|node(10)|seq(12)`,
  epoch **`1704067200000`**. ("14-byte" is acceptable manuscript wording; prefer adding the 3-char-ns/11-Base62 breakdown.)
- The vectors (source truths, not benchmarks): `placement("USR0KHTOWnGLuC") → 234878118` ·
  `parse("USR0NgWEfAEJfs") → {:ok, "USR", 320636799581945856}` · `decode("USRzzzzzzzzzzz") → :error`. Figure home:
  `docs/echo/bcs/bcs.0.md` / `bcs.2.md` — cite verbatim. The branded `JOB` id is gated at the key builder (`EchoMQ.Keyspace`).

## What to VERIFY (no change if already true)
0 `Exchange.`/`echo/apps/exchange`; 0 `EchoCache`/`echo/apps/echo_cache`; 0 `bcs/content/bcs`; 0 frozen-tree; every
`EchoMQ.*`/`EchoStore.*` re-found on disk; the redis doors point at the **reconciled** chapters (`/redis-patterns/queues`
R3, `/redis-patterns/time-delay-priority` R4 — both now contract-sheet); the `.applied` block (queue landing) links those.
If a page already satisfies the direction and has no durability/id frontier, **leave it unchanged**.

## Gate (ship at STATUS: PASS)
```bash
FLAGS="--routes-from /echomq=html/echomq --routes-from /redis-patterns=html/redis-patterns --routes-from /bcs=html/bcs --routes-from /elixir=elixir --routes-from /echo-persistence=html/echo-persistence --require-refs"
go/jonnify-cms/bin/cms check ${=FLAGS} html/echomq/<chapter>/<page>.html
```
Then: 0 `[RECONCILE]` in the HTML; 0 frozen-tree; no version label in prose; the `/echo-persistence` door resolves; the
md mirror (`docs/echo_mq/course/markdown/<route>.md`) carries any `[RECONCILE]` marker. **NEVER git.**

## Inputs
- Skills: `echo-mq-writer` (+ `references/course-map.md`) + `bcs-writer` (+ `references/bcs-canon.md`).
- As-built: `echo/apps/echo_mq/lib/echo_mq/` · `echo/apps/echo_store/lib/echo_store/{stream_archive,graft}.ex`.
- Manuscript: `docs/echo/bcs/bcs.3.md` (B3 bus, B3.3 Stream Tier), `bcs.5.md` (the floor), `bcs.0`/`bcs.2` (id vectors).
- Door target: `/echo-persistence` (`html/echo-persistence`, real built course).
