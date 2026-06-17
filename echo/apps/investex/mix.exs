defmodule Investex.MixProject do
  use Mix.Project

  def project do
    [
      app: :investex,
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

  # Lib-only: the venue client owns its channel inside a supervised
  # `Investex.Client`, but `:investex` starts nothing on its own — no `mod:`,
  # no supervision tree (INV-5, trd.9.1.specs.md). The consumer's tree (or a
  # test) starts the client; merely loading `:investex` opens no connection.
  # The `echo/apps/exchange` lib-only precedent.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # The new top-level deps the umbrella has never carried (L-3): `:grpc` over
  # the Mint adapter (already in the lock) and `:protobuf` for the generated
  # codec — both ABSENT from `mix.lock` before this rung. The minors are the
  # current stable lines verified against hex at build (2026-06-13): grpc
  # 0.11.5, protobuf 0.17.0 — a realization over the spec's `~> 0.9`/`~> 0.13`
  # literal (L-1). `:echo_data` is the canon dep the branded `ORD` seam (9.3)
  # consumes — DECLARED here, NOT exercised this slice. `:stream_data` is the
  # test-only Money round-trip property (G2).
  defp deps do
    [
      {:echo_data, in_umbrella: true},
      {:grpc, "~> 0.11"},
      {:protobuf, "~> 0.17"},
      {:stream_data, "~> 1.0", only: :test}
    ]
  end
end
