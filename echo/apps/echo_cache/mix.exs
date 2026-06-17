defmodule EchoCache.MixProject do
  use Mix.Project

  def project do
    [
      app: :echo_cache,
      version: "2.0.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      test_coverage: [summary: [threshold: 0]],
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:echo_data, in_umbrella: true},
      {:echo_mq, in_umbrella: true},
      {:echo_wire, in_umbrella: true},
      # Chapter 4.4: the journal's SQLite — hex, pinned to the drop's vendored version (D4/D10).
      # Journal uses the raw Exqlite.Sqlite3 NIF API only; db_connection/elixir_make/
      # cc_precompiler/telemetry resolve transitively at production's already-locked versions.
      {:exqlite, "0.23.0"},
      # Graft local store: the append-only, immutable B-tree whose zero-cost MVCC
      # snapshots are Graft's snapshot model. Pure Elixir — no C, no NIF.
      {:cubdb, "~> 2.0"}
    ]
  end
end
