ExUnit.start()

# Configure ExUnit
ExUnit.configure(
  formatters: [ExUnit.CLIFormatter],
  capture_log: true,
  exclude: [:integration, :slow]
)

# Test configuration helper
defmodule EchoMQ.TestHelper do
  @moduledoc """
  Helper module for test configuration.
  """

  @doc """
  Returns the test prefix for Redis keys.

  Can be configured via ECHOMQ_TEST_PREFIX environment variable.
  This is useful for running tests against Redis-compatible databases
  that require hashtag prefixes (e.g., DragonflyDB with cluster mode).

  Examples:
    - Default: "echomq_test"
    - DragonflyDB: "{b}" (set via ECHOMQ_TEST_PREFIX="{b}")
  """
  def test_prefix do
    System.get_env("ECHOMQ_TEST_PREFIX", "echomq_test")
  end

  @doc """
  Returns the Redis URL for tests.

  Can be configured via REDIS_URL environment variable.
  Default: "redis://localhost:6379"
  """
  def redis_url do
    System.get_env("REDIS_URL", "redis://localhost:6379")
  end
end
