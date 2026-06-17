defmodule EchoStore.Ring do
  @moduledoc """
  A bounded ring with one producer and one applier — the part's fifth law
  as a data structure. The producer publishes into preallocated slots and
  advances a tail sequence; the applier drains everything between head and
  tail in one pass, applies the batch in arrival order, and advances head.
  Two atomics carry the sequences, an ETS table carries the slots reused
  by index, and occupancy — tail minus head — is the backpressure gauge,
  readable by anyone at any time.

  Wakes are edge-triggered: the producer sends one `:wake` only when the
  ring transitions from empty, and the applier re-checks the tail after
  every drain before parking, so a busy period costs one message however
  many items flow through it. This is the Disruptor's shape translated to
  the BEAM — sequences, preallocated slots, batched consumption — standing
  beside the bus's park-don't-poll: both replace discovery with arrival.

  When the ring is full the publish is refused and counted, never blocked
  and never overwritten: the broadcast coherence lane this ring serves is
  at-most-once by its substrate's contract, and a counted drop under storm
  preserves that contract where silent overwriting or unbounded queueing
  would trade it for a worse one. Surfaces that cannot accept a drop ride
  the job lane, which does not pass through here.

  The single-producer requirement is structural, not advisory: publish
  must be called from one process only (the table's owner, where pushes
  already serialize). The applier runs `apply_fn` with each ordered batch;
  the function's work races nothing, because nothing else applies.
  """

  use GenServer

  @counters [published: 1, applied: 2, dropped: 3, wakes: 4, batches: 5]

  # -- producer surface (single process only) -------------------------------

  @doc "Publish one item; `:ok`, or `:dropped` with the drop counted when full."
  def publish(name, item) do
    rt = :persistent_term.get({__MODULE__, name})
    tail = :atomics.get(rt.seq, 1)
    head = :atomics.get(rt.seq, 2)

    if tail - head >= rt.capacity do
      :counters.add(rt.counters, @counters[:dropped], 1)
      :dropped
    else
      next = tail + 1
      :ets.insert(rt.slots, {rem(next, rt.capacity), item})
      :atomics.put(rt.seq, 1, next)
      :counters.add(rt.counters, @counters[:published], 1)

      if tail == :atomics.get(rt.seq, 2) do
        send(rt.applier, :wake)
        :counters.add(rt.counters, @counters[:wakes], 1)
      end

      :ok
    end
  end

  @doc "Tail minus head: the items accepted and not yet applied."
  def occupancy(name) do
    rt = :persistent_term.get({__MODULE__, name})
    :atomics.get(rt.seq, 1) - :atomics.get(rt.seq, 2)
  end

  @doc "Counter snapshot plus live occupancy and the largest batch drained."
  def stats(name) do
    rt = :persistent_term.get({__MODULE__, name})

    @counters
    |> Map.new(fn {k, i} -> {k, :counters.get(rt.counters, i)} end)
    |> Map.put(:occupancy, occupancy(name))
    |> Map.put(:max_batch, GenServer.call(rt.applier, :max_batch))
    |> Map.put(:capacity, rt.capacity)
  end

  def stop(name) do
    rt = :persistent_term.get({__MODULE__, name})
    GenServer.stop(rt.applier)
  end

  # -- applier ---------------------------------------------------------------

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, Keyword.put(opts, :name, name))
  end

  @impl true
  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    capacity = Keyword.get(opts, :capacity, 4_096)
    apply_fn = Keyword.fetch!(opts, :apply_fn)

    unless is_function(apply_fn, 1), do: raise(ArgumentError, "apply_fn must take one batch")
    unless capacity >= 2, do: raise(ArgumentError, "capacity must be at least 2")

    slots = :ets.new(:ring_slots, [:set, :public, read_concurrency: false])
    seq = :atomics.new(2, [])
    counters = :counters.new(length(@counters), [:write_concurrency])

    :persistent_term.put({__MODULE__, name}, %{
      seq: seq,
      slots: slots,
      capacity: capacity,
      counters: counters,
      applier: self()
    })

    {:ok,
     %{
       name: name,
       seq: seq,
       slots: slots,
       capacity: capacity,
       counters: counters,
       apply_fn: apply_fn,
       max_batch: 0
     }}
  end

  @impl true
  def handle_info(:wake, state), do: {:noreply, drain(state)}

  @impl true
  def handle_call(:max_batch, _from, state), do: {:reply, state.max_batch, state}

  @impl true
  def terminate(_reason, state) do
    :persistent_term.erase({__MODULE__, state.name})
    :ok
  end

  defp drain(state) do
    head = :atomics.get(state.seq, 2)
    tail = :atomics.get(state.seq, 1)

    if tail == head do
      state
    else
      batch =
        for s <- (head + 1)..tail do
          [{_, item}] = :ets.lookup(state.slots, rem(s, state.capacity))
          item
        end

      :ok = state.apply_fn.(batch)
      :atomics.put(state.seq, 2, tail)
      :counters.add(state.counters, @counters[:applied], length(batch))
      :counters.add(state.counters, @counters[:batches], 1)

      # re-check before parking: the producer may have published after our
      # tail read and skipped the wake on seeing a non-empty ring
      drain(%{state | max_batch: max(state.max_batch, length(batch))})
    end
  end
end
