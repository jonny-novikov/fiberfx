# EMQ.5.4 · the build orchestration runbook — the partitioned finish + dynamic delay (the batches family CLOSER)

> The authoritative run scope for shipping emq.5.4 via `/echo-mq-ship` (Flat-L2, Director-supervised). The body
> ([`emq.5.4.md`](emq.5.4.md)) is the contract; the acceptance is [`emq.5.4.stories.md`](emq.5.4.stories.md); the
> Mars brief is [`emq.5.4.llms.md`](emq.5.4.llms.md). This runbook binds them to the pipeline stages + the gate ladder
> + the risk tier. **FORK 5.4-A is RULED — B · T · N** (the Operator ratified it via AskUserQuestion; ledger
> D-1/D-2/D-3, KB record [`../../../../kb/emq-5-4-decisions.md`](../../../../kb/emq-5-4-decisions.md)): **D-1 = Arm B** a
> new minimal atomic `@delay` script; **D-2 = Arm T** `delay/5` token-fenced on the attempts-token; **D-3 = Arm N** a
> new pure `EchoMQ.BatchFinish`. The reconcile corrected the carve's "reuse `@schedule`" lean — `@schedule` is a
> first-write that cannot re-score an active member, so the ruled mechanism is the new `@delay`. The body/brief/stories
> are synced to the ruling; Mars builds the ruled mechanism (no decision is left open).
>
> **Framing law (propagated).** Third person for any agent; no gendered pronouns for agents; no perceptual or
> interior-state verbs for agents or software — components read, compute, refuse, return; no first-person narration.
> Bind this same clause in any sub-brief.

## The family in one paragraph

emq.5 builds the **batch CONSUME** family across four dependency-ordered sub-rungs ([`../emq.5.md`](../emq.5.md), the
Operator-blessed carve): **emq.5.1** the batch-claim spine (`@bclaim` + `claim_batch/4`) — SHIPPED, the SPINE;
**emq.5.2** `min_size`/`timeout` shaping (`EchoMQ.BatchConsumer` + `BatchShaper.Core`) — SHIPPED, the SHAPING;
**emq.5.3** group affinity + batch concurrency + dynamic rate (`@gbclaim` + `bclaim/3`) — SHIPPED, the COMPOSITION;
**emq.5.4** the partitioned finish + dynamic delay (a batch resolves as a partition + `delay/5` re-score) — **THIS
rung, the CLOSER**. The PRODUCE half already ships (`Jobs.enqueue_many/3`) and is NOT re-built. 5.1 landed FIRST —
5.2/5.3/5.4 each ride `@bclaim` and the shipped transitions; 5.4 reuses 5.2's private `defp settle`, so it lands after
it. Each ships independently; nothing in the family is a wire break.

## The rung in one paragraph

emq.5.4 builds the **partitioned finish** of a claimed batch + a **dynamic-delay** verb. The claim half is done
(emq.5.1/5.2/5.3); emq.5.4 closes the RESOLVE half. (1) The **partition** — the pure `EchoMQ.BatchFinish.partition/N`
(the `BatchShaper.Core` sibling) maps a claimed batch + its per-member verdict map into a partition `%{completed,
retried, dead, delayed}` — exhaustive + disjoint over the claimed members, `dead` read from the `@retry` `{:ok, :dead}`
outcome (the attempts cap, NOT a caller verdict) — D-3 = Arm N. (2) The **dynamic delay** — `Jobs.delay/5` re-scores an
**active** member onto the **schedule** set, **preserving its attempts** (a delay is not a failure — the inverse of
`@claim`: releases a lease, mints nothing), token-fenced on the attempts-token (D-1 = Arm B, D-2 = Arm T); the shipped
promote pump releases it once due. (3) The **cadence** gains the `{:delay, ms}` verdict in the private `defp settle`
(`batch_consumer.ex:257-269`, the third branch, passing `att`) + a `delayed` per-member event. It is **additive over
shipped, byte-frozen transitions** (`@complete`/`@retry`/`@schedule`/`@promote`/`@bclaim`/`@gbclaim` all byte-frozen),
adds **NO new key family** (the delay rides the shipped `active`/`schedule` sets + the gated `job:` row), and **NO wire
edit** (`@wire_version` stays `echomq:2.4.2`, the two-planes model — the rung label climbs to `2.5.2`). Per the ruling
(D-1 = Arm B), it adds **ONE new additive script** (`@delay`, parallel to `@schedule`). All under the v2 master
invariant (braced keyspace · branded `JOB` ids gated · every Lua key declared-or-rooted on a declared base — the
A-1/L-1 law · the server clock on the delay due score · inline `Script.new/2` · additive-minor conformance 70 → 70+N).

## Mode

**Flat-L2, Director-supervised.** Venus (reconcile/author the triad + re-derive to the ruling — DONE; loads
`echo-mq-architect`) → **FORK 5.4-A RULED B · T · N** (the Operator ratified via AskUserQuestion; the body/brief/stories
synced) → Mars-1 (build to the brief — `echo-mq-implementor`) → Director solo review (independent gate re-run on Valkey
6390 + an adversarial probe — the **declared-keys + byte-freeze battery on the new `@delay` script** + the
**attempts-preserved + atomicity + token-fence probes** + the **fence-arg re-ground** (that the `{:delay, ms}` branch
passes `att`, the attempts-token, identically to `Jobs.complete`/`Jobs.retry`) + a **net-zero mutation spot-check**) →
Mars-2 (remediate + harden) → Director ship (one LAW-4 pathspec commit).

**Apollo (`echo-mq-evaluator`) is OPTIONAL** — emq.5.4 is a NORMAL rung (additive over byte-frozen transitions; one
new parallel script; no new process surface, no new lease surface — `@delay` RELEASES a lease, no destructive at-rest
op). On a normal rung Apollo is an optional fast-finisher (closure + stories), not mandatory. *(Arm C — a fold into a
shipped script — was the chosen-against arm that would have re-graded the rung HIGH with Apollo mandatory; it was
rejected on direction + byte-freeze, so NORMAL holds.)*

## The fork is RULED — B · T · N (the Operator ratified via AskUserQuestion; ledger D-1/D-2/D-3)

> **Three forks, one coherent design — RULED.** The Operator ratified FORK 5.4-A and its two sub-forks; the body +
> brief + stories are synced. The full four-part Arms (Rationale / 5W / Steelman / Steward — each chosen-against arm
> kept on record with its best case) are in the body §"The rung's forks"; the KB consolidation is
> [`../../../../kb/emq-5-4-decisions.md`](../../../../kb/emq-5-4-decisions.md). The compact record:
>
> - **D-1 — the dynamic-delay mechanism = Arm B (a new minimal atomic `@delay`).** The carve leaned "reuse `@schedule`
>   / zero new Lua" — but the reconcile against `jobs.ex:55-73` confirmed **`@schedule` CANNOT re-score an active
>   member** (its `EXISTS` guard no-ops a present row; its `attempts 0` reset would wipe the member's history + demand
>   the payload). The ruled mechanism: one new inline `Script.new(:delay, …)` beside `@schedule`, atomic in ONE EVAL —
>   token-fence `EMQSTALE` (attempts-token) → `ZREM active` → `HSET state scheduled` (attempts PRESERVED) → `ZADD
>   schedule now+ms` (server `TIME` relative / caller-ms absolute). The inverse of `@claim`; every shipped script
>   byte-frozen; grades **NORMAL**. *Chosen-against:* Arm A′ (host two-step — NON-ATOMIC, lost-member window + wipes
>   attempts via `@schedule`'s `attempts 0`); Arm C (fold into `@promote` — wrong direction, edits a frozen script).
> - **D-2 — the delay fence = Arm T (token-required `delay/5`).** `delay/5` refuses (`EMQSTALE`) to re-score an
>   in-flight member without the holder's attempts-token — symmetric with `complete/5`/`retry/7`/`extend_lock/5`. The
>   fence arg is the **attempts-token `att`** (resolved at source — the same the cadence threads to `Jobs.complete`
>   `:261` / `Jobs.retry` `:265`), so the `{:delay, ms}` branch passes `att` identically. *Chosen-against:* Arm F
>   (token-free — breaks lease-fence uniformity; an operator "push-out" is a separate control-plane verb later).
> - **D-3 — the partition surface = Arm N (a new pure `EchoMQ.BatchFinish`).** `partition/N` →
>   `%{completed, retried, dead, delayed}` (exhaustive + disjoint; `dead` EMERGES from `@retry` `{:ok, :dead}`),
>   mirroring emq.5.2's pure-core/process split. *Chosen-against:* Arm X (fold into the private `defp settle` — a
>   process method that does IO; the partition stays pure, `defp settle` gains only the `{:delay, ms}` routing branch).
>
> **The cross-fork pattern (the one lesson):** all three are *reuse a shipped surface (the smaller diff) vs add one
> minimal new surface (atomic / fenced / pure)*, and each reuse path breaks an invariant an earlier rung paid to
> establish — atomicity (A′), lease-fence uniformity (F), the pure-core/process split (X). B · T · N keeps all three.

## The gate ladder (per-app, run INSIDE `echo/apps/echo_mq` — NEVER umbrella-wide)

```bash
cd /Users/jonny/dev/jonnify/echo/apps/echo_mq
asdf current                                         # re-probe the toolchain from the app dir (do NOT hardcode)
valkey-cli -p 6390 ping                              # -> PONG (the live engine is Valkey on 6390)
TMPDIR=/tmp mix compile --warnings-as-errors         # the clean-compile gate
TMPDIR=/tmp mix test --include valkey                # the partition + delay + stale :valkey scenarios included
# EchoMQ.Conformance.run/2 -> {:ok, 70+N}  (the additive-minor count, both pinning tests re-pinned)
for s in 0 1 2 7 42 99; do TMPDIR=/tmp mix test --include valkey --seed $s || break; done   # the MULTI-SEED sweep (NOT the ≥100 loop)
grep -c "redis.call" <the lib diff for every shipped transition script>   # = 0 (byte-freeze)
```

- **`TMPDIR=/tmp` for ALL `mix`** — the harness tmp overlay hits ENOSPC, surfacing as spurious mid-suite I/O failures.
- **The determinism posture is a MULTI-SEED sweep, NOT the ≥100 loop.** emq.5.4 introduces no new mint/lease surface —
  `delay/5` RELEASES a lease (re-scores an active member), the partition is pure host logic — so the same-millisecond
  branded-`JOB` mint hazard the ≥100 loop owns does not apply (carve §3). The report includes an **honest posture
  statement** naming why no ≥100 loop is owed.
- **The byte-freeze grep = 0** on every shipped transition script (`@complete`/`@retry`/`@schedule`/`@promote`/
  `@bclaim`/`@gbclaim`) — `@delay` (D-1 = Arm B) is the ONLY added script body.
- **The conformance count** re-pins 70 → 70+N in BOTH `conformance_run_test.exs` (`{:ok, 70+N}`) and
  `conformance_scenarios_test.exs` (the `@run_order` list + the count prose); the prior 70 byte-unchanged (git-verified).
  The conformance moduledoc OPENING prose (lagging at "fifty-five"/"sixty-four") is trued up to the live count when the
  narrative is extended (narration, not a count-law breach).

## The boundary (a change reaching a third app is a diff no one can review)

- **Edit ONLY `echo/apps/echo_mq`:** a NEW `lib/echo_mq/batch_finish.ex` (the pure partition classifier), `jobs.ex`
  (the new `@delay` + `delay/5`), `batch_consumer.ex` (the `{:delay, ms}` branch in the private `defp settle`),
  `conformance.ex` (the new scenarios), the two pinning tests, optionally a focused `:valkey`/pure unit test, `mix.exs`
  (the rung label).
- **NOT** `keyspace.ex` (no new key family — `@delay` rides the shipped `active`/`schedule` sets + the gated `job:` row).
- **NOT** `lanes.ex` (the grouped-batch finish is a carried follow-up, named not built — `@gbclaim` byte-frozen).
- **NOT** `echo_wire` (the verb rides the shipped connector `eval`; `@wire_version` stays `echomq:2.4.2`).
- **NOT** `apps/echomq` (the frozen v1 capability reference — never edited).
- `mix.lock` excluded unless a real dep moved (none expected). Agents run **NO git**; the Director commits once at the
  rung's close by pathspec (`git commit -F <msg> -- <paths>`; never `git add -A`). The Operator pre-stages out-of-band
  — re-verify `git diff --cached --name-only` is purely the rung before any commit.

## Risk tier

**NORMAL** (RULED, D-1 = Arm B: a new additive `@delay` parallel to `@schedule`). emq.5.4 is additive over byte-frozen
transitions — the partition is pure host logic, the delay adds one new parallel script, there is NO new process surface
and NO new lease surface (`@delay` RELEASES a lease, mints nothing), NO destructive at-rest op, NO wire break. The
Director's Stage-2 verify carries the **declared-keys + byte-freeze battery on the new `@delay` script** + the
**attempts-preserved / atomicity / token-fence probes** + the **fence-arg re-ground** (the `{:delay, ms}` branch passes
`att`) + a net-zero mutation spot-check. **Apollo is OPTIONAL** (a normal rung — closure + stories). The determinism
posture is a **MULTI-SEED sweep + an honest posture statement** (no new mint/lease — carve §3). *(Arm C — a fold into a
shipped script — was the chosen-against arm that would have re-graded HIGH with Apollo mandatory; rejected, so NORMAL
holds.)*

## Definition of Done (the rung ships when)

- [x] FORK 5.4-A RULED by the Operator via AskUserQuestion — **B · T · N** (D-1 = Arm B a new minimal `@delay`; D-2 =
      Arm T token-required `delay/5`; D-3 = Arm N a new pure `EchoMQ.BatchFinish`; the reconcile corrected the carve's
      `@schedule` lean); the body/brief/stories synced to the ruling (the delay mechanism, atomicity, the token
      discipline, the partition surface pinned).
- [ ] The **partition** built (D-3 = Arm N): `EchoMQ.BatchFinish.partition/N` → `%{completed, retried, dead, delayed}`,
      exhaustive + disjoint, `dead` from the `@retry` outcome, an absent verdict fail-safe (the `BatchShaper.Core`
      pure-core shape).
- [ ] The **dynamic-delay verb** built (D-1 = Arm B, D-2 = Arm T): `Jobs.delay/5` — active → scheduled, attempts
      PRESERVED, atomic in one step, token-fenced `EMQSTALE` on the attempts-token, server-clock score — via the new
      `@delay` beside the byte-frozen `@schedule`. Every shipped transition script byte-frozen.
- [ ] The **cadence branch** built: the `{:delay, ms}` verdict in the private `defp settle` (passing `att`) + the
      `delayed` per-member event on the byte-frozen `Events.publish/5`.
- [ ] The conformance scenarios registered additively (`batch_partition` + `batch_delay` + `batch_delay_stale`; the
      prior 70 byte-unchanged → 70+N; both pinning tests re-pinned); the `batch_delay` scenario's attempts-PRESERVED
      check is load-bearing; the moduledoc OPENING prose trued up.
- [ ] The per-app gate ladder green on Valkey 6390; the MULTI-SEED sweep green (the posture statement names why no ≥100
      loop is owed); the byte-freeze grep = 0; honest-row reporting; the diff inside `echo/apps/echo_mq`; `mix.exs`
      label `2.5.2`, the wire `@wire_version` unchanged.
- [ ] (OPTIONAL) Apollo closure: the gate ladder + the multi-seed sweep re-run independently, the partition's
      exhaustive/disjoint + the attempts-preserved + the stale-refusal re-verified, the count + byte-freeze re-verified,
      the stories closed.
- [ ] The body synced to the as-built (Stage-5), closing the batches family; the family contract
      ([`../emq.5.md`](../emq.5.md)) remains the carve authority; the carve's emq.5.4 row + FORK 5.4-A updated to record
      the ruled mechanism (the "reuse `@schedule`" lean corrected).

Family: [`../emq.5.md`](../emq.5.md) · Body: [`emq.5.4.md`](emq.5.4.md) · Stories: [`emq.5.4.stories.md`](emq.5.4.stories.md)
· Brief: [`emq.5.4.llms.md`](emq.5.4.llms.md) · Program law: `.claude/skills/echo-mq-program.md` · Design:
[`../../../../emq.design.md`](../../../../emq.design.md) §6.2 · Roadmap: [`../../../../emq.roadmap.md`](../../../../emq.roadmap.md)
· The sibling cadence precedent: [`emq.5.2.md`](emq.5.2.md)
