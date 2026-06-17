defmodule EchoMQ.Flows do
  @moduledoc """
  Single-queue parent/child flows. A flow is a parent job and a flat list
  of children in the SAME queue: the children are enqueued claimable; the
  parent is held out of `pending` with its outstanding-child count in
  `emq:{q}:job:<parent>:dependencies` and its row `state = awaiting_children`,
  and it is released to `pending` only when the last child completes (the
  fan-in hook in `EchoMQ.Jobs.@complete`). One atomic `@enqueue_flow` lands
  the whole flow on one slot, so either it all lands or none of it does.

  The parent reference is carried as a `parent` DATA field on each child row
  (the bare parent branded id), read HOST-SIDE by `EchoMQ.Jobs.complete/4`
  to rebuild the parent's declared `:dependencies`/`:processed` keys -- the
  declared-keys law (S-6) governs the script's keys, so no key is ever read
  out of a hash field in Lua (the v1 `parent_key` form is not lifted). The
  flow keys compose with `<> ":dependencies"`/`<> ":processed"` the way
  `EchoMQ.Jobs.add_log/5` composes `<> ":logs"` (already-registered §6
  subkeys, no new key type). emq.3.1 (the flow family's first slice).

  The parent handler reads its children's outcomes through two PURE reads of
  those same declared subkeys -- `children_values/3` (the completed children's
  results over `:processed`, the v1 `get_children_values` capability) and
  `dependencies/3` (the outstanding-child count over `:dependencies`, the v1
  `get_dependencies` capability). Both ride the shipped connector
  (`HGETALL`/`GET`-class), gate the parent id at `Keyspace.job_key/2`, and
  effect no state change. emq.3.2 (the flow family's child-result reads).
  """

  alias EchoMQ.{Connector, Keyspace, Script}

  # emq.3.5-B3 (S-Bound . 8): the host caps a recursive flow's STRUCTURAL depth
  # at enqueue. A tree deeper than this (root at level 1) is rejected at the add
  # with a typed depth-limit error BEFORE any wire -- never silently truncated.
  # The bound is on enqueue-time depth (the fan-in chain length), not the
  # runtime job count (the per-queue mechanics already bound that). The Operator
  # may set another value (this is the recommended default).
  @max_tree_depth 8

  # The nested-tree result mirrors the input tree: each node carries its minted
  # id and its children's results, the recursive analogue of the flat
  # `{:ok, {parent_id, [child_id]}}`. emq.3.5-D2.
  @type tree_result :: {binary(), [tree_result()]}

  # One atomic transition on one slot (single-queue → fully atomic). The kind
  # law runs FIRST over the parent and every child id (a non-JOB id refuses
  # EMQKIND before any write). Declared keys:
  #   KEYS[1] = the parent row, KEYS[2] = the parent's :dependencies key,
  #   KEYS[3] = the queue pending set, KEYS[4..] = the child rows (each
  #   same-{q}, positionally paired with the (id, payload) ARGV below).
  # ARGV[1] = parent id, ARGV[2] = parent payload, ARGV[3] = the child count
  # N, then ARGV[4..] = (child id, child payload) pairs, one per KEYS[4..].
  @enqueue_flow Script.new(:enqueue_flow, """
                if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
                  return redis.error_reply('EMQKIND job id must be JOB-namespaced')
                end
                local n = tonumber(ARGV[3])
                for i = 1, n do
                  if string.sub(ARGV[2 + 2 * i], 1, 3) ~= 'JOB' then
                    return redis.error_reply('EMQKIND job id must be JOB-namespaced')
                  end
                end
                for i = 1, n do
                  local child = KEYS[3 + i]
                  local cid = ARGV[2 + 2 * i]
                  local cpayload = ARGV[3 + 2 * i]
                  redis.call('HSET', child, 'state', 'pending', 'attempts', '0', 'payload', cpayload, 'parent', ARGV[1])
                  redis.call('ZADD', KEYS[3], 0, cid)
                end
                redis.call('HSET', KEYS[1], 'state', 'awaiting_children', 'attempts', '0', 'payload', ARGV[2])
                redis.call('SET', KEYS[2], n)
                return n
                """)

  # The CROSS-QUEUE add (emq.3.3-D2) is host-orchestrated, NON-atomic across
  # slots: no single script spans the children's different slots (S-1/§6), so
  # the parent and each child land in SEPARATE one-slot EVALs. Parent-first is
  # the safe order -- the :dependencies counter exists on the parent's slot
  # before any child can complete + deliver, so no deliver ever races an absent
  # counter (B2). Two NEW additive scripts, each single-slot + declared-keys:
  #
  # @hold_parent (all on {P}): hold the parent out of pending with its total
  # child count. KEYS[1]=parent row, KEYS[2]=parent :dependencies; ARGV[1]=
  # parent id, ARGV[2]=payload, ARGV[3]=N (the TOTAL child count, same-queue +
  # cross-queue). The kind law runs FIRST. The parent is NOT added to pending
  # (held, state awaiting_children) -- the fan-in releases it.
  @hold_parent Script.new(:hold_parent, """
               if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
                 return redis.error_reply('EMQKIND job id must be JOB-namespaced')
               end
               redis.call('HSET', KEYS[1], 'state', 'awaiting_children', 'attempts', '0', 'payload', ARGV[2])
               redis.call('SET', KEYS[2], tonumber(ARGV[3]))
               return 1
               """)

  # @enqueue_flow_child (all on the CHILD's slot {C}): land one flow child
  # claimable on its own slot, its row carrying the `parent` id and -- for a
  # cross-queue child -- a `parent_queue` field (so its `@complete` knows which
  # outbox to emit to and the sweep knows which slot the parent is on).
  # KEYS[1]=child row, KEYS[2]=the child-queue pending set; ARGV[1]=child id,
  # ARGV[2]=payload, ARGV[3]=parent id, ARGV[4]=parent queue ('' for a
  # same-queue child -> no parent_queue field, the emq.3.1 byte-frozen fan-in
  # path). The kind law runs FIRST.
  #
  # The emq.3.4 `parent_policy` token is NOT written by this script (it stays
  # BYTE-FROZEN -- INV1's "no other Script.new/2 body changes"): the host writes
  # it with a plain HSET on the child row AFTER this EVAL (same slot {C}),
  # mirroring the same-queue add's host-HSET, so the ONLY shipped-script edit
  # emq.3.4 makes is @retry. parent_policy is a host-read DATA field (read
  # HOST-SIDE in `parent_fail_of/3`, passed to the @retry failure branch as a
  # declared policy ARGV -- never a data-rooted Lua key, S-6/INV2).
  @enqueue_flow_child Script.new(:enqueue_flow_child, """
                      if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
                        return redis.error_reply('EMQKIND job id must be JOB-namespaced')
                      end
                      if ARGV[4] ~= '' then
                        redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2], 'parent', ARGV[3], 'parent_queue', ARGV[4])
                      else
                        redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2], 'parent', ARGV[3])
                      end
                      redis.call('ZADD', KEYS[2], 0, ARGV[1])
                      return 1
                      """)

  @doc """
  Add a flow: a parent + a flat list of children. With every child in the
  SAME queue as `queue` the flow lands in one atomic `@enqueue_flow` (one
  slot). With ANY child in a DIFFERENT queue (a CROSS-queue child, the v1 flow
  shape -- a parent in `orders`, children in `validation`/`inventory`/
  `payments`) the add is host-orchestrated, NON-atomic across slots (emq.3.3):
  the parent lands FIRST (held, `state = awaiting_children`, `:dependencies` =
  N the TOTAL child count, on its slot), then each child lands on its own slot
  carrying `parent` and -- cross-queue -- `parent_queue`. A partial add (a
  child fails to land cross-slot) leaves the parent HELD (FAIL-CLOSED, never
  spuriously executed) -- the caller retries by id. The cross-queue fan-in is
  EVENTUALLY-CONSISTENT (the cross-queue child emits to its own-slot outbox on
  completion; the parent's per-queue sweep delivers the decrement on the next
  tick), never atomic across queues -- INV5/INV7. Same-queue children still fan
  in atomically through the byte-frozen `@complete` branch. emq.3.3-D2.

  The flow is `%{parent: spec, children: [spec]}`; a parent spec is
  `%{id: branded_id, payload: binary}`, a child spec the same plus an optional
  `:queue` (the queue the child runs in; defaulting to `queue` -- the parent's
  -- makes it a same-queue child). The id is host-minted by the caller.

  **All same-queue** (no child names a different `:queue`): the whole flow
  lands in one atomic `@enqueue_flow` (one slot) -- the children claimable
  immediately (in `pending`), the parent held out of `pending`
  (`state = awaiting_children`, `:dependencies` = N) until its children
  complete (the byte-frozen fan-in hook releases it). The emq.3.1 atomic add.

  **Any cross-queue child**: the add is host-orchestrated and NON-atomic across
  slots (emq.3.3 -- no single script spans the children's different slots,
  S-1/§6). The **parent lands FIRST** (held, `:dependencies` = N the total
  child count, on its slot), then each child lands on its own slot carrying
  `parent` and -- cross-queue -- `parent_queue`. **FAIL-CLOSED**: a partial add
  (a child fails to land) leaves the parent HELD -- never claimable, never
  spuriously executed -- the caller retries by id (parent-first guarantees the
  `:dependencies` counter exists before any child can complete). The
  cross-queue fan-in is **eventually-consistent** (a cross-queue child emits to
  its own-slot outbox on completion; the child-queue's `EchoMQ.Pump` sweep
  delivers the decrement on the parent's slot on the next tick), **never atomic
  across queues** (INV5/INV7).

  Each child may declare its FAILURE POLICY (emq.3.4): `fail_parent_on_failure`
  (the v1 default `true` -- a dead child fails the parent) or
  `ignore_dependency_on_failure` (`false` by default -- a dead child is treated
  as a satisfied dependency and the parent proceeds, the failure recorded in
  the parent's `:unsuccessful`). The policy is recorded as a `parent_policy`
  token on each child row (`'fp'` or `'id'`), read HOST-SIDE by
  `EchoMQ.Jobs.retry/7` to route the death -- never a data-rooted Lua key
  (S-6/INV2). A same-queue child carries it via a host `HSET` after the atomic
  `@enqueue_flow` (which stays byte-frozen); a cross-queue child carries it in
  `@enqueue_flow_child`'s ARGV. A child naming both flags `true` resolves to
  `ignore_dependency_on_failure` (the proceed policy is the explicit opt-in;
  the default is fail-parent).

  Every id (the parent and each child) is gated at `Keyspace.job_key/2`
  (raises on an ill-formed id -- INV4) BEFORE any wire. Returns
  `{:ok, {parent_id, [child_id]}}` on success (the child ids in spec order).
  emq.3.1-D2, extended emq.3.3-D2, extended emq.3.4-D2 (the failure policy).

  **A NESTED tree (grandchildren / arbitrary depth -- emq.3.5-D2, S3 . Arm A):**
  a child spec may itself carry `:children` (a sub-flow), so the flow is a TREE
  more than one level deep -- a parent (the root), an INTERMEDIATE node that is
  itself a flow-parent of grandchildren, and the grandchildren (leaves). The
  host walks the tree DEPTH-FIRST, enqueuing each NON-LEAF node as a flow-parent
  over its DIRECT children (held, `state = awaiting_children`, its
  `:dependencies` = its OWN direct-child count) AND -- because every node except
  the root is itself a child -- carrying its OWN `parent`/`parent_queue`/
  `parent_policy` toward its parent. **The walk validates the tree ACYCLIC (no
  node id appears twice) + within a DEPTH CAP (#{@max_tree_depth} levels) BEFORE
  any wire**, returning a typed `{:error, {:flow_cycle, id}}` /
  `{:error, {:flow_too_deep, cap}}` (no partial wire). The add is FAIL-CLOSED
  PER NODE (a node that fails to land leaves its subtree's parent held). A
  nested tree returns `{:ok, tree_result}` -- a nested `{node_id, [child_result]}`
  mirroring the input (the recursive analogue of the flat
  `{:ok, {parent_id, [child_id]}}`). **Multi-level COMPLETION composes over the
  byte-frozen `@complete` for FREE** (an intermediate node, when its children
  complete, is RELEASED to `pending` by the existing fan-in as a REAL claimable
  job whose completion fans into the root -- emq.3.5-D3, no new script).
  **Multi-level FAILURE** propagates UP every hop by the recursive failure hook
  (`EchoMQ.Pump`'s host re-emit -- emq.3.5-D4). **A FLAT flow (no nested
  `:children`) is the emq.3.1-3.4 path BYTE-FOR-BYTE** (a leaf is the base case;
  the all-same-queue flat flow still lands in one atomic `@enqueue_flow`).
  """
  @spec add(GenServer.server(), binary(), %{
          parent: %{id: binary(), payload: binary()},
          children: [
            %{
              :id => binary(),
              :payload => binary(),
              optional(:queue) => binary(),
              optional(:fail_parent_on_failure) => boolean(),
              optional(:ignore_dependency_on_failure) => boolean(),
              optional(:children) => list()
            }
          ]
        }) :: {:ok, {binary(), [binary()]} | tree_result()} | {:error, term()}
  def add(conn, queue, %{parent: %{id: parent_id, payload: parent_payload}, children: children})
      when is_binary(queue) and is_binary(parent_id) and is_binary(parent_payload) and
             is_list(children) do
    # Gate EVERY id (parent + each child) at the key builder BEFORE any wire
    # (INV4): an ill-formed id raises here, never reaches a key -- whichever
    # path follows. A child's key is built on ITS OWN queue (the cross-queue
    # slot), the same queue its row + outbox + deliver use.
    _ = Keyspace.job_key(queue, parent_id)
    Enum.each(children, fn %{id: cid} = c -> Keyspace.job_key(child_queue(c, queue), cid) end)

    # emq.3.5-D2 (S3 . Arm A): a NESTED tree (any child carries its own
    # `:children`) routes to the recursive host tree-walk; a FLAT flow (no
    # nested `:children`) stays the emq.3.1-3.4 path BYTE-FOR-BYTE (a leaf is
    # the base case -- the dispatch below is untouched). The nesting probe is a
    # pure shape test over the input tree (no wire), so a flat flow never enters
    # the recursive branch.
    cond do
      Enum.any?(children, &has_children?/1) ->
        add_tree(conn, queue, %{id: parent_id, payload: parent_payload, children: children})

      Enum.any?(children, fn c -> child_queue(c, queue) != queue end) ->
        add_cross_queue(conn, queue, parent_id, parent_payload, children)

      true ->
        add_same_queue(conn, queue, parent_id, parent_payload, children)
    end
  end

  @doc """
  Add many flows in one call (the v1 `add_bulk/2` parity, `flow_producer.ex:183`):
  each flow lands by the existing `add/3` mechanism (pipelined where the
  connector allows -- here issued in sequence over the shipped connector, one
  flow at a time), and the add is **fail-closed PER FLOW** -- a flow that fails
  to land leaves its OWN parent HELD (never claimable), exactly as a single
  `add/3` does (the emq.3.3 B2 add-side honesty, applied per flow), and the
  bulk result records that flow's error rather than aborting the whole batch.

  Each flow is `%{parent: spec, children: [spec]}` (the `add/3` shape, incl. the
  emq.3.4 per-child failure policy). Every id (each parent + each child, across
  every flow) is gated at `Keyspace.job_key/2` (raises on an ill-formed id --
  INV4) BEFORE any wire. Returns `{:ok, [{parent_id, [child_id]}]}` -- one
  `{parent_id, [child_id]}` per flow that LANDED, in input order; a flow that
  failed to land is omitted from the list (its parent left held, host-retryable
  by id). emq.3.4-D2.
  """
  @spec add_bulk(GenServer.server(), binary(), [
          %{parent: %{id: binary(), payload: binary()}, children: [map()]}
        ]) :: {:ok, [{binary(), [binary()]}]} | {:error, term()}
  def add_bulk(conn, queue, flows) when is_binary(queue) and is_list(flows) do
    # Gate EVERY id across EVERY flow BEFORE any wire (INV4): an ill-formed id in
    # any flow raises here, never reaching a key (no flow lands).
    Enum.each(flows, fn %{parent: %{id: pid}, children: cs} ->
      _ = Keyspace.job_key(queue, pid)
      Enum.each(cs, fn %{id: cid} = c -> Keyspace.job_key(child_queue(c, queue), cid) end)
    end)

    landed =
      Enum.reduce(flows, [], fn flow, acc ->
        case add(conn, queue, flow) do
          {:ok, {parent_id, child_ids}} -> [{parent_id, child_ids} | acc]
          # fail-closed PER FLOW: this flow's parent stays held; the batch
          # continues with the next flow (the per-flow honesty -- a poison flow
          # does not abort the others, and its held parent is host-retryable).
          _ -> acc
        end
      end)

    {:ok, Enum.reverse(landed)}
  end

  # -- the recursive flow (grandchildren / arbitrary depth) -- emq.3.5-D2 ----
  # S3 . Arm A: the recursion is a CLAUSE of `add/3` (not a separate verb). A
  # nested tree (a child carrying its own `:children`) is walked DEPTH-FIRST
  # HOST-SIDE -- the v1 `build_flow_commands` (flow_producer.ex:238/:364-374)
  # re-derived under the v2 laws (host-side, NOT a deeper Lua). Each NON-LEAF
  # node is enqueued as a flow-parent over its DIRECT children (held,
  # `state = awaiting_children`, its `:dependencies` = its OWN direct-child
  # count) AND -- because every node except the root is itself a child -- it
  # carries its OWN `parent`/`parent_queue`/`parent_policy` toward its parent,
  # written by the SAME host machinery the flat family uses (the byte-frozen
  # @hold_parent + @enqueue_flow_child + the host policy HSET).
  #
  # Why @hold_parent for every non-leaf (not @enqueue_flow): a node deeper than
  # the root is BOTH a child of its parent (so it lands pending under the flat
  # family) AND a parent of its subtree (so it must land HELD). The two writes
  # conflict -- a node cannot be both pending and awaiting_children. The
  # re-derivation that keeps EVERY shipped script BYTE-FROZEN (INV1) is the
  # cross-queue host-orchestration generalized to a tree: every node lands by a
  # SINGLE-SLOT EVAL (a non-leaf via the byte-frozen @hold_parent -> held with
  # its child count; a leaf via the byte-frozen @enqueue_flow_child -> pending),
  # parent-first (a parent's `:dependencies` exists before any child can
  # complete + deliver -- B2), each carrying its own parent fields. So the flat
  # atomic @enqueue_flow path is NOT taken inside a tree -- it stays exactly the
  # depth-1 same-queue case (the flat-flow byte-identity, INV3).
  #
  # The walk validates the tree ACYCLIC (no node id appears twice -- a cycle
  # would deadlock fan-in) + within the DEPTH CAP (@max_tree_depth -- B3) BEFORE
  # any wire, raising a typed error (INV8). FAIL-CLOSED PER NODE: a node that
  # fails to land short-circuits and leaves its subtree's parent HELD (B2 parity,
  # per node) -- the caller retries by id. Returns a nested `{:ok, tree_result}`
  # mirroring the input (each node's minted id + its children's results).
  defp add_tree(conn, queue, root) do
    # Validate the WHOLE tree before any wire (INV8): collect every node id +
    # its level. A repeated id is a cycle (or a re-converging DAG -- Out); a
    # level past the cap is an over-depth tree. Both raise host-side, no wire.
    case validate_tree(root, queue, 1, MapSet.new()) do
      {:error, _} = error ->
        error

      {:ok, _ids} ->
        # The root has no parent: parent_id '', parent_queue '', policy 'fp'
        # (unused at the root -- it has no parent to fail). Walk parent-first.
        land_node(conn, queue, root, queue, "", "")
    end
  end

  # Walk the tree host-side accumulating each node's (id, level): raise on a
  # repeated id (a cycle / a re-converging DAG -- Out, B2/INV8) and on a level
  # past the cap (over-depth, B3/INV8). A node's children inherit level + 1. The
  # queue a node runs in is its own `:queue` (defaulting to its parent's), so a
  # node id is unique tree-wide REGARDLESS of queue (the wire form is the
  # branded id; two nodes sharing an id is the cycle the guard catches).
  #
  # The walk ALSO gates EVERY node's id at `Keyspace.job_key/2` (which gates
  # `BrandedId.valid?/1` and RAISES on an ill-formed id -- INV4) on its OWN
  # queue, BEFORE any wire: a tree with an ill-formed id at ANY depth raises here
  # in the host validation, so no partial wire ever lands (the top-level `add/3`
  # gate covers only the root + its DIRECT children -- a grandchild's id is gated
  # here). The whole tree is validated before the first `land_node`.
  defp validate_tree(node, queue, level, seen) do
    cond do
      level > @max_tree_depth ->
        {:error, {:flow_too_deep, @max_tree_depth}}

      MapSet.member?(seen, node.id) ->
        {:error, {:flow_cycle, node.id}}

      true ->
        nq = child_queue(node, queue)
        # gate the node's id on its own queue BEFORE any wire (raises on an
        # ill-formed id -- INV4), so a deep ill-formed id never lands a partial
        # tree.
        _ = Keyspace.job_key(nq, node.id)
        seen = MapSet.put(seen, node.id)
        children = Map.get(node, :children, [])

        Enum.reduce_while(children, {:ok, seen}, fn child, {:ok, acc} ->
          case validate_tree(child, nq, level + 1, acc) do
            {:ok, acc2} -> {:cont, {:ok, acc2}}
            {:error, _} = error -> {:halt, error}
          end
        end)
    end
  end

  # Land one node, parent-first, then recurse into its children. `node_queue`
  # is the queue this node runs in (already resolved by the caller). `parent_id`
  # / `parent_queue` link the node UP to its parent ('' for the root); `policy`
  # is the node's OWN failure policy toward its parent ('fp'/'id'). A LEAF
  # (no children) lands pending via the byte-frozen @enqueue_flow_child; a
  # NON-LEAF lands held via the byte-frozen @hold_parent, then each child is
  # landed recursively (parent-first -- the held node's `:dependencies` exists
  # before any child can complete + deliver, B2). Fail-closed per node: a node
  # that fails to land returns its error and leaves its parent held.
  defp land_node(conn, node_queue, node, parent_queue, parent_id, policy) do
    children = Map.get(node, :children, [])

    if children == [] do
      # a leaf: land it pending carrying `parent` (+ `parent_queue` cross-queue)
      # + the host `parent_policy` HSET, exactly as the flat cross-queue leg does.
      case land_one_child(conn, node_queue, node, parent_queue, parent_id, policy) do
        :ok -> {:ok, {node.id, []}}
        {:error, _} = error -> error
      end
    else
      # a non-leaf: HOLD it with its OWN direct-child count, carrying its own
      # parent link (the root passes parent_id '' -> no parent field written),
      # then recurse into its children parent-first.
      with :ok <- hold_node(conn, node_queue, node, parent_queue, parent_id, policy),
           {:ok, child_results} <- land_children_tree(conn, node_queue, node, children) do
        {:ok, {node.id, child_results}}
      end
    end
  end

  # Hold a non-leaf node out of pending with its direct-child count, then -- for
  # a node that is itself a child (parent_id != '') -- write its own
  # `parent`/`parent_queue`/`parent_policy` fields on its row with a plain HSET
  # (same slot {node}), mirroring the flat family's host link-write. The root
  # (parent_id '') writes no parent field. The byte-frozen @hold_parent lands the
  # hold; the parent link is the declared §6 subkey of the node + the host-read
  # fields (the v1 data-value `parent_key` is NOT lifted -- INV2).
  defp hold_node(conn, node_queue, node, parent_queue, parent_id, policy) do
    node_key = Keyspace.job_key(node_queue, node.id)
    n = length(Map.get(node, :children, []))

    with {:ok, 1} <-
           hold(
             Connector.eval(
               conn,
               @hold_parent,
               [node_key, node_key <> ":dependencies"],
               [node.id, node.payload, Integer.to_string(n)]
             )
           ) do
      if parent_id == "" do
        :ok
      else
        # the node carries its own parent link: `parent` always, `parent_queue`
        # only when the parent is in a DIFFERENT queue (the same byte shape the
        # flat @enqueue_flow_child + host HSET write), and `parent_policy` (the
        # node's own policy toward its parent). All on the node's slot {node}.
        write_parent_link(conn, node_key, parent_id, parent_queue, node_queue, policy)
      end
    end
  end

  # Land a leaf child pending, carrying its parent link -- the flat cross-queue
  # leg (`land_children`) applied to one node: the byte-frozen @enqueue_flow_child
  # lands it pending with `parent` (+ `parent_queue` cross-queue), then the host
  # HSETs `parent_policy` (same slot {node}). `parent_queue` passed to the script
  # is '' for a same-queue child (no field written) else the parent's queue.
  defp land_one_child(conn, node_queue, node, parent_queue, parent_id, policy) do
    pq_arg = if node_queue == parent_queue, do: "", else: parent_queue
    keys = [Keyspace.job_key(node_queue, node.id), Keyspace.queue_key(node_queue, "pending")]
    argv = [node.id, node.payload, parent_id, pq_arg]

    case Connector.eval(conn, @enqueue_flow_child, keys, argv) do
      {:ok, 1} ->
        {:ok, _} =
          Connector.command(conn, [
            "HSET",
            Keyspace.job_key(node_queue, node.id),
            "parent_policy",
            policy
          ])

        :ok

      {:error, {:server, "EMQKIND" <> _}} ->
        {:error, :kind}

      other ->
        normalize(other)
    end
  end

  # Recurse into a held node's direct children, fail-closed: the first child
  # whose subtree fails to land short-circuits and returns its error (the held
  # node stays HELD -- B2, per node). Each child is landed by `land_node` with
  # THIS node as its parent (its queue, its id) + the CHILD's own failure policy
  # (the policy is the child's, read off the child spec -- the same per-child
  # policy the flat family resolves). Returns the children's nested results in
  # spec order.
  defp land_children_tree(conn, node_queue, node, children) do
    Enum.reduce_while(children, {:ok, []}, fn child, {:ok, acc} ->
      cq = child_queue(child, node_queue)

      case land_node(conn, cq, child, node_queue, node.id, policy_token(child)) do
        {:ok, child_result} -> {:cont, {:ok, [child_result | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, acc} -> {:ok, Enum.reverse(acc)}
      {:error, _} = error -> error
    end
  end

  # Write a node's parent link on its row with a plain HSET (the host link-write
  # the flat family does after @enqueue_flow_child / @enqueue_flow): `parent`
  # always; `parent_queue` ONLY when the parent runs in a different queue (so a
  # same-queue node's row carries no `parent_queue` -> parent_of/3 reads the
  # byte-frozen same-queue fan-in path); `parent_policy` always (the node's own
  # policy toward its parent). All fields on the node's slot {node} -- a DATA
  # link, never a data-rooted Lua key (S-6/INV2).
  defp write_parent_link(conn, node_key, parent_id, parent_queue, node_queue, policy) do
    fields =
      if node_queue == parent_queue do
        ["parent", parent_id, "parent_policy", policy]
      else
        ["parent", parent_id, "parent_queue", parent_queue, "parent_policy", policy]
      end

    case Connector.command(conn, ["HSET", node_key | fields]) do
      {:ok, _} -> :ok
      other -> normalize(other)
    end
  end

  # Whether a flow node carries its own children (a non-leaf -- the recursive
  # case). A leaf has no `:children` key (or an empty list). Pure shape test.
  defp has_children?(node), do: Map.get(node, :children, []) != []

  @doc """
  Read the completed children's results keyed by child id -- the parity of the
  v1 `EchoMQ.Job.get_children_values/1` capability (the parent handler reads
  what its legs produced, so it runs ON the results, not merely AFTER them).
  Like v1 it is a PURE `HGETALL`-class read of the parent's `:processed` HASH
  decoded to a `%{child_id => result}` map (composed
  `Keyspace.job_key(queue, parent_id) <> ":processed"`, the `add_log`
  `<> ":logs"` subkey precedent), issued through the shipped connector. The
  partial-fan-in shape mirrors v1: after k of N children complete, the map
  holds EXACTLY those k results.

  Each value is the REAL result the child carried at completion (Fork R1.B --
  `EchoMQ.Jobs.complete/5` threads it through `ARGV[5]`); a child completed
  through the shipped arity (no result) records the emq.3.1 presence marker
  (its own id) instead. A parent with no completed children yet returns
  `{:ok, %{}}`. The `parent_id` is gated at `Keyspace.job_key/2` (raises on an
  ill-formed id -- INV4) BEFORE the wire. A pure read -- no write, no state
  transition (INV2). emq.3.2-D2.
  """
  @spec children_values(GenServer.server(), binary(), binary()) ::
          {:ok, %{binary() => binary()}} | {:error, term()}
  def children_values(conn, queue, parent_id) when is_binary(queue) and is_binary(parent_id) do
    key = Keyspace.job_key(queue, parent_id) <> ":processed"

    case Connector.command(conn, ["HGETALL", key]) do
      {:ok, map} when is_map(map) -> {:ok, map}
      {:ok, flat} when is_list(flat) -> {:ok, hash_pairs(flat)}
      other -> other
    end
  end

  @doc """
  Read the children that were IGNORED ON FAILURE keyed by child id -- the parity
  of the v1 `EchoMQ.Job.get_ignored_children_failures/1` capability
  (`job.ex:885`), the FAILURE counterpart of `children_values/3`. A flow child
  with `ignore_dependency_on_failure` that DIES (exhausts its retries) is
  recorded in the parent's `:unsuccessful` HASH keyed by the child's id with its
  error as the value (the parent's `:dependencies` decremented as if satisfied
  -- the child proceeds the parent rather than failing it, emq.3.4-D3/D4). This
  reads that HASH back as a `%{child_id => error}` map, composed
  `Keyspace.job_key(queue, parent_id) <> ":unsuccessful"` (the
  `children_values/3` `<> ":processed"` subkey precedent), through the shipped
  connector.

  Disjoint from `children_values/3` by construction: a child is in `:processed`
  (it completed, with a result) XOR `:unsuccessful` (it died and was
  ignored-on-failure, with an error) -- never both. A `fail_parent_on_failure`
  death lands in the parent's `:failed` and fails the parent, so it appears in
  NEITHER read. A parent with no ignored failures returns `{:ok, %{}}`. The
  `parent_id` is gated at `Keyspace.job_key/2` (raises on an ill-formed id --
  INV4) BEFORE the wire. A pure read -- no write, no state transition (INV2).
  emq.3.4-D6.
  """
  @spec ignored_failures(GenServer.server(), binary(), binary()) ::
          {:ok, %{binary() => binary()}} | {:error, term()}
  def ignored_failures(conn, queue, parent_id) when is_binary(queue) and is_binary(parent_id) do
    key = Keyspace.job_key(queue, parent_id) <> ":unsuccessful"

    case Connector.command(conn, ["HGETALL", key]) do
      {:ok, map} when is_map(map) -> {:ok, map}
      {:ok, flat} when is_list(flat) -> {:ok, hash_pairs(flat)}
      other -> other
    end
  end

  @doc """
  Read the parent's outstanding-child count -- the parity of the v1
  `EchoMQ.Job.get_dependencies_count/1` capability (introspect a flow's
  progress: how many legs are still running). A PURE `GET`-class read of the
  parent's `:dependencies` STRING counter (composed
  `Keyspace.job_key(queue, parent_id) <> ":dependencies"`, the counter
  `EchoMQ.Flows.add/3` writes with `SET` and the fan-in hook decrements),
  parsed to a non-negative integer; `0` once every child has completed (Fork
  R2.A -- the COUNT, not the set).

  NAME-COLLISION NOTE for a v1->v2 porter: this reads the COUNT, so it is the
  parity of v1 `get_dependencies_count/1` (which `SCARD`s a SET), NOT of v1
  `get_dependencies/1` (which `SMEMBERS` the same SET to list WHICH children
  remain). The v1 `:dependencies` is a SET of pending child keys; the v2
  `:dependencies` is a STRING counter (Fork R2.A) -- so the count is the only
  shape a `GET` of the counter yields. The "which children remain" SET answer
  (the v1 `get_dependencies/1` analogue, Fork R2.B) needs a child roster
  subkey; it is a deliberately-deferred carry, not built here.

  A `parent_id` with no `:dependencies` key (not a flow parent, or already
  swept by a later lifecycle rung) returns `{:ok, 0}` -- the honest "zero
  outstanding" reading, the count's natural floor, no new error vocabulary.
  The `parent_id` is gated at `Keyspace.job_key/2` (raises on an ill-formed id
  -- INV4) BEFORE the wire. A pure read -- no write (INV2). emq.3.2-D3.
  """
  @spec dependencies(GenServer.server(), binary(), binary()) ::
          {:ok, non_neg_integer()} | {:error, term()}
  def dependencies(conn, queue, parent_id) when is_binary(queue) and is_binary(parent_id) do
    key = Keyspace.job_key(queue, parent_id) <> ":dependencies"

    case Connector.command(conn, ["GET", key]) do
      {:ok, nil} -> {:ok, 0}
      {:ok, n} when is_binary(n) -> {:ok, String.to_integer(n)}
      {:ok, n} when is_integer(n) and n >= 0 -> {:ok, n}
      other -> other
    end
  end

  # HGETALL decodes to a native map on a RESP3 connection (the shipped
  # connector); the flat [k, v, k, v] form is the RESP2 fallback. Accept both,
  # the way EchoMQ.Conformance.pairs/1 does, so the read is protocol-agnostic.
  defp hash_pairs(flat), do: flat |> Enum.chunk_every(2) |> Map.new(fn [k, v] -> {k, v} end)

  # The queue a child runs in: its `:queue` field, defaulting to the parent's
  # `queue` (so an unqualified child is a same-queue child).
  defp child_queue(child, queue), do: Map.get(child, :queue, queue)

  # The failure-policy token a child's row carries (emq.3.4-D2), read HOST-SIDE
  # at retry time to route the child's death: `'id'`
  # (ignore_dependency_on_failure -- the parent proceeds) when the child opts in
  # explicitly; otherwise `'fp'` (fail_parent_on_failure -- the v1 default, the
  # parent fails too). A child naming both flags resolves to `'id'` (the proceed
  # policy is the explicit opt-in). The token is a host-passed ARGV field, never
  # a data-rooted Lua key.
  defp policy_token(child) do
    if Map.get(child, :ignore_dependency_on_failure, false), do: "id", else: "fp"
  end

  # The emq.3.1 atomic single-queue add -- the whole flow on one slot in one
  # @enqueue_flow EVAL. Reached only when every child is same-queue. After the
  # atomic land, the host writes each child's `parent_policy` token on its row
  # (emq.3.4-D2) -- the SAME slot {C}={P}, a plain HSET that keeps @enqueue_flow
  # BYTE-FROZEN (the policy is a host-read DATA field, never a data-rooted Lua
  # key -- S-6/INV2). A child carrying the DEFAULT policy ('fp') is written too,
  # so parent_of/3 reads a uniform field for every flow child. The policy write
  # follows the atomic add (the children are already claimable + the parent
  # held); a same-queue child cannot complete-and-release the parent before its
  # policy is set in a way that matters, because the policy is consulted only on
  # the child's DEATH (retry past max), never on its completion.
  defp add_same_queue(conn, queue, parent_id, parent_payload, children) do
    parent_key = Keyspace.job_key(queue, parent_id)
    child_keys = Enum.map(children, fn %{id: cid} -> Keyspace.job_key(queue, cid) end)

    keys =
      [
        parent_key,
        parent_key <> ":dependencies",
        Keyspace.queue_key(queue, "pending")
      ] ++ child_keys

    argv =
      [parent_id, parent_payload, Integer.to_string(length(children))] ++
        Enum.flat_map(children, fn %{id: cid, payload: cp} -> [cid, cp] end)

    case Connector.eval(conn, @enqueue_flow, keys, argv) do
      {:ok, n} when is_integer(n) ->
        Enum.each(children, fn %{id: cid} = c ->
          {:ok, _} =
            Connector.command(conn, [
              "HSET",
              Keyspace.job_key(queue, cid),
              "parent_policy",
              policy_token(c)
            ])
        end)

        {:ok, {parent_id, Enum.map(children, & &1.id)}}

      {:error, {:server, "EMQKIND" <> _}} ->
        {:error, :kind}

      other ->
        other
    end
  end

  # The emq.3.3 cross-queue add -- host-orchestrated, NON-atomic across slots,
  # parent-first, fail-closed. Reached when ANY child is cross-queue. The
  # parent lands held FIRST (its :dependencies counter exists before any child
  # can complete), then each child lands on ITS OWN slot (same-queue children
  # on the parent's slot, cross-queue children on theirs, each carrying
  # `parent` + -- cross-queue -- `parent_queue`). A failure at any step returns
  # the error and STOPS: the parent stays HELD (never claimable), the caller
  # retries by id (B2 fail-closed). Each step is a single-slot declared-keys
  # EVAL.
  defp add_cross_queue(conn, queue, parent_id, parent_payload, children) do
    n = length(children)
    parent_key = Keyspace.job_key(queue, parent_id)

    with {:ok, 1} <-
           hold(
             Connector.eval(
               conn,
               @hold_parent,
               [parent_key, parent_key <> ":dependencies"],
               [parent_id, parent_payload, Integer.to_string(n)]
             )
           ),
         :ok <- land_children(conn, queue, parent_id, children) do
      {:ok, {parent_id, Enum.map(children, & &1.id)}}
    end
  end

  # Land each child on its own slot, fail-closed: the first child that fails to
  # land short-circuits and returns its error (the parent stays HELD). A
  # same-queue child carries `parent` only (the emq.3.1 byte-frozen fan-in
  # path); a cross-queue child carries `parent` + `parent_queue` (the outbox
  # emit path). `parent_queue` passed to the script is '' for a same-queue
  # child (no field written), the parent's `queue` for a cross-queue child.
  # After the BYTE-FROZEN @enqueue_flow_child EVAL lands the child, the host
  # writes the emq.3.4 `parent_policy` token on the child row with a plain HSET
  # (same slot {C}) -- so @enqueue_flow_child stays byte-frozen (INV1) and the
  # ONLY shipped-script edit is @retry. A crash between the EVAL and the policy
  # HSET defaults the child to fail_parent_on_failure (the v1 default,
  # `parent_fail_of/3`'s `policy_arm/1` floor), and the cross-queue add is
  # itself fail-closed (a partial add leaves the parent held, host-retried),
  # exactly as the same-queue add is.
  defp land_children(conn, queue, parent_id, children) do
    Enum.reduce_while(children, :ok, fn child, _acc ->
      cq = child_queue(child, queue)
      pq_arg = if cq == queue, do: "", else: queue

      keys = [Keyspace.job_key(cq, child.id), Keyspace.queue_key(cq, "pending")]
      argv = [child.id, child.payload, parent_id, pq_arg]

      case Connector.eval(conn, @enqueue_flow_child, keys, argv) do
        {:ok, 1} ->
          {:ok, _} =
            Connector.command(conn, ["HSET", Keyspace.job_key(cq, child.id), "parent_policy", policy_token(child)])

          {:cont, :ok}

        {:error, {:server, "EMQKIND" <> _}} ->
          {:halt, {:error, :kind}}

        other ->
          {:halt, normalize(other)}
      end
    end)
  end

  # Map the parent-hold EVAL's verdicts: the EMQKIND first-act refusal -> the
  # host-side {:error, :kind}; a transport error passes through.
  defp hold({:ok, 1}), do: {:ok, 1}
  defp hold({:error, {:server, "EMQKIND" <> _}}), do: {:error, :kind}
  defp hold(other), do: normalize(other)

  defp normalize({:ok, other}), do: {:error, {:unexpected, other}}
  defp normalize(other), do: other
end
