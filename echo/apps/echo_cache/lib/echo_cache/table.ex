defmodule EchoCache.Table do
  @moduledoc """
  One declared L1 cache over L2 Valkey: cache-aside at ETS speed.

  The read path never enters this process. A hit is a caller-side
  `:ets.lookup` against a public, read-concurrent table — the owner is
  consulted only on a miss, and that is where the second law holds: one
  fill per herd. Concurrent misses on a key coalesce onto a single
  in-flight load; the first caller's flight checks L2, falls through to
  the declared loader, writes both layers, and every waiter reads the one
  answer.

  Rows expire on a jittered clock — `ttl ± ttl·jitter` — so a cohort
  filled together never expires together, and the sweeper reclaims dead
  rows on a fixed tick so memory is bounded by the declaration, not by
  luck. When the table is full and nothing has expired, a fill still
  serves its caller and skips the insert: a full cache degrades to
  pass-through, never to failure.

  Every table declares its kind, and the kind law runs before either
  layer is touched: a wrong-namespace id is refused at the door, the
  series' oldest law riding into the cache unchanged. The coherence mode
  is declared here (`:none` in this chapter) and wired by Chapter 4.2.
  """

  use GenServer

  alias EchoCache.Coherence
  alias EchoCache.Keyspace
  alias EchoCache.Ring
  alias EchoData.BrandedId
  alias EchoMQ.Connector

  @counters [
    hits: 1,
    misses: 2,
    fills: 3,
    l2_hits: 4,
    coalesced: 5,
    swept: 6,
    full_skips: 7,
    sweeps: 8,
    coh_applied: 9,
    coh_stale: 10
  ]

  # -- public surface ------------------------------------------------------

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Read through the cache: L1 hit in the caller's process, otherwise a
  single-flight fill through the owner. Returns `{:ok, value, source}`
  with source `:hit | :l2 | :fill`, or `{:error, :kind}` for a
  wrong-namespace id, or the loader's error.
  """
  def fetch(name, id, timeout \\ 10_000) do
    case EchoCache.spec(name) do
      :error ->
        {:error, :no_such_cache}

      {:ok, spec} ->
        with :ok <- gate(spec.kind, id) do
          now = System.monotonic_time(:millisecond)

          case :ets.lookup(name, id) do
            [{^id, value, expires_at, _version}] when now < expires_at ->
              :counters.add(spec.counters, @counters[:hits], 1)
              {:ok, value, :hit}

            _ ->
              :counters.add(spec.counters, @counters[:misses], 1)
              GenServer.call(name, {:fill, id}, timeout)
          end
        end
    end
  end

  @doc """
  Writer path: set both layers under the declared TTL, framed with the
  write's mint-time version. `put/3` mints the version now, of the table's
  kind — the write is its own event; `put/4` carries the writer's own.
  """
  def put(name, id, value) when is_binary(value) do
    case EchoCache.spec(name) do
      :error -> {:error, :no_such_cache}
      {:ok, spec} -> put(name, id, value, EchoData.BrandedId.generate!(spec.kind))
    end
  end

  def put(name, id, value, <<_::binary-14>> = version) when is_binary(value) do
    case EchoCache.spec(name) do
      :error ->
        {:error, :no_such_cache}

      {:ok, spec} ->
        with :ok <- gate(spec.kind, id),
             do: GenServer.call(name, {:put, id, value, version}, 10_000)
    end
  end

  @doc """
  Apply one coherence message: drop the L1 row if and only if `version` is
  newer than the row's framed version. Idempotent by comparison — the same
  message applied twice answers `:stale` the second time. The L2 row is the
  writer's business: a coherence message means the writer already placed
  the newer value there.
  """
  def apply_coherence(name, id, <<_::binary-14>> = version, timeout \\ 10_000) do
    case EchoCache.spec(name) do
      :error ->
        {:error, :no_such_cache}

      {:ok, spec} ->
        with :ok <- gate(spec.kind, id),
             do: GenServer.call(name, {:coherence, id, version}, timeout)
    end
  end

  @doc """
  A ready handler for the job lane: start an `EchoMQ.Consumer` on
  `Coherence.queue(table)` with this handler and the table rides
  at-least-once coherence. Reapplication after a crash is harmless — the
  comparison answers stale.
  """
  def coherence_handler(name) do
    fn %{payload: payload} ->
      case Coherence.parse(payload) do
        {:ok, id, version} ->
          {:ok, _} = apply_coherence(name, id, version)
          :ok

        :error ->
          raise ArgumentError, "malformed coherence payload"
      end
    end
  end

  @doc """
  Apply one ordered batch of coherence messages caller-side: public ETS
  lookups, mint-time comparisons, deletes, and the spec's counters — no
  owner call anywhere. This is the ring's apply function: the applier
  races the owner's fills and loses nothing, because newer-wins is a
  comparison and every interleaving converges.
  """
  def apply_batch(name, batch) when is_list(batch) do
    {:ok, spec} = EchoCache.spec(name)

    Enum.each(batch, fn {id, version} ->
      case :ets.lookup(name, id) do
        [{^id, _value, _exp, row_version}] ->
          if Coherence.newer?(version, row_version) do
            :ets.delete(name, id)
            :counters.add(spec.counters, @counters[:coh_applied], 1)
          else
            :counters.add(spec.counters, @counters[:coh_stale], 1)
          end

        [] ->
          :counters.add(spec.counters, @counters[:coh_stale], 1)
      end
    end)

    :ok
  end

  @doc "Drop one name from both layers unconditionally — the admin verb."
  def invalidate(name, id, timeout \\ 10_000) do
    case EchoCache.spec(name) do
      :error -> {:error, :no_such_cache}
      {:ok, spec} -> with :ok <- gate(spec.kind, id), do: GenServer.call(name, {:invalidate, id}, timeout)
    end
  end

  @doc "Counter snapshot plus live size."
  def stats(name) do
    {:ok, spec} = EchoCache.spec(name)

    @counters
    |> Map.new(fn {k, i} -> {k, :counters.get(spec.counters, i)} end)
    |> Map.put(:size, :ets.info(name, :size))
  end

  def stop(name), do: GenServer.stop(name)

  # -- owner ---------------------------------------------------------------

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    name = Keyword.fetch!(opts, :name)
    kind = Keyword.fetch!(opts, :kind)
    loader = Keyword.fetch!(opts, :loader)
    ttl_ms = Keyword.get(opts, :ttl_ms, 5_000)
    jitter = Keyword.get(opts, :jitter, 0.1)
    max_size = Keyword.get(opts, :max_size, 100_000)
    sweep_ms = Keyword.get(opts, :sweep_ms, 1_000)
    coherence = Keyword.get(opts, :coherence, :none)

    unless byte_size(kind) == 3, do: raise(ArgumentError, "kind must be a 3-byte namespace")
    unless is_function(loader, 1), do: raise(ArgumentError, "loader must be a 1-arity fun")
    unless jitter >= 0.0 and jitter <= 0.5, do: raise(ArgumentError, "jitter must be in 0.0..0.5")

    {:ok, conn} = Connector.start_link(Keyword.get(opts, :connector, []))

    :ets.new(name, [:set, :public, :named_table, read_concurrency: true])
    counters = :counters.new(length(@counters), [:write_concurrency])

    ring_capacity = Keyword.get(opts, :ring_capacity, 4_096)

    spec = %{
      kind: kind,
      ttl_ms: ttl_ms,
      jitter: jitter,
      max_size: max_size,
      sweep_ms: sweep_ms,
      coherence: coherence,
      ring: if(coherence == :broadcast, do: {:coh, name}),
      ring_capacity: if(coherence == :broadcast, do: ring_capacity),
      counters: counters
    }

    :ok = EchoCache.Directory.register(name, spec, self())
    Process.send_after(self(), :sweep, sweep_ms)

    table_str = Keyword.get(opts, :table, Atom.to_string(name))

    ring =
      if coherence == :broadcast do
        ring_name = {:coh, name}

        {:ok, _applier} =
          Ring.start_link(
            name: ring_name,
            capacity: ring_capacity,
            apply_fn: fn batch -> __MODULE__.apply_batch(name, batch) end
          )

        {:ok, sub} =
          Connector.start_link(
            Keyword.get(opts, :connector, [])
            |> Keyword.merge(protocol: 3, push_to: self(), heartbeat_ms: 0)
          )

        :ok = Connector.subscribe(sub, Coherence.channel(table_str))
        ring_name
      end

    {:ok,
     %{
       name: name,
       table: table_str,
       ring: ring,
       loader: loader,
       conn: conn,
       spec: spec,
       flights: %{}
     }}
  end

  @impl true
  def handle_call({:fill, id}, from, state) do
    now = System.monotonic_time(:millisecond)

    case :ets.lookup(state.name, id) do
      [{^id, value, expires_at, _version}] when now < expires_at ->
        # the race was won between the caller's miss and this call
        :counters.add(state.spec.counters, counter(:hits), 1)
        {:reply, {:ok, value, :hit}, state}

      _ ->
        case Map.fetch(state.flights, id) do
          {:ok, {ref, waiters}} ->
            :counters.add(state.spec.counters, counter(:coalesced), 1)
            {:noreply, put_in(state.flights[id], {ref, [from | waiters]})}

          :error ->
            ref = launch_flight(state, id)
            {:noreply, put_in(state.flights[id], {ref, [from]})}
        end
    end
  end

  def handle_call({:put, id, value, version}, _from, state) do
    l2 = Keyspace.key(state.table, id)

    {:ok, "OK"} =
      Connector.command(state.conn, [
        "SET",
        l2,
        version <> value,
        "PX",
        Integer.to_string(state.spec.ttl_ms)
      ])

    insert(state, id, value, version)
    {:reply, :ok, state}
  end

  def handle_call({:coherence, id, version}, _from, state) do
    {:reply, apply_newer_wins(state, id, version), state}
  end

  def handle_call({:invalidate, id}, _from, state) do
    l2 = Keyspace.key(state.table, id)
    {:ok, _} = Connector.command(state.conn, ["DEL", l2])
    :ets.delete(state.name, id)
    {:reply, :ok, state}
  end

  @impl true
  def handle_info({:flight, id, result}, state) do
    {{ref, waiters}, flights} = Map.pop(state.flights, id)
    Process.demonitor(ref, [:flush])

    reply =
      case result do
        {:l2, value, version} ->
          :counters.add(state.spec.counters, counter(:l2_hits), 1)
          insert(state, id, value, version)
          {:ok, value, :l2}

        {:fill, value, version} ->
          :counters.add(state.spec.counters, counter(:fills), 1)
          insert(state, id, value, version)
          {:ok, value, :fill}

        {:error, _} = err ->
          err
      end

    Enum.each(waiters, &GenServer.reply(&1, reply))
    {:noreply, %{state | flights: flights}}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    case Enum.find(state.flights, fn {_id, {r, _}} -> r == ref end) do
      {id, {^ref, waiters}} ->
        Enum.each(waiters, &GenServer.reply(&1, {:error, {:flight_crashed, reason}}))
        {:noreply, %{state | flights: Map.delete(state.flights, id)}}

      nil ->
        {:noreply, state}
    end
  end

  def handle_info(:sweep, state) do
    now = System.monotonic_time(:millisecond)

    removed =
      :ets.select_delete(state.name, [{{:_, :_, :"$1", :_}, [{:<, :"$1", now}], [true]}])

    :counters.add(state.spec.counters, counter(:swept), removed)
    :counters.add(state.spec.counters, counter(:sweeps), 1)
    Process.send_after(self(), :sweep, state.spec.sweep_ms)
    {:noreply, state}
  end

  def handle_info({:emq_push, ["message", _channel, payload]}, state) do
    case Coherence.parse(payload) do
      {:ok, id, version} -> Ring.publish(state.ring, {id, version})
      :error -> :ignored
    end

    {:noreply, state}
  end

  def handle_info({:emq_push, _confirm_or_other}, state), do: {:noreply, state}

  def handle_info({:EXIT, _pid, reason}, state), do: {:stop, reason, state}

  @impl true
  def terminate(_reason, state) do
    if state.ring do
      try do
        Ring.stop(state.ring)
      catch
        _, _ -> :ok
      end
    end

    EchoCache.Directory.unregister(state.name)
    :ok
  end

  # -- internals -----------------------------------------------------------

  defp launch_flight(state, id) do
    owner = self()
    l2 = Keyspace.key(state.table, id)
    loader = state.loader
    conn = state.conn
    ttl = state.spec.ttl_ms
    kind_version = EchoData.BrandedId.generate!(state.spec.kind)

    {_pid, ref} =
      spawn_monitor(fn ->
        result =
          case Connector.command(conn, ["GET", l2]) do
            {:ok, nil} ->
              loaded =
                case loader.(id) do
                  {:ok, value} when is_binary(value) -> {:ok, value, kind_version}
                  {:ok, value, <<_::binary-14>> = v} when is_binary(value) -> {:ok, value, v}
                  {:error, _} = err -> err
                  other -> {:error, {:bad_loader_result, other}}
                end

              case loaded do
                {:ok, value, version} ->
                  {:ok, "OK"} =
                    Connector.command(conn, [
                      "SET",
                      l2,
                      version <> value,
                      "PX",
                      Integer.to_string(ttl)
                    ])

                  {:fill, value, version}

                {:error, _} = err ->
                  err
              end

            {:ok, <<version::binary-14, value::binary>>} ->
              {:l2, value, version}

            {:ok, _short} ->
              {:error, :corrupt_l2_frame}

            {:error, _} = err ->
              err
          end

        send(owner, {:flight, id, result})
      end)

    ref
  end

  defp insert(state, id, value, version) do
    size = :ets.info(state.name, :size)

    cond do
      size < state.spec.max_size ->
        :ets.insert(state.name, {id, value, expires_at(state.spec), version})

      reclaim(state) > 0 ->
        :ets.insert(state.name, {id, value, expires_at(state.spec), version})

      true ->
        :counters.add(state.spec.counters, counter(:full_skips), 1)
        :skip
    end
  end

  defp apply_newer_wins(state, id, version) do
    case :ets.lookup(state.name, id) do
      [{^id, _value, _exp, row_version}] ->
        if Coherence.newer?(version, row_version) do
          :ets.delete(state.name, id)
          :counters.add(state.spec.counters, counter(:coh_applied), 1)
          {:ok, :applied}
        else
          :counters.add(state.spec.counters, counter(:coh_stale), 1)
          {:ok, :stale}
        end

      [] ->
        :counters.add(state.spec.counters, counter(:coh_stale), 1)
        {:ok, :stale}
    end
  end

  defp reclaim(state) do
    now = System.monotonic_time(:millisecond)
    :ets.select_delete(state.name, [{{:_, :_, :"$1", :_}, [{:<, :"$1", now}], [true]}])
  end

  defp expires_at(spec) do
    base = System.monotonic_time(:millisecond) + spec.ttl_ms
    spread = trunc(spec.ttl_ms * spec.jitter)

    if spread == 0 do
      base
    else
      base + :rand.uniform(2 * spread + 1) - spread - 1
    end
  end

  defp gate(kind, id) do
    if is_binary(id) and byte_size(id) == 14 and binary_part(id, 0, 3) == kind and
         BrandedId.valid?(id) do
      :ok
    else
      {:error, :kind}
    end
  end

  defp counter(key), do: Keyword.fetch!(@counters, key)
end
