defmodule PortalWeb.EnrollmentLive do
  @moduledoc """
  A compile-only LiveView mount sketch over the `Portal` facade (F5.9-D5).

  The purpose is to prove the boundary is genuinely UI-ready before F6: a
  `mount/3` that loads state with a query, a `handle_event/3` that issues a command
  and branches on the closed `%Portal.Error{}` contract, and a `render/1` that draws
  from `assigns` — all touching ONLY the `Portal` facade (F5.9-INV3). It names
  nothing below the boundary: not the engine GenServer, not the store, not any
  persistence layer — every call goes through `Portal`.

  ## Compile-only — it does not run (F5.9-D5)

  This sketch is **compile-only**. There is no endpoint and no socket until F6.1, so
  it cannot mount or serve; the build target is that it COMPILES, not that it
  renders. It is deliberately **`use`-free** — no `use Phoenix.LiveView`, no `~H`/
  HEEx — and adds **zero** dependencies: `phoenix_live_view` is absent from
  `apps/portal/mix.exs` by design, because adding it would break the
  compiler-enforced no-Phoenix-until-F6 invariant (echo/CLAUDE.md §2). The lifecycle
  callbacks are therefore plain functions over a plain `assigns` map, and `assign/2`
  is the local 3-line stand-in for `Phoenix.Component.assign/2`. At F6.1 the plain
  map becomes a real `Phoenix.LiveView.Socket` and the local `assign/2` is dropped;
  the `mount/3`/`handle_event/3`/`render/1` bodies — which read only `@progress` and
  `@error` — are unchanged.

  ## The structurally-`0` progress (F5.9-D5, F5.9-US3)

  `mount/3` reads `Portal.progress_of/1`, which returns `{:ok, 0}` — structurally `0`
  by two independent mechanisms, an honest read and not a calculation: no
  progress-advancing event exists (the pure core folds a `delivered` set, never a
  `progress` field), AND the read-model projection mints every `%Enrollment{}` with
  `progress: 0` at both the command path and the boot re-projection. Moving it off
  `0` needs both a progress-advancing command and a projection change — an F6
  concern. The sketch assigns and renders that `0`; it implies no single cause and no
  calculation. (The two mechanisms live below the boundary — `Portal` is this
  sketch's only contact with them.)

  ## Exhaustive outcomes (F5.9-INV4, F5.9-US4)

  `handle_event/3` consumes the closed outcome set exhaustively: `{:ok, _}` plus one
  branch per `%Portal.Error{}` code, with NO catch-all, so a new code forces a new
  branch. The union is final at four; only `:course_not_found` and `:already_enrolled`
  have producers today, while `:lesson_locked` and `:invalid_progress` are reserved
  (no producer yet), but the sketch still branches on all four. The exact shape is
  the exhaustive consumer in `Portal`'s moduledoc.

  ## F6 handoff (F5.9-D6, F5.9-INV5)

  F6.1 adds **only** `PortalWeb.Endpoint` to the supervision tree (replacing Bandit);
  its one structural tree change. The first concrete consumer of this facade is
  `PortalWeb.CourseController.index/2`, which calls only `Portal.courses_of/1`. The
  engine, the facade, the `Portal.EventStore` port, and the `%Portal.Error{}`
  contract — everything below the boundary — are unchanged. This is checkable against
  `docs/elixir/specs/phoenix/f6.1.md` (F6.1-D1/D2/D4/INV2). A known opened-gap, out of
  F5 scope and not fixed here: `f6.1.md`'s F6.1-D2 tree lists three children and omits
  the `Portal.Store` that `courses_of/1` reads — reconciled when F6 resumes.
  """

  @doc """
  Load a user's progress through the facade and seed the `assigns`.

  Returns the LiveView `{:ok, assigns}` shape. `Portal.progress_of/1` returns a
  structural `{:ok, 0}` — its closed contract today is success-only (`portal.ex`
  `@spec progress_of/1 :: {:ok, 0}`), so this matches `{:ok, progress}` and seeds a
  nil `:error` (kept so `render/1`'s error clause stays live for the
  `handle_event/3` path, where the `%Portal.Error{}` branches are reachable). A
  defensive error clause here would be dead code (the read cannot fail), so it is
  omitted; the exhaustive four-code consumer lives on the command result in
  `handle_event/3`. Touches only `Portal`.
  """
  @spec mount(map(), map(), map()) :: {:ok, map()}
  def mount(%{"user_id" => user_id}, _session, socket) do
    {:ok, progress} = Portal.progress_of(user_id)

    {:ok,
     socket |> assign(:user_id, user_id) |> assign(:progress, progress) |> assign(:error, nil)}
  end

  @doc """
  Deliver a lesson through the facade, then re-query progress on success.

  Returns the LiveView `{:noreply, assigns}` shape. On `:ok` it re-reads
  `Portal.progress_of/1` (so the view reflects the post-command read); on a
  `{:error, %Portal.Error{}}` it assigns `:error`, branching on EACH of the four
  closed codes with no catch-all (F5.9-INV4). Touches only `Portal`.
  """
  @spec handle_event(String.t(), map(), map()) :: {:noreply, map()}
  def handle_event("deliver_lesson", %{"lesson_id" => lesson_id}, socket) do
    case Portal.deliver_lesson(socket.assigns.user_id, lesson_id) do
      :ok ->
        {:ok, progress} = Portal.progress_of(socket.assigns.user_id)
        {:noreply, socket |> assign(:progress, progress) |> assign(:error, nil)}

      {:error, %Portal.Error{code: :already_enrolled} = error} ->
        {:noreply, assign(socket, :error, error)}

      {:error, %Portal.Error{code: :course_not_found} = error} ->
        {:noreply, assign(socket, :error, error)}

      {:error, %Portal.Error{code: :lesson_locked} = error} ->
        {:noreply, assign(socket, :error, error)}

      {:error, %Portal.Error{code: :invalid_progress} = error} ->
        {:noreply, assign(socket, :error, error)}
    end
  end

  @doc """
  Draw the view from `@progress` and `@error` as a plain string (iodata).

  Not `~H`/HEEx — a `use`-free sketch carries no LiveView compiler, so `render/1`
  returns a bare string the F6.1 endpoint replaces with a real template. Reads only
  the assigns; names nothing below the boundary.
  """
  @spec render(map()) :: iodata()
  def render(%{error: %Portal.Error{message: message}}) do
    "Enrollment unavailable: #{message}"
  end

  def render(%{progress: progress}) do
    "Progress: #{progress}%"
  end

  # Local stand-in for Phoenix.Component.assign/2 — the `use`-free sketch carries no
  # LiveView, so the assigns are a plain map. Dropped at F6.1, when a real
  # Phoenix.LiveView.Socket and its assign/2 take over; the callback bodies above,
  # which read only @progress and @error, are unchanged.
  defp assign(%{assigns: assigns} = socket, key, value) do
    %{socket | assigns: Map.put(assigns, key, value)}
  end
end
