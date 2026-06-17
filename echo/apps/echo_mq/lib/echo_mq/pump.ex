defmodule EchoMQ.Pump do
  @moduledoc """
  The cadence that releases due work. A supervised, OPT-IN process that beats
  on a tick: each beat promotes due schedule entries through
  `EchoMQ.Jobs.promote/3` and fires due repeatables through
  `EchoMQ.Repeat`, minting a fresh branded `JOB` id host-side per occurrence.
  A worker started without the pump is the v2 core worker, unchanged -- the
  pump is the standing release cadence for a deployment that wants scheduled
  and repeatable work released without every consumer hand-rolling a sweeper.

  Opt-in and owner-started (the library law: no `mod:` auto-start). The
  decision core -- the tick interval and the per-tick batch -- is pure
  (`EchoMQ.Pump.Core`), so the cadence arithmetic is a value tested without a
  clock; the GenServer is the thin shell that calls the wire on each tick.
  Restart semantics are stated in `child_spec/1`: a `:transient` child, so a
  normal stop is final and a crash restarts the cadence whole (promotion and
  the repeat sweep are both idempotent over their sets, so a restart loses no
  due entry). Chapter 3.7.
  """

  use GenServer

  alias EchoMQ.{Connector, Jobs, Keyspace, Pump, Repeat, Script}
  alias EchoData.BrandedId

  # The CROSS-QUEUE flow deliver (emq.3.3-D4, D-3) -- the parent-slot half of
  # the completion-signal hop. A cross-queue child emitted its completion to
  # its own-slot outbox (`@complete`'s cross-queue branch); this script applies
  # the decrement on the PARENT's slot {P}, all keys host-built + declared
  # (`Keyspace.job_key(parent_queue, parent_id)`), so no key is read out of a
  # data value (S-6/INV2). The `:processed` HSETNX guard (D-3) makes delivery
  # IDEMPOTENT: the DECR fires ONLY when the child is recorded for the first
  # time, so a re-delivered entry (a sweep crash AFTER the DECR, BEFORE the
  # outbox LTRIM) finds the child already a `:processed` field (HSETNX -> 0),
  # decrements nothing, and the parent is released EXACTLY once (at-least-once
  # -> effectively-once, INV6). At zero outstanding the parent is released to
  # its pending set (derived from the declared parent-queue base root the way
  # @complete derives `p .. 'pending'`) and its row marked pending.
  #   KEYS[1] = the parent's :dependencies, KEYS[2] = the parent's :processed,
  #   KEYS[3] = the parent row (all on {P}); ARGV[1] = child id, ARGV[2] =
  #   result, ARGV[3] = parent id, ARGV[4] = the parent-queue base (p).
  @flow_deliver Script.new(:flow_deliver, """
                if redis.call('HSETNX', KEYS[2], ARGV[1], ARGV[2]) == 1 then
                  local left = redis.call('DECR', KEYS[1])
                  if left <= 0 then
                    redis.call('ZADD', ARGV[4] .. 'pending', 0, ARGV[3])
                    redis.call('HSET', KEYS[3], 'state', 'pending')
                  end
                end
                return 1
                """)

  # The CROSS-QUEUE flow FAIL-deliver (emq.3.4-D4) -- the parent-slot half of
  # the failure-signal hop, the failure counterpart of @flow_deliver. A
  # cross-queue child's DEATH emitted a fail-entry into its own-slot outbox
  # (@retry's cross-queue failure branch); this script applies the policy on the
  # PARENT's slot {P}, all keys host-built + declared
  # (`Keyspace.job_key(parent_queue, parent_id)`), so no key is read out of a
  # data value (S-6/INV2). By the entry's POLICY:
  #   * 'fp' (fail_parent_on_failure) -> if the child is recorded in :failed for
  #     the FIRST time (HSETNX -> 1), move the parent to `dead` (record :failed,
  #     HSET row state 'dead', ZADD <parent dead>, ZREM <parent pending>);
  #   * 'id' (ignore_dependency_on_failure) -> if the child is recorded in
  #     :unsuccessful for the FIRST time (HSETNX -> 1), DECR :dependencies and
  #     at-zero release the parent (ZADD <parent pending>, HSET row state
  #     'pending').
  # The HSETNX guard makes delivery IDEMPOTENT (the SAME :processed-class guard
  # @flow_deliver uses, now over :failed/:unsuccessful): a re-delivered fail (a
  # sweep crash AFTER the apply, BEFORE the outbox LTRIM) finds the child already
  # recorded (HSETNX -> 0) and is a NO-OP, so the parent is failed-or-satisfied
  # EXACTLY once (at-least-once -> effectively-once, INV7).
  #   KEYS[1] = the parent's :dependencies, KEYS[2] = the parent's :failed,
  #   KEYS[3] = the parent's :unsuccessful, KEYS[4] = the parent row (all on
  #   {P}); ARGV[1] = child id, ARGV[2] = error, ARGV[3] = policy ('fp'/'id'),
  #   ARGV[4] = the parent-queue base (p), ARGV[5] = parent id. The parent's
  #   pending/dead sets derive from the declared parent-queue base root the way
  #   @flow_deliver derives `p .. 'pending'` -- slot-sound (all {P}).
  @flow_fail_deliver Script.new(:flow_fail_deliver, """
                     if ARGV[3] == 'fp' then
                       if redis.call('HSETNX', KEYS[2], ARGV[1], ARGV[2]) == 1 then
                         redis.call('HSET', KEYS[4], 'state', 'dead')
                         redis.call('ZADD', ARGV[4] .. 'dead', 0, ARGV[5])
                         redis.call('ZREM', ARGV[4] .. 'pending', ARGV[5])
                       end
                     else
                       if redis.call('HSETNX', KEYS[3], ARGV[1], ARGV[2]) == 1 then
                         local left = redis.call('DECR', KEYS[1])
                         if left <= 0 then
                           redis.call('ZADD', ARGV[4] .. 'pending', 0, ARGV[5])
                           redis.call('HSET', KEYS[4], 'state', 'pending')
                         end
                       end
                     end
                     return 1
                     """)

  @doc """
  A transient child: a normal stop is final, a crash restarts the cadence
  whole. Promotion and the repeat sweep are idempotent over their sets, so a
  restart re-sweeps without loss or duplication.
  """
  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :id, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      restart: :transient,
      shutdown: 5_000
    }
  end

  @doc """
  Start the pump. Options: `:conn` (a connector this pump drives) or
  `:connector` (options to start one, linked); `:queue` (the queue to sweep);
  `:tick_ms` (the beat, default 1_000); `:batch` (the promote LIMIT and the
  repeat due-read LIMIT per tick, default 100); `:name` (an optional
  registered name).
  """
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    gen_opts = if name, do: [name: name], else: []
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  @doc "Stop the pump; the current tick settles, no further tick is scheduled."
  def stop(pump, timeout \\ 5_000), do: GenServer.stop(pump, :normal, timeout)

  @impl true
  def init(opts) do
    queue = Keyword.fetch!(opts, :queue)

    conn =
      case Keyword.fetch(opts, :conn) do
        {:ok, c} ->
          c

        :error ->
          {:ok, c} = Connector.start_link(Keyword.fetch!(opts, :connector))
          c
      end

    state = %{
      conn: conn,
      queue: queue,
      tick_ms: Pump.Core.tick_ms(opts),
      batch: Pump.Core.batch(opts)
    }

    {:ok, arm(state)}
  end

  @impl true
  def handle_info(:tick, s) do
    _ = sweep(s)
    {:noreply, arm(s)}
  end

  @doc """
  One sweep, exposed for a direct-drive test (no cadence): promote due
  schedule entries, fire due repeatables, then deliver cross-queue flow
  completions. Answers `{:ok, %{promoted: n, fired: m, delivered: d}}`.

  The third pass (`deliver_flow_completions/3`, emq.3.3-D4) drains this
  queue's `emq:{queue}:flow:outbox` and delivers each cross-queue child's
  decrement to its parent on the PARENT's slot -- the cross-queue fan-in is
  released here, on the tick, not synchronously at completion (INV5). A queue
  that hosts cross-queue children must run a pump for its parents to be
  released (B4); the durable outbox survives a pump-absent window and drains on
  the next start (delayed, never lost).
  """
  def sweep(%{conn: conn, queue: queue, batch: batch}) do
    promoted =
      case Jobs.promote(conn, queue, batch) do
        {:ok, n} when is_integer(n) -> n
        _ -> 0
      end

    fired = fire_repeats(conn, queue, batch)

    delivered =
      case deliver_flow_completions(conn, queue, batch) do
        {:ok, d} when is_integer(d) -> d
        _ -> 0
      end

    {:ok, %{promoted: promoted, fired: fired, delivered: delivered}}
  end

  @doc """
  Drain this queue's cross-queue flow outbox (`emq:{queue}:flow:outbox`, a
  LIST) and deliver each child's decrement to its parent on the parent's slot
  (emq.3.3-D4). Reads up to `batch` entries NON-DESTRUCTIVELY (`LRANGE 0
  batch-1`), issues one idempotent `@flow_deliver` EVAL per entry on the
  PARENT's slot (the parent key rebuilt HOST-SIDE via
  `Keyspace.job_key(parent_queue, parent_id)` from the entry -- the v1
  data-value key is NOT lifted), and only THEN removes the delivered prefix
  (`LTRIM batch-delivered .. -1`). The order is deliver-BEFORE-remove: a crash
  between the read and the trim RE-DELIVERS (idempotent via the `:processed`
  HSETNX guard -- INV6), never drops -- so the at-least-once outbox becomes
  effectively-once with no drop window (INV7). Each entry is the NUL-joined
  tuple `parent_queue \\0 parent_id \\0 child_id \\0 result` the child's
  `@complete` RPUSHed; the host splits on NUL (absent from a branded id and a
  §6 queue name, so an unambiguous separator) and the result is the LAST field
  (split into exactly four parts). Answers `{:ok, delivered_count}`.
  """
  def deliver_flow_completions(conn, queue, batch)
      when is_integer(batch) and batch > 0 do
    outbox = Keyspace.queue_key(queue, "flow:outbox")

    case Connector.command(conn, ["LRANGE", outbox, "0", Integer.to_string(batch - 1)]) do
      {:ok, []} ->
        {:ok, 0}

      {:ok, entries} when is_list(entries) ->
        # Count the CONTIGUOUS delivered prefix, halting at the first entry
        # that does not deliver -- so `delivered` is always a true head prefix
        # length and `LTRIM delivered -1` removes exactly the delivered
        # entries, never a not-yet-delivered one behind a poison entry (a
        # malformed entry blocks its own queue rather than letting LTRIM drop
        # live entries past it -- deliver-before-remove, no drop).
        delivered =
          Enum.reduce_while(entries, 0, fn entry, acc ->
            if deliver_one(conn, entry) == 1, do: {:cont, acc + 1}, else: {:halt, acc}
          end)

        if delivered > 0 do
          Connector.command(conn, ["LTRIM", outbox, Integer.to_string(delivered), "-1"])
        end

        {:ok, delivered}

      _ ->
        {:ok, 0}
    end
  end

  # Deliver one outbox entry: split the NUL-joined tuple host-side, dispatch by
  # KIND, rebuild the parent's declared keys on its own slot, and issue the
  # idempotent deliver. A well-formed entry that delivers counts 1 (so the LTRIM
  # removes exactly the delivered prefix); a malformed entry (wrong field count,
  # or an ill-formed parent id that raises at the key builder) counts 0 and is
  # left in the outbox -- deliver-before-remove never drops a not-yet-delivered
  # entry.
  #
  # Two entry KINDs share the outbox (emq.3.4-D4): a COMPLETE-entry (the
  # emq.3.3 `parent_queue \0 parent_id \0 child_id \0 result`, whose first field
  # `parent_queue` is a non-empty §6 queue name) dispatches the byte-unchanged
  # @flow_deliver; a FAIL-entry (the emq.3.4 `'' \0 'fail' \0 parent_queue \0
  # parent_id \0 child_id \0 policy \0 error`, whose LEADING field is EMPTY --
  # illegal for a queue name, so it cannot collide with a complete-entry)
  # dispatches the new @flow_fail_deliver. `split_entry/1` returns the tagged
  # shape; the complete branch peels the FIRST THREE NUL boundaries only
  # (parent_queue, parent_id, child_id -- all NUL-free by construction), leaving
  # `result` as the untouched remainder (a result may itself contain any byte).
  defp deliver_one(conn, entry) when is_binary(entry) do
    case split_entry(entry) do
      {:complete, parent_queue, parent_id, child_id, result} ->
        try do
          parent_key = Keyspace.job_key(parent_queue, parent_id)

          keys = [
            parent_key <> ":dependencies",
            parent_key <> ":processed",
            parent_key
          ]

          argv = [child_id, result, parent_id, Keyspace.queue_key(parent_queue, "")]

          case Connector.eval(conn, @flow_deliver, keys, argv) do
            {:ok, 1} -> 1
            _ -> 0
          end
        rescue
          ArgumentError -> 0
        end

      {:fail, parent_queue, parent_id, child_id, error, policy} ->
        try do
          parent_key = Keyspace.job_key(parent_queue, parent_id)

          keys = [
            parent_key <> ":dependencies",
            parent_key <> ":failed",
            parent_key <> ":unsuccessful",
            parent_key
          ]

          argv = [child_id, error, policy, Keyspace.queue_key(parent_queue, ""), parent_id]

          # emq.3.5-D4 (the recursive failure hook, Arm A -- host/sweep): read
          # the parent's state BEFORE the deliver, so a deliver that TRANSITIONS
          # the parent into `dead` (the 'fp' arm, on the FIRST record -- the
          # HSETNX guard) is distinguishable from a re-delivery of an
          # already-dead parent (no transition). Only a TRANSITION re-emits the
          # parent's OWN death UP -- a re-delivery is a no-op for the next hop
          # too (INV7), so the outbox does not grow on re-delivery.
          dead_before? = state_is_dead?(conn, parent_queue, parent_id)

          case Connector.eval(conn, @flow_fail_deliver, keys, argv) do
            {:ok, 1} ->
              unless dead_before?,
                do: maybe_reemit_parent_death(conn, parent_queue, parent_id, error)

              1

            _ ->
              0
          end
        rescue
          ArgumentError -> 0
        end

      _ ->
        0
    end
  end

  defp deliver_one(_conn, _entry), do: 0

  @doc """
  Re-emit a node's death UP to ITS parent -- the recursive failure hook
  (emq.3.5-D4, Arm A). When a node `node_id` in `node_queue` has just been moved
  to `dead` AND it carries its own `parent`/`parent_queue`/`parent_policy` (it is
  itself a flow-child -- read HOST-SIDE via `EchoMQ.Jobs.parent_fail_link/3`),
  the host RE-EMITS the node's death to the node's parent by the node's OWN
  policy, over the SAME byte-frozen failure machinery emq.3.4 founded:

    * a CROSS-QUEUE parent (a different queue) -> RPUSH a FAIL-ENTRY (the
      existing KIND -- leading empty field + `'fail'` tag) into the NODE's
      own-slot `flow:outbox`, BYTE-FAITHFUL to what `@retry`'s `xq:fp`/`xq:id`
      arm RPUSHes, delivered on the parent's slot by the existing sweep +
      byte-frozen `@flow_fail_deliver` (one more hop of the same delivery);
    * a SAME-QUEUE parent (the node's parent shares its queue) -> RPUSH the SAME
      fail-entry into the node's own-slot outbox too (the node's queue IS the
      parent's queue, so the entry's parent_queue is the node's queue and the
      sweep of THIS queue delivers it on the parent's slot -- uniform with the
      cross-queue hop, no special same-slot path, every shipped script frozen).

  The re-emit reuses the existing fail-entry KIND + outbox + sweep +
  `@flow_fail_deliver` -- NO shipped Lua is edited (Arm A). It is gated on the
  parent->dead TRANSITION (the caller's before/after state read), so it fires
  ONCE per node death; the NEXT hop's `@flow_fail_deliver` HSETNX dedups the
  GRANDPARENT's `:failed`/`:unsuccessful`, so even a duplicate next-hop entry
  fails the grandparent exactly once (at-least-once emit -> effectively-once
  deliver, INV6/INV7). Recurses up EVERY level: the parent's own death, when
  delivered, re-emits to ITS parent by the same path (the multi-level analogue
  of emq.3.4's one-level propagation). A node with no parent (the root) re-emits
  nothing -- the recursion stops.
  """
  def maybe_reemit_parent_death(conn, node_queue, node_id, error) do
    case Jobs.parent_fail_link(conn, node_queue, node_id) do
      nil ->
        :ok

      {:cross_queue, grandparent_id, grandparent_queue, policy} ->
        push_fail_entry(conn, node_queue, grandparent_queue, grandparent_id, node_id, policy, error)

      {:same_queue, grandparent_id, _grandparent_key, policy} ->
        # the node's parent shares the node's queue: the fail-entry's
        # parent_queue IS node_queue, and the sweep of node_queue delivers it on
        # the parent's slot -- the same outbox the cross-queue hop uses.
        push_fail_entry(conn, node_queue, node_queue, grandparent_id, node_id, policy, error)
    end
  end

  @doc """
  The SAME-QUEUE recursive-failure trigger (emq.3.5-D4, the second site -- the
  host observing a `retry/7` that returned `:dead`). When a SAME-QUEUE flow
  child `child_id` (in `queue`) dies, `@retry`'s byte-frozen `sq:fp` arm moves
  the child's DIRECT parent to `dead` ATOMICALLY in that one EVAL
  (`jobs.ex`, the `sq:fp` arm) -- but emq.3.4 stops there (one level). If that
  parent is itself an INTERMEDIATE node carrying its OWN parent, its death must
  propagate UP. This is the host observing the death: after `retry/7` returns
  `:dead`, read the dead child's parent (host-side via
  `EchoMQ.Jobs.parent_fail_link/3`) and -- when that parent has thereby moved to
  `dead` AND is itself a flow-child -- re-emit the PARENT's death by the
  PARENT's policy over the byte-frozen failure machinery (the same
  outbox+sweep+`@flow_fail_deliver` hop), recursing up every level.

  `retry/7` stays a pure script-caller (no Lua edited -- Arm A); this is the
  caller's host step at the death observation. It is gated on the parent->dead
  transition implicitly: the `sq:fp` arm moves the parent to dead only on the
  child's FIRST `:failed` record (the same atomic EVAL that returned `:dead`),
  and a re-run finds the child already retired (`retry/7` -> `{:error, :gone}`,
  never `:dead` again), so it fires once per death. A `'fp'` child whose parent
  is NOT yet dead (a sibling still outstanding under a NON-fp arm is impossible
  -- the `sq:fp` arm fails the parent unconditionally on the first record) or a
  child with no parent re-emits nothing. Returns `:ok`.
  """
  def on_same_queue_child_death(conn, queue, child_id, error) do
    case Jobs.parent_fail_link(conn, queue, child_id) do
      nil ->
        # the dead child has no parent (it was a root, or a non-flow job) --
        # nothing to propagate.
        :ok

      {:cross_queue, _parent_id, _parent_queue, _policy} ->
        # the dead child's parent is in ANOTHER queue -- then @retry took the
        # `xq:*` arm (an outbox emit), the parent is failed on the SWEEP tick,
        # and the deliver-loop hook (maybe_reemit_parent_death) handles the next
        # hop. Nothing to do here (this trigger is the SAME-QUEUE site only).
        :ok

      {:same_queue, parent_id, _parent_key, _child_policy} ->
        # the dead child's parent shares the queue -> @retry's `sq:fp` arm moved
        # the parent to `dead` atomically. Propagate the PARENT's death UP (by
        # the PARENT's own policy) IFF the parent is now dead and itself a
        # flow-child. The error carried up is the parent's death cause -- the
        # same error the child failed with (the death cascaded from it).
        if state_is_dead?(conn, queue, parent_id) do
          maybe_reemit_parent_death(conn, queue, parent_id, error)
        else
          :ok
        end
    end
  end

  # RPUSH a FAIL-ENTRY into `node_queue`'s flow outbox, BYTE-FAITHFUL to what
  # `@retry`'s cross-queue failure branch (jobs.ex, the 'xq:fp'/'xq:id' arm)
  # RPUSHes -- a LEADING EMPTY field + the `'fail'` tag + parent_queue +
  # parent_id + child_id + policy + error, NUL-joined (policy before error; the
  # arbitrary-byte error LAST, the remainder). `parent_queue`/`parent_id` here
  # are the GRANDPARENT (the node's parent); `child_id` is the dead node. The
  # sweep's `split_fail_entry/1` reads exactly this shape (the emq.3.3 L-2
  # lesson: a re-injected wire entry counts only if it byte-matches the producer
  # -- so this re-emit shares the producer's field order).
  defp push_fail_entry(conn, node_queue, parent_queue, parent_id, child_id, policy, error) do
    outbox = Keyspace.queue_key(node_queue, "flow:outbox")
    entry = Enum.join(["", "fail", parent_queue, parent_id, child_id, policy, error], <<0>>)

    case Connector.command(conn, ["RPUSH", outbox, entry]) do
      {:ok, _} -> :ok
      _ -> :ok
    end
  end

  # Whether a node's row sits in `state = dead` -- the host-side read that gates
  # the recursive re-emit on the parent->dead TRANSITION (emq.3.5-D4). A direct
  # HGET of the row's `state` field (the node key built through the gated
  # `Keyspace.job_key/2`); any non-"dead"/absent reading is "not dead". A pure
  # read, no transition.
  defp state_is_dead?(conn, queue, job_id) do
    case Connector.command(conn, ["HGET", Keyspace.job_key(queue, job_id), "state"]) do
      {:ok, "dead"} -> true
      _ -> false
    end
  rescue
    ArgumentError -> false
  end

  # Split an outbox entry by KIND. A FAIL-entry leads with an EMPTY field then
  # the literal `'fail'` tag (`'' \0 'fail' \0 parent_queue \0 parent_id \0
  # child_id \0 policy \0 error`): the leading empty field is illegal for a §6
  # queue name, so a fail-entry can never be mis-read as a complete-entry. Its
  # first six fields are NUL-free by construction (the tag, a queue name, two
  # branded ids, the 2-char policy token) and the ERROR is the LAST field (the
  # remainder, so a worker reason carrying any byte -- incl. NUL -- survives),
  # mirroring the complete-entry's result-last design -- peel the first five NUL
  # boundaries, `error` the remainder. Otherwise it is the emq.3.3
  # COMPLETE-entry: peel the FIRST THREE NUL boundaries into [parent_queue,
  # parent_id, child_id, result] (the byte-unchanged emq.3.3 parse). A
  # short/ill-shaped entry returns `:malformed`, which `deliver_one`'s match
  # falls through (count 0, left in the outbox -- deliver-before-remove never
  # drops it).
  defp split_entry(entry) do
    case :binary.split(entry, <<0>>) do
      ["", rest] -> split_fail_entry(rest)
      _ -> split_complete_entry(entry)
    end
  end

  defp split_complete_entry(entry) do
    with [pq, rest1] <- :binary.split(entry, <<0>>),
         [pid, rest2] <- :binary.split(rest1, <<0>>),
         [cid, result] <- :binary.split(rest2, <<0>>) do
      {:complete, pq, pid, cid, result}
    else
      _ -> :malformed
    end
  end

  # `rest` is everything after the leading `'' \0` -- i.e.
  # `'fail' \0 parent_queue \0 parent_id \0 child_id \0 policy \0 error`. Peel
  # the five NUL boundaries between the six leading NUL-free fields; `error` is
  # the last field (the remainder, keeping any byte). A non-`'fail'` tag, or
  # fewer than five NULs, is :malformed.
  defp split_fail_entry(rest) do
    with ["fail", r1] <- :binary.split(rest, <<0>>),
         [pq, r2] <- :binary.split(r1, <<0>>),
         [pid, r3] <- :binary.split(r2, <<0>>),
         [cid, r4] <- :binary.split(r3, <<0>>),
         [policy, error] <- :binary.split(r4, <<0>>) do
      {:fail, pq, pid, cid, error, policy}
    else
      _ -> :malformed
    end
  end

  # Read due registrations, mint a fresh branded JOB id per occurrence,
  # enqueue it (the occurrence is due now -> straight to pending), and advance
  # the registration's score. The mint is host-side; the wire never mints.
  #
  # Each occurrence is fired independently and SOFT-matched: a wire hiccup on
  # one enqueue/advance is logged and skipped, never crash-looping the whole
  # cadence (a crash would also drop the tick's promote work). The pump is
  # :transient and the sweep idempotent, so the next tick re-fires a skipped
  # registration whose score it could not advance -- no occurrence is lost.
  defp fire_repeats(conn, queue, batch) do
    case Repeat.due(conn, queue, batch) do
      {:ok, records} ->
        Enum.reduce(records, 0, fn record, acc ->
          if fire_one(conn, queue, record), do: acc + 1, else: acc
        end)

      _ ->
        0
    end
  end

  defp fire_one(conn, queue, {name, every, template})
       when is_binary(every) and is_binary(template) do
    id = BrandedId.generate!("JOB")

    with {:ok, _} <- Jobs.enqueue(conn, queue, id, template),
         {:ok, _} <- Repeat.advance(conn, queue, name, String.to_integer(every)) do
      true
    else
      other ->
        require Logger
        Logger.warning("EchoMQ.Pump: repeat #{inspect(name)} skipped this tick: #{inspect(other)}")
        false
    end
  end

  defp fire_one(conn, queue, {name, _every, _template}) do
    # the record was deleted mid-sweep; sweep the dangling registry member so
    # it stops surfacing as due (cancel removes the member and the absent
    # record), and count no occurrence
    _ = Repeat.cancel(conn, queue, name)
    false
  end

  defp arm(s) do
    Process.send_after(self(), :tick, s.tick_ms)
    s
  end
end
