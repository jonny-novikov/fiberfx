defmodule PortalWeb.CatalogLive do
  @moduledoc """
  The interactive catalog (F6.6) — F6.5's static `/courses` index made live.

  Backs `live "/courses"` (the live index superseding F6.5's static `GET /courses`,
  F6.6-D6). The page is interactive without a full reload: a live search box filters
  the list as the learner types and an inline create form adds a course in place,
  flashing on success and surfacing the F6.3 changeset errors inline on failure.

  It names ONLY the `Portal` facade (F6.6-INV1, the master invariant) — `list_courses/0`,
  `search_courses/1`, `change_course/0` (arity 0), and `create_course/1`. It reaches
  nothing below the boundary: not the `Catalog` context directly, not `Portal.Engine`,
  not a `Repo`, not `GenServer.call`. Search runs through `Portal.search_courses/1`
  (the one F6.6-ratified read-only delegate), not a direct `Catalog` call (the
  `[RECONCILE]` facade-only direction).

  ## Two-stage mount (F6.6-INV2)

  `mount/3` runs twice: first DISCONNECTED over HTTP (the indexable first paint, US3),
  then CONNECTED once the LiveView socket joins. Both stages assign the same `@courses`
  stream and `@form`, so the two renders match. `connected?/1` guards the
  connection-only seam — there is no domain side effect this rung (PubSub/Presence is
  F6.7), so the guard records a `:connected?` marker the connected socket sets once;
  F6.7 fills this branch with the `Portal.PubSub` subscription. No domain state is
  mutated in either stage.

  ## State in the socket, list as a stream (F6.6-INV3/INV4)

  Interactive state lives in socket assigns and `@streams`; the client holds no
  business logic and every change is event-driven (`handle_event/3` always returns
  `{:noreply, socket}`). The course list is a `stream/3` — rows live in the DOM with
  ids on the server, never as a list in socket memory (INV4). Search re-streams with
  `reset: true` (a narrowing filter must DROP non-matching rows, not only add); a
  successful create prepends with `stream_insert(_, at: 0)`.

  ## Component reuse, no `CoreComponents` (F6.6-INV6, F6.5-INV8)

  `render/1` reuses the F6.5 `<.course_card>` for each row (no duplicated row markup)
  and the LOCAL `<.input>` from `PortalWeb.CatalogComponents` for the create fields —
  this umbrella was hand-built without `mix phx.gen.*`, so there is no `CoreComponents`.
  The create form posts BOTH required fields (`title` + `slug`); `Course.changeset/2`'s
  `validate_required([:title, :slug])` rejects a title-only form, and the rejection's
  errors render inline via the field (F6.6-INV5 — the view adds no validation of its
  own; `create_course/1`'s changeset is the parse boundary).
  """
  use PortalWeb, :live_view

  @doc """
  Mount the live catalog — two-stage (F6.6-INV2), assigning the `@courses` stream and
  the create `@form` from the facade.

  Runs disconnected (HTTP first paint) then connected; both stages stream
  `Portal.list_courses/0` and build the form from `to_form(Portal.change_course())`.
  `change_course/0` is ARITY 0 — the context builds the base `%Course{}` internally
  with `struct(Course, %{})` because `@enforce_keys [:id, :title, :slug]` makes a bare
  `%Course{}` literal fail to compile, so this view never names `Course`. The
  `connected?/1` guard marks the live socket; it mutates no domain state (the F6.7
  PubSub subscription lands in this branch). Touches only `Portal`.
  """
  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:query, "")
      |> assign_form(Portal.change_course())
      |> stream(:courses, Portal.list_courses())

    socket =
      if connected?(socket) do
        # The live socket: a once-only connection seam. No domain side effect this
        # rung — F6.7 subscribes to `Portal.PubSub` here. The marker keeps the
        # two-stage mount observable (US3) without naming anything below the boundary.
        assign(socket, :connected?, true)
      else
        assign(socket, :connected?, false)
      end

    {:ok, socket}
  end

  @doc """
  Render the catalog — search box, create form, and the streamed list (F6.6-D1/D3/D4/D5).

  Reuses the F6.5 `<.course_card>` for each row (INV6) and the local `<.input>` for the
  create fields (no `CoreComponents`, F6.5-INV8). The list container carries
  `phx-update="stream"` and iterates `@streams.courses`; each row is wrapped in a
  minimal `<div id={dom_id}>` — the stream's identity anchor `phx-update="stream"`
  requires on its direct children — with `<.course_card>` inside it (the `id` is NOT
  passed to the component, which declares only `:course`/`:class`; the wrapper carries
  no row markup, so INV6 holds and the F6.5 component is untouched). The full list is
  never an assign (INV4). Search is its own `<form phx-change="search">` (a stable
  `%{"q" => …}` payload); create is `<form phx-submit="create">` whose `<.input>` fields
  post under `course` (the changeset's form name). Draws only from assigns; names
  nothing below the boundary.
  """
  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <h1>Courses</h1>

    <form phx-change="search" data-search-form>
      <input
        type="text"
        name="q"
        value={@query}
        placeholder="Search courses…"
        phx-debounce="150"
        data-search-input
      />
    </form>

    <.form for={@form} phx-submit="create" data-create-form>
      <.input field={@form[:title]} label="Title" />
      <.input field={@form[:slug]} label="Slug" />
      <button type="submit">Create</button>
    </.form>

    <div id="courses" phx-update="stream" data-course-list>
      <div :for={{dom_id, course} <- @streams.courses} id={dom_id}>
        <.course_card course={course} />
      </div>
    </div>
    """
  end

  @doc """
  Filter the list as the learner types (F6.6-D3, US1).

  `phx-change="search"` fires this on each keystroke; it filters through
  `Portal.search_courses/1` (the facade, NOT a direct `Catalog` call — the
  `[RECONCILE]` facade-only direction) and re-streams the matches with `reset: true`
  so a narrowing query drops non-matching rows. The list updates with no reload. The
  query is kept on `@query` so the box stays controlled. Returns `{:noreply, socket}`.
  """
  @impl Phoenix.LiveView
  def handle_event("search", %{"q" => query}, socket) do
    results = Portal.search_courses(query)

    socket =
      socket
      |> assign(:query, query)
      |> stream(:courses, results, reset: true)

    {:noreply, socket}
  end

  # `handle_event("create", …)` — create a course inline (F6.6-D4, US2).
  #
  # `phx-submit="create"` calls `Portal.create_course/1`. On `{:ok, course}` it flashes,
  # prepends the new row with `stream_insert(_, at: 0)` (so it appears without a reload,
  # INV4), and resets the form to a fresh blank changeset. On
  # `{:error, %Ecto.Changeset{}}` (e.g. a title-only submit `validate_required` rejects)
  # it re-assigns `to_form(changeset)` so the F6.3 errors render inline per field (INV5).
  # The view adds no validation of its own. Returns `{:noreply, socket}`. (No `@doc`: a
  # second clause of `handle_event/3`, documented above on the `"search"` clause.)
  @impl Phoenix.LiveView
  def handle_event("create", %{"course" => params}, socket) do
    case Portal.create_course(params) do
      {:ok, course} ->
        socket =
          socket
          |> put_flash(:info, "Course created.")
          |> stream_insert(:courses, course, at: 0)
          |> assign_form(Portal.change_course())

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # Build `@form` from a changeset via the arity-1 `to_form/1` (F6.6-D4) — the create
  # form and its inline errors. Centralized so mount, the create reset, and the error
  # path share one shape.
  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
