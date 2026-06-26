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
      deps: deps(),
      releases: releases()
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

  # The codemojex release: the Telegram Mini App Phoenix surface plus its in-umbrella dependency
  # closure (echo_wire, echo_data, echo_mq, echo_store, echo_bot), which Mix pulls in transitively
  # from codemojex's deps. The other umbrella apps are not codemojex deps and stay out. The release
  # name matches the Dockerfile's `mix release codemojex`, the `_build/prod/rel/codemojex` COPY, and
  # the `bin/codemojex start` entrypoint. (An umbrella has no default release, so this is required.)
  defp releases do
    [
      codemojex: [
        applications: [codemojex: :permanent]
      ]
    ]
  end
end
