defmodule Portal.PersistenceTest do
  @moduledoc """
  DB sandbox tests for the F6.3 Course persistence path (F6.3-US1/US2, AS3) — the
  branded-id round-trip through the custom type, the duplicate-title constraint
  bridged to `%Portal.Error{}`, and the `published/1` query RUN. Runs in the Ecto
  sandbox (Portal.DataCase), `async: true`.
  """
  use Portal.DataCase, async: true

  alias Portal.Catalog.Course
  alias Portal.Error
  alias Portal.Repo

  defp insert_course(attrs) do
    %Course{id: Portal.ID.new("CRS"), title: nil, slug: nil}
    |> Course.changeset(attrs)
    |> Repo.insert()
  end

  test "a course round-trips: changeset -> Repo.insert -> Repo.get by branded id" do
    branded = Portal.ID.new("CRS")

    {:ok, inserted} =
      %Course{id: branded, title: nil, slug: nil}
      |> Course.changeset(%{title: "Elixir", slug: "elixir", published: true})
      |> Repo.insert()

    # The :id surface stays the branded string after insert (custom type load).
    assert inserted.id == branded
    assert Portal.ID.valid?(inserted.id)

    # Repo.get casts the branded id, dumps it to the :bigint for the WHERE, loads
    # the row back to the branded surface.
    fetched = Repo.get(Course, branded)
    assert fetched.id == branded
    assert fetched.title == "Elixir"
    assert fetched.slug == "elixir"
    assert fetched.published == true
  end

  test "a duplicate title surfaces as %Portal.Error{field: :title}, not a raw DB error" do
    {:ok, _} = insert_course(%{title: "Duplicate Title", slug: "dup-1"})

    {:error, changeset} = insert_course(%{title: "Duplicate Title", slug: "dup-2"})

    err = Error.from_changeset(changeset)
    assert %Error{code: :invalid, field: :title} = err
  end

  test "published/1 run with Repo.all returns only the published courses" do
    {:ok, _pub} = insert_course(%{title: "Published Course", slug: "pub", published: true})
    {:ok, _draft} = insert_course(%{title: "Draft Course", slug: "draft", published: false})

    titles = Course.published() |> Repo.all() |> Enum.map(& &1.title)
    assert titles == ["Published Course"]
  end
end
