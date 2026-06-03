defmodule Portal.EngineTest do
  # Not async: drives the shared, named Portal.Engine / Portal.EventLog /
  # Portal.Store, and one test kills the Engine.
  use ExUnit.Case, async: false

  alias Portal.Catalog.Course
  alias Portal.Catalog.Lesson
  alias Portal.Learning.Enrollment

  setup do
    # Start each test from clean shared state. Resetting Store + EventLog clears
    # the persisted rows and the log; the Engine is then re-folded from the
    # now-empty log via Portal.Engine.reset/0 (a synchronous re-fold, mirroring
    # Store.reset/0), so every test begins with a genuinely empty fold AND empty
    # Store. This avoids cross-test contamination — the running Engine's in-memory
    # fold would otherwise still carry prior tests' enrollments, so a later test
    # minting a colliding (USR, CRS) pair (the per-process snowflake sequence
    # resets to 0 per test — Portal.Store.reset/0, CLAUDE.md §4) could read a stale
    # fold and be wrongly rejected as :already_enrolled. Re-folding (not killing)
    # keeps this off the supervisor's restart-intensity budget.
    reset_shared_state()

    # Leave the shared Engine/EventLog/Store as clean as found, so an enrollment
    # this file folds cannot persist into the next test file and collide there with
    # a same-millisecond-minted id pair (the per-process snowflake hazard, CLAUDE.md
    # §4) — which would wrongly reject that file's enroll as :already_enrolled.
    on_exit(&reset_shared_state/0)
    :ok
  end

  # Clear the persisted rows + log, then re-fold the Engine from the now-empty log
  # (Engine.reset/0 mirrors Store/EventLog reset; re-folding, not killing, keeps
  # this off the supervisor's restart-intensity budget).
  defp reset_shared_state do
    Portal.Store.reset()
    Portal.EventLog.reset()
    Portal.Engine.reset()
  end

  # Seed one stored course and return its id (mirrors the slice/contract tests).
  defp seed_course do
    course = %Course{id: Portal.ID.new("CRS"), title: "Elixir", slug: "elixir"}
    :ok = Portal.Store.put(course)
    course.id
  end

  describe "command → query round-trip (D2/D3/D8)" do
    test "a valid enroll returns {:ok, %Enrollment{}} and :courses_of then lists it" do
      user_id = Portal.ID.new("USR")
      course_id = seed_course()

      assert {:ok, %Enrollment{} = enrollment} =
               Portal.Engine.dispatch(%{type: :enroll, user_id: user_id, course_id: course_id})

      assert Portal.ID.valid?(enrollment.id) and Portal.ID.namespace(enrollment.id) == "ENR"
      assert enrollment.user_id == user_id and enrollment.course_id == course_id
      assert enrollment.progress == 0

      listed = Portal.Engine.query(:courses_of, user_id)
      assert Enum.any?(listed, &(&1.id == enrollment.id and &1.course_id == course_id))
    end
  end

  describe "command admissibility via the fold's authorize (D3, INV2)" do
    test "a duplicate enroll is rejected as %Portal.Error{:already_enrolled} and state is unchanged" do
      user_id = Portal.ID.new("USR")
      course_id = seed_course()

      assert {:ok, %Enrollment{}} =
               Portal.Engine.dispatch(%{type: :enroll, user_id: user_id, course_id: course_id})

      assert {:error, %Portal.Error{code: :already_enrolled}} =
               Portal.Engine.dispatch(%{type: :enroll, user_id: user_id, course_id: course_id})

      # Exactly one enrollment for the pair survives the rejection.
      listed = Portal.Engine.query(:courses_of, user_id)
      assert Enum.count(listed, &(&1.course_id == course_id)) == 1
    end

    test "a malformed user id is rejected as %Portal.Error{:course_not_found}" do
      course_id = seed_course()

      assert {:error, %Portal.Error{code: :course_not_found}} =
               Portal.Engine.dispatch(%{type: :enroll, user_id: "USR1", course_id: course_id})
    end
  end

  describe "query never mutates (D4, INV2)" do
    test "running a query leaves the held state identical" do
      user_id = Portal.ID.new("USR")
      _course_id = seed_course()

      before = :sys.get_state(Portal.Engine)
      _ = Portal.Engine.query(:courses_of, user_id)
      assert :sys.get_state(Portal.Engine) == before
    end
  end

  describe "unknown command / query tuples (D5)" do
    test "an unrecognised command maps to {:error, :unknown_command}" do
      assert {:error, :unknown_command} = Portal.Engine.dispatch(%{type: :nope})
      # An incomplete enroll map (the supervision test's shape) also folds to unknown.
      assert {:error, :unknown_command} = Portal.Engine.dispatch(%{type: :enroll})
    end

    test "an unrecognised query maps to {:error, :unknown_query}" do
      assert {:error, :unknown_query} = Portal.Engine.query(:bogus, "x")
    end
  end

  describe ":lesson stays a catalog read (D4)" do
    test "a seeded lesson returns {:ok, %Lesson{}}; an unknown id returns :error" do
      course_id = seed_course()
      lesson = %Lesson{id: Portal.ID.new("LSN"), course_id: course_id, title: "Intro"}
      :ok = Portal.Store.put(lesson)

      assert {:ok, %Lesson{title: "Intro"}} = Portal.Engine.query(:lesson, lesson.id)
      assert :error = Portal.Engine.query(:lesson, Portal.ID.new("LSN"))
    end
  end

  describe "crash recovery: re-fold + re-project the same state (D6/D7/D8, INV3)" do
    test "killing Portal.Engine and re-querying returns the SAME enrollment list" do
      user_id = Portal.ID.new("USR")
      course_id = seed_course()

      assert {:ok, %Enrollment{}} =
               Portal.Engine.dispatch(%{type: :enroll, user_id: user_id, course_id: course_id})

      before = Portal.Engine.query(:courses_of, user_id)
      assert Enum.any?(before, &(&1.course_id == course_id))

      pid = Process.whereis(Portal.Engine)
      ref = Process.monitor(pid)
      Process.exit(pid, :kill)
      assert_receive {:DOWN, ^ref, :process, ^pid, :killed}, 1_000

      new_pid = wait_for_restart(pid)
      assert is_pid(new_pid) and new_pid != pid

      # The EventLog survived the kill; init/1 re-folded it and reproject_enrollments/1
      # re-established the Store rows, so the query returns the SAME list.
      after_restart = Portal.Engine.query(:courses_of, user_id)
      assert MapSet.new(before, & &1.course_id) == MapSet.new(after_restart, & &1.course_id)
      assert after_restart != []
    end
  end

  # Await a fresh Portal.Engine pid after a kill (the supervision_test.exs shape).
  defp wait_for_restart(old_pid, tries \\ 50)
  defp wait_for_restart(_old_pid, 0), do: flunk("Portal.Engine did not restart")

  defp wait_for_restart(old_pid, tries) do
    case Process.whereis(Portal.Engine) do
      nil -> retry(old_pid, tries)
      ^old_pid -> retry(old_pid, tries)
      new_pid -> new_pid
    end
  end

  defp retry(old_pid, tries) do
    Process.sleep(20)
    wait_for_restart(old_pid, tries - 1)
  end
end
