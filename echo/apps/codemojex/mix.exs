defmodule Codemojex.MixProject do
  use Mix.Project

  def project do
    [
      app: :codemojex,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  # The game runs under a supervision tree: the Repo (crucial data), PubSub, the
  # EchoMQ bus + the EchoStore near-cache tier (rounds + emoji sets), the EchoMQ
  # consumers (scoring · settlement · notifications · inbound bot commands), the
  # rate limiter + Telegram bot gateway, an in-memory CHAMP leaderboard, and the
  # Phoenix endpoint. EchoStore is now a first-class dependency — `Codemojex.Tables`
  # declares and supervises the L1/L2 caches — while the Graft committer (the
  # durable, replicated page tier folding to Tigris) stays optional, started only
  # when a `:graft_volume` is configured. `echo_bot` drives the notification I/O:
  # outbound sends go through its vendored Telegram client, inbound updates route to
  # `Codemojex.Bot.Handler`. `:inets` + `:ssl` back the legacy `Codemojex.Telegram`
  # `:httpc` transport, kept as a utility.
  def application do
    [
      mod: {Codemojex.Application, []},
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:echo_mq, in_umbrella: true},
      {:echo_data, in_umbrella: true},
      # the owned wire's fluent client (EchoWire.Cmd) + connector facade
      {:echo_wire, in_umbrella: true},
      # the durable near-cache tier: EchoStore.Table (L1 ETS over L2 Valkey) and
      # the Graft page store; brings exqlite (SQLite C-NIF) and cubdb transitively
      {:echo_store, in_umbrella: true},
      # the Telegram bot engine that drives the notification system (outbound sends
      # via its vendored client; inbound updates routed to Codemojex.Bot.Handler)
      {:echo_bot, in_umbrella: true},
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
