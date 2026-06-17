defmodule EchoWire.MixProject do
  use Mix.Project

  def project do
    [
      app: :echo_wire,
      version: "2.0.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      # The connector's version fence reads EchoMQ.Keyspace.version_key/0 at
      # runtime (connector.ex:417); the keyspace module lives in the sibling
      # :echo_mq app, which depends on this one — the reference is
      # runtime-resolved, never a compile-time edge (deps stay []).
      elixirc_options: [no_warn_undefined: [EchoMQ.Keyspace]],
      test_coverage: [summary: [threshold: 0]],
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger, :crypto]]
  end

  # The wire layer is dependency-free by design: RESP framing and the
  # connector ride stdlib and :crypto; telemetry is emitted only when the
  # :telemetry application is present in the release (guarded at runtime).
  defp deps, do: []
end
