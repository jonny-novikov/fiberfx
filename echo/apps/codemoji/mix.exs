defmodule Codemoji.MixProject do
  use Mix.Project

  def project do
    [
      app: :codemoji,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      elixir: "~> 1.14",
      deps: deps()
    ]
  end

  def application, do: [extra_applications: [:logger]]

  # The game stands on the real component layer and the real bus. EchoCache is an
  # optional read-through (cited from echo/apps/echo_cache); the Cache seam guards
  # on whether EchoCache.Table is loaded, so this compiles without it.
  defp deps do
    [
      {:echo_mq, in_umbrella: true},
      {:echo_data, in_umbrella: true}
    ]
  end
end
