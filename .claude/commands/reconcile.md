---
description: reconcile — bidirectional spec↔code ground-truth differ; catches spec-vs-code drift before/after a build rung
argument-hint: A rung id (e.g. f6.2) or a spec path; append "post" for the as-built→spec direction, "apply" to write corrections
allowed-tools: Read, Grep, Glob, Bash, Edit, Write, TaskCreate, TaskUpdate, TaskList, mcp__aaw__*
model: fable
---

# /reconcile — spec ↔ code ground-truth differ

**Purpose.** Catch the single most expensive, most-recurring, currently-UNGUARDED defect class: a spec
claims a code surface the code does not have (**INVENTED**), or the code drifts from what the spec
promised (**STALE**). Existing gates check manifest × filesystem × presence — NOT the *correspondence*
between prose claims and code reality. This skill is that missing axis. It is the executable form of the
"ground-facts surface + numbered delta list (stale-claim → correction → owner)" that
`docs/elixir/specs/pragmatic/f5.progress.md` §7 prescribes by hand each rung.

**The drift this exists to kill (real incidents):** the F5.8/F5.9 **14-delta** reconcile; the F6.1
**unreachable-422** (the brief claimed `courses_of/1 :: … | {:error, %Portal.Error{}}`, the code `@spec`
was `{:ok, [list]}`-only — caught only by a manual read of `portal.ex:81`); fan-out author-agents
inventing/redefining the Portal API past green gates (`elixir-content-fanout-drift`).

## When to run
- **Pre-build (default) — the lag-1 reconcile.** Before building rung N, diff its spec triad against the
  as-built code it depends on. Blocks INVENTED/STALE claims from reaching the implementor. In `/x` this is
  **Venus's step 1**.
- **Post-build (`post`).** After building rung N, diff the as-built code against the spec's promises.
  Catches the build drifting from the contract (the 14-delta-in-reverse). In `/x` this is an **Apollo** gate.

## Algorithm
1. **Extract claims** from the spec triad (`<rung>.md` + `.llms.md` + `.stories.md`) — deterministic where
   possible:
   - every `` `Module.function/arity` `` in backticks
   - every return / `@spec` shape (e.g. `{:ok, [%X{}]}`)
   - every struct + its field set
   - every supervision-tree child list
   - every path in the "Touched files" manifest
   - every invariant asserting a *code* property ("no module under X names Y")
2. **Probe the code** for each claim (grep / AST / `mix xref` / read the real `@spec`):
   - *existence* — does `Module.function/arity` / the struct field / the tree child / the file exist?
   - *shape* — does the as-built `@spec`/return match the claimed shape? (the fuzzy ~10% — judge it)
   - *invariant* — run the asserted grep; is it empty/true on **code** (reword prose false-positives)?
3. **Classify each delta** and emit the table.

## Delta taxonomy (verdict per claim)
| Verdict | Meaning | Action |
|---|---|---|
| `MATCH` | spec claim == as-built | none |
| `STALE` | spec says X, code says Y | correct the SPEC (pre) or the CODE (post) |
| `INVENTED` | spec references a surface that does not exist | correct the spec; or build it if in scope |
| `MISSING` | code has it, the spec omits it | add to spec, or mark out-of-scope |
| `DEFERRED` | the claim carries a `[RECONCILE]` marker + reason | allowed (lag-1) |

## Gate (build-grade criterion)
A rung is **build-grade** iff every extracted claim is `MATCH` or `DEFERRED`. Any `STALE` / `INVENTED` /
`MISSING` **blocks** until corrected or explicitly `[RECONCILE]`-marked with a reason.

## Output
1. the **delta table** — claim → as-built `file:line` → verdict;
2. a numbered **stale-claim → correction** work order, each with an owner;
3. the **build-grade verdict** — BUILD-GRADE, or BLOCKED (n deltas).

Apply the corrections in place only when invoked with `apply`; otherwise report and let the caller (Venus)
apply — never edit a spec the same turn you judge it without the `apply` flag.

## Deterministic core vs judgment
Existence/invariant checks are pure grep/AST/`mix xref` — cheap, fast, **unrationalizable**. Only return-TYPE
correspondence and the STALE-vs-DEFERRED call need model judgment. Keep the split: never let judgment
override a deterministic `MISSING`/`INVENTED`.

## Composition
- **In `/x`:** Venus runs `/reconcile <rung>` as step 1 of every rung (pre), Apollo runs `/reconcile <rung>
  post` at close. The lag-1 discipline becomes an executable gate, not a remembered practice (`x.md` §11.1).
- **With jonnify-cms:** the deterministic core can ship as `jonnify-cms reconcile <rung>` (Go, reusing the
  manifest/AST plumbing); this skill is then the thin LLM wrapper over the fuzzy deltas — the missing third
  audit axis (manifest × filesystem × **spec-surface**).
