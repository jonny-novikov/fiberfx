defmodule Portal.CatalogTest do
  @moduledoc """
  The Repo-backed Catalog context (F6.4-D1/US2). Runs in the Ecto sandbox
  (Portal.DataCase), `async: true` — every call here touches the Repo from the test
  process, which owns the sandbox transaction (no cross-process engine read).
  """
  use Portal.DataCase, async: true

  alias Portal.Catalog
  alias Portal.Catalog.Course

  describe "create_course/1 (F6.4-D1)" do
    test "mints a branded CRS id, returns {:ok, %Course{}}" do
      assert {:ok, %Course{} = course} =
               Catalog.create_course(%{title: "Elixir", slug: "elixir"})

      assert Portal.ID.valid?(course.id) and Portal.ID.namespace(course.id) == "CRS"
      assert course.title == "Elixir"
      assert course.slug == "elixir"
      assert course.published == false
    end

    test "an invalid changeset returns {:error, %Ecto.Changeset{}}" do
      assert {:error, %Ecto.Changeset{} = changeset} =
               Catalog.create_course(%{title: "ab", slug: "x"})

      refute changeset.valid?
    end
  end

  describe "fetch_course/1 (F6.4-D1, the composing-context surface)" do
    test "a stored course returns {:ok, %Course{}}" do
      {:ok, course} = Catalog.create_course(%{title: "Functional", slug: "fp"})
      assert {:ok, %Course{id: id}} = Catalog.fetch_course(course.id)
      assert id == course.id
    end

    test "a well-formed but absent id returns {:error, :not_found}" do
      assert {:error, :not_found} = Catalog.fetch_course(Portal.ID.new("CRS"))
    end
  end

  describe "get_course!/1 (F6.4-D1, the controller surface)" do
    test "a stored course is returned" do
      {:ok, course} = Catalog.create_course(%{title: "Concurrency", slug: "otp"})
      assert %Course{id: id} = Catalog.get_course!(course.id)
      assert id == course.id
    end

    test "an absent id raises Ecto.NoResultsError" do
      assert_raise Ecto.NoResultsError, fn -> Catalog.get_course!(Portal.ID.new("CRS")) end
    end
  end

  describe "list_courses/0 (F6.4-D1)" do
    test "returns every stored course as %Course{} structs" do
      {:ok, a} = Catalog.create_course(%{title: "Course A", slug: "a"})
      {:ok, b} = Catalog.create_course(%{title: "Course B", slug: "b"})

      ids = Catalog.list_courses() |> Enum.map(& &1.id)
      assert a.id in ids and b.id in ids
      assert Enum.all?(Catalog.list_courses(), &match?(%Course{}, &1))
    end
  end
end
