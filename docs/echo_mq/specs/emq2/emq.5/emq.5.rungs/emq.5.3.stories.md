# EMQ.5.3 · Stories — the grouped batch (affinity + concurrency + dynamic rate)

The acceptance face of [`emq.5.3.md`](emq.5.3.md) (the body authoritative). Every Deliverable is a user story in
Connextra form with Given/When/Then acceptance, naming the invariant(s) it exercises; the Coverage map closes the
loop. **The three forks RULED to their leans (D-1): FORK 5.3-A → additive `@gbclaim`, FORK 5.3-B → reuse `gactive`,
FORK 5.3-C → ring-rotated `bclaim/3`** — the affinity batch is ring-rotated (the rotation picks the group; no `size`,
no caller-named arity; K = `min(lane depth, glimit headroom)`), so `EMQ.5.3-US-FAIRNESS` (the interleaving witness) is
the live acceptance. The standing `EMQ.5.3-US-GATE` is the per-app Valkey gate.

---

## EMQ.5.3-US-AFFINITY — a homogeneous, lane-scoped batch

> *As a* **worker draining a multi-tenant bus**, *I want* **a batch claim that serves a SINGLE group's lane** (the
> rotation picks it; never a mix of tenants), *so that* **I amortize the per-job round-trip over one tenant's backlog
> while the fair-lanes accounting stays intact** — a grouped batch is a lane's turn served deep, not a cross-tenant
> grab.

**Exercises:** EMQ.5.3-INV-Affinity, EMQ.5.3-INV-ServerClock.

```gherkin
Given a queue with TWO branded lanes (group A flooded deep, group B flooded deep)
  And the affinity claim `@gbclaim` / `Lanes.bclaim/3` (the @gwclaim grouped-multi-pop isomorph, gweight read dropped)
When a grouped batch is claimed (`bclaim/3` — the ring rotation picks the served lane)
Then the served members are the rotated lane's serviceable depth (K = min(lane depth, glimit headroom))
  And EVERY served member's row `group` field equals the ONE served group
  And NO served member belongs to the other lane (the batch is homogeneous)
  And every served member carries the SAME `TIME`-derived `active` score (one shared server-clock lease)
  And each served member is at attempts 1 (the per-member HINCRBY fencing token)
  And a batch with members from two lanes is a LOUD failure
```

---

## EMQ.5.3-US-CEILING — a batch never breaks the concurrency ceiling

> *As an* **operator who set a per-tenant concurrency ceiling (`glimit`)**, *I want* **a grouped batch bounded by the
> lane's remaining headroom** (a lane flooded 8 deep but capped at 3 serves 3, not 8), *so that* **bulk consume can
> never over-serve a tenant past its ceiling** — the throughput win of a batch respects the fairness guarantee of the
> limit.

**Exercises:** EMQ.5.3-INV-Ceiling, EMQ.5.3-INV-Affinity.

```gherkin
Given a lane (branded group g) with `glimit` g = 3, flooded 8 deep, 0 in-flight (gactive g = 0)
When a grouped batch is claimed (`bclaim/3`)
Then EXACTLY 3 members are served (K = min(depth 8, headroom 3) clamped to the glimit headroom)
  And `gactive` g = 3 (= glimit — the ceiling reached, never exceeded)
  And a SECOND grouped batch claim returns `:empty` (the lane is de-ringed at its ceiling)
When one served member is retired via the byte-frozen `complete/5` (gactive g -> 2)
Then a grouped batch claim serves again (1 head of headroom freed — the lane re-ringed)
  And a batch that served past the ceiling at any point is a LOUD failure
```

---

## EMQ.5.3-US-FAIRNESS — bulk consume does not starve a lane (the emq.4.4-L1 carry)

> *As an* **operator running skewed tenant load (one heavy lane, several light lanes)**, *I want* **the grouped-batch
> rotation to interleave light lanes early** (not drain the heavy lane to exhaustion first), *so that* **bulk consume
> keeps the starvation-free guarantee the fair lanes earned** — a heavy lane cannot monopolize the machine just because
> it is claimed in batches.

**Exercises:** EMQ.5.3-INV-Fairness (the emq.4.4-L1 carry), EMQ.5.3-INV-ServerClock.

> FORK 5.3-C RULED ring-rotated: the affinity batch rides the ring rotation, so fairness is the ring's property and
> the bounded-early-window interleaving witness proves it (as built `grouped_batch_fairness`, `conformance.ex:2486`).

```gherkin
Given a HEAVY lane flooded deep AND several LIGHT lanes each with a small backlog (all positive weight)
When a bounded EARLY window of grouped-batch claims (`bclaim/3`) is driven (the starvation_drill shape)
Then every LIGHT lane is served INSIDE the bounded early window (recorded in a MapSet of served groups)
  And every served member carries a `TIME`-derived `active` lease (the server clock)
  And — the liveness floor — every lane drains to zero over the full window
  And a FIFO / serve-heavy-to-exhaustion-first rotation goes RED (zero light-lane serves early — the no-op-defeater)
  And a terminal-drain check ALONE is rejected as a weak no-op-defeater (the interleaving is load-bearing)
```

---

## EMQ.5.3-US-RATE — the dynamic rate rides the shipped floor

> *As an* **operator tuning per-tenant throughput at runtime**, *I want* **the existing `weight/4` and `limit/4`
> setters to compose cleanly with the grouped batch** (a weight shapes the ring share, a limit caps the batch
> headroom), *so that* **I tune fair-share and concurrency live without a new key or a wire change** — the dynamic rate
> is the emq.4 floor, additive.

**Exercises:** EMQ.5.3-INV-Ceiling, EMQ.5.3-INV-DeclaredKeys, EMQ.5.3-INV-Frozen.

```gherkin
Given the shipped `Lanes.weight/4` (the gweight share) and `Lanes.limit/4` (the glimit ceiling)
When a `glimit` is lowered at runtime below a lane's live count
Then the lane parks (the shipped `@glimit` re-ring discipline — unchanged by this rung)
When a `glimit` is raised at runtime
Then the lane returns to rotation and a grouped batch is again bounded by the NEW headroom
  And NO new key family is introduced (the rate rides gweight/glimit — INV-DeclaredKeys)
  And `weight/4` / `limit/4` / `@gweight` / `@glimit` are byte-frozen (INV-Frozen)
```

---

## EMQ.5.3-US-ADDITIVE — the protocol grows by additive minor

> *As the* **conformance harness / a future maintainer**, *I want* **the grouped-batch scenarios registered additively
> with the prior 67 byte-unchanged**, *so that* **the wire contract is provably backward-compatible** — a new
> capability adds scenarios + a probe, never edits a shipped one.

**Exercises:** EMQ.5.3-INV-Frozen, the additive-minor conformance law (S-3/§5).

```gherkin
Given the as-built conformance set at 67 scenarios (the pinning tests both assert 67)
When the three grouped-batch scenarios are registered in `scenarios/0` (grouped_batch_affinity + grouped_batch_ceiling + grouped_batch_fairness)
Then the prior 67 scenarios are BYTE-UNCHANGED (git-verified — name + contract + verdict identical)
  And each new scenario's probe is registered in the SAME change
  And the count re-pins 67 -> 70 in BOTH `conformance_run_test.exs` and `conformance_scenarios_test.exs`
  And `EchoMQ.Conformance.run/2` prints 70 lines and returns `{:ok, 70}`
  And the wire `@wire_version` stays `echomq:2.4.2` (no wire break — an additive minor; the mix.exs label is 2.5.1)
```

---

## EMQ.5.3-US-GATE — the rung passes the per-app Valkey gate (the standing gate story)

> *As the* **Director / Apollo verifying the rung**, *I want* **the full per-app gate ladder green on Valkey 6390**,
> *so that* **"done" is a closure over runnable checks, not prose** — the rung ships only when every gate is green and
> every shipped script is byte-frozen.

**Exercises:** every INV (the integration gate); INV-Determinism; honest-row reporting (S-4).

```gherkin
Given the echo_mq app dir and Valkey on :6390 (`valkey-cli -p 6390 ping` -> PONG)
When the per-app gate ladder runs INSIDE `echo/apps/echo_mq`
Then `asdf current` is re-probed from the app dir (the toolchain not hardcoded)
  And `TMPDIR=/tmp mix compile --warnings-as-errors` is clean
  And `TMPDIR=/tmp mix test --include valkey` is green (the affinity + ceiling + fairness scenarios included)
  And `EchoMQ.Conformance.run/2` returns `{:ok, 70}` (the additive-minor count)
  And the ≥100 determinism loop is green end to end (`for i in $(seq 1 100); do TMPDIR=/tmp mix test --include valkey || break; done`) — the same-ms branded-JOB mint hazard
  And `grep redis.call` on every shipped `@g*`/`@bclaim` script in the lib diff = 0 (byte-freeze)
  And claims are reported against Valkey, current stable line (honest-row)
  And the diff stays inside `echo/apps/echo_mq` (boundary)
```

---

## Coverage — every Deliverable → its story (provable from the text)

| Deliverable (emq.5.3.md) | Story | Invariant(s) |
|---|---|---|
| The affinity claim — `@gbclaim` / `bclaim/3`, homogeneous ring-rotated lane-scoped batch, one TIME lease | EMQ.5.3-US-AFFINITY | INV-Affinity, INV-ServerClock |
| Batch concurrency — `gactive += K`, the `glimit` headroom clamp (reuse `gactive`) | EMQ.5.3-US-CEILING | INV-Ceiling, INV-Affinity |
| The group-selection mechanism (FORK 5.3-C RULED ring-rotated) + the fairness guarantee | EMQ.5.3-US-FAIRNESS | INV-Fairness (the emq.4.4-L1 carry) |
| The dynamic rate — the shipped `weight/4`/`limit/4` floor, additive | EMQ.5.3-US-RATE | INV-Ceiling, INV-DeclaredKeys, INV-Frozen |
| Additive-minor conformance — the prior 67 byte-unchanged → 70 | EMQ.5.3-US-ADDITIVE | INV-Frozen, S-3/§5 |
| The per-app gate ladder + the ≥100 loop + the byte-freeze grep | EMQ.5.3-US-GATE | every INV; INV-Determinism; S-4 |

> **Traceability is correct by definition:** every Deliverable maps to exactly one story; every story names the
> invariant(s) it exercises; the gate story closes the integration. The three forks (5.3-A / 5.3-B / 5.3-C) were ruled
> to their leans (D-1); the body + these stories are synced to the rulings (FORK 5.3-C ruled ring-rotated, so
> `EMQ.5.3-US-FAIRNESS` — the interleaving witness — is the live acceptance).

Family: [`../emq.5.md`](../emq.5.md) · Body: [`emq.5.3.md`](emq.5.3.md) · Brief: [`emq.5.3.llms.md`](emq.5.3.llms.md)
· Runbook: [`emq.5.3.prompt.md`](emq.5.3.prompt.md) · The sibling fairness-witness precedent:
[`../../emq.4/emq.4.rungs/emq.4.4.md`](../../emq.4/emq.4.rungs/emq.4.4.md)
