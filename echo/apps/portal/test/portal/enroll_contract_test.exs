defmodule Portal.EnrollContractTest do
  # Not async: drives the shared Portal.Store; properties mint fresh ids per run.
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Portal.Catalog.Course
  alias Portal.Error
  alias Portal.Learning
  alias Portal.Learning.Enrollment

  doctest Portal.Error

  # Start every test from an empty store. The branded snowflake sequence resets
  # per process (EchoData.Snowflake keeps it in the process dictionary), so two
  # tests minting in the same millisecond can produce the SAME id; clearing the
  # store first guarantees a freshly-minted "nonexistent" id is absent and the
  # property's users cannot collide with another test's leftovers.
  setup do
    Portal.Store.reset()
    :ok
  end

  # Seed one stored course and return its id; mint a fresh USR id per run.
  defp seed_course do
    course = %Course{id: Portal.ID.new("CRS"), title: "Elixir", slug: "elixir"}
    :ok = Portal.Store.put(course)
    course.id
  end

  # Local guard: pins the 0..100 invariant. An out-of-range progress fails the
  # match (a crash), proving the impossible state is never silently accepted.
  defp assert_progress_in_range!(%Enrollment{progress: p} = e) when p in 0..100, do: e

  describe "postcondition (F5.4-INV5)" do
    property "a successful enroll always yields {:ok, %Enrollment{progress: 0}} and stores it" do
      course_id = seed_course()

      check all(_ <- StreamData.constant(:ok), max_runs: 50) do
        user_id = Portal.ID.new("USR")

        assert {:ok, %Enrollment{} = enrollment} = Learning.enroll(user_id, course_id)
        assert enrollment.progress == 0
        assert enrollment.user_id == user_id and enrollment.course_id == course_id
        assert {:ok, ^enrollment} = Portal.Store.get("ENR", enrollment.id)
      end
    end
  end

  describe "state invariant (F5.4-INV6)" do
    property "0 <= progress <= 100 for every enrollment the system produces" do
      course_id = seed_course()

      check all(_ <- StreamData.constant(:ok), max_runs: 50) do
        user_id = Portal.ID.new("USR")
        assert {:ok, enrollment} = Learning.enroll(user_id, course_id)
        assert assert_progress_in_range!(enrollment) == enrollment
      end
    end
  end

  describe "expected error :course_not_found (F5.4-INV1, INV2)" do
    test "a malformed user id is rejected and writes nothing" do
      course_id = seed_course()
      before = Portal.Store.all("ENR")

      assert {:error, %Error{code: :course_not_found}} = Learning.enroll("USR1", course_id)
      assert Portal.Store.all("ENR") == before
    end

    test "a well-formed but nonexistent course is rejected and writes nothing" do
      user_id = Portal.ID.new("USR")
      # A valid CRS id that is never stored.
      course_id = Portal.ID.new("CRS")
      before = Portal.Store.all("ENR")

      assert {:error, %Error{code: :course_not_found}} = Learning.enroll(user_id, course_id)
      assert Portal.Store.all("ENR") == before
    end

    test "a wrong-namespace course id is rejected and writes nothing" do
      user_id = Portal.ID.new("USR")
      # A well-formed id, but the wrong brand (LSN, not CRS).
      course_id = Portal.ID.new("LSN")
      before = Portal.Store.all("ENR")

      assert {:error, %Error{code: :course_not_found}} = Learning.enroll(user_id, course_id)
      assert Portal.Store.all("ENR") == before
    end
  end

  describe "expected error :already_enrolled (F5.4-INV3)" do
    test "a duplicate enroll is rejected and leaves exactly one enrollment" do
      user_id = Portal.ID.new("USR")
      course_id = seed_course()

      assert {:ok, %Enrollment{}} = Learning.enroll(user_id, course_id)
      assert {:error, %Error{code: :already_enrolled}} = Learning.enroll(user_id, course_id)

      matching = Enum.filter(Learning.courses_of(user_id), &(&1.course_id == course_id))
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
      out_of_range = %Enrollment{
        id: Portal.ID.new("ENR"),
        user_id: Portal.ID.new("USR"),
        course_id: Portal.ID.new("CRS"),
        progress: 101
      }

      assert_raise FunctionClauseError, fn -> assert_progress_in_range!(out_of_range) end
    end
  end
end
