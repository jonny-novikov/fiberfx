ExUnit.start()

# F6.3 — DB-touching tests run in the Ecto sandbox (Portal.DataCase). Manual mode:
# each test checks out its own owner; the in-memory engine suite never touches the
# Repo, so it is unaffected.
Ecto.Adapters.SQL.Sandbox.mode(Portal.Repo, :manual)
