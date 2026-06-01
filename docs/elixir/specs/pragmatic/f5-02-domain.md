# F5.02 · Modeling the Portal domain

> Give the engine a shape. Model each entity as a plain struct with enforced keys and a typespec, group the entities
> into bounded contexts that own their data, and expose each context through a small public API. Contexts reference
> one another only by branded id, so each can change on its own.

Module guide · part of [F5 · Pragmatic Programming](pragmatic.md) · prev: [F5.01 · Start thin](f5-01-start-thin.md) ·
next: [F5.03 · Tracer bullets](f5-03-tracer-bullets.md)

## What you'll build

The domain core the thin server will eventually call:

- **Entity structs** with `@enforce_keys`, `defstruct`, and `@type` — `User`, `Session`, `Course`, `Lesson`,
  `Page`, `Enrollment`, `Progress`.
- **Three bounded contexts** — `Portal.Accounts`, `Portal.Catalog`, `Portal.Learning` — each owning its entities.
- **A small public API per context** — a smart constructor or command, plus the queries a caller needs — with
  everything else private.

No web wiring in this module; that is F5.03. Here you build the types and the doorways into them.

## Concepts

- **Structs as typed data.** A struct is a named map with a fixed set of keys. `@enforce_keys` makes the required
  ones non-optional at build time; `@type` gives the compiler and Dialyzer a shape to check. Bad data fails to
  exist rather than failing later.
- **Bounded contexts.** Group entities by the part of the domain that owns them. Accounts owns users and sessions;
  Catalog owns courses, lessons, pages; Learning owns enrollments and progress. A context is the unit that changes
  together.
- **Reference by id, not by struct.** A `%Enrollment{}` holds a `user_id` and a `course_id` — branded ids — not
  embedded `%User{}` or `%Course{}` structs. Contexts stay decoupled; one can change its internals without breaking
  another.
- **A small public API.** Each context exposes a handful of functions that validate input and return tagged tuples.
  Structs and helpers stay private. The API is the only way in, and the contract every caller depends on — the thin
  server today, Phoenix in F6.

## Specs

**Entities, namespaces, and key fields:**

| Context | Struct | Namespace | Enforced / key fields |
| --- | --- | --- | --- |
| Accounts | `Portal.Accounts.User` | `USR` | `id`, `email`, `name` |
| Accounts | `Portal.Accounts.Session` | `SES` | `id`, `user_id`, `token` |
| Catalog | `Portal.Catalog.Course` | `CRS` | `id`, `title`, `slug` |
| Catalog | `Portal.Catalog.Lesson` | `LSN` | `id`, `course_id`, `title` |
| Catalog | `Portal.Catalog.Page` | `PGE` | `id`, `lesson_id`, `body` |
| Learning | `Portal.Learning.Enrollment` | `ENR` | `id`, `user_id`, `course_id`, `progress` (default `0`) |
| Learning | `Portal.Learning.Progress` | `PRG` | `id`, `enrollment_id`, `lesson_id`, `percent` |

`id` is the branded form of a Snowflake; cross-context fields (`user_id`, `course_id`, …) hold branded ids of other
entities. See [pragmatic.md](pragmatic.md#conventions).

**Context public APIs (initial surface):**

```elixir
# Portal.Accounts
Accounts.user(user_id)                  :: {:ok, %User{}} | :error

# Portal.Catalog
Catalog.course(course_id)               :: {:ok, %Course{}} | :error
Catalog.lesson(lesson_id)               :: {:ok, %Lesson{}} | :error

# Portal.Learning
Learning.enroll(user_id, course_id)     :: {:ok, %Enrollment{}} | {:error, atom}
Learning.courses_of(user_id)            :: [%Enrollment{}]
```

**Files:** one module per entity under `lib/portal/<context>/`, and one context module per context at
`lib/portal/<context>.ex`.

## Build it

1. **Create the entity structs.** Example — the Enrollment:

   ```elixir
   defmodule Portal.Learning.Enrollment do
     @enforce_keys [:id, :user_id, :course_id]
     defstruct [:id, :user_id, :course_id, progress: 0]

     @type t :: %__MODULE__{
             id: String.t(),
             user_id: String.t(),
             course_id: String.t(),
             progress: 0..100
           }
   end
   ```

   Repeat for `User`, `Session`, `Course`, `Lesson`, `Page`, `Progress` with the fields in the spec table.

2. **Create the context modules** with their public APIs. Example — Learning, delegating reads/writes to the F4
   store; `enroll/2` builds and stores a struct (the real contract is added in F5.04):

   ```elixir
   defmodule Portal.Learning do
     alias Portal.Learning.Enrollment

     @spec enroll(String.t(), String.t()) :: {:ok, Enrollment.t()} | {:error, atom}
     def enroll(user_id, course_id) do
       enrollment = %Enrollment{id: Portal.ID.new("ENR"), user_id: user_id, course_id: course_id}

       case Portal.Store.put(enrollment) do
         :ok -> {:ok, enrollment}
         err -> err
       end
     end

     @spec courses_of(String.t()) :: [Enrollment.t()]
     def courses_of(user_id), do: Portal.Store.all(Enrollment, user_id: user_id)
   end
   ```

3. **Keep helpers private.** Anything that is not part of the documented API is `defp`. Callers see only the
   functions in the spec table.

4. **Verify in `iex`:**

   ```bash
   iex -S mix
   ```

   ```elixir
   # builds a valid struct
   %Portal.Learning.Enrollment{id: "ENR1", user_id: "USR1", course_id: "CRS1"}

   # missing an enforced key raises at build time
   %Portal.Learning.Enrollment{user_id: "USR1"}   # ** (ArgumentError) the following keys must also be given...
   ```

## Build prompts

> Paste into an agent in order. Each prompt carries its spec and acceptance criteria.

```text
PROMPT 1 — Entity structs
In the `portal` app, create one module per entity, each with @enforce_keys, defstruct, and a @type t:
  Portal.Accounts.User       (USR): id, email, name
  Portal.Accounts.Session    (SES): id, user_id, token
  Portal.Catalog.Course      (CRS): id, title, slug
  Portal.Catalog.Lesson      (LSN): id, course_id, title
  Portal.Catalog.Page        (PGE): id, lesson_id, body
  Portal.Learning.Enrollment (ENR): id, user_id, course_id, progress (default 0, type 0..100)
  Portal.Learning.Progress   (PRG): id, enrollment_id, lesson_id, percent
All id and *_id fields are branded-id strings (String.t()). @enforce_keys lists the required fields (every field
except progress, which defaults to 0). Each file lives at lib/portal/<context>/<entity>.ex.
Acceptance: building a struct with all enforced keys succeeds; omitting one raises at compile/build time;
Dialyzer sees a @type t for each.
```

```text
PROMPT 2 — Bounded contexts
Create three context modules: Portal.Accounts, Portal.Catalog, Portal.Learning, at lib/portal/<context>.ex.
Each context owns its entities and is the only module that builds or persists them. Contexts must reference other
contexts' entities by branded id only — never embed another context's struct. Add aliases for the entities each
context owns. Leave the function bodies for the next prompt.
Acceptance: the modules compile; no context aliases or calls another context's struct module.
```

```text
PROMPT 3 — Public APIs
Give each context a small public API, with everything else private (defp):
  Accounts.user(user_id) :: {:ok, %User{}} | :error
  Catalog.course(course_id) :: {:ok, %Course{}} | :error
  Catalog.lesson(lesson_id) :: {:ok, %Lesson{}} | :error
  Learning.enroll(user_id, course_id) :: {:ok, %Enrollment{}} | {:error, atom}
  Learning.courses_of(user_id) :: [%Enrollment{}]
Reads delegate to the F4 store (Portal.Store.get/2, Portal.Store.all/2); Learning.enroll/2 mints an ENR id with
Portal.ID.new("ENR"), builds an %Enrollment{} (progress 0), stores it with Portal.Store.put/1, and returns
{:ok, enrollment}. Add @spec to every public function. Do not add validation yet — the contract is F5.04.
Acceptance: from iex, Learning.enroll("USR1", "CRS1") returns {:ok, %Enrollment{progress: 0}} and the enrollment
is retrievable; the public surface matches the signatures above and nothing else is exported.
```

## Definition of done

- [ ] Every entity has a struct with `@enforce_keys`, `defstruct`, and a `@type t`.
- [ ] Building a struct with all enforced keys succeeds; omitting one raises.
- [ ] Three context modules exist; none references another context's struct directly (only branded ids).
- [ ] Each context exposes exactly its documented public API; helpers are private.
- [ ] `Learning.enroll/2` returns `{:ok, %Enrollment{progress: 0}}` from `iex`.

## Next

[F5.03 · Tracer bullets: a walking skeleton](f5-03-tracer-bullets.md) — drive enroll end to end through every layer.

---

> Part of the jonnify toolkit. Branded build-stamp id format: `TSK` + Base62(snowflake).
