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
      elixirc_paths: elixirc_paths(Mix.env()),
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
  #
  # ecto_sql + postgrex are the F6.3 DRIVEN-EDGE deps (F5.8-permitted): used ONLY by
  # the Postgres persistence adapter (Portal.Repo, Portal.Catalog.Course schema,
  # Portal.EventStore.Postgres). They do NOT make the core Phoenix-coupled and they
  # appear in NO module under :portal_web (F6.3-INV1, compiler-enforced at the app
  # level — :portal_web does not depend on these). ecto arrives transitively via
  # ecto_sql.
  defp deps do
    [
      {:echo_data, in_umbrella: true},
      {:ecto_sql, "~> 3.12"},
      {:postgrex, ">= 0.0.0"},
      {:jason, "~> 1.4"},
      {:stream_data, "~> 1.0", only: :test}
    ]
  end

  # test/support (Portal.DataCase, the Ecto sandbox case template) compiles only
  # under :test (F6.3-INV6).
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
