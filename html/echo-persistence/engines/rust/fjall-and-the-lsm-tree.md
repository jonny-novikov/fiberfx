---
title: "Fjall & the LSM-tree"
id: ep-m8-d1
status: established
route: "/echo-persistence/engines/rust/fjall-and-the-lsm-tree"
kind: "module 8 · dive 8.1"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive memtable/SSTable/compaction SVG; no machine numbers."
renders-to: "engines/rust/fjall-and-the-lsm-tree.html"
---

# Fjall & the LSM-tree { id="ep-m8-d1" }

> _The Rust engine stores its pages in Fjall, a log-structured merge-tree. Writes land in an in-memory memtable; when it fills, it flushes whole to an immutable SSTable on disk; and compaction reclaims space by merging SSTables and dropping superseded versions. A different shape from CubDB's copy-on-write B-tree, the same promise: files are written once and never mutated._

**Interactive figure.** A memtable in RAM with four slots fills as keys are written (some keys repeat at higher versions). When full it flushes downward to a new immutable L0 SSTable; repeated flushes stack more L0 SSTables. Compaction merges all L0 SSTables into a single L1 SSTable, keeping the latest version of each key and dropping superseded ones, then discards the old files — visibly reclaiming space by merging rather than overwriting.

## §1 Memtable, flush, merge { id="lsm" }

Write keys to fill the memtable; at four, flush it to an immutable L0 SSTable and the memtable clears. Stack a few SSTables, then compact: they merge into one L1 SSTable, keeping the latest version per key and dropping the rest. Nothing on disk is ever rewritten — reads check the memtable, then L0 newest-first, then L1.

## §2 Two shapes, one immutability { id="why" }

CubDB and Fjall solve the same problem from opposite directions. The B-tree writes a new copy of the path on every change and keeps the tree balanced as it goes, so reads are a single descent but each write touches several nodes. The LSM-tree batches writes in memory and flushes them sequentially, so writes are cheap and append-only, but a read may have to check the memtable and several SSTables, and space is reclaimed later by compaction. What matters for the Volume contract is that both are immutable on disk: a flushed SSTable, like a written CubDB block, is never overwritten, so old versions stay readable and a crash can only lose the un-flushed memtable tail — which the commit log replays (Module 6). The engine picks the LSM shape for write-heavy page churn; the guarantees the rest of the platform depends on are unchanged.

## §3 References & sources { id="refs" }

External:
- fjall-rs/fjall — the LSM-tree storage engine — https://github.com/fjall-rs/fjall
- Log-structured merge-tree — memtable, SSTables, compaction — https://en.wikipedia.org/wiki/Log-structured_merge-tree
- B-tree — the other shape (CubDB, Module 4) — https://en.wikipedia.org/wiki/B-tree

Echo records:
- graft specs / graft.1.md — eg.1 — the core fork (Fjall retained, libgraft_ext removed) — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/specs/graft.1.md
- graft.roadmap.md — eg.1 — the core fork; Fjall retained as the local store — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md
- graft.engine-split.design.md — echo_graft on Fjall, the LSM local store — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- store.design.md — local page tier, flush + compaction — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

---

_Pager: ← The Rust engine · Dive 8.2 — OpenDAL & the portable remote →_
