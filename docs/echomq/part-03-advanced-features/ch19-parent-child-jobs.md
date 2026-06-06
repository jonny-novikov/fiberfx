# Chapter 19. Parent-Child Jobs

Parent-child jobs form the dependency backbone of EchoMQ flows. A parent job enters a special **waiting-children** state and does not process until every child completes. Children can carry return values that the parent aggregates, and configurable failure modes let you decide whether a single child failure should cascade, be ignored, or trigger early parent execution.

```
                    ┌─────────────────────────────────────────────┐
                    │            Flow Dependency Tree              │
                    ├─────────────────────────────────────────────┤
                    │                                              │
                    │   gather-ore ──────┐                         │
                    │                    │                         │
                    │   smelt-ingot ─────┼──▶ craft-legendary     │
                    │                    │    (waiting-children)   │
                    │   enchant-rune ────┘         │               │
                    │                              ▼               │
                    │                     craft-legendary          │
                    │                     (waiting ──▶ active)     │
                    │                              │               │
                    │                              ▼               │
                    │                        process with          │
                    │                     aggregated results       │
                    │                                              │
                    └─────────────────────────────────────────────┘
```

---

## 19.1. Creating a Parent-Child Flow

Parent-child relationships are defined through `FlowProducer`, which atomically adds the entire job tree to Redis in a single transaction. The parent receives a `parentKey` reference on each child, and children are placed into their respective queues immediately.

<tabs>
<tab title="Elixir">

```elixir
# Match finalization: parent aggregates XP and rewards from each player
{:ok, flow} = EchoMQ.FlowProducer.add(%{
  name: "finalize-match",
  queue_name: "matchmaking",
  data: %{match_id: "MTH0K5M2vuIULY", mode: "ranked"},
  children: [
    %{
      name: "calculate-player-xp",
      queue_name: "player-events",
      data: %{player_id: "PLR0K48QjihpC4", kills: 12, assists: 5, deaths: 3}
    },
    %{
      name: "calculate-player-xp",
      queue_name: "player-events",
      data: %{player_id: "PLR3QR5T7V9W2X", kills: 8, assists: 9, deaths: 4}
    },
    %{
      name: "calculate-player-xp",
      queue_name: "player-events",
      data: %{player_id: "PLR5M2vuIULYab", kills: 15, assists: 2, deaths: 6}
    }
  ]
}, connection: :redis)

# All three children are added atomically
# Parent enters waiting-children state
# When all three complete, parent moves to waiting -> active
```

The `FlowProducer.add/2` call wraps a Redis `MULTI/EXEC` transaction. Either all four jobs (one parent, three children) are created, or none are. Each child's job hash includes a `parentKey` field pointing back to the parent's Redis key.

> **Benefit**: `Ecto.Multi` composes the enqueue step into the database transaction — atomic commit or rollback.

</tab>
<tab title="Go">

```go
// Feature: FlowProducer / Parent-Child Job Dependencies
//
// Not yet implemented in echomq-go. BullMQ's FlowProducer atomically
// creates a tree of parent-child jobs using a Redis MULTI/EXEC
// transaction. The parent enters a "waiting-children" state and does
// not process until all children complete.
//
// Workaround:
//   Implement manual dependency tracking:
//   1. Add child jobs with a shared "matchRef" in their data
//   2. In each child's completion handler, atomically increment a
//      Redis counter (INCR bull:{queue}:MTH0K5M2vuIULY:children_done)
//   3. When the counter equals the expected child count, add the
//      parent "finalize-match" job with aggregated results
//
// Example:
//   queue := echomq.NewQueue("player-events", rdb)
//   for _, player := range players {
//       queue.Add(ctx, "calculate-player-xp",
//           map[string]interface{}{
//               "player_id": player.ID,
//               "match_ref": "MTH0K5M2vuIULY",
//               "kills":     player.Kills,
//           }, echomq.JobOptions{})
//   }
//
// Reference: PROTOCOL-GAPS.md — GAP-006 (moveToFinished handles
//   parent dependency resolution; required for native flow support)
```

> **Tradeoff**: Enqueue happens after `tx.Commit()` — a crash between commit and enqueue requires recovery.

</tab>
<tab title="Node.js">

```typescript
import { FlowProducer } from "bullmq";

const flowProducer = new FlowProducer({ connection });

const flow = await flowProducer.add({
  name: "finalize-match",
  queueName: "matchmaking",
  data: { match_id: "MTH0K5M2vuIULY", mode: "ranked" },
  children: [
    {
      name: "calculate-player-xp",
      queueName: "player-events",
      data: { player_id: "PLR0K48QjihpC4", kills: 12, assists: 5, deaths: 3 },
    },
    {
      name: "calculate-player-xp",
      queueName: "player-events",
      data: { player_id: "PLR3QR5T7V9W2X", kills: 8, assists: 9, deaths: 4 },
    },
    {
      name: "calculate-player-xp",
      queueName: "player-events",
      data: { player_id: "PLR5M2vuIULYab", kills: 15, assists: 2, deaths: 6 },
    },
  ],
});

// flow.job — the parent Job instance
// flow.children — array of { job, children } for each child
```

> **Benefit**: FlowProducer class provides the reference implementation for complex job DAGs.

</tab>
</tabs>

> **⚠️ Go Gap**: FlowProducer (parent-child job tree creation) is not implemented. The entire flow subsystem is missing.
> **Proposed Solution**: Implement `FlowProducer.Add()` using the `addFlowJob` Lua script family. Build a recursive tree walker that creates leaf jobs first, then parents with `waitChildrenKey` references. Requires `moveToWaitingChildren` Lua script integration.

---

## 19.2. The waiting-children State

When a flow is created, parent jobs enter the `waiting-children` state. This is a distinct job state alongside `waiting`, `active`, `delayed`, and `completed`. The parent remains in this state until every child dependency is resolved.

```
child-1 (waiting ──▶ active ──▶ completed) ──┐
                                              │
child-2 (waiting ──▶ active ──▶ completed) ──┼──▶ parent (waiting-children ──▶ waiting ──▶ active)
                                              │
child-3 (waiting ──▶ active ──▶ completed) ──┘
```

The transition from `waiting-children` to `waiting` happens automatically inside the `moveToFinished` Lua script when the last child completes. No polling or external coordination is needed.

---

## 19.3. Accessing Child Results

When the parent job finally processes, it can retrieve the return values from all completed children. Results are keyed by `"queueName:jobId"`, giving the parent full visibility into which child produced which result.

<tabs>
<tab title="Elixir">

```elixir
defmodule Fireheadz.MatchFinalizer do
  @moduledoc "Processes the finalize-match parent job"

  def process(%EchoMQ.Job{name: "finalize-match"} = job) do
    # Retrieve return values from all children
    {:ok, children_values} = EchoMQ.Job.get_children_values(job)

    # children_values is a map:
    # %{
    #   "player-events:abc123" => %{"xp" => 1200, "player_id" => "PLR0K48QjihpC4"},
    #   "player-events:def456" => %{"xp" => 950, "player_id" => "PLR3QR5T7V9W2X"},
    #   "player-events:ghi789" => %{"xp" => 1450, "player_id" => "PLR5M2vuIULYab"}
    # }

    total_xp = Enum.reduce(children_values, 0, fn {_key, val}, acc ->
      acc + val["xp"]
    end)

    leaderboard_entries = Enum.map(children_values, fn {_key, val} ->
      %{player_id: val["player_id"], xp: val["xp"]}
    end)

    {:ok, %{
      match_id: job.data["match_id"],
      total_xp: total_xp,
      leaderboard: leaderboard_entries
    }}
  end
end
```

`get_children_values/1` reads the parent's dependency metadata from Redis. Each child's `returnvalue` hash field is deserialized and returned under its queue-qualified key.

> **Benefit**: `:telemetry` integration provides zero-cost event dispatch when no handlers are attached.

</tab>
<tab title="Go">

```go
// Feature: Child Result Aggregation (getChildrenValues)
//
// Not yet implemented in echomq-go. When a parent job processes in
// BullMQ, it can call job.getChildrenValues() to retrieve the return
// values from all completed children. Results are keyed by
// "queueName:jobId" so the parent knows which child produced which
// result.
//
// Workaround:
//   Store child results in a shared Redis hash:
//   1. Each child worker writes its result:
//      HSET bull:{queue}:MTH0K5M2vuIULY:results <childJobId> <jsonResult>
//   2. The manually-triggered parent reads the hash:
//      HGETALL bull:{queue}:MTH0K5M2vuIULY:results
//   3. Parse and aggregate results in the parent processor.
//
// Reference: PROTOCOL-GAPS.md — GAP-006 (moveToFinished stores
//   returnvalue and resolves parent dependencies atomically)
```

> **Benefit**: Move operations are Lua-script atomic — consistent across all queue states.

</tab>
<tab title="Node.js">

```typescript
import { Worker } from "bullmq";

const matchWorker = new Worker("matchmaking", async (job) => {
  if (job.name !== "finalize-match") return;

  // Retrieve all children's return values
  const childrenValues = await job.getChildrenValues();

  // childrenValues: {
  //   "player-events:1": { xp: 1200, player_id: "PLR0K48QjihpC4" },
  //   "player-events:2": { xp: 950, player_id: "PLR3QR5T7V9W2X" },
  //   "player-events:3": { xp: 1450, player_id: "PLR5M2vuIULYab" },
  // }

  const totalXp = Object.values(childrenValues).reduce(
    (sum, val) => sum + val.xp, 0
  );

  const leaderboard = Object.values(childrenValues).map((val) => ({
    player_id: val.player_id,
    xp: val.xp,
  }));

  return { match_id: job.data.match_id, total_xp: totalXp, leaderboard };
}, { connection });
```

> **Benefit**: EventEmitter pattern is native to Node.js — existing event-handling code works directly.

</tab>
</tabs>

### Dependency Inspection

Before or during processing, you can inspect how many children remain unresolved.

<tabs>
<tab title="Elixir">

```elixir
# Get pending (unresolved) child job keys
{:ok, dependencies} = EchoMQ.Job.get_dependencies(job)
# Returns list of "queueName:jobId" keys still pending

# Get count of pending dependencies
{:ok, count} = EchoMQ.Job.get_dependencies_count(job)
# Returns integer — 0 means all children are resolved
```

> **Benefit**: Stateless function calls with keyword options — no GenServer allocation needed for basic queue operations.

</tab>
<tab title="Go">

```go
// Feature: Dependency Inspection (getDependencies / getDependenciesCount)
//
// Not yet implemented in echomq-go. These methods query the parent
// job's dependency set in Redis to determine which children have not
// yet completed.
//
// Workaround:
//   Track dependencies manually using a Redis set:
//   1. On flow creation: SADD bull:{queue}:<parentId>:deps <childId1> <childId2> ...
//   2. On child completion: SREM bull:{queue}:<parentId>:deps <childId>
//   3. Check remaining: SCARD bull:{queue}:<parentId>:deps
//
// Reference: Ch 18 Flows Overview — Flow structure and dependency model
```

> **Benefit**: Context-based parent-child linking enables deadline propagation through the flow.

</tab>
<tab title="Node.js">

```typescript
// Get pending child job keys
const dependencies = await job.getDependencies();
// { unprocessed: ["player-events:4", "player-events:5"] }

// Get count of unresolved dependencies
const count = await job.getDependenciesCount();
// 0 means all children completed
```

> **Benefit**: EventEmitter pattern is native to Node.js — existing event-handling code works directly.

</tab>
</tabs>

---

## 19.4. Failure Handling

By default, if any child fails, the parent also fails. EchoMQ provides three failure modes to control this cascade behavior, each suited to different game scenarios.

### Default: fail_parent_on_failure

When `fail_parent_on_failure` is `true` (the default), a child failure propagates to the parent. The parent moves to the `failed` state without ever processing. This is appropriate when every child is critical.

<tabs>
<tab title="Elixir">

```elixir
# Raid boss encounter: every player phase MUST succeed
{:ok, flow} = EchoMQ.FlowProducer.add(%{
  name: "raid-complete",
  queue_name: "combat-actions",
  data: %{raid_id: "NPC6tH1bD3gW9Y", difficulty: "mythic"},
  children: [
    %{
      name: "phase-tank",
      queue_name: "combat-actions",
      data: %{player_id: "PLRaH3jL5nP7rT", role: "tank", boss: "NPC6tH1bD3gW9Y"}
      # fail_parent_on_failure defaults to true
    },
    %{
      name: "phase-healer",
      queue_name: "combat-actions",
      data: %{player_id: "PLRbI4kM6oQ8sU", role: "healer", boss: "NPC6tH1bD3gW9Y"}
    },
    %{
      name: "phase-dps",
      queue_name: "combat-actions",
      data: %{player_id: "PLRcJ5lN7pR9tV", role: "dps", boss: "NPC6tH1bD3gW9Y"}
    }
  ]
}, connection: :redis)

# If ANY phase fails (e.g., healer disconnects), the entire raid fails
# Parent "raid-complete" moves to failed state without processing
```

> **Benefit**: Flow trees compose naturally with OTP supervision — parent failure propagates to children.

</tab>
<tab title="Go">

```go
// Feature: fail_parent_on_failure (default child failure cascade)
//
// Not yet implemented in echomq-go. In BullMQ, when a child job
// fails and fail_parent_on_failure is true (the default), the
// moveToFinished Lua script automatically moves the parent to the
// failed state. The parent never processes.
//
// Workaround:
//   In the manual dependency-tracking pattern:
//   1. Each child completion handler checks its own success/failure
//   2. On failure, set a Redis flag:
//      SET bull:{queue}:<raidId>:failed "phase-healer" NX EX 3600
//   3. Before adding the parent job, check the flag:
//      if EXISTS bull:{queue}:<raidId>:failed → skip parent creation
//
// Reference: PROTOCOL-GAPS.md — GAP-006 (moveToFinished handles
//   parent failure cascade in the fpof branch of the Lua script)
```

> **Benefit**: Move operations are Lua-script atomic — consistent across all queue states.

</tab>
<tab title="Node.js">

```typescript
const flowProducer = new FlowProducer({ connection });

await flowProducer.add({
  name: "raid-complete",
  queueName: "combat-actions",
  data: { raid_id: "NPC6tH1bD3gW9Y", difficulty: "mythic" },
  children: [
    {
      name: "phase-tank",
      queueName: "combat-actions",
      data: { player_id: "PLRaH3jL5nP7rT", role: "tank", boss: "NPC6tH1bD3gW9Y" },
      // failParentOnFailure defaults to true
    },
    {
      name: "phase-healer",
      queueName: "combat-actions",
      data: { player_id: "PLRbI4kM6oQ8sU", role: "healer", boss: "NPC6tH1bD3gW9Y" },
    },
    {
      name: "phase-dps",
      queueName: "combat-actions",
      data: { player_id: "PLRcJ5lN7pR9tV", role: "dps", boss: "NPC6tH1bD3gW9Y" },
    },
  ],
});

// If any phase fails, parent "raid-complete" moves to failed
```

> **Benefit**: FlowProducer class provides the reference implementation for complex job DAGs.

</tab>
</tabs>

### ignore_dependency_on_failure

When a child has `ignore_dependency_on_failure: true`, its failure does not block the parent. The parent still waits for all children to finish (succeed or fail), then processes normally. Failed children's results are accessible separately via `get_ignored_children_failures/1`. This is ideal for optional bonus steps.

<tabs>
<tab title="Elixir">

```elixir
# Raid boss: bonus loot child is optional
{:ok, flow} = EchoMQ.FlowProducer.add(%{
  name: "distribute-loot",
  queue_name: "inventory",
  data: %{raid_id: "NPC6tH1bD3gW9Y", players: ["PLRaH3jL5nP7rT", "PLRbI4kM6oQ8sU"]},
  children: [
    %{
      name: "roll-base-loot",
      queue_name: "inventory",
      data: %{loot_table: "wyrm_standard", player_count: 2}
      # Required — parent fails if this fails
    },
    %{
      name: "roll-bonus-loot",
      queue_name: "inventory",
      data: %{loot_table: "wyrm_mythic_bonus", rng_seed: 42},
      opts: %{ignore_dependency_on_failure: true}
      # Optional — parent continues even if bonus roll fails
    }
  ]
}, connection: :redis)
```

In the parent processor, inspect which children failed:

```elixir
def process(%EchoMQ.Job{name: "distribute-loot"} = job) do
  {:ok, children_values} = EchoMQ.Job.get_children_values(job)
  {:ok, ignored_failures} = EchoMQ.Job.get_ignored_children_failures(job)

  base_loot = find_child_result(children_values, "roll-base-loot")

  bonus_loot =
    if map_size(ignored_failures) > 0 do
      Logger.warning("Bonus loot roll failed: #{inspect(ignored_failures)}")
      []
    else
      find_child_result(children_values, "roll-bonus-loot")
    end

  {:ok, %{base_loot: base_loot, bonus_loot: bonus_loot}}
end

defp find_child_result(values, name_prefix) do
  Enum.find_value(values, fn {key, val} ->
    if String.contains?(key, name_prefix), do: val
  end)
end
```

> **Benefit**: Flow trees compose naturally with OTP supervision — parent failure propagates to children.

</tab>
<tab title="Go">

```go
// Feature: ignore_dependency_on_failure
//
// Not yet implemented in echomq-go. This BullMQ option (stored as
// "idof" in the opts hash) tells the moveToFinished Lua script to
// NOT fail the parent when this specific child fails. The parent
// still waits for all children to resolve (succeed or fail), then
// processes with partial results.
//
// Workaround:
//   In the manual dependency-tracking pattern:
//   1. Mark optional children in job data: {"optional": true}
//   2. On child failure, if optional:
//      - Still decrement the dependency counter
//      - Store the failure in a separate hash:
//        HSET bull:{queue}:<parentRef>:failures <childId> <reason>
//   3. Parent reads both results and failures hashes to distinguish
//      successful children from ignored failures.
//
// Reference: PROTOCOL-GAPS.md — GAP-006 (moveToFinished handles
//   the idof flag in its dependency resolution branch)
```

> **Benefit**: Rate limit config is declarative — the Lua script enforces limits atomically in Redis.

</tab>
<tab title="Node.js">

```typescript
const flowProducer = new FlowProducer({ connection });

await flowProducer.add({
  name: "distribute-loot",
  queueName: "inventory",
  data: { raid_id: "NPC6tH1bD3gW9Y", players: ["PLRaH3jL5nP7rT", "PLRbI4kM6oQ8sU"] },
  children: [
    {
      name: "roll-base-loot",
      queueName: "inventory",
      data: { loot_table: "wyrm_standard", player_count: 2 },
      // Required — parent fails if this fails
    },
    {
      name: "roll-bonus-loot",
      queueName: "inventory",
      data: { loot_table: "wyrm_mythic_bonus", rng_seed: 42 },
      opts: { ignoreDependencyOnFailure: true },
      // Optional — parent continues even if bonus roll fails
    },
  ],
});

// Parent worker
const lootWorker = new Worker("inventory", async (job) => {
  if (job.name !== "distribute-loot") return;

  const childrenValues = await job.getChildrenValues();
  const failedChildren = await job.getDependencies({ type: "failed" });

  if (Object.keys(failedChildren).length > 0) {
    console.warn("Some optional children failed:", failedChildren);
  }

  return { base_loot: childrenValues, bonus_applied: Object.keys(failedChildren).length === 0 };
}, { connection });
```

> **Benefit**: FlowProducer class provides the reference implementation for complex job DAGs.

</tab>
</tabs>

### continue_parent_on_failure

The `continue_parent_on_failure` option (stored as `rdof` / `removeDependencyOnFailure` in the BullMQ protocol) causes the parent to start processing **immediately** when a child fails, even if other children are still running. This is useful in tournament scenarios where a player disconnect should trigger early match resolution rather than waiting for all remaining rounds.

<tabs>
<tab title="Elixir">

```elixir
# Tournament elimination: if a player disconnects, resolve match early
{:ok, flow} = EchoMQ.FlowProducer.add(%{
  name: "resolve-bracket",
  queue_name: "matchmaking",
  data: %{bracket_id: "MTH4bS6tV8xZ0G", round: "quarterfinal"},
  children: [
    %{
      name: "player-round",
      queue_name: "combat-actions",
      data: %{player_id: "PLR0K48QjihpC4", opponent: "PLR3QR5T7V9W2X"},
      opts: %{continue_parent_on_failure: true}
    },
    %{
      name: "player-round",
      queue_name: "combat-actions",
      data: %{player_id: "PLR5M2vuIULYab", opponent: "PLR5w8p1qM2tT4"},
      opts: %{continue_parent_on_failure: true}
    }
  ]
}, connection: :redis)
```

Handle the early trigger in the parent processor:

```elixir
def process(%EchoMQ.Job{name: "resolve-bracket"} = job) do
  {:ok, failed_children} = EchoMQ.Job.get_failed_children_values(job)

  if map_size(failed_children) > 0 do
    # Triggered by child failure (player disconnect)
    Logger.warning("Player disconnected: #{inspect(failed_children)}")

    # Cancel remaining rounds that haven't started
    EchoMQ.Job.remove_unprocessed_children(job)

    # Award win to the opponent of the disconnected player
    {:ok, %{result: "walkover", disconnected: Map.keys(failed_children)}}
  else
    # All children completed normally
    {:ok, children_values} = EchoMQ.Job.get_children_values(job)
    {:ok, %{result: "completed", rounds: children_values}}
  end
end
```

> **Benefit**: Flow trees compose naturally with OTP supervision — parent failure propagates to children.

</tab>
<tab title="Go">

```go
// Feature: continue_parent_on_failure (removeDependencyOnFailure)
//
// Not yet implemented in echomq-go. This BullMQ option causes the
// parent to start processing immediately when a child fails, rather
// than waiting for all children. The parent can then inspect which
// children failed via getFailedChildrenValues() and optionally
// cancel unprocessed siblings via removeUnprocessedChildren().
//
// Workaround:
//   In the manual dependency-tracking pattern:
//   1. Each child failure handler publishes to a Redis channel:
//      PUBLISH bull:{queue}:MTH4bS6tV8xZ0G:early-trigger <childId>
//   2. A separate goroutine subscribes and, on receiving a message,
//      immediately adds the parent "resolve-bracket" job with a
//      "triggered_by_failure" flag in its data.
//   3. The parent processor checks the flag and queries which
//      children completed vs. which failed.
//
// Reference: PROTOCOL-GAPS.md — GAP-006 (moveToFinished handles
//   the rdof flag, which removes the failed child from the parent's
//   dependency set and triggers parent processing if deps reach 0)
```

> **Benefit**: Rate limit config is declarative — the Lua script enforces limits atomically in Redis.

</tab>
<tab title="Node.js">

```typescript
const flowProducer = new FlowProducer({ connection });

await flowProducer.add({
  name: "resolve-bracket",
  queueName: "matchmaking",
  data: { bracket_id: "MTH4bS6tV8xZ0G", round: "quarterfinal" },
  children: [
    {
      name: "player-round",
      queueName: "combat-actions",
      data: { player_id: "PLR0K48QjihpC4", opponent: "PLR3QR5T7V9W2X" },
      opts: { removeDependencyOnFailure: true },
    },
    {
      name: "player-round",
      queueName: "combat-actions",
      data: { player_id: "PLR5M2vuIULYab", opponent: "PLR5w8p1qM2tT4" },
      opts: { removeDependencyOnFailure: true },
    },
  ],
});

// Parent worker
const bracketWorker = new Worker("matchmaking", async (job) => {
  if (job.name !== "resolve-bracket") return;

  const failedChildren = await job.getFailedChildrenValues();

  if (Object.keys(failedChildren).length > 0) {
    // Triggered early by player disconnect
    await job.removeUnprocessedChildren();
    return { result: "walkover", disconnected: Object.keys(failedChildren) };
  }

  // All rounds completed normally
  const results = await job.getChildrenValues();
  return { result: "completed", rounds: results };
}, { connection });
```

> **Benefit**: FlowProducer class provides the reference implementation for complex job DAGs.

</tab>
</tabs>

### Failure Mode Summary

| Mode | Option Key | Redis Short Key | Parent Behavior on Child Failure |
|------|-----------|-----------------|----------------------------------|
| **Fail parent** (default) | `fail_parent_on_failure: true` | `fpof` | Parent moves to `failed` without processing |
| **Ignore failure** | `ignore_dependency_on_failure: true` | `idof` | Parent waits for all children, processes with partial results |
| **Continue on failure** | `continue_parent_on_failure: true` | `rdof` | Parent starts immediately, can cancel remaining siblings |

---

## 19.5. Removing Dependencies at Runtime

During parent processing, you can modify the dependency graph by removing specific children or canceling all unprocessed siblings.

<tabs>
<tab title="Elixir">

```elixir
def process(%EchoMQ.Job{name: "coordinate-world-event"} = job) do
  {:ok, failed} = EchoMQ.Job.get_failed_children_values(job)

  if map_size(failed) > 0 do
    # A zone sync failed — cancel remaining zones to prevent
    # inconsistent world state
    EchoMQ.Job.remove_unprocessed_children(job)
    {:error, :partial_world_sync}
  else
    # Remove a specific child dependency manually
    # (e.g., a zone that was already synced by another system)
    EchoMQ.Job.remove_dependency(job, "world-sync:redundant_zone_job_id")

    {:ok, children_values} = EchoMQ.Job.get_children_values(job)
    {:ok, %{synced_zones: map_size(children_values)}}
  end
end
```

> **Benefit**: Job removal is atomic via Lua script — no partial state left in Redis.

</tab>
<tab title="Go">

```go
// Feature: Runtime Dependency Removal
//
// Not yet implemented in echomq-go. BullMQ provides two methods:
//
// 1. job.removeDependency(childKey) — removes a single child from
//    the parent's dependency set. If that was the last dependency,
//    the parent transitions from waiting-children to waiting.
//
// 2. job.removeUnprocessedChildren() — removes all children that
//    have not yet started processing (still in waiting/delayed).
//    Active children continue running but their results are ignored.
//
// Workaround:
//   With manual dependency tracking:
//   1. SREM bull:{queue}:<parentRef>:deps <childId>
//   2. If SCARD returns 0, add the parent job to trigger processing
//   3. For bulk removal, iterate SMEMBERS and delete unstarted jobs
//      via DEL bull:{queue}:<childId>
//
// Reference: Ch 18 Flows Overview — Flow limitations and atomicity
```

> **Benefit**: Rate limit config is declarative — the Lua script enforces limits atomically in Redis.

</tab>
<tab title="Node.js">

```typescript
const eventWorker = new Worker("world-sync", async (job) => {
  if (job.name !== "coordinate-world-event") return;

  const failedChildren = await job.getFailedChildrenValues();

  if (Object.keys(failedChildren).length > 0) {
    // Cancel remaining zones
    await job.removeUnprocessedChildren();
    throw new Error("Partial world sync — remaining zones canceled");
  }

  // Remove a specific redundant dependency
  await job.removeDependency("world-sync:redundant_zone_job_id");

  const results = await job.getChildrenValues();
  return { synced_zones: Object.keys(results).length };
}, { connection });
```

> **Benefit**: `job.remove()` cleans up all associated Redis keys in one atomic operation.

</tab>
</tabs>

---

## 19.6. Flow Tree Traversal

You can retrieve the complete flow structure from any job in the tree. This returns a recursive tree of jobs and their children, useful for monitoring dashboards and debugging complex flows.

<tabs>
<tab title="Elixir">

```elixir
# Retrieve the full flow tree from the parent job
{:ok, tree} = EchoMQ.Job.get_flow_tree(job)

# Returns a nested structure:
# %{
#   job: %EchoMQ.Job{name: "finalize-match", ...},
#   children: [
#     %{
#       job: %EchoMQ.Job{name: "calculate-player-xp", ...},
#       children: []
#     },
#     %{
#       job: %EchoMQ.Job{name: "calculate-player-xp", ...},
#       children: []
#     }
#   ]
# }

# Walk the tree to build a status report
defp flow_status(node, depth \\ 0) do
  indent = String.duplicate("  ", depth)
  state = EchoMQ.Job.estimated_state(node.job)
  IO.puts("#{indent}#{node.job.name} [#{state}]")
  Enum.each(node.children, &flow_status(&1, depth + 1))
end
```

> **Benefit**: Flow trees compose naturally with OTP supervision — parent failure propagates to children.

</tab>
<tab title="Go">

```go
// Feature: Flow Tree Traversal (getFlowTree)
//
// Not yet implemented in echomq-go. BullMQ's getFlowTree() reads
// parent-child relationships from Redis to reconstruct the full
// dependency tree. Each node contains the Job struct and a list of
// child nodes, allowing recursive traversal.
//
// Workaround:
//   Build the tree manually from job metadata:
//   1. Start from the root job's ID
//   2. Read parentKey from each job hash: HGET bull:{queue}:<id> parentKey
//   3. Find children by scanning: SMEMBERS bull:{queue}:<id>:dependencies
//   4. Recursively fetch each child's job data and dependencies
//
// Note: This workaround requires multiple Redis round-trips.
//   For dashboards, consider caching the tree structure in
//   application memory and updating it via queue event subscriptions.
//
// Reference: Ch 18 Flows Overview — Nested flows and bulk addition
```

> **Tradeoff**: No built-in admin UI — JSON endpoints require a separate frontend or Grafana for visualization.

</tab>
<tab title="Node.js">

```typescript
// Retrieve the full flow tree
const tree = await job.getFlowTree();

// tree structure:
// {
//   job: Job { name: "finalize-match", ... },
//   children: [
//     { job: Job { name: "calculate-player-xp", ... }, children: [] },
//     { job: Job { name: "calculate-player-xp", ... }, children: [] },
//   ]
// }

// Recursive status logger
function logFlowStatus(node: any, depth = 0) {
  const indent = "  ".repeat(depth);
  const state = node.job.failedReason ? "failed"
    : node.job.finishedOn ? "completed"
    : node.job.processedOn ? "active"
    : "waiting";
  console.log(`${indent}${node.job.name} [${state}]`);
  for (const child of node.children) {
    logFlowStatus(child, depth + 1);
  }
}

logFlowStatus(tree);
```

> **Benefit**: Repeatable job API matches BullMQ — `every` and `pattern` (cron) options available.

</tab>
</tabs>

---

## 19.7. Bulk Flow Addition

When multiple independent flows need to be created at once (e.g., processing all matches in a tournament round), `add_bulk` adds them in a single atomic transaction.

<tabs>
<tab title="Elixir">

```elixir
# Tournament round: create flows for all quarterfinal matches at once
matches = [
  {"MTH2dU8vX0zB3J", "PLR0K48QjihpC4", "PLR3QR5T7V9W2X"},
  {"MTH6eV9wY1aC4K", "PLR5M2vuIULYab", "PLR5w8p1qM2tT4"},
  {"MTH7fW0xZ2bD5L", "PLR7r4q9rN3uU5", "PLR3t6u2sP4vV6"},
  {"MTH8gX1yA3cE6M", "PLR1v8w5tQ5wW7", "PLR6x2y8uR6xX8"}
]

flows = Enum.map(matches, fn {match_id, player_a, player_b} ->
  %{
    name: "finalize-match",
    queue_name: "matchmaking",
    data: %{match_id: match_id, round: "quarterfinal"},
    children: [
      %{name: "calculate-player-xp", queue_name: "player-events",
        data: %{player_id: player_a, match_ref: match_id}},
      %{name: "calculate-player-xp", queue_name: "player-events",
        data: %{player_id: player_b, match_ref: match_id}}
    ]
  }
end)

# All 4 flows (12 jobs total) added atomically
{:ok, results} = EchoMQ.FlowProducer.add_bulk(flows, connection: :redis)
```

> **Benefit**: Flow trees compose naturally with OTP supervision — parent failure propagates to children.

</tab>
<tab title="Go">

```go
// Feature: Bulk Flow Addition (FlowProducer.addBulk)
//
// Not yet implemented in echomq-go. BullMQ's FlowProducer.addBulk()
// creates multiple independent flow trees in a single Redis
// MULTI/EXEC transaction. Either all flows are created or none.
//
// Workaround:
//   Add flows sequentially using the manual dependency pattern.
//   Each match gets its own set of child jobs + counter:
//
//   for _, match := range matches {
//       for _, player := range match.Players {
//           queue.Add(ctx, "calculate-player-xp",
//               map[string]interface{}{
//                   "player_id": player.ID,
//                   "match_ref": match.ID,
//               }, echomq.JobOptions{})
//       }
//   }
//
// Note: Sequential adds are NOT atomic. Some matches may be created
//   while others fail. Use Redis transactions (MULTI/EXEC) manually
//   if atomicity across all matches is required.
//
// Reference: Ch 18 Flows Overview — Bulk flow addition
```

> **Tradeoff**: Enqueue happens after `tx.Commit()` — a crash between commit and enqueue requires recovery.

</tab>
<tab title="Node.js">

```typescript
const flowProducer = new FlowProducer({ connection });

const matches = [
  { id: "MTH2dU8vX0zB3J", players: ["PLR0K48QjihpC4", "PLR3QR5T7V9W2X"] },
  { id: "MTH6eV9wY1aC4K", players: ["PLR5M2vuIULYab", "PLR5w8p1qM2tT4"] },
  { id: "MTH7fW0xZ2bD5L", players: ["PLR7r4q9rN3uU5", "PLR3t6u2sP4vV6"] },
  { id: "MTH8gX1yA3cE6M", players: ["PLR1v8w5tQ5wW7", "PLR6x2y8uR6xX8"] },
];

const flows = matches.map((match) => ({
  name: "finalize-match",
  queueName: "matchmaking",
  data: { match_id: match.id, round: "quarterfinal" },
  children: match.players.map((playerId) => ({
    name: "calculate-player-xp",
    queueName: "player-events",
    data: { player_id: playerId, match_ref: match.id },
  })),
}));

// All 4 flows (12 jobs total) added atomically
const results = await flowProducer.addBulk(flows);
```

> **Benefit**: FlowProducer class provides the reference implementation for complex job DAGs.

</tab>
</tabs>

---

## 19.8. Deep Nesting: Grandchildren

Flows support arbitrary depth. Children can have their own children, creating multi-level dependency chains. Each level waits for its direct children before processing.

<tabs>
<tab title="Elixir">

```elixir
# Crafting chain: craft-legendary waits for gather + smelt + enchant
# smelt waits for gather (sequential dependency via nesting)
{:ok, flow} = EchoMQ.FlowProducer.add(%{
  name: "craft-legendary",
  queue_name: "inventory",
  data: %{
    item_id: "ITM4bR7zT9vV5O",
    player_id: "PLR0K48QjihpC4",
    recipe: "legendary_sword_01"
  },
  children: [
    %{
      name: "enchant-weapon",
      queue_name: "inventory",
      data: %{enchantment: "dragonbane", power_level: 5}
    },
    %{
      name: "smelt-ingots",
      queue_name: "inventory",
      data: %{material: "dragon_steel", quantity: 3},
      children: [
        %{
          name: "gather-ore",
          queue_name: "player-events",
          data: %{ore_type: "dragon_ore", zone: "volcanic-forge", quantity: 9}
        },
        %{
          name: "gather-flux",
          queue_name: "player-events",
          data: %{material: "star_flux", zone: "crystal-caves", quantity: 2}
        }
      ]
    }
  ]
}, connection: :redis)

# Execution order:
# 1. gather-ore + gather-flux run in parallel (leaf nodes)
# 2. smelt-ingots runs after both gathering jobs complete
# 3. enchant-weapon runs independently (parallel with gathering/smelting)
# 4. craft-legendary runs after BOTH smelt-ingots AND enchant-weapon complete
```

```
gather-ore ────┐
               ├──▶ smelt-ingots ──┐
gather-flux ───┘                   ├──▶ craft-legendary
                                   │
enchant-weapon ────────────────────┘
```

> **Benefit**: Flow trees compose naturally with OTP supervision — parent failure propagates to children.

</tab>
<tab title="Go">

```go
// Feature: Deep Nesting / Grandchildren
//
// Not yet implemented in echomq-go. BullMQ flows support arbitrary
// nesting depth. Each level's parent enters waiting-children until
// its direct children complete. A grandchild completing triggers its
// immediate parent, which in turn may unblock the grandparent.
//
// Workaround:
//   Chain manual dependency tracking across levels:
//   1. Add leaf jobs (gather-ore, gather-flux) first
//   2. Each leaf's completion handler decrements a per-parent counter
//   3. When smelt-ingots' counter reaches 0, add smelt-ingots job
//   4. smelt-ingots' completion decrements craft-legendary's counter
//   5. When craft-legendary's counter reaches 0, add craft-legendary
//
// Example (leaf level):
//   queue := echomq.NewQueue("player-events", rdb)
//   queue.Add(ctx, "gather-ore",
//       map[string]interface{}{
//           "ore_type":    "dragon_ore",
//           "zone":        "volcanic-forge",
//           "quantity":    9,
//           "parent_ref":  "smelt-ingots",
//           "root_ref":    "ITM4bR7zT9vV5O",
//       }, echomq.JobOptions{})
//
// Reference: PROTOCOL-GAPS.md — GAP-006 (moveToFinished resolves
//   parent deps recursively up the tree)
```

> **Benefit**: Context-based parent-child linking enables deadline propagation through the flow.

</tab>
<tab title="Node.js">

```typescript
const flowProducer = new FlowProducer({ connection });

await flowProducer.add({
  name: "craft-legendary",
  queueName: "inventory",
  data: {
    item_id: "ITM4bR7zT9vV5O",
    player_id: "PLR0K48QjihpC4",
    recipe: "legendary_sword_01",
  },
  children: [
    {
      name: "enchant-weapon",
      queueName: "inventory",
      data: { enchantment: "dragonbane", power_level: 5 },
    },
    {
      name: "smelt-ingots",
      queueName: "inventory",
      data: { material: "dragon_steel", quantity: 3 },
      children: [
        {
          name: "gather-ore",
          queueName: "player-events",
          data: { ore_type: "dragon_ore", zone: "volcanic-forge", quantity: 9 },
        },
        {
          name: "gather-flux",
          queueName: "player-events",
          data: { material: "star_flux", zone: "crystal-caves", quantity: 2 },
        },
      ],
    },
  ],
});

// Execution order:
// 1. gather-ore + gather-flux (parallel)
// 2. smelt-ingots (after both gathers)
// 3. enchant-weapon (independent, parallel with smelting)
// 4. craft-legendary (after smelt-ingots AND enchant-weapon)
```

> **Benefit**: FlowProducer class provides the reference implementation for complex job DAGs.

</tab>
</tabs>

---

## 19.9. Cross-Language Compatibility

Parent-child flows are fully interoperable between Elixir and Node.js. A flow created by one runtime can be processed by workers in the other. The Redis data structures are identical.

| Capability | Elixir | Go | Node.js |
|------------|--------|-----|---------|
| Create flows (FlowProducer) | Full | Not implemented | Full |
| waiting-children state | Full | Not implemented | Full |
| getChildrenValues | Full | Not implemented | Full |
| getDependencies | Full | Not implemented | Full |
| fail_parent_on_failure | Full | Not implemented | Full |
| ignore_dependency_on_failure | Full | Not implemented | Full |
| continue_parent_on_failure | Full | Not implemented | Full |
| getFlowTree | Full | Not implemented | Full |
| Deep nesting (grandchildren) | Full | Not implemented | Full |
| Process child jobs | Full | Full | Full |

Go workers **can process child jobs** that were created by Elixir or Node.js FlowProducers. The child job itself is a standard job in a standard queue. However, Go's `moveToFinished` gap (GAP-006) means that when a Go worker completes a child, the parent's dependency counter is not atomically decremented. Until GAP-006 is resolved, avoid using Go workers for child jobs within flows.

### Recommended Deployment Pattern

```
Elixir/Node.js FlowProducer ──▶ Creates flow tree atomically
                                      │
            ┌─────────────────────────┼─────────────────────────┐
            ▼                         ▼                         ▼
   Elixir Worker              Elixir Worker              Elixir Worker
   (child queue 1)            (child queue 2)            (parent queue)
                                                               │
                                                               ▼
                                                    Aggregates child results
                                                    Returns final value
```

For mixed-language deployments, use Elixir or Node.js workers for flow-participating jobs and reserve Go workers for standalone queues that do not participate in parent-child dependencies.

---

## 19.10. What's Next

- [Flows Overview](ch18-flows-overview.md) -- Flow structure, FlowProducer, and atomic operations
- [Job Schedulers](ch20-job-schedulers.md) -- Recurring jobs with cron expressions and intervals
- [Job Options](ch14-job-options.md) -- Priority, delay, retries, backoff, and cleanup

---

*Previous: [Flows Overview](ch18-flows-overview.md) | Next: [Job Schedulers](ch20-job-schedulers.md)*
