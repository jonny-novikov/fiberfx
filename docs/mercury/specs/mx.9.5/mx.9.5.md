# MX.9.5 · The closer — chrome, dual-theme acceptance, the epic gate re-run

> **Status: 📐 SOLID-FORWARD (authored 2026-07-02 in the mx.9 split; re-sharpened at its own ship).** The
> fifth and closing sub-rung of the [`../mx.9/mx.9.md`](../mx.9/mx.9.md) SUB-EPIC — **hard-gates on
> [mx.9.3](../mx.9.3/mx.9.3.md) + [mx.9.4](../mx.9.4/mx.9.4.md)** (the two live surfaces it skins and
> accepts). mx.9.5 lands the epic's K-5 (the chrome skinned from the design seeds — Fork C Arm C composed)
> and the **acceptance half** of INV-8 (dual-theme across the rendered library), then **re-runs the whole
> epic's gate** (INV-1..9 + S-9/S-10). **Movement III CLOSES at this ship.**
>
> **Risk: ELEVATED closer · formation Squad + Apollo** — the epic's verifier mandate is honored HERE: an
> independent whole-app gate re-run plus the two adversarial probes (doc-source-of-truth: rendered docs
> trace to the contracts; package/app-split: no reusable component leaked into the app). The Operator may
> override at ship. **Inherited rulings (2026-07-02, epic §7 — closed):** B · C · D · E.

Parent epic: [`../mx.9/mx.9.md`](../mx.9/mx.9.md) · prior rungs: [`../mx.9.3/mx.9.3.md`](../mx.9.3/mx.9.3.md)
· [`../mx.9.4/mx.9.4.md`](../mx.9.4/mx.9.4.md) · canon: [`../../mercury.design.md`](../../mercury.design.md)
· acceptance: [`mx.9.5.stories.md`](./mx.9.5.stories.md) · build context:
[`mx.9.5.llms.md`](./mx.9.5.llms.md).

## 0 · The slice

Three closes in one rung. (1) **The chrome**: the mx.9.2 structural shell is skinned from the design
seeds — the bundle `app.css` + the `apps/website` docs aesthetic (Fork C Arm C composed with Arm B; the
seeds are read-only, untracked, out of every pathspec — read at THIS ship). The skin is **token-expressed**
app CSS; a look that demands a NEW `--token` family is a **fork surfaced at ship**, never decided (the
program's token law). (2) **The dual-theme acceptance** — epic S-8 in full: the mx.9.2 toggle mechanism
proven across the rendered library, both surfaces (stories + docs), with one **known, logged, out-of-scope
limitation cited as EXPECTED** (below). (3) **The epic closure re-run**: every epic invariant INV-1..9 and
the S-9/S-10 gates re-run over the whole app — the SUB-EPIC's definition of done.

## 1 · Goal

The showcase reads as a designed product (typographic hierarchy from the token font roles, spacing from
the ramp, surfaces/borders from the token families — the seed aesthetic reimplemented, never copied), and
the whole epic accepts: the theme toggle inverts rendered components across the library in both the
Stories and Docs surfaces; the 3-app gate, barrel byte-identity, consume-down greps, derived-registry
liveness, doc-source-of-truth and package/app-split probes all re-run green. Movement III closes.

## 2 · Rationale (5W)

- **Why.** The epic split isolated build risk per surface; the closer is where the SUM is accepted — the
  Squad-tier verifier mandate the original mx.9 banner carried lands here, over the whole app, where it
  proves the most.
- **What.** The chrome skin (app CSS + any shell-markup adjustments it needs), the dual-theme acceptance
  pass, the whole-epic gate re-run, and the closure records (the Director folds the roadmap/progress
  rows and any `D-` entries at ship).
- **Who.** *Built by* the implementor to [`mx.9.5.llms.md`](./mx.9.5.llms.md); **verified by Apollo**
  (the adversarial closure) + the Director (independent gate re-run); *accepted by* the Operator at the
  epic boundary.
- **When.** Last; hard-gates on mx.9.3 + mx.9.4. Closes mx.9 and Movement III; unblocks the Fork-A
  follow-on dedicated-surface rungs (a separate Operator sequencing call).
- **Where.** `mercury/apps/showcase/src/**` (+ `index.html` if the skin needs a font-preload line —
  surfaced at ship if so). The seeds stay untracked and out of pathspec.

## 3 · Invariants (runnable checks)

- **INV-1 · The chrome is token-expressed app CSS.** Colors, borders, and type resolve through
  `rgb(var(--token))` + the three font roles; **no raw hex** (`grep -rnE "#[0-9a-fA-F]{3,8}\b"
  apps/showcase/src` → empty); no seed file is copied into the tree (the seeds are pattern sources, out
  of pathspec). A needed NEW token family is a **fork for the Operator at ship** — recorded, not decided.
- **INV-2 · Dual-theme acceptance across the library** (epic S-8 full). The toggle flips
  `light-theme`/`dark-theme` on `documentElement` and a sampled spread of rendered components (across
  groups, in both the Stories and Docs surfaces) **visibly inverts**; `rgb(var(--token))` resolves in
  both states. **Known limitation, cited as EXPECTED:** `accent="indigo"` soft backgrounds (`--indigo-3`)
  carry light values into dark — inherited from the bundle, no groundable dark source, **logged upstream
  and out of mx.9 scope**. The acceptance NOTES it where sampled and **never fails on it; inventing dark
  RGB values to "fix" it is forbidden** (a token change is an Operator fork on the token system, not a
  showcase patch).
- **INV-3 · The whole-epic closure re-run.** Every epic invariant re-runs green over the finished app:
  INV-1 barrel byte-identical · INV-2 source resolution · INV-3 the 3-app gate · INV-4 package/app split
  (the Apollo adversarial probe: no reusable component housed/re-exported in the app) · INV-5
  doc-source-of-truth (the Apollo probe: sampled rendered docs trace byte-derived to their contracts; no
  authored doc prose) · INV-6 the derived registry (the liveness probe re-run) · INV-7 consume-down greps
  · INV-8 (this rung's INV-2) · INV-9 scope. Epic S-9 + S-10 re-run as written.
- **INV-4 · Scope discipline.** The diff is `apps/showcase/src/**` (+ the surfaced-if-needed
  `index.html` line); no `packages/**` edit, no root edit, no lockfile delta, no new dependency.

## 4 · Key deliverables

| # | Deliverable | Acceptance |
|---|---|---|
| K-1 | The **chrome skin** — the seed aesthetic (bundle `app.css` + `apps/website` docs shell) reimplemented as token-expressed showcase CSS over the mx.9.2 shell | S-1; INV-1 |
| K-2 | The **dual-theme acceptance pass** — the sampled cross-group, both-surface inversion evidence, with the `--indigo-3` limitation noted as expected where sampled | S-2; INV-2 |
| K-3 | The **whole-epic closure re-run** — INV-1..9 + epic S-9/S-10, independently re-run by the Director; the Apollo adversarial probes (doc-source-of-truth · package/app-split) | S-3; INV-3 |
| K-4 | The **closure records** — the rung report carrying the epic's definition-of-done evidence; the Director folds roadmap/progress + any `D-` entries at ship | S-3; INV-3 |

## 5 · The method (build order)

1. **Read the seeds** (at THIS ship — read-only): the bundle `app.css` + the `apps/website` docs-shell
   look; distill the skin as token-expressed CSS (any new-token need → STOP, surface the fork).
2. **Skin the shell** (K-1) over the mx.9.2 structure; adjust shell markup only as the skin needs.
3. **Run the dual-theme acceptance** (K-2) — sample across groups and both surfaces; note the indigo-3
   expectation where sampled.
4. **Run the whole-epic closure** (K-3): the full ladder + the epic invariants + the S-9/S-10 re-run;
   Apollo runs the two adversarial probes; the Director re-runs independently.
5. **Record the closure** (K-4) — Movement III closes; the follow-on dedicated-surface rungs (Fork A)
   are a separate Operator sequencing call.

## 6 · Dependencies

- **Hard-gates on:** [mx.9.3](../mx.9.3/mx.9.3.md) + [mx.9.4](../mx.9.4/mx.9.4.md) (both live surfaces
  must exist to be skinned and accepted).
- **Unblocks:** the epic's close (Movement III) and the Fork-A follow-on surfaces (Operator-sequenced).
- **Touches:** `mercury/apps/showcase/src/**` (+ possibly one `index.html` line, surfaced if needed).
  The seeds stay untracked, read-only, out of every pathspec.

> **Framing (propagate):** no gendered pronouns for agents; no perceptual or interior-state verbs; no
> first-person narration. Each surface is a contract; acceptance is at the boundary.
