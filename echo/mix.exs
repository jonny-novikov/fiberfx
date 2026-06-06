defmodule Echo.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # The scoped umbrella release (F6.8.2-D1). The release is named `portal`
  # (OPERATOR-PINNED) — the OTP release artifact, INDEPENDENT of the Fly app name
  # `echo-portal` (set in fly.toml); do not conflate them. It packages only the
  # Portal apps — `portal_web` (the web entry, which depends on `portal`, which
  # depends on `echo_data`) — and EXCLUDES `echo_bot`, the out-of-band F10 bot
  # (its own separate release). `MIX_ENV=prod mix release portal` builds a
  # self-contained artifact with no `mix` at runtime; migrations run release-native
  # via `bin/portal eval "Portal.Release.migrate()"` (F6.8.2-INV1, INV6).
  defp releases do
    [
      portal: [
        applications: [
          portal_web: :permanent,
          portal: :permanent,
          echo_data: :permanent
        ]
      ]
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
