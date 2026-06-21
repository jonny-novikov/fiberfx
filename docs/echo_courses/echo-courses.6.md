---
title: "ec.6 — The production cutover"
id: echo-courses-6-cutover
rung: ec.6
size: S
risk: HIGH
status: Built (DOCS-ONLY — runbook + smoke shipped & Apollo-verified BUILD-GRADE; production cutover Operator-pending)
stands-on: "ec.1–ec.5"
runbook: "echo-courses.6.cutover-runbook.md"
smoke: "ec.6.smoke.sh"
---

# ec.6 — The production cutover { id="echo-courses-6-cutover" }

> _Cut `jonnify.fly.dev`'s **courses index** (`/`) over to the already-deployed, complete Echo app, verify production, with a one-step rollback — the last small flip of a site that has been live since ec.4._
>
> _[RECONCILE — ec.6 ships **DOCS-ONLY** (D-1). The team authors the reconciled spec + an Operator-facing cutover runbook (`echo-courses.6.cutover-runbook.md`) + a verified smoke battery (`ec.6.smoke.sh`); it touches **no** live app and runs **no** `fly`. The **Operator** executes the cutover. The cutover is **index-only** (`/`), **not** "the course routes" — the five course paths are deep-course roots that must not be shadowed (D-2). See §"As built / topology".]_

## Summary

The Echo app (`echo-courses.fly.dev`) has been live since ec.4 and polished in ec.5. ec.6 is the **production cutover** of `jonnify.fly.dev`'s **courses index** (`/`): verify the deployed Echo app is a correct target, cut **only `/`** over to it, keep the prior release for a one-step rollback, and run a production smoke that proves the deep-course roots survived. No new build — this is the flip. _[RECONCILE — the published index is at `/`, **not** `/courses` (the golden master `html/index.html`, `<title>Courses · jonnify</title>`; `grep href="/courses"` over the master = 0). The earlier wording "route the course paths" is reconciled to "cut the index (`/`) over": on `jonnify.fly.dev` the five course paths **are** the deep-course roots (§2 below), so routing them to the thin Echo landings would shadow the deep courses — D-2.]_

## Rationale

Because the complete index has been live and parity-verified on the Echo app since ec.4, shipping to production is not a launch — it is a controlled, **index-only** routing change with a verified target and a tested way back. The risk is concentrated here (a live domain) and nowhere else, which is exactly why the earlier rungs deployed first. _[RECONCILE — `jonnify.fly.dev` is a **large, Operator-owned multi-section site** (the courses index at `/`, the deep courses at `/elixir` `/bcs` `/echomq` `/redis-patterns` `/fsharp` `/art` `/mesh`, plus `/edu` `/game` `/law` `/physics` `/school` `/map` … `/distr/*` `/sitemap.xml` `/robots.txt` `/llms.txt`); its server source (`main.go`) is **not** in this VCS — only `go/{Dockerfile,fly.toml,go.work}` are tracked. The cutover touches the index file the Operator serves at `/` and nothing else.]_

## 5W + H { id="ec6-5wh" }

| | |
|---|---|
| **Who** | **Operator** executes the cutover; the team authors the runbook + spec + smoke battery (DOCS-ONLY, D-1). |
| **What** | The cutover of `jonnify.fly.dev`'s **courses index** (`/`) to the Echo render, a production verification, a one-step rollback, a production smoke. _[RECONCILE — index-only, not "course routes"; D-2.]_ |
| **When** | Last; stands on ec.1–ec.5 (the Echo app is already live + polished). |
| **Where** | The Operator's `jonnify` Fly app — the file served at `/` (and/or its `/`-path routing). _[RECONCILE — `jonnify`'s server source is out-of-VCS; the team edits only `docs/echo_courses`.]_ |
| **Why** | Replace the published static courses index (`/`) with the Echo render, invisibly, without shadowing the deep courses or any other section. |
| **How** | Verify the deployed Echo app (pre-cutover gate); the Operator cuts **only `/`** over (rebuild the index file — recommended — or proxy `/`); keep the prior release; production smoke; rollback = restore the prior `jonnify` release (per the installed flyctl). The team runs **no** `fly`. |

## Scope { id="ec6-scope" }

### In scope

_[RECONCILE — DOCS-ONLY (D-1): the in-scope deliverables are all under `docs/echo_courses`. The cutover itself is the Operator's; the team produces the documents that drive and verify it.]_

- **Reconcile** this spec (`echo-courses.6.md`) to the real topology (this rung).
- **Author** the Operator-facing cutover runbook `echo-courses.6.cutover-runbook.md` — the pre-cutover gate, the no-shadow topology + recommendation, the one-step rollback (pinned to the installed flyctl), and the production smoke.
- **Author** a runnable smoke battery `ec.6.smoke.sh` (BASE-parameterized; echo-app assertions vs jonnify-cutover assertions; exits non-zero on any failure), **verified locally** against the dev server.
- Pre-cutover gate (in the runbook): verify the deployed Echo app serves `/` + `/courses` + `/healthz` + `/sitemap.xml` + `/robots.txt` + the content-hash `/static/app.<hash>.{css,js}` assets (ec.5). _[RECONCILE — the index is at `/` (and `/courses`); there is no `/courses` on `jonnify`.]_
- **Apollo** (mandatory — HIGH, live-domain): resolve every ambiguity with the Operator; adversarially verify the cutover/rollback **logic** + the no-shadow invariant + the flyctl rollback form.

### Out of scope

- **Editing the live `jonnify` app or running any `fly`** — the Operator executes the cutover; `jonnify`'s server source is out-of-VCS (D-1).
- The image / `fly.toml` / deploy build (ec.4); SEO / assets (ec.5).
- Re-hosting the deep course content — the deep courses stay served by `jonnify`'s own folder trees at `/elixir` `/bcs` … ; the cutover must **not** shadow them (D-2).
- Pointing any deep-course root at a thin Echo landing (the no-shadow invariant); the five thin Echo landings remain reachable at `echo-courses.fly.dev/courses/:slug`, not on `jonnify`'s deep roots.

## Specification { id="ec6-spec" }

A **pre-cutover gate** requests the Echo app's routes (`/`, `/courses`, `/healthz`, `/sitemap.xml`, `/robots.txt`) + the content-hash assets and asserts 200 + the cutover fingerprint (`/static/app.<hash>.css`). The **cutover** replaces **only** `jonnify.fly.dev/`'s courses index with the Echo render (rebuild the index file — recommended — or proxy `/`); the prior `jonnify` release is retained so a rollback is one image-restore. A **production smoke** requests `jonnify.fly.dev/` (now the Echo render — keyed on the fingerprint) **and** the deep-course roots + a couple of other sections after the flip, asserting they still resolve 200. _[RECONCILE — the cutover is **index-only** (`/`), the Operator executes it, and the smoke targets `/` (not `/courses`, which `jonnify` does not serve). Because the five "course paths" **are** the deep-course roots and the detail pages are thin landings (§7 decision 4), the cutover must **not** shadow them — D-2; the smoke proves they survived.]_

The cutover fingerprint is the **`/static/app.<hash>.{css,js}` link** the Echo render carries and the legacy inline-CSS `html/index.html` does not — the only reliable "this is the Echo render" signal (both indexes share `<title>Courses · jonnify</title>`).

## Acceptance criteria { id="ec6-acceptance" }

_[RECONCILE — these are now the acceptance criteria for the **DOCS** (D-1): the runbook + the reconciled spec + the verified battery encode each. The Operator's later execution is gated by the same criteria, run against the live domain.]_

1. **Given** the deployed Echo app, **when** the pre-cutover gate runs (`ec.6.smoke.sh` MODE `echo`), **then** `/`, `/courses`, `/healthz`, `/sitemap.xml`, `/robots.txt` return 200 and `/` carries the cutover fingerprint `/static/app.<hash>.css` + the five course cards (the battery exits 0). _[RECONCILE — "every published path + the right course" is reconciled to the Echo app's real routes; the index is at `/` and `/courses`.]_
2. **Given** the cutover, **when** complete, **then** `jonnify.fly.dev/` is served by the Echo render (it carries `/static/app.<hash>.css` and keeps `<title>Courses · jonnify</title>`). _[RECONCILE — **resolves the old criterion-2-vs-5 contradiction**: the cutover serves the **courses INDEX (`/`)** from the Echo render, **not** the five course paths. On `jonnify.fly.dev` the five paths are the deep-course roots; serving them from the thin Echo landings would shadow the deep courses, contradicting criterion 5. Index-only (D-2) makes 2 and 5 consistent.]_
3. **Given** a deploy under load, **when** the machine receives `SIGTERM`, **then** in-flight requests drain within `kill_timeout` (no dropped connections). _[RECONCILE — `go/fly.toml` already sets `kill_signal = "SIGTERM"`, `kill_timeout = 10`, rolling strategy; the `jonnify` server's drain window (≤ `kill_timeout`) is the Operator's (out-of-VCS). The runbook §5 records the check.]_
4. **Given** a regressed release, **when** rollback is invoked, **then** the prior `jonnify` release is restored by the documented step. _[RECONCILE — pinned to the installed flyctl (`fly v0.4.6`): the two-step image restore `fly releases -a jonnify --image` → `fly deploy -a jonnify --image <prior-ref>`. The one-command `fly releases rollback` form (other flyctl builds) is flagged for Operator/Apollo confirmation, not asserted (runbook §3).]_
5. **Given** the index-only cutover, **when** the deep-course roots (`/elixir` `/redis-patterns` `/echomq` `/bcs` `/fsharp` `/art` `/mesh`, and the agile deep course) and other sections are requested after the flip, **then** they still resolve 200 (the cutover did not shadow them) — `ec.6.smoke.sh` MODE `jonnify` asserts this and exits 0. _[RECONCILE — the deep courses are served by `jonnify`'s own folder trees (the `go/Dockerfile` `COPY` tree: `elixir/`, `html/{redis-patterns,echomq,bcs,fsharp,art,mesh,agile-agent-workflow}/`), untouched by an index-only flip. **Agile-path duality:** the Dockerfile serves the agile deep course under `/agile-agent-workflow/*`, while the courses card/catalog links `/course/agile-agent-workflow` — the `jonnify` server (out-of-VCS) maps between them; the smoke checks `/course/agile-agent-workflow` and flags both for Operator confirmation (runbook §4).]_

## As built / topology { id="ec6-topology" }

ec.6 shipped **DOCS-ONLY** (D-1). The recommended cutover (D-2/D-3, detailed in the runbook) is **narrow and no-shadow**: replace **only** `jonnify.fly.dev/`'s courses index with the Echo render — either by **rebuilding the index file** the `jonnify` Dockerfile serves at `/` (recommended; one file changes; `fly deploy -c go/fly.toml` from the repo root) or by **proxying `/`** to `echo-courses.fly.dev` (an app-level choice inside the out-of-VCS `jonnify` server — Fly has **no** native cross-app per-path router). Every deep-course root (`/elixir` `/bcs` `/echomq` `/redis-patterns` `/fsharp` `/art` `/mesh`) and every other section (`/edu` `/game` … `/distr/*` `/sitemap.xml` `/robots.txt` `/llms.txt`) stays **byte-untouched**; the five thin Echo landings remain reachable only at `echo-courses.fly.dev/courses/:slug`. The team ran **no** `fly` and edited **no** live app.

## Dependencies & risks { id="ec6-risks" }

- **Depends on:** ec.1–ec.5 (the Echo app is live + polished).
- **Risk — HIGH, live-domain cutover:** the runbook's pre-cutover gate verifies the Echo target before the flip (criterion 1); the prior `jonnify` release is the rollback (criterion 4); Apollo mandatory.
- **Risk — shadowing the deep content:** the cutover is **index-only** (`/`); it must never point a deep-course root at a thin Echo landing (criterion 5, D-2). The MODE `jonnify` smoke proves the deep roots survived.
- **Risk — wrong rollback command:** the rollback is pinned to the installed flyctl (`fly v0.4.6`, two-step image restore); the one-command form is flagged for Operator/Apollo confirmation (runbook §3), never assumed.
- **Risk — the index loses its assets:** the Echo render links `/static/app.<hash>.{css,js}` (ec.5); after a rebuild-`/` cutover the `jonnify` app must serve those same hashed paths — **both** (vendor them, or rewrite the two URLs absolute) or `/` renders unstyled (no CSS) or dead (no JS) (runbook §2.A.2; the smoke resolves both assets).
- **Risk — the cross-app canonical/og:url 404 (SEO):** the Echo render is built for the Echo app, where the index's canonical is `/courses` (`internal/handler/courses.go:43` `indexPath = "/courses"`; Echo serves the index at both `/` and `/courses`). Installed at `jonnify`'s `/` — which has **no** `/courses` route — the baked `<link rel="canonical">` and `og:url` (`https://jonnify.fly.dev/courses`) advertise a **404 canonical/og:url**, an *invisible* SEO/social defect (the page renders perfectly; only crawlers/unfurls see it, so the status+fingerprint smoke cannot catch it). The cutover must rewrite both tags from `…/courses` to `…/` before installing the render (runbook §2.A.3, recommended) or serve `/courses` on `jonnify` as an alias; the MODE `jonnify` smoke guards that no `…/courses` leaks.
