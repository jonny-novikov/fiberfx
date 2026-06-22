---
title: "The lazy Reader"
id: ep-m7-d2
status: established
route: "/echo-persistence/engines/native-elixir/the-lazy-reader"
kind: "module 7 · dive 7.2"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive tiered read-fault SVG; no machine numbers."
renders-to: "engines/native-elixir/the-lazy-reader.html"
---

# The lazy Reader { id="ep-m7-d2" }

> _Reads never load a whole volume. A page request faults through the tiers in order — the head cache in ETS, then CubDB on disk, then a segment fetched from Tigris — stopping at the first hit, and the fetched page is cached on the way back so the next read is fast._

**Interactive figure.** Three stacked tiers — ETS (L1 head cache), CubDB (durable pages on disk), Tigris (remote segments) — each showing which page ids it holds. A read probe descends from ETS downward, highlighting each tier it checks, and stops at the first tier that has the page; on a hit below ETS, a cache-fill arrow copies the page up into ETS. Reading P2 (hot) is an L1 hit; P3 (on disk) faults to CubDB and gets cached; P6 (remote only) faults all the way to Tigris. "Flush ETS" makes a hot page cold so a hit becomes a fault.

## §1 Descend until hit, cache on return { id="fault" }

Read P3 and watch the probe miss in ETS, hit in CubDB, then fill ETS — read it again and it's an L1 hit. Read P6 and the probe goes all the way to Tigris before the page returns and warms ETS. Flush the cache and even the hot page faults to disk on the next read: durability lives below the volatile cache.

## §2 Why faulting beats loading { id="why" }

A volume can be far larger than memory, so the Reader treats pages like a working set rather than a file to slurp. The first tier is ETS, an in-process table holding recently-touched pages — a hit here is a memory read and never blocks on the writer (it reads a committed version, not the head being mutated). Miss, and it reads the page from CubDB's on-disk B-tree; miss there too — the page has aged out locally — and it pulls the segment from Tigris. Either deep hit fills ETS on the return path, so locality pays off: the second read of the same page is an L1 hit. This is the storage ladder from the landing page made concrete for one read — faults travel down, the answer travels up and warms the cache. The writer and reader share the durable tiers but never block each other, which is the whole point of the split.

## §3 References & sources { id="refs" }

External:
- ETS — in-memory page cache — https://www.erlang.org/doc/man/ets.html
- Cache (computing) — tiered lookup, fill on miss — https://en.wikipedia.org/wiki/Cache_(computing)
- Page cache — working set vs. whole file — https://en.wikipedia.org/wiki/Page_cache

Echo records:
- store.design.md — lazy Reader, L1 ETS → CubDB → segment — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md
- graft.design.md — page faults, cache-fill — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md

---

_Pager: ← The VolumeServer · Dive 7.3 — The commit-log outbox →_
