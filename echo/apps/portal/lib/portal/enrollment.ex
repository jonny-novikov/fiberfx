defmodule Portal.Enrollment do
  @moduledoc """
  The Enrollment bounded context (F6.4, renamed from `Portal.Learning`) — the
  event-sourced slice. Reads and appends through the `Portal.EventStore` port
  (F6.4-INV4), so it runs unchanged against the in-memory adapter in tests and Postgres
  in production. It exposes the published `%Portal.Enrollment.Enrolled{}` struct, never
  a schema.

  ## The engine is encapsulated (F6.4 reconciliation)

  This context is the PUBLIC boundary; `Portal.Engine` is its PRIVATE write mechanism.
  `enroll/2` calls `Portal.Engine.command/1` — the single-writer GenServer that
  serialises the not-already-enrolled fold check, the `Catalog.fetch_course/1`
  course-exists read, append-before-evolve, and the Store projection. The engine is
  retained UNCHANGED structurally (it earns its keep as the INV5 torn-write guard); it
  is no longer the facade's front door. This context is the ONLY module that names the
  engine — the facade (`Portal`) `defdelegate`s here and never names `Portal.Engine`.

  The engine returns its internal `%Portal.Enrollment.Enrollment{}` projection row;
  this context maps it to the published `%Enrolled{}` at the boundary, so callers
  receive the public struct and never the projection row or the engine internals.

  ## Cross-context composition (F6.4-D5/INV3/INV5)

  The not-already-enrolled / course-exists gating runs in `Portal.Engine.Core.authorize/2`,
  whose only call-out is `Portal.Catalog.fetch_course/1` — the one-way `Enrollment → Catalog`
  edge (no cycle: Catalog never names Enrollment). `authorize/2`'s bare reason is folded to
  the closed `%Portal.Error{}` set at the engine seam (`Portal.Error.new/1`), so callers see
  only the closed error vocabulary.

  ## Orchestration (F6.4-D6)

  `enroll_and_welcome/2` is a `with` chain across `Catalog`, this context, and
  `Accounts`, short-circuiting to one closed `%Portal.Error{}`. It lives here (not in
  the facade) because the facade owns no logic and this context already depends on
  `Catalog` one-way.
  """
  alias Portal.{Accounts, Catalog, Error}
  alias Portal.Engine
  alias Portal.Enrollment.Enrolled

  @doc """
  Enroll a user in a course. Returns the published `%Enrolled{}` on success, or one
  closed `%Portal.Error{}` (`:course_not_found` for a malformed/unknown reference,
  `:already_enrolled` for a duplicate).

  Calls `Portal.Engine.command/1` (the private write mechanism): the engine gates on
  `Core.authorize/2` (the not-already-enrolled fold check + `Catalog.fetch_course/1`),
  appends `%LearnerEnrolled{}` through the port, evolves the fold, and projects the
  Store row. The internal `%Portal.Enrollment.Enrollment{}` projection it returns is
  mapped to `%Enrolled{}` here, so the caller receives the published struct.

  Two error channels are distinct by type (the F5.8 contract preserved): a DOMAIN
  rejection from `Core.authorize/2` crosses as a closed `{:error, %Portal.Error{}}`; an
  INFRASTRUCTURE append failure crosses as the port's raw `{:error, term}` (NOT a
  `%Portal.Error{}` — the four-code union is a domain vocabulary, not infra). The raw
  channel is contract-required for Postgres substitutability and is passed through
  unchanged; it is unreachable against the total in-memory adapter.
  """
  @spec enroll(String.t(), String.t()) ::
          {:ok, Enrolled.t()} | {:error, Error.t() | term()}
  def enroll(user_id, course_id) do
    case Engine.command(%{type: :enroll, user_id: user_id, course_id: course_id}) do
      {:ok, enrollment} -> {:ok, to_enrolled(enrollment)}
      {:error, _reason} = error -> error
    end
  end

  @doc """
  Record that a lesson was delivered to a user — a CQS write returning `:ok`. Delegates
  to the engine command path (`%{type: :deliver_lesson, ...}`); a domain rejection
  crosses as `{:error, %Portal.Error{}}`.
  """
  @spec deliver_lesson(String.t(), String.t()) :: :ok | {:error, Error.t()}
  def deliver_lesson(user_id, lesson_id),
    do: Engine.command(%{type: :deliver_lesson, user_id: user_id, lesson_id: lesson_id})

  @doc """
  List a user's enrollments as published `%Enrolled{}` structs. Reads the engine's
  `:courses_of` projection (event-sourced via the fold, never the Repo — F6.4-INV4) and
  maps each internal projection row to `%Enrolled{}`.
  """
  @spec courses_of(String.t()) :: {:ok, [Enrolled.t()]}
  def courses_of(user_id) do
    enrolled = Engine.query({:courses_of, user_id}) |> Enum.map(&to_enrolled/1)
    {:ok, enrolled}
  end

  @doc """
  Read a user's enrollment progress.

  Returns `{:ok, 0}` — structurally `0`, an honest read: no progress-advancing event
  exists and every projected row is minted with `progress: 0`. Moving it off `0` is a
  later rung (a progress-advancing command + a projection change).
  """
  @spec progress_of(String.t()) :: {:ok, 0}
  def progress_of(_user_id), do: {:ok, 0}

  @doc """
  Enroll a learner and set up the welcome in one step (F6.4-D6/US5): a `with` chain
  across `Catalog`, this context, and `Accounts`, short-circuiting to one closed
  `%Portal.Error{}` on any failure.

  Each branch yields `{:ok, _} | {:error, %Portal.Error{}}`. `Catalog.fetch_course/1`'s
  bare `{:error, :not_found}` is folded to `%Portal.Error{:course_not_found}` at the
  seam (`:not_found` is not itself a `Portal.Error` code, so it is mapped explicitly —
  no catch-all, F6.4-INV5). Cross-context consistency uses THIS `with` chain, never a
  transaction spanning contexts (F6.4-INV6).
  """
  @spec enroll_and_welcome(String.t(), String.t()) ::
          {:ok, Enrolled.t()} | {:error, Error.t()}
  def enroll_and_welcome(user_id, course_id) do
    with {:ok, _course} <- fetch_course(course_id),
         {:ok, enrolled} <- enroll(user_id, course_id),
         {:ok, _user} <- welcome(user_id) do
      {:ok, enrolled}
    end
  end

  # ── seam: fold a context's bare reason into the closed %Portal.Error{} set ──────
  # Catalog.fetch_course/1 returns {:error, :not_found}; :not_found is not a
  # Portal.Error code, so map it explicitly to :course_not_found before from/1 (which
  # has no catch-all — F6.4-INV5).
  defp fetch_course(course_id) do
    case Catalog.fetch_course(course_id) do
      {:ok, course} -> {:ok, course}
      {:error, :not_found} -> {:error, Error.from(:course_not_found)}
    end
  end

  # Accounts.welcome/1 returns {:error, :not_found} for a missing learner. :not_found is
  # not itself a Portal.Error code, so it is mapped explicitly to :user_not_found — the
  # closed-set code for a learner-miss — before from/1 (which has no catch-all,
  # F6.4-INV5). The course-miss branch keeps :course_not_found; the two miss paths carry
  # distinct codes.
  defp welcome(user_id) do
    case Accounts.welcome(user_id) do
      {:ok, user} -> {:ok, user}
      {:error, :not_found} -> {:error, Error.from(:user_not_found)}
    end
  end

  # Internal projection row → published struct. Total over the engine's projection.
  defp to_enrolled(%Portal.Enrollment.Enrollment{} = e) do
    %Enrolled{id: e.id, user_id: e.user_id, course_id: e.course_id, progress: e.progress}
  end
end
