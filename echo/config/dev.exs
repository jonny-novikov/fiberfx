import Config

# Dev runs the in-memory event-store adapter — no database to boot for `mix run`
# or `iex -S mix`. Production overrides to Postgres in `prod.exs` (F5.8-INV4).
config :portal, :event_store, Portal.EventStore.InMemory
