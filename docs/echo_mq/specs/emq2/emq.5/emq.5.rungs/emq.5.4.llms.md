# EMQ.5.4 · Brief (llms) — the grounding map for Mars

The build brief for [`emq.5.4.md`](emq.5.4.md) (the body authoritative; this brief DERIVES from it). emq.5.4 builds
the **partitioned finish** of a claimed batch + a **dynamic-delay** verb, over the byte-frozen per-member transitions.
It closes the batches family. It is **additive over shipped, byte-frozen transitions** (`@complete`/`@retry`/
`@schedule`/`@promote`/`@bclaim`/`@gbclaim` all byte-frozen) — the partition is pure host logic, and the delay adds
exactly **ONE new script** (`@delay`, D-1 = Arm B).

**Framing (propagate to every sub-task):** third person for any agent; no gendered pronouns; no perceptual/
interior-state verbs ("sees"/"wants"/"feels") for agents or software — components read, compute, refuse, return; no
first-person narration ("we"/"I think").

**FORK 5.4-A is RULED — B · T · N** (the Operator ratified all three forks; ledger D-1/D-2/D-3, KB record
[`../../../../kb/emq-5-4-decisions.md`](../../../../kb/emq-5-4-decisions.md)). **D-1 (mechanism) = Arm B** — a new
minimal atomic `@delay` script; **D-2 (fence) = Arm T** — `delay/5` is token-fenced on the attempts-token (`EMQSTALE`);
**D-3 (partition) = Arm N** — a new pure `EchoMQ.BatchFinish`. The reconcile **corrected the carve's lean**: the carve
leaned "reuse `@schedule`," but `@schedule` (`jobs.ex:55-73`) is a FIRST-WRITE that CANNOT re-score an active member
(its `EXISTS` guard no-ops a present row; its `attempts 0` reset would wipe the member's history) — so the ruled
mechanism is the new `@delay` (D-1). **This brief is synced to the ruling** and is Mars's archival build record. The
chosen-against arms (A′ / C / F / X) are the body's road-not-taken (§"The rung's forks").

---

## 1 · References — read these first (the real surface, paths first)

**The reuse targets — the byte-frozen transitions the partition routes through (SHIPPED, BYTE-FROZEN by this rung):**
- `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — **`@schedule`** (`jobs.ex:55-73`): the FIRST-WRITE schedule script. **Read
  it before building the delay** — it opens `if redis.call('EXISTS', KEYS[1]) == 1 then return 0 end` (`jobs.ex:59` —
  the idempotency guard that no-ops a present/active row) and `HSET KEYS[1] 'state' 'scheduled' 'attempts' '0'
  'payload' ARGV[2]` (`jobs.ex:70` — RESETS attempts to 0, DEMANDS the payload). **This is why `@schedule` cannot
  re-score an active member** — the carve's "reuse `@schedule`" lean is corrected. The run-in math (`jobs.ex:63-66`:
  `local t = redis.call('TIME'); local now = t[1]*1000 + math.floor(t[2]/1000); score = now + tonumber(ARGV[4])`) is
  the server-clock pattern `@delay` reuses for its relative mode. `enqueue_at/6` (`jobs.ex:84`) / `enqueue_in/6`
  (`jobs.ex:95`) / the private `schedule/7` (`jobs.ex:106`) — the two due modes (absolute caller-ms, relative
  server-clock) the delay mirrors.
- `jobs.ex` — **`@claim`** (`jobs.ex:165-176`): the INVERSE of the delay. It `ZPOPMIN pending`, `HINCRBY attempts`,
  `HSET state active`, reads `TIME`, `ZADD active now+lease` — a claim moves `pending → active` and MINTS a lease.
  `@delay` is its mirror: `ZREM active`, `HSET state scheduled` (attempts UNTOUCHED), `ZADD schedule now+ms` — moves
  `active → scheduled` and RELEASES the lease. This mental model anchors the new script.
- `jobs.ex` — **`@complete`** (`jobs.ex:257-305`) + **`complete/5`** (`jobs.ex:589-619`): the `:ok` verdict route. The
  token fence `complete/5` uses (`@complete:258-262`: `local att = redis.call('HGET', KEYS[2], 'attempts'); if att ~=
  ARGV[2] then return redis.error_reply('EMQSTALE …')`) is the EMQSTALE pattern `@delay` reuses.
- `jobs.ex` — **`@retry`** (`jobs.ex:334-392`) + **`retry/7`** (`jobs.ex:759-842`): the `{:error, reason}` verdict
  route. **The partition's `dead` bucket is READ FROM the `retry/7` outcome** — `retry/7` returns `{:ok, :scheduled}`
  (a backoff retry) or `{:ok, :dead}` (the attempts cap, `jobs.ex:807-834`, the morgue transition `@retry:364-385`).
  So a `{:error, reason}` member lands in `retried` OR `dead` depending on the return, not on the caller's say-so.
- `jobs.ex` — **`@promote`** (`jobs.ex:394-421`) + **`promote/2`** (`jobs.ex:845-849`): the pump that releases a
  delayed member back to `pending` once due (`ZRANGEBYSCORE schedule -inf now` → `pending`, on the server clock). It
  moves due-scheduled → pending — the WRONG direction for a re-score (the FORK 5.4-A Arm C cost). The delay rides this
  pump unchanged (the delayed member is just another scheduled member to it).
- `jobs.ex` — **`@bclaim`** (`jobs.ex:200-219`) + **`claim_batch/4`** (`jobs.ex:520-539`): the spine the partition
  resolves over (a claimed batch → `{:ok, [{id, payload, att}, …]}`). **`extend_lock/5`** (`jobs.ex:1142-1153`) — the
  other token-fenced verb, the `EMQSTALE` precedent beside `complete/5`.

**The cadence it extends (SHIPPED — the verdict-map router the `{:delay, ms}` branch joins):**
- `echo/apps/echo_mq/lib/echo_mq/batch_consumer.ex` — the PRIVATE **`defp settle(s, members, verdicts)`**
  (`batch_consumer.ex:257-269`): the per-member settle — a PROCESS method that does IO (it calls `Jobs.complete`/
  `Jobs.retry` + publishes), **NOT a public `settle/3`** (the grounding correction, source-confirmed; it is exactly why
  the pure partition is a SEPARATE module, D-3 = Arm N — not folded into this process method). Each member is
  destructured `{id, _payload, att}` (`batch_consumer.ex:258`). Today TWO branches — `:ok` → `Jobs.complete(s.conn,
  s.queue, id, att)` (`:261` — **invoked at `/4`**, the `att` attempts-token in the 4th positional arg, the default
  `result`) + `publish(s, "completed", id)`; `{:error, reason}` → `Jobs.retry(s.conn, s.queue, id, att,
  s.retry_delay_ms, s.max_attempts, to_string(reason))` (`:265` — `att` again the fence) + `publish(s, "failed", id)`.
  **THE FENCE ARG (D-2 grounding note, RESOLVED at source):** both siblings fence by the **attempts-token `att`** (NOT
  a separate lock-token) — `att` is the third element of each claimed member tuple, the same token `@complete`/`@retry`
  check in-script. **So the `{:delay, ms}` branch MUST pass `att` identically** — `Jobs.delay(s.conn, s.queue, id, att,
  ms)` — and the `@delay` in-script fence mirrors `@complete`'s/`@retry`'s attempts-token check. **emq.5.4 ADDS the
  THIRD branch** — `{:delay, ms}` → `Jobs.delay(s.conn, s.queue, id, att, ms)` + `publish(s, "delayed", id)`. The
  absent-member fail-safe (`Map.get(verdicts, id, {:error, "missing verdict"})`, `batch_consumer.ex:259`) is UNCHANGED.
  The verdict-map normalize (`normalize/2`, `batch_consumer.ex:240-249`) admits the new `{:delay, ms}` variant (it is
  already a valid map value; the settle's `case` learns it). *(Mars also re-grounds the fence arg at source —
  `complete/5` `jobs.ex:589`, `retry/7` `jobs.ex:759`, the settle call sites — and threads `@delay`'s fence identically;
  the Director-verify re-grounds this thread.)*
- `echo/apps/echo_mq/lib/echo_mq/batch_shaper/core.ex` — **`EchoMQ.BatchShaper.Core`**: the PURE-CORE precedent the
  partition classifier follows (`decide/4` + `validate!/2`, an injected clock, no I/O, doctests). `EchoMQ.BatchFinish`
  is its sibling — a pure classifier, no process, no clock.
- `echo/apps/echo_mq/lib/echo_mq/events.ex` — **`Events.publish/5`** (`events.ex:117`): the per-member event seam
  (`publish(conn, queue, event, job_id, extra \\ [])`). The `delayed` event rides it beside `completed`/`failed`
  (byte-frozen — the settle calls it; the seam is unchanged).

**The conformance harness (the additive-minor target):**
- `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — **`scenarios/0`** (`conformance.ex:87`): a run-ordered keyword list
  `name: "contract description"`. **`run/2`** (`conformance.ex:179`) dispatches `apply_scenario(name, conn, q)`,
  purges, prints one line, returns `{:ok, length}`. A new scenario = a `name: "…"` entry + a `defp
  apply_scenario(:name, conn, q)` clause. The batch precedents to template: **`:batch_partial_failure`**
  (`conformance.ex:152` — the claim-unit-not-resolution-unit isolation, the partition's ancestor),
  **`:batch_shaping_partial_failure`** (`conformance.ex:155` — the per-member verdict map through the cadence). **The
  moduledoc OPENING prose LAGS** ("fifty-five" `conformance.ex:3`, "sixty-four" `conformance.ex:55`) vs the live 70 —
  true it up to the live count when extending the narrative (narration, NOT a count-law breach; the count-law lives in
  the two pins).
- The pinning tests: `test/conformance_run_test.exs:56` (`assert Conformance.run(conn, q) == {:ok, 70}`) +
  `test/conformance_scenarios_test.exs:33-104` (the `@run_order` list of 70 names + `:107` `assert
  Keyword.keys(scenarios()) == @run_order`). **Re-pin BOTH 70 → 70+N** (append the new names; update the count prose).
- The two version planes: `echo/apps/echo_mq/mix.exs:7` (the rung label `version: "2.5.1"` → `"2.5.2"`, the
  within-family patch) · `echo/apps/echo_wire/lib/echo_mq/connector.ex:35` (`@wire_version "echomq:2.4.2"` — FROZEN; NO
  edit — emq.5.4 adds no wire class).

**The v2 laws (the program floor):** `.claude/skills/echo-mq-program.md` (the v2 laws table, the gate ladder, the
additive-minor law, NO-INVENT) · the design canon [`../../../../emq.design.md`](../../../../emq.design.md) §6.2
(count-variant pops — the family's reserved mechanism), §4 (the server clock), S-6 (declared keys — the A-1/L-1 law),
S-1/§6 (the braced keyspace) · the sibling [`emq.5.2.md`](emq.5.2.md) (the verdict-map cadence the partition + delay
branch extend).

---

## 2 · Requirements (numbered; each traced back to a story, forward to an INV/check)

> **R0 (RULED — Mars proceeds to the ruled mechanism).** FORK 5.4-A was ruled by the Operator via `AskUserQuestion` —
> **B · T · N** (D-1 = Arm B a new minimal atomic `@delay`; D-2 = Arm T token-required `delay/5` on the attempts-token;
> D-3 = Arm N a new pure `EchoMQ.BatchFinish`). The body + this brief are synced to it. Mars builds the ruled mechanism.

| # | Requirement | Story | INV / check |
|---|---|---|---|
| R1 | Build `EchoMQ.BatchFinish` — a NEW pure module (`lib/echo_mq/batch_finish.ex`, the `BatchShaper.Core` sibling; D-3 = Arm N): `partition/N` maps a claimed batch (the M member ids) + a per-member verdict map + the per-member transition OUTCOMES into `%{completed: [...], retried: [...], dead: [...], delayed: [...]}` — exhaustive (every claimed id in exactly one bucket) + disjoint; `dead` read from the `@retry` `{:ok, :dead}` outcome; an absent verdict → fail-safe retry. PURE (no process, no clock, no I/O); doctests like `BatchShaper.Core`. | US-PARTITION | INV-Partition |
| R2 | Build `@delay` — a NEW inline `Script.new(:delay, …)` in `jobs.ex` BESIDE `@schedule` (D-1 = Arm B): token-fence on the row `attempts` (`EMQSTALE` on mismatch — the `@complete:258-262` pattern); `ZREM` the `active` set; `HSET` the row `state = scheduled` (attempts UNTOUCHED — the defining delta from `@schedule`'s `attempts 0`); `ZADD` the `schedule` set at `now + ms` (server `TIME`, the `@schedule:63-66` relative math) or the caller's absolute-due ms; a missing row returns a typed absent. Declared keys pin the `{q}` slot (`active`, `schedule`, the `job:` row — the `@retry:760-765` convention). | US-DELAY | INV-Delay-Rescore, INV-Delay-Atomic, INV-ServerClock, INV-DeclaredKeys |
| R3 | Build `Jobs.delay/5` `(conn, queue, job_id, token, ms)` — the host verb (D-2 = Arm T, token-required): gates the id at `Keyspace.job_key/2`; evals `@delay`; maps `{:ok, 1}` → `:ok`, the typed-absent → `{:error, :gone}`, `{:error, {:server, "EMQSTALE" <> _}}` → `{:error, :stale}` (the `complete/5`/`retry/7`/`extend_lock/5` return convention). The `token` is the **attempts-token** (`att`), the same the cadence threads to `complete`/`retry`. The two due modes (relative / absolute) via a mode arg, mirroring `enqueue_in`/`enqueue_at`. | US-DELAY, US-STALE | INV-Delay-Rescore, INV-Delay-Token |
| R4 | Extend the PRIVATE `defp settle` (`batch_consumer.ex:257-269`): ADD the `{:delay, ms}` verdict branch beside `:ok`/`{:error, reason}` → `Jobs.delay(s.conn, s.queue, id, att, ms)` + `publish(s, "delayed", id)`. **Pass `att`** (the attempts-token, the same fence the sibling `Jobs.complete` `:261` / `Jobs.retry` `:265` pass). The absent-member fail-safe + the `:ok`/`{:error, reason}` branches UNCHANGED; the `delayed` event rides the byte-frozen `Events.publish/5`. | US-CADENCE | INV-Delay-Rescore, INV-Partition |
| R5 | Register the conformance scenarios additively: `batch_partition` (a claimed batch resolved into a partition — exhaustive + disjoint, `dead` from the retry outcome), `batch_delay` (the active→scheduled re-score — attempts PRESERVED, atomic, invisible-to-claim-until-due, promote releases it, fresh claim mints the NEXT attempt), `batch_delay_stale` (the stale-token `EMQSTALE` refusal — the live token settles). The prior 70 byte-unchanged; re-pin **70 → 70+N** in BOTH pinning tests. | US-ADDITIVE | INV-Frozen, S-3/§5 |
| R6 | Byte-freeze every shipped transition script: `grep redis.call` on `@complete`/`@retry`/`@schedule`/`@promote`/`@bclaim`/`@gbclaim` in the lib diff = 0; the prior scenarios git-verified unchanged. `@delay` is the ONLY added script body. | US-ADDITIVE, US-GATE | INV-Frozen |
| R7 | Pass the per-app gate ladder on Valkey 6390 + the **MULTI-SEED determinism sweep** (NOT the ≥100 loop — no new mint/lease, carve §3; the posture statement names why); honest-row reporting; the diff inside `echo/apps/echo_mq`; `mix.exs` label `2.5.2`, the wire `@wire_version` unchanged. | US-GATE | INV-Determinism, S-4, every INV |

---

## 3 · Execution topology

**Runtime shape.** Two additive pieces, no new process. (1) `EchoMQ.BatchFinish.partition/N` is a PURE function —
input the M claimed ids + the verdict map + the transition outcomes, output the four-bucket partition; no I/O (D-3 =
Arm N). (2) `@delay` is ONE inline Lua script, ONE atomic turn: token-fence (the attempts-token) → `ZREM active` →
`HSET state scheduled` (attempts untouched) → `ZADD schedule now+ms` (server `TIME` or caller ms) (D-1 = Arm B). The
host verb `Jobs.delay/5` is the thin `complete/5`-shaped envelope (gate the id, eval, map the return). The private
`defp settle` branch is three new lines (the `{:delay, ms}` case, passing `att`). No new key, no wire change, no
`echo_wire` edit.

**Files touched (the EXACT set — boundary `echo/apps/echo_mq`):**
- `lib/echo_mq/batch_finish.ex` — **NEW** (the pure partition classifier — the `BatchShaper.Core` sibling, D-3 = Arm N).
- `lib/echo_mq/jobs.ex` — ADDED `@delay` (a NEW `Script.new(:delay, …)` beside `@schedule`) + `Jobs.delay/5`. Every
  shipped transition script (`@schedule`/`@complete`/`@retry`/`@promote`/`@bclaim`) byte-frozen.
- `lib/echo_mq/batch_consumer.ex` — ADDED the `{:delay, ms}` branch in the private `defp settle`
  (`batch_consumer.ex:257-269`), passing `att`. The `:ok`/`{:error, reason}` branches + the absent-member fail-safe
  byte-unchanged.
- `lib/echo_mq/conformance.ex` — ADDED `batch_partition`/`batch_delay`/`batch_delay_stale` (`scenarios/0` entries +
  `apply_scenario` clauses). The prior scenarios byte-unchanged. The moduledoc OPENING prose trued up to the live count.
- `test/conformance_run_test.exs` — re-pinned `{:ok, 70}` → `{:ok, 70+N}`.
- `test/conformance_scenarios_test.exs` — appended the new names to `@run_order` (70 → 70+N); count prose updated.
- `mix.exs` — the rung label `2.5.1` → `2.5.2` (the within-family patch; the wire `@wire_version` stays `echomq:2.4.2`).
- **NOT** `keyspace.ex` (no new key family — `@delay` rides the shipped `active`/`schedule` sets + the gated `job:` row).
- **NOT** `lanes.ex` (the grouped-batch finish is a carried follow-up, named not built — `@gbclaim` byte-frozen).
- **NOT** `echo_wire` (the verb rides the shipped connector `eval`). **NOT** `apps/echomq` (the frozen reference).

**Build-order DAG (RULED B · T · N):**
```
R0  FORK 5.4-A RULED B · T · N (Operator, AskUserQuestion; the body/brief/stories synced to it)
   ├─► R1  EchoMQ.BatchFinish.partition/N  (D-3 = Arm N — the pure classifier, independent of the wire)
   └─► R2  @delay  (D-1 = Arm B — the new atomic script, the inverse of @claim, attempts preserved, token-fenced)
         └─► R3  Jobs.delay/5  (D-2 = Arm T — the host verb, token-required on the attempts-token; gate, eval, map)
               └─► R4  defp settle {:delay, ms} branch  (the cadence routes a delayed member, passing att)
                     └─► R5  conformance scenarios  (batch_partition + batch_delay + batch_delay_stale; re-pin 70 → 70+N)
                           └─► R6  byte-freeze grep (= 0 on every shipped transition script)
                                 └─► R7  the gate ladder + the multi-seed sweep
```

---

## 4 · Agent stories (Directive + Acceptance gate — the contracts the Operator/Apollo accept at the boundary)

### AS-1 — `EchoMQ.BatchFinish.partition/N`, the pure partition classifier (R1)

**Directive.** Add a NEW pure module `lib/echo_mq/batch_finish.ex` (the `BatchShaper.Core` sibling — no process, no
clock, no I/O, doctests). `partition/N` maps the M claimed member ids + the per-member verdict map + the per-member
transition outcomes into `%{completed: [...], retried: [...], dead: [...], delayed: [...]}`. The classification rule:
a `:ok` verdict → `completed`; a `{:error, reason}` verdict → `retried` if its `@retry` outcome was `{:ok, :scheduled}`,
or `dead` if `{:ok, :dead}` (the attempts cap — read the OUTCOME, do not assert dead from the verdict); a `{:delay,
ms}` verdict → `delayed`; an ABSENT verdict → fail-safe `retried` (the emq.5.2 "missing verdict"). The result is
exhaustive (every claimed id in exactly one bucket) + disjoint.

- **Precondition.** A claimed batch of M ids; a verdict map (possibly missing some ids); the transition outcomes.
- **Postcondition.** `%{completed, retried, dead, delayed}` where the union is a permutation of the M ids, the buckets
  disjoint.
- **Invariant.** Exhaustive + disjoint; `dead` read from the `@retry` outcome; pure.
- **Acceptance gate.** A pure unit-test scenario asserts `completed ++ retried ++ dead ++ delayed` is a permutation of
  the M ids, the four lists pairwise disjoint, an absent verdict lands in `retried`.

### AS-2 — `@delay` + `Jobs.delay/5`, the dynamic-delay re-score (R2, R3; D-1 = Arm B, D-2 = Arm T)

**Directive.** Add a NEW inline `Script.new(:delay, …)` in `jobs.ex` beside `@schedule` (D-1 = Arm B). The body: read
the row `attempts`; if absent return a typed absent; if it `~= ARGV[token]` return `redis.error_reply('EMQSTALE …')`
(the `@complete:258-262` fence, on the attempts-token — D-2 = Arm T); else `ZREM` the `active` set, `HSET` the row
`state = scheduled` (**attempts UNTOUCHED**), and `ZADD` the `schedule` set at `now + ms` (server `TIME`, the
`@schedule:63-66` math — relative mode) or the caller's absolute-due ms. Declared keys pin the `{q}` slot (`active`,
`schedule`, the `job:` row — the `@retry:760-765` convention). Add `Jobs.delay/5` `(conn, queue, job_id, token, ms)`:
gate the id at `Keyspace.job_key/2`; eval `@delay`; map `{:ok, 1}` → `:ok`, the typed-absent → `{:error, :gone}`,
`EMQSTALE` → `{:error, :stale}` (the `complete/5`/`retry/7` return convention).

- **Precondition.** An active member at a known attempts-token; FORK 5.4-A RULED B · T · N.
- **Postcondition.** The member moves `active → scheduled` (state=scheduled, attempts PRESERVED), released to `pending`
  by `promote/2` once due; a stale token is refused `EMQSTALE` changing nothing.
- **Invariant.** Attempts preserved (NOT reset); the `ZREM active` + `ZADD schedule` in ONE script (atomic, no
  lost-member window); token-fenced on the attempts-token; server-clock score; the declared `{q}` slot.
- **Acceptance gate.** The `batch_delay` `:valkey` scenario: claim (attempts → 1), `delay`, assert state=scheduled +
  attempts STILL 1 + in `schedule`/absent from `active` + invisible to `claim`; `promote` → `pending`; fresh claim →
  attempts 2. `grep redis.call` on every OTHER transition script = 0 (`@delay` the only added body).

### AS-3 — the cadence `{:delay, ms}` branch (R4; the fourth move)

**Directive.** Extend the PRIVATE `defp settle` (`batch_consumer.ex:257-269`): add the `{:delay, ms}` case beside `:ok`
and `{:error, reason}` → `Jobs.delay(s.conn, s.queue, id, att, ms)` + `publish(s, "delayed", id)`. **Pass `att`** (the
attempts-token, the same fence the sibling `Jobs.complete` `:261` / `Jobs.retry` `:265` pass — each member destructured
`{id, _payload, att}` at `:258`). Leave the `:ok` → `complete/5` + `{:error, reason}` → `retry/7` branches and the
absent-member fail-safe (`Map.get(verdicts, id, {:error, "missing verdict"})`) byte-unchanged. The `delayed` event
rides the byte-frozen `Events.publish/5`.

- **Precondition.** AS-2 complete (`Jobs.delay/5` exists).
- **Postcondition.** A `{:delay, ms}` verdict routes the member through `delay/5` (passing `att`) + emits a `delayed`
  event; the partition is observable through the cadence's settle.
- **Invariant.** The `:ok`/`{:error, reason}` branches + the fail-safe unchanged; the delay branch is purely additive.
- **Acceptance gate.** A `:valkey` cadence scenario (or the `batch_partition` scenario via the consumer) drives a
  verdict map with a `{:delay, ms}` member and asserts it re-scores to `schedule` with a `delayed` event, the `:ok`
  members complete, the `{:error, reason}` members retry.

### AS-4 — the conformance scenarios + the count re-pin (R5, R6)

**Directive.** Register the three scenarios in `scenarios/0` (a `name: "contract"` entry each) + a `defp
apply_scenario(:name, conn, q)` clause each: (a) `batch_partition` — claim a batch, resolve it with a mixed verdict
map (some complete, some retry, some at-cap → dead, some delay), assert the partition is exhaustive + disjoint over the
claimed ids and `dead` holds the at-cap members; (b) `batch_delay` — the active→scheduled re-score (attempts PRESERVED,
invisible-to-claim-until-due, promote releases it, fresh claim mints the NEXT attempt); (c) `batch_delay_stale` — claim
(token 1), reap + re-claim (token 2), a `delay` with token 1 refused `EMQSTALE` untouched, the live token 2 settles.
Keep the prior 70 byte-unchanged; re-pin 70 → 70+N in BOTH pinning tests (the `{:ok, 70+N}` assertion + the `@run_order`
list + the count prose). True up the moduledoc OPENING prose to the live count.

- **Precondition.** The prior 70 scenarios green and byte-unchanged.
- **Postcondition.** `Conformance.run/2` → `{:ok, 70+N}`; both pinning tests pass.
- **Invariant.** The prior scenarios byte-identical (git-verified); each new probe registered in the same change; the
  `batch_delay` scenario's attempts-PRESERVED assertion is load-bearing (a no-op that reset attempts fails it).
- **Acceptance gate.** `git diff` on `conformance.ex` shows only additions to `scenarios/0` + new `apply_scenario`
  clauses (+ the moduledoc prose true-up); `Conformance.run/2` prints 70+N lines.

### AS-5 — the gate ladder + the multi-seed sweep (R7)

**Directive.** Run the per-app gate ladder INSIDE `echo/apps/echo_mq`: re-probe `asdf current` from the app dir;
`valkey-cli -p 6390 ping` → PONG; `TMPDIR=/tmp mix compile --warnings-as-errors`; `TMPDIR=/tmp mix test --include
valkey`; `EchoMQ.Conformance.run/2` → `{:ok, 70+N}`; the **MULTI-SEED determinism sweep** (`for s in 0 1 2 7 42 99; do
TMPDIR=/tmp mix test --include valkey --seed $s || break; done` — NOT the ≥100 loop; the posture statement names why:
no new mint/lease — `delay/5` releases a lease, the partition is pure, carve §3); the byte-freeze grep (= 0 on every
shipped transition script). Report honest-row (Valkey 6390).

- **Precondition.** AS-1..AS-4 complete.
- **Postcondition.** Every gate green; the multi-seed sweep green; the posture statement recorded.
- **Invariant.** The diff stays inside `echo/apps/echo_mq` (+ no `echo_wire` edit); `mix.lock` excluded unless a real
  dep moved (none expected); the rung label `2.5.2`, the wire `@wire_version` unchanged.
- **Acceptance gate.** The full ladder green; the multi-seed sweep green; the byte-freeze grep 0; the boundary clean.

---

## 5 · The short prompt (RULED B · T · N — no decision left open)

The partitioned finish + a dynamic delay inside `echo/apps/echo_mq`, closing the batches family — additive over the
byte-frozen `@complete`/`@retry`/`@schedule`/`@promote`/`@bclaim`/`@gbclaim`. The PARTITION is the pure
`EchoMQ.BatchFinish.partition/N` (the `BatchShaper.Core` sibling — D-3 = Arm N) → `%{completed, retried, dead,
delayed}` (exhaustive + disjoint over the claimed members; `dead` read from the `@retry` `{:ok, :dead}` outcome, NOT a
caller verdict; an absent verdict fail-safe-retries). The DYNAMIC DELAY is `Jobs.delay/5` (D-1 = Arm B, D-2 = Arm T: a
NEW inline `@delay` beside `@schedule`, atomic in one EVAL — token-fence `EMQSTALE` on the attempts-token, `ZREM
active`, `HSET state scheduled` with **attempts PRESERVED**, `ZADD schedule now+ms` on the server clock; the INVERSE of
`@claim` — releases a lease, mints nothing). The CADENCE gains the `{:delay, ms}` verdict in the private `defp settle`
(the third branch), routing through `Jobs.delay(s.conn, s.queue, id, att, ms)` — **passing `att`**, the same fence the
sibling `complete` `:261` / `retry` `:265` pass — + a `delayed` event. Register `batch_partition` + `batch_delay` +
`batch_delay_stale` additively (the prior 70 byte-unchanged → 70+N; the `batch_delay` scenario's attempts-PRESERVED
check is load-bearing). Every shipped transition script byte-frozen (`grep redis.call` = 0). No new key, no wire change
(`@wire_version` stays `echomq:2.4.2`), no `echo_wire` edit, no `apps/echomq` touch, no `lanes.ex` edit; `mix.exs`
label `2.5.2`. Gate per-app on Valkey 6390 + the MULTI-SEED sweep (NOT the ≥100 loop — no new mint/lease, carve §3).
The body [`emq.5.4.md`](emq.5.4.md) is authoritative.

Family: [`../emq.5.md`](../emq.5.md) · Body: [`emq.5.4.md`](emq.5.4.md) · Stories: [`emq.5.4.stories.md`](emq.5.4.stories.md)
· Runbook: [`emq.5.4.prompt.md`](emq.5.4.prompt.md) · Program law: `.claude/skills/echo-mq-program.md` · Design:
[`../../../../emq.design.md`](../../../../emq.design.md) §6.2 · The sibling cadence precedent: [`emq.5.2.md`](emq.5.2.md)
