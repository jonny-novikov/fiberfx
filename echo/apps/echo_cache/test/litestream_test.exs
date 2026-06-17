defmodule EchoCache.LitestreamTest do
  @moduledoc """
  The reachable surface of the Litestream row (echo2-migration.md §5 + the
  extension rows): the `replica_url/2` pin and the Shadow behaviour
  conformance. The runtime is deferred (record §7) — `init` demands the
  litestream binary — so nothing here starts the server.
  """
  use ExUnit.Case, async: true

  alias EchoCache.Litestream

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  test "replica_url/2 pins the exact shape under the defaults" do
    group = EchoData.BrandedId.generate!("PRT")

    assert Litestream.replica_url(group, bucket: "jonny-shadow") ==
             "s3://jonny-shadow/shadow/#{group}?endpoint=fly.storage.tigris.dev&region=auto"
  end

  test "replica_url/2 honors bucket, prefix, endpoint, and region" do
    group = EchoData.BrandedId.generate!("PRT")

    url =
      Litestream.replica_url(group,
        bucket: "b1",
        prefix: "pfx",
        endpoint: "s3.example.com",
        region: "us-east-1"
      )

    assert url == "s3://b1/pfx/#{group}?endpoint=s3.example.com&region=us-east-1"
  end

  test "the module conforms to the EchoCache.Shadow behaviour" do
    assert {:module, Litestream} = Code.ensure_loaded(Litestream)

    assert function_exported?(Litestream, :start_link, 1)
    assert function_exported?(Litestream, :restore, 1)
    assert function_exported?(Litestream, :status, 1)
    assert function_exported?(Litestream, :stop, 1)

    behaviours =
      Litestream.module_info(:attributes)
      |> Keyword.get_values(:behaviour)
      |> List.flatten()

    assert EchoCache.Shadow in behaviours
  end
end
