# F6.03 · Ecto: schemas, changesets & queries

> The data module. Ecto does its work in three pieces — a schema maps a table to a struct, a changeset validates
> before a write, and the repo runs queries and persists. The discipline that keeps F5 intact is where Ecto lives:
> behind the engine's port, the `Portal.EventStore` behaviour from the F5.09 lab, now backed by a Postgres adapter, so
> the domain core still names no database. This guide ships the copy-paste **build prompts** that produce the
> migration and schema with a Snowflake primary key, the changeset pipeline, composable queries, and the Postgres
> adapter that implements the port. Run them in order and verify against the definition of done.

Module guide · part of [F6 · Phoenix Framework](phoenix.md) · prev: [F6.02 · routing](f6-02-routing.md)

## What you'll build

The Portal's persistence as an adapter, not a dependency:

- a **migration** creating `:courses` with `primary_key: false` and an explicit `:bigint` `:id`, because the Portal
  mints its own Snowflakes;
- a **schema** `Portal.Catalog.Course` with `@primary_key {:id, :id, autogenerate: false}`, mapping the table to a
  `%Course{}`;
- a **changeset** that `cast`s an allow-list, validates the rules, and declares a `unique_constraint`, returning a
  `%Ecto.Changeset{}` with `valid?` and `errors`;
- an **error bridge** — `Portal.Error.from_changeset/1` turning a failed changeset into the closed `%Portal.Error{}`
  from F5.08;
- **composable queries** — a `published/1` query value run with `Repo.all`, plus `Repo.get` by Snowflake id;
- the **Postgres adapter** `Portal.EventStore.Postgres` implementing the F5.09 behaviour (`append/2`,
  `read_stream/1`), the one module that names `Repo`.

## Concepts

- **Schema and migration are separate on purpose.** The migration owns the database and runs per environment; the
  schema owns the struct and is compiled into the app. They can differ, which is what lets the database evolve safely.
- **The id is a Snowflake, not a serial.** `primary_key: false` plus an explicit `:bigint` id, and
  `autogenerate: false` on the schema, keep the F4/F5 identity convention: `Portal.ID` mints the id, the database
  stores it, and it decodes to a creation time.
- **A changeset is a pure pipeline.** `cast` is the security boundary (a field outside the allow-list is dropped),
  `validate_*` checks values in Elixir, and a constraint defers to the database. The result carries `valid?` and
  `errors` with no side effects, so it is testable without a repo.
- **A query is data; the repo runs it.** `from ...` builds a value you compose; `Repo.all/get/insert` is the only
  thing that touches the database. Build a query in one place, execute it in another.
- **Ecto sits behind the port.** Only the Postgres adapter imports Ecto and calls `Repo`. The core reads and appends
  through the `Portal.EventStore` behaviour, so swapping in-memory for Postgres is a config change and the Portal logic
  never imports Ecto.

## Specs

**The schema (`Portal.Catalog.Course`):**

| Element | Value |
| --- | --- |
| primary key | `@primary_key {:id, :id, autogenerate: false}` — a minted Snowflake |
| fields | `:title` (string), `:published` (boolean, default false) |
| timestamps | `timestamps(type: :utc_datetime)` |

**The changeset pipeline:**

| Stage | Call | Does |
| --- | --- | --- |
| cast | `cast(attrs, [:title, :published])` | permit and coerce only these fields |
| validate | `validate_required([:title])`, `validate_length(:title, min: 3)` | check rules in Elixir |
| constraint | `unique_constraint(:title)` | defer to the database on insert |

**Repo operations:**

| Call | Returns |
| --- | --- |
| `Repo.get(Course, id)` | one struct or `nil` |
| `Repo.all(query)` | a list of structs |
| `Repo.insert(changeset)` | `{:ok, struct} \| {:error, changeset}` |

**The port adapter (`Portal.EventStore.Postgres`, implements F5.09 `Portal.EventStore`):**

| Callback | Uses |
| --- | --- |
| `append/2` | `Repo.insert_all(Event, rows)` |
| `read_stream/1` | `Repo.all(from e in Event, where: e.stream == ^stream, order_by: e.seq)` |

**Config:** `config :portal, :event_store, Portal.EventStore.Postgres` (prod) /
`Portal.EventStore.InMemory` (test). **Touched files:** `priv/repo/migrations/*_create_courses.exs`,
`lib/portal/catalog/course.ex`, `lib/portal/error.ex` (add `from_changeset/1`),
`lib/portal/event_store/postgres.ex`, `lib/portal/repo.ex`.

## Build it

1. **Migration.** Snowflake `:bigint` id, no serial.

   ```elixir
   defmodule Portal.Repo.Migrations.CreateCourses do
     use Ecto.Migration

     def change do
       create table(:courses, primary_key: false) do
         add :id,        :bigint,  primary_key: true
         add :title,     :string,  null: false
         add :published, :boolean, null: false, default: false
         timestamps(type: :utc_datetime)
       end
     end
   end
   ```

2. **Schema.** Mirror the table; supply the id rather than autogenerate it.

   ```elixir
   defmodule Portal.Catalog.Course do
     use Ecto.Schema

     @primary_key {:id, :id, autogenerate: false}
     schema "courses" do
       field :title, :string
       field :published, :boolean, default: false
       timestamps(type: :utc_datetime)
     end
   end
   ```

3. **Changeset.** Cast an allow-list, validate, constrain.

   ```elixir
   import Ecto.Changeset

   def changeset(course, attrs) do
     course
     |> cast(attrs, [:title, :published])
     |> validate_required([:title])
     |> validate_length(:title, min: 3, max: 120)
     |> unique_constraint(:title)
   end
   ```

4. **Error bridge + queries + repo.** Wrap a failed changeset; build and run a query.

   ```elixir
   import Ecto.Query

   def published(query \\ Course), do: from c in query, where: c.published == true

   case Repo.insert(changeset(%Course{id: Portal.ID.snowflake("CRS"), title: t}, attrs)) do
     {:ok, course}       -> {:ok, course}
     {:error, changeset} -> {:error, Portal.Error.from_changeset(changeset)}
   end
   ```

5. **The Postgres adapter.** Implement the F5.09 behaviour; this is the only module that names `Repo`.

   ```elixir
   defmodule Portal.EventStore.Postgres do
     @behaviour Portal.EventStore
     import Ecto.Query

     @impl true
     def append(stream, events), do: Repo.insert_all(Event, rows_for(stream, events))

     @impl true
     def read_stream(stream) do
       {:ok, Repo.all(from e in Event, where: e.stream == ^stream, order_by: e.seq)}
     end
   end
   ```

6. **Verify.** `mix ecto.migrate` creates the table; a row inserted through the facade has a Snowflake id;
   `Repo.get(Course, id)` round-trips it; an invalid changeset returns `{:error, %Portal.Error{}}`; the core and the
   controllers import no Ecto.

## Real-world example

A real catalog has courses *and* lessons, so the schema grows an association and the queries grow filters. The
association is declared on both sides; the lesson's foreign key is a Snowflake bigint like every other id; and a
listing function composes optional filters without running until the `Repo` does:

```elixir
defmodule Portal.Catalog.Course do
  use Ecto.Schema
  @primary_key {:id, :id, autogenerate: false}
  schema "courses" do
    field :title, :string
    field :published, :boolean, default: false
    has_many :lessons, Portal.Catalog.Lesson      # association, not a join in the caller
    timestamps(type: :utc_datetime)
  end
end

# a composable, filterable listing — data until Repo.all runs it
import Ecto.Query
def list_courses(opts \\ []) do
  Course
  |> where(published: true)
  |> maybe_search(opts[:q])
  |> order_by(desc: :inserted_at)
  |> preload(:lessons)                            # one extra query, no N+1
  |> Repo.all()
end

defp maybe_search(query, nil), do: query
defp maybe_search(query, q),   do: where(query, [c], ilike(c.title, ^"%#{q}%"))
```

The lesson changeset uses `foreign_key_constraint(:course_id)` so a bad reference becomes a changeset error rather
than a database exception, and `preload/2` keeps a course-with-lessons read to two queries instead of one-per-row.
That is the everyday shape: a schema with associations, a query that composes filters, and constraints that turn
database failures into the closed contract.

## Build prompts

> Paste into an agent in order. Each prompt carries its spec and acceptance criteria. The Portal stays runnable after
> each one.

```text
PROMPT 1 — Migration and schema with a Snowflake id
Add Ecto and a Portal.Repo. Create a migration for :courses with create table(:courses, primary_key: false) and
add :id, :bigint, primary_key: true; add :title, :string, null: false; add :published, :boolean, null: false,
default: false; timestamps(type: :utc_datetime). Define Portal.Catalog.Course with use Ecto.Schema,
@primary_key {:id, :id, autogenerate: false}, fields :title and :published, and timestamps(type: :utc_datetime).
Acceptance: mix ecto.migrate creates the table; the id column is a bigint primary key with no sequence; the schema's
primary key is :id with autogenerate: false; %Course{} structs carry the declared fields.
```

```text
PROMPT 2 — The changeset
Add Portal.Catalog.Course.changeset(course, attrs) using Ecto.Changeset: cast(attrs, [:title, :published]),
validate_required([:title]), validate_length(:title, min: 3, max: 120), and unique_constraint(:title). The function
must be pure (no Repo calls).
Acceptance: a valid map yields a changeset with valid?: true; missing or short titles yield valid?: false with
errors on :title; a field outside the cast allow-list (for example "published" smuggled by a client) is dropped; the
changeset can be built and asserted on without a database.
```

```text
PROMPT 3 — The error bridge
Add Portal.Error.from_changeset/1 that turns a %Ecto.Changeset{} with errors into the closed %Portal.Error{} from
F5.08 — map a uniqueness error to a code like :title_taken, a required/length error to :invalid_title — preserving a
human message and setting field where appropriate. No catch-all that hides an unmodelled error.
Acceptance: a failed changeset becomes a %Portal.Error{} with a known code and message; the controller branches on
%Portal.Error{}, never on Ecto.Changeset; an unmodelled changeset error is surfaced, not swallowed.
```

```text
PROMPT 4 — Composable queries and repo calls
Add a published/1 query: def published(query \\ Course), do: from c in query, where: c.published == true. Show
Repo.all(published()), Repo.all(from c in published(), order_by: [desc: c.inserted_at]), and Repo.get(Course, id) by
a Snowflake id. Keep query-building functions free of Repo calls so they stay composable and testable.
Acceptance: published/1 returns a query value, not results; Repo.all runs it; composing published/1 with order_by
works; Repo.get fetches one row by its Snowflake id.
```

```text
PROMPT 5 — The Postgres adapter behind the port
Implement Portal.EventStore.Postgres with @behaviour Portal.EventStore (from F5.09): append(stream, events) using
Repo.insert_all, and read_stream(stream) returning {:ok, Repo.all(from e in Event, where: e.stream == ^stream,
order_by: e.seq)}. Set config :portal, :event_store to this adapter in prod and InMemory in test. This module must be
the only place that imports Ecto.Query or calls Repo.
Acceptance: a grep shows Repo and Ecto.Query only in the Postgres adapter (and Repo definition), never in the domain
core or controllers; the engine's init/1 replay and command append run against Postgres unchanged; swapping the
config to InMemory needs no change in any caller.
```

```text
PROMPT 6 — Verify the data layer
Confirm end to end: mix ecto.migrate creates :courses; enrolling or creating through the Portal facade persists a row
with a Snowflake id; Repo.get(Course, id) round-trips it; an invalid changeset returns {:error, %Portal.Error{}} and
writes nothing; and the domain core and controllers import no Ecto. The F5 facade signatures and error codes are
unchanged.
Acceptance: a real insert and read round-trip through the facade; the invalid path writes nothing and returns the
closed contract; Ecto appears only behind the port; the existing F5 tests pass without modification.
```

```text
PROMPT 7 — Atomic multi-step writes with Ecto.Multi and an upsert
Add Catalog.create_course_with_intro/1 that inserts a course and its first lesson atomically using Ecto.Multi:
Multi.new() |> Multi.insert(:course, course_changeset) |> Multi.insert(:lesson, fn %{course: c} -> lesson_changeset(c) end)
|> Repo.transaction(), returning {:ok, %{course: c, lesson: l}} | {:error, step, changeset, _}. Separately, add an
upsert path on create_course/1 using on_conflict: {:replace, [:title]} and conflict_target: :id so re-running with the
same Snowflake id updates instead of failing. Both must mint Snowflake ids via Portal.ID.
Acceptance: if the lesson insert fails, the course insert is rolled back and nothing is written; a successful call
returns both structs; the upsert path is idempotent for a given id; the multi runs inside one transaction and lives
behind the context, never in a controller.
```

## Definition of done

- [ ] The `:courses` migration uses an explicit `:bigint` Snowflake id, not a serial; the schema's key is `autogenerate: false`.
- [ ] `changeset/2` is pure: `cast` allow-list, `validate_*`, and a `unique_constraint`; a non-permitted field is dropped.
- [ ] `Portal.Error.from_changeset/1` maps a failed changeset to the closed `%Portal.Error{}` with no catch-all.
- [ ] Query functions return composable query values; only `Repo.*` executes.
- [ ] `Portal.EventStore.Postgres` implements the F5.09 behaviour and is the only module that names `Repo`/`Ecto.Query`.
- [ ] `mix ecto.migrate` works; a facade write round-trips with a Snowflake id; the core and controllers import no Ecto.

## Next

F6.04 · Contexts & domain design — draw the boundary between Phoenix contexts and the F5 facade, so the two relate
rather than duplicate.
