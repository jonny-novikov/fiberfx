defmodule PortalWeb.EnrollmentController do
  @moduledoc """
  The thin write controller for enrolling a user in a course (F6.2-D1).

  `create/2` calls ONLY the `Portal` facade (`Portal.enroll/2`) — it names no module
  below the boundary, no persistence layer, and issues no direct process call
  (F6.2-INV1). It branches the CLOSED `%Portal.Error{}` code set with NO catch-all
  (the exhaustive-consumer shape from `Portal`'s moduledoc): a new code would force a
  new branch. Kept thin — the full enroll UI is F6.4.
  """
  use PortalWeb, :controller

  @doc """
  Enroll a user in a course, then acknowledge or render the closed-set failure.

  On `{:ok, _enrollment}` it redirects to the user's course list. On a
  `{:error, %Portal.Error{}}` it renders the closed-set message at `422` (the
  defensive-render idiom F6.1's `CourseController` established). The four-branch
  closed match (no catch-all) is the load-bearing part — `:already_enrolled` and
  `:course_not_found` have producers today; `:lesson_locked` and `:invalid_progress`
  are reserved (F5.8-INV3) but matched so the finite outcome set stays closed.
  """
  def create(conn, %{"user_id" => user_id, "course_id" => course_id}) do
    case Portal.enroll(user_id, course_id) do
      {:ok, _enrollment} ->
        redirect(conn, to: ~p"/courses/#{user_id}")

      {:error, %Portal.Error{code: :already_enrolled} = error} ->
        render_error(conn, error)

      {:error, %Portal.Error{code: :course_not_found} = error} ->
        render_error(conn, error)

      {:error, %Portal.Error{code: :lesson_locked} = error} ->
        render_error(conn, error)

      {:error, %Portal.Error{code: :invalid_progress} = error} ->
        render_error(conn, error)
    end
  end

  # Render the closed-vocabulary failure at 422, reusing CourseHTML's :error template
  # (the shared expected-failure render of the closed %Portal.Error{} set, F6.1-INV4).
  defp render_error(conn, %Portal.Error{} = error) do
    conn
    |> put_status(422)
    |> put_view(html: PortalWeb.CourseHTML)
    |> render(:error, error: error)
  end
end
