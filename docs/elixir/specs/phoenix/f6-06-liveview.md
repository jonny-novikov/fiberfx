# F6.06 · Phoenix LiveView fundamentals

> The interactive module. A LiveView is a stateful server process connected to the browser over a WebSocket — an OTP
> actor like the F5 engine — that holds the socket assigns, renders the F6.05 HEEx from them, and pushes only the diff
> on every change. This guide ships the **build prompts** that produce a `CatalogLive` with a two-stage `mount/3`, a
> live search box on `phx-change`, a live create form on `phx-submit` reusing the F6.04 context and F6.03 changeset,
> `connected?/1`-guarded side effects, and streams for large collections. Run them in order and verify against the
> definition of done.

Module guide · part of [F6 · Phoenix Framework](phoenix.md) · prev: [F6.05 · HEEx](f6-05-heex.md)

## What you'll build

`CatalogLive`, the interactive face of the catalog:

- a **LiveView** (`use PortalWeb, :live_view`) with `mount/3` assigning `@courses` from the facade and `render/1`
  reusing the `course_card` component;
- a **two-stage mount** — disconnected HTTP render for first paint, then a connected mount — with `connected?/1`
  guarding side effects;
- a **live search box** — `phx-change="search"` → `handle_event("search", ...)` filtering through the context and
  re-assigning `@courses`, updating as the user types;
- a **live create form** — `phx-submit="create"` → `handle_event` calling `Portal.create_course/1`, flashing on
  success and re-assigning `to_form(changeset)` with inline errors on failure;
- **streams** — `stream/3` + `stream_insert/3` + `phx-update="stream"` for a large, append-only list that does not
  live in socket memory;
- the **routing** — a `live "/catalog", CatalogLive` route in a `:browser` scope.

## Concepts

- **A LiveView is a process holding state.** The socket is its memory; `assign/3` sets state; `@key` reads it in the
  template. Same shape as a GenServer: initial state, then messages returning new state.
- **mount runs twice.** A disconnected HTTP render (fast first paint, indexable), then a connected mount over the
  socket. `connected?(socket)` distinguishes them. Read-only loads are fine on both; gate side effects (subscriptions,
  timers) behind `connected?/1`.
- **Events are messages.** Bindings — `phx-click`, `phx-change`, `phx-submit` — send a named event with a params map to
  `handle_event/3`, which transforms assigns and returns `{:noreply, socket}`. The state change re-renders
  automatically; you never touch the DOM. `{:reply, map, socket}` exists for JS hooks that need an answer.
- **The domain is unchanged.** `handle_event` calls the same `Portal` facade and contexts (F6.04) and the same
  changeset (F6.03) as a controller would. Only the transport — a socket — is different.
- **render is a function of assigns.** HEEx compiles to static segments and dynamic holes. LiveView tracks which holes
  changed and sends only those; the static shell is sent once and cached. Re-render freely — cost is proportional to
  what changed.
- **Interpolate, don't concatenate.** Change tracking can only diff a value it sees as a distinct hole; a value hidden
  in a string can't be tracked. Splitting into function components sharpens tracking — an unchanged component is
  skipped wholesale.
- **Streams for large collections.** `stream/3` keeps rows in the DOM and only their ids on the server, so a feed or
  dashboard doesn't hold the whole list in socket memory. `stream_insert/3` appends or updates one row.

## Specs

**The LiveView (`CatalogLive`):**

| Callback | Signature | Returns |
| --- | --- | --- |
| `mount/3` | `mount(params, session, socket)` | `{:ok, socket}` (assigns set) |
| `handle_event/3` | `handle_event(name, params, socket)` | `{:noreply, socket}` |
| `render/1` | `render(assigns)` | a `~H` template |

**Events:**

| Binding | Fires on | Example event |
| --- | --- | --- |
| `phx-click` | a click | `"toggle"` |
| `phx-change` | each input change | `"search"` |
| `phx-submit` | form submission | `"create"` |

**Change tracking:**

| Part | Behaviour |
| --- | --- |
| static markup | sent once, cached on the client |
| dynamic holes | tracked per assign; only changed ones sent |
| streams | rows in the DOM, ids on the server, no list in memory |

**Touched files:** `lib/portal_web/live/catalog_live.ex`, the router (`live "/catalog", CatalogLive`), and the same
`Portal` facade / `Portal.Catalog` context / changeset from F6.03–F6.04 (unchanged).

## Build it

1. **The LiveView** — mount loads, render shows.

   ```elixir
   defmodule PortalWeb.CatalogLive do
     use PortalWeb, :live_view

     @impl true
     def mount(_params, _session, socket) do
       {:ok, assign(socket, courses: Portal.list_courses(), query: "")}
     end

     @impl true
     def render(assigns) do
       ~H"""
       <h1>Courses</h1>
       <form phx-change="search">
         <input type="text" name="q" value={@query} placeholder="Search courses" />
       </form>
       <.course_card :for={course <- @courses} course={course} />
       """
     end
   end
   ```

2. **The route** — mount it in a browser scope.

   ```elixir
   scope "/", PortalWeb do
     pipe_through :browser
     live "/catalog", CatalogLive
   end
   ```

3. **Live search** — filter on every keystroke.

   ```elixir
   def handle_event("search", %{"q" => q}, socket) do
     {:noreply, assign(socket, courses: Portal.search_courses(q), query: q)}
   end
   ```

4. **Live create** — reuse the context and changeset.

   ```elixir
   def handle_event("create", %{"course" => params}, socket) do
     case Portal.create_course(params) do
       {:ok, _course} ->
         {:noreply, socket |> put_flash(:info, "Created") |> assign(courses: Portal.list_courses())}
       {:error, %Ecto.Changeset{} = cs} ->
         {:noreply, assign(socket, form: to_form(cs))}
     end
   end
   ```

5. **Side effects behind a guard** — subscribe once.

   ```elixir
   def mount(_params, _session, socket) do
     if connected?(socket), do: Portal.subscribe("courses")   # F6.07 uses this
     {:ok, assign(socket, courses: Portal.list_courses(), query: "")}
   end
   ```

6. **Streams** — large lists out of memory.

   ```elixir
   def mount(_p, _s, socket), do: {:ok, stream(socket, :courses, Portal.list_courses())}
   def handle_event("add", %{"course" => p}, socket) do
     {:ok, c} = Portal.create_course(p)
     {:noreply, stream_insert(socket, :courses, c)}
   end
   # template: <ul id="courses" phx-update="stream">
   #             <li :for={{id, c} <- @streams.courses} id={id}>{c.title}</li>
   #           </ul>
   ```

## Build prompts

> Paste into an agent in order. Each prompt carries its spec and acceptance criteria. The app stays runnable after
> each one.

```text
PROMPT 1 — The CatalogLive LiveView
Create PortalWeb.CatalogLive with use PortalWeb, :live_view. mount/3 assigns courses: Portal.list_courses() and
query: "" and returns {:ok, socket}. render/1 returns ~H rendering an <h1>, the courses via
<.course_card :for={course <- @courses} course={course} />, and reuses the F6.05.2 component. Add a
live "/catalog", CatalogLive route in the :browser scope. The LiveView must load data only through the facade, never
the Repo.
Acceptance: visiting /catalog renders the course list; the page paints on first load (disconnected render) and then
connects over the socket; @courses comes from Portal.list_courses(); no Repo or schema reference appears in the
LiveView.
```

```text
PROMPT 2 — A live search box
Add a form with phx-change="search" wrapping a text input named "q" bound to value={@query}, and a
handle_event("search", %{"q" => q}, socket) clause that assigns courses: Portal.search_courses(q) and query: q,
returning {:noreply, socket}. Add Portal.search_courses/1 (delegating to the Catalog context) if it does not exist.
Acceptance: typing in the box filters the list live with no page reload; the input stays in sync via value={@query};
filtering logic lives in the Catalog context, and the LiveView only wires the event to it; the diff sent on each
keystroke updates the list holes, not the whole page.
```

```text
PROMPT 3 — A live create form
Add a form with phx-submit="create" backed by to_form/1 over a changeset, and a
handle_event("create", %{"course" => params}, socket) clause that calls Portal.create_course/1. On {:ok, _} put a
flash and re-assign courses: Portal.list_courses(); on {:error, %Ecto.Changeset{} = cs} re-assign form: to_form(cs) so
the F6.05 <.input> shows errors inline. Reuse the F6.04 context and F6.03 changeset unchanged.
Acceptance: submitting a valid course adds it to the live list and flashes, with no reload; submitting an invalid one
re-renders the form with inline errors and preserved input; the LiveView calls the same create_course/1 a controller
would; no domain code changes.
```

```text
PROMPT 4 — Side effects only on the live connection
Guard side effects in mount/3 with connected?/1: subscribe to a "courses" topic only when connected?(socket) is true,
leaving the read of list_courses/0 outside the guard. Confirm the subscription is not established on the disconnected
first-paint render.
Acceptance: mount runs twice but subscribes once (on the connected mount); the first HTTP paint performs no
subscription or timer; the read-only data load still happens on both passes; the LiveView is ready for F6.07 broadcasts.
```

```text
PROMPT 5 — Streams for a large list
Convert the course list to a stream: in mount use stream(socket, :courses, Portal.list_courses()); add an
handle_event("add", ...) that creates a course and calls stream_insert(socket, :courses, course); and update the
template to <ul id="courses" phx-update="stream"> iterating :for={{dom_id, course} <- @streams.courses} with id={dom_id}.
The full list must not be held in socket assigns.
Acceptance: the list renders from @streams.courses; adding a course inserts one row without re-sending the whole list;
the collection is not retained in socket memory; the DOM ids are managed by the stream and the container has
phx-update="stream".
```

```text
PROMPT 6 — Verify the LiveView
Confirm end to end: /catalog renders on first paint and connects; search filters live; create adds or shows inline
errors; subscriptions are connected-only; the large list uses a stream. Confirm render/1 interpolates assigns (no
string-built markup that defeats change tracking) and that the LiveView reaches data only through the facade. The
F6.04 contexts and F6.03 changesets are unchanged.
Acceptance: a grep shows data access only through Portal/contexts, never Repo, in the LiveView; events update assigns
and re-render with minimal diffs; connected?/1 guards effects; streams hold the big list; existing context and
changeset tests pass unchanged.
```

## Definition of done

- [ ] `CatalogLive` mounts with assigns from the facade and renders the F6.05 component; routed with `live/3`.
- [ ] `mount/3` works on both the disconnected paint and the connected socket; `connected?/1` guards side effects.
- [ ] `phx-change` search and `phx-submit` create are handled in `handle_event/3` returning `{:noreply, socket}`.
- [ ] Create reuses `Portal.create_course/1`; success updates the live list, failure shows inline F6.03 errors.
- [ ] `render/1` interpolates assigns so change tracking sends minimal diffs; no Repo/schema access in the LiveView.
- [ ] A large, append-only list uses `stream/3`/`stream_insert/3` with `phx-update="stream"`, not socket assigns.

## Next

F6.07 · PubSub & real-time — broadcast domain changes on a topic so every connected `CatalogLive` updates at once,
turning one user's create into everyone's live update.
