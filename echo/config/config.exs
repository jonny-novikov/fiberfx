# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# The driven event-store adapter (F5.8). The base default is the in-memory Agent
# so dev, test, and a bare `mix run` boot with no running database; `prod.exs`
# overrides to Postgres. `Portal.EventStore.adapter/0` resolves this value, and the
# engine + supervision tree name only that resolver — swapping the adapter is
# config-only and changes no caller (F5.8-INV4).
config :portal, :event_store, Portal.EventStore.InMemory

# The Phoenix web app (F6.1). The endpoint is keyed to `:portal_web` (its otp_app),
# runs through Bandit (Bandit.PhoenixAdapter), and renders expected errors via
# PortalWeb.ErrorHTML. `pubsub_server: Portal.PubSub` is declared for a later rung
# but NOT started at F6.1 — the endpoint boots without it. The HTTP port and
# secret_key_base resolve at runtime (config/runtime.exs).
config :portal_web, PortalWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: PortalWeb.ErrorHTML],
    layout: false
  ],
  pubsub_server: Portal.PubSub,
  live_view: [signing_salt: "5tFp7nQe"]

# Use Jason for JSON parsing in Phoenix.
config :phoenix, :json_library, Jason

# Per-environment overrides — load the matching env file last so its values win.
import_config "#{config_env()}.exs"
