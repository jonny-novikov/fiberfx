defmodule PortalWeb.LessonControllerTest do
  @moduledoc """
  ConnTest for the lesson routes (F6.2-US5, F6.2-US6, F6.2-D7).

  Covers the HTML `resources "/lessons", only: [:show]` route, the bare-`:error` → 404
  carve-out (F6.2-INV1 NOTE), and the `:api` `/api/lessons/:id` route that negotiates
  JSON via `accepts ["json"]` and serializes the `@derive Jason.Encoder` lesson.
  """
  use PortalWeb.ConnCase, async: false

  alias Portal.Catalog.Lesson

  setup do
    # Seed a real %Lesson{} in the Store; Portal.lesson/1 reads it via the catalog
    # (Portal.Store.get("LSN", id)), so the {:ok, lesson} branch is reachable.
    lesson = %Lesson{
      id: Portal.ID.new("LSN"),
      course_id: Portal.ID.new("CRS"),
      title: "Pattern Matching"
    }

    :ok = Portal.Store.put(lesson)
    {:ok, lesson: lesson}
  end

  describe "GET /lessons/:id (HTML)" do
    test "a stored lesson renders at 200 with its title (F6.2-US6)", %{conn: conn, lesson: lesson} do
      conn = get(conn, ~p"/lessons/#{lesson.id}")
      assert html_response(conn, 200) =~ lesson.title
    end

    test "an unknown lesson id maps the bare :error to 404 (F6.2-INV1 carve-out)", %{conn: conn} do
      conn = get(conn, ~p"/lessons/#{Portal.ID.new("LSN")}")
      assert response(conn, 404)
    end
  end

  describe "GET /api/lessons/:id (JSON)" do
    test "negotiates JSON and serializes the lesson (F6.2-US5, F6.2-D7)", %{conn: conn, lesson: lesson} do
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> get(~p"/api/lessons/#{lesson.id}")

      body = json_response(conn, 200)
      assert body["lesson"]["id"] == lesson.id
      assert body["lesson"]["title"] == lesson.title
    end

    test "an unknown lesson id returns a 404 JSON error body (carve-out)", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> get(~p"/api/lessons/#{Portal.ID.new("LSN")}")

      body = json_response(conn, 404)
      assert body["error"] == "lesson not found"
    end
  end
end
