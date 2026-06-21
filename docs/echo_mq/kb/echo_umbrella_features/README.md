# echo umbrella — EchoMQ 4+ features

New source for the `fiberfx/echo` umbrella, delivered as drop-in files mirroring the umbrella
layout. Read `DESIGN.md` for the full rationale (Graft analysis, the plugin model, and the
Postgres-journal-vs-Oban argument).

## What's here

- **Graft hardening** (`apps/echo_store/lib/echo_store/graft/`): `SyncPoint`, `Segment`,
  `Epoch`, `Divergence` — the four pieces that make `echo_store`'s Graft port match upstream
  `orbitinghail/graft` where EchoMQ 4+'s commit-log-as-outbox depends on it.
- **EchoMQ durability plug** (`apps/echo_mq/lib/echo_mq/journal/`): the `Adapter` behaviour +
  `Journal` facade + `SQLite` / `Postgres` / `Graft` / `Memory` adapters, schema, migration.
- **Config** (`config/journal.exs`): adapter selection per environment.

## Install

Copy the trees into the umbrella root (paths already match):

```sh
cp -r apps/echo_store/lib/echo_store/graft/*.ex   <umbrella>/apps/echo_store/lib/echo_store/graft/
cp -r apps/echo_mq/lib/echo_mq/journal*           <umbrella>/apps/echo_mq/lib/echo_mq/
cp    apps/echo_mq/priv/repo/migrations/*.exs     <umbrella>/apps/echo_mq/priv/repo/migrations/
# import config/journal.exs from the umbrella config, or fold its keys in.
```

Then in the umbrella (where hex is reachable): `mix deps.get && mix compile`. The Postgres
adapter additionally needs `{:ecto_sql, …}` + `{:postgrex, …}` in `apps/echo_mq/mix.exs` and a
host `Repo`; the SQLite adapter reuses `echo_store`'s existing `exqlite`.

## Status

Syntax-validated here (`Code.string_to_quoted!`, 13/13). Not `mix compile`d in this sandbox —
the umbrella's hex deps (`exqlite`, `cubdb`, `ecto_sql`, `postgrex`) are proxy-blocked; compile
in the umbrella.
