---
title: "Module 4 — CubDB architecture"
id: ep-m4-hub
status: established
route: "/echo-persistence/local-store/cubdb"
kind: "module 4 hub — Chapter II, 3 dives"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive write-path SVG; no machine throughput numbers."
renders-to: "local-store/cubdb/index.html"
---

# CubDB architecture { id="ep-m4-hub" }

> _The durable local tier is a single embedded database: CubDB, an append-only, immutable B-tree on one file. Every property the native engine relies on — crash-safe commits, free snapshots, the page log itself — is a consequence of those two words, append-only and immutable._

**Interactive figure (hub).** A CubDB write as a four-stage flow — write (key = value) → B-tree (copy the path, new nodes) → file (append a block) → header (new current version). Tapping a stage reveals it and points to the matching dive; running a write appends a block to a mini-file and advances the current-version marker. Nothing is overwritten.

## §1 Two words do the work { id="write" }

**Append-only** means a write never modifies an existing byte; it adds to the tail. That alone gives crash-safety — a torn final write is ignored, the last complete header wins — and makes a commit a single atomic act: write the header. **Immutable** means the B-tree is copy-on-write, so an update rewrites the path to the changed leaf as new nodes and leaves every old node, and old root, in place. Together they make old versions free to keep, the whole basis of Module 5. The cost is that the file only grows, so dead data must occasionally be swept — compaction.

## §2 The three dives { id="dives" }

- **Dive 4.1 — The append-only file** — commits append; the last header is the truth; crash mid-commit and the torn tail is discarded. → `/echo-persistence/local-store/cubdb/the-append-only-file`
- **Dive 4.2 — The immutable B-tree** — copy-on-write; update a key and only the root-to-leaf path is rewritten, the old tree left whole. → `/echo-persistence/local-store/cubdb/the-immutable-btree`
- **Dive 4.3 — Compaction** — the file only grows; dead nodes pile up; compact copies the live set to a fresh file and reclaims the rest. → `/echo-persistence/local-store/cubdb/compaction`

## §3 Build & check { id="build" }

**What you build.** A one-paragraph note placing CubDB in the storage ladder: which tier it is, what it stores (the page/LSN log), why an embedded single-file store fits — your own words, no numbers.

**Check.** Why is an append-only commit crash-safe, and why does keeping an old version cost nothing? If both point back to "nothing is overwritten," you have the module.

## §4 References & sources { id="refs" }

External:
- lucaong/cubdb — the embedded append-only B-tree — https://github.com/lucaong/cubdb
- CubDB docs · how it works — file format, headers, compaction — https://hexdocs.pm/cubdb/howto.html
- B-tree — the structure on disk — https://en.wikipedia.org/wiki/B-tree

Echo records:
- store.design.md — CubDB as the durable page tier — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md
- graft.design.md — the page log layered on CubDB — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md

---

_Pager: ← Persistence concepts · Dive 4.1 — The append-only file →_
