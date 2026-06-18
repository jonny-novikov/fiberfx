defmodule Investex.ErrorTest do
  @moduledoc """
  Tier 1 (pure): the typed `Investex.Error` value (trd.9.1.specs.md §Surface).
  No token VALUE appears in this file.
  """
  use ExUnit.Case, async: true

  alias Investex.Error

  doctest Investex.Error

  test "new/1 from a bare reason carries a default message and nil status" do
    for reason <- [:no_channel, :rpc_error, :retry_exhausted] do
      e = Error.new(reason)
      assert e.reason == reason
      assert e.status == nil
      assert is_binary(e.message) and byte_size(e.message) > 0
    end
  end

  test "new/1 from opts carries status + a custom message" do
    e = Error.new(reason: :rpc_error, status: :unavailable, message: "down")
    assert %Error{reason: :rpc_error, status: :unavailable, message: "down"} = e
  end

  test "@enforce_keys requires reason + message" do
    assert_raise ArgumentError, fn ->
      struct!(Error, status: :unavailable)
    end
  end

  describe "from_rpc/1 maps a gRPC error to a typed :rpc_error" do
    test "lifts the numeric status code to the snake_case atom" do
      # gRPC code 14 = UNAVAILABLE; 8 = RESOURCE_EXHAUSTED.
      assert %Error{reason: :rpc_error, status: :unavailable} =
               Error.from_rpc(%GRPC.RPCError{status: 14, message: "unavailable"})

      assert %Error{reason: :rpc_error, status: :resource_exhausted} =
               Error.from_rpc(%GRPC.RPCError{status: 8, message: "too many"})
    end

    test "carries the RPC error's own message (the venue status text, never a token)" do
      e = Error.from_rpc(%GRPC.RPCError{status: 14, message: "endpoint unreachable"})
      assert e.message == "endpoint unreachable"
    end

    test "from a bare status atom" do
      assert %Error{reason: :rpc_error, status: :internal} = Error.from_rpc(:internal)
    end
  end
end
