defmodule Portal.EnrollContractTest do
  # async: false — the enroll contract runs through the encapsulated, named
  # Portal.Engine (event-sourced); since F6.4 the course-exists gate reads
  # Catalog.fetch_course/1 -> Repo INSIDE the Engine process. Portal.DataCase with
  # async: false checks out a SHARED sandbox owner so the Engine process sees the course
  # seeded via Repo here; the properties mint fresh USR ids per run. DataCase +
  # ExUnitProperties compose. The Store/adapter/Engine resets give per-test fold
  # isolation (the not-already-enrolled check reads the Engine fold, not the Store).
  use Portal.DataCase, async: false
  use ExUnitProperties

  alias Portal.Catalog
  alias Portal.Enrollment
  alias Portal.Enrollment.Enrolled
  alias Portal.Error

  doctest Portal.Error

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

  # Seed one course via the Repo-backed Catalog (F6.4) and return its branded id. A
  # strong-random title token, so it never collides — not even with rows other suites
  # commit (the portal_web ConnTests have no Ecto sandbox).
  defp seed_course do
    tok = Base.encode16(:crypto.strong_rand_bytes(8))
    {:ok, course} = Catalog.create_course(%{title: "Elixir #{tok}", slug: "elixir-#{tok}"})
    course.id
  end

  # Local guard: pins the 0..100 invariant. An out-of-range progress fails the
  # match (a crash), proving the impossible state is never silently accepted.
  defp assert_progress_in_range!(%Enrolled{progress: p} = e) when p in 0..100, do: e

  describe "postcondition (F5.4-INV5)" do
    property "a successful enroll always yields {:ok, %Enrolled{progress: 0}}" do
      course_id = seed_course()

      check all(_ <- StreamData.constant(:ok), max_runs: 50) do
        user_id = Portal.ID.new("USR")

        assert {:ok, %Enrolled{} = enrolled} = Enrollment.enroll(user_id, course_id)
        assert enrolled.progress == 0
        assert enrolled.user_id == user_id and enrolled.course_id == course_id

        # The engine projects a Store %Enrollment{} row keyed by the published id.
        assert {:ok, %Portal.Enrollment.Enrollment{}} = Portal.Store.get("ENR", enrolled.id)
      end
    end
  end

  describe "state invariant (F5.4-INV6)" do
    property "0 <= progress <= 100 for every enrollment the system produces" do
      course_id = seed_course()

      check all(_ <- StreamData.constant(:ok), max_runs: 50) do
        user_id = Portal.ID.new("USR")
        assert {:ok, enrolled} = Enrollment.enroll(user_id, course_id)
        assert assert_progress_in_range!(enrolled) == enrolled
      end
    end
  end

  describe "expected error :course_not_found (F5.4-INV1, INV2)" do
    test "a malformed user id is rejected and writes nothing" do
      course_id = seed_course()
      before = Portal.Store.all("ENR")

      assert {:error, %Error{code: :course_not_found}} = Enrollment.enroll("USR1", course_id)
      assert Portal.Store.all("ENR") == before
    end

    test "a well-formed but nonexistent course is rejected and writes nothing" do
      user_id = Portal.ID.new("USR")
      # A valid CRS id that is never stored.
      course_id = Portal.ID.new("CRS")
      before = Portal.Store.all("ENR")

      assert {:error, %Error{code: :course_not_found}} = Enrollment.enroll(user_id, course_id)
      assert Portal.Store.all("ENR") == before
    end

    test "a wrong-namespace course id is rejected and writes nothing" do
      user_id = Portal.ID.new("USR")
      # A well-formed id, but the wrong brand (LSN, not CRS).
      course_id = Portal.ID.new("LSN")
      before = Portal.Store.all("ENR")

      assert {:error, %Error{code: :course_not_found}} = Enrollment.enroll(user_id, course_id)
      assert Portal.Store.all("ENR") == before
    end
  end

  describe "expected error :already_enrolled (F5.4-INV3)" do
    test "a duplicate enroll is rejected and leaves exactly one enrollment" do
      user_id = Portal.ID.new("USR")
      course_id = seed_course()

      assert {:ok, %Enrolled{}} = Enrollment.enroll(user_id, course_id)
      assert {:error, %Error{code: :already_enrolled}} = Enrollment.enroll(user_id, course_id)

      {:ok, listed} = Enrollment.courses_of(user_id)
      matching = Enum.filter(listed, &(&1.course_id == course_id))
      assert length(matching) == 1
    end
  end

  describe "closed error vocabulary (F5.4-INV3)" do
    test "Portal.Error.new/1 carries a human-readable message for each code" do
      assert %Error{code: :course_not_found, message: "course not found"} =
               Error.new(:course_not_found)

      assert %Error{code: :already_enrolled, message: "already enrolled in this course"} =
               Error.new(:already_enrolled)
    end
  end

  describe "impossible state crashes, never returns a tuple (F5.4-INV4)" do
    test "an out-of-range progress fails the 0..100 guard (a crash)" do
      out_of_range = %Enrolled{
        id: Portal.ID.new("ENR"),
        user_id: Portal.ID.new("USR"),
        course_id: Portal.ID.new("CRS"),
        progress: 101
      }

      assert_raise FunctionClauseError, fn -> assert_progress_in_range!(out_of_range) end
    end
  end
end
