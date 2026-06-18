# AAW_DEVELOPMENT — pragmatic delivery for AAW agents

> **The one law: rigor is constant; ceremony scales to the work.**
>
> This is the *delivery discipline* — how to size the process to the task. It does **not** replace the AAW
> mechanics: the laws live in [`.claude/commands/x.md`](../.claude/commands/x.md) (CLAUDE_LAWS 1/1a/2/3/4), the
> pipeline in the `/x-mode` skill, the framework in [`docs/aaw/aaw.framework.md`](aaw/aaw.framework.md), the
> echo_mq binding in [`docs/echo_mq/program/emq.program.md`](echo_mq/program/emq.program.md). Read those for
> *what the pipeline is*; read this for *how much of it to run*.

## Why this exists

The AAW pipeline is powerful and expensive — it can spawn a multi-agent team, author a four-doc spec triad, and
run an adversarial battery for any task. Applied to a *small* task, that ceremony costs far more than the work
(a one-call-site change can cost hours through a full lead-team). The recurring failure mode is
**process-weight mismatch**: heavy ceremony for light work. This doc is the standing correction.

## 1. Rigor vs. ceremony — they move oppositely with task size

- **Rigor** — the gate ladder, byte-freeze, behaviour-preservation, the net-zero mutation check, the boundary
  grep, the invariants. **Constant. Never scales down.** It is what keeps the wire from breaking.
- **Ceremony** — multi-agent teams, the four-doc spec triad, formal Arms-rulings, agent-handoff round-trips.
  **Scales to the work.**

When you feel pressure to go faster, cut *ceremony*, keep *rigor*. The moment those blur, speed becomes a broken
keyspace.

## 2. Right-size the formation — triage by the actual delta, not the rung number

A "rung" is a unit of plan, not a unit of ceremony. Size the team to the *change*.

| The change | Formation | Verify depth |
|---|---|---|
| Trivial / additive, mirroring a shipped pattern (a verb beside an existing one; a one-call-site refactor) | **1 builder, solo** — you build it directly, no team | the gate green + the one relevant mutation |
| Normal — a real new behaviour, bounded surface | the standard loop (brief → build → independent verify) | the gate + an adversarial probe + a net-zero mutation |
| High-risk — a new process/lease, a destructive at-rest op, a frozen-line touch, an auth/deploy surface, or a *genuinely open* design fork | the full battery (+ a 2nd architect, the ≥100 determinism loop, the full mutation battery) | deepened |

The **risk tier sets the verify depth**; the **size of the delta sets the formation**. Most rungs are not
high-risk — reserve the team for work that earns it.

## 3. Code-first for small work — the code is the spec

For a small, additive change: **write the code, gate it green, then a slim record.** Do not author a heavyweight
spec *before* ~20 lines of code — at that size the code IS the spec. Stories and formal specs may follow the code
or be skipped. (A *new process / lease / protocol* surface still earns a spec first — that is design, not
transcription.)

## 4. Specs are slim and high-level — name the surface, link the detail

A spec body **names** what it builds and **links** the detail; it does not re-derive it.

- **Keep:** status, the surface (modules/functions, high-level), the load-bearing invariants, the frozen-floor
  guarantee, the gate result.
- **Drop from the body:** exhaustive verb/option tables, per-line `file:line` checks, the same fact restated
  across five sections. Those live where they belong — the **code** is the authority on the verb list, the
  **ledger** on the audit trail, the **design doc** on the rulings.
- A shipped rung's body is ~50 lines (Status → surface → invariants → gate), not 500. If you are writing what the
  code already says, stop.

## 5. Don't fuse a horizon decision into a delivery rung

A model / protocol / version decision is its own unit of work. If one surfaces mid-rung — a blocker, a reopened
fork — **stop, settle it standalone, then resume.** Letting it ride a delivery rung thrashes the rung's docs,
spec, and tests, and the small rung cannot close until the big decision settles.

## 6. Generated artifacts are write-only

Never hand-edit or hand-prune a generated bundle — it must reproduce **byte-for-byte from one documented
command.** A hand-pruned generator output is a non-idempotent artifact (a finding to surface, not a step to
absorb). Verify a generated artifact by its **source** + a `grep -c` + the running check — never by reading the
bundle.

## 7. The rigor that never scales down (the verification floor)

Regardless of formation size, every rung clears this floor (echo_mq/BCS specifics shown — adapt per stack):

- **The gate ladder** — per-app `compile --warnings-as-errors` + the per-app suite (never umbrella-wide) +
  conformance `{:ok, n}` byte-stable. `TMPDIR=/tmp` on every `mix`.
- **Byte-freeze** — when a rung re-drives a shipped script, its body stays byte-identical to HEAD
  (`grep redis.call` on the lib diff = `0`).
- **Behaviour-preservation** — a refactor proves the suite green *and byte-stable across the swap*.
- **The net-zero mutation check** — perturb the invariant, confirm a test KILLS it, revert by an inverse edit
  (never `git checkout`), confirm `git diff` clean.
- **The boundary grep** — the diff touches only the rung's surface; no foreign app, no `mix.lock` unless a real
  dep moved.

## 8. Commit discipline

- **Pathspec only** — `git commit -- <exact paths>`, **never** `git add -A`, never a bare commit.
- **The Operator pre-stages out-of-band.** Re-verify `git diff --cached --name-only` is *purely the rung*
  immediately before committing; **abort on any foreign path** (a memory file, a sibling app, a concurrent edit).
- **Commit only when asked.** Separate concerns into separate scoped commits. Don't push unless asked.

## 9. Self-check — am I overbloating?

Before you spawn a team or author a spec:

- [ ] Is the ceremony bigger than the work? (A team for a one-file change? A triad for 20 lines?)
- [ ] Am I writing docs the **code** already says?
- [ ] Did a horizon decision sneak into a delivery rung?
- [ ] Am I re-deriving in the spec what the code / ledger / design-doc is the authority on?
- [ ] Can this ship **solo, code-first, with a slim record**?

Yes to any of the first four — or to the last — means right-size *down*.

---

The full mechanics: [`.claude/commands/x.md`](../.claude/commands/x.md) (the laws) · the `/x-mode` skill (the
pipeline) · [`docs/aaw/aaw.framework.md`](aaw/aaw.framework.md) (the framework) ·
[`docs/echo_mq/program/emq.program.md`](echo_mq/program/emq.program.md) (the echo_mq binding).
