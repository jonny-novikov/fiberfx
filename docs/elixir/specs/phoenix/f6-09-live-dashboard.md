# F6.09 · The live dashboard (lab)

> The capstone. This lab assembles everything from F5 and F6 into one real-time screen: a dashboard that shows live
> counts, an activity feed, and a viewer count, updating for every connected client the instant anything changes.
> Nothing here is new machinery — it is a LiveView (F6.06) holding a read model seeded from the contexts (F6.04), kept
> live by broadcasts from the domain (F6.07) that the engine (F5) emits, protected and clustered by F6.08. The build
> prompts below produce the dashboard step by step: the read model, the subscription, the fold, the render, the
> Presence count, and the read-only route. Run them in order and verify against the definition of done.

Module guide · part of [F6 · Phoenix Framework](phoenix.md) · prev: [F6.08 · deployment](f6-08-deployment.md)

## What you'll build

A read-only, real-time operations dashboard:

- **a dashboard LiveView** holding a read model on its socket — metric counts seeded from the F6.04 contexts at mount,
  plus a capped stream for an activity feed;
- **a subscription** to the domain's `"events"` topic on the connected mount;
- **the fold** — `handle_info/2` clauses that apply each broadcast to the read model, bumping a count and prepending a
  feed row;
- **the render** — HEEx metric cards from assigns and a feed under `phx-update="stream"`;
- **a Presence viewer count** — `track/3` at mount and a `"presence_diff"` handler;
- **the route** — under the F6.08 auth, read-only, correct across a cluster.

## Concepts

- **The dashboard is a projection.** It holds *derived* state — counts and a feed computed from the domain — not a new
  source of truth. If the process restarts, it re-seeds from the contexts.
- **Seed from the read side.** `mount/3` reads counts from the F6.04 contexts (`Catalog.count_courses/0`,
  `Enrollment.count/0`) so the first paint is accurate with no loading state.
- **Feed as a stream.** The activity feed uses `stream/3` (F6.06.3), keeping a long append-only list in the DOM rather
  than in socket memory.
- **Reuse F6.07's broadcasts.** The domain already emits tagged events after a write
  (`{:course_created, course}`, `{:enrolled, enrollment}`). The dashboard adds no emission code — it subscribes.
- **Subscribe on the connected mount.** `if connected?(socket), do: Portal.subscribe("events")` — the disconnected
  HTTP render does no work it would throw away.
- **The fold is the core idea.** Each `handle_info/2` clause applies one event to the read model — `update/3` bumps a
  count, `stream_insert/3` prepends a feed row. State is maintained incrementally, never recomputed or re-queried.
  This is the F5 event-sourcing intuition expressed as a live LiveView.
- **Fan-out gives multi-client for free.** One broadcast reaches every subscribed dashboard, so all viewers update
  together — the publisher fires once and the runtime delivers to all.
- **Presence is one more event kind.** `track/3` at mount; a `"presence_diff"` arrives in `handle_info/2` and the
  dashboard recomputes `map_size(Presence.list(...))` into `viewers`.
- **Read-only by design.** The dashboard seeds, folds, and reports presence — it has no write path, so it is safe to
  open anywhere with access.
- **Clustering spans nodes.** Because PubSub and Presence ride the BEAM's distribution, the F6.08 cluster makes the
  dashboard correct across servers with no code change.

## Specs

**Read model (socket assigns + stream):**

| Piece | Source | Held as |
| --- | --- | --- |
| `courses_count` | `Catalog.count_courses/0` at mount, then folded | assign |
| `enrollments_count` | `Enrollment.count/0` at mount, then folded | assign |
| `viewers` | `map_size(Presence.list("dashboard"))` | assign |
| feed | `stream(:events, ...)`, `stream_insert/3` at `:0` | stream |

**Event handling:**

| Message | handle_info/2 does |
| --- | --- |
| `{:course_created, course}` | bump `courses_count`, insert a feed row |
| `{:enrolled, enrollment}` | bump `enrollments_count`, insert a feed row |
| `%{event: "presence_diff"}` | recompute `viewers` from `Presence.list/1` |

**Topics:** `"events"` (domain events, F6.07) and `"dashboard"` (Presence).

**Touched files:** `PortalWeb.DashboardLive` (mount/render/handle_info), the router (`live_session` under F6.08 auth),
and the existing `Portal` PubSub facade + `PortalWeb.Presence` from F6.07.

## Build it

1. **The read model + render** (`PortalWeb.DashboardLive`).

   ```elixir
   def mount(_params, _session, socket) do
     socket =
       socket
       |> assign(:courses_count, Catalog.count_courses())
       |> assign(:enrollments_count, Enrollment.count())
       |> assign(:viewers, 0)
       |> stream(:events, [])
     {:ok, socket}
   end
   ```

2. **Subscribe on the connected mount.**

   ```elixir
   if connected?(socket), do: Portal.subscribe("events")
   ```

3. **Fold each event** in `handle_info/2`.

   ```elixir
   def handle_info({:enrolled, enrollment}, socket) do
     {:noreply,
      socket
      |> update(:enrollments_count, fn n -> n + 1 end)
      |> stream_insert(:events, row("enrolled", enrollment.id), at: 0)}
   end
   ```

4. **Track Presence + count viewers.**

   ```elixir
   PortalWeb.Presence.track(self(), "dashboard", socket.id, %{})

   def handle_info(%{event: "presence_diff"}, socket) do
     {:noreply, assign(socket, viewers: map_size(PortalWeb.Presence.list("dashboard")))}
   end
   ```

5. **Route it** under the F6.08 auth.

   ```elixir
   live_session :authenticated, on_mount: [{PortalWeb.UserAuth, :ensure_authenticated}] do
     live "/dashboard", DashboardLive
   end
   ```

## Build prompts

> Paste into an agent in order. Each prompt carries its spec and acceptance criteria. The dashboard stays runnable
> after each one — accurate on load first, then progressively live.

```text
PROMPT 1 — The dashboard read model + render
Create PortalWeb.DashboardLive. In mount/3, seed a read model on the socket: assign courses_count from
Catalog.count_courses/0, enrollments_count from Enrollment.count/0, viewers to 0, and initialise stream(:events, []).
In render/1, draw three metric cards interpolating the count assigns and a feed list under a phx-update="stream"
container that iterates @streams.events with a :for comprehension, using the stream dom_id as each row's id.
Acceptance: the page loads showing real counts from the contexts with no loading state; the feed container is present
and empty; the read model is derived (no schema, no separate store); render uses assigns for counts and the stream for
the feed.
```

```text
PROMPT 2 — Subscribe to engine events
In mount/3, after seeding, subscribe to the "events" topic behind connected?/1:
if connected?(socket), do: Portal.subscribe("events"). Do not add any broadcasting — the domain already emits
{:course_created, course} and {:enrolled, enrollment} after writes (F6.07). Confirm the dashboard is purely a
subscriber.
Acceptance: a connected dashboard is subscribed to "events"; the disconnected first render does not subscribe; no new
broadcast code is added to the dashboard; the emission remains in the context from F6.07.
```

```text
PROMPT 3 — Fold events into the read model
Add handle_info/2 clauses, one per event kind. For {:course_created, course}: update(:courses_count, fn n -> n + 1 end)
and stream_insert(:events, row, at: 0). For {:enrolled, enrollment}: update(:enrollments_count, ...) and
stream_insert(...). Add a small row/2 helper that builds a feed entry with a stable id and a label. Add a catch-all
handle_info/2 that ignores unknown messages.
Acceptance: each event bumps exactly the right count and prepends one feed row; the count is incremented, not
recomputed; the feed is updated by stream_insert, not a re-query; unknown messages are ignored without crashing; the
browser updates with no reload.
```

```text
PROMPT 4 — Presence viewer count
At the connected mount, also call PortalWeb.Presence.track(self(), "dashboard", socket.id, %{}). Add a
handle_info(%{event: "presence_diff"}, socket) clause that recomputes viewers as
map_size(PortalWeb.Presence.list("dashboard")) and assigns it. Confirm the "Watching" card reflects the live count.
Acceptance: opening or closing a dashboard changes the viewer count on every open dashboard; the count comes from
Presence.list/1; presence_diff is handled in handle_info/2 like any other message; the count is correct across a
cluster.
```

```text
PROMPT 5 — Route under auth, read-only
Route the dashboard under the F6.08 auth: a live_session :authenticated with
on_mount: [{PortalWeb.UserAuth, :ensure_authenticated}] containing live "/dashboard", DashboardLive. Audit the module
to confirm it never writes — it only reads from contexts at mount, folds broadcasts, and reports presence.
Acceptance: an anonymous visitor is redirected before the dashboard connects; an authenticated user sees it; the module
has no create/update/delete calls; it is a projection over the event stream, not a participant.
```

```text
PROMPT 6 — Verify multi-client and clustering
Open two or more dashboards and perform a write elsewhere (create a course, enrol a student). Confirm every open
dashboard updates together from the single broadcast, the relevant count ticks up, and a feed row appears on each. With
a clustered deploy (F6.08), confirm a write on one node updates a viewer on another, since PubSub and Presence span the
cluster — with no change to the publishing code.
Acceptance: one broadcast reaches every connected dashboard; counts and feed stay in sync across clients; the viewer
count is correct cluster-wide; the same code works on one node or several; the dashboard remains read-only throughout.
```

## Definition of done

- [ ] `DashboardLive` mounts with counts seeded from the F6.04 contexts and an empty feed stream; render shows cards
      and the feed.
- [ ] The dashboard subscribes to `"events"` on the connected mount and adds no broadcasting of its own.
- [ ] `handle_info/2` folds each event incrementally — `update/3` bumps a count, `stream_insert/3` prepends a row.
- [ ] Presence is tracked at mount and `"presence_diff"` updates a live viewer count.
- [ ] The route sits under the F6.08 auth and the module never writes — a projection over the event stream.
- [ ] Many clients stay in sync from one broadcast, correct across a cluster.

## Next

Course complete. From the F5 engine and its supervision tree, through contexts, routing, Ecto, templates, LiveView,
PubSub, and deployment, to this live dashboard, you have built one coherent system on the BEAM — and have the build
prompts to reproduce every layer of it.
