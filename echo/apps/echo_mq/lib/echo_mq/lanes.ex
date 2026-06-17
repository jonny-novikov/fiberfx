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
