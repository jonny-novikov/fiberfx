import Config

# Tests run the in-memory event-store adapter — the suite needs no database, and
# `Portal.EventStore.InMemory.reset/0` gives per-test isolation (CLAUDE.md §4).
config :portal, :event_store, Portal.EventStore.InMemory
