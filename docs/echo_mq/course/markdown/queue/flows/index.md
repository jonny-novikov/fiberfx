# Flows — orchestration over the queue (module hub)

> Route: `/echomq/queue/flows` · surface: module hub · pillar: The Queue
> Grounding: **all real code** in `echo/apps/echo_mq` (`flows.ex`, `jobs.ex` fan-in hook, `keyspace.ex`). No `[RECONCILE]` markers — every surface verified on disk.

## Thesis

A flow is a **parent job and a flat list of children**. The children run; the parent runs only after
they finish. EchoMQ holds the parent out of `pending` with an outstanding-child counter, lands the
whole same-queue flow in **one atomic script**, and releases the parent on the **fan-in hook** the
instant the last child completes.

## The framing

Three facts carry the module:

1. **The parent is held, not pending.** A flow parent's row is written `state = awaiting_children`,
   and its outstanding-child count lives in a string counter at `<parent job key>:dependencies`. It is
   never in the pending set, so no worker can claim it while its children are still running.
2. **One atomic script lands a same-queue flow.** `EchoMQ.Flows.add/3` runs `@enqueue_flow` — one EVAL
   on one slot — that gates every id, writes each child claimable, holds the parent, and sets the
   counter to N. All of it lands, or none of it does.
3. **The fan-in releases the parent.** The release is not a separate process. It lives **inside the
   `@complete` script**: each completing flow child decrements `:dependencies`, records its result in
   `:processed`, and at zero adds the parent to `pending` and flips its row to `pending`.

## The script catalog (framing interactive)

Three scripts carry a flow. `EchoMQ.Flows @enqueue_flow` lands a same-queue flow atomically.
`EchoMQ.Flows @hold_parent` + `EchoMQ.Flows @enqueue_flow_child` land a cross-queue flow parent-first.
The fan-in is the single-queue branch already inside `EchoMQ.Jobs @complete`. Picking a verb reads its
declared keys and its transition — a pure lookup over a fixed dataset.

## The dives

- **Parent and children** (`parent-and-children`) — the shape and the atomic same-queue add. The parent
  held `awaiting_children` with `:dependencies = N`; the children claimable in pending; `@enqueue_flow`
  in two beats; the fan-in hook inside `@complete` that DECRs and at zero releases.
- **Reading the results** (`reading-the-results`) — the parent runs *on* its children's outcomes through
  three pure reads: `children_values/3` (HGETALL `:processed`), `dependencies/3` (GET `:dependencies`),
  `ignored_failures/3` (HGETALL `:unsuccessful`). All id-gated, no state change.
- **Cross-queue & the failure policy** (`cross-queue-and-failure-policy`) — a child on another slot makes
  the add host-orchestrated, non-atomic across slots, parent-first, fail-closed; its fan-in is
  eventually-consistent through the per-queue Pump sweep. The failure policy — fail-parent vs
  ignore-dependency — carried as the `parent_policy` token.

## Pattern & implementation (bridge)

- **The pattern (Redis Patterns Applied).** Flow control and orchestration — composing dependent work
  so a parent step waits on its legs — is **R6 · Flow control**. The near, resolvable door is
  **R3 · Reliable Queues** (`/redis-patterns/queues`): the reliable-queue lifecycle the flow composes.
- **The implementation (echo_mq).** `EchoMQ.Flows.add/3` lands the flow; the parent's `:dependencies`
  counter holds it; the fan-in branch inside `EchoMQ.Jobs @complete` releases it. Composition is a
  counter and one atomic script, not a coordinator.

## References

### Sources
- Valkey — SET (`https://valkey.io/commands/set/`) — the `:dependencies` outstanding-child counter the flow holds the parent with.
- Valkey — DECR (`https://valkey.io/commands/decr/`) — the fan-in decrement inside `@complete`.
- Redis — EVALSHA (`https://redis.io/commands/evalsha/`) — the load-once dispatch `@enqueue_flow` runs by.
- Valkey — Documentation (`https://valkey.io/docs/`) — the substrate of record EchoMQ is backed by.

### Related in this course
- `/echomq/queue` — The Queue, the chapter this module belongs to.
- `/echomq/queue/flows/parent-and-children` — the shape and the atomic same-queue add.
- `/echomq/queue/flows/reading-the-results` — the three pure reads the parent runs on.
- `/echomq/queue/flows/cross-queue-and-failure-policy` — cross-queue fan-in and the failure policy.
- `/echomq/protocol` — the keyspace and the Lua layer the flow scripts are built on.
- `/redis-patterns/queues` — the reliable-queue pattern, the near side of the door.
