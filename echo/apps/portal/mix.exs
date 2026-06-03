defmodule Portal.MixProject do
  use Mix.Project

  def project do
    [
      app: :portal,
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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Portal.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  # The core app stays Phoenix-free AND, since F6.1, web-server-free: the F5 Bandit
  # front door + Plug.Router moved to the new `:portal_web` app, so `bandit` and
  # `plug` are dropped here (Plug was used only by the deleted Portal.Web.Router).
  # This keeps the master invariant compiler-enforced at the app level — the core
  # cannot name a web framework it does not depend on (F6.1-INV1, RK-2).
  defp deps do
    [
      {:echo_data, in_umbrella: true},
      {:jason, "~> 1.4"},
      {:stream_data, "~> 1.0", only: :test}
    ]
  end
end
