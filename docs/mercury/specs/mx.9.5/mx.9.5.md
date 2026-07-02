# MX.9.5 · The closer — chrome, dual-theme acceptance, the epic gate re-run

> **Status: ✅ BUILT (2026-07-02 · `/mercury-ship mx.9.5` · Squad + Apollo · BUILD-GRADE · Movement III
> closes; re-sharpened + ship ruling folded §7 Arm A; as-built §8).** The
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
> **Ship ruling (2026-07-02, §7 below): Arm A — the clean token skin; F1–F4 declined; no token fork.**

Parent epic: [`../mx.9/mx.9.md`](../mx.9/mx.9.md) · prior rungs: [`../mx.9.3/mx.9.3.md`](../mx.9.3/mx.9.3.md)
· [`../mx.9.4/mx.9.4.md`](../mx.9.4/mx.9.4.md) · canon: [`../../mercury.design.md`](../../mercury.design.md)
· acceptance: [`mx.9.5.stories.md`](./mx.9.5.stories.md) · build context:
[`mx.9.5.llms.md`](./mx.9.5.llms.md).

## 0 · The slice

Three closes in one rung. (1) **The chrome**: the mx.9.2 structural shell is skinned from the design
seeds — the bundle `app.css` + the `apps/website` docs aesthetic (Fork C Arm C composed with Arm B; the
seeds are read-only, untracked, out of every pathspec — read at THIS ship; **skin scope ruled Arm A at
ship — §7**). The skin is **token-expressed** app CSS; a look that demands a NEW `--token` family is a
**fork surfaced at ship**, never decided (the program's token law; ruled: none opened — §7). (2) **The dual-theme acceptance** — epic S-8 in full: the mx.9.2 toggle mechanism
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
- **Where.** `mercury/apps/showcase/src/**` only — the §7 F2 decline removes the sole `index.html`
  font-preload candidate (the token font roles already load through the barrel stylesheet). The seeds
  stay untracked and out of pathspec.

## 3 · Invariants (runnable checks)

- **INV-1 · The chrome is token-expressed app CSS.** Colors, borders, and type resolve through
  `rgb(var(--token))` + the three font roles; **no raw hex** (`grep -rnE "#[0-9a-fA-F]{3,8}\b"
  apps/showcase/src` → empty); no seed file is copied into the tree (the seeds are pattern sources, out
  of pathspec). A needed NEW token family is a **fork for the Operator at ship** — recorded, not decided.
  **Ruled 2026-07-02 (§7): no fork opened — the skin ships within the existing vocabulary; F1–F4 declined.**
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
- **INV-4 · Scope discipline.** The diff is `apps/showcase/src/**` — `showcase.css` (primary) +
  `shell/Home.tsx` (inline-layout absorption) + optionally `shell/Topbar.tsx` (a wordmark/crumb hook);
  the `index.html` contingency resolved OUT (§7 F2). No `packages/**` edit, no root edit, no lockfile
  delta, no new dependency.

## 4 · Key deliverables

| # | Deliverable | Acceptance |
|---|---|---|
| K-1 | The **chrome skin** — the seed aesthetic (bundle `app.css` + `apps/website` docs shell) reimplemented as token-expressed showcase CSS over the mx.9.2 shell | S-1; INV-1 |
| K-2 | The **dual-theme acceptance pass** — the sampled cross-group, both-surface inversion evidence, with the `--indigo-3` limitation noted as expected where sampled | S-2; INV-2 |
| K-3 | The **whole-epic closure re-run** — INV-1..9 + epic S-9/S-10, independently re-run by the Director; the Apollo adversarial probes (doc-source-of-truth · package/app-split) | S-3; INV-3 |
| K-4 | The **closure records** — the rung report carrying the epic's definition-of-done evidence; the Director folds roadmap/progress + any `D-` entries at ship | S-3; INV-3 |

## 5 · The method (build order)

1. **The seed census + the ruling (done 2026-07-02 — §7):** the donor `app.css` read; the four
   `apps/website`-only candidates declined; the skin distilled into the region table in
   [`mx.9.5.llms.md`](./mx.9.5.llms.md). A RESIDUAL new-token need → STOP, surface the fork.
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
- **Touches:** `mercury/apps/showcase/src/**` only (§7 resolves the `index.html` contingency OUT).
  The seeds stay untracked, read-only, out of every pathspec.

## 7 · Ship ruling (2026-07-02) — the skin scope: Arm A, no token fork

**Operator-ruled at this rung's ship (recorded; closes the skin-scope question §0/INV-1 left open):**
the skin scope is **Arm A — the clean token skin**. Every real showcase surface is skinned from the
sanctioned bundle-shell donor (`mercury/packages/mercury-ds/project/showcase/app.css`, read-only,
already 100% `rgb(var(--token))`) + the groundable docs treatments, using ONLY existing tokens;
off-scale literals snap to the scale; the `--indigo-3` dark soft-bg limitation is cited EXPECTED
(INV-2). The four fork candidates from the seed census are **DECLINED** — each sourced only from the
`apps/website` marketing decoration, which the developer showcase has no surface for:

- **F1 · inverse-muted text** — a marketing-hero treatment; no showcase surface renders inverse text.
- **F2 · script/Caveat accent face** — a decorative marketing face; the three token font roles carry
  the showcase voice (this decline also removes the only `index.html` font-preload candidate — §2/§6
  resolve to `src/**` only).
- **F3 · brand-tinted glow shadow** — a marketing hero glow; the elevation scale (`--shadow-100..600`)
  is the showcase's depth vocabulary.
- **F4 · exact cyan/pink syntax hues** — website-local syntax decoration with no token grounding; code
  blocks keep the token families.

**No token fork is opened on this closer — zero new token, zero new dependency.** A residual need
outside this ruled scope remains a STOP-and-surface (INV-1).

## 8 · As-built record (2026-07-02 — the post-build reconcile, Apollo)

**Verdict: BUILD-GRADE.** Every region-table promise MATCHES the as-built tree; zero STALE / INVENTED /
MISSING; the human-eye pixel pass stays the Operator residual by design.

- Shipped surface: `apps/showcase/src/showcase.css` 308 → **388** lines (region A + the Home absorption
  appended; regions B/C/D/F/G/H restyle the mx.9.2–9.4 rules in place) + `shell/Home.tsx` (the static
  layout absorbed into `.showcase-home` / `.showcase-home-swatch`; the dynamic per-swatch background stays
  inline). The optional Topbar hook (EDIT 3) was **not taken** — the `@mercury/ui` `<Button>` toggle is
  unchanged. No other file moved; the `pnpm-lock.yaml` working-tree delta attributes to
  `codemojex/apps/dashboard` (a concurrent track; `link:../../../packages/*` importer depth) — this rung
  has no lockfile involvement.
- **Ratified realization (Director, 2026-07-02):** the crosshatch stage paints hatch-first /
  opaque-base-LAST (`showcase.css:192–197`, rationale in-file) — under the CSS multi-background model the
  first layer paints on top, so the donor's solid-first order would occlude the hatch.
- **Dual-theme (INV-2):** the mechanism is the static `light-theme` default in `index.html` + the
  `main.tsx:6–9` boot-apply of the persisted theme (pre-mount, no flash) + the `App.tsx` toggle — all on
  `documentElement`. The chrome uses **no non-flipping token** — `--indigo-3` / `--bg-active-subtle` /
  `--bg-info-subtle` are absent from `showcase.css`; the skin's raw ramps (`--slate-3/6/7`) carry dark
  overrides (`tokens.css:312–316`), and `--bg-brand-subtle` flips via `--iris-3` (:325). The EXPECTED
  citation lands only on the Home raw-ramp demo swatch and `accent="indigo"` component samples.
- **The whole-epic closure re-ran green (2026-07-02, independent):** packages + showcase typecheck/build
  (`@mercury/*`-scoped), the 3-app gate (`Scope: 3 of 21`, 3× built, rc=0), every negative grep empty
  (hex · extractor-framing · `@storybook/` · `*.md` in src · re-export/dist), the barrel byte-identical
  (root-relative diff), the 65/65 stories↔prompts census mirrored by 65+65 lazy chunks in the bundle,
  `dev:showcase` live on `:5176`. Epic INV-1..9 + S-9/S-10: all pass.

> **Framing (propagate):** no gendered pronouns for agents; no perceptual or interior-state verbs; no
> first-person narration. Each surface is a contract; acceptance is at the boundary.
