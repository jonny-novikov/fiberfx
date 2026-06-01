# F5.03 · Tracer bullets: a walking skeleton

> A running server and a domain model are still two separate things until one request travels between them. Drive a
> single use case — enroll a learner — end to end through every layer at once, each layer minimal but real. That
> thin slice is the walking skeleton. Once it runs, grow it one vertical slice at a time.

Module guide · part of [F5 · Pragmatic Programming](pragmatic.md) · prev: [F5.02 · Domain](f5-02-domain.md) ·
next: [F5.04 · Design by contract](f5-04-contracts.md)

## What you'll build

The enroll slice, wired through the whole stack, then a second slice:

- **Slice 1 — enroll a learner:** `POST /enroll` → `Portal.Learning.enroll/2` → `%Enrollment{}` →
  `Portal.Store.put/1` → `201`.
- **Slice 2 — deliver a lesson:** `GET /lessons/:id` → `Portal.Catalog.lesson/1` → the lesson → `200`.

Every layer is touched; none is finished. The result is a system that round-trips a real request and persists a real
entity.

## Concepts

- **Tracer bullets, not prototypes.** A tracer bullet is thin but real code that round-trips the system and is kept
  and built upon. A prototype is throwaway code that answers one question and is then discarded. Decide which you are
  writing: ship the bullet, delete the prototype.
- **The walking skeleton.** One use case through every layer at once — route, context API, struct, store — each
  minimal, all wired. A real `curl` produces a real, stored enrollment. The skeleton proves the design holds together
  before any layer is finished.
- **Iterate the slice.** Grow vertically, never horizontally. Each new use case is another thin slice through all the
  layers, added on top of the last, leaving the system runnable at the end of every slice. A stack of thin finished
  slices is a working product; a stack of half-built layers is nothing that runs.

### Note on the boundary

The walking skeleton wires the route directly to the context API (`Portal.Learning.enroll/2`). The unified
`Portal.Engine` facade from F5.01 stays a stub for now; it is consolidated in F5.08 to wrap these context calls
behind one `dispatch/1` / `query/2` door. Calling the context directly first is the pragmatic move — it gets the
slice running with the least ceremony, and the facade is a refactor later, not a prerequisite now.

## Specs

**Slice 1 — enroll:**

| Layer | Element | Behaviour |
| --- | --- | --- |
| web | `POST /enroll` | parse params, call the context, map the result to a status |
| context | `Portal.Learning.enroll/2` | mint an `ENR` id, build `%Enrollment{}`, store it, return `{:ok, e}` |
| struct | `%Enrollment{}` | real domain type, `progress: 0` |
| store | `Portal.Store.put/1` | persist the one entity |
| response | `201` / `422` | `201` with the id on `{:ok, _}`, `422` on `{:error, _}` |

**Slice 2 — deliver a lesson:**

| Layer | Element | Behaviour |
| --- | --- | --- |
| web | `GET /lessons/:id` | call the catalog query, map to a status |
| context | `Portal.Catalog.lesson/1` | read one lesson from the store |
| response | `200` / `404` | `200` with the lesson on `{:ok, _}`, `404` on `:error` |

## Build it

1. **Make `Learning.enroll/2` real** (from F5.02 it already builds and stores; confirm it returns a tagged tuple):

   ```elixir
   def enroll(user_id, course_id) do
     enrollment = %Enrollment{id: Portal.ID.new("ENR"), user_id: user_id, course_id: course_id}

     case Portal.Store.put(enrollment) do
       :ok -> {:ok, enrollment}
       err -> err
     end
   end
   ```

2. **Wire the route to the context** (`lib/portal_web/router.ex`):

   ```elixir
   post "/enroll" do
     case Portal.Learning.enroll(conn.params["user"], conn.params["course"]) do
       {:ok, enrollment} -> send_resp(conn, 201, enrollment.id)
       {:error, reason}  -> send_resp(conn, 422, to_string(reason))
     end
   end
   ```

3. **Verify the round trip:**

   ```bash
   iex -S mix
   # another shell:
   curl -i -X POST localhost:4000/enroll -d "user=USR1&course=CRS1"   # 201 + the new ENR id
   ```

4. **Add the second slice** — deliver a lesson. Catalog gains one function; Learning, the store, and the server are
   untouched:

   ```elixir
   # Portal.Catalog
   def lesson(lesson_id), do: Portal.Store.get(Lesson, lesson_id)
   ```

   ```elixir
   # router
   get "/lessons/:id" do
     case Portal.Catalog.lesson(id) do
       {:ok, lesson} -> send_resp(conn, 200, Jason.encode!(lesson))
       :error        -> send_resp(conn, 404, "not found")
     end
   end
   ```

## Build prompts

> Paste into an agent in order. Each prompt carries its spec and acceptance criteria.

```text
PROMPT 1 — Walking skeleton (wire enroll end to end)
In the `portal` app, wire the enroll use case through every layer.
- Confirm Portal.Learning.enroll/2 mints an ENR id (Portal.ID.new("ENR")), builds %Enrollment{} with progress 0,
  stores it via Portal.Store.put/1, and returns {:ok, enrollment} | {:error, reason}.
- In Portal.Web.Router, change POST "/enroll" to call Portal.Learning.enroll(params["user"], params["course"])
  directly (leave Portal.Engine a stub — it is consolidated in F5.08). Map {:ok, e} -> 201 with e.id;
  {:error, reason} -> 422 with the reason.
Acceptance: `curl -X POST localhost:4000/enroll -d "user=USR1&course=CRS1"` returns 201 and a branded ENR id, and
the enrollment is retrievable from the store afterward.
```

```text
PROMPT 2 — Iterate the slice (deliver a lesson)
Add a second vertical slice without touching the enroll slice.
- Add Portal.Catalog.lesson/1 :: {:ok, %Lesson{}} | :error, reading one lesson from the F4 store.
- Add GET "/lessons/:id" to the router: {:ok, lesson} -> 200 with Jason.encode!(lesson); :error -> 404.
Constraints: do not modify Portal.Learning, Portal.Store, or Portal.Application; the change touches only Catalog
and the router (one new route, one new function).
Acceptance: GET /lessons/<known id> returns 200 with the lesson JSON; an unknown id returns 404; POST /enroll still
returns 201.
```

## Definition of done

- [ ] `curl -X POST /enroll` returns `201` and a branded `ENR` id.
- [ ] The enrollment is retrievable from the store after the request.
- [ ] `GET /lessons/:id` returns `200` with the lesson for a known id, `404` otherwise.
- [ ] The second slice touched only Catalog and the router; the enroll slice is unchanged.
- [ ] The system is runnable at the end of each slice.

## Next

[F5.04 · Design by contract](f5-04-contracts.md) — harden the enroll command with preconditions and invariants.

---

> Part of the jonnify toolkit. Branded build-stamp id format: `TSK` + Base62(snowflake).
