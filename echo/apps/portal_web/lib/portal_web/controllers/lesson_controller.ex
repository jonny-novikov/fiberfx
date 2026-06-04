defmodule PortalWeb.LessonController do
  @moduledoc """
  The thin catalog-read controller for a single lesson (F6.2-D1).

  Both actions call ONLY the `Portal` facade (`Portal.lesson/1`) — they name no
  module below the boundary, no persistence layer, and issue no direct process call
  (F6.2-INV1). `show/2` backs `resources "/lessons", only: [:show]` (HTML);
  `show_json/2` backs the `:api` route (JSON).

  ## The lesson-not-found carve-out (F6.2-INV1 NOTE)

  `Portal.lesson/1 :: {:ok, %Portal.Catalog.Lesson{}} | :error` returns a BARE
  `:error` (`apps/portal/lib/portal.ex:90`), and the closed `%Portal.Error{}` code
  set has NO `:lesson_not_found` (`apps/portal/lib/portal/error.ex:19`). Both actions
  map that bare `:error` DIRECTLY to a `404` — they construct no `%Portal.Error{}`
  and add no new code. This is the narrow, spec-blessed exception to INV1's "render
  only `%Portal.Error{}`" rule, scoped solely to the catalog-not-found path; the
  frozen four-code domain vocabulary below the facade is NOT mutated. Every
  domain-failure path elsewhere still renders only `%Portal.Error{}`.
  """
  use PortalWeb, :controller

  @doc """
  Render a lesson as HTML, or a `404` when the catalog has no such lesson.

  `Portal.lesson/1` returns `{:ok, lesson}` for a stored lesson and a bare `:error`
  for a missing one; the `:error` arm maps directly to `404` (the carve-out above).
  """
  def show(conn, %{"id" => id}) do
    case Portal.lesson(id) do
      {:ok, lesson} ->
        render(conn, :show, lesson: lesson)

      :error ->
        conn
        |> put_status(:not_found)
        |> text("lesson not found")
    end
  end

  @doc """
  Return a lesson as JSON, or a `404` JSON body when the catalog has no such lesson.

  The `%Portal.Catalog.Lesson{}` struct is `@derive {Jason.Encoder, only: [:id,
  :course_id, :title]}` (`apps/portal/lib/portal/catalog/lesson.ex:3`), so it
  JSON-encodes itself — no struct→map mapping in the web layer. The bare `:error`
  maps directly to a `404` JSON body (the carve-out above).
  """
  def show_json(conn, %{"id" => id}) do
    case Portal.lesson(id) do
      {:ok, lesson} ->
        json(conn, %{lesson: lesson})

      :error ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "lesson not found"})
    end
  end
end
