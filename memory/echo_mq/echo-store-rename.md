---
name: echo-store-rename
description: "echo_cache → echo_store rename (2026-06-18, code-complete): app :echo_store v2.0.0, modules EchoStore.*; keyspace UNCHANGED (ecc:, no ecs:); EchoCache.Shadow RETIRED; new EchoStore.Graft.* CubDB/Tigris engine; decision doc docs/echo_mq/store/design/store.design.md; docs/echo_mq reconciled link-clean (msh specs → 0) + rename-complete; course docs + some memory notes still say echo_cache pending their own reconciles"
metadata: 
  node_type: memory
  type: project
  originSessionId: 9d74f8c0-fad8-4a2e-99a9-a029129a761a
---

The BCS-stack cache app **`echo_cache` was renamed to `echo_store`** (done in code, 2026-06-18). A **pure mechanical name change, no semantics** — the app grew a CubDB/Tigris replication (Graft) engine, so `EchoCache` no longer named what it is.

- **App / module:** OTP `:echo_store` (v2.0.0); every module `EchoStore.*` (`EchoStore`, `.Table`, `.Journal`, `.Coherence`, `.Keyspace`, `.Ring`, `.Tigris`, + the new `EchoStore.Graft.*` subtree). Path is now `echo/apps/echo_store` (was `echo/apps/echo_cache`).
- **Keyspace UNCHANGED — still `ecc:{table}:{id}`.** The rename did NOT touch it; there is **no `ecs:`** anywhere. Never rewrite `ecc:`→`ecs:`.
- **`EchoCache.Shadow` is RETIRED** (the Litestream shadow dropped) — Shadow mentions are concept-stale, not just name-stale.
- **Decision record (authoritative):** `docs/echo_mq/store/design/store.design.md` — records the `git mv`, the sed, the verification grep. Cite it; it legitimately RETAINS `EchoCache`/`echo_cache` as the documented "before" side of the rename (do not "fix" those).

**Reconcile status.** `docs/echo_mq` is **rename-complete + link-clean** — verified `msh specs echo_mq` → 0 broken links (was 177); the only remaining `EchoCache`/`echo_cache` matches are inside store.design.md (correct). The Operator executed the reconcile out-of-band (`[echo_mq] echo_cache rename to echo_store` + `[echo_mq] specs reconcile`); the `msh specs` checker (see [[msh-mcp-server]]) was the verification harness.

**STILL PENDING — own reconcile rungs (NOT done):** the course docs (`docs/echo/bcs` ≈253, `docs/redis-patterns` ≈368, `docs/echo/mesh`, `docs/echo/art`), the two `CLAUDE.md` manuals, the repo-internal `memory/` corpus, and `echo/apps/codemoji` code (still reads `EchoCache.Table`). The course-teaching memory notes ([[bcs-course]], [[redis-patterns-course]], [[redis-reframe-echomq]], [[mesh-course]]) intentionally keep `echo_cache` until their course docs reconcile — but the real code path is `echo/apps/echo_store`.

Related: [[echo-mq-three-movements]].
