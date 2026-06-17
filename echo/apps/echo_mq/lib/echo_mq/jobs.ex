defmodule EchoMQ.Jobs do
  @moduledoc """
  Jobs are entities. A job's identity is a branded id under the `JOB`
  namespace; its row is a hash at the job key; the pending set is a
  same-score sorted set whose members are the ids themselves, so byte
  order is mint order and the queue carries no second index. Enqueue is
  one idempotent script: kind policy, duplicate refusal, row write, and
  pending insertion happen on the server in one atomic step.
  Chapter 3.2.
  """

  alias EchoMQ.{Connector, Keyspace, Script}

  @enqueue Script.new(:enqueue, """
           if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
             return redis.error_reply('EMQKIND job id must be JOB-namespaced')
           end
           if redis.call('EXISTS', KEYS[1]) == 1 then
             return 0
           end
           redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
           redis.call('ZADD', KEYS[2], 0, ARGV[1])
           return 1
           """)

  @doc "One idempotent script: admit by kind, refuse duplicates, write the row and the pending entry atomically."
  def enqueue(conn, queue, job_id, payload) when is_binary(job_id) and is_binary(payload) do
    keys = [Keyspace.job_key(queue, job_id), Keyspace.queue_key(queue, "pending")]

    case Connector.eval(conn, @enqueue, keys, [job_id, payload]) do
      {:ok, 1} -> {:ok, :enqueued}
      {:ok, 0} -> {:ok, :duplicate}
      {:error, {:server, "EMQKIND" <> _}} -> {:error, :kind}
      other -> other
    end
  end

  @schedule Script.new(:schedule, """
            if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
              return redis.error_reply('EMQKIND job id must be JOB-namespaced')
            end
            if redis.call('EXISTS', KEYS[1]) == 1 then
              return 0
            end
            local score
            if ARGV[3] == 'in' then
              local t = redis.call('TIME')
              local now = t[1] * 1000 + math.floor(t[2] / 1000)
              score = now + tonumber(ARGV[4])
            else
              score = tonumber(ARGV[4])
            end
            redis.call('HSET', KEYS[1], 'state', 'scheduled', 'attempts', '0', 'payload', ARGV[2])
            redis.call('ZADD', KEYS[2], score, ARGV[1])
            return 1
            """)

  @doc """
  Scheduled admission at an absolute due time: the job is minted at enqueue,
  its row written `state = scheduled`, and parked on the schedule set at the
  caller's run-at millisecond score -- a visibility fence, not a second
  queue. The existing promote pump releases it once due; the mint-ordered id
  stays the sort key, so a job minted earlier but scheduled later sorts, once
  promoted, by its mint. The caller's clock prices only the schedule score.
  Chapter 3.7.
  """
  def enqueue_at(conn, queue, job_id, payload, run_at_ms)
      when is_binary(job_id) and is_binary(payload) and is_integer(run_at_ms) do
    schedule(conn, queue, job_id, payload, "at", run_at_ms)
  end

  @doc """
  Scheduled admission after a relative delay: identical to `enqueue_at/5`
  with the run-at score computed wire-side from the server clock (`TIME`), so
  the delay is measured on the same clock that promote and reap read -- never
  the caller's. Chapter 3.7.
  """
  def enqueue_in(conn, queue, job_id, payload, delay_ms)
      when is_binary(job_id) and is_binary(payload) and is_integer(delay_ms) and delay_ms >= 0 do
    schedule(conn, queue, job_id, payload, "in", delay_ms)
  end

  defp schedule(conn, queue, job_id, payload, mode, value) do
    keys = [Keyspace.job_key(queue, job_id), Keyspace.queue_key(queue, "schedule")]

    case Connector.eval(conn, @schedule, keys, [job_id, payload, mode, Integer.to_string(value)]) do
      {:ok, 1} -> {:ok, :scheduled}
      {:ok, 0} -> {:ok, :duplicate}
      {:error, {:server, "EMQKIND" <> _}} -> {:error, :kind}
      other -> other
    end
  end

  @doc """
  Batch admission: pipelines the enqueue transition for many `{id, payload}`
  pairs in one wire flush. Per-item verdicts return in input order --
  `:enqueued`, `:duplicate`, or `{:error, :kind}` -- under the same script,
  the same row shape, and the same idempotency as `enqueue/4`. Chapter 3.6.
  """
  def enqueue_many(conn, queue, pairs) when is_list(pairs) do
    {:ok, _} = Connector.command(conn, ["SCRIPT", "LOAD", @enqueue.source])

    cmds =
      for {id, payload} <- pairs do
        [
          "EVALSHA",
          @enqueue.sha,
          "2",
          Keyspace.job_key(queue, id),
          Keyspace.queue_key(queue, "pending"),
          id,
          payload
        ]
      end

    with {:ok, results} <- Connector.pipeline(conn, cmds) do
      {:ok,
       Enum.map(results, fn
         1 -> :enqueued
         0 -> :duplicate
         {:error_reply, "EMQKIND" <> _} -> {:error, :kind}
       end)}
    end
  end

  @claim Script.new(:claim, """
         local popped = redis.call('ZPOPMIN', KEYS[1])
         if #popped == 0 then return {} end
         local id = popped[1]
         local jk = ARGV[1] .. id
         local att = redis.call('HINCRBY', jk, 'attempts', 1)
         redis.call('HSET', jk, 'state', 'active')
         local t = redis.call('TIME')
         local now = t[1] * 1000 + math.floor(t[2] / 1000)
         redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)
         return {id, redis.call('HGET', jk, 'payload'), att}
         """)

  # KEYS[1]=active set, KEYS[2]=row; ARGV[1]=id, ARGV[2]=token, ARGV[3]=p
  # (the queue base). The fan-in hook (emq.3.1) APPENDS, for a flow child
  # only, three host-built declared keys -- KEYS[3]=the parent's :dependencies
  # key, KEYS[4]=the parent's :processed key, KEYS[5]=the parent row -- and
  # ARGV[4]=the parent's bare id, ARGV[5]=the child's result; a non-flow
  # completion passes the shipped two-key call unchanged (KEYS[3] nil), so the
  # flat and grouped-lane branches below are byte-unchanged. The fan-in body
  # sits INSIDE the `was_active == 1` branch the script already computes at
  # ZREM, so the DECR fires exactly once per the child's own active->done
  # transition (a redelivered/stale-token completion never re-enters it --
  # the idempotent fan-in, INV5). No key is read out of a data value: the
  # parent keys are declared KEYS[n] the host built from the child row's
  # `parent` field read HOST-SIDE (S-6/INV2). emq.3.1-D3.
  #
  # The CROSS-QUEUE outbox-emit branch (emq.3.3-D3, D-1/D-4) is ADDITIVE: a
  # cross-queue child's completion cannot atomically reach its parent's
  # OTHER-slot :dependencies (slot({C}) != slot({P}) under the braced keyspace,
  # S-1/§6), so it EMITS instead -- RPUSH the completion entry into the child's
  # OWN-slot outbox `emq:{C}:flow:outbox` (KEYS[3]), atomically with the
  # active-set ZREM above, so a completed cross-queue child ALWAYS has a durable
  # signal (the drop window does not exist, INV7). The host signals this leg by
  # passing ARGV[6]='xq' and the outbox at KEYS[3] (a key the single-queue +
  # non-flow callers NEVER pass), and the branch RETURNS EARLY -- so the
  # single-queue fan-in branch below (`if KEYS[3] and was_active == 1`) is
  # NEVER reached for a cross-queue child even though its outbox occupies the
  # KEYS[3] slot the single-queue branch reads as :dependencies (the dense Lua
  # KEYS array forces the outbox to KEYS[3]; the ARGV marker, not key-presence,
  # is the unambiguous dispatch). The emit is gated on `was_active == 1` exactly
  # as the single-queue DECR is, so a redelivered/stale completion emits no
  # phantom signal; the shared tail (DEL KEYS[2] + metrics:completed HINCRBY) is
  # replicated VERBATIM so the row retires and the metric increments as on every
  # path. The single-queue fan-in branch (jobs.ex below) and the non-flow path
  # stay BYTE-UNCHANGED -- only ADDED lines (INV3). The entry is a NUL-joined
  # tuple (parent_queue \\0 parent_id \\0 child_id \\0 result) the sweep splits
  # HOST-SIDE; NUL cannot occur in a branded id or a queue name (the §6
  # charset), so it is an unambiguous field separator. emq.3.3-D3.
  @complete Script.new(:complete, """
            local att = redis.call('HGET', KEYS[2], 'attempts')
            if not att then return 0 end
            if att ~= ARGV[2] then
              return redis.error_reply('EMQSTALE complete token mismatch')
            end
            local p = ARGV[3]
            local g = redis.call('HGET', KEYS[2], 'group')
            local was_active = redis.call('ZREM', KEYS[1], ARGV[1])
            if g then
              local lane = p .. 'g:' .. g .. ':pending'
              if was_active == 1 then
                local act = redis.call('HINCRBY', p .. 'gactive', g, -1)
                if act <= 0 then redis.call('HDEL', p .. 'gactive', g) end
                if redis.call('SISMEMBER', p .. 'paused', g) == 0 and redis.call('ZCARD', lane) > 0 then
                  local lim = redis.call('HGET', p .. 'glimit', g)
                  if (not lim or act < tonumber(lim)) and not redis.call('LPOS', p .. 'ring', g) then
                    redis.call('RPUSH', p .. 'ring', g)
                    redis.call('LPUSH', p .. 'wake', '1')
                    redis.call('LTRIM', p .. 'wake', 0, 63)
                  end
                end
              else
                redis.call('ZREM', lane, ARGV[1])
                if redis.call('ZCARD', lane) == 0 then redis.call('LREM', p .. 'ring', 0, g) end
              end
            else
              if was_active == 0 then redis.call('ZREM', p .. 'pending', ARGV[1]) end
            end
            if ARGV[6] == 'xq' then
              if was_active == 1 then
                redis.call('RPUSH', KEYS[3], ARGV[7] .. '\\0' .. ARGV[4] .. '\\0' .. ARGV[1] .. '\\0' .. ARGV[5])
              end
              redis.call('DEL', KEYS[2])
              redis.call('HINCRBY', p .. 'metrics:completed', 'count', 1)
              return 1
            end
            if KEYS[3] and was_active == 1 then
              local left = redis.call('DECR', KEYS[3])
              redis.call('HSET', KEYS[4], ARGV[1], ARGV[5])
              if left <= 0 then
                redis.call('ZADD', p .. 'pending', 0, ARGV[4])
                redis.call('HSET', KEYS[5], 'state', 'pending')
              end
            end
            redis.call('DEL', KEYS[2])
            redis.call('HINCRBY', p .. 'metrics:completed', 'count', 1)
            return 1
            """)

  # KEYS[1]=active, KEYS[2]=schedule, KEYS[3]=dead, KEYS[4]=the child row;
  # ARGV[1]=id, ARGV[2]=token, ARGV[3]=delay, ARGV[4]=max, ARGV[5]=error,
  # ARGV[6]=p (the queue base). The CROSS-FLOW FAILURE-PROPAGATION branch
  # (emq.3.4-D3/D4) is ADDITIVE: when a FLOW child dead-letters (lands in its
  # OWN morgue, the byte-frozen body below), the host signals the death to the
  # parent by APPENDING a flow marker (ARGV[7]) and the per-arm keys/ARGV the
  # shipped + non-flow + completing callers NEVER pass -- so a non-flow retry's
  # @retry is byte-identical end to end, the branch unreached (ARGV[7] nil). The
  # marker ARGV[7] encodes the ARM and the POLICY in one field: 'sq:fp'/'sq:id'
  # (a SAME-QUEUE child -- the parent is on the dead child's slot {C}, so the
  # parent fail is atomic in this EVAL) or 'xq:fp'/'xq:id' (a CROSS-QUEUE child
  # -- the parent is on another slot, so this EVAL EMITS a fail-entry into the
  # child's OWN-slot outbox and the sweep delivers it on the parent's slot,
  # eventually-consistent). The branch runs ONLY at-max-attempts (inside the
  # byte-frozen morgue block, AFTER the morgue transition + metrics:failed and
  # BEFORE `return 'dead'`): the child lands in its own morgue FIRST, then the
  # parent is notified. The schedule (non-terminal) arm is byte-unchanged.
  #
  # SAME-QUEUE arm keys (all on the dead child's slot {C}, the parent same-queue
  # -> same hashtag): KEYS[5]=the parent's :failed, KEYS[6]=the parent's
  # :unsuccessful, KEYS[7]=the parent's :dependencies, KEYS[8]=the parent row;
  # ARGV[8]=the parent's bare id. CROSS-QUEUE arm keys (all on the child's slot
  # {C}): KEYS[5]=the child's OWN-slot flow:outbox; ARGV[8]=the parent_queue
  # (DATA, for the fail-entry the sweep rebuilds the parent key from), ARGV[9]=
  # the parent's bare id. No key is read out of a data value (S-6/INV2: the host
  # read the child row's parent/parent_queue/parent_policy fields HOST-SIDE and
  # passes declared keys + the policy ARGV). No script mixes slots. emq.3.4-D3/D4.
  @retry Script.new(:retry, """
         local att = redis.call('HGET', KEYS[4], 'attempts')
         if not att then return redis.error_reply('EMQSTALE job gone') end
         if att ~= ARGV[2] then
           return redis.error_reply('EMQSTALE retry token mismatch')
         end
         local p = ARGV[6]
         local g = redis.call('HGET', KEYS[4], 'group')
         local was_active = redis.call('ZREM', KEYS[1], ARGV[1])
         if g then
           local lane = p .. 'g:' .. g .. ':pending'
           if was_active == 1 then
             local act = redis.call('HINCRBY', p .. 'gactive', g, -1)
             if act <= 0 then redis.call('HDEL', p .. 'gactive', g) end
             if redis.call('SISMEMBER', p .. 'paused', g) == 0 and redis.call('ZCARD', lane) > 0 then
               local lim = redis.call('HGET', p .. 'glimit', g)
               if (not lim or act < tonumber(lim)) and not redis.call('LPOS', p .. 'ring', g) then
                 redis.call('RPUSH', p .. 'ring', g)
                 redis.call('LPUSH', p .. 'wake', '1')
                 redis.call('LTRIM', p .. 'wake', 0, 63)
               end
             end
           else
             redis.call('ZREM', lane, ARGV[1])
             if redis.call('ZCARD', lane) == 0 then redis.call('LREM', p .. 'ring', 0, g) end
           end
         else
           if was_active == 0 then redis.call('ZREM', p .. 'pending', ARGV[1]) end
         end
         redis.call('HSET', KEYS[4], 'last_error', ARGV[5])
         if tonumber(att) >= tonumber(ARGV[4]) then
           redis.call('HSET', KEYS[4], 'state', 'dead')
           redis.call('ZADD', KEYS[3], 0, ARGV[1])
           redis.call('HINCRBY', p .. 'metrics:failed', 'count', 1)
           if ARGV[7] == 'sq:fp' then
             redis.call('HSET', KEYS[5], ARGV[1], ARGV[5])
             redis.call('HSET', KEYS[8], 'state', 'dead')
             redis.call('ZADD', p .. 'dead', 0, ARGV[8])
             redis.call('ZREM', p .. 'pending', ARGV[8])
           elseif ARGV[7] == 'sq:id' then
             redis.call('HSET', KEYS[6], ARGV[1], ARGV[5])
             local left = redis.call('DECR', KEYS[7])
             if left <= 0 then
               redis.call('ZADD', p .. 'pending', 0, ARGV[8])
               redis.call('HSET', KEYS[8], 'state', 'pending')
             end
           elseif ARGV[7] == 'xq:fp' then
             redis.call('RPUSH', KEYS[5], '' .. '\\0' .. 'fail' .. '\\0' .. ARGV[8] .. '\\0' .. ARGV[9] .. '\\0' .. ARGV[1] .. '\\0' .. 'fp' .. '\\0' .. ARGV[5])
           elseif ARGV[7] == 'xq:id' then
             redis.call('RPUSH', KEYS[5], '' .. '\\0' .. 'fail' .. '\\0' .. ARGV[8] .. '\\0' .. ARGV[9] .. '\\0' .. ARGV[1] .. '\\0' .. 'id' .. '\\0' .. ARGV[5])
           end
           return 'dead'
         end
         local t = redis.call('TIME')
         local now = t[1] * 1000 + math.floor(t[2] / 1000)
         redis.call('HSET', KEYS[4], 'state', 'scheduled')
         redis.call('ZADD', KEYS[2], now + tonumber(ARGV[3]), ARGV[1])
         return 'scheduled'
         """)

  @promote Script.new(:promote, """
           local p = ARGV[1]
           local t = redis.call('TIME')
           local now = t[1] * 1000 + math.floor(t[2] / 1000)
           local due = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', now, 'LIMIT', 0, tonumber(ARGV[2]))
           for _, id in ipairs(due) do
             redis.call('ZREM', KEYS[1], id)
             local jk = p .. 'job:' .. id
             local g = redis.call('HGET', jk, 'group')
             if g then
               local lane = p .. 'g:' .. g .. ':pending'
               redis.call('ZADD', lane, 0, id)
               if redis.call('SISMEMBER', p .. 'paused', g) == 0 then
                 local lim = redis.call('HGET', p .. 'glimit', g)
                 local act = tonumber(redis.call('HGET', p .. 'gactive', g) or '0')
                 if (not lim or act < tonumber(lim)) and not redis.call('LPOS', p .. 'ring', g) then
                   redis.call('RPUSH', p .. 'ring', g)
                   redis.call('LPUSH', p .. 'wake', '1')
                   redis.call('LTRIM', p .. 'wake', 0, 63)
                 end
               end
             else
               redis.call('ZADD', KEYS[2], 0, id)
             end
             redis.call('HSET', jk, 'state', 'pending')
           end
           return #due
           """)

  @reap Script.new(:reap, """
        local p = ARGV[1]
        local t = redis.call('TIME')
        local now = t[1] * 1000 + math.floor(t[2] / 1000)
        local exp = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', now, 'LIMIT', 0, 100)
        for _, id in ipairs(exp) do
          redis.call('ZREM', KEYS[1], id)
          local jk = p .. 'job:' .. id
          local g = redis.call('HGET', jk, 'group')
          if g then
            local act = redis.call('HINCRBY', p .. 'gactive', g, -1)
            if act <= 0 then redis.call('HDEL', p .. 'gactive', g) end
            local lane = p .. 'g:' .. g .. ':pending'
            redis.call('ZADD', lane, 0, id)
            if redis.call('SISMEMBER', p .. 'paused', g) == 0 then
              local lim = redis.call('HGET', p .. 'glimit', g)
              if (not lim or act < tonumber(lim)) and not redis.call('LPOS', p .. 'ring', g) then
                redis.call('RPUSH', p .. 'ring', g)
                redis.call('LPUSH', p .. 'wake', '1')
                redis.call('LTRIM', p .. 'wake', 0, 63)
              end
            end
          else
            redis.call('ZADD', KEYS[2], 0, id)
          end
          redis.call('HSET', jk, 'state', 'pending')
        end
        return #exp
        """)

  @doc """
  Pop the oldest pending job: lease on the server clock, attempts as the
  fencing token. The queue-wide pause flag (`emq:{q}:meta` field `paused`,
  set by `EchoMQ.Admin.pause/2`) is honored FIRST: a paused queue answers
  `:empty` even with a non-empty pending set, and the pending set is left
  unmutated -- the separate-gate form (emq.2.2-D2), which keeps the shipped
  `@claim` script byte-unchanged. emq.2.2-D2.
  """
  def claim(conn, queue, lease_ms) when is_integer(lease_ms) and lease_ms > 0 do
    if paused?(conn, queue) do
      :empty
    else
      keys = [Keyspace.queue_key(queue, "pending"), Keyspace.queue_key(queue, "active")]
      argv = [Keyspace.queue_key(queue, "job:"), Integer.to_string(lease_ms)]

      case Connector.eval(conn, @claim, keys, argv) do
        {:ok, []} -> :empty
        {:ok, [id, payload, att]} -> {:ok, {id, payload, att}}
        other -> other
      end
    end
  end

  @doc """
  Whether the whole queue is paused: the `paused` field on `emq:{q}:meta`
  (set by `EchoMQ.Admin.pause/2`, cleared by `resume/2`). The claim path
  reads this first; `EchoMQ.Lanes.claim/3` reads it too, so a queue-wide
  pause gates both the flat and the grouped claim. emq.2.2-D2.
  """
  def paused?(conn, queue) do
    case Connector.command(conn, ["HGET", Keyspace.queue_key(queue, "meta"), "paused"]) do
      {:ok, nil} -> false
      {:ok, _} -> true
      _ -> false
    end
  end

  @doc """
  Retire the row -- only the current token holder may. When the job is a flow
  child (its row carries a `parent` field, written by `EchoMQ.Flows.add/3`),
  the parent's branded id is read HOST-SIDE here and the parent's declared
  `:dependencies`/`:processed` keys + row are passed to `@complete`, which
  decrements the parent's outstanding-child count idempotently and, at zero,
  releases the parent to `pending` (the fan-in hook). A non-flow job has no
  `parent` field, so the shipped two-key completion runs byte-unchanged -- no
  key is ever read out of a data value in Lua (S-6/INV2: the host did the row
  read; the script receives only declared keys). emq.3.1-D3.

  The host-side `parent` read is one extra round-trip on every completion
  (flow or not) -- correctness-neutral, and the simplest A-1-clean form
  (complete/4's public arity is unchanged; see emq-3-1 D-5). Folding the
  parent read into the claim result (the worker already holds the row) is a
  carried perf follow-up the read API declines (the optional O2/N2 fold).

  `result` is the flow child's outcome, recorded HOST-SIDE in the parent's
  `:processed` subkey keyed by the child's id -- it is threaded through the
  EXISTING `ARGV[5]` slot the emq.3.1 fan-in hook already `HSET`s into
  `:processed` (`@complete`, `HSET KEYS[4] ARGV[1] ARGV[5]`), so the shipped
  `@complete` Lua body is BYTE-UNCHANGED: only the host-supplied VALUE of
  `ARGV[5]` changes, from the `job_id` presence marker (emq.3.1's O1 bound)
  to the real result `EchoMQ.Flows.children_values/3` reads back. The default
  `nil` keeps the emq.3.1 presence marker (`ARGV[5] = job_id`), so a caller
  passing no result -- every non-flow caller, and a flow child completed
  through the shipped arity -- takes the byte-unchanged path: the non-flow
  job has `KEYS[3]` nil, the fan-in branch unreached, `ARGV[5]` unused. The
  result reaches `:processed` only for a flow child (its `parent` field
  present), the family's single-queue carve. emq.3.2-D4 (Fork R1.B,
  host-only -- no shipped Lua script is edited).

  A CROSS-QUEUE flow child (its row carries a `parent_queue` field, written by
  `EchoMQ.Flows.add/3`, in addition to the `parent` id) cannot fan in
  atomically -- its parent's `:dependencies` lives on a DIFFERENT slot. So
  `complete/5` routes it through the `@complete` cross-queue branch: the host
  supplies the child's OWN-slot outbox key `emq:{queue}:flow:outbox` as the
  declared `KEYS[3]`, plus `ARGV[6] = 'xq'` (the cross-queue dispatch marker
  the single-queue + non-flow callers never pass) and `ARGV[7] =
  parent_queue`, and the script RPUSHes the completion entry into the outbox
  atomically with the active-set ZREM (one EVAL on slot {C}; the drop window
  does not exist -- INV7). The decrement is delivered later, on the PARENT's
  slot, by the sweep (`EchoMQ.Pump.deliver_flow_completions/3` +
  `@flow_deliver`) -- eventually-consistent, NOT atomic across queues (INV5).
  The single-queue (same-slot) flow child still takes the byte-frozen fan-in
  branch (KEYS[3..5] = the parent's same-slot subkeys, no `xq` marker).
  emq.3.3-D3.
  """
  def complete(conn, queue, job_id, token, result \\ nil) do
    keys = [Keyspace.queue_key(queue, "active"), Keyspace.job_key(queue, job_id)]
    argv = [job_id, Integer.to_string(token), Keyspace.queue_key(queue, "")]

    {keys, argv} =
      case parent_of(conn, queue, job_id) do
        nil ->
          {keys, argv}

        {:cross_queue, parent_id, parent_queue} ->
          # the cross-queue leg: KEYS[3] = the child's OWN-slot outbox; the
          # ARGV cross-queue marker + parent_queue let the script emit the
          # signal (the parent keys are NOT passed -- they are on another slot,
          # rebuilt host-side by the sweep's deliver). ARGV[5] carries the
          # result; ARGV[6]='xq' dispatches the emit branch; ARGV[7] the parent
          # queue.
          {keys ++ [Keyspace.queue_key(queue, "flow:outbox")],
           argv ++ [parent_id, result || job_id, "xq", parent_queue]}

        {:same_queue, parent_id, parent_key} ->
          {keys ++ [parent_key <> ":dependencies", parent_key <> ":processed", parent_key],
           argv ++ [parent_id, result || job_id]}
      end

    case Connector.eval(conn, @complete, keys, argv) do
      {:ok, 1} -> :ok
      {:ok, 0} -> {:error, :gone}
      {:error, {:server, "EMQSTALE" <> _}} -> {:error, :stale}
      other -> other
    end
  end

  # The flow parent of a job, read HOST-SIDE from the child row's `parent`
  # field (the bare parent branded id, written by `EchoMQ.Flows.add/3`), plus
  # the `parent_queue` field a CROSS-queue child carries (emq.3.3) -- read in
  # one `HMGET` round-trip. Nil for a non-flow job (no `parent` field) -- the
  # byte-unchanged completion. The two flow shapes:
  #   * `parent_queue` present AND != this queue -> `{:cross_queue, parent_id,
  #     parent_queue}` (the child emits to its own-slot outbox; the parent keys
  #     are on another slot, rebuilt by the sweep's deliver -- never here).
  #   * no `parent_queue`, or `parent_queue` == this queue (a same-queue flow,
  #     or a defensive equality) -> `{:same_queue, parent_id, parent_key}`, the
  #     parent key built through the gated `Keyspace.job_key/2` (raises on an
  #     ill-formed id) -- the emq.3.1 byte-frozen fan-in.
  # The fan-in records the child's completion in the parent's `:processed`
  # subkey keyed by the child's id (the real result the read API serves).
  # emq.3.1-D3, extended emq.3.3-D3.
  defp parent_of(conn, queue, job_id) do
    case Connector.command(conn, ["HMGET", Keyspace.job_key(queue, job_id), "parent", "parent_queue"]) do
      {:ok, [parent_id, parent_queue]}
      when is_binary(parent_id) and is_binary(parent_queue) and parent_queue != queue ->
        {:cross_queue, parent_id, parent_queue}

      {:ok, [parent_id, _parent_queue]} when is_binary(parent_id) ->
        {:same_queue, parent_id, Keyspace.job_key(queue, parent_id)}

      _ ->
        nil
    end
  end

  # The flow parent + the failure POLICY of a job, read HOST-SIDE in one
  # `HMGET` (emq.3.4 -- the retry-path counterpart of `parent_of/3`, which the
  # completion path uses). Reads the child row's `parent`/`parent_queue`/
  # `parent_policy` fields and returns the shape the `@retry` failure branch is
  # driven by; the policy token defaults to `'fp'` (the v1
  # `fail_parent_on_failure` default) when a child carries no `parent_policy`
  # field (a non-emq.3.4 flow child -- byte-compatible). Nil for a non-flow job
  # (no `parent` field) -- the byte-unchanged morgue transition, the failure
  # branch unreached. The shapes:
  #   * `parent_queue` present AND != this queue -> `{:cross_queue, parent_id,
  #     parent_queue, policy}` (the @retry branch EMITS a fail-entry to the
  #     child's own-slot outbox; the parent keys are on another slot, rebuilt by
  #     the sweep's fail-deliver -- never here).
  #   * otherwise (a flow child whose parent shares this queue) ->
  #     `{:same_queue, parent_id, parent_key, policy}`, the parent key built
  #     through the gated `Keyspace.job_key/2`.
  # No key is read out of a data value in Lua (S-6/INV2: the host did the row
  # read; the script receives only declared keys + the policy ARGV). emq.3.4-D3.
  defp parent_fail_of(conn, queue, job_id) do
    case Connector.command(conn, [
           "HMGET",
           Keyspace.job_key(queue, job_id),
           "parent",
           "parent_queue",
           "parent_policy"
         ]) do
      {:ok, [parent_id, parent_queue, policy]}
      when is_binary(parent_id) and is_binary(parent_queue) and parent_queue != queue ->
        {:cross_queue, parent_id, parent_queue, policy_arm(policy)}

      {:ok, [parent_id, _parent_queue, policy]} when is_binary(parent_id) ->
        {:same_queue, parent_id, Keyspace.job_key(queue, parent_id), policy_arm(policy)}

      _ ->
        nil
    end
  end

  # The policy token a flow child carries (`'fp'`/`'id'`), defaulting to the v1
  # `fail_parent_on_failure` (`'fp'`) when absent or unrecognized -- so a flow
  # child written before emq.3.4 (no `parent_policy` field) routes its death by
  # the v1 default.
  defp policy_arm("id"), do: "id"
  defp policy_arm(_), do: "fp"

  @doc """
  The flow parent + the failure POLICY of a node, read HOST-SIDE -- the PUBLIC
  host-read the recursive failure hook (emq.3.5-D4) uses to learn an
  intermediate node's OWN ancestry when that node has been moved to `dead`. It
  is the public face of the existing private `parent_fail_of/3` (the @retry
  path's counterpart of `parent_of/3`): one `HMGET` of the node row's
  `parent`/`parent_queue`/`parent_policy` fields, returning the same shape the
  `@retry` failure branch is driven by, or `nil` for a node with no parent (the
  root, or a non-flow job). `EchoMQ.Pump`'s deliver loop calls this to detect a
  dead node that is itself a flow-child and re-emit its death to ITS parent --
  the multi-level analogue of emq.3.4's one-level propagation.

  The shapes (identical to the private form):
    * `{:cross_queue, parent_id, parent_queue, policy}` -- the node's parent runs
      in a DIFFERENT queue (the re-emit RPUSHes a fail-entry into the node's
      own-slot outbox, delivered on the parent's slot by the sweep);
    * `{:same_queue, parent_id, parent_key, policy}` -- the node's parent shares
      its queue (the parent_key built through the gated `Keyspace.job_key/2`).
    * `nil` -- the node carries no `parent` field (recursion stops -- the root).

  `policy` is the node's OWN failure policy toward its parent (`'fp'`/`'id'`,
  the `parent_policy` field, defaulting `'fp'`). No key is read out of a data
  value in Lua -- the host did the row read; the script the re-emit issues
  receives only declared keys (S-6/INV2). emq.3.5-D4.
  """
  @spec parent_fail_link(GenServer.server(), binary(), binary()) ::
          {:cross_queue, binary(), binary(), binary()}
          | {:same_queue, binary(), binary(), binary()}
          | nil
  def parent_fail_link(conn, queue, job_id) when is_binary(queue) and is_binary(job_id) do
    parent_fail_of(conn, queue, job_id)
  end

  @doc """
  Park the job in the schedule or, past max attempts, in the morgue --
  token-fenced. When the job is a FLOW CHILD (its row carries a `parent` field,
  written by `EchoMQ.Flows.add/3`) and it dead-letters (lands in its own
  morgue), the death is PROPAGATED to the parent by the child's failure policy
  (emq.3.4-D3/D4), read HOST-SIDE here (`parent_fail_of/3` reads `parent` /
  `parent_queue` / `parent_policy`):

    * a SAME-QUEUE flow child -> the parent is on the dead child's slot {C}, so
      the parent fail is ATOMIC in the same EVAL: the host appends the parent's
      declared `:failed` / `:unsuccessful` / `:dependencies` / row keys
      (`KEYS[5..8]`) + the marker `'sq:fp'`/`'sq:id'` (ARGV[7]) + the parent's
      bare id (ARGV[8]); the @retry branch records `:failed` + moves the parent
      `dead` (fail_parent_on_failure), or records `:unsuccessful` + DECRs +
      at-zero releases (ignore_dependency_on_failure).
    * a CROSS-QUEUE flow child -> the parent is on ANOTHER slot, so this EVAL
      EMITS a fail-entry into the child's OWN-slot `flow:outbox` (`KEYS[5]`)
      atomically with the morgue transition (one EVAL on {C}, no drop window);
      the host appends the marker `'xq:fp'`/`'xq:id'` (ARGV[7]) + the
      parent_queue DATA (ARGV[8]) + the parent's bare id (ARGV[9]); the sweep's
      `@flow_fail_deliver` applies it on the parent's slot {P}
      (eventually-consistent).

  A NON-FLOW job (no `parent` field) appends NEITHER the keys nor the marker, so
  its `@retry` runs the byte-frozen morgue/schedule path unchanged (the failure
  branch fires only on the host-supplied marker -- INV1/INV3). The failure
  branch runs only at-max-attempts (the schedule arm is byte-unchanged on every
  path); a flow child that merely SCHEDULES a retry (not yet at max) takes the
  byte-frozen schedule arm, its parent untouched until it actually dies.
  emq.3.4-D3/D4.
  """
  def retry(conn, queue, job_id, token, delay_ms, max_attempts, error) do
    keys = [
      Keyspace.queue_key(queue, "active"),
      Keyspace.queue_key(queue, "schedule"),
      Keyspace.queue_key(queue, "dead"),
      Keyspace.job_key(queue, job_id)
    ]

    argv = [
      job_id,
      Integer.to_string(token),
      Integer.to_string(delay_ms),
      Integer.to_string(max_attempts),
      error,
      Keyspace.queue_key(queue, "")
    ]

    parent_link = parent_fail_of(conn, queue, job_id)

    {keys, argv} =
      case parent_link do
        nil ->
          {keys, argv}

        {:same_queue, parent_id, parent_key, policy} ->
          # the parent is same-slot: the host appends the parent's declared
          # keys (all on {C}) + the 'sq:<policy>' marker + the parent's bare id.
          {keys ++
             [
               parent_key <> ":failed",
               parent_key <> ":unsuccessful",
               parent_key <> ":dependencies",
               parent_key
             ], argv ++ ["sq:" <> policy, parent_id]}

        {:cross_queue, parent_id, parent_queue, policy} ->
          # the parent is on another slot: the host appends the child's OWN-slot
          # outbox (KEYS[5]) + the 'xq:<policy>' marker + the parent_queue DATA
          # (ARGV[8], the fail-entry the sweep rebuilds the parent key from) +
          # the parent's bare id (ARGV[9]).
          {keys ++ [Keyspace.queue_key(queue, "flow:outbox")],
           argv ++ ["xq:" <> policy, parent_queue, parent_id]}
      end

    case Connector.eval(conn, @retry, keys, argv) do
      {:ok, "scheduled"} ->
        {:ok, :scheduled}

      {:ok, "dead"} ->
        # The flow-failure ONE-LEVEL propagation just ran in the EVAL above (the
        # `sq:fp`/`sq:id` arm moved the SAME-QUEUE parent, or the `xq:*` arm
        # emitted a fail-entry to this child's outbox). For the RECURSIVE
        # (multi-level) hook (emq.3.5-D4): when this dead child's parent is
        # SAME-QUEUE, the `sq:fp` arm moved that parent to `dead` atomically --
        # but emq.3.4 stops one level. If the parent is itself an intermediate
        # flow node carrying its OWN parent, its death must propagate UP. The
        # host observes that here: `EchoMQ.Pump.on_same_queue_child_death/4`
        # reads the dead child's parent and, when that parent has thereby moved
        # to `dead` AND is itself a flow-child, re-emits the parent's death by
        # the parent's policy over the byte-frozen outbox+sweep+`@flow_fail_deliver`
        # machinery (recursing up every level). It is a NO-OP for a non-flow
        # child, a root, or a CROSS-queue parent (the `xq:*` arm's outbox emit is
        # delivered + re-emitted on the sweep tick by the deliver-loop hook
        # instead). `@retry` is byte-unchanged -- this is the caller's host step
        # at the death observation (Arm A). The call fires only on a SAME-QUEUE
        # flow child's death (`parent_link` already read above), so a non-flow
        # `retry` adds no work.
        case parent_link do
          {:same_queue, _parent_id, _parent_key, _policy} ->
            EchoMQ.Pump.on_same_queue_child_death(conn, queue, job_id, error)

          _ ->
            :ok
        end

        {:ok, :dead}

      {:error, {:server, "EMQSTALE" <> _}} ->
        {:error, :stale}

      other ->
        other
    end
  end

  @doc "Move due scheduled jobs back to pending."
  def promote(conn, queue, batch) when is_integer(batch) and batch > 0 do
    keys = [Keyspace.queue_key(queue, "schedule"), Keyspace.queue_key(queue, "pending")]

    Connector.eval(conn, @promote, keys, [Keyspace.queue_key(queue, ""), Integer.to_string(batch)])
  end

  @doc "Return expired leases to pending -- crash recovery on the server's clock."
  def reap(conn, queue) do
    keys = [Keyspace.queue_key(queue, "active"), Keyspace.queue_key(queue, "pending")]
    Connector.eval(conn, @reap, keys, [Keyspace.queue_key(queue, "")])
  end

  @doc "Newest-first browse over the ids themselves: ZRANGE REV BYLEX, no second index."
  def browse(conn, queue, n) when is_integer(n) and n > 0 do
    key = Keyspace.queue_key(queue, "pending")
    Connector.command(conn, ["ZRANGE", key, "+", "-", "BYLEX", "REV", "LIMIT", "0", Integer.to_string(n)])
  end

  @doc "Pending depth."
  def pending_size(conn, queue) do
    Connector.command(conn, ["ZCARD", Keyspace.queue_key(queue, "pending")])
  end

  # -- the operator job-mutation plane (emq.2.2) ----------------------------
  # Real transitions on the three-field row + the §6 logs subkey. Each is one
  # inline script declaring its keys; the branded id is gated at the key
  # builder (Keyspace.job_key/2 raises on an ill-formed id -- INV5); a missing
  # job answers a typed absent (-1 -> {:error, :gone}, the complete/4
  # convention) and changes nothing (INV6).

  @update_data Script.new(:update_data, """
               if redis.call('EXISTS', KEYS[1]) == 0 then return -1 end
               redis.call('HSET', KEYS[1], 'payload', ARGV[1])
               return 1
               """)

  @doc """
  Replace the job's `payload` field (the v1 `updateData` capability, v1
  `data` -> the as-built `payload`). A transition on the row -- one declared
  key, no set move. A missing job answers `{:error, :gone}`, changing
  nothing. The id is gated at `Keyspace.job_key/2`. emq.2.2-D5.
  """
  def update_data(conn, queue, job_id, payload) when is_binary(payload) do
    case Connector.eval(conn, @update_data, [Keyspace.job_key(queue, job_id)], [payload]) do
      {:ok, 1} -> :ok
      {:ok, -1} -> {:error, :gone}
      other -> other
    end
  end

  @update_progress Script.new(:update_progress, """
                   if redis.call('EXISTS', KEYS[1]) == 0 then return -1 end
                   redis.call('HSET', KEYS[1], 'progress', ARGV[1])
                   redis.call('PUBLISH', ARGV[3] .. 'events',
                     cjson.encode({event = 'progress', job = ARGV[2], progress = ARGV[1]}))
                   return 1
                   """)

  @doc """
  Write the job's `progress` field (the v1 `updateProgress` capability) and
  emit the progress event the watch plane (emq.2.3) subscribes to. A
  transition on the row, one declared key. A missing job answers
  `{:error, :gone}`, changing nothing.

  The registered progress-event contract (emq.2.2-D6/D-5): after the field
  write, the script PUBLISHes on the per-queue events channel
  `emq:{q}:events` the JSON object
  `{"event":"progress","job":"<branded-id>","progress":"<value>"}`
  (`cjson`-encoded). The event NAME rides the payload's `event` field (one
  channel per queue carries every lifecycle event, distinguished by `event`),
  so emq.2.3's `EchoMQ.Events` subscribes once and dispatches on it. The
  channel derives from the declared queue base root; a pub/sub channel is not
  a slot-routed key, so this adds no §6 key type and no new transport -- it
  rides the existing connector RESP3 pub/sub seam (ADR-4). A subscriber-less
  PUBLISH is a no-op (returns 0) until emq.2.3 subscribes. emq.2.2-D6.
  """
  def update_progress(conn, queue, job_id, progress) when is_binary(progress) do
    keys = [Keyspace.job_key(queue, job_id)]
    argv = [progress, job_id, Keyspace.queue_key(queue, "")]

    case Connector.eval(conn, @update_progress, keys, argv) do
      {:ok, 1} -> :ok
      {:ok, -1} -> {:error, :gone}
      other -> other
    end
  end

  @add_log Script.new(:add_log, """
           if redis.call('EXISTS', KEYS[1]) == 0 then return -1 end
           local count = redis.call('RPUSH', KEYS[2], ARGV[1])
           if ARGV[2] ~= '' then
             local keep = tonumber(ARGV[2])
             redis.call('LTRIM', KEYS[2], -keep, -1)
             if keep < count then return keep end
           end
           return count
           """)

  @doc """
  Append a line to the job's logs list (`emq:{q}:job:<id>:logs`, the §6
  `logs` subkey -- the v1 `addLog` capability) and answer the log count.
  With a `keep` argument (> 0), the list is trimmed to the last `keep`
  lines and the trimmed count is returned. Both keys are declared (the row
  for the existence check, the logs list for the append); the id is gated.
  A missing job answers `{:error, :gone}`, changing nothing. emq.2.2-D7.
  """
  def add_log(conn, queue, job_id, line, keep \\ 0)
      when is_binary(line) and is_integer(keep) and keep >= 0 do
    keys = [Keyspace.job_key(queue, job_id), Keyspace.job_key(queue, job_id) <> ":logs"]
    keep_arg = if keep > 0, do: Integer.to_string(keep), else: ""

    case Connector.eval(conn, @add_log, keys, [line, keep_arg]) do
      {:ok, -1} -> {:error, :gone}
      {:ok, n} when is_integer(n) -> {:ok, n}
      other -> other
    end
  end

  @doc """
  Read the job's logs list in append order (`emq:{q}:job:<id>:logs`, the
  read paired with `add_log/5`). A missing job (no row) answers
  `{:error, :gone}`; a job with no logs answers `{:ok, []}`. The id is
  gated at the key builder. emq.2.2-D7.
  """
  def get_job_logs(conn, queue, job_id) do
    row = Keyspace.job_key(queue, job_id)

    case Connector.command(conn, ["EXISTS", row]) do
      {:ok, 0} ->
        {:error, :gone}

      {:ok, 1} ->
        Connector.command(conn, ["LRANGE", row <> ":logs", "0", "-1"])

      other ->
        other
    end
  end

  @remove_job Script.new(:remove_job, """
              local jk = KEYS[1]
              if redis.call('EXISTS', jk) == 0 then return -1 end
              if redis.call('EXISTS', jk .. ':lock') == 1 then
                return redis.error_reply('EMQLOCK job is locked')
              end
              local id = ARGV[1]
              redis.call('ZREM', KEYS[2], id)
              redis.call('ZREM', KEYS[3], id)
              redis.call('ZREM', KEYS[4], id)
              redis.call('ZREM', KEYS[5], id)
              if ARGV[2] ~= '' then
                local dk = KEYS[6]
                if redis.call('GET', dk) == id then redis.call('DEL', dk) end
              end
              redis.call('DEL', jk, jk .. ':logs')
              return 1
              """)

  @doc """
  Remove one job from whichever of the four as-built sets holds it
  (`pending`/`active`/`schedule`/`dead`), delete the row and its §6 `logs`
  subkey, and -- when `dedup_id` is supplied -- release a held dedup key
  (`emq:{q}:de:<dedup_id>`) IFF its value is this job id (the v1 `removeJob`
  capability re-derived against the four sets + declared keys). It **refuses
  a locked job** (`emq:{q}:job:<id>:lock` present -- the §6 `lock` subkey the
  worker-side lock plane writes at emq.2.3) with `{:error, :locked}` (the
  `EMQLOCK` wire class), leaving the job untouched. A missing job answers
  `{:error, :gone}`.

  The as-built three-field row stores no dedup backref, so the dedup key
  cannot be discovered from the row (unlike v1's `HGET deid`); the optional
  `dedup_id` is the caller's -- a caller that parked a dedup key passes it
  (emq.2.2-D8, the declared-keys re-derivation). The id is gated at the key
  builder; one inline script. emq.2.2-D8.
  """
  def remove_job(conn, queue, job_id, dedup_id \\ nil) do
    did = dedup_id || ""

    keys = [
      Keyspace.job_key(queue, job_id),
      Keyspace.queue_key(queue, "pending"),
      Keyspace.queue_key(queue, "active"),
      Keyspace.queue_key(queue, "schedule"),
      Keyspace.queue_key(queue, "dead"),
      Keyspace.queue_key(queue, "de:" <> did)
    ]

    case Connector.eval(conn, @remove_job, keys, [job_id, did]) do
      {:ok, 1} -> :ok
      {:ok, -1} -> {:error, :gone}
      {:error, {:server, "EMQLOCK" <> _}} -> {:error, :locked}
      other -> other
    end
  end

  @reprocess Script.new(:reprocess, """
             local jk = KEYS[1]
             if redis.call('EXISTS', jk) == 0 then return -1 end
             local id = ARGV[1]
             if redis.call('ZREM', KEYS[2], id) ~= 1 then
               return redis.error_reply('EMQSTATE not dead')
             end
             redis.call('HDEL', jk, 'last_error')
             redis.call('HSET', jk, 'state', 'pending')
             redis.call('ZADD', KEYS[3], 0, id)
             return 1
             """)

  # -- the lock-extension verb (the recovery half -- emq.2.3) ----------------
  # Re-score the active-set member to a fresh server-clock deadline so a
  # long-but-alive handler is not reaped mid-work. The v2 lease IS the active
  # score (the @claim re-score, jobs.ex @claim), so the extension re-scores
  # that member -- NEVER a separate :lock string (the v1 mechanism the bus does
  # not have; the :lock subkey survives only as the held-by-a-worker presence
  # marker remove_job reads, written by the worker-side lock plane). The verb
  # reads the server TIME (it touches a lease -- DQ-2c) and is token-fenced on
  # the row's attempts (EMQSTALE on a stale token -- the existing fencing-token
  # wire class, no new class -- the @complete pattern). emq.2.3-D4.

  @extend_lock Script.new(:extend_lock, """
               local att = redis.call('HGET', KEYS[2], 'attempts')
               if not att then return -1 end
               if att ~= ARGV[2] then
                 return redis.error_reply('EMQSTALE extend token mismatch')
               end
               local t = redis.call('TIME')
               local now = t[1] * 1000 + math.floor(t[2] / 1000)
               redis.call('ZADD', KEYS[1], now + tonumber(ARGV[3]), ARGV[1])
               return 1
               """)

  @extend_locks Script.new(:extend_locks, """
                local base = ARGV[1]
                local lease = tonumber(ARGV[2])
                local t = redis.call('TIME')
                local now = t[1] * 1000 + math.floor(t[2] / 1000)
                local failed = {}
                local i = 3
                while i < #ARGV do
                  local id = ARGV[i]
                  local token = ARGV[i + 1]
                  local jk = base .. 'job:' .. id
                  local att = redis.call('HGET', jk, 'attempts')
                  if att and att == token then
                    redis.call('ZADD', KEYS[1], now + lease, id)
                  else
                    table.insert(failed, id)
                  end
                  i = i + 2
                end
                return failed
                """)

  @doc """
  Move a `dead` job back to `pending`: clear the failure field
  (`last_error`), reset the row to `state = pending`, and add the id to the
  pending set at score zero (the v1 `reprocessJob` capability re-derived --
  the bus's only finished-and-retained state is `dead`, so reprocess is
  `dead`->`pending`, the "retry a failed job" surface). It **refuses a job
  not in `dead`** (`{:error, :not_dead}`, the `EMQSTATE` wire class),
  changing nothing. A missing job answers `{:error, :gone}`.

  The queue-wide pause flag is honored by the claim path (D2), so a
  reprocessed job lands `pending` but stays unclaimable while the queue is
  paused -- the reprocess transition itself does not consult the flag (the
  job IS pending; pause gates the future claim). One inline script; the id is
  gated at the key builder. emq.2.2-D9.
  """
  def reprocess_job(conn, queue, job_id) do
    keys = [
      Keyspace.job_key(queue, job_id),
      Keyspace.queue_key(queue, "dead"),
      Keyspace.queue_key(queue, "pending")
    ]

    case Connector.eval(conn, @reprocess, keys, [job_id]) do
      {:ok, 1} -> :ok
      {:ok, -1} -> {:error, :gone}
      {:error, {:server, "EMQSTATE" <> _}} -> {:error, :not_dead}
      other -> other
    end
  end

  @doc """
  Extend a claimed job's lease: re-score the `active`-set member to a fresh
  deadline computed from the server clock (`TIME` inside the script -- never
  the caller's), so a long-but-alive handler is not reaped mid-work (the v1
  `extendLock` capability re-derived). The v2 lease IS the active score, so the
  extension re-scores that member -- never a separate `…:lock` string.

  Token-fenced: only the current attempts-token holder may extend. A stale
  token answers `{:error, :stale}` (the `EMQSTALE` fencing-token wire class --
  no new class, the `complete/4` pattern); a missing row answers
  `{:error, :gone}`. Declared keys `[active, job_key]`; the id is gated at the
  key builder (`Keyspace.job_key/2` -- INV5). emq.2.3-D4.
  """
  def extend_lock(conn, queue, job_id, token, lease_ms)
      when is_integer(lease_ms) and lease_ms > 0 do
    keys = [Keyspace.queue_key(queue, "active"), Keyspace.job_key(queue, job_id)]
    argv = [job_id, Integer.to_string(token), Integer.to_string(lease_ms)]

    case Connector.eval(conn, @extend_lock, keys, argv) do
      {:ok, 1} -> :ok
      {:ok, -1} -> {:error, :gone}
      {:error, {:server, "EMQSTALE" <> _}} -> {:error, :stale}
      other -> other
    end
  end

  @doc """
  Extend many leases in one call (the v1 `extendLocks` capability re-derived):
  re-score each `active`-set member whose attempts-token matches, under one
  server-clock read, and answer `{:ok, failed}` where `failed` is the list of
  job ids whose lease could NOT be extended (a stale token or a gone row). The
  declared key is `[active]`; each per-job key is derived in-script from the
  declared queue base root (`base .. 'job:' .. id`, the A-1 grammar-derived
  rule) -- never the v1 `cmsgpack` form. Each id is gated at the key builder
  (an ill-formed id raises before the wire -- INV5). emq.2.3-D4.

  `held` is a list of `{job_id, token}` pairs (the ids currently tracked).
  """
  def extend_locks(conn, queue, held, lease_ms)
      when is_list(held) and is_integer(lease_ms) and lease_ms > 0 do
    # Gate every id at the key builder before the wire (INV5): an ill-formed id
    # raises here, never reaches a key.
    Enum.each(held, fn {id, _token} -> Keyspace.job_key(queue, id) end)

    pairs =
      Enum.flat_map(held, fn {id, token} -> [id, Integer.to_string(token)] end)

    argv = [Keyspace.queue_key(queue, ""), Integer.to_string(lease_ms) | pairs]

    case Connector.eval(conn, @extend_locks, [Keyspace.queue_key(queue, "active")], argv) do
      {:ok, failed} when is_list(failed) -> {:ok, failed}
      other -> other
    end
  end
end
