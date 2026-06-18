# EMQ.3.2 · user stories — the child-result reads (the second sub-rung)

> Who wants the child-result reads, what they need, and how we will know it works. Each story is Connextra with
> Given/When/Then acceptance, an INVEST line naming the invariant(s) it encodes, and a Priority/Size/Implements
> line; the file ends with a Coverage line mapping every Deliverable to ≥1 story. The standing
> **`EMQ.3.2-US-GATE`** carries the Valkey gate (design §7) — a structural gate. emq.3.2 makes a single-queue
> flow's outcome **consumable**: the parent handler reads its children's results, the `:processed` value becomes
> a **real result** (closing emq.3.1's O1), and the reads are **pure** — all on one slot, no shipped Lua touched.

## EMQ.3.2-US1 — the result mechanism is settled before the build

As a **program Operator**, I want Fork R1 (a pure presence read vs the real-result-carrying completion) settled
before emq.3.2 builds, so that the rung does not silently commit a completion-contract change — whether the
first slice ships the **real child result** in `:processed` (Arm B, a host-side `complete` extension) or a pure
read of the emq.3.1 **presence marker** (Arm A) is **my** call, recorded, and the triad re-derives to the ruled
arm.

Acceptance criteria
- Given the family body + this rung's ledger surface Fork R1 with both arms steelmanned and the recommendation
  (Arm B), when emq.3.2 opens, then **no build artifact exists** until the Operator records the Fork R1 ruling.
- Given the Operator rules Arm B, when emq.3.2 builds, then `EchoMQ.Jobs.complete` gains a **result argument**
  threaded into the **existing `ARGV[5]` slot** the emq.3.1 fan-in hook already `HSET`s into `:processed`, the
  **`@complete` Lua stays byte-unchanged** (host-only), and `children_values/3` returns the **real** results.
- Given Fork R2 (the `dependencies/3` count vs set) is recorded with its recommendation (the **count**), when
  emq.3.2 opens, then it is surfaced for the Operator's optional ruling — and noted that R2·B is **not free**
  (it adds a `:children` roster subkey + an `@enqueue_flow` edit, a pre-build write-surface add), unlike R1·A
  which is a free narrowing of R1·B.

INVEST — independent (the gate that precedes every build story); testable by the ledger record + the build's
touch-set (Arm B → a host-only `complete` extension, the `@complete` Lua byte-unchanged); encodes
EMQ.3.2-INV3, EMQ.3.2-INV5. Priority: must · Size: 1 · Implements: EMQ.3.2-D1.

## EMQ.3.2-US2 — a parent handler reads its children's results

As a **bus consumer running a same-queue fan-in job**, I want to read what my children produced once they
complete, so that the parent runs **on** the children's results (not merely **after** them) — the v1
`get_children_values` capability — without my tracking each child myself.

Acceptance criteria
- Given a flow whose children have completed (each carrying a result under R1·B), when
  `EchoMQ.Flows.children_values/3` is called with the parent's id, then it returns `{:ok, %{child_id =>
  result}}` — the completed children keyed by child id, each value the **real result** the child carried at
  completion — by a **pure** read of the parent's `emq:{q}:job:<parent>:processed` HASH.
- Given a flow whose parent has **no** completed children yet (just enqueued), when `children_values/3` is
  called, then it returns `{:ok, %{}}` (the empty result map), never an error.
- Given an **ill-formed** `parent_id`, when `children_values/3` is called, then it **raises** at
  `Keyspace.job_key/2` (the gated key builder) before any wire — never a malformed read.

INVEST — independent (the family's result-read capability); testable by the `flow_children_values` `:valkey`
scenario (two children completed with distinct results → the result map keyed by child id) + an empty-parent
read + an ill-formed-id raise; encodes EMQ.3.2-INV2, EMQ.3.2-INV4, EMQ.3.2-INV5. Priority: must · Size: 3 ·
Implements: EMQ.3.2-D2.

## EMQ.3.2-US3 — a parent handler reads how many children remain

As a **bus consumer**, I want to read the parent's outstanding-child count, so that I can introspect a flow's
progress — how many legs are still running — the v1 `get_dependencies` capability, by a single cheap read.

Acceptance criteria
- Given a flow parent with N children and k completed, when `EchoMQ.Flows.dependencies/3` is called with the
  parent's id, then it returns `{:ok, N − k}` (the outstanding count) — a **pure** `GET`-class read of the
  parent's `emq:{q}:job:<parent>:dependencies` STRING counter, parsed to a non-negative integer; `{:ok, 0}`
  once every child has completed (Fork R2·A — the **count**, not the set).
- Given a `parent_id` with **no** `:dependencies` key (not a flow parent, or already swept by a later lifecycle
  rung), when `dependencies/3` is called, then it returns **`{:ok, 0}`** (the build chose the count's natural
  floor — no new error vocabulary), never a crash or a malformed integer.
- Given an **ill-formed** `parent_id`, when `dependencies/3` is called, then it **raises** at
  `Keyspace.job_key/2` before any wire.

INVEST — independent (the dependency-count read); testable by a `:valkey` read of `dependencies/3` after k of N
children complete (returns `N − k`; `0` at full fan-in) + the none-key sentinel + an ill-formed-id raise;
encodes EMQ.3.2-INV2, EMQ.3.2-INV4. Priority: should · Size: 2 · Implements: EMQ.3.2-D3.

## EMQ.3.2-US4 — the child carries a real result; the shipped completion is byte-unchanged

As a **protocol maintainer**, I want a flow child's completion to record the **real result** it produced — by a
**host-only** extension that leaves every shipped Lua script byte-unchanged — so that O1 closes (the
`:processed` value is the result, not a placeholder) without re-tiering the rung to high-risk.

Acceptance criteria
- Given a flow child completing with a result, when `EchoMQ.Jobs.complete` is called with the result argument
  (R1·B), then the result is passed through the **existing `ARGV[5]` slot** and the emq.3.1 fan-in hook records
  it in `:processed[child_id]` — and the **`@complete` Lua attribute is byte-unchanged** (it already `HSET`s
  `ARGV[5]`; only the *value* the host supplies changes, from `job_id` to the result).
- Given a **non-flow** job completing (no parent), when `complete` is called, then it takes the **byte-unchanged**
  shipped path (`KEYS[3]` nil → the fan-in branch unreached → `ARGV[5]` unused), and a caller passing no result
  is the shipped completion.
- Given **every** shipped `@… Script.new/2` attribute in `jobs.ex` + `flows.ex` (**all 15 as-built** — the 8
  state-machine/flow scripts `@enqueue` / `@claim` / `@complete` / `@retry` / `@promote` / `@reap` / `@schedule` /
  `@enqueue_flow` **plus** the 7 emq.2.x mutation scripts `@update_data` / `@update_progress` / `@add_log` /
  `@remove_job` / `@reprocess` / `@extend_lock` / `@extend_locks`), when emq.3.2 lands, then a `git diff` of each
  is **empty** — the proof that R1·B is host-only and the rung is **NORMAL-risk** (no shipped-script edit).

INVEST — independent (the O1-closing host extension); testable by a `:valkey` scenario completing children with
distinct results (`children_values/3` returns the results) + the byte-unchanged non-flow completion + the empty
`git diff` of every Lua attribute; encodes EMQ.3.2-INV1, EMQ.3.2-INV3, EMQ.3.2-INV5. Priority: must · Size: 3 ·
Implements: EMQ.3.2-D4.

## EMQ.3.2-US5 — the reads are pure; the flow-subkey lifecycle is named, not discovered

As a **program Director**, I want the result reads proven side-effect-free and the flow-subkey cleanup
disposition stated in the spec body, so that emq.3.2 closes on a pure read surface and an **explicit** lifecycle
bound — not a silent at-rest leak a green board cannot catch.

Acceptance criteria
- Given `children_values/3` and `dependencies/3`, when each is called any number of times, then the flow's
  `:dependencies` count and `:processed` contents are **byte-identical** before and after (the reads are
  **pure** — `HGETALL`/`GET`-class only, no `HSET`/`SET`/`DECR`/`ZADD`/`DEL`).
- Given the subkeys emq.3.2 reads outlive the parent row (emq.3.1 L-5 — `@complete` `DEL`s only the row;
  `obliterate`'s `del_job` enumerates only `jk`/`:logs`/`:lock`), when emq.3.2 specs its scope, then the body
  **names** the cleanup disposition: the `obliterate`-sweep (`del_job` gains `:dependencies`/`:processed`) **and**
  per-flow completion cleanup, **both routed to the emq.3.x lifecycle rung** (each would re-tier emq.3.2 out of
  NORMAL-risk) — emq.3.2 itself adds **zero** cleanup and leaves the subkeys (correct — the reads need them).
- Given the named carry, when emq.3.2 lands, then its touch-set contains **no** `DEL`/`HDEL`/`UNLINK` of a flow
  subkey, `admin.ex` is **untouched** (the emq.3.1 obliterate-moduledoc carry re-affirmed for the lifecycle
  rung), and the body records the honest bounds **N1** (the lifecycle carry), **N2** (the O2 fold is optional,
  not required), **N3** (single-queue, one-level only).

INVEST — independent (the purity + the named lifecycle); testable by a double-read byte-identity scenario + the
body naming both cleanup mechanisms + the empty cleanup touch-set; encodes EMQ.3.2-INV2, EMQ.3.2-INV7,
EMQ.3.2-INV8. Priority: must · Size: 2 · Implements: EMQ.3.2-D5.

## EMQ.3.2-US6 — the new read is a conformance scenario; the prior set is untouched; no regression

As a **protocol maintainer**, I want the child-result read registered as a conformance scenario with its probe
in the same change and the prior set byte-unchanged, the flow read proven under the determinism loop, and the
shipped surface unregressed, so that the protocol grows by additive minor and emq.3.2 closes on a proven core —
not a false-green.

Acceptance criteria
- Given `flow_children_values`, when it is added to `scenarios/0`, then it is registered **with its probe in the
  same change**, and the prior **45** scenarios pass **byte-unchanged** (name + contract + verdict body
  identical, git-verified); the count is re-pinned **45 → 46** in **both** pinning tests
  (`conformance_scenarios_test.exs` + `conformance_run_test.exs`), and `EchoMQ.Conformance.run/2` prints
  `{:ok, 46}`.
- Given the mint/process-touching read scenario (a flow minting N+1 ids, fanned in, then read), when it is
  gated, then it runs under the **≥100-iteration determinism loop** owning the machine (one green run is NOT
  proof — a flow read stands on a flow that minted many ids), and a same-millisecond mint collision is caught
  there.
- Given the shipped surface, when emq.3.2 lands, then the emq.1 + emq.2.{1,2,3,4} + **emq.3.1** suites +
  `Conformance.run/2` pass **unchanged** (no regression — INV3), and **Apollo is OPTIONAL** (NORMAL-risk — no
  shipped-script edit; the Director's solo review + the gate ladder are the gate).

INVEST — independent (the additive-minor contract + the proof); testable by the git-verified byte-unchanged
prior set + the re-pinned count in both tests + the ≥100 loop green + the prior suites green; encodes
EMQ.3.2-INV6, EMQ.3.2-INV3. Priority: must · Size: 2 · Implements: EMQ.3.2-D6.

## EMQ.3.2-US-GATE — the Valkey gate (specification by example)

As a **release gate**, I want the child-result reads proven on the certified wire under honest-row reporting, so
that the v2 laws bind at the wire (design §7, S-4).

Acceptance criteria
- Given the engine-hygiene allowlist {Valkey, Redis-as-the-historical-row}, when the read suites run, then they
  run against **Valkey on port 6390** (the truth row; `redis-cli -p 6390 ping` → `PONG`); a host without Valkey
  reports its row honestly, never the truth row.
- Given `GET {emq}:version`, when read after the bus connects, then it returns `echomq:2.0.0` (the
  connect-scoped fence — emq.3.2 changes nothing about the fence; the five-code union stands unextended).
- Given grammar totality, when a flow read key (`emq:{q}:job:<parent>:processed` / `:dependencies`) is parsed,
  then it classifies under the §6 grammar (the `job:<id>:<sub>` subkeys), the queue name extracts as the `{q}`
  hashtag, and `q ≠ "emq"` keeps the slot families disjoint — emq.3.2 edits the grammar's shape not at all.
- Given the conformance run, when `Conformance.run/2` executes, then it prints one line per scenario, the prior
  set is byte-unchanged, and `flow_children_values` is present (the count re-pinned in both pinning tests).

INVEST — independent (the standing structural gate); testable by the honest-row run + `{emq}:version` + grammar
totality + the additive-minor conformance; encodes EMQ.3.2-INV1, EMQ.3.2-INV6. Priority: must · Size: 1 ·
Implements: design §7, S-4 (the structural gate).

## Coverage

| Deliverable | Story |
|---|---|
| EMQ.3.2-D1 — the fork gate (R1 ruled; R2 recorded) | US1 |
| EMQ.3.2-D2 — `EchoMQ.Flows.children_values/3` (the result read) | US2 |
| EMQ.3.2-D3 — `EchoMQ.Flows.dependencies/3` (the outstanding-count read, R2·A) | US3 |
| EMQ.3.2-D4 — the real-result-carrying completion (R1·B, host-only; the `@complete` Lua byte-unchanged) | US4 |
| EMQ.3.2-D5 — the flow-subkey lifecycle disposition (named carry; the §2 guardrail) | US5 |
| EMQ.3.2-D6 — the proof (additive-minor conformance; the ≥100 loop; no regression; Apollo optional) | US6 |
| The Valkey structural gate (honest-row; `{emq}:version`; grammar totality; additive-minor conformance) | US-GATE |

Spec body: [`./emq.3.2.md`](emq.3.2.md) (authoritative)
· Family: [`./emq.3.md`](../emq.3.md) (the contract + the carve + the forks) · The first slice (SHIPPED):
[`./emq.3.1.md`](emq.3.1.md).
