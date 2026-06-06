import Config

# Production selects the Postgres event-store adapter (F5.8-INV4). The adapter is a
# signature-only stub at F5.8 — `MIX_ENV=prod mix compile` is green with no Ecto
# dependency; F6.3 fills the body, schema, and migration behind this same config.
config :portal, :event_store, Portal.EventStore.Postgres

# The prod endpoint settings (F6.8.2-D4, INV2). Compile-time, no secret:
#   * `url` — the fixed HTTPS:443 shape; the HOST is resolved at runtime from PHX_HOST
#     (runtime.exs, D3), which merges over this `host` placeholder under :prod.
#   * `cache_static_manifest` — the `mix phx.digest` output the Dockerfile produces, so
#     the release serves fingerprinted assets.
# The `server`-from-PHX_SERVER toggle (D4) is realized in runtime.exs, NOT here: a
# release reads PHX_SERVER at BOOT, and `System.get_env` in this compile-time file
# would bake the build-time env into the image instead — so the gate is set at runtime
# (where it also keeps `bin/portal eval` from starting the listener). No
# secret_key_base / DATABASE_URL here — those stay runtime-only (INV2).
config :portal_web, PortalWeb.Endpoint,
  url: [host: "echo-portal.fly.dev", port: 443, scheme: "https"],
  cache_static_manifest: "priv/static/cache_manifest.json"

# The prod libcluster topology (F6.8.2-D6, INV4). Fly's `.internal` DNS resolves the
# app name to every machine's private IPv6, so `Cluster.Strategy.DNSPoll` over
# `echo-portal.internal` forms and maintains the BEAM cluster — making the F6.7
# `Phoenix.PubSub` broadcasts and `PortalWeb.Presence` counts cluster-correct across
# nodes (the IPv6 substrate is the fly.toml `ERL_INETRC`/`ECTO_IPV6`/`ERL_AFLAGS` trio).
# `node_basename: "portal"` matches the OTP release name (`bin/portal`), the left side
# of the `name@host` the cluster connects. Dev/test keep the EMPTY config.exs default
# (no clustering under the suite). `PortalWeb.Application` reads this key.
config :portal_web, :cluster_topologies,
  fly_dns: [
    strategy: Cluster.Strategy.DNSPoll,
    config: [
      polling_interval: 5_000,
      query: "echo-portal.internal",
      node_basename: "portal"
    ]
  ]
