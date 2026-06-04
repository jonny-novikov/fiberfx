defmodule Portal.CatalogTest do
  @moduledoc """
  The Repo-backed Catalog context (F6.4-D1/US2). Runs in the Ecto sandbox
  (Portal.DataCase), `async: true` — every call here touches the Repo from the test
  process, which owns the sandbox transaction (no cross-process engine read).
  """
  use Portal.DataCase, async: true

  # Runs the three `Portal.Catalog` moduledoc doctests under the sandbox: `list_courses/0`,
  # the F6.6 `search_courses("") == list_courses()` (the empty-query-returns-all property
  # the live search box's initial paint relies on), and `change_course/0` (the actionless
  # changeset). Before this they were inert prose — `Portal.Catalog` carried no `doctest`
  # invocation, so F6.6-AS0's "a doctest shows the filter" promise was unexecuted.
  doctest Portal.Catalog

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

  describe "search_courses/1 (F6.6-R8, the one ratified read-only addition)" do
    # The context-level guard for the narrowing filter the live search relies on (the
    # web exercises it through `Portal.search_courses/1`; this proves it independent of
    # the LiveView). The doctest above already pins the empty-query-returns-all property.
    test "narrows to a case-insensitive title substring, returning [Course.t()]" do
      {:ok, keep} = Catalog.create_course(%{title: "Elixir Patterns", slug: "elixir-patterns"})
      {:ok, _drop} = Catalog.create_course(%{title: "Rust Internals", slug: "rust-internals"})

      results = Catalog.search_courses("elixir")

      assert Enum.all?(results, &match?(%Course{}, &1))
      assert keep.id in Enum.map(results, & &1.id)
      refute "Rust Internals" in Enum.map(results, & &1.title)
    end
  end
end
