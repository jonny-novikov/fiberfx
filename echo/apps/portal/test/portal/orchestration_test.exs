defmodule Portal.OrchestrationTest do
  @moduledoc """
  The `enroll_and_welcome/2` cross-context `with` orchestration (F6.4-D6/US5/INV5/INV6).
  Chains Catalog (Repo) -> Enrollment (engine over the port) -> Accounts (Store),
  short-circuiting to one closed `%Portal.Error{}`.

  async: false + Portal.DataCase shared sandbox — the enroll step runs through the
  encapsulated, named Portal.Engine, whose course-exists gate reads
  Catalog.fetch_course/1 -> Repo INSIDE the Engine process. The Store/adapter/Engine
  resets give per-test fold isolation.
  """
  use Portal.DataCase, async: false

  alias Portal.{Accounts, Catalog}
  alias Portal.Accounts.User
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

  defp seed_user do
    user = %User{id: Portal.ID.new("USR"), email: "a@b.c", name: "Ada"}
    :ok = Portal.Store.put(user)
    user.id
  end

  defp seed_course do
    tok = Base.encode16(:crypto.strong_rand_bytes(8))
    {:ok, course} = Catalog.create_course(%{title: "Elixir #{tok}", slug: "elixir-#{tok}"})
    course.id
  end

  test "happy path: chains all three contexts and returns {:ok, %Enrolled{}}" do
    user_id = seed_user()
    course_id = seed_course()

    assert {:ok, %Enrolled{} = enrolled} =
             Enrollment.enroll_and_welcome(user_id, course_id)

    assert enrolled.user_id == user_id and enrolled.course_id == course_id
    # The welcome step is real: the seeded learner resolves.
    assert {:ok, %User{}} = Accounts.welcome(user_id)
  end

  test "short-circuit on a missing course: one closed %Portal.Error{:course_not_found}, no enroll" do
    user_id = seed_user()
    # A well-formed CRS id that was never created in the catalog.
    absent_course = Portal.ID.new("CRS")

    assert {:error, %Portal.Error{code: :course_not_found}} =
             Enrollment.enroll_and_welcome(user_id, absent_course)

    # The chain stopped at the first step — nothing was enrolled.
    assert {:ok, []} = Enrollment.courses_of(user_id)
  end

  test "short-circuit on a missing learner: folds to %Portal.Error{:user_not_found}" do
    # A well-formed USR id that was never stored, so welcome/1 misses after enroll.
    user_id = Portal.ID.new("USR")
    course_id = seed_course()

    assert {:error, %Portal.Error{code: :user_not_found}} =
             Enrollment.enroll_and_welcome(user_id, course_id)
  end
end
