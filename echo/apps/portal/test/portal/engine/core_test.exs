defmodule Portal.Engine.CoreTest do
  # Not async: the `authorize/2` cases are the boundary contract against the shared
  # Portal.Store (via `course_exists`/`seed_course`), and the branded snowflake
  # sequence resets per process (so two tests minting in the same millisecond could
  # collide on an id), so this file resets the Store in setup. The store-free pure
  # cases (decide/evolve/replay/query) + the `replay==fold` property live in
  # Portal.Engine.CorePureTest (`async: true`).
  use ExUnit.Case, async: false

  alias Portal.Catalog.Course
  alias Portal.Engine.Core
  alias Portal.Learning.Events.LearnerEnrolled

  # A fixed occurrence time keeps the cases deterministic; `at` is data the boundary
  # supplies, never minted by the core.
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
end
