defmodule EchoMQ.FlowRecursionTest do
  @moduledoc """
  EMQ.3.5 -- grandchildren / deep recursion, the flow family's CLOSER. A flow
  tree more than one level deep: a parent (the ROOT), an INTERMEDIATE node that
  is itself a flow-parent of grandchildren, and the grandchildren (leaves) --
  the v1 `flow_producer`'s arbitrary-depth `build_flow_commands`, re-derived
  under the v2 laws. The build is Arm A (host/sweep-orchestrated over the
  byte-frozen scripts -> NORMAL-risk), so EVERY shipped Lua body is unchanged;
  the recursion is the host tree-walk (`Flows.add/3`'s nested-tree clause -- D2)
  plus the host re-emit (`Pump`'s recursive failure hook -- D4).

  The headline finding (emq.3.5-D3): COMPLETION composes recursively for FREE
  over the byte-frozen `@complete`. An intermediate node, when its children
  complete, is RELEASED to `pending` by the existing fan-in as a REAL claimable
  job whose completion fans into the root -- so emq.3.5 builds NO new completion
  script; the recursive ENQUEUE is what makes the tree multi-level. FAILURE is
  the genuine new mechanism: a death must propagate UP every hop (the recursive
  failure hook re-emits a dead node's death to its own parent by the node's
  policy, over the existing fail-entry + outbox + sweep + `@flow_fail_deliver`).

  Each hop is ATOMIC same-queue (one `@complete`/`@retry` EVAL) and
  EVENTUALLY-CONSISTENT per-tick cross-queue (the sweep deliver, B1) -- never
  "atomic across queues" nor "synchronous deep recursion." The tree is validated
  ACYCLIC + within a DEPTH CAP (8) host-side BEFORE any wire (B2/B3). This is the
  most MINT-DENSE surface (a tree mints one branded JOB id per node across many
  queues), so it runs under the >=100-iteration determinism loop owning the
  machine (one green run is NOT proof -- the same-ms mint collision flakes only
  across runs, B5). Per-test sub-queues; Valkey 6390 the truth row.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Flows, Jobs, Keyspace, Metrics, Pump}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    base = "emq35.rec#{System.unique_integer([:positive])}"
    on_exit(fn -> purge([base, base <> ".n", base <> ".g", base <> ".n2", base <> ".g2"]) end)
    %{conn: conn, q: base}
  end

  describe "the recursive enqueue (emq.3.5-D2) -- the host depth-first tree walk" do
    test "a same-queue three-level tree lands: root + node held, grandchild claimable", %{
      conn: conn,
      q: q
    } do
      root = BrandedId.generate!("JOB")
      node = BrandedId.generate!("JOB")
      gc = BrandedId.generate!("JOB")

      assert {:ok, {^root, [{^node, [{^gc, []}]}]}} =
               Flows.add(conn, q, %{
                 parent: %{id: root, payload: "R"},
                 children: [%{id: node, payload: "N", children: [%{id: gc, payload: "G"}]}]
               })

      # the root is held with its 1 direct child (the node)
      assert {:ok, :awaiting_children} = Metrics.get_job_state(conn, q, root)
      assert {:ok, 1} = Flows.dependencies(conn, q, root)
      # the node is held with ITS 1 direct child (the grandchild) AND carries
      # its own parent link toward the root
      assert {:ok, :awaiting_children} = Metrics.get_job_state(conn, q, node)
      assert {:ok, 1} = Flows.dependencies(conn, q, node)

      assert {:ok, [^root, ""]} =
               Connector.command(conn, ["HMGET", Keyspace.job_key(q, node), "parent", "parent_queue"])
               |> drop_nil_pq()

      # only the grandchild is claimable (a real leaf in pending)
      assert {:ok, {^gc, "G", 1}} = Jobs.claim(conn, q, 60_000)
      assert :empty = Jobs.claim(conn, q, 60_000)
    end

    test "every node mints a DISTINCT branded JOB id (the order theorem at scale)", %{
      conn: conn,
      q: q
    } do
      ids = for _ <- 1..5, do: BrandedId.generate!("JOB")
      [root, n1, n2, g1, g2] = ids
      assert length(Enum.uniq(ids)) == 5

      assert {:ok, {^root, _}} =
               Flows.add(conn, q, %{
                 parent: %{id: root, payload: "R"},
                 children: [
                   %{id: n1, payload: "N1", children: [%{id: g1, payload: "G1"}]},
                   %{id: n2, payload: "N2", children: [%{id: g2, payload: "G2"}]}
                 ]
               })

      # five distinct rows landed (one job per node)
      for id <- ids do
        assert {:ok, 1} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, id)])
      end
    end

    test "an ill-formed id at ANY node raises before any wire (INV4)", %{conn: conn, q: q} do
      root = BrandedId.generate!("JOB")
      node = BrandedId.generate!("JOB")

      assert_raise ArgumentError, fn ->
        Flows.add(conn, q, %{
          parent: %{id: root, payload: "R"},
          children: [%{id: node, payload: "N", children: [%{id: "not-a-branded-id", payload: "G"}]}]
        })
      end

      # nothing landed (the gate ran before any wire)
      assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, root)])
    end

    test "a CYCLE (a repeated node id) is rejected before any wire (INV8/B2)", %{conn: conn, q: q} do
      root = BrandedId.generate!("JOB")
      node = BrandedId.generate!("JOB")

      # the grandchild reuses the root's id -> a cycle
      assert {:error, {:flow_cycle, ^root}} =
               Flows.add(conn, q, %{
                 parent: %{id: root, payload: "R"},
                 children: [%{id: node, payload: "N", children: [%{id: root, payload: "G"}]}]
               })

      # no partial wire: the root never landed
      assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, root)])
    end

    test "a tree DEEPER than the cap (8) is rejected before any wire (INV8/B3)", %{
      conn: conn,
      q: q
    } do
      # build a 9-level chain (root at level 1, so level 9 > cap 8)
      ids = for _ <- 1..9, do: BrandedId.generate!("JOB")

      tree =
        ids
        |> Enum.reverse()
        |> Enum.reduce(nil, fn id, acc ->
          children = if acc, do: [acc], else: []
          %{id: id, payload: "x", children: children}
        end)

      [root | _] = ids
      flow = %{parent: %{id: root, payload: "R"}, children: tree.children}

      assert {:error, {:flow_too_deep, 8}} = Flows.add(conn, q, flow)
      assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, root)])
    end

    test "a tree AT the cap (8 levels) lands", %{conn: conn, q: q} do
      ids = for _ <- 1..8, do: BrandedId.generate!("JOB")

      tree =
        ids
        |> Enum.reverse()
        |> Enum.reduce(nil, fn id, acc ->
          children = if acc, do: [acc], else: []
          %{id: id, payload: "x", children: children}
        end)

      [root | _] = ids
      assert {:ok, {^root, _}} = Flows.add(conn, q, %{parent: %{id: root, payload: "R"}, children: tree.children})
      # every node landed
      for id <- ids, do: assert({:ok, 1} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, id)]))
    end

    test "a FLAT flow (no nested children) is unchanged -- the emq.3.1 atomic path", %{
      conn: conn,
      q: q
    } do
      parent = BrandedId.generate!("JOB")
      c1 = BrandedId.generate!("JOB")
      c2 = BrandedId.generate!("JOB")

      # the FLAT return shape (NOT the nested tree_result) -- byte-for-byte the
      # emq.3.1-3.4 contract
      assert {:ok, {^parent, [^c1, ^c2]}} =
               Flows.add(conn, q, %{
                 parent: %{id: parent, payload: "P"},
                 children: [%{id: c1, payload: "c1"}, %{id: c2, payload: "c2"}]
               })

      assert {:ok, "2"} = Connector.command(conn, ["GET", Keyspace.job_key(q, parent) <> ":dependencies"])
      assert {:ok, :awaiting_children} = Metrics.get_job_state(conn, q, parent)
    end
  end

  describe "multi-level completion (emq.3.5-D3) -- composes over the byte-frozen @complete for free" do
    test "SAME-QUEUE: the grandchild completes -> node released -> the node completes -> root released",
         %{conn: conn, q: q} do
      root = BrandedId.generate!("JOB")
      node = BrandedId.generate!("JOB")
      gc = BrandedId.generate!("JOB")

      {:ok, {^root, [{^node, [{^gc, []}]}]}} =
        Flows.add(conn, q, %{
          parent: %{id: root, payload: "R"},
          children: [%{id: node, payload: "N", children: [%{id: gc, payload: "G"}]}]
        })

      # the grandchild completes -> the node is RELEASED to pending (a real job)
      {:ok, {^gc, "G", 1}} = Jobs.claim(conn, q, 60_000)
      :ok = Jobs.complete(conn, q, gc, 1, "g-done")

      assert {:ok, 0} = Flows.dependencies(conn, q, node)
      assert {:ok, :pending} = Metrics.get_job_state(conn, q, node)
      # the root is STILL held (the node has not completed)
      assert {:ok, :awaiting_children} = Metrics.get_job_state(conn, q, root)
      assert {:ok, 1} = Flows.dependencies(conn, q, root)

      # the node ran ON its child's result (emq.3.2)
      assert {:ok, %{^gc => "g-done"}} = Flows.children_values(conn, q, node)

      # complete the node -> the ROOT is released (the recursion up)
      {:ok, {^node, "N", 1}} = Jobs.claim(conn, q, 60_000)
      :ok = Jobs.complete(conn, q, node, 1, "n-done")

      assert {:ok, 0} = Flows.dependencies(conn, q, root)
      assert {:ok, :pending} = Metrics.get_job_state(conn, q, root)
      assert {:ok, {^root, "R", 1}} = Jobs.claim(conn, q, 60_000)
    end

    test "CROSS-QUEUE: each hop fans in on a sweep tick (eventually-consistent, B1)", %{
      conn: conn,
      q: q
    } do
      nq = q <> ".n"
      gq = q <> ".g"
      root = BrandedId.generate!("JOB")
      node = BrandedId.generate!("JOB")
      gc = BrandedId.generate!("JOB")

      # the three nodes are on three DIFFERENT slots (the forcing constraint)
      assert Keyspace.slot(Keyspace.job_key(q, root)) != Keyspace.slot(Keyspace.job_key(nq, node))
      assert Keyspace.slot(Keyspace.job_key(nq, node)) != Keyspace.slot(Keyspace.job_key(gq, gc))

      {:ok, {^root, [{^node, [{^gc, []}]}]}} =
        Flows.add(conn, q, %{
          parent: %{id: root, payload: "R"},
          children: [%{id: node, payload: "N", queue: nq, children: [%{id: gc, payload: "G", queue: gq}]}]
        })

      # the grandchild completes IN ITS QUEUE -> emits to gq's outbox
      {:ok, {^gc, "G", 1}} = Jobs.claim(conn, gq, 60_000)
      :ok = Jobs.complete(conn, gq, gc, 1, "g-done")
      # the node is held pre-sweep (eventually-consistent)
      assert {:ok, 1} = Flows.dependencies(conn, nq, node)

      # the gq sweep delivers the decrement on the NODE's slot -> node released
      assert {:ok, 1} = Pump.deliver_flow_completions(conn, gq, 100)
      assert {:ok, 0} = Flows.dependencies(conn, nq, node)
      assert {:ok, :pending} = Metrics.get_job_state(conn, nq, node)

      # complete the node in ITS queue -> emits to nq's outbox; the root held
      {:ok, {^node, "N", 1}} = Jobs.claim(conn, nq, 60_000)
      :ok = Jobs.complete(conn, nq, node, 1, "n-done")
      assert {:ok, 1} = Flows.dependencies(conn, q, root)

      # the nq sweep delivers on the ROOT's slot -> root released (recursion up)
      assert {:ok, 1} = Pump.deliver_flow_completions(conn, nq, 100)
      assert {:ok, 0} = Flows.dependencies(conn, q, root)
      assert {:ok, {^root, "R", 1}} = Jobs.claim(conn, q, 60_000)
    end
  end

  describe "the recursive failure hook (emq.3.5-D4) -- a death propagates UP every level" do
    test "SAME-QUEUE fail_parent: the grandchild dies -> the node dies -> the ROOT dies", %{
      conn: conn,
      q: q
    } do
      root = BrandedId.generate!("JOB")
      node = BrandedId.generate!("JOB")
      gc = BrandedId.generate!("JOB")

      {:ok, {^root, [{^node, [{^gc, []}]}]}} =
        Flows.add(conn, q, %{
          parent: %{id: root, payload: "R"},
          children: [%{id: node, payload: "N", children: [%{id: gc, payload: "G"}]}]
        })

      # kill the grandchild past max attempts via the PRODUCTION path (retry/7,
      # exactly what a worker calls) -> @retry's sq:fp arm fails the NODE
      # atomically (the node is the grandchild's same-queue parent), AND retry/7
      # itself triggers the recursive re-emit of the node's death UP into q's
      # outbox (emq.3.5-D4 -- NO hand-call; the host hook fires inside retry/7).
      {:ok, {^gc, _, 1}} = Jobs.claim(conn, q, 60_000)
      {:ok, :dead} = Jobs.retry(conn, q, gc, 1, 10, 1, "boom-gc")

      # the node is dead atomically with the grandchild in the node's :failed
      assert {:ok, :dead} = Metrics.get_job_state(conn, q, node)
      assert {:ok, %{^gc => "boom-gc"}} = hgetall(conn, Keyspace.job_key(q, node) <> ":failed")
      # the root is NOT yet dead (the node's death is in q's outbox, delivered on
      # the sweep tick -- eventually-consistent, B1)
      assert {:ok, :awaiting_children} = Metrics.get_job_state(conn, q, root)

      # the q sweep delivers the node's death (re-emitted by retry/7) on the
      # ROOT's slot -> root dead. This exercises the PRODUCTION path end to end
      # (retry/7 -> outbox -> sweep -> @flow_fail_deliver), not a simulated hook.
      assert {:ok, 1} = Pump.deliver_flow_completions(conn, q, 100)
      assert {:ok, :dead} = Metrics.get_job_state(conn, q, root)
      assert {:ok, %{^node => "boom-gc"}} = hgetall(conn, Keyspace.job_key(q, root) <> ":failed")
    end

    test "SAME-QUEUE 4-LEVEL: the death RECURSES hop by hop (the deliver-loop re-emit, not a single delivery)",
         %{conn: conn, q: q} do
      # A FOUR-level same-queue chain (root -> n1 -> n2 -> leaf, all in q,
      # all fail_parent). This is the proof a depth-3 chain CANNOT give: at
      # depth 3 `retry/7`'s own `on_same_queue_child_death` re-emits the node's
      # death DIRECTLY to the root (the node's parent IS the root), so ONE sweep
      # tick finishes -- the RECURSIVE deliver-loop re-emit (a node failed BY a
      # sweep delivery, itself re-emitting to ITS parent) never fires. At depth 4
      # the death must take TWO re-emit hops: retry/7 re-emits n2->n1 (hop 1),
      # then the DELIVER-LOOP, on failing n1, must re-emit n1->root (hop 2 -- the
      # recursive hop). A regression isolated to the deliver-loop re-emit passes
      # depth 3 and fails HERE.
      root = BrandedId.generate!("JOB")
      n1 = BrandedId.generate!("JOB")
      n2 = BrandedId.generate!("JOB")
      leaf = BrandedId.generate!("JOB")

      {:ok, {^root, [{^n1, [{^n2, [{^leaf, []}]}]}]}} =
        Flows.add(conn, q, %{
          parent: %{id: root, payload: "R"},
          children: [
            %{
              id: n1,
              payload: "N1",
              children: [%{id: n2, payload: "N2", children: [%{id: leaf, payload: "L"}]}]
            }
          ]
        })

      # every intermediate node carries its own parent link toward its parent
      assert {:ok, [^root, "fp"]} =
               Connector.command(conn, ["HMGET", Keyspace.job_key(q, n1), "parent", "parent_policy"])

      assert {:ok, [^n1, "fp"]} =
               Connector.command(conn, ["HMGET", Keyspace.job_key(q, n2), "parent", "parent_policy"])

      # kill the leaf -> @retry's sq:fp arm fails n2 atomically AND retry/7
      # re-emits n2's death up into q's outbox (hop 1, the retry/7 trigger)
      {:ok, {^leaf, _, 1}} = Jobs.claim(conn, q, 60_000)
      {:ok, :dead} = Jobs.retry(conn, q, leaf, 1, 10, 1, "boom")

      assert {:ok, :dead} = Metrics.get_job_state(conn, q, n2)
      # n1 and root are BOTH still held -- the death has only reached n2 so far
      assert {:ok, :awaiting_children} = Metrics.get_job_state(conn, q, n1)
      assert {:ok, :awaiting_children} = Metrics.get_job_state(conn, q, root)
      # exactly one queued hop: n2 -> n1
      assert {:ok, 1} = Connector.command(conn, ["LLEN", Keyspace.queue_key(q, "flow:outbox")])

      # TICK 1: the deliver loop fails n1 (n2's death delivered) AND -- the
      # RECURSIVE hop -- re-emits n1's death up to the root (n1 transitioned to
      # dead, carries its own parent). root is STILL held; outbox now n1 -> root.
      assert {:ok, 1} = Pump.deliver_flow_completions(conn, q, 100)
      assert {:ok, :dead} = Metrics.get_job_state(conn, q, n1)
      assert {:ok, %{^n2 => "boom"}} = hgetall(conn, Keyspace.job_key(q, n1) <> ":failed")
      assert {:ok, :awaiting_children} = Metrics.get_job_state(conn, q, root)
      assert {:ok, 1} = Connector.command(conn, ["LLEN", Keyspace.queue_key(q, "flow:outbox")])

      # TICK 2: the deliver loop fails the root (n1's death delivered). root has
      # no parent -> the recursion STOPS; outbox drains to empty.
      assert {:ok, 1} = Pump.deliver_flow_completions(conn, q, 100)
      assert {:ok, :dead} = Metrics.get_job_state(conn, q, root)
      assert {:ok, %{^n1 => "boom"}} = hgetall(conn, Keyspace.job_key(q, root) <> ":failed")
      assert {:ok, 0} = Connector.command(conn, ["LLEN", Keyspace.queue_key(q, "flow:outbox")])

      # TICK 3: a stable no-op (the recursion terminated -- no phantom re-emit)
      assert {:ok, 0} = Pump.deliver_flow_completions(conn, q, 100)
      assert {:ok, 1} = Connector.command(conn, ["HLEN", Keyspace.job_key(q, root) <> ":failed"])
    end

    test "CROSS-QUEUE fail_parent: the death propagates UP per sweep tick to the root", %{
      conn: conn,
      q: q
    } do
      nq = q <> ".n"
      gq = q <> ".g"
      root = BrandedId.generate!("JOB")
      node = BrandedId.generate!("JOB")
      gc = BrandedId.generate!("JOB")

      {:ok, {^root, [{^node, [{^gc, []}]}]}} =
        Flows.add(conn, q, %{
          parent: %{id: root, payload: "R"},
          children: [
            %{
              id: node,
              payload: "N",
              queue: nq,
              fail_parent_on_failure: true,
              children: [%{id: gc, payload: "G", queue: gq, fail_parent_on_failure: true}]
            }
          ]
        })

      # the grandchild dies in gq -> a fail-entry emitted to gq's outbox
      {:ok, {^gc, _, 1}} = Jobs.claim(conn, gq, 60_000)
      {:ok, :dead} = Jobs.retry(conn, gq, gc, 1, 10, 1, "boom-gc")
      assert {:ok, :awaiting_children} = Metrics.get_job_state(conn, nq, node)

      # the gq sweep fails the node on its slot AND (the deliver-loop hook)
      # re-emits the node's death into nq's outbox
      assert {:ok, 1} = Pump.deliver_flow_completions(conn, gq, 100)
      assert {:ok, :dead} = Metrics.get_job_state(conn, nq, node)
      assert {:ok, %{^gc => "boom-gc"}} = hgetall(conn, Keyspace.job_key(nq, node) <> ":failed")
      # the root is still held (the node's death is in nq's outbox)
      assert {:ok, :awaiting_children} = Metrics.get_job_state(conn, q, root)

      # the nq sweep delivers the node's death on the ROOT's slot -> root dead
      assert {:ok, 1} = Pump.deliver_flow_completions(conn, nq, 100)
      assert {:ok, :dead} = Metrics.get_job_state(conn, q, root)
      assert {:ok, %{^node => "boom-gc"}} = hgetall(conn, Keyspace.job_key(q, root) <> ":failed")
    end

    test "ignore_dependency_on_failure at the TOP hop: the root PROCEEDS (not failed)", %{
      conn: conn,
      q: q
    } do
      root = BrandedId.generate!("JOB")
      node = BrandedId.generate!("JOB")
      gc = BrandedId.generate!("JOB")

      {:ok, {^root, [{^node, [{^gc, []}]}]}} =
        Flows.add(conn, q, %{
          parent: %{id: root, payload: "R"},
          children: [
            %{
              id: node,
              payload: "N",
              # the node's policy toward the ROOT is ignore-on-failure
              ignore_dependency_on_failure: true,
              children: [%{id: gc, payload: "G", fail_parent_on_failure: true}]
            }
          ]
        })

      # the grandchild dies via the PRODUCTION path (retry/7) -> the node dies
      # (sq:fp) AND retry/7 re-emits the node's death UP into q's outbox (NO
      # hand-call -- the host hook fires inside retry/7).
      {:ok, {^gc, _, 1}} = Jobs.claim(conn, q, 60_000)
      {:ok, :dead} = Jobs.retry(conn, q, gc, 1, 10, 1, "boom")

      # the node's death is delivered to the root by the node's 'id' policy: the
      # root PROCEEDS (released to pending), the node in the root's :unsuccessful
      assert {:ok, 1} = Pump.deliver_flow_completions(conn, q, 100)
      assert {:ok, 0} = Flows.dependencies(conn, q, root)
      assert {:ok, :pending} = Metrics.get_job_state(conn, q, root)
      assert {:ok, %{^node => "boom"}} = Flows.ignored_failures(conn, q, root)
      # NOT in :failed (it proceeded, not failed)
      assert {:ok, %{}} = hgetall(conn, Keyspace.job_key(q, root) <> ":failed")
      assert {:ok, {^root, "R", 1}} = Jobs.claim(conn, q, 60_000)
    end

    test "a re-delivered node-death fails the root EXACTLY once (idempotent, INV7)", %{
      conn: conn,
      q: q
    } do
      nq = q <> ".n"
      gq = q <> ".g"
      root = BrandedId.generate!("JOB")
      node = BrandedId.generate!("JOB")
      gc = BrandedId.generate!("JOB")

      {:ok, {^root, [{^node, [{^gc, []}]}]}} =
        Flows.add(conn, q, %{
          parent: %{id: root, payload: "R"},
          children: [
            %{
              id: node,
              payload: "N",
              queue: nq,
              fail_parent_on_failure: true,
              children: [%{id: gc, payload: "G", queue: gq, fail_parent_on_failure: true}]
            }
          ]
        })

      {:ok, {^gc, _, 1}} = Jobs.claim(conn, gq, 60_000)
      {:ok, :dead} = Jobs.retry(conn, gq, gc, 1, 10, 1, "boom-gc")
      # the FIRST gq sweep fails the node AND (the deliver-loop hook) re-emits
      # the node's death into nq's outbox -- exactly ONE node-death entry queued
      {:ok, 1} = Pump.deliver_flow_completions(conn, gq, 100)
      assert {:ok, 1} = Connector.command(conn, ["LLEN", Keyspace.queue_key(nq, "flow:outbox")])

      # a SECOND gq sweep (a natural re-tick) must NOT re-emit: the node is
      # already dead (the parent->dead TRANSITION gate -- INV7), so the node's
      # death is NOT re-pushed and nq's outbox does NOT re-grow. (This is the
      # gate the host re-emit's idempotency rests on -- without it the outbox
      # grows unboundedly on every re-delivery.) The gq outbox is empty (the
      # first sweep LTRIM'd the delivered grandchild-death) so this is a clean
      # no-op tick over a now-dead node row.
      {:ok, _} =
        Connector.command(conn, [
          "RPUSH",
          Keyspace.queue_key(gq, "flow:outbox"),
          fail_entry(nq, node, gc, "boom-gc", "fp")
        ])

      {:ok, 1} = Pump.deliver_flow_completions(conn, gq, 100)
      # nq's outbox STILL holds exactly one node-death entry -- the re-delivery
      # of the grandchild's death found the node already dead and re-emitted
      # nothing (no phantom second hop)
      assert {:ok, 1} = Connector.command(conn, ["LLEN", Keyspace.queue_key(nq, "flow:outbox")])

      # now drain nq -> the root is failed
      {:ok, 1} = Pump.deliver_flow_completions(conn, nq, 100)
      assert {:ok, :dead} = Metrics.get_job_state(conn, q, root)

      # re-push the SAME node-death fail-entry the deliver-loop hook emits
      # (BYTE-FAITHFUL: the node is the "child", the root the parent, 'fp') and
      # re-drain -- the root's :failed HSETNX finds the node already recorded
      {:ok, _} =
        Connector.command(conn, [
          "RPUSH",
          Keyspace.queue_key(nq, "flow:outbox"),
          fail_entry(q, root, node, "boom-gc", "fp")
        ])

      {:ok, 1} = Pump.deliver_flow_completions(conn, nq, 100)
      # exactly one :failed entry for the node (failed exactly once)
      assert {:ok, 1} = Connector.command(conn, ["HLEN", Keyspace.job_key(q, root) <> ":failed"])
    end
  end

  # -- helpers ----------------------------------------------------------------

  # The cross-queue FAIL-entry as the producer (the @retry xq arm AND the
  # emq.3.5 host re-emit) writes it: a LEADING EMPTY field + the 'fail' tag +
  # parent_queue + parent_id + child_id + policy + error, NUL-joined (the error
  # LAST). BYTE-FAITHFUL to the producer (the emq.3.3 L-2 lesson).
  defp fail_entry(parent_queue, parent_id, child_id, error, policy) do
    Enum.join(["", "fail", parent_queue, parent_id, child_id, policy, error], <<0>>)
  end

  # HGETALL -> a %{field => value} map (RESP3 native or RESP2 flat-list).
  defp hgetall(conn, key) do
    case Connector.command(conn, ["HGETALL", key]) do
      {:ok, map} when is_map(map) -> {:ok, map}
      {:ok, flat} when is_list(flat) -> {:ok, flat |> Enum.chunk_every(2) |> Map.new(fn [k, v] -> {k, v} end)}
      other -> other
    end
  end

  # HMGET of [parent, parent_queue] -> normalize an absent parent_queue (a
  # same-queue node carries `parent` but NO `parent_queue` field) to "" so the
  # assertion reads a uniform shape.
  defp drop_nil_pq({:ok, [parent, nil]}), do: {:ok, [parent, ""]}
  defp drop_nil_pq(other), do: other

  defp purge(queues) do
    {:ok, conn} = Connector.start_link(port: 6390)

    Enum.each(queues, fn q ->
      {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
      if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    end)

    GenServer.stop(conn)
  end
end
