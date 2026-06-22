---
title: "OpenDAL & the portable remote"
id: ep-m8-d2
status: established
route: "/echo-persistence/engines/rust/opendal-and-the-portable-remote"
kind: "module 8 · dive 8.2"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive operator/backends routing SVG; no machine numbers."
renders-to: "engines/rust/opendal-and-the-portable-remote.html"
---

# OpenDAL & the portable remote { id="ep-m8-d2" }

> _The Rust engine never talks to Tigris directly. It writes through an Apache OpenDAL operator — one API over many storage backends — so the remote can be Tigris, S3, local disk, or memory by configuration, not by changing code. And the fence is a single call: `write(…, if_not_exists)`, whose create-if-not-exists semantics hold identically on every backend._

**Interactive figure.** The `echo_graft` engine on the left issues one conditional write through an OpenDAL operator in the center, which routes to one of four backends on the right — Tigris, S3, local filesystem, or memory. Selecting a backend redraws the route arrow. Writing a key creates it (success); writing the same key again to the same backend returns `ConditionNotMatch` — showing the fence semantics are identical across backends, only the driver changes.

## §1 Same call, any backend { id="operator" }

The active backend starts as Tigris. Press write and OpenDAL routes the same `if_not_exists` call to it: created. Press again and the same backend returns `ConditionNotMatch`. Switch to S3, fs, or memory and repeat: identical behaviour, different driver. The engine's call and its result type never change.

## §2 The remote is a detail, the fence is not { id="why" }

Putting OpenDAL between the engine and the object store buys two things. First, portability: the same build runs against Tigris in production, MinIO or the local filesystem in a test, or an in-memory store in a unit test, because the operator presents one interface and the driver is chosen by config — in production that driver is `RemoteConfig::S3Compatible`, which reads `AWS_ENDPOINT_URL` to point at Tigris. Second — and this is the part that matters for correctness — the conditional write is expressed once. The engine asks OpenDAL to write the segment only if the key does not already exist; on a backend that supports it that becomes the store's create-if-not-exists, and the failure surfaces uniformly as `ConditionNotMatch`. That single call is the fence (Module 3), and because it lives at the operator boundary it is the same fence no matter which store is underneath. So the Rust engine gets the exact remote-commit guarantee the native engine gets from Tigris directly — the subject of Module 9, where both engines meet at one shared remote.

## §3 References & sources { id="refs" }

External:
- Apache OpenDAL — one data-access layer, many backends — https://opendal.apache.org/
- OpenDAL Operator — write, conditional ops — https://opendal.apache.org/docs/rust/opendal/struct.Operator.html
- Tigris conditional writes — If-None-Match on the object store — https://www.tigrisdata.com/docs/objects/conditionals/

Echo records:
- graft specs / graft.2.md — eg.2 — the Tigris/OpenDAL remote + the conditional-write fence — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/specs/graft.2.md
- graft.roadmap.md — eg.2 — the OpenDAL remote behind a stable trait — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md
- graft.engine-split.design.md — echo_graft on OpenDAL, RemoteCommit fence — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.engine-split.design.md
- store.design.md — segment upload, conditional write — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/store/design/store.design.md

---

_Pager: ← Fjall & the LSM-tree · Dive 8.3 — The in-memory feed →_
