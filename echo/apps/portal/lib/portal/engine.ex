defmodule Portal.Engine do
  @moduledoc """
  The boundary between the web and the domain, and the runtime home of the F5.5
  pure core (F5.6). A single GenServer serialises commands and queries over one
  folded state (`Portal.Engine.Core.replay/1` of the stream). Since F5.8 the web
  reaches this boundary ONLY through the `Portal` facade; `command/1` and `query/1`
  (the F5.8 rename of the as-built `dispatch/1`/`query/2`) are the only callers of
  `GenServer.call` (F5.8-INV2), and `handle_call` and the state shape are private
  and add no business logic — the deciding and folding are the pure core's
  (F5.6-INV4/INV5).

  ## State home (F5.6-D1)

  A GenServer is chosen: the mailbox serialises command/query over one consistent
  fold, so a query never observes a half-applied command (F5.6-INV6). An Agent
  (simpler, but get/update lambdas rather than the mandated call callbacks) and ETS
  (concurrent reads, but manual consistency and no init replay hook) are the
  alternatives. The trade-off — one process is a throughput ceiling — is accepted at
  this scale.

  The crash-surviving stream lives in a SEPARATE process — the configured
  `Portal.EventStore` adapter (F5.8), started before this one, because a supervisor
  evaluates a child's args once; `init/1` reads the CURRENT stream through the port
  (`read_stream/1`) so a restart re-folds to the same state (F5.6-INV3). The engine
  names only the `Portal.EventStore` behaviour and the configured `adapter()`, never
  a concrete adapter (F5.8-INV1).

  ## The dual home: held fold (truth) + Store projection (the unchanged web's read model)

  The event stream is the source of truth and the held fold is the live read model
  (F5.6-INV1): `authorize`'s not-already-enrolled check reads the fold, and a
  restart reconstructs it from the stream. To leave the F5.3/F5.4 web boundary
  unchanged (F5.6-INV5), the command callback ALSO performs the F5.4 effect — mint
  an `ENR` id and `Portal.Store.put` an `%Enrollment{}` — so a command returns
  `{:ok, %Enrollment{}}` and `:courses_of` returns `%Enrollment{}`-shaped rows. The
  Store rows are a derived projection of the fold; `init/1` re-establishes them
  (`reproject_enrollments/1`) after a restart, so nothing web-visible lives only in
  volatile memory the stream cannot rebuild (F5.6-INV3).

  ## Append before evolve (F5.8-INV5)

  The command path appends events through the `Portal.EventStore` port BEFORE folding
  them into state. This inverts the as-built F5.6 order (evolve then append), which
  was safe only because `Portal.EventLog.append/1` was total and in-process. The
  port's `append/2` is FALLIBLE (`{:error, term}`, especially for Postgres), so a
  failed append aborts the command — the reply is the error and the state, the held
  fold, and the Store projection are all left unchanged (no `evolve`, no `project`).
  The fold never leads durable storage.
  """
  use GenServer
  alias Portal.Engine.Core
  # The internal Store-projection row (NOT the `Portal.Enrollment` context module): the
  # engine mints + stores `%Enrollment{}` rows the `Portal.Enrollment` context maps to
  # the published `%Enrolled{}` at its boundary.
  alias Portal.Enrollment.Enrollment
  alias Portal.Enrollment.Events.LearnerEnrolled

  # The single logical stream this engine reads and appends through the port. The
  # stream key is the engine's policy, not the port's or an adapter's — the
  # behaviour names the capability, the engine names the one stream it operates.
  @stream "portal"

  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @doc """
  Run a write command (e.g. enroll). Translates the web map to a core command and
  stamps `at`. The F5.8 rename of the as-built `dispatch/1`; with `query/1` the only
  caller of `GenServer.call` (F5.8-INV2).
  """
  @spec command(map()) :: {:ok, Enrollment.t()} | :ok | {:error, Portal.Error.t() | term()}
  def command(cmd) when is_map(cmd),
    do: GenServer.call(__MODULE__, {:command, to_command(cmd)})

  @doc """
  Run a read query as a single tagged tuple (e.g. `{:lesson, id}`,
  `{:courses_of, user_id}`). The F5.8 rename of the as-built `query/2`, collapsing
  its `(name, arg)` pair to one tuple; with `command/1` the only caller of
  `GenServer.call` (F5.8-INV2).
  """
  @spec query({atom(), term()}) :: {:ok, term()} | :error | [term()]
  def query({name, _arg} = q) when is_atom(name), do: GenServer.call(__MODULE__, {:query, q})

  @doc """
  Re-fold the held state from the CURRENT event stream, read through the port
  (test isolation only).

  Synchronous; mirrors `Portal.Store.reset/0` and the configured adapter's reset.
  The Engine holds derived in-memory state (the fold) whose only legitimate source
  is the stream, so a test that has emptied the stream must re-fold this process to
  clear it — without killing it (a kill on every test setup would exceed the
  supervisor's restart intensity and tear the tree down). Runs the same `load/0` as
  `init/1`.
  """
  @spec reset() :: :ok
  def reset, do: GenServer.call(__MODULE__, :reset)

  # ── init: fold the CURRENT stream once, then re-establish the Store projection ─
  @impl true
  def init(:ok), do: {:ok, load()}

  # ── command callback: authorize → decide → append (port) → evolve → project ──
  # Append BEFORE evolve (F5.8-INV5): the port's append/2 is fallible, so a failed
  # append aborts — the reply is the error and state, fold, and Store are unchanged
  # (no evolve, no project). On a successful append the events are folded and the
  # Store projection runs.
  @impl true
  def handle_call({:command, {:unknown, _raw}}, _from, state),
    do: {:reply, {:error, :unknown_command}, state}

  def handle_call({:command, cmd}, _from, state) do
    case Core.authorize(state, cmd) do
      :ok ->
        events = Core.decide(state, cmd)

        case Portal.EventStore.adapter().append(@stream, events) do
          :ok ->
            new_state = Enum.reduce(events, state, &Core.evolve/2)
            {:reply, project(cmd, events), new_state}

          {:error, _term} = err ->
            # A failed append aborts: no evolve, no project, state byte-unchanged.
            {:reply, err, state}
        end

      {:error, reason} ->
        {:reply, {:error, Portal.Error.new(reason)}, state}
    end
  end

  # ── query callback: read held state, never mutate (single tagged tuple) ───────
  def handle_call({:query, {:courses_of, user_id}}, _from, state),
    do: {:reply, project_enrollments(state, user_id), state}

  def handle_call({:query, {:lesson, id}}, _from, state),
    do: {:reply, Portal.Catalog.lesson(id), state}

  def handle_call({:query, {name, arg}}, _from, state),
    do: {:reply, query_or_unknown(state, name, arg), state}

  # Re-fold from the current (caller-emptied) log — test isolation; see reset/0.
  def handle_call(:reset, _from, _state), do: {:reply, :ok, load()}

  ## Shell-only helpers — translation / projection / wrapping ONLY (no rule lives
  ## here; every admissibility rule is `Portal.Engine.Core`'s — F5.6-INV4).

  # Fold the CURRENT stream (read through the port) and re-establish the Store
  # projection — the shared init/1 + reset/0 body, so the boot path and the test
  # re-fold cannot drift. read_stream/1 returns the whole stream in append order,
  # generalizing the as-built Portal.EventLog.all/0 (F5.8-D3).
  defp load do
    {:ok, log} = Portal.EventStore.adapter().read_stream(@stream)
    state = Core.replay(log)
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
