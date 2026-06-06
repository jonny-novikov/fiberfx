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
  # app level (F6.1-INV1, RK-2). Bandit is the HTTP adapter Phoenix runs through
  # (Bandit.PhoenixAdapter, set in config). `phoenix_ecto` is the web↔Ecto bridge: it
  # ships the `Phoenix.HTML.FormData` impl for `Ecto.Changeset` that `to_form/1` needs
  # to render the F6.5 catalog create form (`Portal.change_course/0` returns a
  # changeset). It lives HERE, not in `apps/portal` — the engine owns the schema, the
  # web owns the form bridge — so the layering stays intact (the bridge is a web concern).
  #
  # libcluster is the F6.8.2 clustering dep (the ONE net-new dependency this rung adds;
  # mix.lock confirms neither libcluster nor dns_cluster was locked). It is declared
  # HERE, in `:portal_web`, per the per-app DEP-GRAPH-VISIBILITY rule: `PortalWeb.Presence`
  # and the endpoint live in this app, and `PortalWeb.Application` supervises the
  # `Cluster.Supervisor` child (F6.8.2-D6). Clustering is a supervision-tree + transport
  # concern — the web still reaches PubSub/Presence ONLY through the `Portal` facade
  # (`Portal.subscribe/1`/`Portal.broadcast/2`); libcluster adds NO web→engine path
  # (F6.8.2-INV4).
  defp deps do
    [
      {:portal, in_umbrella: true},
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_html, "~> 4.1"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:bandit, "~> 1.5"},
      {:libcluster, "~> 3.3"},
      # The DOM backend `Phoenix.LiveViewTest` parses against (LiveView 1.1 requires it
      # explicitly). F6.6 is the first rung to drive a LiveView THROUGH `LiveViewTest`
      # (F6.2's `EnrollmentLive` was compile-only), so this test-only dep is pulled here.
      {:lazy_html, ">= 0.1.0", only: :test}
    ]
  end
end
