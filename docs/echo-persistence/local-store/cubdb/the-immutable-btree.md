---
title: "The immutable B-tree"
id: ep-m4-d2
status: established
route: "/echo-persistence/local-store/cubdb/the-immutable-btree"
kind: "module 4 · dive 4.2"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive copy-on-write B-tree SVG; no machine numbers."
renders-to: "local-store/cubdb/the-immutable-btree.html"
---

# The immutable B-tree { id="ep-m4-d2" }

> _Inside the file is a B-tree, and it is copy-on-write. Changing a key does not edit a node in place; it writes new copies of the nodes along the path from the root to that leaf, and a new root. Everything off the path — and the entire old tree — stays exactly as it was._

**Interactive figure.** A B-tree: root v0 over three leaves holding key ranges. Updating one leaf's range produces a new leaf and a new root v1; v1 links to the new leaf and shares the other two with v0 by dashed reference, while v0 still reaches the original leaf. A "highlight v0" toggle confirms the old version is intact; reset clears it. Both versions remain valid.

## §1 A new path, a shared rest { id="cow" }

Update a key and CubDB writes a new copy of that leaf and a new root; the other leaves are shared by reference. The old root still reaches the original leaf — both versions valid, only the path copied.

## §2 Why this is the whole game { id="why" }

Copy-on-write links Dive 4.1 to the next module. Because an update only ever *adds* nodes — the path copies plus a root — it appends cleanly to the file; and because the old root is undisturbed, the version it names is still a complete, readable tree. A snapshot, then, is nothing but a retained root: no copy, no freeze. The work per write is the tree's height, not its size, so it stays cheap as data grows. Module 5 takes this single fact — old roots stay valid — and builds MVCC and time travel out of it.

## §3 References & sources { id="refs" }

External:
- B-tree — the structure being copied — https://en.wikipedia.org/wiki/B-tree
- Persistent data structures — path copying, structural sharing — https://en.wikipedia.org/wiki/Persistent_data_structure
- CubDB · how it works — copy-on-write B-tree, new roots — https://hexdocs.pm/cubdb/howto.html

Echo records:
- store.design.md — immutable pages, retained roots — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md
- graft.design.md — snapshots from immutability — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md

---

_Pager: ← The append-only file · Dive 4.3 — Compaction →_
