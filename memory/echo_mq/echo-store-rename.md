---
name: echo-store-rename
description: "echo_cache → echo_store rename (2026-06-18, code-complete): app :echo_store v2.0.0, modules EchoStore.*; keyspace UNCHANGED (ecc:, no ecs:); EchoCache.Shadow RETIRED; new EchoStore.Graft.* CubDB/Tigris engine; decision doc docs/echo_mq/store/design/store.design.md; docs/echo_mq reconciled link-clean (msh specs → 0) + rename-complete; course docs + some memory notes still say echo_cache pending their own reconciles"
project: echo_mq
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

**Reconcile status.** `docs/echo_mq` is **rename-complete + link-clean** — verified `msh specs echo_mq` → 0 broken links (was 177); the only remaining `EchoCache`/`echo_cache` matches are inside store.design.md (correct). The Operator executed the reconcile out-of-band (`[echo_mq] echo_cache rename to echo_store` + `[echo_mq] specs reconcile`); the `msh specs` checker (see [[msh-mcp-server]]) was the verification harness — **re-run it after any reorg**: later emq.4 + epics-flattening work re-broke 25 links (incl. `emq.1.stories.md` accidentally deleted as collateral in an unrelated `[codemoji]` commit — restored from git to `specs/emq.1/`, completing that triad), all re-fixed to 0.

**DONE 2026-06-18:** both `CLAUDE.md` manuals (echo_cache→echo_store, retired Litestream shadow→Graft engine, `ecc:` kept), `echo/apps/codemojex` code (already on `EchoStore`, no refs), and all Claude memory notes. **STILL PENDING — own reconcile rungs:** the course docs (`docs/echo/bcs` ≈253, `docs/redis-patterns` ≈368, `docs/echo/mesh`, `docs/echo/art`) and the Operator-curated repo-internal `memory/` corpus. The course-teaching memory notes ([[bcs-course]], [[redis-patterns-course]], [[redis-reframe-echomq]], [[mesh-course]]) intentionally keep `echo_cache` until their course docs reconcile — the real code path is `echo/apps/echo_store`.

**Course-page reconcile 2026-06-25 (via /bcs-writer keystone run).** The live `EchoCache`→`EchoStore` drift in the *served* courses was far smaller than the case-insensitive ≈-counts above implied — those matched the common noun "exchange.", the lowercase CSS token `echocache`, and `echo/apps/echo_cache` paths. Real + FIXED: **`html/bcs/cache` (17 pages, 95 subs) + `html/echomq/overview` (2 pages) + 5 `docs/echo/bcs` appendix/research md (12 subs)**. PRESERVED by design: `docs/echo/bcs/bcs.course-tooling.guide.md` (its deltas-doc keeps `EchoCache` as the documented "before" column — 3 refs). `redis-patterns` was **already clean** (0 real module refs; was never the ≈368). Core manuscript `bcs.N.md` already on `EchoStore`. Bonus fix: 7 `/bcs/cache` pages had pre-existing dangling `/bcs/bus/{jobs-are-entities,state-machine}` links (the bus chapter restructured B3.2+B3.3 → one `jobs-and-lanes` module) → repointed. **STILL pending EchoCache reconcile:** `/mesh`, `/art` (unchecked this run), the Operator `memory/` corpus. **Tooling gap found:** `/bcs-reconcile` targets `R<N>`/`E<N>` only — the `/bcs` *course* (`B<N>`) has no command path; reconcile it directly or extend the family.

Related: [[echo-mq-three-movements]] · [[bcs-family-tooling]] · [[bcs-course]].
