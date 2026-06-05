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
  Search courses by a case-insensitive title substring (F6.6-R8 — the one ratified
  read-only addition for `CatalogLive`'s live search). Returns `[Course.t()]`, the
  same shape as `list_courses/0`; an EMPTY query returns ALL courses, so the search
  box's initial (empty) state shows the full catalog. The pattern is parameterized
  (`^`), never concatenated, so the filter is injection-safe.

      iex> Portal.Catalog.list_courses() == Portal.Catalog.search_courses("")
      true
  """
  @spec search_courses(String.t()) :: [Course.t()]
  def search_courses(query) when is_binary(query) do
    case String.trim(query) do
      "" ->
        Repo.all(Course)

      term ->
        pattern = "%#{term}%"
        Repo.all(from(c in Course, where: ilike(c.title, ^pattern)))
    end
  end

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
  Build a blank, unsaved changeset for the create form (F6.5-D4). Returns an
  ACTIONLESS `%Ecto.Changeset{}` (no `:action`), so `Phoenix.Component.to_form/1`
  renders the form with no premature errors. The base struct is built INSIDE the
  context with `struct(Course, %{})` — mirroring `Course.changeset/2`'s own default
  base (`course.ex`) — because `Course` declares `@enforce_keys [:id, :title, :slug]`,
  so a bare `%Course{}` literal would not compile. `:id`/`:title`/`:slug` start nil and
  are cast/required by the changeset, exactly as in `create_course/1`.

      iex> %Ecto.Changeset{action: action} = Portal.Catalog.change_course()
      iex> action
      nil
  """
  @spec change_course() :: Ecto.Changeset.t()
  def change_course, do: Course.changeset(struct(Course, %{}), %{})

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
    |> broadcast(&{:course_created, &1})
  end

  @doc """
  Update an existing course from untrusted attrs (F6.7-D2/US0 — the one new write below
  the facade this rung adds). The exact mirror of `create_course/1` (`catalog.ex:118`)
  with `Repo.update/1` substituted for `Repo.insert/1`: the persisted struct's branded
  `:id` is fixed (`Course.changeset/2` excludes `:id` from `cast`, F6.3-INV2), so it is
  never re-minted — the same id rides through, which is what lets a `{:course_updated, _}`
  broadcast `stream_insert` replace the row in place (F6.7-INV6). Returns
  `{:ok, %Course{}}` or `{:error, %Ecto.Changeset{}}`, the identical shape to
  `create_course/1` (`catalog.ex:117`), so the ok-only `broadcast/2` helper closes over
  both write paths uniformly (F6.7-INV1).

      iex> {:ok, c} = Portal.Catalog.create_course(%{title: "Original", slug: "orig"})
      iex> {:ok, updated} = Portal.Catalog.update_course(c, %{title: "Renamed"})
      iex> {c.id, updated.title}
      {updated.id, "Renamed"}
  """
  @spec update_course(Course.t(), map()) :: {:ok, Course.t()} | {:error, Ecto.Changeset.t()}
  def update_course(%Course{} = course, attrs) do
    course
    |> Course.changeset(attrs)
    |> Repo.update()
    |> broadcast(&{:course_updated, &1})
  end

  # The single place catalog writes broadcast from (F6.7-D2/INV1). Fires ONLY on an
  # `{:ok, course}` result — a failed write (`{:error, %Ecto.Changeset{}}`) is passed
  # through untouched and broadcasts nothing, so a subscriber only ever learns of a fact
  # that committed. The event constructor is supplied by the caller as a 1-arity fn over
  # the saved course (`&{:course_created, &1}` / `&{:course_updated, &1}`), so the helper
  # itself is event-agnostic. Broadcasts over `Portal.PubSub` through the `Portal.broadcast/2`
  # facade wrapper (F6.7-D1) on the `"courses"` topic — a domain-tier call to this app's own
  # supervised process, not a web-boundary leak (the master invariant INV2 fences the WEB,
  # not the context that owns the broadcast).
  defp broadcast({:ok, %Course{} = course} = result, event_fun) do
    Portal.broadcast("courses", event_fun.(course))
    result
  end

  defp broadcast({:error, %Ecto.Changeset{}} = result, _event_fun), do: result

  @doc """
  Fetch a lesson by branded id — retained Store-backed reference data (lessons are out
  of F6.4 scope; the `/lessons/:id` route and the engine `:lesson` query read it).
  """
  @spec lesson(String.t()) :: {:ok, Lesson.t()} | :error
  def lesson(lesson_id), do: Portal.Store.get("LSN", lesson_id)
end
