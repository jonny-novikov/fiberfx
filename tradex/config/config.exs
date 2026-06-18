# This file configures the tradex umbrella and all of its applications.
#
# tradex holds the trading apps extracted from the echo umbrella — `exchange`
# (the pure matching/gateway core, minting branded ids through the inlined
# `Exchange.Id.*` codec) and `investex` (the gRPC venue client). Both are
# lib-only and read NO compile-time config: `exchange` starts its minter via
# `Exchange.Id.Snowflake.start/1`; `investex` resolves its endpoint and token
# from the environment (`INVEST_TOKEN` / `INVEST_API_URL` / `INVEST_API_PORT`)
# at call time (`Investex.Config.resolve/1`). So this file declares no app
# config today — it is the umbrella's shared config anchor, the file each app's
# `config_path: "../../config/config.exs"` points at.
import Config
