defmodule EchoMQ.BatchFinishTest do
  @moduledoc """
  The batch RESOLVE half's pure partition core (emq.5.4, INV-Partition): the
  `%{completed, retried, dead, delayed}` classification as a plain function of
  the claimed member ids and the per-member `{verdict, outcome}` map -- no
  process, no clock, no I/O (the `EchoMQ.BatchShaper.Core` pure-core precedent).
  The wire behavior (the dynamic-delay re-score, the token fence, the partition
  driven through the cadence) is the `conformance.ex` `:valkey` suite
  (batch_partition / batch_delay / batch_delay_stale); this pins the pure
  classifier -- exhaustive, disjoint, the `dead` emergence, the absent fail-safe.
  """
  use ExUnit.Case, async: true

  alias EchoMQ.BatchFinish

  doctest EchoMQ.BatchFinish

  describe "partition/2 -- the four buckets" do
    test "routes each verdict/outcome pair to its bucket" do
      ids = ["JOBa", "JOBb", "JOBc", "JOBd"]

      resolved = %{
        "JOBa" => {:ok, :ok},
        "JOBb" => {{:error, "boom"}, {:ok, :scheduled}},
        "JOBc" => {{:error, "boom"}, {:ok, :dead}},
        "JOBd" => {{:delay, 5_000}, :ok}
      }

      assert BatchFinish.partition(ids, resolved) == %{
               completed: ["JOBa"],
               retried: ["JOBb"],
               dead: ["JOBc"],
               delayed: ["JOBd"]
             }
    end

    test "dead EMERGES from the retry outcome, not the caller verdict" do
      # the SAME caller verdict ({:error, _}) lands in DIFFERENT buckets purely
      # by its resolved outcome: a scheduled retry -> retried, a capped retry ->
      # dead. dead is never asserted by the caller.
      ids = ["JOBx", "JOBy"]

      resolved = %{
        "JOBx" => {{:error, "same reason"}, {:ok, :scheduled}},
        "JOBy" => {{:error, "same reason"}, {:ok, :dead}}
      }

      part = BatchFinish.partition(ids, resolved)
      assert part.retried == ["JOBx"]
      assert part.dead == ["JOBy"]
    end
  end

  describe "partition/2 -- exhaustive + disjoint" do
    test "the four buckets are a permutation of the claimed ids (exhaustive)" do
      ids = for n <- 1..12, do: "JOB#{n}"

      resolved =
        Map.new(ids, fn id ->
          outcome =
            case rem(byte_size(id), 4) do
              0 -> {:ok, :ok}
              1 -> {{:error, "e"}, {:ok, :scheduled}}
              2 -> {{:error, "e"}, {:ok, :dead}}
              3 -> {{:delay, 100}, :ok}
            end

          {id, outcome}
        end)

      part = BatchFinish.partition(ids, resolved)
      all = part.completed ++ part.retried ++ part.dead ++ part.delayed
      assert Enum.sort(all) == Enum.sort(ids)
    end

    test "no member appears in two buckets (disjoint)" do
      ids = ["JOBa", "JOBb", "JOBc"]

      resolved = %{
        "JOBa" => {:ok, :ok},
        "JOBb" => {{:delay, 1}, :ok},
        "JOBc" => {{:error, "e"}, {:ok, :dead}}
      }

      part = BatchFinish.partition(ids, resolved)
      all = part.completed ++ part.retried ++ part.dead ++ part.delayed
      assert length(all) == length(Enum.uniq(all))
      assert length(all) == length(ids)
    end

    test "the buckets preserve input order" do
      ids = ["JOBc", "JOBa", "JOBb"]
      resolved = Map.new(ids, fn id -> {id, {:ok, :ok}} end)
      assert BatchFinish.partition(ids, resolved).completed == ["JOBc", "JOBa", "JOBb"]
    end
  end

  describe "partition/2 -- the fail-safe (unprocessed work is never reported completed)" do
    test "a member absent from the outcome map lands in retried" do
      ids = ["JOBa", "JOBb"]
      # JOBb is absent from resolved -> fail-safe retried, NOT completed
      part = BatchFinish.partition(ids, %{"JOBa" => {:ok, :ok}})
      assert part.completed == ["JOBa"]
      assert part.retried == ["JOBb"]
      assert part.dead == []
      assert part.delayed == []
    end

    test "a stale/gone retry outcome reports retried (never silently completed)" do
      # the member is no longer the caller's to complete -- a stale/gone delay or
      # retry outcome is reported retried, never completed
      ids = ["JOBa", "JOBb"]

      resolved = %{
        "JOBa" => {{:error, "e"}, {:error, :stale}},
        "JOBb" => {{:delay, 1}, {:error, :gone}}
      }

      part = BatchFinish.partition(ids, resolved)
      assert part.completed == []
      assert Enum.sort(part.retried) == ["JOBa", "JOBb"]
    end

    test "an empty batch yields four empty buckets" do
      assert BatchFinish.partition([], %{}) == %{
               completed: [],
               retried: [],
               dead: [],
               delayed: []
             }
    end
  end
end
