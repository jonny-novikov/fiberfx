# EWR.4.1 · ship runbook — `echomq:2.5.0` the client floor (the Pool half) { id="ewr-4-1-runbook" }

> The authoritative **scope of this run** for `/echo-mq-ship ewr-4-1` (the Flat-L2 lead-team, Director-supervised,
> to one LAW-4 pathspec commit). The triad is the contract: body [`ewr.4.1.md`](ewr.4.1.md) (authoritative),
> stories [`ewr.4.1.stories.md`](ewr.4.1.stories.md), brief [`ewr.4.1.llms.md`](ewr.4.1.llms.md). Read all three
> before the build. The roadmap section is [`../../ewr4.roadmap.md`](../../ewr4.roadmap.md) Rung 1.

## Scope (one increment, one run)

Route the **producer hot path** through an optional `EchoMQ.Pool` (the shipped `EchoWire.Pipe` `via` idiom),
bump the wire fence to **`echomq:2.5.0`**, grow the conformance gate **55 → 57**. **No Lua, no new key, no new
dependency, no third app.** The branded-id NIF (roadmap Rung 1 bullet 1b) is **DEFERRED** to a future rung.

## Risk classification — **LOW**

- **Additive + backward-compatible.** Every existing enqueue call site is byte-unchanged (default `Connector`).
  The `Pool` and the `via` idiom are both **already shipped** and exercised — no new mechanism.
- **No keyspace / Lua / wire-protocol change** — the v2 master invariant is untouched by construction
  (`grep redis.call` on the diff = 0).
- **No destructive at-rest op, no new process/lease surface, no frozen-line touch** beyond the sanctioned
  `@wire_version` constant bump (the per-rung fence mechanism).

→ **Apollo is OPTIONAL** (a fast-finisher for closure + the stories), **not mandatory** — this rung trips none
of the high-risk triggers (new process/lease surface, destructive at-rest op, frozen-line touch). The
verification floor is Mars's adversarial self-verify + the Director's independent re-run.

## The team (Flat-L2)

- **Venus** (`echo-mq-architect`) — authored this triad; reconcile SPECCED→BUILT post-ship (sync the body to
  the as-built `via` shape + the final count).
- **Mars-1** (`echo-mq-implementor`) — build R1–R7 to the brief; run the per-app gate ladder + the ≥100
  determinism loop **before reporting**.
- **Director** — independent verify (fresh gate re-run on Valkey `6390`, an adversarial probe, a net-zero
  mutation spot-check incl. the order-theorem mutation on `pool_order`); the REMEDIATE loop; the LAW-4 commit.
- **Mars-2** — remediate + harden if the Director's verify surfaces a finding.

## The cutover (exactly three numbers, all `2.4.2 → 2.5.0`)

1. `echo/apps/echo_wire/lib/echo_mq/connector.ex:35` — `@wire_version "echomq:2.4.2"` → `"echomq:2.5.0"`.
2. `echo/apps/echo_wire/mix.exs:7` — `version: "2.4.2"` → `"2.5.0"`.
3. `echo/apps/echo_mq/mix.exs:7` — `version: "2.4.2"` → `"2.5.0"`.

Guard: `version_reflection_test.exs` (the three numbers must agree). `connector_test.exs:49` asserts only the
shape `^echomq:\d+\.\d+\.\d+$` → **no connector-shape edit**.

## The conformance delta (additive-minor, 55 → 57)

Append **after `flow_grandchild_fail`** (the current list end), prior 55 byte-unchanged:

- `pool_enqueue` — "pool-fronted enqueue is idempotent: a duplicate id through the pool answers duplicate and
  changes nothing; the row and pending entry match a single-connector enqueue."
- `pool_order` — "score-0 mint order holds across pool members: ids enqueued round-robin through the pool
  browse newest-first by name alone (REV BYLEX), identical to the single-connector order."

Re-pin in **both** tests: `conformance_run_test.exs:48` `{:ok, 55}` → `{:ok, 57}`;
`conformance_scenarios_test.exs` `@run_order` (55-elem → 57-elem, the two names appended). **The pool scenarios
MUST start a real `EchoMQ.Pool` (size ≥ 2) and pass `via: pool`** — a clause that passed `via: Connector` or
started no pool would false-green (gate-liveness: a no-op must not satisfy the scenario's letter). `pool_order`
must enqueue **≥ 3** ids; the order-theorem net-zero mutation (reverse/shuffle) MUST kill it.

## The gate ladder (run before reporting)

```bash
# from the touched app
cd /Users/jonny/dev/jonnify/echo/apps/echo_mq
asdf current; valkey-cli -p 6390 ping            # PONG
TMPDIR=/tmp mix compile --warnings-as-errors
TMPDIR=/tmp mix test --include valkey            # Conformance.run/2 → {:ok, 57}
# the ≥100 determinism loop (id-mint suite — the same-ms branded-id mint hazard)
for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey || break; done   # OWN the machine

# from the version-constant seam
cd /Users/jonny/dev/jonnify/echo/apps/echo_wire
TMPDIR=/tmp mix compile --warnings-as-errors
TMPDIR=/tmp mix test
```

`TMPDIR=/tmp` on EVERY `mix`. The loop must own the machine (no concurrent liveness server, no sibling I/O).

## Boundary + frozen-floor proof (Mars self-verifies, Director re-verifies)

- `git diff --name-only` ⊆ {`jobs.ex`, `conformance.ex`, `conformance_run_test.exs`,
  `conformance_scenarios_test.exs`, `connector.ex`, the two `mix.exs`, optionally `jobs_test.exs`} — **minus
  `echo/mix.lock`** (excluded; no dep moved).
- `git grep -c redis.call` on the `lib/echo_mq/` diff = **0** (no Lua touched).
- **No `echo_data` edit** (the NIF is deferred); `deps/0` unchanged; the `EchoWire` facade + the frozen
  `Connector`/`RESP`/`Script`/`Pool` bodies untouched beyond `@wire_version`.

## Commit (Director only, at the close — LAW-4 pathspec)

One pathspec commit over the boundary files. Re-verify `git diff --cached --name-only` is **purely** the rung
boundary before committing (the Operator pre-stages out-of-band; exclude any `AM`-status foreign path). Never
`git add -A`; never commit `echo/mix.lock`; do not push unless asked.

## Out of scope (do not do in this run)

- The branded-id NIF (a future rung — crosses into `echo_data`, needs the Fly/CI `.so` decision).
- Consumer-plane pooling (`claim`/`complete`/`retry`/`extend_lock` stay single-connector).
- Any keyspace / Lua / wire-protocol change.

---

Body: [`ewr.4.1.md`](ewr.4.1.md) · Stories: [`ewr.4.1.stories.md`](ewr.4.1.stories.md) · Brief:
[`ewr.4.1.llms.md`](ewr.4.1.llms.md) · Ledger: [`../progress/ewr-4-1.progress.md`](../progress/ewr-4-1.progress.md)
