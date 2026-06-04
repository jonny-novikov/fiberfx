defmodule Portal.Engine.CorePureTest do
  # Async: every case here is store-free and clock-free — the pure
  # decide/evolve/replay/query surface plus the doctest and the set-monotonicity
  # property. No shared process state, so the fast base of the test pyramid runs in
  # parallel (F5.7-D6/INV2). The store-touching `authorize/2` cases stay serialised
  # in Portal.Engine.CoreTest. The numeric-progress monotonic property (F5.7-D2/INV3)
  # is DEFERRED: the F5.5 model has no progress-advancing event (`evolve` folds set
  # membership; `progress` stays 0), so there is no operation to exercise — inventing
  # one would add domain behaviour from a testing rung. The monotonic INTENT is met
  # below by the set-monotonicity property (a forward event never shrinks a user's
  # enrolled/delivered set); the `0..100` bound is property-tested in
  # Portal.EnrollContractTest.
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Portal.Engine.Core
  alias Portal.Enrollment.Events.{LearnerEnrolled, LessonDelivered}

  doctest Portal.Engine.Core

  # A fixed occurrence time keeps the pure cases deterministic; `at` is data the
  # boundary supplies, never minted by the core.
  @at ~U[2026-01-01 00:00:00Z]

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

  describe "set-monotonicity — a forward event never shrinks a user's sets (INV3, monotonic intent)" do
    # The honest substitute for the numeric-progress monotonic (deferred above):
    # `evolve` only ever adds set membership, so appending any forward event to a log
    # leaves every user's enrolled/delivered set a superset of what it was before.
    property "appending an event keeps every user's enrolled and delivered sets a superset" do
      check all(log <- list_of(event_gen()), extra <- event_gen(), max_runs: 200) do
        before = Core.replay(log)
        after_state = Core.replay(log ++ [extra])

        for {user_id, set} <- before.enrollments do
          assert MapSet.subset?(set, Map.get(after_state.enrollments, user_id, MapSet.new()))
        end

        for {user_id, set} <- before.delivered do
          assert MapSet.subset?(set, Map.get(after_state.delivered, user_id, MapSet.new()))
        end
      end
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
