defmodule Portal.Engine.Core do
  @moduledoc """
  The pure functional core of the Portal engine (F5.5): the Decider.

  `decide/2` turns an admissible command into the event(s) to record; `evolve/2`
  folds exactly one event into state; `replay/1` derives the current state from a
  log as the left fold over `initial_state/0`. These four —
  `decide`/`evolve`/`replay`/`initial_state` — and the read `query/2` are **pure**:
  no I/O, no process, no clock (F5.5-INV2). The occurrence time `at` is the 4th
  element of every command tuple, supplied by the boundary, so `decide` is a
  deterministic function of `(state, command)`.

  The command boundary is guarded by `authorize/2`, which runs the F5.4 contract
  against the folded state and a single catalog read and returns the closed reasons
  (`:course_not_found`, `:already_enrolled`) BEFORE `decide` runs (F5.5-INV5).
  `authorize/2` is the only function here that calls out (one read of
  `Portal.Catalog.course/1`); `decide`/`evolve`/`replay`/`query` take no I/O at all.

  The runtime home that holds the folded state and routes commands through this
  core is F5.6 (a supervised `Portal.Engine` GenServer); this module is plain
  functions, not a process.
  """
  alias Portal.Learning.Events.{LearnerEnrolled, LessonDelivered}

  @typedoc "A domain event: a past-tense fact recorded in the log."
  @type event :: LearnerEnrolled.t() | LessonDelivered.t()

  @typedoc "The folded read model: per-user enrolled course ids and delivered lesson ids."
  @type state :: %{
          enrollments: %{optional(String.t()) => MapSet.t(String.t())},
          delivered: %{optional(String.t()) => MapSet.t(String.t())}
        }

  @typedoc "Write-path commands. `at` is the occurrence time supplied by the boundary."
  @type command ::
          {:enroll, user_id :: String.t(), course_id :: String.t(), at :: DateTime.t()}
          | {:deliver_lesson, user_id :: String.t(), lesson_id :: String.t(), at :: DateTime.t()}

  ## State + fold (F5.5-D4/D5)

  @doc ~S'''
  The empty state: no enrollments, no delivered lessons.

      iex> Portal.Engine.Core.initial_state()
      %{enrollments: %{}, delivered: %{}}
  '''
  @spec initial_state() :: state()
  def initial_state, do: %{enrollments: %{}, delivered: %{}}

  @doc """
  Fold one event into the state (F5.5-D4). One clause per event type; total over
  every event. Argument order is `(event, state)` so it drops into
  `Enum.reduce/3`'s `(element, acc)` reducer. Pure: no I/O, no clock. Only the
  fields the read model needs are read; `at` rides on the event for the audit log
  but is not part of the folded state at this scope.
  """
  @spec evolve(event(), state()) :: state()
  def evolve(%LearnerEnrolled{user_id: user_id, course_id: course_id}, state) do
    update_in(state.enrollments, fn by_user ->
      Map.update(by_user, user_id, MapSet.new([course_id]), &MapSet.put(&1, course_id))
    end)
  end

  def evolve(%LessonDelivered{user_id: user_id, lesson_id: lesson_id}, state) do
    update_in(state.delivered, fn by_user ->
      Map.update(by_user, user_id, MapSet.new([lesson_id]), &MapSet.put(&1, lesson_id))
    end)
  end

  @doc """
  Derive the current state from the event log (F5.5-D5): the left fold of `evolve/2`
  over `initial_state/0`. So the state is exactly the fold of the log (F5.5-INV4) —
  `replay(log)` and incremental folding are the same reduce.
  """
  @spec replay([event()]) :: state()
  def replay(log), do: Enum.reduce(log, initial_state(), &evolve/2)

  ## Decide (F5.5-D3)

  @doc """
  Decide what happened (F5.5-D3). Pure: returns the event(s) to record and mutates
  nothing.

  Reached only for an admissible command — `authorize/2` runs the F5.4 contract at
  the boundary first and returns the closed `{:error, reason}` before `decide`. So
  `decide` carries no error channel: it proposes facts, the boundary decides
  admissibility (F5.5-INV5). `at` arrives as the 4th element of the command tuple,
  so there is no clock here.
  """
  @spec decide(state(), command()) :: [event()]
  def decide(_state, {:enroll, user_id, course_id, at}) do
    [%LearnerEnrolled{user_id: user_id, course_id: course_id, at: at}]
  end

  def decide(_state, {:deliver_lesson, user_id, lesson_id, at}) do
    [%LessonDelivered{user_id: user_id, lesson_id: lesson_id, at: at}]
  end

  ## Authorize — the F5.4 contract at the boundary (F5.5-INV5)

  @doc """
  Guard the command boundary: the F5.4 contract, reading folded state (F5.5-INV5).
  Returns `:ok` for an admissible command, or a closed tagged reason BEFORE
  `decide` runs. The reference/course checks resolve `:course_not_found`; the
  folded state resolves `:already_enrolled`.

  The reason is a bare atom — the F5.6 shell maps it to `%Portal.Error{}` via
  `Portal.Error.new/1` (the existing seam). The catalog read inside `course_exists/1`
  is the only call-out in this module; `decide`/`evolve`/`replay`/`query` take no I/O.
  An enroll mirrors `Portal.Learning.enroll/2`'s `with`-chain, but the
  not-already-enrolled check reads `state`, not the Store. `:deliver_lesson` has no
  rejection reason at this scope, so it is always admissible.
  """
  @spec authorize(state(), command()) :: :ok | {:error, :course_not_found | :already_enrolled}
  def authorize(state, {:enroll, user_id, course_id, _at}) do
    with :ok <- check_ref(user_id, "USR"),
         :ok <- check_ref(course_id, "CRS"),
         {:ok, _course} <- course_exists(course_id),
         :ok <- refute_enrolled(state, user_id, course_id) do
      :ok
    end
  end

  def authorize(_state, {:deliver_lesson, _user_id, _lesson_id, _at}), do: :ok

  # A well-formed branded id of the expected namespace. `valid?/1` enforces the
  # full 14-char format (a bare "USR1" passes `namespace/1` but fails here);
  # `namespace/1` confirms the kind. A malformed/wrong-namespace ref folds into
  # :course_not_found, matching the F5.4 contract.
  defp check_ref(id, namespace) do
    if Portal.ID.valid?(id) and Portal.ID.namespace(id) == namespace,
      do: :ok,
      else: {:error, :course_not_found}
  end

  defp course_exists(course_id) do
    case Portal.Catalog.course(course_id) do
      {:ok, course} -> {:ok, course}
      :error -> {:error, :course_not_found}
    end
  end

  defp refute_enrolled(state, user_id, course_id) do
    enrolled = Map.get(state.enrollments, user_id, MapSet.new())
    if MapSet.member?(enrolled, course_id), do: {:error, :already_enrolled}, else: :ok
  end

  ## Query — the read path (F5.5-D6, CQS read side)

  @doc """
  Read the derived state (F5.5-D6). CQS: returns data, never mutates (F5.5-INV1).
  `{:enrollments, user_id}` lists the course ids the user is enrolled in.

  This pure read against folded state is DISTINCT from the live
  `Portal.Engine.query/2` GenServer call (which today routes `:courses_of` to the
  Store); F5.6 reroutes the live query to read this folded state.

      iex> alias Portal.Learning.Events.LearnerEnrolled
      iex> ev = %LearnerEnrolled{user_id: "USRaaaaaaaaaaa", course_id: "CRSaaaaaaaaaaa", at: ~U[2026-01-01 00:00:00Z]}
      iex> state = Portal.Engine.Core.evolve(ev, Portal.Engine.Core.initial_state())
      iex> Portal.Engine.Core.query(state, {:enrollments, "USRaaaaaaaaaaa"})
      ["CRSaaaaaaaaaaa"]
  """
  @spec query(state(), {:enrollments, String.t()}) :: [String.t()]
  def query(state, {:enrollments, user_id}) do
    state.enrollments |> Map.get(user_id, MapSet.new()) |> MapSet.to_list()
  end
end
