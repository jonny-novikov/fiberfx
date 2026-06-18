# Starting the suite boots the :codemojex application (mod: Codemojex.Application),
# which brings up the full supervision tree — Repo, the EchoMQ bus + consumers,
# the rate limiter, the Telegram bot gateway, and the CHAMP leaderboard. The pure
# game stories (scoring · economy · emoji codes) need only the modules and run by
# default; the integration stories carry `@moduletag :valkey` and are opt-in via
# `mix test --include valkey` (they also need Postgres up), matching the umbrella's
# convention that bus/wire scenarios are explicitly requested.
ExUnit.start(exclude: [:valkey])
