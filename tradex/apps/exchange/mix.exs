defmodule Exchange.MixProject do
  use Mix.Project

  def project do
    [
      app: :exchange,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Lib-only: the Gateway is one stateless module that starts nothing — no
  # `mod:`, no supervision tree (INV-5 / AS-5). The branded-id minter the
  # Gateway/Decider mint through (`Exchange.Id.Snowflake`) is inlined into this
  # app, so there is no runtime dependency to start — a host (or a test
  # `setup_all`) calls `Exchange.Id.Snowflake.start/1` once before any mint (INV-3).
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # No external runtime dependency (AS-5): the branded-id codec (`Exchange.Id.*`,
  # `lib/exchange/id/`) is inlined pure-Elixir — vendored from echo_data's branded
  # contract when the trading apps were extracted to this umbrella. `stream_data`
  # is test-only — the totality property — locked at the umbrella root.
  defp deps do
    [
      {:stream_data, "~> 1.0", only: :test}
    ]
  end
end
