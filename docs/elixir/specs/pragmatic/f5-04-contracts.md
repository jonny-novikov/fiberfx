# F5.04 · Design by contract

> The walking skeleton runs, but its commands trust whatever they are handed. Make that trust explicit. Give the
> enroll command a contract — a precondition the caller must meet, a postcondition the command guarantees, and an
> invariant always true of the state — written in Elixir idioms, and failing fast at the boundary before anything
> can be corrupted.

Module guide · part of [F5 · Pragmatic Programming](pragmatic.md) · prev: [F5.03 · Tracer bullets](f5-03-tracer-bullets.md)

## What you'll build

A hardened `Portal.Learning.enroll/2` whose contract is enforced in code:

- a **precondition** — the ids are well-formed and the learner is not already enrolled;
- a **postcondition** — on success, a fresh `%Enrollment{}` with `progress: 0`, stored;
- an **invariant** — `progress` always within `0..100`;

plus the router mapping expected failures to `422` and the slice failing fast — checking before it builds or stores.

## Concepts

- **The contract triad.** A precondition is the caller's obligation (valid input). A postcondition is the function's
  guarantee on return, given the precondition held. An invariant is what every operation must leave true of the
  state. Naming them assigns blame precisely: the term that breaks tells you whether you have a bad request or a bug.
- **Assertions in Elixir.** There are no contract keywords, so contracts use ordinary idioms. Guards and pattern
  matching express shape preconditions in the function head. A `with` chain composes runtime checks and
  short-circuits on the first failure. Tagged tuples carry expected failures back to the caller. `raise` — or a
  failed match — crashes on a broken invariant, which is a bug, not a bad request.
- **Failing fast.** Check at the boundary, before the command does anything: a violated precondition stops it before
  a struct is built or the store is touched, so the error lands close to its cause and nothing downstream is
  corrupted. The opposite — failing late and silently — surfaces far from the cause, after the damage. The rule:
  check, then act.

## Specs

**The enroll contract:**

| Term | Owner | For enroll |
| --- | --- | --- |
| precondition | the caller | `user_id` matches `USR…`, `course_id` matches `CRS…`, not already enrolled |
| postcondition | the function | `{:ok, %Enrollment{progress: 0}}`, stored |
| invariant | every operation | `0 <= progress <= 100` |

**Failure handling — split by kind:**

| Kind | Example | Mechanism | HTTP |
| --- | --- | --- | --- |
| expected | bad reference, already enrolled | tagged tuple `{:error, reason}` | `422` |
| impossible | `progress` out of `0..100` | `raise` / failed match (crash) | n/a (bug) |

**Touched files:** `lib/portal/learning.ex` (the contract), `lib/portal_web/router.ex` (status mapping).

## Build it

1. **Add the contract to `enroll/2`** — a binary-pattern guard for shape, a `with` chain for the runtime
   precondition, tagged tuples for expected failures, and an invariant assertion in a private `build/2`:

   ```elixir
   defmodule Portal.Learning do
     alias Portal.Learning.Enrollment

     # shape precondition via pattern: a malformed id never matches this head
     def enroll(<<"USR", _::binary>> = user_id, <<"CRS", _::binary>> = course_id) do
       with :ok <- ensure_not_enrolled(user_id, course_id) do   # expected failure -> {:error, _}
         enrollment = build(user_id, course_id)
         :ok = Portal.Store.put(enrollment)
         {:ok, enrollment}                                       # postcondition: progress is 0
       end
     end

     # precondition unmet (wrong shape) — the caller's fault
     def enroll(_, _), do: {:error, :bad_reference}

     defp ensure_not_enrolled(user_id, course_id) do
       case Portal.Store.get_by(Enrollment, user_id: user_id, course_id: course_id) do
         {:ok, _} -> {:error, :already_enrolled}
         :error   -> :ok
       end
     end

     defp build(user_id, course_id) do
       e = %Enrollment{id: Portal.ID.new("ENR"), user_id: user_id, course_id: course_id}
       true = e.progress in 0..100    # invariant assertion — raises MatchError if ever false
       e
     end
   end
   ```

2. **Map expected failures to a status** in the router (fail fast: the contract runs before anything persists):

   ```elixir
   post "/enroll" do
     case Portal.Learning.enroll(conn.params["user"], conn.params["course"]) do
       {:ok, enrollment}          -> send_resp(conn, 201, enrollment.id)
       {:error, :already_enrolled} -> send_resp(conn, 422, "already enrolled")
       {:error, :bad_reference}    -> send_resp(conn, 422, "bad reference")
     end
   end
   ```

3. **Verify each path:**

   ```bash
   iex -S mix
   ```

   ```bash
   curl -i -X POST localhost:4000/enroll -d "user=USR1&course=CRS1"   # 201 + ENR id
   curl -i -X POST localhost:4000/enroll -d "user=USR1&course=CRS1"   # 422 already enrolled
   curl -i -X POST localhost:4000/enroll -d "user=nope&course=CRS1"   # 422 bad reference
   ```

## Build prompts

> Paste into an agent in order. Each prompt carries its spec and acceptance criteria.

```text
PROMPT 1 — Add the enroll contract
In the `portal` app, harden Portal.Learning.enroll/2 with a design-by-contract implementation.
- Precondition (shape) via a function head with binary patterns: enroll(<<"USR", _::binary>> = user_id,
  <<"CRS", _::binary>> = course_id). A fallback clause enroll(_, _) returns {:error, :bad_reference}.
- Precondition (runtime): a private ensure_not_enrolled/2 returning :ok or {:error, :already_enrolled}, checked in a
  `with` chain before anything is built or stored.
- Build in a private build/2 that mints an ENR id, constructs %Enrollment{} (progress 0), and asserts the invariant
  with `true = e.progress in 0..100` so a broken invariant raises.
- Postcondition: on success return {:ok, %Enrollment{progress: 0}} after Portal.Store.put/1 succeeds.
Acceptance: valid USR/CRS ids enroll once and return {:ok, _}; a second identical call returns {:error,
:already_enrolled}; a malformed id returns {:error, :bad_reference}; forcing progress outside 0..100 raises.
```

```text
PROMPT 2 — Fail fast and map status
Ensure the contract is checked before any state changes (the `with` precondition runs before build/2 and
Portal.Store.put/1 — never build or store and then check). In Portal.Web.Router, map the enroll result:
{:ok, e} -> 201 with e.id; {:error, :already_enrolled} -> 422 "already enrolled";
{:error, :bad_reference} -> 422 "bad reference". Do not catch or convert a raised invariant error — let it crash.
Acceptance: the three curl calls (valid, duplicate, malformed) return 201, 422, 422 respectively, and a duplicate or
malformed request leaves the store unchanged (no partial write).
```

## Definition of done

- [ ] A valid `USR`/`CRS` pair enrolls once and returns `{:ok, %Enrollment{progress: 0}}`.
- [ ] A duplicate enroll returns `{:error, :already_enrolled}` → `422`.
- [ ] A malformed id returns `{:error, :bad_reference}` → `422`.
- [ ] A `progress` outside `0..100` raises (the invariant is asserted, not handled).
- [ ] The precondition is checked before `build/2` and `Portal.Store.put/1`; a rejected request writes nothing.

## Next

The contract closes F5.04. Next is **F5.05 · Commands, queries & events** — separate writes from reads and model each
change as a domain event. Back to the [chapter guide](pragmatic.md).

---

> Part of the jonnify toolkit. Branded build-stamp id format: `TSK` + Base62(snowflake).
