defmodule Portal.Catalog.CourseTest do
  @moduledoc """
  DB-FREE tests for the F6.3 parse boundary (F6.3-INV6): `Course.changeset/2`, the
  `Portal.Catalog.CourseID` custom-type round-trip, and the `published/1` query
  builder. Pure — no sandbox, `async: true`. The DB round-trip lives in
  `Portal.PersistenceTest`.
  """
  use ExUnit.Case, async: true

  alias Portal.Catalog.Course
  alias Portal.Catalog.CourseID

  describe "changeset/2" do
    test "valid attrs produce a valid changeset" do
      cs = Course.changeset(%{title: "Elixir", slug: "elixir", published: true})
      assert cs.valid?
      assert cs.changes.title == "Elixir"
      assert cs.changes.slug == "elixir"
      assert cs.changes.published == true
    end

    test ":published is optional and defaults false" do
      cs = Course.changeset(%{title: "Elixir", slug: "elixir"})
      assert cs.valid?
      refute Map.has_key?(cs.changes, :published)
    end

    test "missing :title errors on :title" do
      cs = Course.changeset(%{slug: "elixir"})
      refute cs.valid?
      assert Keyword.has_key?(cs.errors, :title)
    end

    test "missing :slug errors on :slug" do
      cs = Course.changeset(%{title: "Elixir"})
      refute cs.valid?
      assert Keyword.has_key?(cs.errors, :slug)
    end

    test "a too-short title (len < 3) errors on :title" do
      cs = Course.changeset(%{title: "ab", slug: "s"})
      refute cs.valid?
      assert Keyword.has_key?(cs.errors, :title)
    end

    test ":id is not cast from untrusted attrs" do
      cs = Course.changeset(%{id: "CRSaaaaaaaaaaa", title: "Elixir", slug: "elixir"})
      refute Map.has_key?(cs.changes, :id)
    end
  end

  describe "CourseID custom type" do
    test "cast accepts a valid branded id, rejects a non-valid string" do
      branded = Portal.ID.new("CRS")
      assert {:ok, ^branded} = CourseID.cast(branded)
      assert :error = CourseID.cast("not-a-branded-id")
      assert :error = CourseID.cast(42)
    end

    test "load(dump(branded)) == branded — the round-trip is identity" do
      branded = Portal.ID.new("CRS")
      assert {:ok, int} = CourseID.dump(branded)
      assert is_integer(int)
      assert {:ok, ^branded} = CourseID.load(int)
    end

    test "dump(load(int)) == int — the inverse round-trip is identity" do
      int = EchoData.Snowflake.generate(worker_id: 1)
      assert {:ok, branded} = CourseID.load(int)
      assert Portal.ID.valid?(branded)
      assert {:ok, ^int} = CourseID.dump(branded)
    end

    test "type/0 maps to :integer (the :bigint column)" do
      assert CourseID.type() == :integer
    end
  end

  describe "published/1 query builder (DB-free construction)" do
    test "returns an Ecto.Query value without running it" do
      assert %Ecto.Query{} = Course.published()
    end
  end
end
