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

  # Lib-only: the Gateway is one stateless module that starts nothing —
  # no `mod:`, no supervision tree (INV-5 / AS-5). The lone runtime edge is the
  # in-umbrella `:echo_data` minting prerequisite (INV-3, trd.1.1.specs.md §70).
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # The single in-umbrella canon edge is the sanctioned minting prerequisite,
  # NOT the new external dependency AS-5 forbids (trd.1.1.specs.md §70-76).
  # `stream_data` is test-only — the totality property — already locked at the
  # umbrella root.
  defp deps do
    [
      {:echo_data, in_umbrella: true},
      {:stream_data, "~> 1.0", only: :test}
    ]
  end
end
