defmodule EchoMq.MixProject do
  use Mix.Project

  def project do
    [
      app: :echo_mq,
      version: "2.0.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      test_coverage: [summary: [threshold: 0]],
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  # test/support holds the EchoMQ.Story BDD DSL used by test/stories/*_story_test.exs
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:echo_data, in_umbrella: true},
      {:echo_wire, in_umbrella: true}
    ]
  end
end
