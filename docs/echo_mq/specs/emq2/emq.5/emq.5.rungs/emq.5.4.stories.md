# EMQ.5.4 · Stories — the partitioned finish + dynamic delay (the batches family CLOSER)

The acceptance face of [`emq.5.4.md`](emq.5.4.md) (the body authoritative). Every Deliverable is a user story in
Connextra form with Given/When/Then acceptance, naming the invariant(s) it exercises; the Coverage map closes the
loop. **FORK 5.4-A is RULED — B · T · N** (D-1 = Arm B a new minimal atomic `@delay`; D-2 = Arm T token-required
`delay/5`; D-3 = Arm N a new pure `EchoMQ.BatchFinish`): the delay is an atomic, attempts-preserving, token-fenced
`active → scheduled` re-score, so `EMQ.5.4-US-DELAY` (the re-score) + `EMQ.5.4-US-STALE` (the token fence) are the live
acceptance. The standing `EMQ.5.4-US-GATE` is the per-app Valkey gate. These stories are synced to the ruling.

---

## EMQ.5.4-US-PARTITION — a claimed batch resolves as an exhaustive, disjoint partition

> *As a* **worker resolving a claimed batch**, *I want* **the finish to report a partition `{completed, retried, dead,
> delayed}` over the batch's members** (every member in exactly one bucket), *so that* **"the batch resolved" is a
> closure over checks, not prose** — I can verify every member went somewhere definite, and `dead` is read from the
> retry outcome (the attempts cap), never silently asserted.

**Exercises:** EMQ.5.4-INV-Partition.

```gherkin
Given a claimed batch of M members and a per-member verdict map
  And the verdict vocabulary `:ok | {:error, reason} | {:delay, ms}` (the emq.5.2 map extended with `{:delay, ms}`)
  And the pure classifier `EchoMQ.BatchFinish.partition/N`
When the batch is resolved (each member's verdict routed through the byte-frozen `@complete`/`@retry`/the new `@delay`)
Then the partition `%{completed, retried, dead, delayed}` is returned
  And `completed ++ retried ++ dead ++ delayed` is a PERMUTATION of the M claimed ids (exhaustive — every member, exactly once)
  And the four buckets are pairwise DISJOINT (no member in two)
  And `dead` holds exactly the members whose `@retry` returned `{:ok, :dead}` (the attempts cap — NOT a caller verdict)
  And a member ABSENT from the verdict map lands fail-safe in `retried` (the emq.5.2 "missing verdict", never a silent complete)
  And the classifier is PURE (no process, no clock, no I/O — the BatchShaper.Core discipline)
```

---

## EMQ.5.4-US-DELAY — a handler re-scores a member to run later, attempts preserved

> *As a* **batch handler that learns a member should run later (not fail)**, *I want* **`Jobs.delay/5` to re-score an
> active member onto the schedule set without consuming an attempt**, *so that* **"run this again in `ms`" is distinct
> from a failure** — the member keeps its identity, its attempts, and its payload, and the shipped promote pump
> releases it once due.

**Exercises:** EMQ.5.4-INV-Delay-Rescore, EMQ.5.4-INV-Delay-Atomic, EMQ.5.4-INV-ServerClock.

```gherkin
Given a claimed (active) member at attempts 1, leased on the active set
  And the dynamic-delay verb `Jobs.delay/5` (D-1 = Arm B's new atomic `@delay`)
When the member is delayed by `ms` (the relative mode — server-clock `now + ms`)
Then the member's row reads `state = scheduled`
  And the member's `attempts` is STILL 1 (PRESERVED — NOT reset to 0; the delay is not a failure)
  And the member is in the `schedule` set and ABSENT from the `active` set
  And the member is invisible to `claim` (parked behind the schedule fence)
  And the member is in EXACTLY one of {active, schedule, pending} at every observation (never zero — atomic, no lost-member window)
When `promote/2` runs once the server-clock score is due
Then the member returns to `pending` and a fresh `claim` mints attempts 2 (the history CONTINUED, not restarted)
  And an attempts-reset across the delay is a LOUD failure
```

---

## EMQ.5.4-US-STALE — only the current lease holder may delay a member

> *As the* **bus's lease discipline**, *I want* **`Jobs.delay/5` token-fenced** (a stale-token delay refused
> `EMQSTALE`, changing nothing), *so that* **a worker whose lease was reaped and re-claimed by another worker cannot
> yank a member out from under its new owner** — the same fencing (on the attempts-token) that guards `complete/5`,
> `retry/7`, and `extend_lock/5` guards the delay.

**Exercises:** EMQ.5.4-INV-Delay-Token.

```gherkin
Given a member claimed by worker A (token 1 — the attempts-token)
  And the lease lapses and worker B re-claims it (token 2 — A's token is now stale)
When worker A calls `Jobs.delay/5` with the stale token 1
Then the delay is refused `{:error, :stale}` (the EMQSTALE fencing-token wire class — no new class)
  And the member's `active`-set membership (worker B's token-2 lease) is UNTOUCHED
  And worker B's `Jobs.delay/5` with the live token 2 settles (re-scores the member to schedule)
  And a `delay/5` on a missing row answers `{:error, :gone}`
```

---

## EMQ.5.4-US-CADENCE — the shaping consumer routes a delayed member

> *As an* **operator running the `EchoMQ.BatchConsumer` shaping cadence**, *I want* **the consumer to honor a
> `{:delay, ms}` verdict beside `:ok` and `{:error, reason}`** (routing the member through `delay/5` and emitting a
> `delayed` event), *so that* **the batch handler's "run later" decision flows through the cadence** — the partition is
> observable through the consumer's per-member settle, not just the manual API.

**Exercises:** EMQ.5.4-INV-Delay-Rescore, EMQ.5.4-INV-Partition.

```gherkin
Given the `EchoMQ.BatchConsumer` cadence (emq.5.2) draining a flooded queue
  And a batch handler returning a per-member verdict map with at least one `{:delay, ms}` member
When the consumer settles the batch (the private `defp settle` — the third branch beside `:ok`/`{:error, reason}`)
Then each `:ok` member retires through the byte-frozen `complete/5` (a `completed` event)
  And each `{:error, reason}` member retries through the byte-frozen `retry/7` (a `failed` event)
  And each `{:delay, ms}` member re-scores through `delay/5` (passing the same `att` token its siblings pass; a `delayed` event on the byte-frozen `Events.publish/5`)
  And the settle reports the partition over the batch (completed / retried / dead / delayed)
  And a member absent from the verdict map fail-safe-retries (the emq.5.2 "missing verdict" discipline, unchanged)
```

---

## EMQ.5.4-US-ADDITIVE — the protocol grows by additive minor

> *As the* **conformance harness / a future maintainer**, *I want* **the partition + delay scenarios registered
> additively with the prior 70 byte-unchanged**, *so that* **the wire contract is provably backward-compatible** — a
> new capability adds scenarios + a probe and at most ONE new script, never edits a shipped one.

**Exercises:** EMQ.5.4-INV-Frozen, the additive-minor conformance law (S-3/§5).

```gherkin
Given the as-built conformance set at 70 scenarios (the pinning tests both assert 70)
When the partition + delay scenarios are registered in `scenarios/0` (the partition over a batch + the dynamic-delay re-score + the stale-delay EMQSTALE refusal)
Then the prior 70 scenarios are BYTE-UNCHANGED (git-verified — name + contract + verdict identical)
  And each new scenario's probe is registered in the SAME change
  And the count re-pins 70 -> 70+N in BOTH `conformance_run_test.exs` and `conformance_scenarios_test.exs`
  And `EchoMQ.Conformance.run/2` prints 70+N lines and returns `{:ok, 70+N}`
  And every shipped transition script (`@complete`/`@retry`/`@schedule`/`@promote`/`@bclaim`/`@gbclaim`) is byte-frozen (`grep redis.call` on the lib diff for those = 0)
  And the wire `@wire_version` stays `echomq:2.4.2` (no wire break — an additive minor; the mix.exs label is 2.5.2)
```

---

## EMQ.5.4-US-GATE — the rung passes the per-app Valkey gate (the standing gate story)

> *As the* **Director / Apollo verifying the rung**, *I want* **the full per-app gate ladder green on Valkey 6390**,
> *so that* **"done" is a closure over runnable checks, not prose** — the rung ships only when every gate is green,
> every shipped script is byte-frozen, and the determinism posture is honest.

**Exercises:** every INV (the integration gate); INV-Determinism; honest-row reporting (S-4).

```gherkin
Given the echo_mq app dir and Valkey on :6390 (`valkey-cli -p 6390 ping` -> PONG)
When the per-app gate ladder runs INSIDE `echo/apps/echo_mq`
Then `asdf current` is re-probed from the app dir (the toolchain not hardcoded)
  And `TMPDIR=/tmp mix compile --warnings-as-errors` is clean
  And `TMPDIR=/tmp mix test --include valkey` is green (the partition + delay + stale scenarios included)
  And `EchoMQ.Conformance.run/2` returns `{:ok, 70+N}` (the additive-minor count)
  And the MULTI-SEED determinism sweep is green (`for s in 0 1 2 7 42 99; do TMPDIR=/tmp mix test --include valkey --seed $s || break; done`)
  And NO ≥100 loop is owed (the posture statement names why — no new mint/lease: `delay/5` releases a lease, the partition is pure — carve §3)
  And `grep redis.call` on every shipped transition script (`@complete`/`@retry`/`@schedule`/`@promote`/`@bclaim`/`@gbclaim`) in the lib diff = 0 (byte-freeze)
  And claims are reported against Valkey, current stable line (honest-row)
  And the diff stays inside `echo/apps/echo_mq` (boundary)
```

---

## Coverage — every Deliverable → its story (provable from the text)

| Deliverable (emq.5.4.md) | Story | Invariant(s) |
|---|---|---|
| The partition — `EchoMQ.BatchFinish.partition/N`, exhaustive + disjoint, `dead` from the `@retry` outcome | EMQ.5.4-US-PARTITION | INV-Partition |
| The dynamic-delay verb — `Jobs.delay/5`, active → scheduled, attempts PRESERVED, atomic, server-clock | EMQ.5.4-US-DELAY | INV-Delay-Rescore, INV-Delay-Atomic, INV-ServerClock |
| The token fence — `delay/5` `EMQSTALE` on the attempts-token | EMQ.5.4-US-STALE | INV-Delay-Token |
| The cadence branch — the `{:delay, ms}` verdict in the private `defp settle` + the `delayed` event | EMQ.5.4-US-CADENCE | INV-Delay-Rescore, INV-Partition |
| Additive-minor conformance — the prior 70 byte-unchanged → 70+N; every shipped script byte-frozen | EMQ.5.4-US-ADDITIVE | INV-Frozen, S-3/§5 |
| The per-app gate ladder + the multi-seed sweep + the byte-freeze grep | EMQ.5.4-US-GATE | every INV; INV-Determinism; S-4 |

> **Traceability is correct by definition:** every Deliverable maps to exactly one story; every story names the
> invariant(s) it exercises; the gate story closes the integration. FORK 5.4-A is RULED B · T · N (D-1 = Arm B, D-2 =
> Arm T, D-3 = Arm N); the body + these stories are synced to the ruling (the delay mechanism, atomicity, the token
> discipline, and the partition surface pinned). **A gate must specify its own liveness:** the `batch_delay` scenario
> requires the attempts-PRESERVED proof (a present claimed member exercised), and the `batch_delay_stale` scenario
> requires a stale token to be REFUSED (not a silent pass) — a no-op cannot satisfy either letter.

Family: [`../emq.5.md`](../emq.5.md) · Body: [`emq.5.4.md`](emq.5.4.md) · Brief: [`emq.5.4.llms.md`](emq.5.4.llms.md)
· Runbook: [`emq.5.4.prompt.md`](emq.5.4.prompt.md) · The sibling cadence precedent: [`emq.5.2.md`](emq.5.2.md)
