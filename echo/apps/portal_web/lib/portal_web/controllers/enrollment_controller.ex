defmodule PortalWeb.EnrollmentController do
  @moduledoc """
  The enrollment controller (F6.2-D1 + F6.5-D0).

  Owns the `Portal.Enrollment` slice of the web surface: `index/2` reads a learner's
  enrolled courses (`get "/my/courses"`, the read MOVED here from `CourseController`
  in the F6.5 reconcile) and `create/2` enrolls a user. It calls ONLY the `Portal`
  facade (`courses_of/1`, `enroll/2`) — it names no module below the boundary, no
  persistence layer, and issues no direct process call (F6.2-INV1/F6.5-INV7). It
  renders through its own `EnrollmentHTML` (Phoenix infers `<Controller>HTML`), which
  embeds the moved enrolled-list and `:error` templates.
  """
  use PortalWeb, :controller

  @doc """
  Render the authenticated learner's enrolled courses.

  Reads `conn.assigns.current_user_id` (set by `PortalWeb.RequireUser` on the
  protected `/my/courses` route — no path param, F6.2-INV6) and calls
  `Portal.courses_of/1`, handing the closed outcome to `render_outcome/2`.
  `courses_of/1` is total today (`{:ok, [%Enrolled{}]}`), so an unknown learner
  yields `{:ok, []}` and the empty state renders at `200`; the `{:error,
  %Portal.Error{}}` arm is the defensive railway (F6.1-INV5), exercised by an
  injected-error unit test until the facade gains id-validation in a later F6 rung.
  """
  def index(conn, _params) do
    render_outcome(conn, Portal.courses_of(conn.assigns.current_user_id))
  end

  # Split into a separate function so each outcome arm is its own clause. With a single
  # inline `case`, the 1.18 type checker would prune the defensive `{:error, ...}` branch
  # as unreachable (`Portal.courses_of/1` is success-only today); distinct heads keep the
  # error path live for the injected-error unit test and the later id-validation rung.
  @spec render_outcome(Plug.Conn.t(), {:ok, [Portal.Enrollment.Enrolled.t()]}) :: Plug.Conn.t()
  @spec render_outcome(Plug.Conn.t(), {:error, Portal.Error.t()}) :: Plug.Conn.t()
  def render_outcome(conn, {:ok, courses}) do
    render(conn, :index, courses: courses)
  end

  def render_outcome(conn, {:error, %Portal.Error{} = error}) do
    conn
    |> put_status(422)
    |> render(:error, error: error)
  end

  @doc """
  Enroll a user in a course, then acknowledge or render the closed-set failure.

  On `{:ok, _enrollment}` it redirects to the joined course's catalog `:show`
  (`~p"/courses/\#{course_id}"`, F6.5-D0 — needs no session). On a `{:error,
  %Portal.Error{}}` it renders the closed-set message at `422`. The four-branch
  closed match (no catch-all) is the load-bearing part — `:already_enrolled` and
  `:course_not_found` have producers today; `:lesson_locked` and `:invalid_progress`
  are reserved (F5.8-INV3) but matched so the finite outcome set stays closed.
  """
  def create(conn, %{"user_id" => user_id, "course_id" => course_id}) do
    case Portal.enroll(user_id, course_id) do
      {:ok, _enrollment} ->
        redirect(conn, to: ~p"/courses/#{course_id}")

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

  # Render the closed-vocabulary failure at 422 through this controller's inferred
  # EnrollmentHTML (which now owns the moved :error template, F6.5-D0). No explicit
  # put_view — Phoenix infers <Controller>HTML.
  defp render_error(conn, %Portal.Error{} = error) do
    conn
    |> put_status(422)
    |> render(:error, error: error)
  end
end
