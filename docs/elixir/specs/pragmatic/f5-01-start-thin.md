# F5.01 · Start thin: a running Portal from day one

> Stand the Portal up behind a minimal Elixir web server now, and plan the path to Phoenix. The deliverable is a
> supervised Mix app that answers real HTTP on port 4000, with a stubbed engine boundary and the branded-id
> generator in place — and a web layer thin enough that Phoenix replaces it in F6 without touching the engine.

Module guide · part of [F5 · Pragmatic Programming](pragmatic.md) · next: [F5.02 · Domain](f5-02-domain.md)

## What you'll build

A new application `portal` that boots a `Plug.Router` under `Bandit` on port 4000, supervised, with:

- `Portal.Web.Router` — a thin router: `GET /courses/:user_id`, `POST /enroll`, and a catch-all 404.
- `Portal.Engine` — the boundary the web calls: `dispatch/1` and `query/2`, stubbed for now (consolidated in F5.08).
- `Portal.ID` — mint and decode branded Snowflake ids.
- `Portal.Application` — the supervision tree wiring the engine and the server.

Nothing here implements Portal logic yet. The point is a running shell: a real request reaches a real route, and the
seam to the engine exists.

## Concepts

- **Start thin, not big.** A working skeleton beats a perfect plan. Get one request crossing the wire on day one so
  the risky unknowns — does the web reach the engine, does a request round-trip — are answered immediately.
- **The thin server is a detail.** The router speaks HTTP and nothing about the Portal's rules. Because every route
  only calls the engine boundary, the same calls move into Phoenix in F6 with the engine unchanged.
- **The roadmap.** This is stage two (simple web server). The engine grows behind it in F5.02–F5.09; Phoenix replaces
  the server in F6; Fly is later and out of scope.

## Specs

**Dependencies** (`mix.exs`):

| Package | Version | Role |
| --- | --- | --- |
| `bandit` | `~> 1.5` | pure-Elixir HTTP server for the Plug |
| `plug` | `~> 1.16` | the composable HTTP adapter |
| `jason` | `~> 1.4` | JSON encode/decode |

**Modules and files:**

| File | Module | Responsibility |
| --- | --- | --- |
| `lib/portal/application.ex` | `Portal.Application` | supervision tree |
| `lib/portal/id.ex` | `Portal.ID` | mint/decode branded Snowflake ids |
| `lib/portal/engine.ex` | `Portal.Engine` | boundary stub: `dispatch/1`, `query/2` |
| `lib/portal_web/router.ex` | `Portal.Web.Router` | the thin HTTP router |

**Boundary contract (stub for now):**

```elixir
Portal.Engine.dispatch(command)   :: {:ok, term} | {:error, atom}   # writes
Portal.Engine.query(name, args)   :: {:ok, term} | {:error, atom}   # reads
```

**Supervision tree:** `[Portal.Engine, {Bandit, plug: Portal.Web.Router, port: 4000}]`, strategy `:one_for_one`.

**Routes:** `GET /courses/:user_id` → `query(:courses_of, user_id)`; `POST /enroll` →
`dispatch(%{type: :enroll, ...})`; unmatched → `404`.

## Build it

1. **Scaffold the supervised app.**

   ```bash
   mix new portal --sup
   cd portal
   ```

2. **Add dependencies** to `mix.exs`, then fetch:

   ```elixir
   defp deps do
     [
       {:bandit, "~> 1.5"},
       {:plug, "~> 1.16"},
       {:jason, "~> 1.4"}
     ]
   end
   ```

   ```bash
   mix deps.get
   ```

3. **Write `Portal.ID`** — snowflake generation (timestamp + node + sequence) and Base62 branding with a 3-letter
   namespace; plus decoders. See the id convention in [pragmatic.md](pragmatic.md#conventions).

4. **Write the engine stub** (`lib/portal/engine.ex`):

   ```elixir
   defmodule Portal.Engine do
     use GenServer

     def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

     @impl true
     def init(state), do: {:ok, state}

     # boundary — real logic arrives with the domain (F5.02+) and is consolidated in F5.08
     def dispatch(_command), do: {:error, :not_implemented}
     def query(_name, _args), do: {:error, :not_implemented}
   end
   ```

5. **Write the thin router** (`lib/portal_web/router.ex`):

   ```elixir
   defmodule Portal.Web.Router do
     use Plug.Router

     plug :match
     plug Plug.Parsers, parsers: [:urlencoded, :json], json_decoder: Jason
     plug :dispatch

     get "/courses/:user_id" do
       case Portal.Engine.query(:courses_of, user_id) do
         {:ok, courses}   -> send_resp(conn, 200, Jason.encode!(courses))
         {:error, reason} -> send_resp(conn, 422, to_string(reason))
       end
     end

     post "/enroll" do
       command = %{type: :enroll, user_id: conn.params["user"], course_id: conn.params["course"]}

       case Portal.Engine.dispatch(command) do
         {:ok, _event}    -> send_resp(conn, 201, "enrolled")
         {:error, reason} -> send_resp(conn, 422, to_string(reason))
       end
     end

     match _, do: send_resp(conn, 404, "not found")
   end
   ```

6. **Wire the supervision tree** (`lib/portal/application.ex`):

   ```elixir
   def start(_type, _args) do
     children = [
       Portal.Engine,
       {Bandit, plug: Portal.Web.Router, port: 4000}
     ]

     Supervisor.start_link(children, strategy: :one_for_one, name: Portal.Supervisor)
   end
   ```

7. **Run and verify:**

   ```bash
   iex -S mix          # or: mix run --no-halt
   # in another shell:
   curl -i -X POST localhost:4000/enroll -d "user=USR1&course=CRS1"   # 422 :not_implemented (boundary stubbed)
   curl -i localhost:4000/nope                                        # 404 not found
   ```

   A `422` from `/enroll` is the success signal here: the request reached the route and the boundary answered. Logic
   comes next.

## Build prompts

> Paste into an agent (e.g. Claude Code) in order. Each prompt carries its spec and acceptance criteria.

```text
PROMPT 1 — Scaffold the Portal app
Create a new supervised Elixir Mix project named `portal`. Add and fetch these deps in mix.exs:
bandit ~> 1.5, plug ~> 1.16, jason ~> 1.4. Do not add Phoenix or Ecto.
Acceptance: `mix deps.get` succeeds and `mix compile` is clean.
```

```text
PROMPT 2 — Portal.ID (branded Snowflake ids)
Create lib/portal/id.ex defining Portal.ID. A snowflake is a 64-bit, time-ordered integer:
timestamp(41 bits, ms since epoch 1704067200000) <<22 | node(10 bits) <<12 | seq(12 bits).
Generate node from a configurable value (default 1) and a monotonic per-ms sequence.
A branded id is a 3-letter uppercase namespace followed by the Base62 (0-9A-Za-z) encoding of the snowflake.
Public API:
  new(namespace :: String.t()) :: String.t()        # mint a fresh branded id
  snowflake(branded :: String.t()) :: non_neg_integer()
  namespace(branded :: String.t()) :: String.t()
  at(branded :: String.t()) :: DateTime.t()          # creation time decoded from the snowflake
Constraints: pure functions except the clock/sequence; no external deps.
Acceptance: new("ENR") returns "ENR" <> base62; snowflake(new("ENR")) round-trips; at/1 returns a UTC DateTime.
```

```text
PROMPT 3 — The thin web server
Create Portal.Engine (lib/portal/engine.ex) as a GenServer with name __MODULE__ and a boundary of two functions,
dispatch/1 and query/2, each returning {:ok, term} | {:error, atom}; stub both to {:error, :not_implemented}.
Create Portal.Web.Router (lib/portal_web/router.ex) using Plug.Router with `plug :match`,
`plug Plug.Parsers, parsers: [:urlencoded, :json], json_decoder: Jason`, `plug :dispatch`, and routes:
  GET  "/courses/:user_id" -> Portal.Engine.query(:courses_of, user_id); 200 with Jason-encoded body on {:ok, _},
       422 with the reason on {:error, _}
  POST "/enroll" -> Portal.Engine.dispatch(%{type: :enroll, user_id: params["user"], course_id: params["course"]});
       201 on {:ok, _}, 422 on {:error, _}
  match _ -> 404 "not found"
Wire Portal.Application's supervision tree to start [Portal.Engine, {Bandit, plug: Portal.Web.Router, port: 4000}]
with strategy :one_for_one.
Acceptance: the app boots, `curl -X POST localhost:4000/enroll` returns 422, and an unknown path returns 404.
```

```text
PROMPT 4 — Run and verify
Start the app with `iex -S mix`. Confirm Bandit is listening on 4000, POST /enroll returns 422 :not_implemented,
GET /nope returns 404, and the supervisor restarts Portal.Engine if it is killed. Report the observed responses.
```

## Definition of done

- [ ] `mix compile` is clean; the app boots under its supervisor.
- [ ] `Bandit` listens on port 4000.
- [ ] `POST /enroll` returns `422` (boundary stubbed) and an unknown path returns `404`.
- [ ] `Portal.ID.new("ENR")` mints a branded id and `Portal.ID.snowflake/1` round-trips it.
- [ ] The router calls only `Portal.Engine`; no Portal logic lives in the web layer.

## Next

[F5.02 · Modeling the Portal domain](f5-02-domain.md) — give the engine a shape: structs, contexts, and public APIs.

---

> Part of the jonnify toolkit. Branded build-stamp id format: `TSK` + Base62(snowflake).
