import Config

# Tests run the in-memory event-store adapter — the suite needs no database, and
# `Portal.EventStore.InMemory.reset/0` gives per-test isolation (CLAUDE.md §4).
config :portal, :event_store, Portal.EventStore.InMemory

# The endpoint runs with `server: false` under test so ConnTest exercises the plug
# pipeline WITHOUT binding a port — avoids the :4000 TIME_WAIT race across repeated
# runs (RK-5). The secret_key_base is a fixed 64-char dummy (signing only; no real
# secret needed in test).
config :portal_web, PortalWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_at_least_sixtyfour_bytes_long_for_phoenix_0000",
  server: false
