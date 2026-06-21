# EMQ.5.3 · the build orchestration runbook — the grouped batch (affinity + concurrency + dynamic rate)

> The authoritative run scope for shipping emq.5.3 via `/echo-mq-ship` (Flat-L2, Director-supervised). The body
> ([`emq.5.3.md`](emq.5.3.md)) is the contract; the acceptance is [`emq.5.3.stories.md`](emq.5.3.stories.md); the
> Mars brief is [`emq.5.3.llms.md`](emq.5.3.llms.md). This runbook binds them to the pipeline stages + the gate
> ladder + the risk tier. **No decision the body has fixed is left open here — EXCEPT the three forks (5.3-A the
> affinity-claim home, 5.3-B the concurrency counter, 5.3-C the group-selection mechanism), which the Operator rules
> at the pre-build reconcile (the Director routes via AskUserQuestion). FORK 5.3-A is RISK-DECIDING (additive
> `@gbclaim` = NORMAL+; extend `@gwclaim` = HIGH + Apollo MANDATORY); FORK 5.3-C is API-CONTRACT-DECIDING (it sets
> the `bclaim/N` arity + the fairness property).**
>
> **Framing law (propagated).** Third person for any agent; no gendered pronouns for agents; no perceptual or
> interior-state verbs for agents or software — components read, compute, refuse, return; no first-person narration.
> Bind this same clause in any sub-brief.

## The family in one paragraph

emq.5 builds the **batch CONSUME** family across four dependency-ordered sub-rungs ([`../emq.5.md`](../emq.5.md),
the Operator-blessed carve): **emq.5.1** the batch-claim spine (`@bclaim` + `claim_batch/4`) — SHIPPED, the SPINE;
**emq.5.2** `min_size`/`timeout` shaping (`EchoMQ.BatchConsumer`) — SHIPPED, the SHAPING; **emq.5.3** group affinity +
batch concurrency + dynamic rate (`@gbclaim`, a homogeneous lane-scoped batch — **THIS rung**, the COMPOSITION,
**Apollo RECOMMENDED**); **emq.5.4** the partitioned finish (a batch resolves as a partition + dynamic delay). The
PRODUCE half already ships (`Jobs.enqueue_many/3`) and is NOT re-built. 5.1 landed FIRST — 5.2/5.3/5.4 each ride
`@bclaim`/the ring and are mutually independent. Each ships independently; nothing in the family is a wire break.

## The rung in one paragraph

emq.5.3 builds the **grouped (affinity-respecting) batch claim** — `@gbclaim` + `Lanes.bclaim/N` — composing the
SHIPPED flat-batch spine (emq.5.1) with the CLOSED fair-lanes ring (emq.4). The flat batch crosses groups, bypassing
the ring's per-group `gactive` accounting; emq.5.3 makes the batch **homogeneous** — drawn from a SINGLE lane
(`emq:{q}:g:<group>:pending`), counted against that group's `gactive` ceiling, leased on ONE server-clock `TIME`
deadline. The mechanism is the **near-isomorph of the SHIPPED `@gwclaim`** weighted multi-pop (emq.4.4,
`lanes.ex:87-129`): the ONLY semantic delta is K = `min(size, depth, glimit headroom)` — the caller's batch `size`
replaces the lane's `weight`. It is **additive over a proven mechanism** (the lean, FORK 5.3-A → a new `@gbclaim`
parallel to `@gwclaim`, every shipped `@g*`/`@bclaim` byte-frozen), adds **NO new key family** (rides the shipped
`g:`-segment + `gactive`/`glimit` — the lean, FORK 5.3-B → reuse `gactive`), and **NO wire edit** (`@wire_version`
stays `echomq:2.4.2`, the two-planes model). All under the v2 master invariant (braced keyspace · branded `JOB` ids
gated · every Lua key declared-or-rooted on a declared base — the A-1/L-1 law · the server clock on the lease · inline
`Script.new/2` · additive-minor conformance 67 → 67+N).

## Mode

**Flat-L2, Director-supervised.** Venus (reconcile/author the triad — DONE; loads `echo-mq-architect`) → **the
Director rules the three forks via AskUserQuestion** → Mars-1 (build to the brief — `echo-mq-implementor`) → Director
solo review (independent gate re-run on Valkey 6390 + an adversarial probe — the **declared-keys + byte-freeze battery
on the new lane script** + a **net-zero mutation spot-check** + the **emq.4.4-L1 interleaving witness re-run**) →
Mars-2 (remediate + harden) → Director ship (one LAW-4 pathspec commit).

**Apollo (`echo-mq-evaluator`) is RECOMMENDED** — this rung composes with the fairness ring (a grouped claim touches
the `gactive` ceiling + the ring bookkeeping the fairness story depends on), and the body explicitly carries
**emq.4.4-L1** (a fair-share property needs a bounded-early-window interleaving witness, not a terminal drain). Apollo
re-runs the gate ladder + the ≥100 loop independently, re-verifies the conformance count + the byte-freeze, and
**re-verifies the fairness scenario goes RED under a FIFO/serve-heavy-first mutation** (the load-bearing
no-op-defeater). **If FORK 5.3-A rules the HIGH arm** (extend `@gwclaim`), **Apollo is MANDATORY** (a frozen
fairness-script edit) and the rung re-grades HIGH.

## The forks are OPEN — the Operator's pre-build decisions (ruled via AskUserQuestion BEFORE Mars builds)

> **Three forks. FORK 5.3-A is RISK-DECIDING; FORK 5.3-C is API-CONTRACT-DECIDING.** The Director routes each to the
> Operator via `AskUserQuestion`, records the ruling, and only THEN releases Mars. The full four-part Arms (Rationale /
> 5W / Steelman / Steward) are in the body §"The rung's forks"; the compact routing summary:
>
> - **FORK 5.3-A — the affinity-claim mechanism (RISK-DECIDING).** An **additive `@gbclaim`** (Arm 1 — a new inline
>   script beside `@gwclaim`, the `@gwclaim` body re-used with `size` in place of `weight`; `@gwclaim`/`@gclaim`
>   byte-frozen; **NORMAL+**, Apollo RECOMMENDED) **vs** extending `@gwclaim` to a batch-return (Arm 2 — edits a shipped
>   frozen fairness script; **HIGH** + byte-freeze every OTHER `@g*` + **Apollo MANDATORY** + the ≥100 loop required).
>   **Venus lean: Arm 1 (additive `@gbclaim`)** — keeps the fairness path frozen, reversible, the direct `@gwclaim`
>   dividend. **This ruling sets the rung's risk tier.**
>
> - **FORK 5.3-B — the batch-concurrency home.** Reuse **`gactive`** (Arm 1 — a batch counts as its `size` against the
>   group's ceiling; NO new key, the §6 grammar unedited; the `glimit` headroom clamp already governs it) **vs** a new
>   **`gbatch`** in-flight counter (Arm 2 — a new key family + a second ceiling to keep coherent). **Venus lean: Arm 1
>   (reuse `gactive`)** — one ceiling, no new key. Does NOT change the risk tier.
>
> - **FORK 5.3-C — the group-selection mechanism (NEW — surfaced by Venus at the reconcile; API-CONTRACT-DECIDING).**
>   **Ring-rotated** (Arm 1 — `@gbclaim` does the `LMOVE` ring step like `@gwclaim`, serves a batch from whichever lane
>   the rotation lands on; `bclaim/3` + `size`; fairness preserved by construction; carries emq.4.4-L1; the smallest
>   change) **vs** **caller-named** (Arm 2 — `@gbclaim` takes a specific `group`, no `LMOVE`, serves THAT lane;
>   `bclaim/4` with a `group` argument; true "affinity"; fairness becomes the caller's responsibility) **vs** **BOTH**
>   (Arm 3 — ship both verbs). **Venus lean: Arm 1 (ring-rotated)** — the direct `@gwclaim` isomorph, lowest-risk,
>   fairness-preserving. **BUT this is the Operator's call** — if the consumer story is "a worker dedicated to one
>   tenant" (the codemojex / echo_bot pull model), Arm 2 (caller-named) is the right surface. **This ruling sets the
>   `bclaim/N` arity AND selects the fairness vs. isolation acceptance story** (US-FAIRNESS under Arm 1 → the
>   interleaving witness; US-ISOLATION under Arm 2 → a named-lane-only scenario). Does NOT change the risk tier (both
>   keep the `@gbclaim` additive shape).
>
> **After the rulings:** Venus re-derives the body + brief + stories to the rulings (the affinity-claim home, the
> concurrency counter, the group-selection + the host arity + the live fairness/isolation story) before Mars proceeds
> — a surgical sync, not a rewrite. The emq.5.2 precedent: the Operator may flip a lean (5.2-A leaned Arm A, shipped
> Arm B); the body re-derives to what shipped at Stage-5.

## The gate ladder (per-app, run INSIDE `echo/apps/echo_mq` — NEVER umbrella-wide)

```bash
cd /Users/jonny/dev/jonnify/echo/apps/echo_mq
asdf current                                         # re-probe the toolchain from the app dir (do NOT hardcode)
valkey-cli -p 6390 ping                              # -> PONG (the live engine is Valkey on 6390)
TMPDIR=/tmp mix compile --warnings-as-errors         # the clean-compile gate
TMPDIR=/tmp mix test --include valkey                # the affinity + ceiling + fairness :valkey scenarios included
# EchoMQ.Conformance.run/2 -> {:ok, 67+N}  (the additive-minor count, both pinning tests re-pinned)
for i in $(seq 1 100); do TMPDIR=/tmp mix test --include valkey || break; done   # the ≥100 determinism loop (a mint/lease surface)
grep -c "redis.call" <the lib diff for every shipped @g*/@bclaim>   # = 0 (byte-freeze)
```

- **`TMPDIR=/tmp` for ALL `mix`** — the harness tmp overlay hits ENOSPC, surfacing as spurious mid-suite I/O failures.
- **The ≥100 determinism loop is REQUIRED** — a mint/lease surface (the affinity + ceiling scenarios mint many
  `JOB`/`PRT` ids per run and lease a batch; the same-millisecond branded-`JOB` mint hazard flakes only across runs).
  The loop OWNS the machine (no concurrent liveness server, no sibling heavy I/O).
- **The byte-freeze grep = 0** on every shipped `@g*` (`@genqueue`/`@gclaim`/`@gpause`/`@gresume`/`@glimit`/
  `@greassign`/`@gdrain`/`@greap_group`/`@gwclaim`/`@gweight`) AND `@bclaim` — the affinity claim is the NEW `@gbclaim`,
  the only added script body. *(If FORK 5.3-A rules the HIGH arm, `@gwclaim` is the one edited script; every OTHER
  `@g*`/`@bclaim` byte-frozen.)*
- **The conformance count** re-pins 67 → 67+N in BOTH `conformance_run_test.exs` (`{:ok, 67+N}`) and
  `conformance_scenarios_test.exs` (the `@run_order` list + the count prose); the prior 67 byte-unchanged (git-verified).

## The boundary (a change reaching a third app is a diff no one can review)

- **Edit ONLY `echo/apps/echo_mq`:** `lanes.ex` (the new `@gbclaim` + `bclaim/N`), `conformance.ex` (the new
  scenarios), the two pinning tests, optionally a focused `:valkey` unit test, `mix.exs` (the rung label).
- **NOT `keyspace.ex`** (no new key family — `@gbclaim` rides the shipped `g:`-segment + `gactive`/`glimit`).
- **NOT `echo_wire`** (the claim rides the shipped connector `eval`; `@wire_version` stays `echomq:2.4.2`).
- **NOT `apps/echomq`** (the frozen v1 capability reference — never edited).
- `mix.lock` excluded unless a real dep moved (none expected). Agents run **NO git**; the Director commits once at the
  rung's close by pathspec (`git commit -F <msg> -- <paths>`; never `git add -A`). The Operator pre-stages out-of-band
  — re-verify `git diff --cached --name-only` is purely the rung before any commit.

## Risk tier

**NORMAL+** (under the lean, FORK 5.3-A → additive `@gbclaim`). The composition with the fairness ring is the elevated
point → the Director's Stage-2 verify deepens (the declared-keys + byte-freeze battery on the new lane script + the
≥100 loop + the emq.4.4-L1 interleaving-witness re-run), and **Apollo is RECOMMENDED** (carry emq.4.4-L1). **If FORK
5.3-A rules the HIGH arm** (extend `@gwclaim`), the rung re-grades **HIGH** and **Apollo is MANDATORY** (a frozen
fairness-script edit). The determinism posture is the **≥100 determinism loop** (a mint/lease surface — required
either way).

## Definition of Done (the rung ships when)

- [ ] The three forks (5.3-A / 5.3-B / 5.3-C) ruled by the Operator via AskUserQuestion; the body re-derived to the
      rulings (the risk tier, the host arity, the live fairness/isolation story pinned).
- [ ] `@gbclaim` + `bclaim/N` built (the affinity multi-pop; K = `min(size, depth, glimit headroom)`, one TIME lease,
      `gactive += K`, the re-ring guard) — additive, every shipped `@g*`/`@bclaim` byte-frozen.
- [ ] The conformance scenarios registered additively (affinity + ceiling + fairness/isolation; the prior 67
      byte-unchanged → 67+N; both pinning tests re-pinned); the fairness scenario carries emq.4.4-L1.
- [ ] The per-app gate ladder green on Valkey 6390; the ≥100 determinism loop green; the byte-freeze grep = 0;
      honest-row reporting; the diff inside `echo/apps/echo_mq`.
- [ ] Apollo (RECOMMENDED) closure: the gate ladder + the ≥100 loop re-run independently, the fairness scenario's RED
      under a FIFO/serve-heavy-first mutation re-verified, the count + byte-freeze re-verified, the stories closed.
- [ ] The body synced to the as-built (Stage-5); the family contract ([`../emq.5.md`](../emq.5.md)) remains the carve
      authority.

Family: [`../emq.5.md`](../emq.5.md) · Body: [`emq.5.3.md`](emq.5.3.md) · Stories: [`emq.5.3.stories.md`](emq.5.3.stories.md)
· Brief: [`emq.5.3.llms.md`](emq.5.3.llms.md) · Program law: `.claude/skills/echo-mq-program.md` · Design:
[`../../../../emq.design.md`](../../../../emq.design.md) §6.2 · Roadmap: [`../../../../emq.roadmap.md`](../../../../emq.roadmap.md)
· The sibling precedent + emq.4.4-L1: [`../../emq.4/emq.4.rungs/emq.4.4.md`](../../emq.4/emq.4.rungs/emq.4.4.md)
· Approach: [`../../../../../elixir/specs/specs.approach.md`](../../../../../elixir/specs/specs.approach.md)
