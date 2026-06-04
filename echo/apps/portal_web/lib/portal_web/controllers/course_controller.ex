defmodule PortalWeb.CourseController do
  @moduledoc """
  The catalog resource controller (F6.5-D0/INV7).

  `CourseController` is the **pure catalog resource** — `index`/`show`/`new`/`create`
  over the `Portal.Catalog` slice — after the F6.5 reconcile moved the enrolled read
  to `EnrollmentController.index` (`/my/courses`). It calls ONLY the `Portal` facade
  (`list_courses/0`, `get_course!/1`, `change_course/0`, `create_course/1`) — it
  names no context, no `Repo`, no `%Course{}`, and issues no direct process call
  (F6.5-INV1/INV7). The controller performs all data access; the templates render
  only from assigns (F6.5-INV1). `health/2` is the domain-free liveness action
  (F6.1-R6), the only action that does not reach the facade.
  """
  use PortalWeb, :controller

  @doc """
  The catalog list. `Portal.list_courses/0` returns `[%Course{}]`; the template
  renders each with a `~p` link to `:show`, an escaped title, and an `:if` badge,
  with no data access of its own (F6.5-D1/INV1).
  """
  def index(conn, _params) do
    render(conn, :index, courses: Portal.list_courses())
  end

  @doc """
  One catalog course. `Portal.get_course!/1` raises `Ecto.NoResultsError` on a miss,
  which the router maps to a 404 (F6.5-D8). The template renders the escaped title
  and an `:if` badge from the assign.
  """
  def show(conn, %{"id" => id}) do
    render(conn, :show, course: Portal.get_course!(id))
  end

  @doc """
  The create form. `Portal.change_course/0` returns an unsaved, actionless
  `%Ecto.Changeset{}` (no `:action`), so `to_form/1` renders a blank form with no
  premature errors (F6.5-D9). `<.form>`/`<.input>` are the locally-defined catalog
  components.
  """
  def new(conn, _params) do
    render(conn, :new, form: to_form(Portal.change_course()))
  end

  @doc """
  Create a course from the form params. `to_form/1` of a `Course` changeset names the
  form `course`, so the params arrive nested under `"course"`. On `{:ok, course}` it
  redirects to the catalog `:show`; on `{:error, %Ecto.Changeset{}}` it re-renders
  `:new` with `to_form(changeset)`, so the F6.3 changeset errors surface inline per
  field (F6.5-D5/INV5). The view adds no validation — parsing stays in
  `create_course/1`'s `changeset/2` (F6.5-INV6).
  """
  def create(conn, %{"course" => course_params}) do
    case Portal.create_course(course_params) do
      {:ok, course} ->
        redirect(conn, to: ~p"/courses/#{course.id}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, form: to_form(changeset))
    end
  end

  @doc """
  Liveness probe — `200 "ok"`, no domain call (F6.1-R6). The only route that does not
  reach the facade.
  """
  def health(conn, _params) do
    send_resp(conn, 200, "ok")
  end
end
