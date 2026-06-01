# F6.04 · Contexts & domain design

> The boundary module. Phoenix is blunt that it is not your application — the framework is the web interface, and the
> application is a set of *contexts*: dedicated modules that group related functionality behind a small public API and
> hide their schemas and the `Repo`. That is the same boundary the F5 `Portal` facade already draws, so this module
> reconciles the two vocabularies and makes the boundary load-bearing. This guide ships the **build prompts** that
> produce a real `Catalog` context with a private schema, the thin `Portal` facade that delegates to contexts, an
> `Enrollment` context that depends on the F6.03 port instead of the `Repo`, cross-context composition through public
> APIs only, and a `with` pipeline that orchestrates several contexts behind one closed error. Run them in order and
> verify against the definition of done.

Module guide · part of [F6 · Phoenix Framework](phoenix.md) · prev: [F6.03 · Ecto](f6-03-ecto.md)

## What you'll build

The Portal's domain as a graph of public APIs:

- a **`Catalog` context** exposing `list_courses/0`, `get_course!/1`, `fetch_course/1`, `create_course/1`, with the
  `Course` schema and every `Repo` call private to the module;
- the **`Portal` facade** — a thin module that `defdelegate`s to `Catalog`, `Enrollment`, and `Accounts`, so the web
  layer imports one module and the slices stay separate behind it;
- an **`Enrollment` context** that reads and appends through the `Portal.EventStore` port from F5.09 (not the `Repo`),
  so it runs unchanged against the in-memory adapter in tests and Postgres in production;
- **cross-context composition** — `Enrollment.enroll/2` calling `Catalog.fetch_course/1`, branching on the public
  struct, and folding every outcome into `%Portal.Error{}`;
- a **`with` orchestration** — `enroll_and_welcome/2` chaining public calls across `Catalog`, `Enrollment`, and
  `Accounts`, short-circuiting to one closed error;
- the **dependency discipline** — a one-way graph (`Enrollment → Catalog`), no cycles, no foreign schema or `Repo`
  access.

## Concepts

- **A context is a capability, not a table.** Group by cohesion — "the catalog," "enrollment" — not one context per
  table. Courses and lessons live in `Catalog`; a user lives in `Accounts`. Prefer fewer, broader contexts and split
  only when a real internal seam appears.
- **Public API in, internals sealed.** The public functions are the contract. The schema (`Catalog.Course`) and the
  `Repo` are private — no other module builds a query against them. That seal is what lets a context rewrite its
  storage without breaking a caller.
- **Context = facade.** Phoenix's "context" and F5's "facade" name the same boundary: one public API over a slice of
  the domain. The only genuinely extra idea is the **port** — a behaviour the context depends on so its adapter can
  swap (F6.03).
- **Where Ecto goes.** Stock Phoenix calls `Repo` from the context. This course keeps Ecto behind the
  `Portal.EventStore` port, so the context depends on the abstraction and the adapter holds Ecto.
- **Compose by API, pass ids.** One context depends on another only through its public functions, and data crosses as
  an id or a published struct — never a private schema. The dependency graph stays acyclic; a cycle means the boundary
  is wrong.
- **Orchestrate across, transact within.** A single operation spanning contexts is a `with` chain of public calls
  returning one closed error. Atomic writes *within* one context use `Ecto.Multi` and a single `Repo.transaction` —
  you do not stretch a transaction across contexts.
- **Two failure variants.** Expose both `get_course!/1` (raises → controller 404) and `fetch_course/1` (tagged tuple →
  composing context branches). Each caller picks the failure mode it can handle.

## Specs

**The `Catalog` context (public API):**

| Function | Returns | For |
| --- | --- | --- |
| `list_courses/0` | `[%Course{}]` | index pages |
| `get_course!/1` | `%Course{}` or raises | controllers (404 on miss) |
| `fetch_course/1` | `{:ok, %Course{}} \| {:error, :not_found}` | composing contexts |
| `create_course/1` | `{:ok, %Course{}} \| {:error, %Ecto.Changeset{}}` | writes |

Private to the module: `alias Portal.Catalog.Course`, `import Ecto.Query`, all `Repo.*`.

**The `Portal` facade:**

| Element | Value |
| --- | --- |
| role | thin index of the public API; owns no logic |
| mechanism | `defdelegate fun(args), to: Context` per public function |
| rule | the web layer calls `Portal`, never a context or `Repo` directly |

**Composition rules:**

| Rule | Allowed | Forbidden |
| --- | --- | --- |
| how | call the other context's public function | reach its schema or `Repo` |
| data | pass an id or a published struct | pass a private schema |
| graph | one-way edges (`Enrollment → Catalog`) | cycles between two contexts |
| consistency | `with` across contexts; `Ecto.Multi` within one | one transaction across contexts |

**Touched files:** `lib/portal.ex` (facade), `lib/portal/catalog.ex`, `lib/portal/catalog/course.ex` (private),
`lib/portal/enrollment.ex`, `lib/portal/enrollment/enrolled.ex`, `lib/portal/accounts.ex`, `lib/portal/error.ex`.

## Build it

1. **The `Catalog` context** — public API, private schema and `Repo`.

   ```elixir
   defmodule Portal.Catalog do
     @moduledoc "The catalog of courses. The only public entry to course data."
     import Ecto.Query
     alias Portal.Repo
     alias Portal.Catalog.Course        # private to this module

     def list_courses,
       do: Repo.all(from c in Course, where: c.published == true, order_by: [desc: c.inserted_at])

     def get_course!(id), do: Repo.get!(Course, id)

     def fetch_course(id) do
       case Repo.get(Course, id) do
         nil -> {:error, :not_found}
         course -> {:ok, course}
       end
     end

     def create_course(attrs) do
       %Course{id: Portal.ID.snowflake("CRS")}
       |> Course.changeset(attrs)
       |> Repo.insert()
     end
   end
   ```

2. **The `Portal` facade** — delegate, do not re-implement.

   ```elixir
   defmodule Portal do
     @moduledoc "The application facade. The web layer calls Portal and nothing deeper."
     alias Portal.{Catalog, Enrollment, Accounts}

     defdelegate list_courses(),               to: Catalog
     defdelegate get_course!(id),              to: Catalog
     defdelegate enroll(user_id, course_id),   to: Enrollment
     defdelegate courses_of(user_id),          to: Enrollment
     defdelegate get_user(id),                 to: Accounts
   end
   ```

3. **The `Enrollment` context** — depend on the port, not the `Repo`.

   ```elixir
   defmodule Portal.Enrollment do
     @moduledoc "Enrollment: who is enrolled in what."
     alias Portal.EventStore                 # the F5.09 port
     alias Portal.Enrollment.Enrolled

     def courses_of(user_id) do
       {:ok, events} = EventStore.read_stream("enrollment:#{user_id}")
       events |> Enum.map(fn e -> e.course_id end) |> Enum.uniq()
     end
   end
   ```

4. **Cross-context composition** — call `Catalog`'s public API, return the closed error.

   ```elixir
   def enroll(user_id, course_id) do
     case Portal.Catalog.fetch_course(course_id) do
       {:ok, %{published: true} = course} ->
         EventStore.append("enrollment:#{user_id}",
           [%Enrolled{user_id: user_id, course_id: course.id, at: DateTime.utc_now()}])
       {:ok, %{published: false}} -> {:error, Portal.Error.new(:course_unpublished)}
       {:error, :not_found}       -> {:error, Portal.Error.new(:course_not_found)}
     end
   end
   ```

5. **Orchestrate with `with`** — several contexts, one closed error.

   ```elixir
   def enroll_and_welcome(user_id, course_id) do
     with {:ok, course} <- Portal.Catalog.fetch_course(course_id),
          {:ok, _enr}   <- Portal.Enrollment.enroll(user_id, course.id),
          {:ok, _msg}   <- Portal.Accounts.notify(user_id, {:enrolled, course.id}) do
       {:ok, course}
     else
       {:error, %Portal.Error{} = err} -> {:error, err}
     end
   end
   ```

6. **Verify.** A controller calls only `Portal.*`; a grep finds `Repo` and each schema only inside its owning context;
   `Enrollment` aliases `Catalog` but not `Catalog.Course`; the dependency graph has no cycle; enrolling in an unknown
   or unpublished course returns `%Portal.Error{}` and writes nothing.

## Build prompts

> Paste into an agent in order. Each prompt carries its spec and acceptance criteria. The Portal stays runnable after
> each one.

```text
PROMPT 1 — The Catalog context with a private schema
Create Portal.Catalog as the public API for course data. Expose list_courses/0 (published, newest first),
get_course!/1 (raises on miss), fetch_course/1 ({:ok, course} | {:error, :not_found}), and create_course/1
({:ok, course} | {:error, changeset}). Keep alias Portal.Catalog.Course, import Ecto.Query, and every Repo call
private to the module. The Course schema must not be aliased or referenced by any module outside Portal.Catalog.
Acceptance: callers can list, fetch, and create courses without naming Course or Repo; a grep shows Catalog.Course
and Repo only inside lib/portal/catalog/; get_course!/1 raises Ecto.NoResultsError on a missing id while
fetch_course/1 returns {:error, :not_found}.
```

```text
PROMPT 2 — The Portal facade by delegation
Create the Portal module as a thin facade that defdelegates each public function to its context — list_courses and
get_course! to Catalog, enroll and courses_of to Enrollment, get_user to Accounts. Portal must contain no business
logic, no Repo calls, and no Ecto imports — only defdelegate lines and an alias.
Acceptance: the web layer can call Portal.list_courses() and Portal.enroll(uid, cid) and reach the right context;
Portal has zero function bodies of its own beyond delegation; controllers import Portal and never a context module or
Repo directly.
```

```text
PROMPT 3 — The Enrollment context on the port
Create Portal.Enrollment that reads and appends through the Portal.EventStore port from F5.09, never the Repo. Add
courses_of/1 that reads the "enrollment:#{user_id}" stream and returns unique course ids. Alias Portal.EventStore;
do not alias Repo or any Ecto module in this context.
Acceptance: Enrollment names EventStore, not Repo; the same module works against the InMemory adapter in a test and
the Postgres adapter in production with no change; courses_of/1 returns the distinct course ids a user has enrolled
in, derived from the event stream.
```

```text
PROMPT 4 — Cross-context composition, the right way
Add Enrollment.enroll/2 that must refuse an unknown or unpublished course. It must call Portal.Catalog.fetch_course/1
(the public API), branch on the returned struct's published field, append an Enrolled event on success, and return
{:error, %Portal.Error{}} (codes :course_not_found, :course_unpublished) otherwise. Enrollment may alias Portal.Catalog
but must not alias or query Portal.Catalog.Course.
Acceptance: enroll/2 calls Catalog.fetch_course/1 and never Repo or Catalog.Course; enrolling in a missing course
returns {:error, %Portal.Error{code: :course_not_found}} and writes no event; enrolling in an unpublished course
returns :course_unpublished; a valid enrollment appends exactly one event.
```

```text
PROMPT 5 — Orchestrate across contexts with `with`
Add Portal.enroll_and_welcome/2 that chains three public calls — Catalog.fetch_course/1, Enrollment.enroll/2,
Accounts.notify/2 — using with, returning {:ok, course} on success and folding any {:error, %Portal.Error{}} into a
single closed error in the else clause. Do not wrap the three contexts in one Repo.transaction; this is orchestration,
not an atomic write.
Acceptance: a failure in any step short-circuits and returns that step's %Portal.Error{} unchanged; the success path
returns the course; no Repo.transaction spans the three contexts; the function reads top to bottom as three public
calls.
```

```text
PROMPT 6 — Enforce the dependency graph
Audit the contexts for boundary violations and the dependency graph for cycles. Confirm Enrollment → Catalog is the
only cross-context edge, Accounts is independent, and no context imports another's schema or Repo. If a cycle exists,
break it by introducing an event or a third context rather than a back-reference. Optionally add a boundary check (for
example a Credo or compile-time rule) that fails when a context references a foreign schema.
Acceptance: the dependency graph is acyclic; each schema and Repo call lives only in its owning context; no controller
or LiveView names a schema or Repo; the F5 Portal facade signatures and error codes are unchanged.
```

## Definition of done

- [ ] `Catalog` exposes a small public API; `Course` and `Repo` appear only inside `lib/portal/catalog/`.
- [ ] `Portal` is a delegation-only facade — no logic, no `Repo`, no Ecto.
- [ ] `Enrollment` depends on the `Portal.EventStore` port, not the `Repo`, and runs against either adapter unchanged.
- [ ] Cross-context calls go through public APIs; data crosses as ids or published structs, never a foreign schema.
- [ ] The dependency graph is acyclic; `with` orchestrates across contexts and returns one `%Portal.Error{}`.
- [ ] Atomic intra-context writes use `Ecto.Multi`; no transaction spans contexts; the F5 facade is unchanged.

## Next

F6.05 · HEEx & components — render these contexts' data into markup with HEEx templates and function components, the
view half of the request the controller already returns.
