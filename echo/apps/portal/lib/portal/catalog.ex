defmodule Portal.Catalog do
  @moduledoc """
  The Catalog bounded context — courses, lessons, and pages (F6.4).

  The idiomatic Ecto context over the F6.3 `Portal.Catalog.Course` schema: courses
  are Repo-backed (Postgres is the single source of truth, no dual write). The schema
  alias `Course`, the `Ecto.Query` import, and every `Repo.*` call are PRIVATE to this
  module — no module outside Catalog names `Repo` or `Course` (F6.4-INV1). The rest of
  the app reads courses through this small public API and never touches `Repo`.

  ## Source of truth (F6.4-INV1/INV4)

  Courses live in Postgres ONLY. `Portal.Engine.Core.authorize/2` reads a course via
  `fetch_course/1` (Repo-backed) when gating an enroll, so the enroll path runs against
  the same single source of truth — there is no Store copy of a course to drift from.
  The catalog is plain CRUD reference data; enrollment is event-sourced through the
  `Portal.EventStore` port (the `Portal.Enrollment` context), so the two slices keep
  separate persistence by design.

  ## Lessons stay Store-backed this rung (scope)

  `lesson/1` is retained Store-backed: lessons are reference data the `/lessons/:id`
  route and the engine `:lesson` query still read, and F6.4 scope is courses +
  enrollment, not a lessons migration. The courses=Repo / lessons=Store split is
  intentional — a later rung that migrates lessons would move `lesson/1` to Repo.

  ## Transaction boundary (F6.4-INV6)

  Catalog writes this rung are single-row inserts, so no `Ecto.Multi` is needed and
  INV6 is satisfied vacuously. A future multi-table catalog write (e.g. a course with
  its lessons in one atomic step) uses `Ecto.Multi` WITHIN this context — never a
  transaction spanning contexts; cross-context consistency uses a `with` chain at the
  seam instead.
  """
  import Ecto.Query, warn: false

  alias Portal.Catalog.{Course, Lesson}
  alias Portal.Repo

  @doc """
  List every course.

      iex> is_list(Portal.Catalog.list_courses())
      true
  """
  @spec list_courses() :: [Course.t()]
  def list_courses, do: Repo.all(Course)

  @doc """
  Fetch a course by branded id, raising `Ecto.NoResultsError` on a miss — the
  controller surface (a missing course is a 404 the router maps). The branded `"CRS"`
  string is cast/dumped to the `:bigint` column by `Portal.Catalog.CourseID`.
  """
  @spec get_course!(String.t()) :: Course.t()
  def get_course!(id), do: Repo.get!(Course, id)

  @doc """
  Fetch a course by branded id as a tagged tuple — the composing-context surface
  (`Portal.Engine.Core.authorize/2` and `enroll_and_welcome/2` branch on it). Returns
  `{:ok, %Course{}}` or `{:error, :not_found}`; the caller folds the bare reason into
  the closed `%Portal.Error{}` set at the seam (F6.4-INV5).
  """
  @spec fetch_course(String.t()) :: {:ok, Course.t()} | {:error, :not_found}
  def fetch_course(id) do
    case Repo.get(Course, id) do
      nil -> {:error, :not_found}
      %Course{} = course -> {:ok, course}
    end
  end

  @doc """
  Create a course from untrusted attrs. The branded `"CRS"` id is minted on the struct
  (never cast from attrs — `Course.changeset/2` excludes `:id`, F6.3-INV2); the branded
  id surfaces via `Portal.Catalog.CourseID.load/1` after insert. Returns
  `{:ok, %Course{}}` or `{:error, %Ecto.Changeset{}}` (the caller bridges the changeset
  to `%Portal.Error{}` via `Portal.Error.from_changeset/1` when a closed error is
  needed).
  """
  @spec create_course(map()) :: {:ok, Course.t()} | {:error, Ecto.Changeset.t()}
  def create_course(attrs) do
    # `:title`/`:slug` are `@enforce_keys` on the struct, so they are set nil here and
    # cast from `attrs` by the changeset (`validate_required` rejects a true miss). The
    # branded `:id` is minted on the struct, never cast (F6.3-INV2).
    %Course{id: Portal.ID.new("CRS"), title: nil, slug: nil}
    |> Course.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Fetch a lesson by branded id — retained Store-backed reference data (lessons are out
  of F6.4 scope; the `/lessons/:id` route and the engine `:lesson` query read it).
  """
  @spec lesson(String.t()) :: {:ok, Lesson.t()} | :error
  def lesson(lesson_id), do: Portal.Store.get("LSN", lesson_id)
end
