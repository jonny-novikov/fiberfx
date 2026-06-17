defmodule EchoCache.DirectoryTest do
  @moduledoc """
  The pure column of the EchoCache / Directory row (echo2-migration.md §5).
  The Directory is a lazily-ensured NAMED singleton holding a named ETS
  table, started unlinked — so this suite is `async: false` and resets the
  singleton before every test (the hazards bank).
  """
  use ExUnit.Case, async: false

  alias EchoCache.Directory

  setup do
    if pid = Process.whereis(Directory) do
      GenServer.stop(pid)
      wait_until(fn -> :ets.whereis(EchoCache.directory_table()) == :undefined end)
    end

    :ok
  end

  test "tables/0 is empty and spec/1 errors before any cache is declared" do
    assert EchoCache.tables() == []
    assert EchoCache.spec(:undeclared) == :error
  end

  test "register/3 declares the cache for tables/0 and spec/1" do
    assert :ok = Directory.register(:users_cache, %{kind: "USR", max: 100}, self())

    assert EchoCache.tables() == [{:users_cache, %{kind: "USR", max: 100}}]
    assert EchoCache.spec(:users_cache) == {:ok, %{kind: "USR", max: 100}}
    assert EchoCache.spec(:other) == :error
  end

  test "a crashed owner leaves the roster — the DOWN scrubs the entry" do
    owner = spawn(fn -> Process.sleep(:infinity) end)
    assert :ok = Directory.register(:doomed_cache, %{kind: "AST"}, owner)
    assert {:ok, _} = EchoCache.spec(:doomed_cache)

    Process.exit(owner, :kill)
    wait_until(fn -> EchoCache.spec(:doomed_cache) == :error end)

    assert EchoCache.tables() == []
  end

  test "unregister/1 removes the declaration" do
    assert :ok = Directory.register(:fleeting_cache, %{kind: "ORD"}, self())
    assert :ok = Directory.unregister(:fleeting_cache)

    assert EchoCache.spec(:fleeting_cache) == :error
    assert EchoCache.tables() == []
  end

  test "unregister/1 is a no-op when no directory exists" do
    assert :ok = Directory.unregister(:never_there)
  end

  defp wait_until(pred, tries \\ 200) do
    cond do
      pred.() -> :ok
      tries == 0 -> flunk("condition never held")
      true ->
        Process.sleep(5)
        wait_until(pred, tries - 1)
    end
  end
end
