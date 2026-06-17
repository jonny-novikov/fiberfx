defmodule EchoStore.RingTest do
  @moduledoc """
  The pure column of the Ring row (echo2-migration.md §5) — the best pure
  M2 suite, no wire: a collecting `apply_fn` observes batches; a gated
  `apply_fn` (blocks until released) makes occupancy, capacity drops, and
  batching deterministic. Ring names are per-test atoms, so the
  persistent_term entries never collide across async tests. Init refusals
  raise in `init/1` and exit the caller — exits are trapped, never
  bare-matched (the hazards bank).
  """
  use ExUnit.Case, async: true

  alias EchoStore.Ring

  defp safe_stop(name) do
    try do
      Ring.stop(name)
    rescue
      ArgumentError -> :ok
    catch
      :exit, _ -> :ok
    end
  end

  test "publish/2 answers :ok and order is preserved across drains" do
    parent = self()
    apply_fn = fn batch -> send(parent, {:batch, batch}) && :ok end
    {:ok, _pid} = Ring.start_link(name: :ring_order, capacity: 8, apply_fn: apply_fn)
    on_exit(fn -> safe_stop(:ring_order) end)

    for i <- 1..5, do: assert(Ring.publish(:ring_order, i) == :ok)

    items =
      Enum.reduce_while(1..5, [], fn _, acc ->
        receive do
          {:batch, batch} ->
            acc = acc ++ batch
            if length(acc) >= 5, do: {:halt, acc}, else: {:cont, acc}
        after
          1_000 -> {:halt, acc}
        end
      end)

    assert items == [1, 2, 3, 4, 5]
  end

  test "a full ring refuses with :dropped, counts it, and occupancy gauges the backlog" do
    parent = self()

    gated = fn batch ->
      send(parent, {:batch, self(), batch})

      receive do
        :go -> :ok
      end
    end

    {:ok, _pid} = Ring.start_link(name: :ring_full, capacity: 2, apply_fn: gated)
    on_exit(fn -> safe_stop(:ring_full) end)

    assert Ring.publish(:ring_full, :a) == :ok
    assert_receive {:batch, applier, [:a]}, 1_000

    # the applier holds :a (head not yet advanced); a second accepted item
    # fills the ring to capacity, the third is refused and counted
    assert Ring.publish(:ring_full, :b) == :ok
    assert Ring.occupancy(:ring_full) == 2
    assert Ring.publish(:ring_full, :c) == :dropped

    send(applier, :go)
    assert_receive {:batch, ^applier, [:b]}, 1_000
    send(applier, :go)

    # the head advances before the applied/batches counters move, and stats/1
    # assembles its map from independent reads — poll the settled counters,
    # never occupancy alone
    stats =
      wait_stats(:ring_full, fn s -> s.occupancy == 0 and s.applied == 2 and s.batches == 2 end)

    assert stats.published == 2
    assert stats.dropped == 1
    assert stats.applied == 2
    assert stats.batches == 2
    assert stats.capacity == 2
    assert stats.max_batch >= 1
  end

  test "wakes are edge-triggered and a busy period drains as one batch" do
    parent = self()

    gated = fn batch ->
      send(parent, {:batch, self(), batch})

      receive do
        :go -> :ok
      end
    end

    {:ok, _pid} = Ring.start_link(name: :ring_batch, capacity: 64, apply_fn: gated)
    on_exit(fn -> safe_stop(:ring_batch) end)

    assert Ring.publish(:ring_batch, :a) == :ok
    assert_receive {:batch, applier, [:a]}, 1_000

    # published into a non-empty ring: no further wake is sent
    for item <- [:b, :c, :d], do: assert(Ring.publish(:ring_batch, item) == :ok)

    send(applier, :go)
    assert_receive {:batch, ^applier, [:b, :c, :d]}, 1_000
    send(applier, :go)

    stats = wait_stats(:ring_batch, fn s -> s.occupancy == 0 end)

    assert stats.wakes <= stats.published
    assert stats.wakes == 1
    assert stats.published == 4
    assert stats.max_batch == 3
  end

  test "stats/1 carries the full key set" do
    {:ok, _pid} = Ring.start_link(name: :ring_keys, capacity: 4, apply_fn: fn _ -> :ok end)
    on_exit(fn -> safe_stop(:ring_keys) end)

    assert Map.keys(Ring.stats(:ring_keys)) |> Enum.sort() ==
             [:applied, :batches, :capacity, :dropped, :max_batch, :occupancy, :published, :wakes]
  end

  test "stop/1 erases the runtime — the producer surface refuses afterward" do
    {:ok, _pid} = Ring.start_link(name: :ring_gone, capacity: 4, apply_fn: fn _ -> :ok end)
    assert :ok = Ring.stop(:ring_gone)

    assert_raise ArgumentError, fn -> Ring.publish(:ring_gone, :x) end
    assert_raise ArgumentError, fn -> Ring.occupancy(:ring_gone) end
  end

  test "init refuses a capacity below 2" do
    Process.flag(:trap_exit, true)

    assert {:error, {%ArgumentError{message: "capacity must be at least 2"}, _stack}} =
             Ring.start_link(name: :ring_cap, capacity: 1, apply_fn: fn _ -> :ok end)
  end

  test "init refuses an apply_fn that does not take one batch" do
    Process.flag(:trap_exit, true)

    assert {:error, {%ArgumentError{message: "apply_fn must take one batch"}, _stack}} =
             Ring.start_link(name: :ring_fn, capacity: 4, apply_fn: fn _a, _b -> :ok end)
  end

  defp wait_stats(name, pred, tries \\ 200) do
    stats = Ring.stats(name)

    cond do
      pred.(stats) -> stats
      tries == 0 -> stats
      true ->
        Process.sleep(5)
        wait_stats(name, pred, tries - 1)
    end
  end
end
