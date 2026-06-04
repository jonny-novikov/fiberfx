defmodule PortalWeb.EnrollmentLive do
  @moduledoc """
  A thin LiveView over the `Portal` facade (F6.2, converted from the F5.9 sketch).

  Backs `live "/enroll/:id"`. `mount/3` loads a learner's progress through the facade
  (`Portal.progress_of/1`) and seeds the assigns; `render/1` draws from `@progress`
  and `@error` only. It touches ONLY the `Portal` facade (F6.2-INV1) — it names
  nothing below the boundary: not the engine GenServer, not the store, not any
  persistence layer.

  ## Converted from the F5.9 compile-only sketch (F5.9-D5 → F6.2)

  The F5.9 sketch was `use`-free — a plain `assigns` map and a local 3-line `assign/2`
  stand-in, no `~H`. F6.1 added the endpoint + the LiveView socket and F6.2 adds the
  `use PortalWeb, :live_view` macro, so the sketch is now a real Phoenix LiveView: a
  `Phoenix.LiveView.Socket` replaces the plain map, `Phoenix.LiveView`'s `assign/3`
  replaces the local stand-in, and a `~H` template replaces the bare string. The
  route param is `:id` (route `live "/enroll/:id"`), so `mount/3`'s param key is
  `"id"`, not `"user_id"`.

  ## The structurally-`0` progress (F5.9-D5, F5.9-US3)

  `mount/3` reads `Portal.progress_of/1`, which returns `{:ok, 0}` — structurally `0`
  by two independent mechanisms, an honest read and not a calculation: no
  progress-advancing event exists (the pure core folds a `delivered` set, never a
  `progress` field), AND the read-model projection mints every `%Enrollment{}` with
  `progress: 0`. Moving it off `0` needs both a progress-advancing command and a
  projection change — an F6 concern (the full LiveView is fleshed at F6.6). The two
  mechanisms live below the boundary; `Portal` is this module's only contact with
  them.
  """
  use PortalWeb, :live_view

  @doc """
  Load a learner's progress through the facade and seed the assigns.

  `Portal.progress_of/1` returns a structural `{:ok, 0}` — its closed contract today
  is success-only (`portal.ex` `@spec progress_of/1 :: {:ok, 0}`), so this matches
  `{:ok, progress}` and seeds a nil `:error`. A defensive error clause here would be
  dead code (the read cannot fail), so it is omitted. The route param is `:id`.
  Touches only `Portal`.
  """
  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    {:ok, progress} = Portal.progress_of(id)

    {:ok, assign(socket, progress: progress, error: nil)}
  end

  @doc """
  Draw the view from `@progress` and `@error`.

  Reads only the assigns; names nothing below the boundary. The `:error` branch stays
  live for a later rung's command path (F6.6 fleshes `handle_event/3`).
  """
  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <%= if @error do %>
        <p data-error-message>Enrollment unavailable: {@error.message}</p>
      <% else %>
        <p data-progress>Progress: {@progress}%</p>
      <% end %>
    </div>
    """
  end
end
