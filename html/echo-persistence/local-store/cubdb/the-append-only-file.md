---
title: "The append-only file"
id: ep-m4-d1
status: established
route: "/echo-persistence/local-store/cubdb/the-append-only-file"
kind: "module 4 · dive 4.1"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive append + crash-safe-tail SVG; no machine numbers."
renders-to: "local-store/cubdb/the-append-only-file.html"
---

# The append-only file { id="ep-m4-d1" }

> _CubDB writes by appending and never by overwriting. Each commit adds its data and ends with a header; the last complete header is, by definition, the current state. That makes a commit a single atomic act and crash recovery a non-event — a half-written tail is just ignored._

**Interactive figure.** A file as a row of blocks growing rightward. Commit appends a data block and a header, and a current-version marker moves to it. Crash mid-commit appends a data block and a torn header; everything after the last good header is shaded as discarded on the next open. Commit and crash buttons, plus reset.

## §1 The last header wins { id="file" }

Commit appends data + a header and the current version advances; no earlier byte changes. Crash mid-commit and CubDB scans back to the last good header on open — the torn tail simply never existed, and there is no corruption.

## §2 Atomicity for free { id="why" }

A database that overwrites in place must work to stay consistent through a crash — journals, double-writes, fsync dances — because a torn overwrite corrupts existing data. Append-only sidesteps all of it: existing bytes are never at risk, so the only recovery question is "where does the good data end," answered by scanning to the last valid header. The commit becomes visible exactly when its header lands. This is the property the native engine leans on to call a page durable, and why the durable tier could be a single embedded file rather than a server.

## §3 References & sources { id="refs" }

External:
- CubDB · how it works — append-only file, headers, recovery — https://hexdocs.pm/cubdb/howto.html
- lucaong/cubdb — the implementation — https://github.com/lucaong/cubdb
- Write-ahead logging — the contrast: journal vs append-only — https://en.wikipedia.org/wiki/Write-ahead_logging

Echo records:
- store.design.md — why a page is durable on CubDB — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md
- Designing Data-Intensive Applications, Kleppmann 2017 — log-structured storage, crash recovery (Ch. 3) — https://dataintensive.net

---

_Pager: ← CubDB architecture · Dive 4.2 — The immutable B-tree →_
