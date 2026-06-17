# EMQ.TODO · Deferred actionable 

> **Format (greppable).** `R-N` = a remediation group (sub-items `R.<rung>-<n>`) · `D-N` = a deferred decision.
> Inline tags — **type** `{remediation}`/`{deferred}` · **scope** `{emq.N}` · **status** `{status=open | in-progress | done}`.
> **Resolution marker.** A fully-resolved group carries **`{resolved}`** in place of its type tag (every sub-item done = SHIPPED) — a readability shorthand; **`{resolved}` groups are SKIPPED when listing the deferred/open backlog**. 
> Query the live backlog by grepping the **open** status tag (the `{resolved}` + in-progress groups drop out). A group is **done** only when **every**
> sub-item is **done = SHIPPED** (cite its commit), never when merely written; per-sub-item status lives in the
> group's `**Status:**` block. (The "done = shipped, not written" rule is the echo-mq-implementor §6 guardrail.)

## Remediation 

### R-1 ✅{resolved} The flow failure-policy + bulk add {emq.3.4} {status=done}

```
┌───────────────────────────────────────────────────────────────────────────────────────┬────────────────────────────────────────────────────────────────────────────────────────────┐
│                                      Remediation                                      │                                            Why                                             │
├───────────────────────────────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┤
│ R.3.4-1 keep @enqueue_flow_child byte-frozen (host-HSET parent_policy for cross-queue too) │ His edit grew the HIGH-risk shipped-script-edit surface to two, violating INV1             │
├───────────────────────────────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┤
│ R.3.4-2 fail-entry payload order (error last, like the complete-entry's result)            │ error is arbitrary-byte but was peeled — a NUL would mis-parse                             │
├───────────────────────────────────────────────────────────────────────────────────────┼────────────────────────────────────────────────────────────────────────────────────────────┤
│ R.3.4-3 revert the mix format churn on pre-existing code                                   │ echo_mq isn't under mix format; the reflow broke INV9 byte-identity + buried the real diff │
└───────────────────────────────────────────────────────────────────────────────────────┴────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Status:** all three CLEARED + SHIPPED in `4c401479` (emq.3.4, Apollo BUILD-GRADE) — Director-reviewed (D-1), Mars-2-fixed, Apollo-verified.
- `R.3.4-1` {status=done} — `@enqueue_flow_child` kept byte-frozen; `parent_policy` persisted via a host `HSET`, symmetric same/cross-queue (Mars-2 R1; Apollo confirmed INV1 — `@retry` the only shipped-script edit).
- `R.3.4-2` {status=done} — fail-entry reordered `policy`-before-`error` (error the NUL-safe remainder); `@retry` emit + `split_fail_entry` + the test helpers byte-aligned (Mars-2 R2; Apollo L-2 producer=consumer fidelity verified).
- `R.3.4-3` {status=done} — `mix format` churn reverted to HEAD byte-identity; the ~36-line residual on pre-existing probe bodies closed by a whole-file diff (Mars-2 R3 + the R3-closure; Apollo L-3 finding → the §6 guardrail fold).

---

# Deferred Decisions

### D-1 ✅{resolved} {emq.3.4} Deferred near-term actionables (Operator decisions, 2026-06-15) {status=done}

The emq.3.4 rung SHIPPED (`4c401479`). The guardrail fold (Operator decision 1) is APPLIED to
`.claude/skills/echo-mq-implementor/SKILL.md` §6 (the whole-file-diff-to-closure discipline). Decisions 2 + 3
are captured here as surgical, near-term actionables (decided in `epics/emq.epic.0.md`; not executed now).

### D-2 ✅{resolved} AAW framework — the Epic / corpus instrument  [APPLIED 2026-06-15 · surgical] {status=done}

> Decision: emq.epic.0 **D0-4** — surgical (a named instrument + one rule), NOT a third layer; defer until the
> pattern proves across ≥2 programs ("practice ships first, codified second"). The canon is shared by all programs.

**Edit A — `docs/aaw/aaw.framework.md`**, append to the *named instruments* paragraph (after "…and the retrospective."):
> "For a cross-cutting body that spans many rungs (a command catalogue, a knowledge base, the program's memory),
> the practice adds the **Epic / corpus** instrument: a thin catalogue index (`<epic>.md`) + per-feature slices
> under a cross-reference grammar — the one-authority and thin-but-robust values applied to the knowledge layer.
> The corpus is git-controlled and Director-owned; program memory lives in the repo, symlinked from the
> agent-memory path for observability. Defined in aaw.rules.md; first proven in the emq program (emq.epic.0)."

**Edit B — `docs/aaw/aaw.rules.md`**: (i) the Director's **Owns** cell (roles table) gains
"; the program corpus (epics · kb)". (ii) add one rule under "The events":
> "**The corpus instrument (Epics).** A cross-cutting body no single rung owns — a command catalogue, a knowledge
> base: a thin index (`<epic>.md`) + per-feature slices under a `#{…}`
> cross-reference grammar, one authority per fact, loaded one slice at a time (never a monolith). Git-controlled,
> Director-owned;

**Actionable:** apply Edits A + B to `docs/aaw/`; one scoped commit; flip emq.epic.0 D0-4 to applied.

**Applied 2026-06-15:** Edits A + B landed — `docs/aaw/aaw.framework.md` (the named instrument) + `aaw.rules.md` (the Director's *Owns* gains "the program corpus (epics · kb)" + the corpus rule under *The events*); **memory pruned from both** (the memory model is D-3, out of scope). The program operating manual + agent calibrations **moved** `docs/echo_mq/specs/program/` → `docs/echo_mq/program/` (corpus, not a spec); all inbound (skills, memory) + outbound links re-based and swept clean. `emq.epic.0` D0-4 flipped to applied.

## D-3 {deferred} Memory framework — repo-controlled memory + symlink  [DEFERRED · whole-project · Operator-gated] {status=open}

> Decision: emq.epic.0 **D0-3** — the Claude Memory Mind Model: the canonical memory is **repo-git-controlled**
> and **Director-owned**; `~/.claude/projects/-Users-jonny-dev-jonnify/memory/` becomes a **symlink** into the
> repo for observability. NOT executed: the dir is **project-wide** (elixir / bcs / … — not
> only emq), so the physical move is a whole-project, Operator-gated step.

**Current state:** `~/.claude/projects/-Users-jonny-dev-jonnify/memory/` is a REAL directory (not yet symlinked),
git-uncontrolled.

**Near-term steps (Operator executes):**
1. Choose the repo home (e.g. `<repo>/.memory/`), git-controlled.
2. Move the memory contents (`MEMORY.md` + the `*.md` files) into the repo home; commit (memory becomes versioned).
3. Replace the `~/.claude/.../memory/` directory with a SYMLINK → the repo home
   (`ln -s <repo>/.memory ~/.claude/projects/-Users-jonny-dev-jonnify/memory`) so the Claude memory tool path keeps working.
4. Verify: recall resolves through the symlink; the repo home is git-tracked; the Director owns updates.

**Risk/why-gated:** project-wide; reversible (re-point the symlink); verify the symlink resolves before relying on it.
**Actionable:** Operator-gated execution; until then memory stays at the `~/.claude` path (model documented here + emq.epic.0 D0-3).