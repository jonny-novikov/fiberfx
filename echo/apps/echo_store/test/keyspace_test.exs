defmodule EchoStore.KeyspaceTest do
  @moduledoc """
  The pure column of the EchoStore.Keyspace row (echo2-migration.md §5):
  the `ecc:{<table>}:<id>` shape, and the shape check that refuses a
  malformed id before any key is composed.
  """
  use ExUnit.Case, async: true

  alias EchoStore.Keyspace

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  test "key/2 composes the cache's own hashtagged keyspace" do
    id = EchoData.BrandedId.generate!("USR")
    assert Keyspace.key("users", id) == "ecc:{users}:" <> id
  end

  test "key/2 raises on an invalid branded id in the value position" do
    assert_raise ArgumentError, ~r/invalid branded id in cache key position/, fn ->
      Keyspace.key("users", "not-a-branded-id")
    end
  end
end
