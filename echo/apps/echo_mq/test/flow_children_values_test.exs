defmodule EchoMQ.FlowChildrenValuesTest do
  @moduledoc """
  EMQ.3.2 -- the child-result reads: the host API a flow's parent handler reads
  its children's outcomes through. `EchoMQ.Flows.children_values/3` reads the
  parent's `:processed` HASH back as the completed children's RESULTS keyed by
  child id; `EchoMQ.Flows.dependencies/3`
  reads the parent's `:dependencies` STRING counter as the outstanding count
  (Fork R2.A -- the count, not the set).

  The O1 close (INV5): emq.3.1 wrote `:processed` as a `child_id -> child_id`
  PRESENCE marker (`complete/4` carried no result). emq.3.2 threads a result
  through the EXISTING `ARGV[5]` slot the fan-in hook already `HSET`s, so
  `:processed[child_id]` holds the REAL result -- and the shipped `@complete`
  Lua is BYTE-UNCHANGED (host-only -- only the value the host supplies for
  `ARGV[5]` changes, from `job_id` to the result). `children_values/3` returns
  the results, NOT the child ids.

  The reads are PURE (INV2): `HGETALL`/`GET`-class only, no `HSET`/`SET`/`DECR`/
  `ZADD`/`DEL` -- a double-read leaves `:dependencies` + `:processed`
  byte-identical. The `parent_id` is gated at `Keyspace.job_key/2` (raises on an
  ill-formed id -- INV4) BEFORE the wire.

  This is the mint/process-touching flow suite -- it mints N+1 ids per flow and
  fans in across completions -- so it runs under the >=100-iteration determinism
  loop owning the machine (one green run is NOT proof). Per-test sub-queues;
  Valkey 6390 the truth row. EMQ.3.2-US2 / US3 / US5 / AS-3 / AS-4.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Admin, Connector, Flows, Jobs, Keyspace}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq32.fcv#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(q) end)
    %{conn: conn, q: q}
  end

  describe "children_values/3 -- the parent reads its children's results (the O1 close)" do
    test "two children completed with distinct results read back as the results keyed by id",
         %{conn: conn, q: q} do
      {parent, [c1, c2]} = add_flow(conn, q, 2)

      # before any child completes: the empty result map, never an error
      assert {:ok, %{}} == Flows.children_values(conn, q, parent)

      # complete both children, each carrying a DISTINCT result keyed to its id
      r1 = complete_with_result(conn, q)
      r2 = complete_with_result(conn, q)

      # children_values returns the RESULTS (not the child-id presence markers
      # emq.3.1 wrote) keyed by child id -- O1 closed, INV5
      assert {:ok, values} = Flows.children_values(conn, q, parent)
      assert values == %{c1 => "r-" <> c1, c2 => "r-" <> c2}
      assert values == %{r1.id => r1.result, r2.id => r2.result}

      # the values are the results, provably NOT the child ids
      refute Map.keys(values) |> Enum.any?(fn id -> values[id] == id end)
    end

    test "a parent with no completed children yet returns {:ok, %{}}", %{conn: conn, q: q} do
      {parent, [_c1, _c2]} = add_flow(conn, q, 2)
      assert {:ok, %{}} == Flows.children_values(conn, q, parent)
    end

    test "an ill-formed parent_id raises at Keyspace.job_key/2 before any wire", %{
      conn: conn,
      q: q
    } do
      assert_raise ArgumentError, fn -> Flows.children_values(conn, q, "not-branded") end
    end
  end

  describe "dependencies/3 -- the parent reads its outstanding-child count (Fork R2.A)" do
    test "the count is N before any completion, N-k after k complete, 0 at full fan-in", %{
      conn: conn,
      q: q
    } do
      {parent, _children} = add_flow(conn, q, 3)

      assert {:ok, 3} == Flows.dependencies(conn, q, parent)
      complete_with_result(conn, q)
      assert {:ok, 2} == Flows.dependencies(conn, q, parent)
      complete_with_result(conn, q)
      assert {:ok, 1} == Flows.dependencies(conn, q, parent)
      complete_with_result(conn, q)
      assert {:ok, 0} == Flows.dependencies(conn, q, parent)
    end

    test "a parent with no :dependencies key (not a flow parent) returns the {:ok, 0} sentinel",
         %{conn: conn, q: q} do
      # a plain enqueued job is not a flow parent -- it has no :dependencies key
      lone = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, lone, "solo")
      assert {:ok, 0} == Flows.dependencies(conn, q, lone)
    end

    test "an ill-formed parent_id raises at Keyspace.job_key/2 before any wire", %{
      conn: conn,
      q: q
    } do
      assert_raise ArgumentError, fn -> Flows.dependencies(conn, q, "not-branded") end
    end
  end

  describe "the reads are pure (INV2) -- no write, no state transition" do
    test "a double-read leaves :dependencies and :processed byte-identical", %{conn: conn, q: q} do
      {parent, _children} = add_flow(conn, q, 2)
      complete_with_result(conn, q)

      # snapshot the subkeys before the reads
      deps_before = raw_deps(conn, q, parent)
      processed_before = raw_processed(conn, q, parent)

      # read each twice
      assert {:ok, v1} = Flows.children_values(conn, q, parent)
      assert {:ok, ^v1} = Flows.children_values(conn, q, parent)
      assert {:ok, d1} = Flows.dependencies(conn, q, parent)
      assert {:ok, ^d1} = Flows.dependencies(conn, q, parent)

      # the subkeys are byte-identical after the reads -- the reads effect no
      # state change (INV2)
      assert raw_deps(conn, q, parent) == deps_before
      assert raw_processed(conn, q, parent) == processed_before
    end
  end

  # flow-read proves more than the two-child
  # happy path: get_dependencies_count exercises a THREE-child flow
  # (flow_producer_test.exs:444), and "parent can access children results after
  # completion" reads the results map MID-handler (:519). The two tests below
  # close the matching v2 gaps -- the results read on a >2-child flow, and the
  # results read after PARTIAL completion (the map holds ONLY the completed
  # children) -- behaviors the as-built two-child cases above do not prove.

  describe "children_values/3 at flow width and at partial fan-in" do
    test "a three-child flow reads back all three distinct results keyed by id", %{
      conn: conn,
      q: q
    } do
      # get_dependencies_count depth bar is a 3-child flow; children_values
      # must read back the full result map at that width, not a 2-bounded subset.
      {parent, [c1, c2, c3]} = add_flow(conn, q, 3)

      r1 = complete_with_result(conn, q)
      r2 = complete_with_result(conn, q)
      r3 = complete_with_result(conn, q)

      assert {:ok, values} = Flows.children_values(conn, q, parent)
      assert map_size(values) == 3
      assert values == %{c1 => "r-" <> c1, c2 => "r-" <> c2, c3 => "r-" <> c3}
      assert values == %{r1.id => r1.result, r2.id => r2.result, r3.id => r3.result}
      assert {:ok, 0} == Flows.dependencies(conn, q, parent)
    end

    test "after a PARTIAL fan-in the map holds only the completed child's result", %{
      conn: conn,
      q: q
    } do
      # the parent handler reads its children's outcomes as they land -- after k
      # of N complete, children_values returns EXACTLY the k completed results
      # (the map grows with fan-in), and dependencies counts the N-k still
      # outstanding.
      {parent, _children} = add_flow(conn, q, 3)

      # complete one of three: exactly that child's result is present, 2 outstanding
      first = complete_with_result(conn, q)
      assert {:ok, %{} = partial} = Flows.children_values(conn, q, parent)
      assert partial == %{first.id => first.result}
      assert {:ok, 2} == Flows.dependencies(conn, q, parent)

      # complete a second: the map now holds exactly the two completed results
      second = complete_with_result(conn, q)
      assert {:ok, two} = Flows.children_values(conn, q, parent)
      assert two == %{first.id => first.result, second.id => second.result}
      assert {:ok, 1} == Flows.dependencies(conn, q, parent)
    end
  end

  # -- the L-5 / N1 flow-subkey lifecycle honest bound (the named carry) -----
  # emq.3.2 reads :processed/:dependencies; D-2/N1 NAMES (does not silence) that
  # these subkeys OUTLIVE both the parent row (`@complete` DELs only the row) and
  # `obliterate` (`del_job` enumerates a FIXED jk/:logs/:lock, not the flow
  # subkeys) -- the cleanup is routed to the emq.3.x lifecycle rung, admin.ex
  # UNTOUCHED here (INV7). This test PINS the as-built leak so the carry is
  # ASSERTED, not silent prose: a future rung that begins sweeping these subkeys
  # flips this test, prompting the spec update -- the gate the emq.3.1 harness
  # forward-points to ("the obliterate non-sweep is the named honest bound").
  describe "the flow-subkey lifecycle honest bound (D-2/N1 -- the named carry)" do
    test ":processed and :dependencies survive the parent's own completion and obliterate", %{
      conn: conn,
      q: q
    } do
      {parent, _children} = add_flow(conn, q, 2)
      complete_with_result(conn, q)
      complete_with_result(conn, q)

      # after fan-in: the subkeys are live -- :dependencies at 0, :processed full
      assert {:ok, "0"} == raw_deps(conn, q, parent)
      assert {:ok, 2} == Connector.command(conn, ["HLEN", processed_key(q, parent)])

      # claim + complete the PARENT itself: `@complete` DELs only its row
      {:ok, {^parent, _, ptok}} = Jobs.claim(conn, q, 60_000)
      :ok = Jobs.complete(conn, q, parent, ptok)
      assert {:ok, 0} == Connector.command(conn, ["EXISTS", Keyspace.job_key(q, parent)])

      # the flow subkeys OUTLIVE the parent row (the @complete-only-the-row bound)
      assert {:ok, 1} == Connector.command(conn, ["EXISTS", deps_key(q, parent)])
      assert {:ok, 1} == Connector.command(conn, ["EXISTS", processed_key(q, parent)])

      # and they OUTLIVE obliterate too -- del_job's fixed enumeration misses them
      :ok = Admin.pause(conn, q)
      :ok = Admin.obliterate(conn, q)
      assert {:ok, 1} == Connector.command(conn, ["EXISTS", deps_key(q, parent)])
      assert {:ok, 1} == Connector.command(conn, ["EXISTS", processed_key(q, parent)])
    end
  end

  # -- helpers --------------------------------------------------------------

  # Add a flow of a parent + n same-queue children; return {parent_id, child_ids}.
  defp add_flow(conn, q, n) do
    parent = BrandedId.generate!("JOB")
    children = for i <- 1..n, do: %{id: BrandedId.generate!("JOB"), payload: "c#{i}"}
    child_ids = Enum.map(children, & &1.id)

    {:ok, {^parent, ^child_ids}} =
      Flows.add(conn, q, %{parent: %{id: parent, payload: "P"}, children: children})

    {parent, child_ids}
  end

  # Claim the next pending child and complete it with a DISTINCT result keyed to
  # its own id ("r-" <> id) -- the Fork R1.B host-only result arg threaded
  # through complete/5 into the existing ARGV[5]. Return %{id, result}.
  defp complete_with_result(conn, q) do
    {:ok, {id, _, tok}} = Jobs.claim(conn, q, 60_000)
    result = "r-" <> id
    :ok = Jobs.complete(conn, q, id, tok, result)
    %{id: id, result: result}
  end

  defp deps_key(q, parent), do: Keyspace.job_key(q, parent) <> ":dependencies"
  defp processed_key(q, parent), do: Keyspace.job_key(q, parent) <> ":processed"

  defp raw_deps(conn, q, parent), do: Connector.command(conn, ["GET", deps_key(q, parent)])

  defp raw_processed(conn, q, parent),
    do: Connector.command(conn, ["HGETALL", processed_key(q, parent)])

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end
end
