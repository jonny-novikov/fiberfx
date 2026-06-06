# Chapter 18. Flows Overview

A flow is a tree of jobs with parent-child dependencies. Parent jobs **wait for all their children** to complete before running, children can have their own children (nested flows), and the entire hierarchy is added to Redis atomically. Flows replace manual job coordination with declarative dependency trees -- instead of chaining callbacks and tracking completion counters, you describe the shape of the work and EchoMQ handles the execution order.

In Fireheadz Arena, flows model naturally hierarchical operations: a game session that must process results, update leaderboards, and notify players before marking the session complete; a tournament bracket where each round depends on the previous round's matches finishing; or a crafting pipeline where raw materials must be gathered and smelted before an enchantment can be applied.

## 18.1. Flow Structure

A flow is defined as a tree where each node has a **name** (routing key), a **queue_name** (target queue), optional **data** and **opts**, and optional **children**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Job type identifier (routing key for workers) |
| `queue_name` | string | Yes | Queue to add the job to |
| `data` | map | No | Payload for the job (default: `%{}`) |
| `opts` | map | No | Job options (priority, attempts, backoff, etc.) |
| `children` | list | No | Child jobs that must complete before this job runs |

```
                    ┌─────────────────────┐
                    │  session-complete    │  ← Parent (runs LAST)
                    │  queue: analytics    │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
    ┌─────────┴──────┐ ┌──────┴────────┐ ┌─────┴──────────┐
    │ process-results│ │ update-boards │ │ notify-players │  ← Children
    │ queue: combat  │ │ queue: leader │ │ queue: player  │    (run FIRST)
    └────────────────┘ └───────────────┘ └────────────────┘
```

The execution contract is simple: children run first (possibly in parallel), and the parent runs only after **all** children reach a terminal state (completed or failed).

## 18.2. FlowProducer API

The `FlowProducer` creates job flows atomically. It accepts a flow definition tree and returns a result tree with populated job IDs.

<tabs>
<tab title="Elixir">

```elixir
# Add a single flow — game session completion
{:ok, flow} = EchoMQ.FlowProducer.add(%{
  name: "session-complete",
  queue_name: "analytics",
  data: %{match_id: "MTH0K5M2vuIULY", mode: "ranked"},
  children: [
    %{
      name: "process-results",
      queue_name: "combat-actions",
      data: %{match_id: "MTH0K5M2vuIULY", players: ["PLR0K48QjihpC4", "PLR3QR5T7V9W2X"]}
    },
    %{
      name: "update-leaderboard",
      queue_name: "leaderboard",
      data: %{match_id: "MTH0K5M2vuIULY", season: "S12"}
    },
    %{
      name: "notify-players",
      queue_name: "player-events",
      data: %{match_id: "MTH0K5M2vuIULY", event: "match_ended"}
    }
  ]
}, connection: :redis)

# flow.job contains the parent Job struct
IO.puts("Session flow created: #{flow.job.id}")

# flow.children is a list of %{job: %Job{}, children: []}
Enum.each(flow.children, fn child ->
  IO.puts("  Child: #{child.job.name} (#{child.job.id})")
end)
```

`EchoMQ.FlowProducer.add/2` builds all Redis commands via `build_flow_commands/4`, then executes them in a single `MULTI/EXEC` transaction via `Scripts.execute_transaction/2`. Job IDs are generated with `crypto.strong_rand_bytes/1` (24-char hex) and populated into the result tree after the transaction succeeds.

> **Benefit**: `Ecto.Multi` composes the enqueue step into the database transaction — atomic commit or rollback.

</tab>
<tab title="Go">

```go
// Feature: FlowProducer (parent-child job trees)
//
// Not yet implemented in echomq-go. The BullMQ FlowProducer creates
// hierarchical job trees atomically using Redis MULTI/EXEC transactions.
// The Elixir implementation (EchoMQ.FlowProducer) supports arbitrary
// nesting depth, atomic bulk addition, and automatic parent-key wiring.
//
// Workaround:
//   Create jobs sequentially with manual dependency tracking:
//   1. Add child jobs first, collecting their IDs
//   2. Add parent job with child IDs stored in job data
//   3. Use a completion callback to check if all children finished
//
//   queue := echomq.NewQueue("combat-actions", rdb)
//   child1, _ := queue.Add(ctx, "process-results",
//       map[string]interface{}{"match_id": "MTH0K5M2vuIULY"}, echomq.JobOptions{})
//   child2, _ := queue.Add(ctx, "update-leaderboard",
//       map[string]interface{}{"match_id": "MTH0K5M2vuIULY"}, echomq.JobOptions{})
//   // Track children manually in parent data
//   queue.Add(ctx, "session-complete",
//       map[string]interface{}{
//           "match_id":  "MTH0K5M2vuIULY",
//           "child_ids": []string{child1.ID, child2.ID},
//       }, echomq.JobOptions{})
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table
```

> **Tradeoff**: Enqueue happens after `tx.Commit()` — a crash between commit and enqueue requires recovery.

</tab>
<tab title="Node.js">

```typescript
import { FlowProducer } from "bullmq";

const flowProducer = new FlowProducer({ connection });

// Add a single flow — game session completion
const flow = await flowProducer.add({
  name: "session-complete",
  queueName: "analytics",
  data: { match_id: "MTH0K5M2vuIULY", mode: "ranked" },
  children: [
    {
      name: "process-results",
      queueName: "combat-actions",
      data: { match_id: "MTH0K5M2vuIULY", players: ["PLR0K48QjihpC4", "PLR3QR5T7V9W2X"] },
    },
    {
      name: "update-leaderboard",
      queueName: "leaderboard",
      data: { match_id: "MTH0K5M2vuIULY", season: "S12" },
    },
    {
      name: "notify-players",
      queueName: "player-events",
      data: { match_id: "MTH0K5M2vuIULY", event: "match_ended" },
    },
  ],
});

console.log(`Session flow created: ${flow.job.id}`);
flow.children.forEach((child) => {
  console.log(`  Child: ${child.job.name} (${child.job.id})`);
});
```

> **Benefit**: FlowProducer class provides the reference implementation for complex job DAGs.

</tab>
</tabs>

> **⚠️ Go Gap**: FlowProducer (parent-child job tree creation) is not implemented. The entire flow subsystem is missing.
> **Proposed Solution**: Implement `FlowProducer.Add()` using the `addFlowJob` Lua script family. Build a recursive tree walker that creates leaf jobs first, then parents with `waitChildrenKey` references. Requires `moveToWaitingChildren` Lua script integration.

### Return Value

The return value mirrors the input tree structure, with each node containing a fully populated `Job` and its resolved children:

```
%{
  job: %EchoMQ.Job{id: "a1b2c3...", name: "session-complete", ...},
  children: [
    %{job: %EchoMQ.Job{id: "d4e5f6...", name: "process-results", ...}, children: []},
    %{job: %EchoMQ.Job{id: "g7h8i9...", name: "update-leaderboard", ...}, children: []},
    %{job: %EchoMQ.Job{id: "j0k1l2...", name: "notify-players", ...}, children: []}
  ]
}
```

---

## 18.3. Nested Flows

Children can have their own children, creating deep hierarchies. A crafting pipeline in Fireheadz Arena demonstrates three-level nesting: the final enchanted weapon depends on smelting, which depends on material gathering.

<tabs>
<tab title="Elixir">

```elixir
# Crafting pipeline: gather → smelt → enchant
{:ok, flow} = EchoMQ.FlowProducer.add(%{
  name: "enchant-weapon",
  queue_name: "inventory",
  data: %{
    player_id: "PLR0K48QjihpC4",
    weapon: "ITM3aQ6yS8uU4N",
    enchantment: "fire_aspect"
  },
  children: [
    %{
      name: "smelt-ore",
      queue_name: "inventory",
      data: %{recipe: "mythril_ingot", quantity: 3},
      children: [
        %{
          name: "gather-materials",
          queue_name: "world-sync",
          data: %{zone: "crystal-caves", resource: "mythril_ore", quantity: 9}
        },
        %{
          name: "gather-materials",
          queue_name: "world-sync",
          data: %{zone: "dungeon-7", resource: "fire_essence", quantity: 2}
        }
      ]
    },
    %{
      name: "check-enchanter-level",
      queue_name: "player-events",
      data: %{player_id: "PLR0K48QjihpC4", required_level: 50, skill: "enchanting"}
    }
  ]
}, connection: :redis)
```

**Execution order:**
1. `gather-materials` (mythril ore) and `gather-materials` (fire essence) run in parallel
2. When both complete, `smelt-ore` runs
3. `check-enchanter-level` runs independently (parallel with gathering/smelting)
4. When `smelt-ore` and `check-enchanter-level` both complete, `enchant-weapon` runs

> **Benefit**: Flow trees compose naturally with OTP supervision — parent failure propagates to children.

</tab>
<tab title="Go">

```go
// Feature: Nested FlowProducer (multi-level job trees)
//
// Not yet implemented in echomq-go. Nested flows allow children to
// have their own children, creating arbitrarily deep dependency trees.
// The Elixir FlowProducer handles this via recursive build_flow_commands/4,
// which walks the tree depth-first and collects all Redis commands.
//
// Workaround:
//   Build the tree bottom-up with sequential adds:
//   queue := echomq.NewQueue("world-sync", rdb)
//   invQueue := echomq.NewQueue("inventory", rdb)
//
//   // Level 3: leaf nodes (gather materials)
//   ore, _ := queue.Add(ctx, "gather-materials",
//       map[string]interface{}{"zone": "crystal-caves", "resource": "mythril_ore"},
//       echomq.JobOptions{})
//   essence, _ := queue.Add(ctx, "gather-materials",
//       map[string]interface{}{"zone": "dungeon-7", "resource": "fire_essence"},
//       echomq.JobOptions{})
//
//   // Level 2: depends on level 3
//   smelt, _ := invQueue.Add(ctx, "smelt-ore",
//       map[string]interface{}{
//           "recipe": "mythril_ingot",
//           "deps":   []string{ore.ID, essence.ID},
//       }, echomq.JobOptions{})
//
//   // Level 1: depends on level 2
//   invQueue.Add(ctx, "enchant-weapon",
//       map[string]interface{}{
//           "weapon":   "ITM3aQ6yS8uU4N",
//           "deps":     []string{smelt.ID},
//       }, echomq.JobOptions{})
//
// Note: This workaround is NOT atomic. If a mid-tree add fails,
// earlier jobs are already enqueued. Add rollback logic for
// production crafting pipelines.
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table
```

> **Benefit**: Context-based parent-child linking enables deadline propagation through the flow.

</tab>
<tab title="Node.js">

```typescript
const flowProducer = new FlowProducer({ connection });

// Crafting pipeline: gather → smelt → enchant
const flow = await flowProducer.add({
  name: "enchant-weapon",
  queueName: "inventory",
  data: {
    player_id: "PLR0K48QjihpC4",
    weapon: "ITM3aQ6yS8uU4N",
    enchantment: "fire_aspect",
  },
  children: [
    {
      name: "smelt-ore",
      queueName: "inventory",
      data: { recipe: "mythril_ingot", quantity: 3 },
      children: [
        {
          name: "gather-materials",
          queueName: "world-sync",
          data: { zone: "crystal-caves", resource: "mythril_ore", quantity: 9 },
        },
        {
          name: "gather-materials",
          queueName: "world-sync",
          data: { zone: "dungeon-7", resource: "fire_essence", quantity: 2 },
        },
      ],
    },
    {
      name: "check-enchanter-level",
      queueName: "player-events",
      data: { player_id: "PLR0K48QjihpC4", required_level: 50, skill: "enchanting" },
    },
  ],
});
```

> **Benefit**: FlowProducer class provides the reference implementation for complex job DAGs.

</tab>
</tabs>

---

## 18.4. Atomic Execution

All jobs in a flow are added atomically using Redis `MULTI/EXEC` transactions. Either every job in the tree is created, or none are. This prevents partial flows -- you will never have orphaned children without a parent, or a parent waiting for children that were never created.

<tabs>
<tab title="Elixir">

```elixir
# Tournament bracket — all matches added atomically
{:ok, flow} = EchoMQ.FlowProducer.add(%{
  name: "tournament-final",
  queue_name: "matchmaking",
  data: %{tournament_id: "TRN5cT7uW9yA1H", round: "final"},
  children: [
    %{
      name: "semifinal-match",
      queue_name: "matchmaking",
      data: %{match_id: "MTH8kL2mN4pQ6D", players: ["PLR0K48QjihpC4", "PLR3QR5T7V9W2X"]},
      opts: %{attempts: 3}
    },
    %{
      name: "semifinal-match",
      queue_name: "matchmaking",
      data: %{match_id: "MTH9aR3sU5wY7F", players: ["PLR6sL4qP8xS3N", "PLR7tM5rQ9yT4P"]},
      opts: %{attempts: 3}
    }
  ]
}, connection: :redis)

# Guarantees:
# - All 3 jobs exist, or none do
# - Parent-child relationships are always valid
# - No partial bracket state in Redis
```

The atomicity guarantee comes from `Scripts.execute_transaction/2`, which wraps all `EVALSHA` calls (one per job node) inside a single `MULTI/EXEC` block. If the Redis connection drops mid-transaction, `EXEC` never fires and no jobs are created.

> **Benefit**: `Ecto.Multi` composes the enqueue step into the database transaction — atomic commit or rollback.

</tab>
<tab title="Go">

```go
// Feature: Atomic flow addition (MULTI/EXEC transactions)
//
// Not yet implemented in echomq-go. The FlowProducer's atomicity
// guarantee ensures that all jobs in a flow tree are created together
// or not at all, using Redis MULTI/EXEC transactions.
//
// Without FlowProducer, Go's sequential queue.Add() calls are NOT
// atomic — if the third add fails, the first two jobs already exist
// in Redis. For tournament brackets where partial state is dangerous:
//
// Workaround:
//   Use Redis transactions manually via go-redis Pipeline:
//   pipe := rdb.TxPipeline()
//   // ... queue HSET + LPUSH commands for each job ...
//   _, err := pipe.Exec(ctx)
//   if err != nil {
//       // All commands rolled back — no partial state
//   }
//
//   This requires reimplementing the addJob Lua script logic in Go,
//   which is non-trivial. For most game scenarios, sequential adds
//   with error checking and cleanup are sufficient.
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table
```

> **Tradeoff**: Enqueue happens after `tx.Commit()` — a crash between commit and enqueue requires recovery.

</tab>
<tab title="Node.js">

```typescript
const flowProducer = new FlowProducer({ connection });

// Tournament bracket — all matches added atomically
const flow = await flowProducer.add({
  name: "tournament-final",
  queueName: "matchmaking",
  data: { tournament_id: "TRN5cT7uW9yA1H", round: "final" },
  children: [
    {
      name: "semifinal-match",
      queueName: "matchmaking",
      data: { match_id: "MTH8kL2mN4pQ6D", players: ["PLR0K48QjihpC4", "PLR3QR5T7V9W2X"] },
      opts: { attempts: 3 },
    },
    {
      name: "semifinal-match",
      queueName: "matchmaking",
      data: { match_id: "MTH9aR3sU5wY7F", players: ["PLR6sL4qP8xS3N", "PLR7tM5rQ9yT4P"] },
      opts: { attempts: 3 },
    },
  ],
});

// Guarantees:
// - All 3 jobs exist, or none do
// - Parent-child relationships are always valid
// - No partial bracket state in Redis
```

> **Benefit**: FlowProducer class provides the reference implementation for complex job DAGs.

</tab>
</tabs>

---

## 18.5. Bulk Flow Addition

Add multiple independent flows in a single transaction. Each flow maintains its own parent-child hierarchy, but all flows are created atomically together. This is useful for batch operations like registering multiple tournament brackets simultaneously.

<tabs>
<tab title="Elixir">

```elixir
# Register multiple tournament brackets at once
flows = [
  %{
    name: "bracket-alpha",
    queue_name: "matchmaking",
    data: %{bracket: "alpha", tier: "gold"},
    children: [
      %{name: "match", queue_name: "matchmaking",
        data: %{match_id: "MTH2dU8vX0zB3J", players: ["PLR0K48QjihpC4", "PLR3QR5T7V9W2X"]}},
      %{name: "match", queue_name: "matchmaking",
        data: %{match_id: "MTH6eV9wY1aC4K", players: ["PLR6sL4qP8xS3N", "PLR7tM5rQ9yT4P"]}}
    ]
  },
  %{
    name: "bracket-beta",
    queue_name: "matchmaking",
    data: %{bracket: "beta", tier: "silver"},
    children: [
      %{name: "match", queue_name: "matchmaking",
        data: %{match_id: "MTH7fW0xZ2bD5L", players: ["PLR8uN6sR0zU5Q", "PLR9vP7tS1AU6R"]}},
      %{name: "match", queue_name: "matchmaking",
        data: %{match_id: "MTH8gX1yA3cE6M", players: ["PLR0wQ8uT2BV7S", "PLR1xR9vU3CW8T"]}}
    ]
  }
]

# All 6 jobs (2 parents + 4 children) added atomically
{:ok, results} = EchoMQ.FlowProducer.add_bulk(flows, connection: :redis)

Enum.each(results, fn result ->
  IO.puts("Bracket #{result.job.data["bracket"]}: #{length(result.children)} matches")
end)
```

`add_bulk/2` collects commands from all flows via `build_flow_commands/4` for each tree, concatenates them, and executes the combined command list in a single `MULTI/EXEC` transaction. This is more efficient than calling `add/2` in a loop because it requires only one round-trip to Redis.

> **Benefit**: `Ecto.Multi` composes the enqueue step into the database transaction — atomic commit or rollback.

</tab>
<tab title="Go">

```go
// Feature: Bulk FlowProducer (multiple flow trees in one transaction)
//
// Not yet implemented in echomq-go. The BullMQ FlowProducer.addBulk()
// and EchoMQ.FlowProducer.add_bulk/2 create multiple independent flow
// trees in a single Redis MULTI/EXEC transaction.
//
// Workaround:
//   Use a goroutine pool to add flows concurrently (not atomic):
//   brackets := []BracketConfig{
//       {Name: "alpha", Matches: []string{"MTH2dU8vX0zB3J", "MTH6eV9wY1aC4K"}},
//       {Name: "beta", Matches: []string{"MTH7fW0xZ2bD5L", "MTH8gX1yA3cE6M"}},
//   }
//
//   var wg sync.WaitGroup
//   for _, b := range brackets {
//       wg.Add(1)
//       go func(bracket BracketConfig) {
//           defer wg.Done()
//           for _, matchID := range bracket.Matches {
//               queue.Add(ctx, "match",
//                   map[string]interface{}{"match_id": matchID},
//                   echomq.JobOptions{})
//           }
//       }(b)
//   }
//   wg.Wait()
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table
```

> **Tradeoff**: Enqueue happens after `tx.Commit()` — a crash between commit and enqueue requires recovery.

</tab>
<tab title="Node.js">

```typescript
const flowProducer = new FlowProducer({ connection });

// Register multiple tournament brackets at once
const results = await flowProducer.addBulk([
  {
    name: "bracket-alpha",
    queueName: "matchmaking",
    data: { bracket: "alpha", tier: "gold" },
    children: [
      { name: "match", queueName: "matchmaking",
        data: { match_id: "MTH2dU8vX0zB3J", players: ["PLR0K48QjihpC4", "PLR3QR5T7V9W2X"] } },
      { name: "match", queueName: "matchmaking",
        data: { match_id: "MTH6eV9wY1aC4K", players: ["PLR6sL4qP8xS3N", "PLR7tM5rQ9yT4P"] } },
    ],
  },
  {
    name: "bracket-beta",
    queueName: "matchmaking",
    data: { bracket: "beta", tier: "silver" },
    children: [
      { name: "match", queueName: "matchmaking",
        data: { match_id: "MTH7fW0xZ2bD5L", players: ["PLR8uN6sR0zU5Q", "PLR9vP7tS1AU6R"] } },
      { name: "match", queueName: "matchmaking",
        data: { match_id: "MTH8gX1yA3cE6M", players: ["PLR0wQ8uT2BV7S", "PLR1xR9vU3CW8T"] } },
    ],
  },
]);

results.forEach((result) => {
  console.log(`Bracket ${result.job.data.bracket}: ${result.children.length} matches`);
});
```

> **Benefit**: FlowProducer class provides the reference implementation for complex job DAGs.

</tab>
</tabs>

---

## 18.6. Accessing Child Results

When a parent job runs, it can access the return values of its completed children. This lets the parent aggregate results -- for example, a session-complete job can collect individual match statistics from its children.

<tabs>
<tab title="Elixir">

```elixir
# Worker for the parent "session-complete" queue
{:ok, _} = EchoMQ.Worker.start_link(
  queue: "analytics",
  connection: :redis,
  processor: fn job ->
    # Get return values from all completed children
    {:ok, children_values} = EchoMQ.Job.get_children_values(job)
    # children_values is a map: %{"child_job_id" => return_value, ...}

    total_damage = children_values
      |> Map.values()
      |> Enum.filter(&is_map/1)
      |> Enum.reduce(0, fn val, acc -> acc + Map.get(val, "damage_dealt", 0) end)

    # Get any dependencies still pending (should be empty for parent)
    {:ok, deps} = EchoMQ.Job.get_dependencies(job)

    {:ok, %{
      match_id: job.data["match_id"],
      total_damage: total_damage,
      children_processed: map_size(children_values)
    }}
  end
)

# Workers for each child queue
{:ok, _} = EchoMQ.Worker.start_link(
  queue: "combat-actions",
  connection: :redis,
  processor: fn job ->
    stats = Fireheadz.Combat.process_results(job.data["match_id"])
    {:ok, %{damage_dealt: stats.total_damage, kills: stats.kills}}
  end
)
```

`EchoMQ.Job.get_children_values/1` reads from the `bull:{queue}:{id}:dependencies` Redis key, which is populated by the child completion Lua scripts. The values are the `returnvalue` field each child wrote on completion.

> **Benefit**: Named connections via `Redix` integrate into supervision trees — automatic reconnect on network partitions.

</tab>
<tab title="Go">

```go
// Feature: Accessing child results (get_children_values)
//
// Not yet implemented in echomq-go. When a parent job's worker runs,
// BullMQ provides access to all children's return values via the
// parent job's dependencies key in Redis.
//
// How it works internally:
//   When a child job completes, the moveToFinished Lua script writes
//   the child's returnvalue to the parent's dependencies hash:
//     HSET bull:{parent_queue}:{parent_id}:dependencies {child_id} {returnvalue}
//   When all children complete, the parent moves from waiting-children
//   to the waiting state.
//
// Workaround:
//   If using the manual dependency tracking pattern (see FlowProducer
//   gap above), read child results directly from Redis:
//   for _, childID := range childIDs {
//       jobData, _ := rdb.HGetAll(ctx, fmt.Sprintf("bull:%s:%s", queueName, childID)).Result()
//       returnVal := jobData["returnvalue"]
//       // Parse and aggregate
//   }
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table
```

> **Benefit**: Context-based parent-child linking enables deadline propagation through the flow.

</tab>
<tab title="Node.js">

```typescript
import { Worker } from "bullmq";

// Worker for the parent "session-complete" queue
const analyticsWorker = new Worker("analytics", async (job) => {
  // Get return values from all completed children
  const childrenValues = await job.getChildrenValues();
  // childrenValues is an object: { "bull:combat-actions:123": {...}, ... }

  let totalDamage = 0;
  for (const val of Object.values(childrenValues)) {
    if (val && typeof val === "object" && "damage_dealt" in val) {
      totalDamage += (val as any).damage_dealt;
    }
  }

  return {
    match_id: job.data.match_id,
    total_damage: totalDamage,
    children_processed: Object.keys(childrenValues).length,
  };
}, { connection });

// Worker for each child queue
const combatWorker = new Worker("combat-actions", async (job) => {
  const stats = await processResults(job.data.match_id);
  return { damage_dealt: stats.totalDamage, kills: stats.kills };
}, { connection });
```

> **Benefit**: `ioredis` connection with lazy initialization — Redis connects only when the first command is issued.

</tab>
</tabs>

---

## 18.7. Getting Flow Tree State

You can retrieve the full state of a flow tree to inspect which jobs have completed, which are still running, and which are waiting. This is useful for building progress dashboards or debugging stuck flows.

<tabs>
<tab title="Elixir">

```elixir
# After creating a flow, inspect its state
{:ok, flow} = EchoMQ.FlowProducer.add(%{
  name: "session-complete",
  queue_name: "analytics",
  data: %{match_id: "MTH4bS6tV8xZ0G"},
  children: [
    %{name: "process-results", queue_name: "combat-actions",
      data: %{match_id: "MTH4bS6tV8xZ0G"}},
    %{name: "update-leaderboard", queue_name: "leaderboard",
      data: %{match_id: "MTH4bS6tV8xZ0G"}}
  ]
}, connection: :redis)

# Check parent state — should be "waiting-children"
{:ok, parent_state} = EchoMQ.Queue.get_job_state(
  "analytics", flow.job.id, connection: :redis)
IO.puts("Parent: #{parent_state}")
# => "waiting-children"

# Check each child's state
Enum.each(flow.children, fn child ->
  {:ok, state} = EchoMQ.Queue.get_job_state(
    child.job.queue_name, child.job.id, connection: :redis)
  IO.puts("  #{child.job.name}: #{state}")
end)
# => "process-results: waiting"
# => "update-leaderboard: waiting"
```

> **Benefit**: Flow trees compose naturally with OTP supervision — parent failure propagates to children.

</tab>
<tab title="Go">

```go
// Feature: Flow tree state inspection
//
// Not yet implemented as a single API in echomq-go. Since Go lacks
// FlowProducer, there is no built-in flow tree traversal. However,
// individual job states can be checked if you have the job IDs.
//
// Workaround:
//   If you tracked job IDs during manual creation:
//   queue := echomq.NewQueue("analytics", rdb)
//   state, _ := queue.GetJobState(ctx, parentJobID)
//   fmt.Printf("Parent: %s\n", state)
//
//   for _, childID := range childIDs {
//       childState, _ := queue.GetJobState(ctx, childID)
//       fmt.Printf("  Child %s: %s\n", childID, childState)
//   }
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table
```

> **Benefit**: Context-based parent-child linking enables deadline propagation through the flow.

</tab>
<tab title="Node.js">

```typescript
const flowProducer = new FlowProducer({ connection });

const flow = await flowProducer.add({
  name: "session-complete",
  queueName: "analytics",
  data: { match_id: "MTH4bS6tV8xZ0G" },
  children: [
    { name: "process-results", queueName: "combat-actions",
      data: { match_id: "MTH4bS6tV8xZ0G" } },
    { name: "update-leaderboard", queueName: "leaderboard",
      data: { match_id: "MTH4bS6tV8xZ0G" } },
  ],
});

// Get the full flow tree with current state
const tree = await flow.job.getFlow();
// tree contains the parent job and all children with their current states

// Or check individual job states
const parentState = await flow.job.getState();
console.log(`Parent: ${parentState}`);
// => "waiting-children"

for (const child of flow.children) {
  const state = await child.job.getState();
  console.log(`  ${child.job.name}: ${state}`);
}
// => "process-results: waiting"
// => "update-leaderboard: waiting"
```

> **Benefit**: FlowProducer class provides the reference implementation for complex job DAGs.

</tab>
</tabs>

---

## 18.8. Removing Flows

Removing a flow removes the parent job and all its descendants. This is useful for cancelling an entire operation tree -- for example, cancelling a tournament bracket removes all pending matches.

<tabs>
<tab title="Elixir">

```elixir
# Remove individual jobs in the flow (bottom-up for clean teardown)
# Remove children first, then parent
Enum.each(flow.children, fn child ->
  EchoMQ.Queue.remove("matchmaking", child.job.id, connection: :redis)
end)
EchoMQ.Queue.remove("matchmaking", flow.job.id, connection: :redis)

# For a simpler approach, remove just the parent — children become orphans
# that workers will process normally (they lose their parent dependency)
EchoMQ.Queue.remove("matchmaking", flow.job.id, connection: :redis)
```

When removing flows, consider the execution state. Removing a parent while children are still active means the children will complete but their results will not be aggregated. Removing active children causes the parent to wait indefinitely (it never transitions from `waiting-children` to `waiting`).

> **Benefit**: Flow trees compose naturally with OTP supervision — parent failure propagates to children.

</tab>
<tab title="Go">

```go
// Feature: Flow removal
//
// Since Go lacks FlowProducer, there is no flow-aware removal.
// Individual jobs can be removed if you tracked their IDs:
//
// Workaround:
//   queue := echomq.NewQueue("matchmaking", rdb)
//   // Remove children first (bottom-up)
//   for _, childID := range childIDs {
//       queue.Remove(ctx, childID)
//   }
//   // Then remove the parent
//   queue.Remove(ctx, parentID)
//
// Caution: Removing a parent while children are active leaves
// children as orphans. Removing children while parent waits
// causes the parent to stall in waiting-children state.
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table
```

> **Benefit**: Context-based parent-child linking enables deadline propagation through the flow.

</tab>
<tab title="Node.js">

```typescript
const flowProducer = new FlowProducer({ connection });

// Remove the entire flow tree (parent + all descendants)
await flowProducer.remove(flow.job.id);

// Or remove individual jobs
const queue = new Queue("matchmaking", { connection });
for (const child of flow.children) {
  await queue.remove(child.job.id);
}
await queue.remove(flow.job.id);
```

> **Benefit**: FlowProducer class provides the reference implementation for complex job DAGs.

</tab>
</tabs>

---

## 18.9. Error Handling in Flows

By default, if a child job fails, the parent also fails. This cascading failure behavior ensures that a session-complete job does not run with incomplete data. You can control this with two options:

| Option | Default | Description |
|--------|---------|-------------|
| `fail_parent_on_failure` | `true` | If `false`, parent proceeds even if children fail |
| `ignore_dependency_on_failure` | `false` | If `true`, failed children are ignored and parent runs |

<tabs>
<tab title="Elixir">

```elixir
# Strict mode (default) — parent fails if any child fails
{:ok, strict_flow} = EchoMQ.FlowProducer.add(%{
  name: "tournament-final",
  queue_name: "matchmaking",
  data: %{tournament_id: "TRN5cT7uW9yA1H"},
  children: [
    %{name: "semifinal", queue_name: "matchmaking",
      data: %{match_id: "MTH8kL2mN4pQ6D"}, opts: %{attempts: 3}},
    %{name: "semifinal", queue_name: "matchmaking",
      data: %{match_id: "MTH9aR3sU5wY7F"}, opts: %{attempts: 3}}
  ]
}, connection: :redis)
# If either semifinal fails after 3 retries, the final is also marked failed

# Lenient mode — parent runs regardless of child failures
{:ok, lenient_flow} = EchoMQ.FlowProducer.add(%{
  name: "daily-analytics",
  queue_name: "analytics",
  data: %{date: Date.utc_today()},
  children: [
    %{name: "collect-combat-stats", queue_name: "analytics",
      data: %{source: "combat"},
      opts: %{fail_parent_on_failure: false}},
    %{name: "collect-trade-stats", queue_name: "analytics",
      data: %{source: "trades"},
      opts: %{fail_parent_on_failure: false}},
    %{name: "collect-chat-stats", queue_name: "analytics",
      data: %{source: "chat"},
      opts: %{ignore_dependency_on_failure: true}}
  ]
}, connection: :redis)
# Parent runs even if some stat collectors fail — partial analytics are
# better than no analytics. Use get_ignored_children_failures/1 in the
# parent worker to check which children failed.
```

> **Benefit**: Flow trees compose naturally with OTP supervision — parent failure propagates to children.

</tab>
<tab title="Go">

```go
// Feature: Flow error handling options
//
// Not yet implemented in echomq-go. BullMQ's FlowProducer supports
// two failure control options on child job opts:
//
//   fail_parent_on_failure (default: true)
//     When false, the parent job proceeds even if this child fails.
//     Useful for analytics pipelines where partial data is acceptable.
//
//   ignore_dependency_on_failure (default: false)
//     When true, a failed child is removed from the parent's
//     dependency list entirely. The parent runs as if the child
//     never existed.
//
// Workaround:
//   In the manual dependency pattern, handle failures in the parent
//   worker by checking each child's state before aggregating:
//   for _, childID := range childIDs {
//       state, _ := queue.GetJobState(ctx, childID)
//       if state == "failed" {
//           log.Printf("Child %s failed, skipping", childID)
//           continue
//       }
//       // ... aggregate results ...
//   }
//
// Reference: Ch 17 Worker Patterns — Protocol Gap Summary Table
```

> **Benefit**: Context-based parent-child linking enables deadline propagation through the flow.

</tab>
<tab title="Node.js">

```typescript
const flowProducer = new FlowProducer({ connection });

// Strict mode (default) — parent fails if any child fails
await flowProducer.add({
  name: "tournament-final",
  queueName: "matchmaking",
  data: { tournament_id: "TRN5cT7uW9yA1H" },
  children: [
    { name: "semifinal", queueName: "matchmaking",
      data: { match_id: "MTH8kL2mN4pQ6D" }, opts: { attempts: 3 } },
    { name: "semifinal", queueName: "matchmaking",
      data: { match_id: "MTH9aR3sU5wY7F" }, opts: { attempts: 3 } },
  ],
});

// Lenient mode — parent runs regardless of child failures
await flowProducer.add({
  name: "daily-analytics",
  queueName: "analytics",
  data: { date: new Date().toISOString().split("T")[0] },
  children: [
    { name: "collect-combat-stats", queueName: "analytics",
      data: { source: "combat" },
      opts: { failParentOnFailure: false } },
    { name: "collect-trade-stats", queueName: "analytics",
      data: { source: "trades" },
      opts: { failParentOnFailure: false } },
    { name: "collect-chat-stats", queueName: "analytics",
      data: { source: "chat" },
      opts: { ignoreDependencyOnFailure: true } },
  ],
});
```

> **Benefit**: FlowProducer class provides the reference implementation for complex job DAGs.

</tab>
</tabs>

---

## 18.10. Cross-Language Compatibility

Flows created in one language are fully processable by workers in another language. The flow structure is stored in Redis using the same key patterns across all runtimes:

| Redis Key | Purpose |
|-----------|---------|
| `bull:{queue}:{id}` | Job hash (data, opts, state) |
| `bull:{queue}:{id}:dependencies` | Child return values (hash) |
| `bull:{queue}:waiting-children` | Parents waiting for children (sorted set) |

A flow created by Elixir's `FlowProducer.add/2` produces the same Redis structure as Node.js's `FlowProducer.add()`. This means:

- An Elixir producer can create flows processed by Node.js workers
- A Node.js producer can create flows processed by Elixir workers
- Mixed environments (some queues handled by Elixir, others by Node.js) work seamlessly
- Go workers can process individual child jobs from flows created by Elixir or Node.js (they just cannot create the flow hierarchy themselves)

```
Elixir FlowProducer ──┐
                       ├──▶ Redis (bull:matchmaking:*)  ──▶ Elixir/Node.js/Go workers
Node.js FlowProducer ──┘
```

The key constraint is that all implementations must use the same Redis prefix (default: `"bull"`). The prefix is configurable via the `:prefix` option in Elixir and the `prefix` constructor option in Node.js.

---

## 18.11. Flow Limitations

| Limitation | Detail |
|------------|--------|
| **All children must complete** | Parent cannot run until every child reaches a terminal state |
| **No partial execution** | You cannot selectively run some children and skip others (use `ignore_dependency_on_failure` instead) |
| **Parent cannot cancel children** | Once children are enqueued, they run to completion or failure |
| **Maximum depth** | ~100 levels (practical Redis transaction size limit) |
| **Job IDs** | Flow job IDs should not contain colons (`:`) as they are used as Redis key separators |
| **Go support** | Go cannot create flows; it can only process individual jobs from flows created by Elixir or Node.js |

---

## 18.12. What's Next

- [Parent-Child Jobs](ch19-parent-child-jobs.md) -- Dependency management, failure propagation, and result aggregation
- [Job Lifecycle](ch13-job-lifecycle.md) -- State transitions including the `waiting-children` state
- [Worker Patterns](ch17-worker-patterns.md) -- Protocol gap summary and cross-language interop details

---

*Previous: [Worker Patterns](ch17-worker-patterns.md) | Next: [Parent-Child Jobs](ch19-parent-child-jobs.md)*
