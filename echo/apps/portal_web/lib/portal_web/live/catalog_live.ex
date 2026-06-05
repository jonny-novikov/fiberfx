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

  ## Two-stage mount (F6.6-INV2, F6.7-D3/D5)

  `mount/3` runs twice: first DISCONNECTED over HTTP (the indexable first paint, US3),
  then CONNECTED once the LiveView socket joins. Both stages assign the same `@courses`
  stream and `@form`, so the two renders match. `connected?/1` guards the
  connection-only seam: the connected socket subscribes to the `"courses"` topic through
  `Portal.subscribe/1` (the facade wrapper, F6.7-D3/INV2 — never `Phoenix.PubSub`
  directly) and tracks its presence via `PortalWeb.Presence.track/3` (F6.7-D5). No domain
  state is mutated in either stage — subscribe and track register interest, they write
  nothing below the boundary.

  ## Real-time updates (F6.7-D4/INV3/INV6)

  A successful catalog write broadcasts `{:course_created, _}` / `{:course_updated, _}`
  on `"courses"` (the `Portal.Catalog` ok-only helper, F6.7-D2). `handle_info/2` applies
  `stream_insert/3` (prepend on create at `at: 0`, replace on update) so every connected
  client patches its OWN DOM with no reload (INV3) — no client holds the full list. The
  insert is GATED to the active `@query`: a broadcast inserts a row only when it matches
  the live filter, so a real-time create never breaks a learner's narrowed view (the
  RECONCILE live-search × broadcast decision). The gate mirrors `Portal.search_courses/1`'s
  title-only `ilike` (`catalog.ex` `ilike(c.title, ^pattern)`) as the in-memory
  case-insensitive substring test, so a live insert and a fresh search agree on what
  matches. The inserted row renders through the SAME `course_card/1` the mount uses, and
  `stream_insert` keys on the course id, so a re-delivered broadcast replaces in place
  rather than duplicating (INV6).

  ## Presence (F6.7-D5/INV4)

  `PortalWeb.Presence.track/3` records each connected socket under its socket id on the
  `"courses"` topic; a `"presence_diff"` message recomputes a `viewers` count from
  `Presence.list/1`. The count is CRDT-backed, correct across the cluster (INV4), not a
  single-node tally. The disconnected first paint has no socket to track, so `viewers`
  starts at 0 and the connected mount recomputes it.

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
  Mount the live catalog — two-stage (F6.6-INV2, F6.7-D3/D5), assigning the `@courses`
  stream, the create `@form`, and the `@viewers` count from the facade.

  Runs disconnected (HTTP first paint) then connected; both stages stream
  `Portal.list_courses/0` and build the form from `to_form(Portal.change_course())`.
  `change_course/0` is ARITY 0 — the context builds the base `%Course{}` internally
  with `struct(Course, %{})` because `@enforce_keys [:id, :title, :slug]` makes a bare
  `%Course{}` literal fail to compile, so this view never names `Course`. The
  `connected?/1` branch subscribes the live socket to `"courses"` through
  `Portal.subscribe/1` (the facade — never `Phoenix.PubSub` directly, F6.7-INV2) and
  tracks its presence (F6.7-D5); it mutates no domain state. `@viewers` starts at 0 for
  the disconnected paint and is recomputed once tracked. Touches only `Portal` and the
  web-tier `PortalWeb.Presence`.
  """
  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:query, "")
      |> assign(:viewers, 0)
      |> assign_form(Portal.change_course())
      |> stream(:courses, Portal.list_courses())

    socket =
      if connected?(socket) do
        # The live socket: a once-only connection seam (F6.7-D3/D5). Subscribe to the
        # "courses" topic THROUGH the facade (`Portal.subscribe/1` over `Portal.PubSub`)
        # — never `Phoenix.PubSub` directly (INV2) — so a broadcast from any client's
        # write reaches this view's `handle_info/2`. Track this socket's presence under
        # its socket id on the same topic, then seed `@viewers` from the current roster;
        # subsequent "presence_diff" messages recompute it (INV4, cluster-correct).
        Portal.subscribe("courses")
        PortalWeb.Presence.track(self(), "courses", socket.id, %{})

        socket
        |> assign(:connected?, true)
        |> assign(:viewers, count_viewers())
      else
        assign(socket, :connected?, false)
      end

    {:ok, socket}
  end

  @doc """
  Render the catalog — a live viewer count, the search box, the create form, and the
  streamed list (F6.6-D1/D3/D4/D5, F6.7-D5).

  Shows `@viewers` (the F6.7 Presence count, recomputed on each `"presence_diff"`).
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

    <p data-viewers>{@viewers} viewing</p>

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

  @doc """
  Apply a `"courses"` broadcast to this client's stream (F6.7-D4, US3).

  A successful catalog write (`create_course/1` / `update_course/2`) broadcasts
  `{:course_created, course}` / `{:course_updated, course}` on `"courses"`; this view is
  subscribed (the connected mount), so every connected client receives the fact and
  patches its OWN DOM (INV3) — no reload, no full list in memory. The insert is GATED to
  the active `@query`: a create prepends with `stream_insert(_, at: 0)` and an update
  replaces, but ONLY when the course matches the live filter (`matches?/2`), so a
  real-time write never adds a row the learner has filtered out. `stream_insert` keys on
  the course id, so a re-delivered broadcast (or a creator's own self-delivery alongside
  the inline create insert) replaces in place rather than duplicating (INV6). The row
  renders through the SAME `course_card/1` the mount uses.
  """
  @impl Phoenix.LiveView
  def handle_info({:course_created, course}, socket) do
    socket =
      if matches?(course, socket.assigns.query),
        do: stream_insert(socket, :courses, course, at: 0),
        else: socket

    {:noreply, socket}
  end

  # `handle_info({:course_updated, …})` — the update broadcast (F6.7-D4). Replaces the
  # row in place (`stream_insert/3` without `at:`, keyed on the id → INV6), gated to the
  # active `@query` exactly as the create clause. (No `@doc`: a second clause of
  # `handle_info/2`, documented above on the `:course_created` clause.)
  @impl Phoenix.LiveView
  def handle_info({:course_updated, course}, socket) do
    socket =
      if matches?(course, socket.assigns.query),
        do: stream_insert(socket, :courses, course),
        else: socket

    {:noreply, socket}
  end

  # `handle_info(%{event: "presence_diff"}, …)` — recompute the viewer count (F6.7-D5).
  # `PortalWeb.Presence` broadcasts a "presence_diff" on every track/untrack; the count
  # is recomputed from the full current roster (`count_viewers/0`), so it is correct
  # across the cluster (CRDT-backed, INV4), not an increment/decrement that could drift.
  # (No `@doc`: a third clause of `handle_info/2`.)
  @impl Phoenix.LiveView
  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :viewers, count_viewers())}
  end

  # The in-memory gate mirroring `Portal.search_courses/1`'s title-only `ilike` filter
  # (`catalog.ex`, `ilike(c.title, ^"%term%")`) — F6.7-D4's RECONCILE live-search ×
  # broadcast decision. An EMPTY query matches all (the search box's initial state shows
  # the full catalog); a non-empty query matches a case-insensitive title substring, the
  # in-Elixir equivalent of the SQL `ilike "%term%"`, so a live insert and a fresh search
  # agree on what matches. The canonical filter stays `Portal.search_courses/1`; this is
  # only the consistency predicate the broadcast path needs (the title-substring test
  # alone, since `search_courses/1` filters the title field only).
  defp matches?(_course, ""), do: true

  defp matches?(course, query) do
    String.contains?(String.downcase(course.title), String.downcase(query))
  end

  # The current viewer count from Presence (F6.7-D5/INV4): the number of distinct tracked
  # keys on the "courses" topic. CRDT-backed via `Portal.PubSub`, so it merges correctly
  # across nodes — not a single-node counter.
  defp count_viewers, do: "courses" |> PortalWeb.Presence.list() |> map_size()

  # Build `@form` from a changeset via the arity-1 `to_form/1` (F6.6-D4) — the create
  # form and its inline errors. Centralized so mount, the create reset, and the error
  # path share one shape.
  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
