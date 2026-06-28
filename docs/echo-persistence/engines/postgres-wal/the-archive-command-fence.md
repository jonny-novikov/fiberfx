---
title: "The archive_command is the fence"
id: ep-m11-d2
status: proposed
route: "/echo-persistence/engines/postgres-wal/the-archive-command-fence"
kind: "module 11 · dive 11.2"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive archive-fence SVG (a WAL segment PUT to /wal arbitrated by create-if-not-exists — fresh creates, duplicate is rejected ConditionNotMatch with no clobber and an unmoved frontier); no machine numbers. Forward-tense: this dive teaches a PROPOSED design, not shipped code."
grounded-in: "docs/graft/graft.pg-wal-archive.design.md (Common mechanism — the fence coincidence + bytes-as-blobs/manifest-in-Graft; Arm C — the WAL-archive Volume) · docs/graft/graft.design.md (the create-if-not-exists conditional put / ConditionNotMatch as the commit fence; /segments + /logs keyspaces) · docs/echo-persistence/engines/tigris+fence/the-create-if-not-exists-fence (Module 9 — the fence the engine commits with) · docs/echo-persistence/platform/bus-and-persistence/the-loop-closes (the watermark W derived from the engine's committed frontier) · PostgreSQL Continuous Archiving (archive_command idempotency, WAL segments, timelines)"
renders-to: "engines/postgres-wal/the-archive-command-fence.html"
---

# The archive_command is the fence { id="ep-m11-d2" }

> _Postgres asks one hard thing of WAL archiving: the `archive_command` must be **idempotent**, and it must **never overwrite** a same-named segment with different bytes — break that and point-in-time recovery corrupts. State the requirement plainly and it is already familiar. It is **create-if-not-exists** — the exact conditional put the engine commits with in Module 9. So the PROPOSED WAL archive needs no new fence: a retried or raced archive resolves by the same conditional put failing, and the WAL-archive manifest becomes the authoritative durable frontier — the recovery cut cannot drift from what is committed._

> {style="note"}
> **Forward-tense.** Nothing here is shipped. The `/wal` keyspace and the WAL-archive manifest Volume are PROPOSED in `graft.pg-wal-archive.design.md` (the chosen path is Arm A → Arm B; the Graft-native archive is Arm C, deferred). What is *real* is the mechanism the design rests on — the create-if-not-exists fence the engine already commits with (Module 9, `graft.design.md`). This dive teaches the coincidence, not as-built code.

**Interactive figure.** Postgres hands a WAL segment to its `archive_command`, which PUTs the bytes as a blob into the bucket under the PROPOSED `/wal/{cluster}/{tli}/…` keyspace, beside the engine's own `/segments` and `/logs`. Tap **fresh segment** and the conditional put finds nothing at that key — the object is created (green), a manifest entry is recorded (timeline, segment name, start/end WAL LSN, object key, checksum), and the durable frontier advances one notch. Tap **retry / duplicate** — the same segment name PUT again — and the conditional put refuses: `ConditionNotMatch` (red), no clobber, the existing object and the frontier are untouched. The retry is harmless because the fence makes it harmless.

## §1 What Postgres demands of an archive { id="demand" }

Continuous archiving is how a Postgres cluster earns arbitrary-point recovery: as each write-ahead log segment fills, the server runs the operator's `archive_command` to copy that segment somewhere durable; a restore then replays the base backup forward over the archived segments to a chosen point or timeline. The documentation is blunt about the contract the command must honour — it must return success only when the segment is safely stored, and it **must not overwrite** a pre-existing file of the same name with different content, because a retry, a crash between copy and acknowledgement, or a promoted standby re-archiving can all present the same segment name twice. If the second write clobbers the first with different bytes, the replay reads a segment that does not match the history that produced it, and recovery is silently corrupt. So the archive's hardest requirement is not throughput — it is a **concurrency-and-idempotency** rule: same name, same bytes, exactly once; a duplicate must be refused, not merged.

## §2 The coincidence: that rule is the engine's fence { id="coincidence" }

Read that requirement next to Module 9 and it is the same sentence. The engine's durable commit is a **create-if-not-exists** on the next object in the bucket — `graft.design.md` names it directly: OpenDAL's conditional put, surfaced as `ConditionNotMatch`, *is* the commit fence; the matching `If-None-Match` create-only PUT is the same rule the other way. "Create only if absent; reject if present" is precisely "archive only if this segment name is unwritten; refuse if it already exists." A retried or raced `archive_command` therefore resolves itself: the first PUT creates the segment object, every duplicate PUT comes back `ConditionNotMatch` and is treated as the harmless success the contract wants. There is no clobber to guard against because the store will not admit the second write at all — the same property that keeps the engine's commit chain from forking (Module 9) keeps two copies of one WAL segment from ever disagreeing. The design records this as the **fence coincidence**: *the archive's hardest concurrency requirement is satisfied by a mechanism the engine ships* (`graft.pg-wal-archive.design.md`, "Common mechanism"). No new fence is invented for the money's WAL — the same conditional put arbitrates both.

## §3 Where the bytes land, and where the truth lives { id="manifest" }

The fence settles *whether* a segment is admitted; two more PROPOSED pieces settle *where the bytes go* and *what counts as recovered*. WAL segments are opaque and do not deduplicate, so storing them as engine pages would waste the page model; instead they land as **blobs** in the same Tigris bucket under a new `/wal/{cluster}/{tli}/…` keyspace, sitting beside the engine's own `/segments` and `/logs`. The authority is not the pile of blobs but a small transactional **WAL-archive manifest** — one entry per segment: timeline, segment name, start and end WAL LSN, object key, checksum — held in a per-cluster Graft Volume and committed under the very same fence. That manifest is the **authoritative durable frontier**: a restore reads it to verify a gap-free, single-timeline chain before it replays a byte, so the recovery cut can never run past what is actually committed. This is the same discipline the archive fold already uses on the available-first tier, where the watermark `W` is *derived from the engine's committed frontier* rather than guessed ([the loop closes](/echo-persistence/platform/bus-and-persistence/the-loop-closes)) — the cut follows the commit, never the other way round. The bytes are blobs; the truth is the committed manifest; the arbiter for both is the fence the engine was already built with.

## §4 References & sources { id="refs" }

Echo records:
- graft.pg-wal-archive.design.md — "Common mechanism" (the fence coincidence; bytes-as-blobs, manifest-in-Graft; the `/wal` keyspace) and Arm C (the WAL-archive Volume) — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.pg-wal-archive.design.md
- graft.design.md — the create-if-not-exists conditional put (`ConditionNotMatch`) as the commit fence; the `/segments` and `/logs` keyspaces — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- the create-if-not-exists fence (Module 9) — the fence the engine commits with, reused here for `archive_command` — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo-persistence/engines/tigris+fence/the-create-if-not-exists-fence.md
- the loop closes — the watermark `W` derived from the engine's committed frontier (the same manifest-is-the-truth discipline) — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo-persistence/platform/bus-and-persistence/the-loop-closes.md

External:
- PostgreSQL — Continuous Archiving and PITR (archive_command idempotency / no-overwrite, WAL segments, timelines) — https://www.postgresql.org/docs/current/continuous-archiving.html
- Tigris conditional writes — create-if-not-exists semantics — https://www.tigrisdata.com/docs/objects/conditionals/
- If-None-Match — the conditional header behind a create-only PUT — https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match

---

_Pager: ← Dive 11.1 — Two LSN worlds · Dive 11.3 — A then B, forward-tense →_
