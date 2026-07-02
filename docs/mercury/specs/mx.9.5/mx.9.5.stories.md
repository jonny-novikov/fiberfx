# MX.9.5 · acceptance stories

Given/When/Then for [`mx.9.5.md`](./mx.9.5.md) (the body wins on any disagreement). **BUILD-GRADE** —
re-sharpened at ship 2026-07-02 (ruling folded — body §7). **Coverage:** K-1 → S-1; K-2 → S-2; K-3, K-4 → S-3. Epic
traceability: S-2 realizes epic **S-8** (in full); S-3 re-runs epic **S-9 + S-10** and closes the epic.

## S-1 · The chrome reads as a designed product — through tokens only (K-1)

*As an **Operator**, I want the showcase skinned from the ruled design seeds, so that the library's public
face carries the system's own aesthetic.*

**Given** the mx.9.2 structural shell and the read-only seeds (the bundle `app.css` + the `apps/website`
docs shell — Fork C Arm C, read at this ship),
**when** the skin lands,
**then** the shell's type, spacing, surfaces, and borders resolve through the token families and the three
font roles (`rgb(var(--token))`; the ramp; `--font-*`), **no raw hex appears**
(`grep -rnE "#[0-9a-fA-F]{3,8}\b" apps/showcase/src` → empty), and no seed file is copied into the tree.
**And** the ship ruling (2026-07-02, body §7) records the census outcome — Arm A, F1–F4 declined, no fork
opened; if a RESIDUAL need beyond that ruled scope appears, the rung STOPS on that piece and surfaces the
fork — the skin ships within the existing vocabulary otherwise.
*(Proves INV-1.)*

## S-2 · The theme flip inverts the rendered library — with the known indigo-3 expectation (K-2 · epic S-8)

*As a **design reviewer**, I want the light/dark toggle proven across the rendered library, so that the
canon's dual-theme promise is accepted at the epic boundary.*

**Given** the finished showcase,
**when** a reviewer toggles the theme over a sampled spread of components (across the 9 groups, in both
the Stories and the Docs surfaces),
**then** each sampled component re-renders under the flipped `documentElement` class and its
surface/foreground **visibly inverts**, with `rgb(var(--token))` resolving in both states.
**And** where a sample hits an `accent="indigo"` soft background, the acceptance **notes the EXPECTED
limitation** — `--indigo-3` carries light values into dark (inherited from the bundle; no groundable dark
source; logged upstream; out of mx.9 scope) — and **does not fail on it**; no dark RGB value is invented
to mask it.
*(Proves INV-2.)*

## S-3 · The epic closes: the whole gate re-runs green under adversarial verify (K-3, K-4 · epic S-9 + S-10)

*As a **Director**, I want the entire epic's invariant set re-run over the finished app with Apollo
adversarial probes, so that Movement III closes on proof, not accumulation.*

**Given** the finished app and the Squad formation (implementor + Apollo + Director),
**when** the closure runs,
**then** epic S-9 passes as written (packages typecheck/build · the 3-app gate builds exactly `echomq` ·
`mobile` · `showcase` · the barrel-diff empty) and epic S-10 passes as written (the consume-down greps
empty; `dev:showcase` live), **and** the epic invariants re-verify: the derived-registry liveness probe
re-run (INV-6), the **doc-source-of-truth probe** (sampled rendered docs trace byte-derived to their
`.prompt.md`; no authored doc prose in the app — INV-5), the **package/app-split probe** (no reusable
component housed or re-exported in `apps/showcase` — INV-4), source resolution with no package `dist/`
(INV-2), and scope (INV-9).
**And** the closure evidence is recorded in the rung report; the Director folds the roadmap/progress rows
at ship. **Movement III closes.**
*(Proves INV-3 + INV-4.)*
