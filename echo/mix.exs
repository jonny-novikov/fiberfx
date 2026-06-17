defmodule Echo.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      # No Phoenix.CodeReloader listener here: the Phoenix surface (portal · portal_web ·
      # mercury_cms · mercury_live_admin · live_svelte) moved out to its own repository, so
      # this umbrella has no Phoenix dependency to drive a listener. echo is now the
      # pure-BCS stack (echo_data · echo_mq · echo_cache · echo_wire) plus echo_bot,
      # exchange, and investex. The `portal` OTP release moved out with it.
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
