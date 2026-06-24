defmodule Echo.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      # echo is the BCS data-layer stack (echo_wire · echo_data · echo_mq · echo_store)
      # plus echo_bot and codemojex; the umbrella root itself declares no deps and no
      # listeners — each app configures its own.
      deps: deps()
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    []
  end
end
