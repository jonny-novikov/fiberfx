defmodule PortalWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :portal_web,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # The web app supervises [PortalWeb.Telemetry, PortalWeb.Endpoint] (F6.1-R2). The
  # `:portal_web` → `:portal` app dependency orders the boots: the three F5 domain
  # children are ready before this endpoint accepts traffic (F6.1-INV2).
  def application do
    [
      extra_applications: [:logger],
      mod: {PortalWeb.Application, []}
    ]
  end

  # The test ConnCase support file lives under test/support and compiles only in
  # the test environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Phoenix lives ONLY here so apps/portal/mix.exs stays Phoenix-free and the master
  # invariant (the web calls only the Portal facade) remains compiler-enforced at the
  # app level (F6.1-INV1, RK-2). No Ecto at F6.1 — persistence is F6.3. Bandit is the
  # HTTP adapter Phoenix runs through (Bandit.PhoenixAdapter, set in config).
  defp deps do
    [
      {:portal, in_umbrella: true},
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_html, "~> 4.1"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:bandit, "~> 1.5"}
    ]
  end
end
