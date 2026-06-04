defmodule Portal.EnrollmentTest do
  # async: false — the direct-call `Portal.Enrollment.enroll/2` contract runs through
  # the encapsulated, named Portal.Engine (event-sourced), and since F6.4 the engine's
  # course-exists gate reads Catalog.fetch_course/1 -> Repo INSIDE the Engine process.
  # Portal.DataCase with async: false checks out a SHARED sandbox owner so the Engine
  # process sees the course this test seeds via Repo (F6.4 fork-B). The Store/adapter/
  # Engine resets give per-test fold isolation (CLAUDE.md §4); the sandbox rolls the
  # course insert back at teardown.
  use Portal.DataCase, async: false

  alias Portal.Catalog
  alias Portal.Enrollment
  alias Portal.Enrollment.Enrolled

  setup do
    Portal.Store.reset()
    Portal.EventStore.InMemory.reset()
    Portal.Engine.reset()

    on_exit(fn ->
      Portal.Store.reset()
      Portal.EventStore.InMemory.reset()
      Portal.Engine.reset()
    end)

    :ok
  end

  test "enroll/2 returns a published %Enrolled{progress: 0} and lists it" do
    user_id = Portal.ID.new("USR")
    {:ok, course} = Catalog.create_course(%{title: "Elixir", slug: "elixir"})

    assert {:ok, %Enrolled{} = e} = Enrollment.enroll(user_id, course.id)

    assert Portal.ID.valid?(e.id) and Portal.ID.namespace(e.id) == "ENR"
    assert e.user_id == user_id and e.course_id == course.id
    assert e.progress == 0

    assert {:ok, listed} = Enrollment.courses_of(user_id)
    assert Enum.any?(listed, &(&1.id == e.id and &1.course_id == course.id))
    assert Enum.all?(listed, &match?(%Enrolled{}, &1))
  end

  test "a duplicate enroll is rejected as %Portal.Error{:already_enrolled}" do
    user_id = Portal.ID.new("USR")
    {:ok, course} = Catalog.create_course(%{title: "Elixir Dup", slug: "elixir-dup"})

    assert {:ok, %Enrolled{}} = Enrollment.enroll(user_id, course.id)

    assert {:error, %Portal.Error{code: :already_enrolled}} =
             Enrollment.enroll(user_id, course.id)
  end

  test "a well-formed but nonexistent course is rejected as %Portal.Error{:course_not_found}" do
    user_id = Portal.ID.new("USR")
    course_id = Portal.ID.new("CRS")

    assert {:error, %Portal.Error{code: :course_not_found}} =
             Enrollment.enroll(user_id, course_id)
  end
end
