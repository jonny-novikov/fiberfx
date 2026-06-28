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
      aliases: aliases(),
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

  # Umbrella task aliases.
  #
  # `mix codemojex.edge` wraps the edge-bundle publish (apps/codemojex/scripts/edge-deploy.sh):
  # build the content-hashed React GAME bundle, upload it immutably to the Tigris edge bucket,
  # then flip the short-cached `manifest.json` pointer (`{"game": url}`) that `Codemojex.Edge`
  # reads. No `mix release`, no `fly deploy`, no socket drop — the board hot-swaps within the
  # pointer's ~10s TTL. Args pass straight through to the script:
  #
  #   mix codemojex.edge                            # build → upload → flip the pointer
  #   mix codemojex.edge --dry-run                  # build → show what WOULD upload/flip (no writes)
  #   mix codemojex.edge --rollback game-<hash>.js  # re-point the manifest only, no rebuild
  #
  # Requires TIGRIS_EDGE_* + GAME_EDGE_HOST in the env — `mix` does NOT load .env, so source it
  # first: `set -a && source .env && set +a && mix codemojex.edge`. This publishes to a LIVE
  # bucket — the Operator runs it. Setup + boundary: echo/docs/codemojex/edge-bucket-setup.md.
  defp aliases do
    ["codemojex.edge": &edge_publish/1]
  end

  defp edge_publish(args) do
    script = Path.expand("apps/codemojex/scripts/edge-deploy.sh", __DIR__)
    unless File.exists?(script), do: Mix.raise("mix codemojex.edge: not found at #{script}")

    # Mix.shell().cmd/1 streams the build/upload output live and returns the exit status.
    case Mix.shell().cmd(Enum.join(["bash", script | args], " ")) do
      0 -> :ok
      status -> Mix.raise("mix codemojex.edge: edge-deploy.sh exited with status #{status}")
    end
  end
end
