defmodule Portal.Engine.CoreTest do
  # Not async: the `authorize`-via-catalog cases read the shared Portal.Store, and
  # the branded snowflake sequence resets per process (so two tests minting in the
  # same millisecond could collide on an id). The pure decide/evolve/replay/query
  # cases are store-free — they only need the reset because the file is shared.
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Portal.Catalog.Course
  alias Portal.Engine.Core
  alias Portal.Learning.Events.{LearnerEnrolled, LessonDelivered}

  # A fixed occurrence time keeps the pure cases deterministic; `at` is data the
  # boundary supplies, never minted by the core.
  @at ~U[2026-01-01 00:00:00Z]

  # Start every test from an empty store, per Portal.EnrollContractTest: a freshly
  # minted "nonexistent" id is then guaranteed absent and no leftover collides.
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

  describe "decide/2 — pure, events only (F5.5-D3, INV3)" do
    test "enroll emits [%LearnerEnrolled{}] carrying the command fields" do
      user_id = Portal.ID.new("USR")
      course_id = Portal.ID.new("CRS")

      assert [%LearnerEnrolled{user_id: ^user_id, course_id: ^course_id, at: @at}] =
               Core.decide(Core.initial_state(), {:enroll, user_id, course_id, @at})
    end

    test "deliver_lesson emits [%LessonDelivered{}] carrying the command fields" do
      user_id = Portal.ID.new("USR")
      lesson_id = Portal.ID.new("LSN")

      assert [%LessonDelivered{user_id: ^user_id, lesson_id: ^lesson_id, at: @at}] =
               Core.decide(Core.initial_state(), {:deliver_lesson, user_id, lesson_id, @at})
    end

    test "decide returns a list and leaves the input state unchanged" do
      state = Core.initial_state()
      cmd = {:enroll, Portal.ID.new("USR"), Portal.ID.new("CRS"), @at}

      events = Core.decide(state, cmd)
      # CQS write side proposes facts only: a list of event structs, no state.
      assert is_list(events)
      assert Enum.all?(events, &is_struct(&1, LearnerEnrolled))
      # Pure: re-deciding on the same state yields the same events, mutating nothing.
      assert Core.decide(state, cmd) == events
    end
  end

  describe "evolve/2 — fold one event (F5.5-D4)" do
    test "folds one LearnerEnrolled into enrollments" do
      user_id = Portal.ID.new("USR")
      course_id = Portal.ID.new("CRS")

      state =
        Core.evolve(
          %LearnerEnrolled{user_id: user_id, course_id: course_id, at: @at},
          Core.initial_state()
        )

      assert MapSet.member?(state.enrollments[user_id], course_id)
      assert state.delivered == %{}
    end

    test "folds one LessonDelivered into delivered" do
      user_id = Portal.ID.new("USR")
      lesson_id = Portal.ID.new("LSN")

      state =
        Core.evolve(
          %LessonDelivered{user_id: user_id, lesson_id: lesson_id, at: @at},
          Core.initial_state()
        )

      assert MapSet.member?(state.delivered[user_id], lesson_id)
      assert state.enrollments == %{}
    end

    test "re-folding the same enrollment is idempotent (a set, not a count)" do
      user_id = Portal.ID.new("USR")
      course_id = Portal.ID.new("CRS")
      event = %LearnerEnrolled{user_id: user_id, course_id: course_id, at: @at}

      once = Core.evolve(event, Core.initial_state())
      twice = Core.evolve(event, once)

      assert once == twice
      assert MapSet.size(twice.enrollments[user_id]) == 1
    end
  end

  describe "replay/1 — state is the fold of the log (F5.5-D5, INV4)" do
    test "replay([]) == initial_state()" do
      assert Core.replay([]) == Core.initial_state()
    end

    test "rebuilds the same state a hand-written incremental fold produces" do
      u1 = Portal.ID.new("USR")
      u2 = Portal.ID.new("USR")
      c1 = Portal.ID.new("CRS")
      c2 = Portal.ID.new("CRS")
      l1 = Portal.ID.new("LSN")

      log = [
        %LearnerEnrolled{user_id: u1, course_id: c1, at: @at},
        %LearnerEnrolled{user_id: u1, course_id: c2, at: @at},
        %LessonDelivered{user_id: u1, lesson_id: l1, at: @at},
        %LearnerEnrolled{user_id: u2, course_id: c1, at: @at}
      ]

      expected =
        Core.initial_state()
        |> then(&Core.evolve(Enum.at(log, 0), &1))
        |> then(&Core.evolve(Enum.at(log, 1), &1))
        |> then(&Core.evolve(Enum.at(log, 2), &1))
        |> then(&Core.evolve(Enum.at(log, 3), &1))

      assert Core.replay(log) == expected
      assert MapSet.equal?(Core.replay(log).enrollments[u1], MapSet.new([c1, c2]))
      assert MapSet.member?(Core.replay(log).delivered[u1], l1)
    end

    property "replay(log) == folding the same events incrementally (INV4)" do
      check all(log <- list_of(event_gen()), max_runs: 200) do
        assert Core.replay(log) == Enum.reduce(log, Core.initial_state(), &Core.evolve/2)
      end
    end
  end

  describe "authorize/2 — the contract at the boundary (F5.5-INV5)" do
    test "an admissible enroll returns :ok; then decide + fold lets query list the course" do
      user_id = Portal.ID.new("USR")
      course_id = seed_course()
      state = Core.initial_state()

      assert :ok = Core.authorize(state, {:enroll, user_id, course_id, @at})

      [event] = Core.decide(state, {:enroll, user_id, course_id, @at})
      next = Core.evolve(event, state)
      assert Core.query(next, {:enrollments, user_id}) == [course_id]
    end

    test "a duplicate enroll is rejected at the boundary; decide still emits events only" do
      user_id = Portal.ID.new("USR")
      course_id = seed_course()

      # Fold one enrollment so the duplicate is "against the folded state".
      state =
        Core.evolve(
          %LearnerEnrolled{user_id: user_id, course_id: course_id, at: @at},
          Core.initial_state()
        )

      assert {:error, :already_enrolled} =
               Core.authorize(state, {:enroll, user_id, course_id, @at})

      # decide carries no error channel: called on the already-folded state it still
      # proposes the fact (events only). The boundary, not decide, does the rejecting.
      assert [%LearnerEnrolled{}] = Core.decide(state, {:enroll, user_id, course_id, @at})
    end

    test "a malformed user id is rejected with :course_not_found" do
      course_id = seed_course()

      assert {:error, :course_not_found} =
               Core.authorize(Core.initial_state(), {:enroll, "USR1", course_id, @at})
    end

    test "a well-formed but nonexistent course is rejected with :course_not_found" do
      user_id = Portal.ID.new("USR")
      # A valid CRS id that is never stored.
      course_id = Portal.ID.new("CRS")

      assert {:error, :course_not_found} =
               Core.authorize(Core.initial_state(), {:enroll, user_id, course_id, @at})
    end

    test "a wrong-namespace course id is rejected with :course_not_found" do
      user_id = Portal.ID.new("USR")
      # A well-formed id, but the wrong brand (LSN, not CRS).
      course_id = Portal.ID.new("LSN")

      assert {:error, :course_not_found} =
               Core.authorize(Core.initial_state(), {:enroll, user_id, course_id, @at})
    end

    test "deliver_lesson is always admissible at this scope" do
      assert :ok =
               Core.authorize(
                 Core.initial_state(),
                 {:deliver_lesson, Portal.ID.new("USR"), Portal.ID.new("LSN"), @at}
               )
    end
  end

  describe "query/2 — CQS read side (F5.5-D6, INV1)" do
    test "{:enrollments, user_id} returns a list and leaves state unchanged" do
      user_id = Portal.ID.new("USR")
      course_id = Portal.ID.new("CRS")

      state =
        Core.evolve(
          %LearnerEnrolled{user_id: user_id, course_id: course_id, at: @at},
          Core.initial_state()
        )

      result = Core.query(state, {:enrollments, user_id})
      assert is_list(result)
      assert result == [course_id]
      # The read mutates nothing: a second identical read sees the same state.
      assert Core.query(state, {:enrollments, user_id}) == result
    end

    test "an unknown user reads the empty list" do
      assert Core.query(Core.initial_state(), {:enrollments, Portal.ID.new("USR")}) == []
    end
  end

  # Events over a small fixed id pool so collisions and repeats (re-folds, multi-event
  # users) actually occur — the property then exercises the idempotent set fold, not
  # just disjoint singletons. Ids are fixed strings (not minted) to keep the generator
  # store-free and the run deterministic; only `@at` is carried.
  defp event_gen do
    users = StreamData.member_of(["USRaaaaaaaaaaa", "USRbbbbbbbbbbb"])
    courses = StreamData.member_of(["CRSaaaaaaaaaaa", "CRSbbbbbbbbbbb"])
    lessons = StreamData.member_of(["LSNaaaaaaaaaaa", "LSNbbbbbbbbbbb"])

    enrolled =
      StreamData.bind(users, fn u ->
        StreamData.map(courses, fn c -> %LearnerEnrolled{user_id: u, course_id: c, at: @at} end)
      end)

    delivered =
      StreamData.bind(users, fn u ->
        StreamData.map(lessons, fn l -> %LessonDelivered{user_id: u, lesson_id: l, at: @at} end)
      end)

    StreamData.one_of([enrolled, delivered])
  end
end
