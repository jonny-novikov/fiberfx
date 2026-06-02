# F6.07 · PubSub, channels & real-time

> The real-time module. PubSub turns one LiveView into many that update together — the domain broadcasts an event on a
> topic after a write, every subscribed LiveView receives it in `handle_info/2` and re-renders, and one user's change
> becomes everyone's live update. This guide ships the **build prompts** that add a facade PubSub wrapper, broadcast
> domain events from the context, subscribe `CatalogLive` and handle the messages into a stream, and track viewers with
> Presence for a cluster-correct live count. It is the same OTP message passing the F5 engine ran on. Run the prompts
> in order and verify against the definition of done.

Module guide · part of [F6 · Phoenix Framework](phoenix.md) · prev: [F6.06 · LiveView](f6-06-liveview.md)

## What you'll build

Real-time across the catalog:

- a **facade PubSub wrapper** — `Portal.subscribe/1` and `Portal.broadcast/2` over `Portal.PubSub`, started in the
  supervision tree;
- **broadcasts from the context** — `create_course/1` and `update_course/2` emit `{:course_created, course}` /
  `{:course_updated, course}` after a successful write, via a `broadcast/2` helper that fires only on `{:ok, _}`;
- a **subscribed LiveView** — `CatalogLive` subscribes to `"courses"` on its connected mount and handles the events in
  `handle_info/2`;
- **stream updates from broadcasts** — `handle_info` calls `stream_insert/3` (prepend on create, replace on update) so
  every connected client's list updates without a reload;
- **Presence** — `track/3` on the connected mount and a `"presence_diff"` handler that recomputes a live viewer count,
  correct across the cluster;
- (optional) a **channel** — a minimal `join/3` + `handle_in/3` module, for a non-LiveView client.

## Concepts

- **PubSub is BEAM message passing over a topic.** `broadcast(server, topic, message)` delivers a term to every
  subscribed process. The same broadcast reaches a LiveView, a worker, or a process on another node.
- **The domain broadcasts, not the web.** The context emits the event after the write, because the fact belongs to the
  domain. Every caller — web form, live form, import — then emits it for free. A controller/LiveView broadcasting
  directly would couple the event to one path.
- **Broadcast on success only.** A `broadcast/2` helper pattern-matches `{:ok, _}` to fire and passes `{:error, _}`
  through unchanged, preserving the F6.03 contract.
- **One server name, one place.** Wrap `subscribe`/`broadcast` on the facade so `Portal.PubSub` appears once; topics
  stay domain strings like `"courses"`.
- **Subscribe on the connected mount.** Behind `connected?/1` (F6.06.1), so the throwaway first paint doesn't join.
- **handle_info vs handle_event.** `handle_info/2` receives *process* messages (PubSub broadcasts, timers);
  `handle_event/3` receives *browser* events. Both update assigns and re-render — different doorways.
- **Pair with streams.** A broadcast `handle_info` does `stream_insert/3`, so one event updates one row in every
  client's DOM without holding the list (F6.06.3).
- **Presence is cluster-wide.** `track/3` registers a process on a topic; nodes merge their sets with a CRDT, so
  `Presence.list/1` returns everyone. A `presence_diff` message updates the count.
- **Channels are the primitive.** LiveView is built on channels; use a raw channel only for a custom client protocol
  (mobile, game) where you control the wire.

## Specs

**Facade additions:**

| Function | Body |
| --- | --- |
| `subscribe(topic)` | `Phoenix.PubSub.subscribe(Portal.PubSub, topic)` |
| `broadcast(topic, message)` | `Phoenix.PubSub.broadcast(Portal.PubSub, topic, message)` |
| supervision | `{Phoenix.PubSub, name: Portal.PubSub}` in `Portal.Application` |

**Events on `"courses"`:**

| Event | Emitted by | Handled into |
| --- | --- | --- |
| `{:course_created, course}` | `create_course/1` | `stream_insert(socket, :courses, course, at: 0)` |
| `{:course_updated, course}` | `update_course/2` | `stream_insert(socket, :courses, course)` |
| `%{event: "presence_diff"}` | Presence | recompute `viewers` count |

**LiveView callbacks:**

| Callback | Receives |
| --- | --- |
| `mount/3` | subscribe + `Presence.track` behind `connected?/1` |
| `handle_info/2` | PubSub broadcasts and presence diffs |
| `handle_event/3` | the create form submit (F6.06.2) |

**Touched files:** the `Portal` facade, `Portal.Catalog` (broadcast helper), `Portal.Application` (PubSub +
`PortalWeb.Presence` children), `lib/portal_web/live/catalog_live.ex`, `lib/portal_web/presence.ex`, and optionally a
channel module + `UserSocket`.

## Build it

1. **Facade wrapper + supervision.**

   ```elixir
   # Portal
   def subscribe(topic), do: Phoenix.PubSub.subscribe(Portal.PubSub, topic)
   def broadcast(topic, msg), do: Phoenix.PubSub.broadcast(Portal.PubSub, topic, msg)
   # Portal.Application children: [{Phoenix.PubSub, name: Portal.PubSub}, PortalWeb.Presence, ...]
   ```

2. **Broadcast from the context.**

   ```elixir
   def create_course(attrs) do
     %Course{} |> Course.changeset(attrs) |> Repo.insert() |> broadcast(:course_created)
   end

   defp broadcast({:ok, course} = ok, event) do
     Portal.broadcast("courses", {event, course})
     ok
   end
   defp broadcast({:error, _} = err, _event), do: err
   ```

3. **Subscribe in the LiveView.**

   ```elixir
   def mount(_params, _session, socket) do
     if connected?(socket), do: Portal.subscribe("courses")
     {:ok, stream(socket, :courses, Portal.list_courses())}
   end
   ```

4. **Handle the broadcasts into the stream.**

   ```elixir
   def handle_info({:course_created, course}, socket),
     do: {:noreply, stream_insert(socket, :courses, course, at: 0)}
   def handle_info({:course_updated, course}, socket),
     do: {:noreply, stream_insert(socket, :courses, course)}
   ```

5. **Presence + viewer count.**

   ```elixir
   # mount, behind connected?/1:
   PortalWeb.Presence.track(self(), "courses", socket.id, %{})

   def handle_info(%{event: "presence_diff"}, socket),
     do: {:noreply, assign(socket, viewers: map_size(PortalWeb.Presence.list("courses")))}
   ```

6. **Verify with two browsers.** Open `/catalog` in two tabs; create in one and watch the other update live; confirm
   the viewer count rises and falls as tabs open and close.

## Build prompts

> Paste into an agent in order. Each prompt carries its spec and acceptance criteria. The app stays runnable after
> each one.

```text
PROMPT 1 — Facade PubSub wrapper and supervision
Add Portal.subscribe/1 and Portal.broadcast/2 that delegate to Phoenix.PubSub with the server name Portal.PubSub, so
the server name lives in one place. Ensure {Phoenix.PubSub, name: Portal.PubSub} is started in Portal.Application's
supervision tree. Do not reference the raw Phoenix.PubSub module or the server name anywhere outside the facade.
Acceptance: Portal.subscribe/1 and Portal.broadcast/2 exist and wrap Phoenix.PubSub; the PubSub server is supervised
and starts with the app; a grep finds Portal.PubSub only in the facade and the application module.
```

```text
PROMPT 2 — Broadcast domain events from the context
In Portal.Catalog, pipe create_course/1 and update_course/2 through a private broadcast/2 helper that, on {:ok, course},
calls Portal.broadcast("courses", {event, course}) with :course_created / :course_updated and returns the result
unchanged, and on {:error, _} returns the error without broadcasting. The web layer must not broadcast.
Acceptance: a successful create broadcasts {:course_created, course} on "courses"; a successful update broadcasts
{:course_updated, course}; a failed write broadcasts nothing and the {:ok,_}/{:error,_} contract is unchanged; no
controller or LiveView calls broadcast directly.
```

```text
PROMPT 3 — Subscribe the LiveView and handle events
In CatalogLive.mount/3, subscribe to "courses" behind connected?/1 and load the list as a stream. Add handle_info/2
clauses for {:course_created, course} (stream_insert at: 0) and {:course_updated, course} (stream_insert replacing by
id). Keep handle_event/3 for the form submit from F6.06.2 separate.
Acceptance: the LiveView subscribes only on the connected mount; a broadcast arrives in handle_info/2, not
handle_event/3; creating a course inserts a row at the top of the stream and updating replaces it in place; a second
connected client sees the same change without a reload.
```

```text
PROMPT 4 — Verify multi-client live updates
Confirm the end-to-end fan-out: opening /catalog in two browser sessions and creating a course in one updates the list
in both, driven by the context broadcast and the handle_info stream insert — not by the create handler touching the
other session. Confirm the author's own session updates through the same broadcast path.
Acceptance: two sessions both update from one write; the update flows through PubSub and handle_info; there is no
special-case code path for the author's own client; the create handler does not directly manipulate other sessions.
```

```text
PROMPT 5 — Presence and a live viewer count
Add a PortalWeb.Presence module (use Phoenix.Presence) and start it in the supervision tree. In CatalogLive.mount/3,
behind connected?/1, call PortalWeb.Presence.track(self(), "courses", socket.id, %{}). Add a
handle_info(%{event: "presence_diff"}, socket) clause that assigns viewers: map_size(PortalWeb.Presence.list("courses")),
and render the count. Initialize viewers in the non-connected mount.
Acceptance: opening and closing tabs changes the displayed viewer count live; the count reflects all connected clients,
not one node's share; Presence is supervised; the presence_diff is handled in handle_info alongside the PubSub events.
```

```text
PROMPT 6 — (Optional) A raw channel for a non-LiveView client
Add PortalWeb.CatalogChannel with use PortalWeb, :channel, a join("catalog:lobby", _payload, socket) returning {:ok,
socket}, and a handle_in("ping", _payload, socket) returning {:reply, {:ok, %{pong: true}}, socket}. Wire it into
UserSocket. Explain in a comment that LiveView is built on this primitive and that channels are for custom client
protocols.
Acceptance: a client can join "catalog:lobby" and receive a pong reply to "ping"; the channel is registered on
UserSocket; the comment notes that web UI should prefer LiveView and channels are for non-browser protocols.
```

## Definition of done

- [ ] `Portal.subscribe/1` and `Portal.broadcast/2` wrap `Portal.PubSub`; the server is supervised; no raw references
      escape the facade.
- [ ] The context broadcasts `{:course_created, _}` / `{:course_updated, _}` after successful writes only; the web
      layer never broadcasts.
- [ ] `CatalogLive` subscribes behind `connected?/1` and handles broadcasts in `handle_info/2`, not `handle_event/3`.
- [ ] Broadcasts drive `stream_insert/3` so every connected client updates without a reload.
- [ ] `Presence.track/3` registers viewers and a `presence_diff` handler keeps a cluster-correct live count.
- [ ] (Optional) a minimal channel exists for a non-LiveView client, with a note on when to use it.

## Next

F6.08 · Deployment — releases, runtime configuration, migrations, and putting the whole application into production,
including the PubSub and Presence you added across nodes.
