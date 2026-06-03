defmodule Portal.LearningTest do
  # Not async: writes to the shared Portal.Store.
  use ExUnit.Case, async: false

  alias Portal.Learning
  alias Portal.Learning.Enrollment

  # Start from an empty Store so a leftover ENR from a prior test cannot collide:
  # `Learning.enroll/2` is the F5.4 Store path (not the engine fold), and its
  # not-already-enrolled check reads the Store via `courses_of/1`. The branded
  # snowflake sequence resets per process (CLAUDE.md §4), so two tests minting in
  # the same millisecond can produce the same (user, course) pair — a stale row for
  # that pair would flip this enroll's `{:ok, _}` to `:already_enrolled`. Store.reset
  # alone suffices (no fold here, so no EventLog/Engine reset needed).
  setup do
    Portal.Store.reset()
    :ok
  end

  test "enroll/2 mints an ENR id, persists progress 0, and lists it" do
    user_id = Portal.ID.new("USR")
    course_id = Portal.ID.new("CRS")
    # enroll/2 now checks the course exists (F5.4) — seed it in the store first.
    :ok = Portal.Store.put(%Portal.Catalog.Course{id: course_id, title: "Elixir", slug: "elixir"})

    assert {:ok, %Enrollment{} = e} = Learning.enroll(user_id, course_id)

    assert Portal.ID.valid?(e.id) and Portal.ID.namespace(e.id) == "ENR"
    assert e.user_id == user_id and e.course_id == course_id
    assert e.progress == 0

    assert {:ok, ^e} = Portal.Store.get("ENR", e.id)
    assert e in Learning.courses_of(user_id)
  end
end
