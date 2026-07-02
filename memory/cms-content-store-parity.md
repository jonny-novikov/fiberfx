---
name: cms-content-store-parity
description: "jonnify-cms gained a SQLite (modernc, CGO-free) content-store page builder + Go byte-parity test proving it recomposes the 204 published /elixir pages byte-identically; overrides spec 90's progress-only SQLite scope"
project: elixir
metadata: 
  node_type: memory
  type: project
  originSessionId: 73b81fc7-ffef-4d6d-ac38-349cafb4dda9
---

`apps/jonnify-cms` now has a **filesystem-mirrored SQLite content store + page builder + byte-parity test** (built 2026-06-02, slug `cms-builder-parity`, Flat-L2 /x). Packages: `internal/tmpl` (envelope constants `DOCTYPE`/`BodySep`/`BOOTSTRAP`/`Suffix` + `Esc` — the Python `html.escape` form, apostrophe **`&#x27;` NOT Go's `&#39;`**); `internal/store` (`modernc.org/sqlite`, `LoadFromTree`+`decompose`, `head`/`page` tables); `internal/builder` (`Assemble` = byte-port of `docs/elixir/toolkit/build_page.py` `_assemble`); parity test `internal/builder/parity_test.go`; the un-stubbed `cms build` (`--load DB | --route R | --verify`).

**Architecture = round-trip, NOT shared-head rebuild.** An empirical probe proved a single shared `_head.html` can never reproduce published pages: each published hub bakes a **per-chapter accent into its own `<head>`**, and the toolkit `_head.html` had **drifted ahead** of the corpus (the de-walling `.lede` change from [[elixir-clamp-spacing-bug]] follow-ups). So the store **decomposes each published page into normalized templates** — head with `{{TITLE}}`/`{{DESC}}` spliced out (byte-span splice, collision-safe), fragment with `{{BUILD_ID}}`/`{{BUILD_TS}}` spliced out, title/desc stored unescaped, stamp pinned — dedups heads by sha256 (**204 pages → 66 distinct heads**), and `Assemble` re-substitutes through the real `Esc`+envelope. The test asserts recompose==published for all **204** pages, 0 skips, count==on-disk. A per-page `Esc(unescape(titleEsc))==titleEsc` guard rejects any escaping mismatch (57 pages carry apostrophes).

**It proves builder FIDELITY, not corruption-detection** (the store is built from the same tree it is compared against). Verified non-vacuous by an independent adversarial agent: 3/3 injected builder bugs (esc form, `BodySep` byte, replace-0) force the test red. `cms build --verify`: the **`--db` form** (frozen snapshot vs live tree) detects on-disk drift; the **`--root` form** is a builder self-check **plus a skip/count gate** (a non-conforming page exits 1, never a false `OK N/N` — this gate was the one remediation found by the evaluator).

**Decision: this overrides spec `90-deferred-auth.md`**, which had scoped SQLite to a *deferred learner-progress* store ("no course content in the store"). The user explicitly chose a **content** store — recomposing the published course pages — not the deferred learner-progress store. Recorded in new `apps/jonnify-cms/docs/specs/07-content-store.md`. Driver `modernc.org/sqlite` (pure-Go, CGO-free, matches the static Alpine build) per spec 90 §4. **Follow-up (NOT built):** from-manifest *generation* of the 2 index pages (`/elixir`, `/elixir/course`) — they currently replay stored rendered bytes; the `RenderContents`/`ChaptersJSON` port is deferred. Build/test always with `GOWORK=off`. Relates to [[jonnify-cms-toolchain]], [[elixir-toolkit-portable-kit]], [[elixir-e2e-baseline-not-throwaway]].
