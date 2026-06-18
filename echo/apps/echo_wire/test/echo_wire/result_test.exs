defmodule EchoWire.ResultTest do
  @moduledoc """
  EWR.1.3 — the two-tier error classifier: the total transport-vs-server
  partition asserted **through the accessors** (never a literal return shape),
  the per-reply index lens, the transport-before-server ordering, and the
  cross-consistency of `classify`/`error`/`non_valkey_error`. Fully offline —
  hand-built `exec`-shaped returns, no Valkey.
  """
  use ExUnit.Case, async: true

  alias EchoWire.Result

  # A representative server-error slot (the in-band {:error_reply, _}, resp.ex:47).
  @wrongtype {:error_reply, "WRONGTYPE Operation against a key holding the wrong kind of value"}
  @err_reply {:error_reply, "ERR something"}

  describe "server_errors/1 — the per-reply lens (D5)" do
    test "a clean reply list → []" do
      assert Result.server_errors(["OK", "alice", 1]) == []
    end

    test "one error slot → its 0-based index + value" do
      assert Result.server_errors(["OK", @wrongtype]) == [{1, @wrongtype}]
    end

    test "several error slots → ascending index order" do
      replies = [@err_reply, "OK", @wrongtype, "v", @err_reply]

      assert Result.server_errors(replies) == [
               {0, @err_reply},
               {2, @wrongtype},
               {4, @err_reply}
             ]
    end

    test "an empty list → []" do
      assert Result.server_errors([]) == []
    end

    test "it does not mistake a nested list reply for an error" do
      # a RESP array reply is a plain list, not an {:error_reply, _}
      assert Result.server_errors([["a", "b"], @wrongtype]) == [{1, @wrongtype}]
    end
  end

  describe "classify/1 — the total transport-vs-server partition (D2, INV4)" do
    test "a clean success classifies as :ok carrying the replies — non_valkey_error nil, server_errors []" do
      ret = {:ok, ["OK", "alice", 1]}
      assert {:ok, ["OK", "alice", 1]} = Result.classify(ret)
      # bound through the accessors (INV4):
      assert Result.non_valkey_error(ret) == nil
      assert Result.server_errors(elem(ret, 1)) == []
    end

    test "a transport failure classifies as :transport_error carrying the term" do
      for term <- [:disconnected, :overloaded, {:version_fence, "x"}, :empty_pipeline, :anything] do
        ret = {:error, term}
        assert {:transport_error, ^term} = Result.classify(ret)
        # accessor binding: non_valkey_error non-nil IFF transport-error
        assert Result.non_valkey_error(ret) == {:error, term}
      end
    end

    test "a success carrying server errors classifies as :server_error with the full replies + indexed slots" do
      ret = {:ok, ["OK", @wrongtype]}
      assert {:server_error, ["OK", @wrongtype], [{1, @wrongtype}]} = Result.classify(ret)
      # accessor binding: server_errors non-[] IFF server-error; non_valkey_error nil
      assert Result.non_valkey_error(ret) == nil
      assert Result.server_errors(elem(ret, 1)) == [{1, @wrongtype}]
    end

    test "the :server_error case carries the FULL reply list (oks not elided), indices valid against it" do
      ret = {:ok, ["OK", @wrongtype, "tail"]}
      assert {:server_error, oks, [{1, @wrongtype}]} = Result.classify(ret)
      assert oks == ["OK", @wrongtype, "tail"]
      # the index points at the error slot in the carried list
      assert Enum.at(oks, 1) == @wrongtype
    end

    test "the partition is exhaustive — every exec return shape lands in exactly one outcome (INV4)" do
      shapes = [
        {:ok, []},
        {:ok, ["OK"]},
        {:ok, ["OK", @wrongtype]},
        {:ok, [@err_reply, @wrongtype]},
        {:error, :disconnected},
        {:error, {:version_fence, "v"}}
      ]

      for ret <- shapes do
        # the accessor-pair determines the outcome with no overlap, no gap:
        transport? = Result.non_valkey_error(ret) != nil

        server? =
          case ret do
            {:ok, replies} -> Result.server_errors(replies) != []
            _ -> false
          end

        clean? = not transport? and not server?

        # exactly one is true
        assert Enum.count([transport?, server?, clean?], & &1) == 1

        # and classify agrees with the accessor verdict
        case Result.classify(ret) do
          {:transport_error, _} -> assert transport?
          {:server_error, _, _} -> assert server?
          {:ok, _} -> assert clean?
        end
      end
    end
  end

  describe "non_valkey_error/1 — the transport tier only (D3, NonValkeyError())" do
    test "a transport failure → {:error, term}" do
      assert Result.non_valkey_error({:error, :disconnected}) == {:error, :disconnected}
    end

    test "a clean success → nil" do
      assert Result.non_valkey_error({:ok, ["OK"]}) == nil
    end

    test "a SERVER-error-carrying success → nil (a server error is NOT a transport error)" do
      assert Result.non_valkey_error({:ok, ["OK", @wrongtype]}) == nil
    end
  end

  describe "error/1 — transport-or-server, transport FIRST (D4, INV6, Error())" do
    test "a transport failure → that {:error, term}" do
      assert Result.error({:error, :overloaded}) == {:error, :overloaded}
    end

    test "a success with server errors → the FIRST (lowest-index) {:error_reply, _}" do
      assert Result.error({:ok, ["OK", @err_reply, @wrongtype]}) == @err_reply
    end

    test "a clean success → nil" do
      assert Result.error({:ok, ["OK", "v"]}) == nil
    end

    test "transport PRECEDES server: a transport term answers even when no reply list exists" do
      # the hallmark of the ordering — error/1 must not try to walk a reply list
      # for a transport failure.
      assert Result.error({:error, :disconnected}) == {:error, :disconnected}
    end
  end

  describe "INV6 — classify / error / non_valkey_error AGREE on every return shape" do
    test "transport: classify :transport_error ⇒ non_valkey_error & error both return that term" do
      ret = {:error, {:version_fence, "v2"}}
      assert {:transport_error, term} = Result.classify(ret)
      assert Result.non_valkey_error(ret) == {:error, term}
      assert Result.error(ret) == {:error, term}
    end

    test "server: classify :server_error ⇒ non_valkey_error nil, error the first server reply" do
      ret = {:ok, ["OK", @wrongtype]}
      assert {:server_error, _, [{1, first} | _]} = Result.classify(ret)
      assert Result.non_valkey_error(ret) == nil
      assert Result.error(ret) == first
    end

    test "clean: classify :ok ⇒ both error and non_valkey_error nil" do
      ret = {:ok, ["OK", "v"]}
      assert {:ok, _} = Result.classify(ret)
      assert Result.non_valkey_error(ret) == nil
      assert Result.error(ret) == nil
    end
  end

  describe "EWR.1.3-INV3 — purity (a function over a value, never a wire call)" do
    test "result.ex calls no Connector/Pool/socket/process/pipeline" do
      src = File.read!(Path.join(__DIR__, "../../lib/echo_wire/result.ex"))
      refute src =~ ~r/Connector|Pool|:gen_tcp|GenServer\.|\.pipeline\(/
    end

    test "every accessor is referentially transparent — same input, same output" do
      ret = {:ok, ["OK", @wrongtype]}
      assert Result.classify(ret) == Result.classify(ret)
      assert Result.error(ret) == Result.error(ret)
      assert Result.non_valkey_error(ret) == Result.non_valkey_error(ret)
      assert Result.server_errors(elem(ret, 1)) == Result.server_errors(elem(ret, 1))
    end
  end

  describe "EWR.1.3-INV5 — no synthesized {:server, _} (that term is eval-exclusive, unreachable here)" do
    test "no classification produces a {:server, _} tuple" do
      for ret <- [{:ok, ["OK", @wrongtype]}, {:error, :disconnected}, {:ok, ["OK"]}] do
        # the classification's leading tag is one of the three known atoms,
        # never :server (that term is eval/5-exclusive — connector.ex:76-77).
        assert elem(Result.classify(ret), 0) in [:ok, :transport_error, :server_error]

        case Result.classify(ret) do
          {:server_error, _, errs} ->
            # the server tier is exactly {:error_reply, _}, never {:server, _}
            assert Enum.all?(errs, fn {_i, {:error_reply, _}} -> true end)

          _ ->
            :ok
        end
      end
    end
  end
end
