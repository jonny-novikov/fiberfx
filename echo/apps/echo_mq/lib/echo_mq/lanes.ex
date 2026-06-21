defmodule EchoMQ.Lanes do
  @moduledoc """
  Fair lanes: grouped admission and a rotating claim over the same machine.
  A lane is a per-group pending set named by an identity; the ring is the
  rota -- a list holding exactly the lanes that can be served right now
  (nonempty, unpaused, below their concurrency limit) -- and every claim
  rotates it one step before serving, so fairness between identities is
  constructed, never hashed (D-9). Transitions stay `EchoMQ.Jobs`':
  complete, retry, promote, and reap are group-aware and return a lane to
  rotation the moment it becomes serviceable again, pushing a wake for
  any parked consumer. Chapter 3.4.
  """

  alias EchoMQ.{Connector, Keyspace, Script}

  @genqueue Script.new(:genqueue, """
            if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
              return redis.error_reply('EMQKIND job id must be JOB-namespaced')
            end
            if redis.call('EXISTS', KEYS[1]) == 1 then
              return 0
            end
            redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2], 'group', ARGV[3])
            redis.call('ZADD', KEYS[2], 0, ARGV[1])
            if redis.call('SISMEMBER', KEYS[4], ARGV[3]) == 0 then
              local lim = redis.call('HGET', KEYS[5], ARGV[3])
              local act = tonumber(redis.call('HGET', KEYS[6], ARGV[3]) or '0')
              if (not lim or act < tonumber(lim)) and not redis.call('LPOS', KEYS[3], ARGV[3]) then
                redis.call('RPUSH', KEYS[3], ARGV[3])
                redis.call('LPUSH', KEYS[7], '1')
                redis.call('LTRIM', KEYS[7], 0, 63)
              end
            end
            return 1
            """)

  @gclaim Script.new(:gclaim, """
          local g = redis.call('LMOVE', KEYS[1], KEYS[1], 'LEFT', 'RIGHT')
          if not g then return {} end
          local lane = ARGV[1] .. 'g:' .. g .. ':pending'
          local popped = redis.call('ZPOPMIN', lane)
          if #popped == 0 then
            redis.call('LREM', KEYS[1], 0, g)
            return {}
          end
          local id = popped[1]
          local jk = ARGV[1] .. 'job:' .. id
          local att = redis.call('HINCRBY', jk, 'attempts', 1)
          redis.call('HSET', jk, 'state', 'active')
          local t = redis.call('TIME')
          local now = t[1] * 1000 + math.floor(t[2] / 1000)
          redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)
          local act = redis.call('HINCRBY', ARGV[1] .. 'gactive', g, 1)
          local lim = redis.call('HGET', ARGV[1] .. 'glimit', g)
          if lim and act >= tonumber(lim) then
            redis.call('LREM', KEYS[1], 0, g)
          elseif redis.call('ZCARD', lane) == 0 then
            redis.call('LREM', KEYS[1], 0, g)
          end
          return {id, redis.call('HGET', jk, 'payload'), att, g}
          """)

  # The weighted rotation: @gclaim's ring step deepened to a fair SHARE per turn
  # (emq.4.4-D1, Fork B Arm 2 -- the additive weighted multi-pop; @gclaim stays
  # byte-frozen, this is a parallel path). One LMOVE rotates the ring exactly
  # once (the same rota step as @gclaim:38), then the rotated lane is served K
  # heads in this one atomic turn instead of one, where K is the lane's fair
  # share. The weight is read from the gweight HASH (ARGV-rooted on the declared
  # base, the @gclaim gactive/glimit convention at :53-54), absent or below 1
  # clamping to 1 -- a weight is a THROUGHPUT share, never a pause (a zero/parked
  # lane is the operator's @gpause, not a rotation outcome; INV1).
  #
  # K = min(weight, the lane's pending depth, the glimit HEADROOM). The headroom
  # clamp is load-bearing: the weight is a throughput share but glimit is a
  # CONCURRENCY ceiling, so the multi-pop must NEVER push gactive past glimit --
  # K is bounded by (lim - cur) when a limit is set (INV1). With no headroom the
  # lane is at its ceiling: it is de-ringed (the @gclaim:55-56 guard) and skipped,
  # nothing served. The served jobs all share ONE lease deadline computed once
  # from the server clock (the @gclaim:50-52 TIME pattern -- no host timestamp
  # crosses the lease, INV4). gactive is incremented by the ACTUAL count served,
  # then the post-increment re-ring guard runs once (the @gclaim:53-59 ceiling +
  # empty-lane test). Returns a NESTED array of the K served tuples
  # {id, payload, attempts, group} (each isomorphic to @gclaim's flat return);
  # an empty ring, a lane emptied since the LMOVE, or a lane with no headroom all
  # return {} (the host maps to :empty). Every key shares the one {q} slot KEYS[1]
  # pins (the declared base root, A-1). emq.4.4-D1.
  @gwclaim Script.new(:gwclaim, """
           local g = redis.call('LMOVE', KEYS[1], KEYS[1], 'LEFT', 'RIGHT')
           if not g then return {} end
           local lane = ARGV[1] .. 'g:' .. g .. ':pending'
           local depth = redis.call('ZCARD', lane)
           if depth == 0 then
             redis.call('LREM', KEYS[1], 0, g)
             return {}
           end
           local w = tonumber(redis.call('HGET', ARGV[1] .. 'gweight', g) or '1')
           if w < 1 then w = 1 end
           local k = w
           if depth < k then k = depth end
           local lim = redis.call('HGET', ARGV[1] .. 'glimit', g)
           if lim then
             local cur = tonumber(redis.call('HGET', ARGV[1] .. 'gactive', g) or '0')
             local headroom = tonumber(lim) - cur
             if headroom < k then k = headroom end
           end
           if k <= 0 then
             redis.call('LREM', KEYS[1], 0, g)
             return {}
           end
           local t = redis.call('TIME')
           local now = t[1] * 1000 + math.floor(t[2] / 1000)
           local served = {}
           for _ = 1, k do
             local popped = redis.call('ZPOPMIN', lane)
             local id = popped[1]
             local jk = ARGV[1] .. 'job:' .. id
             local att = redis.call('HINCRBY', jk, 'attempts', 1)
             redis.call('HSET', jk, 'state', 'active')
             redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)
             served[#served + 1] = {id, redis.call('HGET', jk, 'payload'), att, g}
           end
           local act = redis.call('HINCRBY', ARGV[1] .. 'gactive', g, k)
           if lim and act >= tonumber(lim) then
             redis.call('LREM', KEYS[1], 0, g)
           elseif redis.call('ZCARD', lane) == 0 then
             redis.call('LREM', KEYS[1], 0, g)
           end
           return served
           """)

  # The grouped (affinity-respecting) batch claim: @gwclaim's grouped multi-pop
  # re-used as a NEW parallel script (emq.5.3-D1, FORK 5.3-A Arm 1 -- additive;
  # @gwclaim/@gclaim stay byte-frozen). One LMOVE rotates the ring exactly once
  # (the same rota step as @gclaim:38 / @gwclaim:88), then the rotated lane is
  # served a homogeneous batch in this one atomic turn -- every member of the
  # batch comes from THAT one lane (INV-Affinity). The ONLY semantic delta over
  # @gwclaim is the meaning of K: @gwclaim's K is the lane's WEIGHT (a fairness
  # throughput share, read from gweight); @gbclaim's K is the lane's full
  # concurrency HEADROOM -- ring-rotated, no caller size, the operator does not
  # pick the group (FORK 5.3-C Arm 1, bclaim/3). So @gbclaim drops the gweight
  # read entirely; K = min(the lane's pending depth, the glimit HEADROOM).
  #
  # The glimit headroom clamp is the same load-bearing ceiling as @gwclaim's: the
  # batch must NEVER push gactive past glimit (INV-Ceiling), so K is bounded by
  # (lim - cur) when a limit is set. A lane with NO glimit set is bounded by its
  # depth alone (its whole backlog is serviceable -- the @gwclaim no-limit case).
  # With no headroom the lane is at its ceiling: it is de-ringed (the @gwclaim:106
  # / @gclaim:55 guard) and skipped, nothing served. The served jobs all share ONE
  # lease deadline computed once from the server clock (the @gclaim:50-52 TIME
  # pattern -- no host timestamp crosses the lease, INV-ServerClock). gactive is
  # incremented by the ACTUAL count served (HINCRBY by k -- the @gwclaim:122
  # form), then the post-increment re-ring guard runs once (the @gwclaim:123-127
  # ceiling + empty-lane test). Returns a NESTED array of the K served tuples
  # {id, payload, attempts, group} (each isomorphic to @gclaim's flat return); an
  # empty ring, a lane emptied since the LMOVE, or a lane with no headroom all
  # return {} (the host maps to :empty). KEYS[1]=ring and KEYS[2]=active are the
  # only braced keys -- they PIN the {q} slot; the lane (ARGV[1]..'g:'..g..
  # ':pending'), gactive, and glimit all derive from the declared base root ARGV[1]
  # by the registered grammar (the @gwclaim:90,100,122 convention -- an ARGV base
  # is slot-sound ONLY because KEYS pin the slot, A-1/L-1). emq.5.3-D1.
  @gbclaim Script.new(:gbclaim, """
           local g = redis.call('LMOVE', KEYS[1], KEYS[1], 'LEFT', 'RIGHT')
           if not g then return {} end
           local lane = ARGV[1] .. 'g:' .. g .. ':pending'
           local depth = redis.call('ZCARD', lane)
           if depth == 0 then
             redis.call('LREM', KEYS[1], 0, g)
             return {}
           end
           local k = depth
           local lim = redis.call('HGET', ARGV[1] .. 'glimit', g)
           if lim then
             local cur = tonumber(redis.call('HGET', ARGV[1] .. 'gactive', g) or '0')
             local headroom = tonumber(lim) - cur
             if headroom < k then k = headroom end
           end
           if k <= 0 then
             redis.call('LREM', KEYS[1], 0, g)
             return {}
           end
           local t = redis.call('TIME')
           local now = t[1] * 1000 + math.floor(t[2] / 1000)
           local served = {}
           for _ = 1, k do
             local popped = redis.call('ZPOPMIN', lane)
             local id = popped[1]
             local jk = ARGV[1] .. 'job:' .. id
             local att = redis.call('HINCRBY', jk, 'attempts', 1)
             redis.call('HSET', jk, 'state', 'active')
             redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)
             served[#served + 1] = {id, redis.call('HGET', jk, 'payload'), att, g}
           end
           local act = redis.call('HINCRBY', ARGV[1] .. 'gactive', g, k)
           if lim and act >= tonumber(lim) then
             redis.call('LREM', KEYS[1], 0, g)
           elseif redis.call('ZCARD', lane) == 0 then
             redis.call('LREM', KEYS[1], 0, g)
           end
           return served
           """)

  # The weight-set script: write the lane's fair-share weight into the gweight
  # HASH (KEYS[1], group -> weight). A weight change never alters a lane's
  # serviceability (serviceable = nonempty AND unpaused AND below-limit, all
  # independent of weight), so -- unlike @glimit -- this path needs NO ring
  # bookkeeping or re-ring. The single declared key roots the whole script (A-1
  # trivial). emq.4.4-D1.
  @gweight Script.new(:gweight, """
           redis.call('HSET', KEYS[1], ARGV[1], ARGV[2])
           return 1
           """)

  @gpause Script.new(:gpause, """
          redis.call('SADD', KEYS[1], ARGV[1])
          redis.call('LREM', KEYS[2], 0, ARGV[1])
          return 1
          """)

  @gresume Script.new(:gresume, """
           redis.call('SREM', KEYS[1], ARGV[2])
           local lane = ARGV[1] .. 'g:' .. ARGV[2] .. ':pending'
           if redis.call('ZCARD', lane) > 0 then
             local lim = redis.call('HGET', KEYS[3], ARGV[2])
             local act = tonumber(redis.call('HGET', KEYS[4], ARGV[2]) or '0')
             if (not lim or act < tonumber(lim)) and not redis.call('LPOS', KEYS[2], ARGV[2]) then
               redis.call('RPUSH', KEYS[2], ARGV[2])
               redis.call('LPUSH', KEYS[5], '1')
               redis.call('LTRIM', KEYS[5], 0, 63)
             end
           end
           return 1
           """)

  @glimit Script.new(:glimit, """
          redis.call('HSET', KEYS[1], ARGV[2], ARGV[3])
          local act = tonumber(redis.call('HGET', KEYS[2], ARGV[2]) or '0')
          if act >= tonumber(ARGV[3]) then
            redis.call('LREM', KEYS[3], 0, ARGV[2])
          else
            local lane = ARGV[1] .. 'g:' .. ARGV[2] .. ':pending'
            if redis.call('SISMEMBER', KEYS[4], ARGV[2]) == 0 and redis.call('ZCARD', lane) > 0 and
               not redis.call('LPOS', KEYS[3], ARGV[2]) then
              redis.call('RPUSH', KEYS[3], ARGV[2])
              redis.call('LPUSH', KEYS[5], '1')
              redis.call('LTRIM', KEYS[5], 0, 63)
            end
          end
          return 1
          """)

  # The source group is the row's authority -- read it in-script, never passed
  # (arity 4; src cannot mismatch what the row records). The source lane is
  # derived from the ARGV queue base by the registered lane grammar
  # (`base..'g:'..src..':pending'`, the @gclaim convention at :40), rooted on the
  # same {q} slot KEYS[1] pins; the destination lane is a declared KEYS[2] (the
  # host knows and gates dst). The outcome is a numeric sentinel the host maps to
  # an atom -- the @genqueue/update_data return-shape idiom, no error_reply, so
  # the closed wire-class registry stays unextended (INV1):
  #   -1  no row, or a row with no group        -> {:error, :not_found}
  #   -2  the member is not pending in src       -> {:error, :not_pending}
  #    0  dst already equals src                  -> {:ok, :noop}
  #    1  moved                                   -> {:ok, :reassigned}
  # A pending member moves at score 0 (FIFO-by-mint kept) and the row's group is
  # rewritten to dst -- the load-bearing write the later @gclaim/@complete/@retry/
  # @reap read (HGET <row> 'group') to find the lane and the active counter. A
  # claimed (in-flight) member is NOT in src's lane, so ZREM returns 0, the row is
  # left untouched (its gactive sits under src), and -2 is returned. No lease is
  # touched, so no server clock. emq.4.1-D2.
  @greassign Script.new(:greassign, """
             local g = redis.call('HGET', KEYS[1], 'group')
             if not g then return -1 end
             if g == ARGV[2] then return 0 end
             local src_lane = ARGV[3] .. 'g:' .. g .. ':pending'
             if redis.call('ZREM', src_lane, ARGV[1]) == 0 then return -2 end
             redis.call('ZADD', KEYS[2], 0, ARGV[1])
             redis.call('HSET', KEYS[1], 'group', ARGV[2])
             if redis.call('SISMEMBER', KEYS[4], ARGV[2]) == 0 then
               local lim = redis.call('HGET', KEYS[5], ARGV[2])
               local act = tonumber(redis.call('HGET', KEYS[6], ARGV[2]) or '0')
               if (not lim or act < tonumber(lim)) and not redis.call('LPOS', KEYS[3], ARGV[2]) then
                 redis.call('RPUSH', KEYS[3], ARGV[2])
                 redis.call('LPUSH', KEYS[7], '1')
                 redis.call('LTRIM', KEYS[7], 0, 63)
               end
             end
             if redis.call('ZCARD', src_lane) == 0 then
               redis.call('LREM', KEYS[3], 0, g)
             end
             return 1
             """)

  @doc "Grouped admission: one idempotent script -- kind policy, duplicate refusal, the row with its group, the lane entry, and the ring bookkeeping with a wake."
  def enqueue(conn, queue, group, job_id, payload)
      when is_binary(job_id) and is_binary(payload) do
    keys = [
      Keyspace.job_key(queue, job_id),
      lane_key!(queue, group),
      Keyspace.queue_key(queue, "ring"),
      Keyspace.queue_key(queue, "paused"),
      Keyspace.queue_key(queue, "glimit"),
      Keyspace.queue_key(queue, "gactive"),
      Keyspace.queue_key(queue, "wake")
    ]

    case Connector.eval(conn, @genqueue, keys, [job_id, payload, group]) do
      {:ok, 1} -> {:ok, :enqueued}
      {:ok, 0} -> {:ok, :duplicate}
      {:error, {:server, "EMQKIND" <> _}} -> {:error, :kind}
      other -> other
    end
  end

  @doc """
  Rotate the ring one step and serve the head of that lane: lease on the
  server clock, attempts as the fencing token, the group returned beside the
  job. The queue-wide pause flag (`EchoMQ.Jobs.paused?/2`, set by
  `EchoMQ.Admin.pause/2`) is honored FIRST -- a queue-wide pause stops the
  grouped claim too, answering `:empty` with the lanes untouched, distinct
  from the per-group `pause/3` which parks ONE lane (emq.2.2-D2).
  """
  def claim(conn, queue, lease_ms) when is_integer(lease_ms) and lease_ms > 0 do
    if EchoMQ.Jobs.paused?(conn, queue) do
      :empty
    else
      keys = [Keyspace.queue_key(queue, "ring"), Keyspace.queue_key(queue, "active")]
      argv = [Keyspace.queue_key(queue, ""), Integer.to_string(lease_ms)]

      case Connector.eval(conn, @gclaim, keys, argv) do
        {:ok, []} -> :empty
        {:ok, [id, payload, att, group]} -> {:ok, {id, payload, att, group}}
        other -> other
      end
    end
  end

  @doc """
  The weighted rotation: rotate the ring one step and serve the rotated lane its
  fair SHARE in one atomic turn (`claim/3` deepened from one head to K, where K =
  `min(weight, lane depth, glimit headroom)` -- emq.4.4-D1). A higher-weight lane
  is served proportionally more over a window, never all of it; the equal
  round-robin `claim/3` is byte-frozen and coexists (the additive weighted path,
  Fork B Arm 2). The queue-wide pause flag (`EchoMQ.Jobs.paused?/2`) is honored
  FIRST -- a queue-wide pause stops the weighted claim too, answering `:empty`.
  Each served job is leased on the server clock (the shipped `@gclaim` lease
  pattern); the served jobs share the one lease deadline of this turn. Answers
  `{:ok, [{id, payload, attempts, group}, ...]}` with one tuple per served job,
  or `:empty` (an empty ring, a lane emptied since the rotation, or a lane with
  no concurrency headroom -- it is de-ringed and skipped). A weight is set with
  `weight/4`; an unweighted lane serves one head per turn (weight defaults to 1),
  identical to `claim/3`.
  """
  def wclaim(conn, queue, lease_ms) when is_integer(lease_ms) and lease_ms > 0 do
    if EchoMQ.Jobs.paused?(conn, queue) do
      :empty
    else
      keys = [Keyspace.queue_key(queue, "ring"), Keyspace.queue_key(queue, "active")]
      argv = [Keyspace.queue_key(queue, ""), Integer.to_string(lease_ms)]

      case Connector.eval(conn, @gwclaim, keys, argv) do
        {:ok, []} -> :empty
        {:ok, served} when is_list(served) -> {:ok, Enum.map(served, &List.to_tuple/1)}
        other -> other
      end
    end
  end

  @doc """
  The grouped (affinity-respecting) batch claim: rotate the ring one step and
  serve the rotated lane a HOMOGENEOUS batch in one atomic turn -- every member
  of the batch belongs to the ONE group the rotation landed on (the bulk-consume
  axis of the fair-lanes ring -- emq.5.3-D1). The grouped counterpart of the flat
  `EchoMQ.Jobs.claim_batch/4` (which serves a cross-group batch from the flat
  `pending` set): `claim_batch/4` bypasses the ring's per-group `gactive`
  accounting, whereas `bclaim/3` draws from a SINGLE lane and counts the batch
  against that group's ceiling, so bulk consume coexists with fairness.

  Ring-rotated, NOT caller-named (FORK 5.3-C Arm 1): the operator does NOT pass a
  group -- the rotation picks it (fairness-by-construction, the `claim/3`/
  `wclaim/3` round-robin), and the served count is the lane's full `glimit`
  HEADROOM, the direct `wclaim/3` shape with the lane's depth in place of its
  weight. K = `min(lane depth, glimit headroom)`. A lane with no `glimit` set is
  served its whole depth; a lane at its ceiling (no headroom) is de-ringed and
  serves nothing.

  The near-isomorph of `wclaim/3` -- the only delta is K's source: `wclaim/3`
  reads the lane's `gweight` (a throughput share), `bclaim/3` uses the `glimit`
  headroom (the concurrency room). Each served job is leased on the server clock
  (the shipped `@gclaim`/`@gwclaim` `TIME` lease); the served jobs share the one
  lease deadline of this turn. `gactive` is incremented by the ACTUAL count served
  and the `glimit` headroom clamp guarantees a batch NEVER pushes `gactive` past
  `glimit` (INV-Ceiling). The queue-wide pause flag (`EchoMQ.Jobs.paused?/2`,
  set by `EchoMQ.Admin.pause/2`) is honored FIRST -- a queue-wide pause stops the
  grouped batch too, answering `:empty` with the lanes untouched (the `claim/3`/
  `wclaim/3`/`claim_batch/4` precedent). Answers `{:ok, [{id, payload, attempts,
  group}, ...]}` with one tuple per served member (the `wclaim/3` 4-tuple shape),
  or `:empty` (an empty ring, a lane emptied since the rotation, or a lane with no
  concurrency headroom -- it is de-ringed and skipped). The batch is a CLAIM unit,
  not a resolution unit: each member is settled independently over the byte-frozen
  `EchoMQ.Jobs.complete/5`/`retry/7` (the emq.5.1 partial-failure model). A grouped
  batch CONSUMER riding this is a carried follow-up (emq.5.2's `BatchConsumer`
  shapes the flat set), not built here. emq.5.3-D1.
  """
  def bclaim(conn, queue, lease_ms) when is_integer(lease_ms) and lease_ms > 0 do
    if EchoMQ.Jobs.paused?(conn, queue) do
      :empty
    else
      keys = [Keyspace.queue_key(queue, "ring"), Keyspace.queue_key(queue, "active")]
      argv = [Keyspace.queue_key(queue, ""), Integer.to_string(lease_ms)]

      case Connector.eval(conn, @gbclaim, keys, argv) do
        {:ok, []} -> :empty
        {:ok, served} when is_list(served) -> {:ok, Enum.map(served, &List.to_tuple/1)}
        other -> other
      end
    end
  end

  @doc """
  Set the lane's fair-share weight: the rotation serves a higher-weight lane
  proportionally more per turn (`wclaim/3`). Weight is per-LANE, never per-job --
  there is no numeric per-job priority (retired by design); "served more" is a
  property of the identity, not the work. The weight rides the `gweight`
  per-queue HASH (group -> weight), the same key SHAPE as `glimit`/`gactive`, no
  new key family. The group is gated `EchoData.BrandedId.valid?/1` at
  `lane_key!/2` (raises on an ill-formed branded id) before any wire. A weight
  change never alters a lane's serviceability (serviceable is nonempty AND
  unpaused AND below-limit, all weight-independent), so -- unlike `limit/4` -- no
  ring bookkeeping is touched. `w >= 1` (a weight of zero is not a parked lane --
  that is the operator's `pause/3`). Answers `:ok`. emq.4.4-D1.
  """
  def weight(conn, queue, group, w) when is_integer(w) and w >= 1 do
    _ = lane_key!(queue, group)
    keys = [Keyspace.queue_key(queue, "gweight")]

    case Connector.eval(conn, @gweight, keys, [group, Integer.to_string(w)]) do
      {:ok, 1} -> :ok
      other -> other
    end
  end

  @doc "Remove the lane from rotation; its backlog and its in-flight work are untouched."
  def pause(conn, queue, group) do
    _ = lane_key!(queue, group)
    keys = [Keyspace.queue_key(queue, "paused"), Keyspace.queue_key(queue, "ring")]

    case Connector.eval(conn, @gpause, keys, [group]) do
      {:ok, 1} -> :ok
      other -> other
    end
  end

  @doc "Return the lane to rotation if it is serviceable, with a wake for any parked consumer."
  def resume(conn, queue, group) do
    _ = lane_key!(queue, group)

    keys = [
      Keyspace.queue_key(queue, "paused"),
      Keyspace.queue_key(queue, "ring"),
      Keyspace.queue_key(queue, "glimit"),
      Keyspace.queue_key(queue, "gactive"),
      Keyspace.queue_key(queue, "wake")
    ]

    case Connector.eval(conn, @gresume, keys, [Keyspace.queue_key(queue, ""), group]) do
      {:ok, 1} -> :ok
      other -> other
    end
  end

  @doc "Set the lane's concurrency ceiling; lowering it below the live count parks the lane, raising it may return the lane to rotation."
  def limit(conn, queue, group, n) when is_integer(n) and n > 0 do
    _ = lane_key!(queue, group)

    keys = [
      Keyspace.queue_key(queue, "glimit"),
      Keyspace.queue_key(queue, "gactive"),
      Keyspace.queue_key(queue, "ring"),
      Keyspace.queue_key(queue, "paused"),
      Keyspace.queue_key(queue, "wake")
    ]

    case Connector.eval(conn, @glimit, keys, [Keyspace.queue_key(queue, ""), group, Integer.to_string(n)]) do
      {:ok, 1} -> :ok
      other -> other
    end
  end

  @doc """
  Move a pending member from its current lane to `dst_group` in one atomic
  script. The source group is not passed: it is read from the job row's `group`
  field inside the script (the row is authoritative -- `@genqueue` wrote it),
  so the move cannot disagree with what the row records. Both lanes share the
  one `{q}` slot (the group is outside the braces), so a cross-queue move is not
  expressible -- the move is atomic by construction. The job id is gated at
  `Keyspace.job_key/2` and `dst_group` at `lane_key!/2` (each raises on an
  ill-formed branded id) before any wire.

  The member leaves `g:<src>:pending` and enters `g:<dst>:pending` at score 0
  (its mint-ordered place is kept), the row's `group` field is rewritten to
  `dst` (the later `@gclaim`/`@complete`/`@retry`/`@reap` read it to find the
  lane and the active counter), `dst` is returned to the ring if it is
  serviceable (not paused, below its ceiling, not already on the ring) with a
  wake for any parked consumer, and `src` is dropped from the ring if its lane
  is now empty. No lease is touched, so no clock.

    * `{:ok, :reassigned}` -- the member moved
    * `{:ok, :noop}`       -- `dst` already equals the member's lane
    * `{:error, :not_found}`   -- no row, or a row that carries no group
    * `{:error, :not_pending}` -- the member is not pending in its lane (it is
      claimed/in-flight or absent); the row is left untouched, since its active
      count sits under the source group

  Re-aims the RETIRED v1 `changePriority-7`: there is no numeric per-job
  priority -- "matters more now" is a change of lane, mint order is the order
  theorem. emq.4.1-D2.
  """
  def reassign(conn, queue, job_id, dst_group) when is_binary(job_id) do
    keys = [
      Keyspace.job_key(queue, job_id),
      lane_key!(queue, dst_group),
      Keyspace.queue_key(queue, "ring"),
      Keyspace.queue_key(queue, "paused"),
      Keyspace.queue_key(queue, "glimit"),
      Keyspace.queue_key(queue, "gactive"),
      Keyspace.queue_key(queue, "wake")
    ]

    argv = [job_id, dst_group, Keyspace.queue_key(queue, "")]

    case Connector.eval(conn, @greassign, keys, argv) do
      {:ok, 1} -> {:ok, :reassigned}
      {:ok, 0} -> {:ok, :noop}
      {:ok, -1} -> {:error, :not_found}
      {:ok, -2} -> {:error, :not_pending}
      other -> other
    end
  end

  # The lane-scoped destructive drain, the Admin.@drain wipe (admin.ex:84) scoped
  # to ONE lane: ZRANGE the lane's pending set, DEL each member's row + its §6
  # logs subkey (the job key derives from the declared base root KEYS[1] by the
  # A-1 convention), DEL the lane set, and LREM the group from the ring (a drained
  # lane is no longer serviceable -- the contract removes its ring entry). Returns
  # the count drained. Touches ONLY the target lane's pending rows + logs + set +
  # the ring entry: NOT active/in-flight (those are not in the lane), NOT gactive
  # (it counts in-flight, not pending), NOT paused/glimit (the lane's config
  # survives a drain), NOT any sibling lane, NOT the repeat registry. No lease is
  # touched, so no clock. emq.4.1-D5.
  @gdrain Script.new(:gdrain, """
          local base = KEYS[1]
          local ids = redis.call('ZRANGE', KEYS[2], 0, -1)
          for _, id in ipairs(ids) do
            local jk = base .. 'job:' .. id
            redis.call('DEL', jk, jk .. ':logs')
          end
          redis.call('DEL', KEYS[2])
          redis.call('LREM', KEYS[3], 0, ARGV[1])
          return #ids
          """)

  @doc """
  Drain one lane: empty its `g:<group>:pending` set and delete each drained
  member's row and its §6 `logs` subkey, then drop the group from the ring. The
  lane-scoped counterpart of `EchoMQ.Admin.drain/3` (which empties the flat
  `pending` set) -- the `Admin.@drain` wipe scoped to one lane. `active`/in-flight
  members are NOT drained (they are not in the lane -- a claim moved them to
  `active`), so the lane's `gactive` counter, its `paused`/`glimit` config, every
  sibling lane, and the repeat registry all survive; only the target lane's
  pending backlog (rows + logs + set) and its ring entry are removed. The group
  is gated `EchoData.BrandedId.valid?/1` at `lane_key!/2` (raises on an ill-formed
  id) before any wire. Each job key is derived from the declared queue-base root
  (INV5). Answers `{:ok, n}`, the number of members drained. emq.4.1-D5.
  """
  def drain(conn, queue, group) do
    keys = [
      Keyspace.queue_key(queue, ""),
      lane_key!(queue, group),
      Keyspace.queue_key(queue, "ring")
    ]

    case Connector.eval(conn, @gdrain, keys, [group]) do
      {:ok, n} when is_integer(n) -> {:ok, n}
      other -> other
    end
  end

  # The group-scoped stalled-sweep: @reap's group branch (jobs.ex:350-362)
  # byte-modelled into a NEW script with a `g == ARGV[1]` filter, so an operator
  # recovers ONE named tenant's lapsed leases on demand without a queue-wide scan
  # -- @reap and @sweep_stalled stay byte-frozen (emq.4.2-D2). KEYS[1]=active,
  # KEYS[2]=base ('emq:{q}:') -- the lane/gactive/ring/wake/paused/glimit keys and
  # the job row all derive from the declared base root KEYS[2] by the registered
  # grammar (the @gdrain KEYS-rooted A-1 form, never @reap's ARGV-rooted base), so
  # every key shares the one {q} slot KEYS pins. ARGV[1]=the gated target group,
  # ARGV[2]=the scan limit. The server clock (TIME) computes lease expiry (INV2 --
  # no host timestamp crosses the lease).
  #
  # THE REORDER (the load-bearing delta over @reap): @reap ZREMs every expired id
  # it scans (it is the queue-wide reaper -- every lapsed lease is its business);
  # @greap_group reads the row's group FIRST and ZREMs ONLY when `g == ARGV[1]`. A
  # non-matching expired id is SKIPPED -- never ZREM'd -- so it stays in `active`
  # for the queue-wide reaper to recover; evicting a sibling group's expired member
  # here would silently drop it from recovery. INV1 (a no-group job, g=nil, never
  # equals the target) falls out for free. The recovered member returns to ITS OWN
  # lane -- `group` is a PURE READ (no HSET 'group'; only emq.4.1's @greassign
  # rewrites it), so no read-site of `group` drifts. `gactive[g]` is decremented by
  # 1 (the same counter @reap keeps; the post-decrement `act` drives the re-ring
  # ceiling test, byte-identical to @reap). Returns the count RECOVERED (matching),
  # not the count expired. emq.4.2-D2.
  @greap_group Script.new(:greap_group, """
               local base = KEYS[2]
               local target = ARGV[1]
               local t = redis.call('TIME')
               local now = t[1] * 1000 + math.floor(t[2] / 1000)
               local exp = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', now, 'LIMIT', 0, tonumber(ARGV[2]))
               local n = 0
               for _, id in ipairs(exp) do
                 local jk = base .. 'job:' .. id
                 local g = redis.call('HGET', jk, 'group')
                 if g == target then
                   redis.call('ZREM', KEYS[1], id)
                   local act = redis.call('HINCRBY', base .. 'gactive', g, -1)
                   if act <= 0 then redis.call('HDEL', base .. 'gactive', g) end
                   local lane = base .. 'g:' .. g .. ':pending'
                   redis.call('ZADD', lane, 0, id)
                   if redis.call('SISMEMBER', base .. 'paused', g) == 0 then
                     local lim = redis.call('HGET', base .. 'glimit', g)
                     if (not lim or act < tonumber(lim)) and not redis.call('LPOS', base .. 'ring', g) then
                       redis.call('RPUSH', base .. 'ring', g)
                       redis.call('LPUSH', base .. 'wake', '1')
                       redis.call('LTRIM', base .. 'wake', 0, 63)
                     end
                   end
                   redis.call('HSET', jk, 'state', 'pending')
                   n = n + 1
                 end
               end
               return n
               """)

  @doc """
  Recover the expired-lease members of ONE named group on demand: a group-scoped
  stalled-sweep that returns each lapsed-lease member to its OWN lane
  (`emq:{q}:g:<group>:pending`, score 0 -- the mint-ordered place kept), NOT the
  flat `pending`. The group-scoped entry the shipped queue-wide `EchoMQ.Jobs.reap/2`
  and `EchoMQ.Stalled.check/3` lack: a multi-tenant operator recovers ONE crashed
  tenant's in-flight work without a queue-wide scan, the crashed tenant re-queuing
  behind its own identity (fairness -- it never jumps the ring).

  Only the expired-lease members whose row `group` field equals `group` are
  recovered (the `g == ARGV[1]` filter); a sibling group's expired members are
  LEFT in `active` for the queue-wide reaper. Each recovered member leaves
  `active`, returns to its lane at score 0, the group's `gactive` is decremented
  (`HINCRBY <gactive> g -1`, `HDEL` at zero), and the lane is re-rung if
  serviceable (unpaused, below its `glimit`, not already on the ring) with a wake
  for any parked consumer -- the byte-frozen `@reap` group-branch guard. Expiry is
  computed from the server clock (`redis.call('TIME')`); no host timestamp crosses
  the lease. The member returns to its own lane, so the row's `group` is a PURE
  READ (no `HSET 'group'` -- the later `@gclaim`/`@complete`/`@retry`/`@reap`
  readers see the same value).

  The group is gated `EchoData.BrandedId.valid?/1` at `lane_key!/2` (raises on an
  ill-formed branded id) before any wire (the `drain/3` precedent); `active` and
  the declared queue base are the only `KEYS[]`, every other key derived from the
  base root by the registered grammar (INV3 -- no new key family, one `{q}` slot).
  Answers `{:ok, n}`, the number RECOVERED; a well-formed group with no expired
  members answers `{:ok, 0}`, changing nothing. Reuses the proven recovery-into-
  the-lane mechanism (the `stalled_group` scenario), adding only the group-scoping
  filter -- the shipped `@reap`/`@sweep_stalled` are byte-unchanged (INV1). The
  optional `limit` (default 100) bounds the scan, matching the shipped reaper's
  `LIMIT 0 100`. emq.4.2-D2.
  """
  def reap_group(conn, queue, group, limit \\ 100) when is_integer(limit) and limit > 0 do
    keys = [Keyspace.queue_key(queue, "active"), Keyspace.queue_key(queue, "")]
    _ = lane_key!(queue, group)

    case Connector.eval(conn, @greap_group, keys, [group, Integer.to_string(limit)]) do
      {:ok, n} when is_integer(n) -> {:ok, n}
      other -> other
    end
  end

  @doc "Lane depth: pending work parked behind one identity."
  def depth(conn, queue, group) do
    Connector.command(conn, ["ZCARD", lane_key!(queue, group)])
  end

  defp lane_key!(queue, group) do
    if EchoData.BrandedId.valid?(group) do
      Keyspace.queue_key(queue, "g:" <> group <> ":pending")
    else
      raise ArgumentError, "a lane is named by a valid branded id"
    end
  end
end
