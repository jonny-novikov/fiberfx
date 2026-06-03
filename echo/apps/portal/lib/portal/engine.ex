defmodule Portal.Engine do
  @moduledoc """
  The boundary between the web and the domain, and the runtime home of the F5.5
  pure core (F5.6). A single GenServer serialises commands and queries over one
  folded state (`Portal.Engine.Core.replay/1` of the log). The web calls ONLY
  `dispatch/1` and `query/2`; `handle_call` and the state shape are private and add
  no business logic — the deciding and folding are the pure core's (F5.6-INV4/INV5).

  ## State home (F5.6-D1)

  A GenServer is chosen: the mailbox serialises command/query over one consistent
  fold, so a query never observes a half-applied command (F5.6-INV6). An Agent
  (simpler, but get/update lambdas rather than the mandated call callbacks) and ETS
  (concurrent reads, but manual consistency and no init replay hook) are the
  alternatives. The trade-off — one process is a throughput ceiling — is accepted at
  this scale.

  The crash-surviving log lives in a SEPARATE `Portal.EventLog` process started
  before this one, because a supervisor evaluates a child's args once; `init/1`
  reads the CURRENT log so a restart re-folds to the same state (F5.6-INV3).

  ## The dual home: held fold (truth) + Store projection (the unchanged web's read model)

  The event log is the source of truth and the held fold is the live read model
  (F5.6-INV1): `authorize`'s not-already-enrolled check reads the fold, and a
  restart reconstructs it from the log. To leave the F5.3/F5.4 web boundary
  unchanged (F5.6-INV5), the command callback ALSO performs the F5.4 effect — mint
  an `ENR` id and `Portal.Store.put` an `%Enrollment{}` — so `dispatch/1` returns
  `{:ok, %Enrollment{}}` and `:courses_of` returns `%Enrollment{}`-shaped rows. The
  Store rows are a derived projection of the fold; `init/1` re-establishes them
  (`reproject_enrollments/1`) after a restart, so nothing web-visible lives only in
  volatile memory the log cannot rebuild (F5.6-INV3).
  """
  use GenServer
  alias Portal.Engine.Core
  alias Portal.Learning.Enrollment
  alias Portal.Learning.Events.LearnerEnrolled

  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @doc "Run a write command (e.g. enroll). Translates the web map to a core command, stamps `at`."
  @spec dispatch(map()) :: {:ok, Enrollment.t()} | :ok | {:error, Portal.Error.t() | atom()}
  def dispatch(command) when is_map(command),
    do: GenServer.call(__MODULE__, {:command, to_command(command)})

  @doc "Run a read query (e.g. :lesson, :courses_of)."
  @spec query(atom(), term()) :: {:ok, term()} | :error | [term()]
  def query(name, arg) when is_atom(name), do: GenServer.call(__MODULE__, {:query, name, arg})

  @doc """
  Re-fold the held state from the CURRENT `Portal.EventLog` (test isolation only).

  Synchronous; mirrors `Portal.Store.reset/0` / `Portal.EventLog.reset/0`. The
  Engine holds derived in-memory state (the fold) whose only legitimate source is
  the log, so a test that has emptied the log must re-fold this process to clear it
  — without killing it (a kill on every test setup would exceed the supervisor's
  restart intensity and tear the tree down). Runs the same `load/0` as `init/1`.
  """
  @spec reset() :: :ok
  def reset, do: GenServer.call(__MODULE__, :reset)

  # ── init: fold the CURRENT log once, then re-establish the Store projection ───
  @impl true
  def init(:ok), do: {:ok, load()}

  # ── command callback: authorize → decide → evolve → record → project ─────────
  @impl true
  def handle_call({:command, {:unknown, _raw}}, _from, state),
    do: {:reply, {:error, :unknown_command}, state}

  def handle_call({:command, cmd}, _from, state) do
    case Core.authorize(state, cmd) do
      :ok ->
        events = Core.decide(state, cmd)
        new_state = Enum.reduce(events, state, &Core.evolve/2)
        :ok = Portal.EventLog.append(events)
        {:reply, project(cmd, events), new_state}

      {:error, reason} ->
        {:reply, {:error, Portal.Error.new(reason)}, state}
    end
  end

  # ── query callback: read held state, never mutate ────────────────────────────
  def handle_call({:query, :courses_of, user_id}, _from, state),
    do: {:reply, project_enrollments(state, user_id), state}

  def handle_call({:query, :lesson, id}, _from, state),
    do: {:reply, Portal.Catalog.lesson(id), state}

  def handle_call({:query, name, arg}, _from, state),
    do: {:reply, query_or_unknown(state, name, arg), state}

  # Re-fold from the current (caller-emptied) log — test isolation; see reset/0.
  def handle_call(:reset, _from, _state), do: {:reply, :ok, load()}

  ## Shell-only helpers — translation / projection / wrapping ONLY (no rule lives
  ## here; every admissibility rule is `Portal.Engine.Core`'s — F5.6-INV4).

  # Fold the CURRENT log and re-establish the Store projection — the shared
  # init/1 + reset/0 body, so the boot path and the test re-fold cannot drift.
  defp load do
    state = Core.replay(Portal.EventLog.all())
    reproject_enrollments(state)
    state
  end

  # Web map → core command (4-tuple), stamping the wall-clock at the shell (never
  # the core). A total function: an incomplete or unrecognised map cannot match the
  # full-key clauses, so it folds to `{:unknown, raw}` → `{:error, :unknown_command}`
  # (the as-built `dispatch(%{type: :enroll})` → `{:error, _}` behaviour the
  # supervision test relies on; never a crash).
  defp to_command(%{type: :enroll, user_id: user_id, course_id: course_id}),
    do: {:enroll, user_id, course_id, DateTime.utc_now()}

  defp to_command(%{type: :deliver_lesson, user_id: user_id, lesson_id: lesson_id}),
    do: {:deliver_lesson, user_id, lesson_id, DateTime.utc_now()}

  defp to_command(other), do: {:unknown, other}

  # Command success → the web's `{:ok, %Enrollment{}}` shape. Mints the `ENR` id and
  # writes the Store projection AFTER `Core.authorize` has gated, and runs NO
  # admissibility re-check (the fold's authorize is the sole gate — no torn write).
  # `deliver_lesson` and any other command need no web row: CQS `:ok`.
  defp project({:enroll, user_id, course_id, _at}, [%LearnerEnrolled{} | _]) do
    enrollment = %Enrollment{
      id: Portal.ID.new("ENR"),
      user_id: user_id,
      course_id: course_id,
      progress: 0
    }

    :ok = Portal.Store.put(enrollment)
    {:ok, enrollment}
  end

  defp project(_cmd, _events), do: :ok

  # Query `:courses_of` → `[%Enrollment{}]`, the unchanged web shape. The fold knows
  # the user's course ids; the matching `%Enrollment{}` rows come from the Store
  # projection, so the returned shape is byte-for-byte the F5.4 read.
  defp project_enrollments(state, user_id) do
    course_ids = MapSet.new(Core.query(state, {:enrollments, user_id}))

    "ENR"
    |> Portal.Store.all()
    |> Enum.filter(&(&1.user_id == user_id and MapSet.member?(course_ids, &1.course_id)))
  end

  # `:enrollments` is an alias for the fold read behind the live `:courses_of`;
  # anything else is the unknown-query tuple (the as-built fall-through).
  defp query_or_unknown(state, :enrollments, user_id),
    do: Core.query(state, {:enrollments, user_id})

  defp query_or_unknown(_state, _name, _arg), do: {:error, :unknown_query}

  # Walk the fold and `Store.put` a `%Enrollment{}` for every (user, course) lacking
  # one, so `:courses_of` is correct after a restart (idempotent: re-projection of
  # the deterministic log → fold → Store chain, F5.6-INV3). Minting a fresh `ENR`
  # id per row is sound — the id is a Store-projection handle, not an event fact.
  defp reproject_enrollments(state) do
    existing = MapSet.new(Portal.Store.all("ENR"), &{&1.user_id, &1.course_id})

    Enum.each(state.enrollments, fn {user_id, course_ids} ->
      Enum.each(course_ids, fn course_id ->
        unless MapSet.member?(existing, {user_id, course_id}) do
          Portal.Store.put(%Enrollment{
            id: Portal.ID.new("ENR"),
            user_id: user_id,
            course_id: course_id,
            progress: 0
          })
        end
      end)
    end)
  end
end
