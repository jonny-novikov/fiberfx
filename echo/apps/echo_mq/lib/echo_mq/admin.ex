defmodule EchoMQ.Admin do
  @moduledoc """
  The operator plane's queue-scope verbs: real lifecycle transitions over the
  whole queue rather than one job's row. An operator runbook drives a queue
  with these -- pause and resume claiming on the entire queue (distinct from
  `EchoMQ.Lanes`' per-group park), drain the pending backlog, and obliterate a
  paused queue down to its keyspace footprint. The per-job mutation verbs
  (update_data/update_progress/add_log/get_job_logs/remove_job/reprocess_job)
  fold onto `EchoMQ.Jobs` beside the state machine they extend; this module is
  their queue-scope twin, the mutation-plane sibling of the `EchoMQ.Metrics`
  read plane.

  The structures are the as-built four sorted sets
  (`pending`/`active`/`schedule`/`dead`) and the §6-registered auxiliary keys
  (`meta`/`metrics:*`/`de:*`/the lane structures/`repeat`/`logs`) -- never a
  v1 BullMQ set name (the bus has no `wait`/`paused`-LIST/`completed`/`failed`/
  `prioritized`/`waiting-children`, and completion-deletes leave no
  `completed`/`failed` set). Every script declares its keys in `KEYS[]` or
  derives them in-script from the declared queue-base root by the §6 grammar
  (slot-sound under braces); every precondition refusal leads with its `EMQ*`
  wire class and changes nothing. emq.2.2 (the lifecycle & mutation-ops plane).
  """

  alias EchoMQ.{Connector, Keyspace, Script}

  # -- queue-wide pause / resume (D2) ---------------------------------------
  # A claim gate over the WHOLE queue: a `paused` field on the queue's `meta`
  # hash (an as-built §6-registered key type -- no new type). The claim path
  # (`EchoMQ.Jobs.claim/3`, `EchoMQ.Lanes.claim/3`) reads it first and answers
  # empty when set; pause never mutates pending, so the backlog survives. This
  # is the separate-gate form (D-2) -- the shipped `@claim`/`@gclaim` scripts
  # are byte-unchanged. Distinct from `EchoMQ.Lanes.pause/3` (which SADDs the
  # per-group `paused` SET + LREMs the ring): this is a meta FIELD, structurally
  # disjoint from that SET.

  @pause Script.new(:queue_pause, """
         redis.call('HSET', KEYS[1], 'paused', '1')
         return 1
         """)

  @resume Script.new(:queue_resume, """
          redis.call('HDEL', KEYS[1], 'paused')
          return 1
          """)

  @doc """
  Pause claiming on the whole queue: set the `paused` field on `emq:{q}:meta`
  so a subsequent `EchoMQ.Jobs.claim/3` (and `EchoMQ.Lanes.claim/3`) answers
  `:empty`. The pending backlog is untouched (pause gates the future claim, it
  does not move members) -- `EchoMQ.Metrics.get_counts/3` reads the same
  pending depth before and after. Idempotent. Distinct from
  `EchoMQ.Lanes.pause/3` (one group); this gates the entire queue. emq.2.2-D2.
  """
  def pause(conn, queue) do
    case Connector.eval(conn, @pause, [Keyspace.queue_key(queue, "meta")], []) do
      {:ok, 1} -> :ok
      other -> other
    end
  end

  @doc """
  Resume claiming on the whole queue: clear the `paused` field on
  `emq:{q}:meta`, so a subsequent claim serves the head of pending again.
  Idempotent. emq.2.2-D2.
  """
  def resume(conn, queue) do
    case Connector.eval(conn, @resume, [Keyspace.queue_key(queue, "meta")], []) do
      {:ok, 1} -> :ok
      other -> other
    end
  end

  # -- drain (D3) -----------------------------------------------------------
  # Empty the pending backlog (and, when asked, the schedule set), deleting
  # each drained job's row + its §6 logs subkey, via ONE inline script
  # declaring KEYS[1] = the queue base (the slot root the job keys derive from
  # by the §6 grammar) + KEYS[2] = pending (+ optional KEYS[3] = schedule).
  # `active` is NOT touched (in flight). The repeat REGISTRY (`emq:{q}:repeat`
  # + `repeat:<name>`) is never deleted, so a drain does not cancel a
  # registered repeatable (D-4's re-derivation: the as-built row stores no
  # job->repeat backref, so the guard protects the registry, not individual
  # already-enqueued occurrences).

  @drain Script.new(:drain, """
         local base = KEYS[1]
         local function wipe(setkey)
           local ids = redis.call('ZRANGE', setkey, 0, -1)
           for _, id in ipairs(ids) do
             local jk = base .. 'job:' .. id
             redis.call('DEL', jk, jk .. ':logs')
           end
           redis.call('DEL', setkey)
           return #ids
         end
         local n = wipe(KEYS[2])
         if KEYS[3] then n = n + wipe(KEYS[3]) end
         return n
         """)

  @doc """
  Drain the pending backlog: empty the `pending` set and delete each drained
  job's row and its §6 `logs` subkey. With `include_schedule: true`, the
  `schedule` set is emptied too. `active` jobs are NOT drained (they are in
  flight). The repeat registry survives -- a registered repeatable keeps
  producing after a drain (D-4). Answers `{:ok, n}`, the number of jobs
  drained. ONE inline script; each job key is derived from the declared queue
  base root (INV4). emq.2.2-D3.
  """
  def drain(conn, queue, opts \\ []) do
    base = Keyspace.queue_key(queue, "")

    keys =
      [base, Keyspace.queue_key(queue, "pending")] ++
        if Keyword.get(opts, :include_schedule, false),
          do: [Keyspace.queue_key(queue, "schedule")],
          else: []

    case Connector.eval(conn, @drain, keys, []) do
      {:ok, n} when is_integer(n) -> {:ok, n}
      other -> other
    end
  end

  # -- obliterate (D4) ------------------------------------------------------
  # Destroy a PAUSED queue: every as-built set + every §6 auxiliary key +
  # every reachable job row, bounded per invocation (returns :more while work
  # remains, :ok when done). Refuses a non-paused queue (`EMQSTATE not paused`)
  # and, unless forced, a queue with live active jobs (`EMQSTATE active jobs
  # present`), each changing nothing. ONE inline script declaring KEYS[1] =
  # meta, KEYS[2] = the queue base root (every other key derives from it).
  # NO `completed`/`failed` set is touched (none exists -- the metrics HASHes
  # are the throughput record, deleted as §6 keys). The fixed-name structure
  # keys derive from the base directly; the OPEN families (lane sets per group,
  # repeat records per name) are read from the live structures that name them
  # (the `ring`/`paused` SET for groups, the `repeat` ZSET for names) and each
  # family key derives from the base -- slot-sound, declared-keys-clean. A lane
  # is a state set too: every `g:<g>:pending` member's row is del_job'd before
  # the lane ZSET is DELed (a grouped-but-unclaimed job lives only there), under
  # the same budget bound -- so no reachable job row leaks (emq.2.2 fix).

  @obliterate Script.new(:obliterate, """
              local meta = KEYS[1]
              local base = KEYS[2]
              if redis.call('HGET', meta, 'paused') == false then
                return redis.error_reply('EMQSTATE not paused')
              end
              local force = ARGV[1] == 'force'
              local budget = tonumber(ARGV[2])

              local function del_job(id)
                local jk = base .. 'job:' .. id
                redis.call('DEL', jk, jk .. ':logs', jk .. ':lock')
              end

              -- active first: refuse on live active jobs unless forced
              local active = base .. 'active'
              local act = redis.call('ZRANGE', active, 0, budget - 1)
              if #act > 0 and not force then
                return redis.error_reply('EMQSTATE active jobs present')
              end
              for _, id in ipairs(act) do del_job(id) end
              if #act > 0 then
                redis.call('ZREM', active, unpack(act))
                budget = budget - #act
                if budget <= 0 then return 1 end
              end

              -- the remaining state sets, bounded
              for _, t in ipairs({'pending', 'schedule', 'dead'}) do
                local sk = base .. t
                local ids = redis.call('ZRANGE', sk, 0, budget - 1)
                for _, id in ipairs(ids) do del_job(id) end
                if #ids > 0 then
                  redis.call('ZREM', sk, unpack(ids))
                  budget = budget - #ids
                  if budget <= 0 then return 1 end
                end
              end

              -- all state sets empty: clear the auxiliary §6 keys and finish.
              -- the OPEN families read from the live structures that name them.
              local groups = {}
              local rg = redis.call('LRANGE', base .. 'ring', 0, -1)
              for _, g in ipairs(rg) do groups[g] = true end
              local pg = redis.call('SMEMBERS', base .. 'paused')
              for _, g in ipairs(pg) do groups[g] = true end
              -- each lane is a state set too: del_job every member's row before
              -- DELing the lane ZSET (a grouped-but-unclaimed job lives ONLY
              -- here, never in a flat set), bounded by the same budget. The row
              -- key derives from the declared base root (slot-sound, A-1-clean).
              for g, _ in pairs(groups) do
                local lane = base .. 'g:' .. g .. ':pending'
                local ids = redis.call('ZRANGE', lane, 0, budget - 1)
                for _, id in ipairs(ids) do del_job(id) end
                if #ids > 0 then
                  redis.call('ZREM', lane, unpack(ids))
                  budget = budget - #ids
                end
                -- DEL the lane only once fully drained; while members remain,
                -- leave it for the next bounded call (:more).
                if redis.call('ZCARD', lane) == 0 then
                  redis.call('DEL', lane)
                else
                  return 1
                end
                if budget <= 0 then return 1 end
              end

              local names = redis.call('ZRANGE', base .. 'repeat', 0, -1)
              for _, n in ipairs(names) do
                redis.call('DEL', base .. 'repeat:' .. n)
              end

              redis.call('DEL',
                base .. 'metrics:completed', base .. 'metrics:completed:data',
                base .. 'metrics:failed', base .. 'metrics:failed:data',
                base .. 'gactive', base .. 'glimit', base .. 'ring',
                base .. 'wake', base .. 'paused', base .. 'repeat',
                base .. 'limiter', base .. 'meta')
              return 0
              """)

  @default_budget 1000

  @doc """
  Obliterate a PAUSED queue: destroy every as-built set
  (`pending`/`active`/`schedule`/`dead`) and every §6 auxiliary key
  (`metrics:*`, `de:*` -- see below, the lane structures, `repeat`/
  `repeat:<name>`, `limiter`, `meta` with the paused flag) and every reachable
  job row + its subkeys. Bounded per invocation by `budget` (default
  #{@default_budget}): answers `:more` while work remains (call again) and
  `:ok` when the queue is gone.

  Refuses a NON-paused queue with `{:error, :not_paused}` (the `EMQSTATE`
  class) and, unless `force: true`, a queue with live `active` jobs with
  `{:error, :active}` -- each changing nothing. There is NO `completed`/
  `failed` set to destroy (the metrics HASHes ARE the throughput record,
  deleted as §6 keys). Every job key derives from the declared queue base
  root; the open key families (lane sets, repeat records) are read from the
  live structures that name them (INV4). emq.2.2-D4.

  Note: a `de:<did>` dedup string with no live referrer is not individually
  discoverable under declared keys (the row stores no backref); dedup keys are
  released at remove-time (`EchoMQ.Jobs.remove_job/4`) and at drain-time, and
  obliterate clears the structure keys -- the bounded-completeness honest limit
  (D-4).
  """
  def obliterate(conn, queue, opts \\ []) do
    force = if Keyword.get(opts, :force, false), do: "force", else: ""
    budget = Keyword.get(opts, :budget, @default_budget)
    keys = [Keyspace.queue_key(queue, "meta"), Keyspace.queue_key(queue, "")]

    case Connector.eval(conn, @obliterate, keys, [force, Integer.to_string(budget)]) do
      {:ok, 0} -> :ok
      {:ok, 1} -> :more
      {:error, {:server, "EMQSTATE not paused" <> _}} -> {:error, :not_paused}
      {:error, {:server, "EMQSTATE active" <> _}} -> {:error, :active}
      other -> other
    end
  end
end
