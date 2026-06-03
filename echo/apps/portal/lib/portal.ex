defmodule Portal do
  @moduledoc """
  The Portal engine — F5 "Pragmatic Programming" value ladder.

  Since F5.8 this module is the public **facade** (the driving port): the only
  surface the web calls (F5.8-INV2). It exposes `enroll/2`, `deliver_lesson/2`,
  `progress_of/1`, `courses_of/1` (and the retained-route passthrough `lesson/1`),
  returning the closed outcome set `:ok | {:ok, data} | {:error, %Portal.Error{}}`,
  and delegates to the engine's `command/1`/`query/1` wrappers — the only callers of
  `GenServer.call`. Nothing above this boundary names the engine, the store, or the
  pure core; swapping the storage adapter or the web layer below leaves callers of
  this facade unchanged (F5.8-INV4, the F5→F6 contract).

  `courses_of/1` reads the dual-write `Portal.Store` `%Enrollment{}` rows (the web
  read shape) while the core's `query({:enrollments, user_id})` returns bare
  `[course_id]` (the fold read) — a deliberate two-layer naming, unified at F6.4.

  ## Exhaustive consumer sketch (F5.8-D7)

  The closed outcome set is consumed exhaustively — `{:ok, data}` and one branch per
  `Portal.Error` code, with no catch-all, so a new code forces a new branch:

      case Portal.enroll(user_id, course_id) do
        {:ok, enrollment} -> {:created, enrollment}
        {:error, %Portal.Error{code: :already_enrolled}} -> :duplicate
        {:error, %Portal.Error{code: :course_not_found}} -> :no_such_course
        {:error, %Portal.Error{code: :lesson_locked}} -> :locked
        {:error, %Portal.Error{code: :invalid_progress}} -> :bad_progress
      end

  `:lesson_locked` and `:invalid_progress` are reserved (no producers today); the
  sketch still branches on all four so the finite outcome set is closed and complete
  (the F5.9 LiveView adopts this exact shape).
  """
  alias Portal.Engine

  @doc """
  Enroll a user in a course. Delegates to `Portal.Engine.command/1`; an expected
  **domain** failure crosses as `{:error, %Portal.Error{}}` (F5.8-INV6).

  Two error channels are distinct by type: a domain rejection (from
  `Core.authorize/2`) is a closed `%Portal.Error{}`; an **infrastructure** append
  failure crosses as the port's raw `{:error, term}`, NOT a `%Portal.Error{}` (the
  four-code union is a domain vocabulary, not infra). That raw channel is contract-
  required for Postgres substitutability (F5.8-INV4/INV5) but is unreachable today —
  `Portal.EventStore.InMemory.append/2` is total — so it is omitted from the spec
  and first fires at F6.3; this spec advertises only the reachable domain outcome.
  """
  @spec enroll(String.t(), String.t()) ::
          {:ok, Portal.Learning.Enrollment.t()} | {:error, Portal.Error.t()}
  def enroll(user_id, course_id) do
    Engine.command(%{type: :enroll, user_id: user_id, course_id: course_id})
  end

  @doc """
  Record that a lesson was delivered to a user. CQS write — returns `:ok` on success.
  A domain rejection crosses as `{:error, %Portal.Error{}}`; an infra append failure
  crosses as the port's raw `{:error, term}` (unreachable today — see `enroll/2`).
  """
  @spec deliver_lesson(String.t(), String.t()) :: :ok | {:error, Portal.Error.t()}
  def deliver_lesson(user_id, lesson_id) do
    Engine.command(%{type: :deliver_lesson, user_id: user_id, lesson_id: lesson_id})
  end

  @doc """
  Read a user's enrollment progress.

  Returns `{:ok, 0}` — structurally `0` by **two independent mechanisms**, an honest
  read, not a calculation: no progress-advancing event exists (the core folds a
  `delivered` set, never a `progress` field), AND the `Portal.Store` projection mints
  every `%Enrollment{}` with `progress: 0` (F5.8-D4). Moving it off `0` is an F6
  concern (a progress-advancing command AND a projection change).
  """
  @spec progress_of(String.t()) :: {:ok, 0}
  def progress_of(_user_id), do: {:ok, 0}

  @doc """
  List a user's enrollments as `%Enrollment{}` rows. Wraps the engine's bare list in
  `{:ok, _}` — the web read shape (the dual-write `Portal.Store` projection).
  """
  @spec courses_of(String.t()) :: {:ok, [Portal.Learning.Enrollment.t()]}
  def courses_of(user_id), do: {:ok, Engine.query({:courses_of, user_id})}

  @doc """
  Read a catalog lesson by branded id — a passthrough delegating to the engine's
  `query({:lesson, id})`, kept so the retained `/lessons/:id` route does not name the
  engine (F5.8-INV2). A minimal extension for the catalog route, not new domain
  capability (a spec-refinement candidate for `f5.progress.md`).
  """
  @spec lesson(String.t()) :: {:ok, Portal.Catalog.Lesson.t()} | :error
  def lesson(id), do: Engine.query({:lesson, id})
end
