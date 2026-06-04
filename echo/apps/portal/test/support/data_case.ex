defmodule Portal.DataCase do
  @moduledoc """
  ExUnit case template for DB-touching tests (F6.3-INV6). Each test runs inside an
  `Ecto.Adapters.SQL.Sandbox` transaction that rolls back at teardown, so DB tests
  isolate without truncating tables and run `async: true` where the sandbox allows.

  `use Portal.DataCase, async: true` for an isolated test; the sandbox owner is
  checked out per test (shared only for `async: false`). Compiled only under :test
  (mix.exs `elixirc_paths`).
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      alias Portal.Repo
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Portal.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
