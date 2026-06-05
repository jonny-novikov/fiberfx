defmodule EchoBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :echo_bot,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # The engine boots its own supervision tree via EchoBot.Application — the third app
  # in the umbrella to do so, alongside Portal.Application and PortalWeb.Application
  # (F10.1-INV2). `:inets`/`:ssl` are OTP's built-in HTTP client stack the vendored
  # ex_gram copy uses for live getUpdates/sendMessage calls; no Finch/Tesla/hackney is
  # pulled in, keeping the footprint minimal (live HTTP is never exercised in tests —
  # the fake updater contacts no Telegram, F10.1-INV6).
  def application do
    [
      extra_applications: [:logger, :inets, :ssl],
      mod: {EchoBot.Application, []}
    ]
  end

  # The vendored ex_gram copy lives OUTSIDE lib/ at vendor/ex_gram/ as owned source; it
  # is added to the compile path here so the in-app modules build, while staying off the
  # `lib/` tree the Portal no-touch grep scans (F10.1-INV4). The wrap — not the copy — is
  # the long-lived boundary: only EchoBot.Platform.Telegram names a vendored module.
  defp elixirc_paths(_), do: ["lib", "vendor/ex_gram"]

  # NO `{:portal, in_umbrella: true}` and neither Portal app is named — echo_bot does
  # not depend on, join, or touch Portal (F10.1-INV1). `jason` (already in the umbrella
  # lock) decodes the Telegram JSON; `yaml_elixir` parses the v1.0 bot YAML.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:yaml_elixir, "~> 2.9"}
    ]
  end
end
