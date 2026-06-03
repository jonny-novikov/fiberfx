defmodule Portal.Web.EnrollSliceTest do
  # Not async: drives the real, shared stack (router → engine → contexts → store).
  use ExUnit.Case, async: false
  import Plug.Test

  setup do
    # Fold-touching test: enroll now folds into the shared Portal.Engine + the event
    # stream (the configured InMemory adapter the engine reads through since F5.8).
    # Reset Store + adapter + Engine BEFORE seeding so each test starts from an empty
    # fold and store — otherwise a prior test's enrollment plus a same-millisecond id
    # collision (the per-process snowflake hazard, CLAUDE.md §4) can wrongly reject a
    # fresh enroll as :already_enrolled. Empty the stream before the Engine re-folds
    # so it re-folds the now-empty stream. The standard fold-isolation every
    # fold-touching test uses (see Portal.EngineTest); seeds below survive it.
    Portal.Store.reset()
    Portal.EventStore.InMemory.reset()
    Portal.Engine.reset()

    # Seed the live store with real minted ids — no mocks, no "USR1" placeholders.
    user = %Portal.Accounts.User{id: Portal.ID.new("USR"), email: "ada@example.com", name: "Ada"}
    course = %Portal.Catalog.Course{id: Portal.ID.new("CRS"), title: "Elixir", slug: "elixir"}

    lesson = %Portal.Catalog.Lesson{
      id: Portal.ID.new("LSN"),
      course_id: course.id,
      title: "Intro"
    }

    Enum.each([user, course, lesson], &Portal.Store.put/1)
    %{user: user, course: course, lesson: lesson}
  end

  defp call(method, path), do: Portal.Web.Router.call(conn(method, path), [])

  test "POST /enroll creates a persisted enrollment, 201 + a valid ENR id", %{
    user: user,
    course: course
  } do
    conn = call(:post, "/enroll?user=#{user.id}&course=#{course.id}")

    assert conn.status == 201
    assert %{"data" => %{"id" => id}} = Jason.decode!(conn.resp_body)
    assert Portal.ID.valid?(id) and Portal.ID.namespace(id) == "ENR"

    # Persisted with progress 0, referencing the real ids — read it from the store.
    assert {:ok, enrollment} = Portal.Store.get("ENR", id)
    assert enrollment.progress == 0
    assert enrollment.user_id == user.id and enrollment.course_id == course.id
  end

  test "GET /lessons/:id returns 200 with the lesson; 404 for an unknown id", %{lesson: lesson} do
    ok = call(:get, "/lessons/#{lesson.id}")
    assert ok.status == 200
    assert %{"data" => %{"id" => lesson_id, "title" => "Intro"}} = Jason.decode!(ok.resp_body)
    assert lesson_id == lesson.id

    # A valid-but-unstored id → 404 (not found), not a malformed-string accident.
    assert call(:get, "/lessons/#{Portal.ID.new("LSN")}").status == 404
  end

  test "GET /courses/:user_id lists the user's enrollments", %{user: user, course: course} do
    %{status: 201, resp_body: body} = call(:post, "/enroll?user=#{user.id}&course=#{course.id}")
    %{"data" => %{"id" => id}} = Jason.decode!(body)

    conn = call(:get, "/courses/#{user.id}")
    assert conn.status == 200
    assert %{"data" => enrollments} = Jason.decode!(conn.resp_body)
    assert Enum.any?(enrollments, &(&1["id"] == id))
  end

  test "expected failures map to 4xx, never 500" do
    assert call(:get, "/lessons/#{Portal.ID.new("LSN")}").status == 404
    assert call(:get, "/nope").status == 404
  end

  test "POST /enroll with a malformed user id → 422 :course_not_found", %{course: course} do
    # "USR1" passes namespace/1 but fails valid?/1 → rejected at the door.
    conn = call(:post, "/enroll?user=USR1&course=#{course.id}")

    assert conn.status == 422
    assert %{"error" => %{"code" => "course_not_found"}} = Jason.decode!(conn.resp_body)
  end
end
