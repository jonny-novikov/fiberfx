defmodule EchoMQ.CancelTest do
  @moduledoc """
  The v1 `EchoMQ.CancellationToken` test corpus ADOPTED for the v2
  `EchoMQ.Cancel` (emq.2.3-D7, the Operator's "tests v1 adopted and verified").
  Re-derived against the v2 surface: the module is `EchoMQ.Cancel`; the cancel
  message is `{:emq_cancel, token, reason}` (the v1 `{:cancel, …}` re-rooted to
  the bus); `check!/1` raises the typed `EchoMQ.Cancel.Cancelled` (the v1 bare
  `RuntimeError ~r/Job cancelled/`). The capability is identical -- the
  worker-side cooperative token; the distributed cancel is emq.6 (INV7), not
  exercised here. Host-side, no wire identity, so a pure (`async: true`) suite.
  """
  use ExUnit.Case, async: true

  alias EchoMQ.Cancel

  describe "new/0" do
    test "creates a unique reference" do
      token1 = Cancel.new()
      token2 = Cancel.new()

      assert is_reference(token1)
      assert is_reference(token2)
      refute token1 == token2
    end
  end

  describe "cancel/3" do
    test "sends cancellation message to target process" do
      token = Cancel.new()
      Cancel.cancel(self(), token, "test reason")
      assert_receive {:emq_cancel, ^token, "test reason"}
    end

    test "sends cancellation message with nil reason" do
      token = Cancel.new()
      Cancel.cancel(self(), token)
      assert_receive {:emq_cancel, ^token, nil}
    end

    test "sends cancellation message with atom reason" do
      token = Cancel.new()
      Cancel.cancel(self(), token, :shutdown)
      assert_receive {:emq_cancel, ^token, :shutdown}
    end

    test "can cancel from a different process" do
      token = Cancel.new()
      test_pid = self()

      spawn(fn -> Cancel.cancel(test_pid, token, "cancelled from another process") end)

      assert_receive {:emq_cancel, ^token, "cancelled from another process"}
    end
  end

  describe "check/1" do
    test "returns :ok when no cancellation message" do
      assert Cancel.check(Cancel.new()) == :ok
    end

    test "returns {:cancelled, reason} when a cancellation message is present" do
      token = Cancel.new()
      send(self(), {:emq_cancel, token, "test reason"})
      assert Cancel.check(token) == {:cancelled, "test reason"}
    end

    test "consumes the cancellation message" do
      token = Cancel.new()
      send(self(), {:emq_cancel, token, "test reason"})
      assert Cancel.check(token) == {:cancelled, "test reason"}
      # second check answers :ok -- the message was consumed
      assert Cancel.check(token) == :ok
    end

    test "only matches the correct token" do
      token1 = Cancel.new()
      token2 = Cancel.new()
      send(self(), {:emq_cancel, token1, "reason1"})

      # token2 does not match token1's cancel
      assert Cancel.check(token2) == :ok
      # token1 does
      assert Cancel.check(token1) == {:cancelled, "reason1"}
    end
  end

  describe "check!/1" do
    test "returns :ok when no cancellation message" do
      assert Cancel.check!(Cancel.new()) == :ok
    end

    test "raises the typed Cancelled when a cancellation message is present" do
      token = Cancel.new()
      send(self(), {:emq_cancel, token, "test reason"})

      assert_raise EchoMQ.Cancel.Cancelled, ~r/cancelled/, fn ->
        Cancel.check!(token)
      end
    end

    test "the raised Cancelled carries the reason" do
      token = Cancel.new()
      send(self(), {:emq_cancel, token, :operator_stop})

      err =
        assert_raise EchoMQ.Cancel.Cancelled, fn -> Cancel.check!(token) end

      assert err.reason == :operator_stop
    end
  end

  describe "cooperative patterns (the v1 integration patterns, re-derived)" do
    test "receive-after-0 chunked processing without cancellation" do
      token = Cancel.new()
      items = [1, 2, 3, 4, 5]

      result =
        Enum.reduce_while(items, {:ok, []}, fn item, {:ok, acc} ->
          case Cancel.check(token) do
            {:cancelled, reason} -> {:halt, {:error, {:cancelled, reason}}}
            :ok -> {:cont, {:ok, [item * 2 | acc]}}
          end
        end)

      assert result == {:ok, [10, 8, 6, 4, 2]}
    end

    test "mid-processing cancellation stops the work" do
      token = Cancel.new()
      items = [1, 2, 3, 4, 5]
      send(self(), {:emq_cancel, token, "user cancelled"})

      result =
        Enum.reduce_while(items, {:ok, []}, fn item, {:ok, acc} ->
          case Cancel.check(token) do
            {:cancelled, reason} -> {:halt, {:error, {:cancelled, reason}}}
            :ok -> {:cont, {:ok, [item * 2 | acc]}}
          end
        end)

      assert result == {:error, {:cancelled, "user cancelled"}}
    end

    test "task cancellation pattern" do
      token = Cancel.new()
      test_pid = self()

      task = Task.async(fn -> Process.sleep(100) && :completed end)
      spawn(fn -> Process.sleep(10) && Cancel.cancel(test_pid, token, "timeout") end)

      result =
        receive do
          {:emq_cancel, ^token, reason} ->
            Task.shutdown(task, :brutal_kill)
            {:error, {:cancelled, reason}}

          {ref, value} when is_reference(ref) ->
            {:ok, value}
        end

      assert result == {:error, {:cancelled, "timeout"}}
    end
  end

  describe "concurrency + isolation" do
    test "token pattern matching ensures isolation" do
      token1 = Cancel.new()
      token2 = Cancel.new()
      send(self(), {:emq_cancel, token1, "cancel1"})

      assert Cancel.check(token2) == :ok
      assert Cancel.check(token1) == {:cancelled, "cancel1"}
    end

    test "rapid cancellation and check cycles" do
      for _ <- 1..100 do
        token = Cancel.new()
        assert Cancel.check(token) == :ok
        send(self(), {:emq_cancel, token, "rapid"})
        assert Cancel.check(token) == {:cancelled, "rapid"}
        assert Cancel.check(token) == :ok
      end
    end

    test "multiple concurrent tokens work independently" do
      tokens = for _ <- 1..10, do: Cancel.new()

      tasks =
        Enum.map(tokens, fn token ->
          Task.async(fn ->
            Process.sleep(50)

            case Cancel.check(token) do
              {:cancelled, reason} -> {:cancelled, reason}
              :ok -> :completed
            end
          end)
        end)

      # cancel only even-indexed tokens, sent to their task processes
      tokens
      |> Enum.with_index()
      |> Enum.filter(fn {_, i} -> rem(i, 2) == 0 end)
      |> Enum.each(fn {token, i} ->
        task = Enum.at(tasks, i)
        Cancel.cancel(task.pid, token, "cancelled")
      end)

      results = Task.await_many(tasks)

      results
      |> Enum.with_index()
      |> Enum.each(fn {result, i} ->
        if rem(i, 2) == 0 do
          assert result == {:cancelled, "cancelled"}
        else
          assert result == :completed
        end
      end)
    end
  end

  describe "scalability" do
    test "handles thousands of tokens efficiently" do
      count = 10_000

      {time_create, tokens} = :timer.tc(fn -> for _ <- 1..count, do: Cancel.new() end)
      assert time_create < 100_000

      {time_check, _} =
        :timer.tc(fn -> Enum.each(tokens, fn token -> Cancel.check(token) end) end)

      assert time_check < 100_000
    end
  end
end
