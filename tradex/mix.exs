defmodule Tradex.MixProject do
  use Mix.Project

  def project do
    [
      # The trading umbrella, extracted from the `echo` umbrella so it can ship,
      # version, and resolve dependencies on its own (grpc/protobuf are its alone
      # — echo never needed them). Its two apps are `exchange` (the pure
      # matching/gateway core) and `investex` (the gRPC venue client). It is
      # SELF-CONTAINED: the branded-id codec the matching core mints through is
      # inlined into `exchange` (`Exchange.Id.*`), so tradex has NO dependency on
      # echo_data or any echo app.
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
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
