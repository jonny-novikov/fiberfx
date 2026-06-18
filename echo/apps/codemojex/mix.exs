defmodule Codemojex.MixProject do
  use Mix.Project

  def project do
    [
      app: :codemojex,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  # The game runs under a supervision tree now: the Repo (crucial data), PubSub,
  # the EchoMQ bus + consumers, and the Phoenix endpoint. EchoStore stays an
  # optional read-through (the Cache seam guards on whether it is loaded), so the
  # app still compiles without it.
  def application do
    [
      mod: {Codemojex.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:echo_mq, in_umbrella: true},
      {:echo_data, in_umbrella: true},
      # crucial data is persisted relationally; BCS ids stay the keys
      {:ecto_sql, "~> 3.11"},
      {:postgrex, "~> 0.18"},
      # the web surface for the Telegram Mini App
      {:phoenix, "~> 1.7"},
      {:phoenix_pubsub, "~> 2.1"},
      {:bandit, "~> 1.5"},
      {:jason, "~> 1.4"}
    ]
  end
end
