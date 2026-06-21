---
title: "ec.6 — The production cutover"
id: echo-courses-6-cutover
rung: ec.6
size: S
risk: HIGH
status: Draft
stands-on: "ec.1–ec.5"
---

# ec.6 — The production cutover { id="echo-courses-6-cutover" }

> _Point `jonnify.fly.dev`'s course routes at the already-deployed, complete Echo app, verify every published path on production, with a one-step rollback — the last small flip of a site that has been live since ec.4._

## Summary

The Echo app has been live (on its Fly app) since ec.4 and polished in ec.5. ec.6 is the **production cutover**: route `jonnify.fly.dev`'s course paths to the Echo app, verify every published path on production, keep the prior release for a one-step rollback, and run a production smoke. No new build — the Dockerfile/`fly.toml` are ec.4's; this is the flip.

## Rationale

Because the complete site has been live and parity-verified since ec.4, shipping to production is not a launch — it is a controlled routing change with a verified target and a tested way back. The risk is concentrated here (a live domain) and nowhere else, which is exactly why the earlier rungs deployed first.

## 5W + H { id="ec6-5wh" }

| | |
|---|---|
| **Who** | Platform / operator. |
| **What** | The cutover of `jonnify.fly.dev`'s course routes to the Echo app, a production verification, a rollback, a production smoke. |
| **When** | Last; stands on ec.1–ec.5 (the app is already live). |
| **Where** | Fly routing / the `jonnify.fly.dev` app config. |
| **Why** | Replace the published static course routes with the Echo app, invisibly. |
| **How** | Verify the deployed app serves every published path; cut the production routes over; keep the prior release; production smoke; rollback = restore the prior route/release in one step. |

## Scope { id="ec6-scope" }

### In scope

- Pre-cutover: verify the deployed Echo app serves `/courses` + every published path + `/healthz` (the parity battery against the production-bound app).
- Cut `jonnify.fly.dev`'s course routes over to the Echo app.
- Retain the prior release/route so rollback is a single documented step.
- A production smoke against `jonnify.fly.dev` after the flip.
- **Apollo** (mandatory — HIGH, live-domain): resolve every ambiguity with the Operator before the flip; verify the rollback works.

### Out of scope

- The image / `fly.toml` / deploy build (ec.4); SEO / assets (ec.5).
- Re-hosting the deep course content (landings; the deep content stays at its existing routes — the cutover must not shadow them).

## Specification { id="ec6-spec" }

A verification step requests every published path + `/healthz` against the deployed app and asserts 200 + the right course. The cutover points `jonnify.fly.dev`'s course routes at the Echo app; the prior release is retained so a rollback is one redeploy / route-restore. A production smoke requests `jonnify.fly.dev/courses` + the five paths after the flip. Because the detail pages are landings (§7 decision 4), the cutover must **not** shadow the deep course content still served at its existing routes — verify the deep routes still resolve.

## Acceptance criteria { id="ec6-acceptance" }

1. **Given** the deployed Echo app, **when** every published path is requested pre-cutover, **then** each returns 200 + the right course (the parity battery).
2. **Given** the cutover, **when** complete, **then** `jonnify.fly.dev/courses` + the five course paths are served by the Echo app.
3. **Given** a deploy under load, **when** the machine receives `SIGTERM`, **then** in-flight requests drain within `kill_timeout` (no dropped connections).
4. **Given** a regressed release, **when** rollback is invoked, **then** the prior release is restored by a single documented step.
5. **Given** the landing detail pages, **when** the deep course routes are requested after cutover, **then** they still resolve (the cutover did not shadow the deep content).

## Dependencies & risks { id="ec6-risks" }

- **Depends on:** ec.1–ec.5 (the app is live + polished).
- **Risk — HIGH, live-domain cutover:** verify all published paths on the deployed app before the flip (criterion 1); keep the prior release for rollback (criterion 4); Apollo mandatory.
- **Risk — shadowing the deep content:** the landings must not capture the deep course routes (criterion 5).
