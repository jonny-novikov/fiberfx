---
title: "The in-heap structure"
id: ep-m2-d1
status: established
route: "/echo-persistence/foundations/champ-accept-tier/the-in-heap-structure"
kind: "module 2 · dive 2.1"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive structural-sharing SVG; no machine numbers."
renders-to: "foundations/champ-accept-tier/the-in-heap-structure.html"
---

# The in-heap structure { id="ep-m2-d1" }

> _Champ keeps the outbox in a persistent map — a hash-array-mapped trie, the BEAM's native immutable kind. Updating it does not mutate; it returns a new version that shares almost everything with the old one. That one property is why a snapshot costs nearly nothing: keep the old root._

**Interactive figure.** A trie node drawn as eight slots, each linking to a subtree (version v0). Click a slot to write it: a new version v1 appears whose clicked slot links to a freshly copied subtree, while its other seven slots link by dashed reference to v0's existing subtrees. Only one branch is new; v0 stays intact. The readout counts copied vs shared.

## §1 One write, one new path { id="share" }

A real trie is deeper, so a write copies the nodes along one root-to-leaf path — on the order of the tree's height, not its size. Everything off that path is the same memory, pointed at by both versions. The old version is never disturbed, so it remains a perfectly good thing to read — or to write to disk.

## §2 Why the accept tier wants this { id="why" }

Two consequences fall straight out. A **snapshot is a reference**: to checkpoint, Champ keeps the current root and hands it to the writer that fsyncs it, while accepts keep producing newer roots — no copy, no stop-the-world. And readers are **lock-free**: a reader holds a root and sees a consistent version no matter how many writes follow. The next dive turns the checkpoint into a dial; this is the property that makes it cheap.

## §3 References & sources { id="refs" }

External:
- Hash array mapped trie — the structure Champ uses — https://en.wikipedia.org/wiki/Hash_array_mapped_trie
- Persistent data structures — structural sharing, path copying — https://en.wikipedia.org/wiki/Persistent_data_structure
- CHAMP — efficient immutable maps — https://blog.acolyer.org/2015/11/27/hamt/

Echo records:
- store.design.md — the in-heap accept structure — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md
- graft.design.md — the snapshot-as-reference checkpoint — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md

---

_Pager: ← Champ, the accept tier · Dive 2.2 — The checkpoint dial →_
