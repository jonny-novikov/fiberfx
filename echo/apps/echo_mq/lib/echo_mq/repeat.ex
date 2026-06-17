defmodule EchoMQ.Repeat do
  @moduledoc """
  Repeatable jobs: a registration the bus sweeps, minting a fresh branded
  `JOB` id for every occurrence. A daily report or a periodic reconciliation
  sweep registers once; each run is a first-class, browsable, mint-ordered
  job, because the id mints fresh per occurrence -- never a reused row (id
  reuse would break both the order theorem and the dedup semantics). The
  mint is host-side: ids are producer-minted, the wire never mints.

  Two declared keys, both `{q}`-hashtagged so a queue's repeat state lands on
  its slot:

    * `emq:{q}:repeat` -- a sorted set scored by next-run millisecond, members
      the registration names.
    * `emq:{q}:repeat:<name>` -- a hash carrying `every_ms` and the payload
      `template`.

  The cadence is the pump's (`EchoMQ.Pump`): it reads due registrations off
  the sorted set, mints and enqueues each occurrence, and advances the score
  by `every_ms`. This module owns the registry verbs and the two scripts the
  pump composes -- registration, cancellation, the due read, and the advance.
  Chapter 3.7.
  """

  alias EchoMQ.{Connector, Keyspace, Script}

  @register Script.new(:repeat_register, """
            if redis.call('EXISTS', KEYS[2]) == 1 then
              return 0
            end
            redis.call('HSET', KEYS[2], 'every_ms', ARGV[2], 'template', ARGV[3])
            redis.call('ZADD', KEYS[1], tonumber(ARGV[4]), ARGV[1])
            return 1
            """)

  @cancel Script.new(:repeat_cancel, """
          local removed = redis.call('ZREM', KEYS[1], ARGV[1])
          redis.call('DEL', KEYS[2])
          return removed
          """)

  @advance Script.new(:repeat_advance, """
           if redis.call('EXISTS', KEYS[2]) == 0 then
             redis.call('ZREM', KEYS[1], ARGV[1])
             return 0
           end
           redis.call('ZADD', KEYS[1], tonumber(ARGV[2]), ARGV[1])
           return 1
           """)

  @doc """
  Register a repeatable under `name` with a period and a payload template,
  first occurrence due `first_in_ms` from now (default 0 -- due immediately).
  Idempotent: a second register of a live name answers `:exists` and changes
  nothing. The name is the registry member; the period and template are the
  record.
  """
  def register(conn, queue, name, every_ms, template, first_in_ms \\ 0)
      when is_binary(name) and is_integer(every_ms) and every_ms > 0 and
             is_binary(template) and is_integer(first_in_ms) and first_in_ms >= 0 do
    keys = [Keyspace.queue_key(queue, "repeat"), repeat_key(queue, name)]
    first_at = now_ms() + first_in_ms

    argv = [name, Integer.to_string(every_ms), template, Integer.to_string(first_at)]

    case Connector.eval(conn, @register, keys, argv) do
      {:ok, 1} -> {:ok, :registered}
      {:ok, 0} -> {:ok, :exists}
      other -> other
    end
  end

  @doc """
  Cancel a repeatable: remove the registry member and delete the record, so
  no further occurrence mints and the registration is gone from the declared
  keyspace. Answers `:cancelled` when a live registration was removed,
  `:absent` when there was none.
  """
  def cancel(conn, queue, name) when is_binary(name) do
    keys = [Keyspace.queue_key(queue, "repeat"), repeat_key(queue, name)]

    case Connector.eval(conn, @cancel, keys, [name]) do
      {:ok, 1} -> {:ok, :cancelled}
      {:ok, 0} -> {:ok, :absent}
      other -> other
    end
  end

  @doc """
  Due registrations: the names scored at or before now, oldest-due first, up
  to `limit`, each paired with its `{every_ms, template}` record. The pump's
  read half -- it mints an occurrence per name and advances the score. A name
  whose record has been deleted out of band is skipped (its score is swept by
  `advance/4`).
  """
  def due(conn, queue, limit) when is_integer(limit) and limit > 0 do
    set = Keyspace.queue_key(queue, "repeat")
    now = Integer.to_string(now_ms())

    with {:ok, names} <-
           Connector.command(conn, [
             "ZRANGEBYSCORE",
             set,
             "-inf",
             now,
             "LIMIT",
             "0",
             Integer.to_string(limit)
           ]) do
      records =
        for name <- names do
          {:ok, [every, template]} =
            Connector.command(conn, ["HMGET", repeat_key(queue, name), "every_ms", "template"])

          {name, every, template}
        end

      {:ok, records}
    end
  end

  @doc """
  Advance a registration's next-run score to now plus its period. Answers
  `:advanced` when the record still exists, `:absent` (and sweeps the dangling
  registry member) when it was cancelled mid-sweep. The pump calls this once
  per occurrence it mints.
  """
  def advance(conn, queue, name, every_ms)
      when is_binary(name) and is_integer(every_ms) and every_ms > 0 do
    keys = [Keyspace.queue_key(queue, "repeat"), repeat_key(queue, name)]
    next_at = now_ms() + every_ms

    case Connector.eval(conn, @advance, keys, [name, Integer.to_string(next_at)]) do
      {:ok, 1} -> {:ok, :advanced}
      {:ok, 0} -> {:ok, :absent}
      other -> other
    end
  end

  @doc "Registry depth: how many repeatables are registered on this queue."
  def count(conn, queue) do
    Connector.command(conn, ["ZCARD", Keyspace.queue_key(queue, "repeat")])
  end

  defp repeat_key(queue, name), do: Keyspace.queue_key(queue, "repeat:") <> name

  defp now_ms, do: System.system_time(:millisecond)
end
