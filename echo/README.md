# Echo — the Portal engine (umbrella)

A Mix umbrella housing the **Portal** learning-platform engine, built rung by rung
along the F5 *"Pragmatic Programming"* value ladder
(`docs/elixir/specs/pragmatic/`). Each rung ships a more capable Portal that still runs.

## Apps

- **`apps/echo_data`** — pure id primitives: `EchoData.Snowflake` (time-ordered
  64-bit ids) + `EchoData.Base62` (compact `0-9A-Za-z` transport encoding). No processes.
- **`apps/portal`** — the framework-free engine: branded ids (`Portal.ID`), the
  `Portal.Engine` boundary, the Accounts/Catalog/Learning domain over `Portal.Store`,
  and a thin **Bandit + Plug** web layer (`Portal.Web.Router`). Depends only on
  `echo_data` + bandit/plug/jason.
- *`apps/portal_web`* — **added at F6**: a Phoenix app that replaces the Bandit/Plug
  layer without touching the core.

## Master invariant

> The domain core is framework-free and depends on nothing above it. The web layer
> calls only the `Portal.Engine` boundary (`dispatch/1`, `query/2`) and never reaches
> into the core.

In this umbrella that invariant is **compiler-enforced**: `apps/portal`'s `mix.exs`
lists no Phoenix, so the core cannot call it.

## Run it

```bash
cd /Users/jonny/dev/jonnify/echo
mix deps.get && mix compile
mix run --no-halt          # serves HTTP on :4000 (PORT env overridable)
# or: iex -S mix
mix test
```

## Roadmap (F5 → F6)

- **Now (F5.1–F5.3):** a supervised app on `:4000`; branded Snowflake ids; the
  `Portal.Engine` boundary; the Accounts/Catalog/Learning domain over `Portal.Store`;
  `enroll` + `deliver-lesson` wired end to end (a walking skeleton).
- **F6 replaces:** the web layer (`Portal.Web.Router` + Bandit) is swapped for Phoenix
  in `apps/portal_web`.
- **Preserved across F6:** the domain (contexts/entities), `Portal.ID`, `Portal.Store`,
  and the `Portal.Engine` boundary — nothing below the boundary changes.

> **Tracer-bullet discipline (F5.3):** every layer is touched and none is finished; the
> skeleton is the architecture, grown one thin vertical slice at a time.
