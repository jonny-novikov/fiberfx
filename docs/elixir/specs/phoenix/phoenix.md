# F6 · Phoenix Framework — Portal build guide

The web chapter. F5 built a supervised Portal engine behind a clean facade; F6 puts a real, real-time learning
platform on top of it with Phoenix and LiveView, without reaching into the engine. The endpoint joins the same
supervision tree, the router sends requests to controllers and LiveViews, and every handler calls only the `Portal`
facade.

This guide indexes the chapter. Each module has its own guide with copy-paste build prompts; build them in order.

## How to use these guides

Each module guide is self-contained: **What you'll build**, **Concepts**, **Specs** (tables you can implement
against), **Build it** (numbered steps), **Build prompts** (paste into an agent in order), and a **Definition of
done**. The platform stays runnable after every module.

## The platform, layer by layer

| Layer | What it is | Where |
| --- | --- | --- |
| Phoenix web | endpoint, router, controllers, LiveView | **F6** |
| Engine facade | `Portal` — the one public API | F5.08 (built) |
| Domain core | contexts, commands, queries, events | F5.02 – F5.06 (built) |
| Persistence | branded CHAMP store + an Ecto adapter | F4 / **F6.03** |

A request travels down and a render travels back up; live updates push up the same stack over a socket.

## Conventions

**Stack.** Elixir (OTP) · Phoenix (endpoint, router, controllers, LiveView) · `Ecto` as one adapter behind the
engine's port (F6.03) · the F4 branded CHAMP store · `Jason` for JSON. Prefer pure functions; keep side effects at
the edges.

**The one rule.** The web layer calls only the `Portal` facade and renders the closed `%Portal.Error{}` set. No
controller or LiveView names `Portal.Engine`, a repo, or `GenServer.call`. That rule is what lets F6 add a web layer
without changing anything below the facade.

**The structural change.** F6 adds exactly one child to the supervision tree the F5.09 lab assembled —
`PortalWeb.Endpoint` — under the same `:one_for_one` strategy. The engine and store entries do not move.

**Identifiers.** Every entity is identified by a **Snowflake** — a 64-bit, time-ordered integer that is the canonical
identity. Its transport form is a **branded id**: a three-letter namespace prefix plus the Base62-encoded snowflake.

```text
branded id:  ENR0KHTOWnGLuC
namespace:   ENR                       (Enrollment)
snowflake:   274557032793636864        (the canonical integer id)
created at:  2026-01-27 15:11:37 UTC   (decoded from the snowflake)
```

Snowflake layout (epoch `2024-01-01T00:00:00Z`, i.e. `1704067200000` ms): `timestamp = snowflake >>> 22`,
`node = (snowflake >>> 12) &&& 0x3FF`, `seq = snowflake &&& 0xFFF`. `Portal.ID.new/1` mints and `Portal.ID.snowflake/1`
decodes them, exactly as in F5.

## Modules

### F6.01 · Architecture & the request lifecycle → [guide](f6-01-lifecycle.md)

The path a request travels — endpoint → router → controller → view — and the one point where it meets the engine.
Stand `PortalWeb.Endpoint` up as the outermost plug and a supervised child of the F5 tree, route a request through a
browser pipeline, and call the `Portal` facade from a thin controller that renders a view. **Build target:** `mix
phx.server` boots with the endpoint supervised beside the engine, and `GET /courses/:id` returns a rendered page from
a facade query. Dives: the request lifecycle, the endpoint, and the controller/view seam.

### F6.02 · Routing, controllers & plugs → [guide](f6-02-routing.md)

The plug pipeline: routes and verbs, named pipelines and scopes, and writing a plug. The router is the only place
that names a controller; a pipeline is a reusable stack of plugs.

### F6.03 · Ecto: schemas, changesets & queries → [guide](f6-03-ecto.md)

Data, validation, and the repo — added as one more adapter behind the engine's port, so the core still names no
database.

### F6.04 · Contexts & domain design → [guide](f6-04-contexts.md)

Phoenix contexts and how they relate to the F5 facade rather than duplicate it; composing contexts behind one edge.

### F6.05 · Templates, components & HEEx → [guide](f6-05-heex.md)

Server-rendered markup: templates and assigns, function components and slots, forms and inputs.

### F6.06 · Phoenix LiveView fundamentals → [guide](f6-06-liveview.md)

Interactive UIs with no hand-written JavaScript: `mount` loads state from a query, `handle_event` issues a command,
`render` draws from assigns — all over the facade.

### F6.07 · PubSub, channels & real-time

Broadcast engine events over PubSub and push them to every subscribed LiveView; channels and presence.

### F6.08 · Auth, deployment & going live

Sessions and authentication, releases and config, and a production deployment that keeps the engine supervised.

### F6.09 · Lab: the live dashboard

The finale: a real-time dashboard that streams engine state over a socket and broadcasts to many clients via PubSub.

## Global build sequence

Run each module's build prompts in order; each lives in its module guide.

1. `f6-01` — The endpoint + plug stack · add the endpoint to the F5 tree · a browser pipeline + route · a thin
   controller over the facade · a view · verify boot and a rendered request.
2. `f6-02` — The router + routes (get/post/resources/live) + verified `~p` · the `:browser`, `:api`, and
   `:require_auth` pipelines + a protected scope · a `RequireUser` module plug + a function plug · verify.
3. `f6-03` — Migration + schema with a Snowflake id · the changeset pipeline + error bridge · composable queries ·
   the Postgres adapter behind the F5.09 port · verify.
4. `f6-04` — The Catalog context with a private schema · the Portal facade by delegation · Enrollment on the F6.03
   port · cross-context composition through public APIs · a `with` orchestration returning one closed error · verify.
5. `f6-05` — The index template over assigns · the course_card function component · compose it and add a slot wrapper ·
   a changeset-backed form · create with inline errors · verify the view layer.
6. `f6-06` — The CatalogLive LiveView · a live search box on phx-change · a live create form on phx-submit · side
   effects only on the live connection · streams for a large list · verify the LiveView.
7. `f6-07` … `f6-08` — PubSub and deployment (companion HTML modules).
8. `f6-09` — assemble the live dashboard over a socket, broadcast to many clients.

After F6 the headless engine from F5 is a deployed, real-time learning platform, and everything below the facade is
unchanged from F5.

---

> Part of the jonnify toolkit. Branded build-stamp id format: `TSK` + Base62(snowflake), e.g. `TSK0KHTOWnGLuC`.
> Markdown is the source; the presentation is generated from it.
