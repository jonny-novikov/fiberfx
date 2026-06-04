defmodule Portal.EventStoreTest do
  # async: false — drives the shared, named Portal.Engine / Portal.Store / the configured
  # InMemory adapter, and swaps :event_store config to exercise the abort branch. Since
  # F6.4 the engine's course-exists gate reads Catalog.fetch_course/1 -> Repo INSIDE the
  # Engine process, so Portal.DataCase with async: false checks out a SHARED sandbox owner
  # (the Engine — and a restarted pid after the kill — sees the course seeded via Repo).
  use Portal.DataCase, async: false

  alias Portal.Catalog
  alias Portal.Enrollment.Enrolled

  # A failing adapter that satisfies the behaviour: read_stream delegates to the
  # real InMemory (so init/reset/replay still work), append always fails. Used to
  # exercise the engine's append-before-evolve ABORT branch (F5.8-INV5): a failed
  # append must leave state, fold, and the Store projection byte-unchanged.
  defmodule FailingAppend do
    @behaviour Portal.EventStore
    @impl Portal.EventStore
    def read_stream(stream), do: Portal.EventStore.InMemory.read_stream(stream)
    @impl Portal.EventStore
    def append(_stream, _events), do: {:error, :boom}
  end

  setup do
    Portal.Store.reset()
    Portal.EventStore.InMemory.reset()
    Portal.Engine.reset()

    on_exit(fn ->
      # Restore the configured adapter and clean shared state for the next file.
      Application.put_env(:portal, :event_store, Portal.EventStore.InMemory)
      Portal.Store.reset()
      Portal.EventStore.InMemory.reset()
      Portal.Engine.reset()
    end)

    :ok
  end

  defp seed_course do
    tok = Base.encode16(:crypto.strong_rand_bytes(8))
    {:ok, course} = Catalog.create_course(%{title: "Elixir #{tok}", slug: "elixir-#{tok}"})
    course.id
  end

  describe "InMemory adapter (F5.8-D1/D2)" do
    test "append preserves order; read_stream of an absent stream returns {:ok, []}" do
      assert {:ok, []} = Portal.EventStore.InMemory.read_stream("absent-stream")

      :ok = Portal.EventStore.InMemory.append("s", [%{n: 1}])
      :ok = Portal.EventStore.InMemory.append("s", [%{n: 2}, %{n: 3}])
      assert {:ok, [%{n: 1}, %{n: 2}, %{n: 3}]} = Portal.EventStore.InMemory.read_stream("s")

      :ok = Portal.EventStore.InMemory.reset()
      assert {:ok, []} = Portal.EventStore.InMemory.read_stream("s")
    end

    test "adapter/0 resolves the configured module; swapping config changes the resolution" do
      assert Portal.EventStore.adapter() == Portal.EventStore.InMemory

      Application.put_env(:portal, :event_store, Portal.EventStore.Postgres)
      assert Portal.EventStore.adapter() == Portal.EventStore.Postgres
    end
  end

  describe "Postgres adapter satisfies the behaviour (F6.3-D7 fills the F5.8 stub)" do
    # F5.8 shipped both callbacks as {:error, :not_implemented} stubs; F6.3 fills the
    # body (Repo.insert_all + read_stream ordered by :seq). The filled adapter touches
    # the DB, so its round-trip/ordering/rollback behaviour is tested in the Ecto
    # sandbox by Portal.EventStore.PostgresTest (Portal.DataCase), not here in the
    # engine suite (which runs InMemory with no DB ownership). This test pins only the
    # static substitutability fact (F6.3-INV5): the module satisfies the port.
    test "implements the Portal.EventStore behaviour (callbacks exported)" do
      assert function_exported?(Portal.EventStore.Postgres, :append, 2)
      assert function_exported?(Portal.EventStore.Postgres, :read_stream, 1)

      behaviours =
        Portal.EventStore.Postgres.module_info(:attributes)
        |> Keyword.get_values(:behaviour)
        |> List.flatten()

      assert Portal.EventStore in behaviours
    end
  end

  describe "append-before-evolve ABORT branch (F5.8-INV5, the torn-write hunt)" do
    test "a failed append leaves the fold AND the Store projection byte-unchanged, and returns the error" do
      user_id = Portal.ID.new("USR")
      course_id = seed_course()

      # A successful enroll establishes a baseline fold + one ENR row.
      assert {:ok, %Enrolled{}} = Portal.enroll(user_id, course_id)

      fold_before = :sys.get_state(Portal.Engine)
      enr_before = Portal.Store.all("ENR")
      stream_before = Portal.EventStore.InMemory.read_stream("portal")

      # Swap to the failing adapter and attempt a second (distinct) enroll.
      Application.put_env(:portal, :event_store, FailingAppend)
      other_course = seed_course()

      assert {:error, :boom} = Portal.enroll(user_id, other_course)

      # ZERO side effects below the boundary: no evolve (fold identical), no project
      # (no new ENR row), and the durable stream is unchanged — the append never
      # committed, so nothing folded or projected.
      assert :sys.get_state(Portal.Engine) == fold_before
      assert Portal.Store.all("ENR") == enr_before
      assert Portal.EventStore.InMemory.read_stream("portal") == stream_before
    end
  end

  describe "engine-process restart replays through the port (F5.8-D8)" do
    test "killing Portal.Engine and re-querying returns the SAME enrollment list" do
      user_id = Portal.ID.new("USR")
      course_id = seed_course()

      assert {:ok, %Enrolled{}} = Portal.enroll(user_id, course_id)
      {:ok, before} = Portal.courses_of(user_id)
      assert Enum.any?(before, &(&1.course_id == course_id))

      pid = Process.whereis(Portal.Engine)
      ref = Process.monitor(pid)
      Process.exit(pid, :kill)
      assert_receive {:DOWN, ^ref, :process, ^pid, :killed}, 1_000

      new_pid = wait_for_restart(pid)
      assert is_pid(new_pid) and new_pid != pid

      # The supervised adapter outlived the engine; init/1 re-read the stream
      # through the port and reproject_enrollments/1 re-established the Store rows.
      {:ok, after_restart} = Portal.courses_of(user_id)
      assert MapSet.new(before, & &1.course_id) == MapSet.new(after_restart, & &1.course_id)
      assert after_restart != []
    end
  end

  defp wait_for_restart(old_pid, tries \\ 50)
  defp wait_for_restart(_old_pid, 0), do: flunk("Portal.Engine did not restart")

  defp wait_for_restart(old_pid, tries) do
    case Process.whereis(Portal.Engine) do
      nil -> retry(old_pid, tries)
      ^old_pid -> retry(old_pid, tries)
      new_pid -> new_pid
    end
  end

  defp retry(old_pid, tries) do
    Process.sleep(20)
    wait_for_restart(old_pid, tries - 1)
  end
end
