defmodule EchoMQ.Metrics do
  @moduledoc """
  The read plane: pure-read verbs over the bus's as-built structures. The
  state machine answers how it is doing without being asked to change: counts
  per state over the four sorted sets, a job and its state by which set holds
  the id, the completed/failed throughput the terminal transitions tally, the
  dedup id parked for a key, the rate-limit TTL, and a read-and-refuse gate at
  the concurrency ceiling. Every verb observes; none mutates -- the structures
  are emq.1's, the transitions are emq.1's, and the only write the read plane
  earns is the terminal-outcome counter the completion and dead-letter
  transitions now keep, so a metric read is never a phantom. Every read script
  declares its keys; an unregistered state name is an error, never an open
  concatenation. emq.2.1 (the introspection & metrics plane).
  """

  alias EchoMQ.{Connector, Keyspace, Lanes, Script}

  # The counts contract: the closed set of state names the bus answers. The
  # four as-built sets (ZCARD) plus the two metrics counters for the terminal
  # outcomes completion-deletes leave no set for. NOT the v1 getCounts list --
  # the bus has no wait/prioritized/waiting-children/completed-set (emq.2.1 D3,
  # design.md §6 closed registry).
  @set_states ~w(pending active schedule dead)
  @metric_states ~w(completed failed)

  @counts Script.new(:counts, """
          -- KEYS[1] = queue base 'emq:{q}:' (the declared slot root); KEYS[2..]
          -- = the set keys to ZCARD. ARGV[1..] = metric names, each read from
          -- the DECLARED KEYS[1] root so the {q} slot is pinned even when no
          -- set key is requested (S-6 declared-keys, slot-sound).
          local base = KEYS[1]
          local out = {}
          for i = 2, #KEYS do
            out[#out + 1] = redis.call('ZCARD', KEYS[i])
          end
          for i = 1, #ARGV do
            out[#out + 1] = tonumber(redis.call('HGET', base .. 'metrics:' .. ARGV[i], 'count') or '0')
          end
          return out
          """)

  @doc """
  Count per requested state name over the as-built structures. The set states
  (`pending`/`active`/`schedule`/`dead`) read `ZCARD` of their sorted set; the
  metric states (`completed`/`failed`) read the terminal-outcome counter
  (completion-deletes leave no set). The queue base is declared as `KEYS[1]`
  (the slot root) and the set keys at `KEYS[2..]`, so even a metric-only request
  pins the `{q}` slot (declared keys, S-6); an unregistered state name is
  `{:error, {:unknown_state, name}}`, never an open concatenation. A pure read.
  emq.2.1-D2.
  """
  @spec get_counts(GenServer.server(), binary(), [binary()]) ::
          {:ok, %{binary() => non_neg_integer()}} | {:error, term()}
  def get_counts(conn, queue, states) when is_binary(queue) and is_list(states) do
    with :ok <- validate_states(states) do
      {sets, metrics} = Enum.split_with(states, &(&1 in @set_states))
      base = Keyspace.queue_key(queue, "")
      keys = [base | Enum.map(sets, &Keyspace.queue_key(queue, &1))]

      case Connector.eval(conn, @counts, keys, metrics) do
        {:ok, counts} ->
          ordered = sets ++ metrics
          {:ok, ordered |> Enum.zip(counts) |> Map.new()}

        other ->
          other
      end
    end
  end

  defp validate_states(states) do
    case Enum.find(states, &(&1 not in @set_states and &1 not in @metric_states)) do
      nil -> :ok
      bad -> {:error, {:unknown_state, bad}}
    end
  end

  @doc """
  The three-field row for a branded id: `state`/`attempts`/`payload`. The key
  is gated by `BrandedId.valid?/1` at `Keyspace.job_key/2` (an ill-formed id
  raises before any wire). A missing job answers `:absent`, never an exception.
  A pure read. emq.2.1-D3.
  """
  @spec get_job(GenServer.server(), binary(), binary()) ::
          {:ok, map()} | :absent | {:error, term()}
  def get_job(conn, queue, job_id) when is_binary(job_id) do
    key = Keyspace.job_key(queue, job_id)

    case Connector.command(conn, ["HGETALL", key]) do
      {:ok, []} -> :absent
      {:ok, flat} when is_list(flat) -> {:ok, pairs(flat)}
      {:ok, m} when is_map(m) and map_size(m) == 0 -> :absent
      {:ok, m} when is_map(m) -> {:ok, m}
      other -> other
    end
  end

  # After the four set checks miss, the row-FIELD branch (emq.3.1-D4): a flow
  # parent withheld from every set carries `state = awaiting_children` on its
  # row, so the tail reads the row's `state` field and answers
  # 'awaiting_children' ONLY for that exact value; every OTHER extant-row
  # state still reads 'unknown' (a row that exists but sits in no set --
  # in-flight between transitions), so the shipped `unknown_state` verdict (a
  # row whose state field is "active") is byte-unchanged. A row-EXISTENCE
  # check could not tell the two row-in-no-set cases apart; the discriminator
  # is the row's own state field, never row existence.
  @state_lookup Script.new(:state_lookup, """
                local id = ARGV[1]
                if redis.call('ZSCORE', KEYS[1], id) then return 'pending' end
                if redis.call('ZSCORE', KEYS[2], id) then return 'active' end
                if redis.call('ZSCORE', KEYS[3], id) then return 'scheduled' end
                if redis.call('ZSCORE', KEYS[4], id) then return 'dead' end
                local st = redis.call('HGET', KEYS[5], 'state')
                if st == 'awaiting_children' then return 'awaiting_children' end
                if st then return 'unknown' end
                return 'absent'
                """)

  # The exact set of strings `@state_lookup` can return. Mapping the wire
  # string through this closed table (rather than `String.to_existing_atom`)
  # is what GUARANTEES the `awaiting_children` atom exists at runtime (the
  # emq.3.1 row-field branch returns it as a string, and no other compiled
  # code creates that atom -- this literal table is its site), and keeps the
  # read plane honest: an unexpected wire string is a typed error, never an
  # open `to_existing_atom` that could raise. emq.2.1-D3, extended emq.3.1-D4.
  @lookup_states %{
    "pending" => :pending,
    "active" => :active,
    "scheduled" => :scheduled,
    "dead" => :dead,
    "awaiting_children" => :awaiting_children,
    "unknown" => :unknown,
    "absent" => :absent
  }

  @doc """
  The job's state by which set holds the id: `pending`/`active`/`scheduled`/
  `dead`, or `awaiting_children` when the row is a flow parent held out of
  every set until its children complete (the row-field branch, emq.3.1-D4),
  or `absent` when no row exists, or `unknown` when the row exists but sits in
  no set (in-flight between transitions). The id is gated at the key builder.
  One script declaring the four set keys + the row key. A pure read.
  emq.2.1-D3, extended emq.3.1.
  """
  @spec get_job_state(GenServer.server(), binary(), binary()) ::
          {:ok, :pending | :active | :scheduled | :dead | :awaiting_children | :unknown | :absent}
          | {:error, term()}
  def get_job_state(conn, queue, job_id) when is_binary(job_id) do
    keys =
      Enum.map(@set_states, &Keyspace.queue_key(queue, &1)) ++ [Keyspace.job_key(queue, job_id)]

    case Connector.eval(conn, @state_lookup, keys, [job_id]) do
      {:ok, state} when is_binary(state) ->
        case @lookup_states do
          %{^state => atom} -> {:ok, atom}
          _ -> {:error, {:unknown_state, state}}
        end

      other ->
        other
    end
  end

  @doc """
  Throughput for a terminal outcome: the count the completion/dead-letter
  transition tallies at `emq:{q}:metrics:<which>`. `which` is `:completed` or
  `:failed`. Reads the `count` field and the `:data` series length honestly --
  the series is unwritten this rung, so it answers length 0, never a phantom.
  A pure read. emq.2.1-D4.
  """
  @spec get_metrics(GenServer.server(), binary(), :completed | :failed) ::
          {:ok, %{count: non_neg_integer(), data_points: non_neg_integer()}} | {:error, term()}
  def get_metrics(conn, queue, which) when which in [:completed, :failed] do
    suffix = "metrics:" <> Atom.to_string(which)
    hash = Keyspace.queue_key(queue, suffix)
    data = Keyspace.queue_key(queue, suffix <> ":data")

    with {:ok, count} <- Connector.command(conn, ["HGET", hash, "count"]),
         {:ok, points} <- Connector.command(conn, ["LLEN", data]) do
      {:ok, %{count: to_int(count), data_points: to_int(points)}}
    end
  end

  @doc """
  The branded job id parked at `emq:{q}:de:<dedupId>` for a producer-chosen
  idempotency key (`design §2/§6`). Answers `:absent` when no id is parked. A
  pure read -- the dedup-key mutation is emq.2.2's. emq.2.1-D5.
  """
  @spec get_deduplication_job_id(GenServer.server(), binary(), binary()) ::
          {:ok, binary()} | :absent | {:error, term()}
  def get_deduplication_job_id(conn, queue, dedup_id) when is_binary(dedup_id) do
    key = Keyspace.queue_key(queue, "de:" <> dedup_id)

    case Connector.command(conn, ["GET", key]) do
      {:ok, nil} -> :absent
      {:ok, id} when is_binary(id) -> {:ok, id}
      other -> other
    end
  end

  @rate_ttl Script.new(:rate_ttl, """
            local max = tonumber(ARGV[1])
            if max == 0 then
              max = tonumber(redis.call('HGET', KEYS[2], 'max') or '0')
            end
            if max > 0 and max <= tonumber(redis.call('GET', KEYS[1]) or '0') then
              local pttl = redis.call('PTTL', KEYS[1])
              if pttl > 0 then return pttl end
            end
            return 0
            """)

  @doc """
  Remaining rate-limit TTL in ms (`0` = not limited): the limiter string is
  spent down to the configured `max` (read from meta when `max_jobs` is 0); the
  `getRateLimitTtl` capability re-derived against the §6 limiter/meta keys. A
  pure read. emq.2.1-D6.
  """
  @spec get_rate_limit_ttl(GenServer.server(), binary(), non_neg_integer()) ::
          {:ok, non_neg_integer()} | {:error, term()}
  def get_rate_limit_ttl(conn, queue, max_jobs \\ 0)
      when is_integer(max_jobs) and max_jobs >= 0 do
    keys = [Keyspace.queue_key(queue, "limiter"), Keyspace.queue_key(queue, "meta")]

    case Connector.eval(conn, @rate_ttl, keys, [Integer.to_string(max_jobs)]) do
      {:ok, ttl} when is_integer(ttl) -> {:ok, ttl}
      other -> other
    end
  end

  @doc """
  The queue's configured rate limit (`max`) from meta; `0` when unconfigured. A
  pure read. emq.2.1-D6.
  """
  @spec get_global_rate_limit(GenServer.server(), binary()) ::
          {:ok, non_neg_integer()} | {:error, term()}
  def get_global_rate_limit(conn, queue) do
    case Connector.command(conn, ["HGET", Keyspace.queue_key(queue, "meta"), "max"]) do
      {:ok, max} -> {:ok, to_int(max)}
      other -> other
    end
  end

  @is_maxed Script.new(:is_maxed, """
            local cap = tonumber(redis.call('HGET', KEYS[1], 'concurrency') or '0')
            if cap > 0 and redis.call('ZCARD', KEYS[2]) >= cap then
              return redis.error_reply('EMQRATE at concurrency ceiling')
            end
            return 0
            """)

  @doc """
  The concurrency gate, a read-and-refuse: where the active set is at the
  configured ceiling (`meta.concurrency`), the refusal leads with the `EMQRATE`
  wire class (design §5, the additive minor), mapped to `{:error, :rate}`;
  otherwise `:ok`. No state transition, no set member moved -- a read of the
  ceiling and a typed refusal. emq.2.1-D6.
  """
  @spec is_maxed(GenServer.server(), binary()) :: :ok | {:error, :rate} | {:error, term()}
  def is_maxed(conn, queue) do
    keys = [Keyspace.queue_key(queue, "meta"), Keyspace.queue_key(queue, "active")]

    case Connector.eval(conn, @is_maxed, keys, []) do
      {:ok, 0} -> :ok
      {:error, {:server, "EMQRATE" <> _}} -> {:error, :rate}
      other -> other
    end
  end

  @doc """
  Per-lane introspection: pending depth behind one group identity, delegating
  to the as-built `Lanes.depth/2` (which gates the group with `BrandedId`). A
  pure read; no rotation or recovery change. emq.2.1-D7.
  """
  @spec lane_depth(GenServer.server(), binary(), binary()) ::
          {:ok, non_neg_integer()} | {:error, term()}
  def lane_depth(conn, queue, group), do: Lanes.depth(conn, queue, group)

  @lane_counts Script.new(:lane_counts, """
               local base = ARGV[1]
               local out = {}
               for i = 1, #ARGV - 1 do
                 local g = ARGV[i + 1]
                 out[i] = redis.call('ZCARD', base .. 'g:' .. g .. ':pending')
               end
               return out
               """)

  @doc """
  Per-lane pending depth for several groups in one read: a count per group over
  its lane sorted set, derived in-script from the declared queue-base root by
  the registered lane grammar (`base..'g:'..g..':pending'`). Each group id is
  gated by `BrandedId.valid?/1` before the wire. A pure read. emq.2.1-D7.
  """
  @spec lane_depths(GenServer.server(), binary(), [binary()]) ::
          {:ok, %{binary() => non_neg_integer()}} | {:error, term()}
  def lane_depths(conn, queue, groups) when is_list(groups) do
    Enum.each(groups, fn g ->
      unless EchoData.BrandedId.valid?(g) do
        raise ArgumentError, "a lane is named by a valid branded id"
      end
    end)

    base = Keyspace.queue_key(queue, "")

    case Connector.eval(conn, @lane_counts, [base], [base | groups]) do
      {:ok, counts} when is_list(counts) -> {:ok, groups |> Enum.zip(counts) |> Map.new()}
      other -> other
    end
  end

  # -- helpers --------------------------------------------------------------

  defp pairs(flat) when is_list(flat) do
    flat |> Enum.chunk_every(2) |> Map.new(fn [k, v] -> {k, v} end)
  end

  defp to_int(nil), do: 0
  defp to_int(n) when is_integer(n), do: n
  defp to_int(s) when is_binary(s), do: String.to_integer(s)
end
