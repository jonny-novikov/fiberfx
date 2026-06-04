defmodule Portal.ErrorTest do
  @moduledoc """
  DB-FREE tests for the F6.3 error bridge (F6.3-INV2/INV6): `Portal.Error.from_changeset/1`
  maps a failed changeset into the closed `%Portal.Error{}` vocabulary, and the closed
  `from/1`/`new/1` stay no-catch-all over the extended `:invalid` code.
  """
  use ExUnit.Case, async: true

  alias Portal.Catalog.Course
  alias Portal.Error

  test "from_changeset/1 on a too-short title yields code :invalid, field :title" do
    err = %{title: "ab", slug: "s"} |> Course.changeset() |> Error.from_changeset()
    assert %Error{code: :invalid, field: :title} = err
    assert is_binary(err.message) and err.message != ""
  end

  test "from_changeset/1 on a missing title yields field :title" do
    err = %{slug: "elixir"} |> Course.changeset() |> Error.from_changeset()
    assert %Error{code: :invalid, field: :title} = err
  end

  test "from_changeset/1 on a missing slug yields field :slug" do
    err = %{title: "Elixir"} |> Course.changeset() |> Error.from_changeset()
    assert %Error{code: :invalid, field: :slug} = err
  end

  test "new/1 supports the extended :invalid code" do
    assert %Error{code: :invalid, message: "invalid"} = Error.new(:invalid)
  end

  test "from/1 stays no-catch-all (an unmapped reason raises)" do
    assert_raise FunctionClauseError, fn -> Error.from(:not_a_real_code) end
  end
end
