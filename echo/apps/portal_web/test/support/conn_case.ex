defmodule PortalWeb.ConnCase do
  @moduledoc """
  The ExUnit case template for tests that exercise the `:portal_web` endpoint
  through a connection (F6.1-T7).

  Sets up a `Plug.Conn` and imports the Phoenix test helpers. `async: false` and a
  `Portal.Store`/event-store/`Portal.Engine` reset in `setup` give per-test fold
  isolation: the engine mints branded ids whose `worker_id` is fixed, so two tests
  minting in the same millisecond can collide unless each starts from an empty store
  (echo/CLAUDE.md §4). The endpoint runs `server: false` under test (config/test.exs),
  so no port is bound (RK-5).
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint PortalWeb.Endpoint

      use PortalWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import PortalWeb.ConnCase
    end
  end

  setup _tags do
    # Per-test fold isolation (echo/CLAUDE.md §4): empty the Store, the event stream,
    # then re-fold the Engine from the now-empty stream, so each test starts clean and
    # a same-millisecond branded-id collision cannot leak across tests.
    Portal.Store.reset()
    Portal.EventStore.InMemory.reset()
    Portal.Engine.reset()

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
