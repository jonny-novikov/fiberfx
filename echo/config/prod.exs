import Config

# Production selects the Postgres event-store adapter (F5.8-INV4). The adapter is a
# signature-only stub at F5.8 — `MIX_ENV=prod mix compile` is green with no Ecto
# dependency; F6.3 fills the body, schema, and migration behind this same config.
config :portal, :event_store, Portal.EventStore.Postgres
