# MX.9.5 · build context (the agent brief)

Build context for [`mx.9.5.md`](./mx.9.5.md) (authoritative body) + [`mx.9.5.stories.md`](./mx.9.5.stories.md).
The body wins on any disagreement. **SOLID-FORWARD** — re-sharpened at the rung's own ship: the seed read
and the skin distillation are SHIP-TIME work, deliberately not performed at authoring (2026-07-02).

> **Framing (propagate — do not drop):** no gendered pronouns for agents; no perceptual or interior-state
> verbs; no first-person narration. State each surface as a contract.

## References — read at THIS rung's ship (the re-sharpen list)

1. **This brief + the body** — the contracts, the known-limitation citation, the closure checklist.
2. **The design seeds (read-only, untracked, out of every pathspec)** —
   `mercury/packages/mercury-ds/project/showcase/app.css` (the bundle shell chrome) +
   `mercury/apps/website/` (the docs-shell aesthetic; `index.html` · `docs.html` · `styles.css`). Pattern
   sources to DISTILL into token-expressed CSS — never copy a file, never import a seed path.
3. **The token vocabulary** — canon §6 + a re-grep of `mercury/packages/mercury-ui/src/styles/` for every
   token family the skin names (a token name is a claim; the live styles tree is the truth).
4. **The epic gate set** — [`../mx.9/mx.9.md`](../mx.9/mx.9.md) §3 (INV-1..9) +
   [`../mx.9/mx.9.stories.md`](../mx.9/mx.9.stories.md) S-9/S-10 (re-run as written).

**Preconditions:** mx.9.3 + mx.9.4 SHIPPED. **Formation: Squad + Apollo (ELEVATED closer)** — Apollo runs
the doc-source-of-truth and package/app-split adversarial probes; the Director re-runs the gate
independently. **Inherited rulings:** B · C · D · E.

## Requirements (each traced: story ⇠ requirement ⇢ invariant)

| # | Requirement | Story | Invariant |
|---|---|---|---|
| R-1 | The chrome skin distilled from the seeds as token-expressed app CSS (no raw hex; no seed copy) | S-1 | INV-1 |
| R-2 | A new-token need STOPS and surfaces a fork (never decided, never hex-inlined) | S-1 | INV-1 |
| R-3 | The dual-theme acceptance across groups + both surfaces; the `--indigo-3` limitation noted as EXPECTED, never failed-on, never RGB-patched | S-2 | INV-2 |
| R-4 | The whole-epic closure re-run: epic INV-1..9 + S-9/S-10, Apollo probes, Director independent re-run | S-3 | INV-3 |
| R-5 | Scope: `apps/showcase/src/**` (+ a surfaced-if-needed `index.html` line); no package/root/lockfile delta | S-3 | INV-4 |

## Execution topology (shape, not bytes — re-sharpened at ship)

- **EDIT** `src/showcase.css` (the mx.9.2 structural sheet grows into the skin) + the shell components'
  class hooks as the skin needs; possibly `index.html` (one line, surfaced if needed).
- **The known limitation (cite verbatim at acceptance):** `accent="indigo"` soft-bg (`--indigo-3`)
  carries light values into dark — inherited from the bundle, no groundable dark source, logged upstream,
  **out of mx.9 scope unless the Operator makes dark first-class**. Acceptance notes it; a "fix" here is
  forbidden (a token change is an Operator fork on the token system).
- **The closure checklist (run in this order):** the full ladder below → the epic invariant re-runs
  (registry liveness probe re-run · doc-source-of-truth sample · package/app-split audit · no-dist render
  check) → epic S-9/S-10 as written → the Apollo adversarial pass → the Director independent re-run →
  the closure record (Movement III closes; roadmap/progress folds are the Director's at ship).

## The gate ladder (run from `mercury/` — NEVER `pnpm -r`)

```bash
pnpm --filter "./packages/*" typecheck && pnpm --filter "./packages/*" build   # unchanged
pnpm --filter @mercury/showcase typecheck && pnpm --filter @mercury/showcase build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build                  # exactly 3 product apps
grep -rnE "#[0-9a-fA-F]{3,8}\b" apps/showcase/src                              # → empty (token law)
grep -rnE "design-sync|DesignSync|@babel/standalone|window\.MercuryUI|_ds_bundle" apps/showcase  # → empty
grep -rnE "from \"@storybook/" apps/showcase/src                               # → empty (re-run)
find apps/showcase/src -name "*.md"                                            # → empty (re-run)
# Whole-epic closure (Director + Apollo): barrel-diff byte-identical · registry liveness probe re-run ·
# doc-source-of-truth sample · package/app-split audit · dual-theme sampled inversion (indigo-3 noted
# EXPECTED) · dev:showcase live on :5176 · epic S-9/S-10 as written.
```

## The prompt (the decisions this spec fixes; the ship re-sharpens the rest)

Skin the mx.9.2 shell from the two ruled seeds (the bundle `app.css` + the `apps/website` docs aesthetic),
distilled into token-expressed showcase CSS — the existing families and font roles only; STOP and surface
a fork if the look demands a new token family; copy no seed file. Then accept the epic: run the dual-theme
pass across the 9 groups and both surfaces, noting the `--indigo-3` indigo-accent soft-bg limitation as
EXPECTED (logged upstream, out of scope — never fail on it, never invent a dark RGB); re-run the whole
epic gate — INV-1..9, S-9/S-10 as written — under the Squad formation (Apollo's doc-source-of-truth and
package/app-split adversarial probes; the Director's independent re-run). Touch only
`apps/showcase/src/**` (+ a surfaced `index.html` line if the skin requires one); no new dependency, no
git. Movement III closes on this rung's green — record the evidence and hand the roadmap/progress folds
to the Director.
