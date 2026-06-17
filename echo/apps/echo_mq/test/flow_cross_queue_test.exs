defmodule EchoMQ.FlowCrossQueueTest do
  @moduledoc """
  EMQ.3.3 -- the CROSS-QUEUE flow: a parent and its DIRECT children in
  DIFFERENT queues (the v1 flow shape -- a parent in `orders`, children in
  `validation`/`inventory`/`payments`). Under the braced keyspace each queue is
  a different cluster slot (`slot({P}) != slot({C})`), so a child's completion
  CANNOT atomically reach its parent's other-slot `:dependencies` -- no single
  Lua script spans two slots (S-1/§6). The decrement is delivered by the
  completion-signal hop (D-1..D-4):

    * the cross-queue ADD (D-2) is host-orchestrated, NON-atomic across slots,
      parent-first, fail-closed: the parent lands FIRST (held,
      `state = awaiting_children`, `:dependencies` = N), then each child on its
      own slot carrying `parent` + `parent_queue`;
    * the outbox EMIT (D-1/D-4) -- the cross-queue child's `@complete` RPUSHes
      the completion entry into its OWN-slot `emq:{C}:flow:outbox` ATOMICALLY
      with the active-set ZREM (one EVAL on {C}), so a completed cross-queue
      child ALWAYS has a durable signal (the drop window does not exist, INV7);
    * the sweep DELIVER (D-2/D-3) -- `EchoMQ.Pump.deliver_flow_completions/3`
      drains the outbox and, per entry, issues `@flow_deliver` on the PARENT's
      slot, recording the child in `:processed` via HSETNX and -- only on the
      first record -- DECRing `:dependencies` + at-zero releasing the parent.

  The cross-queue fan-in is EVENTUALLY-CONSISTENT (the parent releases on the
  sweep TICK, never synchronously -- INV5), AT-LEAST-ONCE made EFFECTIVELY-ONCE
  (a re-delivery finds the child already `:processed` -> no double-DECR --
  INV6). This is the mint/process-touching cross-queue suite -- it mints a
  parent + children ACROSS queues and fans in across slots -- so it runs under
  the >=100-iteration determinism loop owning the machine (one green run is NOT
  proof). Per-test sub-queues; Valkey 6390 the truth row.
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
    base = "emq33.fxq#{System.unique_integer([:positive])}"
    # the parent queue and a DIFFERENT child queue (a different hashtag)
    pq = base <> ".P"
    cq = base <> ".C"
    on_exit(fn -> purge([pq, cq]) end)
    %{conn: conn, pq: pq, cq: cq}
  end

  describe "the cross-queue add (emq.3.3-D2) -- host-orchestrated, parent-first, fail-closed" do
    test "the parent + child land on DIFFERENT slots (the forcing constraint)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      parent = BrandedId.generate!("JOB")
      child = BrandedId.generate!("JOB")

      # the whole reason emq.3.3 exists: the parent and the cross-queue child
      # are on DIFFERENT cluster slots, so no single Lua script spans them
      assert Keyspace.slot(Keyspace.job_key(pq, parent)) !=
               Keyspace.slot(Keyspace.job_key(cq, child))

      assert {:ok, {^parent, [^child]}} =
               Flows.add(conn, pq, %{
                 parent: %{id: parent, payload: "P"},
                 children: [%{id: child, payload: "c", queue: cq}]
               })
    end

    test "the parent lands HELD on its slot (awaiting_children, :dependencies = N)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      parent = BrandedId.generate!("JOB")
      c1 = BrandedId.generate!("JOB")
      c2 = BrandedId.generate!("JOB")

      {:ok, {^parent, [^c1, ^c2]}} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [%{id: c1, payload: "c1", queue: cq}, %{id: c2, payload: "c2", queue: cq}]
        })

      assert {:ok, "2"} ==
               Connector.command(conn, ["GET", Keyspace.job_key(pq, parent) <> ":dependencies"])

      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, parent)
      # the parent is NOT a pending member of its own queue
      assert {:ok, nil} ==
               Connector.command(conn, ["ZSCORE", Keyspace.queue_key(pq, "pending"), parent])
    end

    test "each cross-queue child lands claimable on ITS OWN slot carrying parent + parent_queue", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      parent = BrandedId.generate!("JOB")
      child = BrandedId.generate!("JOB")

      {:ok, _} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [%{id: child, payload: "c", queue: cq}]
        })

      # the child is claimable IN ITS OWN QUEUE, not the parent's
      assert :empty == Jobs.claim(conn, pq, 60_000)

      assert {:ok, [parent, pq]} ==
               Connector.command(conn, ["HMGET", Keyspace.job_key(cq, child), "parent", "parent_queue"])

      assert {:ok, {^child, "c", 1}} = Jobs.claim(conn, cq, 60_000)
    end

    test "a MIXED flow (a same-queue child + a cross-queue child) routes each by its queue", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      parent = BrandedId.generate!("JOB")
      same = BrandedId.generate!("JOB")
      cross = BrandedId.generate!("JOB")

      {:ok, {^parent, [^same, ^cross]}} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [%{id: same, payload: "s"}, %{id: cross, payload: "x", queue: cq}]
        })

      # :dependencies counts BOTH children
      assert {:ok, "2"} ==
               Connector.command(conn, ["GET", Keyspace.job_key(pq, parent) <> ":dependencies"])

      # the same-queue child is claimable in the parent's queue (no parent_queue field)
      assert {:ok, {^same, "s", 1}} = Jobs.claim(conn, pq, 60_000)
      assert {:ok, nil} == Connector.command(conn, ["HGET", Keyspace.job_key(pq, same), "parent_queue"])
      # the cross-queue child is claimable in its own queue
      assert {:ok, {^cross, "x", 1}} = Jobs.claim(conn, cq, 60_000)
    end

    test "an ill-formed child id raises at the gate BEFORE any wire (the parent unwritten)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      parent = BrandedId.generate!("JOB")

      assert_raise ArgumentError, fn ->
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [%{id: "not-a-branded-id", payload: "c", queue: cq}]
        })
      end

      assert {:ok, 0} == Connector.command(conn, ["EXISTS", Keyspace.job_key(pq, parent)])
    end

    test "a non-JOB cross-queue child refuses EMQKIND; the parent lands HELD (fail-closed)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      # parent-first means the parent is written before the child is attempted;
      # the child's kind refusal then leaves the parent HELD (never claimable),
      # host-retryable by id -- the honest non-atomic add (B2).
      parent = BrandedId.generate!("JOB")
      bad = BrandedId.generate!("ORD")

      assert {:error, :kind} =
               Flows.add(conn, pq, %{
                 parent: %{id: parent, payload: "P"},
                 children: [%{id: bad, payload: "c", queue: cq}]
               })

      # the parent is HELD (fail-closed): present, awaiting_children, NOT claimable
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, parent)
      assert :empty == Jobs.claim(conn, pq, 60_000)
    end
  end

  describe "the outbox emit (emq.3.3-D3, INV7) -- atomic with completion, no drop window" do
    test "a cross-queue child's completion RPUSHes one outbox entry AND leaves active (one EVAL)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      {parent, child} = add_one(conn, pq, cq)

      {:ok, {^child, "c", 1}} = Jobs.claim(conn, cq, 60_000)
      assert :ok == Jobs.complete(conn, cq, child, 1, "done")

      # both effects of the ONE EVAL: gone from active, present in the outbox
      assert {:ok, 0} == Connector.command(conn, ["ZCARD", Keyspace.queue_key(cq, "active")])
      assert {:ok, 1} == Connector.command(conn, ["LLEN", Keyspace.queue_key(cq, "flow:outbox")])

      # the entry encodes (parent_queue, parent_id, child_id, result)
      {:ok, [entry]} =
        Connector.command(conn, ["LRANGE", Keyspace.queue_key(cq, "flow:outbox"), "0", "-1"])

      assert :binary.split(entry, <<0>>, [:global]) == [pq, parent, child, "done"]

      # the parent is STILL held (the decrement is NOT applied at completion)
      assert {:ok, "1"} ==
               Connector.command(conn, ["GET", Keyspace.job_key(pq, parent) <> ":dependencies"])

      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, parent)
    end

    test "the child's own row is retired by its completion (DEL KEYS[2], the shared tail)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      {_parent, child} = add_one(conn, pq, cq)
      {:ok, {^child, _, 1}} = Jobs.claim(conn, cq, 60_000)
      :ok = Jobs.complete(conn, cq, child, 1, "r")
      assert {:ok, 0} == Connector.command(conn, ["EXISTS", Keyspace.job_key(cq, child)])
    end

    test "a stale-token completion of a cross-queue child emits NO phantom signal", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      {_parent, child} = add_one(conn, pq, cq)
      {:ok, {^child, _, 1}} = Jobs.claim(conn, cq, 60_000)

      # a wrong token is refused EMQSTALE and writes NOTHING to the outbox
      assert {:error, :stale} == Jobs.complete(conn, cq, child, 99, "x")
      assert {:ok, 0} == Connector.command(conn, ["LLEN", Keyspace.queue_key(cq, "flow:outbox")])
    end
  end

  describe "the sweep-deliver (emq.3.3-D4, INV5) -- eventually-consistent release on the parent's slot" do
    test "the parent is HELD until the sweep, then RELEASED (claimable, deps 0, pending)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      {parent, child} = add_one(conn, pq, cq)

      # complete the child -> emitted, but the parent is NOT yet released
      {:ok, {^child, _, 1}} = Jobs.claim(conn, cq, 60_000)
      :ok = Jobs.complete(conn, cq, child, 1, "r-" <> child)
      assert {:ok, 1} == Flows.dependencies(conn, pq, parent)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, parent)

      # run the CHILD queue's deliver pass: the decrement is applied on the
      # PARENT's slot, the parent released
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, 0} == Flows.dependencies(conn, pq, parent)
      assert {:ok, :pending} == Metrics.get_job_state(conn, pq, parent)
      assert {:ok, {^parent, "P", 1}} = Jobs.claim(conn, pq, 60_000)

      # the result is recorded in the parent's :processed (the cross-queue payload)
      assert {:ok, %{^child => result}} = Flows.children_values(conn, pq, parent)
      assert result == "r-" <> child

      # the outbox is drained empty (self-clearing in steady state -- B5)
      assert {:ok, 0} == Connector.command(conn, ["LLEN", Keyspace.queue_key(cq, "flow:outbox")])
    end

    test "a multi-child cross-queue flow releases the parent only at the LAST deliver", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      parent = BrandedId.generate!("JOB")
      c1 = BrandedId.generate!("JOB")
      c2 = BrandedId.generate!("JOB")

      {:ok, _} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [%{id: c1, payload: "c1", queue: cq}, %{id: c2, payload: "c2", queue: cq}]
        })

      # complete BOTH children in the child queue
      {:ok, {first, _, 1}} = Jobs.claim(conn, cq, 60_000)
      :ok = Jobs.complete(conn, cq, first, 1)
      {:ok, {second, _, 1}} = Jobs.claim(conn, cq, 60_000)
      :ok = Jobs.complete(conn, cq, second, 1)

      # one deliver pass drains BOTH entries -> deps 0, parent released
      assert {:ok, 2} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, 0} == Flows.dependencies(conn, pq, parent)
      assert {:ok, :pending} == Metrics.get_job_state(conn, pq, parent)
    end

    test "Pump.sweep/1's third pass delivers (the return grows to %{..., delivered})", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      {parent, child} = add_one(conn, pq, cq)
      {:ok, {^child, _, 1}} = Jobs.claim(conn, cq, 60_000)
      :ok = Jobs.complete(conn, cq, child, 1)

      # drive the full sweep on the CHILD queue (promote + repeats + deliver)
      assert {:ok, %{promoted: _, fired: _, delivered: 1}} =
               Pump.sweep(%{conn: conn, queue: cq, batch: 100})

      assert {:ok, :pending} == Metrics.get_job_state(conn, pq, parent)
    end

    test "an empty outbox delivers nothing (delivered: 0)", %{conn: conn, pq: _pq, cq: cq} do
      assert {:ok, 0} == Pump.deliver_flow_completions(conn, cq, 100)
    end
  end

  describe "idempotent delivery (emq.3.3-D3/INV6) -- at-least-once made effectively-once" do
    test "a re-delivered completion does NOT double-DECR (the :processed HSETNX guard)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      parent = BrandedId.generate!("JOB")
      c1 = BrandedId.generate!("JOB")
      c2 = BrandedId.generate!("JOB")

      {:ok, _} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [%{id: c1, payload: "c1", queue: cq}, %{id: c2, payload: "c2", queue: cq}]
        })

      # complete + deliver ONLY the first child -> deps 1
      {:ok, {first, _, 1}} = Jobs.claim(conn, cq, 60_000)
      :ok = Jobs.complete(conn, cq, first, 1, "r-" <> first)
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, 1} == Flows.dependencies(conn, pq, parent)

      # RE-PUSH the SAME entry and re-deliver (a sweep crash after DECR, before
      # LTRIM): HSETNX finds first already :processed -> NO second DECR. The
      # entry's FIRST field is the PARENT queue (pq) -- exactly what @complete
      # emits -- so the deliver rebuilds the REAL parent's keys on the PARENT's
      # slot and the HSETNX guard actually fires (returns 0 for the already-
      # recorded child).
      entry = pq <> <<0>> <> parent <> <<0>> <> first <> <<0>> <> ("r-" <> first)
      {:ok, _} = Connector.command(conn, ["RPUSH", Keyspace.queue_key(cq, "flow:outbox"), entry])
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)

      # deps STILL 1 -- decremented exactly once, the parent still held
      assert {:ok, 1} == Flows.dependencies(conn, pq, parent)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, parent)
    end

    test "re-delivering the FINAL child does not release the parent twice", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      {parent, child} = add_one(conn, pq, cq)
      {:ok, {^child, _, 1}} = Jobs.claim(conn, cq, 60_000)
      :ok = Jobs.complete(conn, cq, child, 1, "r")
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, 0} == Flows.dependencies(conn, pq, parent)

      # claim the released parent (it is pending now)
      assert {:ok, {^parent, "P", 1}} = Jobs.claim(conn, pq, 60_000)

      # re-deliver the same child -> a no-op (HSETNX 0); the parent is NOT
      # re-added to pending while it is in flight. The entry's FIRST field is the
      # PARENT queue (pq) -- what @complete emits -- so the deliver targets the
      # REAL parent's slot and the guard fires (the child is already :processed).
      entry = pq <> <<0>> <> parent <> <<0>> <> child <> <<0>> <> "r"
      {:ok, _} = Connector.command(conn, ["RPUSH", Keyspace.queue_key(cq, "flow:outbox"), entry])
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, 0} == Flows.dependencies(conn, pq, parent)
      # the parent is not back in pending (it was claimed, deps already 0)
      assert {:ok, nil} ==
               Connector.command(conn, ["ZSCORE", Keyspace.queue_key(pq, "pending"), parent])
    end
  end

  describe "the entry encoding -- a result may contain any byte (the result is the last field)" do
    test "a cross-queue result containing a NUL byte still delivers intact", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      {parent, child} = add_one(conn, pq, cq)
      {:ok, {^child, _, 1}} = Jobs.claim(conn, cq, 60_000)
      # a result with an embedded NUL -- the split peels only the first three
      # boundaries, so the result remainder keeps the NUL
      :ok = Jobs.complete(conn, cq, child, 1, "left\0right")
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, %{^child => "left\0right"}} = Flows.children_values(conn, pq, parent)
      assert {:ok, 0} == Flows.dependencies(conn, pq, parent)
    end
  end

  describe "the deliver is non-destructive until success (the drain-order, no-drop)" do
    test "a deliver leaves the outbox drained only AFTER the decrement is applied", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      {parent, child} = add_one(conn, pq, cq)
      {:ok, {^child, _, 1}} = Jobs.claim(conn, cq, 60_000)
      :ok = Jobs.complete(conn, cq, child, 1, "r")

      # one entry present pre-deliver
      assert {:ok, 1} == Connector.command(conn, ["LLEN", Keyspace.queue_key(cq, "flow:outbox")])
      # deliver -> applied AND removed (LTRIM only the delivered prefix)
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, 0} == Connector.command(conn, ["LLEN", Keyspace.queue_key(cq, "flow:outbox")])
      assert {:ok, 0} == Flows.dependencies(conn, pq, parent)
    end
  end

  describe "emq.3.3-R2 hardening -- multi-queue fan-in, the grandchildren-OUT boundary, the crash-before-LTRIM redeliver" do
    test "a parent + 3 children in 3 DISTINCT queues releases ONLY after all 3 deliver", %{
      conn: conn,
      pq: pq
    } do
      # the v1 flow shape at width: a parent in `orders`, children in three
      # DIFFERENT queues (validation/inventory/payments) -- each on its OWN
      # cluster slot, each with its OWN outbox, each swept independently. The
      # parent (deps = 3) releases only when the THIRD child's deliver drives
      # :dependencies to zero -- not on the first, not on the second.
      base = "emq33.fxq3#{System.unique_integer([:positive])}"
      cqs = [base <> ".A", base <> ".B", base <> ".C"]
      on_exit(fn -> purge(cqs) end)

      parent = BrandedId.generate!("JOB")
      kids = Enum.map(cqs, fn _ -> BrandedId.generate!("JOB") end)

      children =
        Enum.zip(kids, cqs)
        |> Enum.map(fn {id, q} -> %{id: id, payload: "leg", queue: q} end)

      {:ok, {^parent, ^kids}} =
        Flows.add(conn, pq, %{parent: %{id: parent, payload: "P"}, children: children})

      # the three child queues are three DISTINCT slots (the forcing constraint
      # holds across all of them, not just one)
      slots = Enum.map(Enum.zip(kids, cqs), fn {id, q} -> Keyspace.slot(Keyspace.job_key(q, id)) end)
      assert length(Enum.uniq([Keyspace.slot(Keyspace.job_key(pq, parent)) | slots])) == 4

      assert {:ok, 3} == Flows.dependencies(conn, pq, parent)

      # complete each child IN ITS OWN QUEUE, then sweep THAT queue's deliver
      # pass; assert the parent stays held until the LAST sweep.
      [d1, d2, d3] =
        Enum.map(Enum.zip(kids, cqs), fn {kid, q} ->
          {:ok, {^kid, "leg", 1}} = Jobs.claim(conn, q, 60_000)
          :ok = Jobs.complete(conn, q, kid, 1, "r-" <> kid)
          # each child queue drains ONLY its own outbox (one entry each)
          {:ok, delivered} = Pump.deliver_flow_completions(conn, q, 100)
          {delivered, Flows.dependencies(conn, pq, parent), Metrics.get_job_state(conn, pq, parent)}
        end)

      # each sweep delivered exactly its own one entry
      assert {1, {:ok, 2}, {:ok, :awaiting_children}} == d1
      assert {1, {:ok, 1}, {:ok, :awaiting_children}} == d2
      # only the THIRD sweep drives deps to 0 and releases the parent
      assert {1, {:ok, 0}, {:ok, :pending}} == d3

      assert {:ok, {^parent, "P", 1}} = Jobs.claim(conn, pq, 60_000)
      # all three legs' results fanned in (the cross-queue payload, keyed by child)
      {:ok, values} = Flows.children_values(conn, pq, parent)
      assert Map.keys(values) |> Enum.sort() == Enum.sort(kids)
      assert Enum.all?(kids, fn kid -> values[kid] == "r-" <> kid end)
    end

    test "a cross-queue child is a LEAF -- emq.3.3 attempts no grandchild recursion (D-5a, OUT)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      # emq.3.3 is FLAT: a parent + its DIRECT cross-queue children. A child is a
      # LEAF -- it carries `parent`/`parent_queue` but is NOT itself held with a
      # :dependencies counter, and its completion fans in to ITS parent only (no
      # descent into a grandchild). Grandchildren / deep recursion are emq.3.4,
      # OUT. This asserts the boundary HOLDS: the leaf has no own dependency
      # state, the parent is the only held node, and the flat fan-in completes
      # without any recursion having been attempted.
      {parent, child} = add_one(conn, pq, cq)

      # the leaf child is NOT a flow-parent: it has no :dependencies / :processed
      # subkey of its own on its slot (those exist only for a held parent)
      assert {:ok, 0} == Connector.command(conn, ["EXISTS", Keyspace.job_key(cq, child) <> ":dependencies"])
      assert {:ok, 0} == Connector.command(conn, ["EXISTS", Keyspace.job_key(cq, child) <> ":processed"])
      # the leaf is claimable pending (a worker job), NOT awaiting_children
      assert {:ok, :pending} == Metrics.get_job_state(conn, cq, child)

      # the PARENT is the single held node (the one parent level)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, parent)

      # completing the leaf fans in to its parent and STOPS -- no grandchild
      # outbox is written on the child's slot (the deliver targets the parent's
      # :processed, never a descendant)
      {:ok, {^child, _, 1}} = Jobs.claim(conn, cq, 60_000)
      :ok = Jobs.complete(conn, cq, child, 1, "leaf-done")
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, 0} == Flows.dependencies(conn, pq, parent)
      assert {:ok, :pending} == Metrics.get_job_state(conn, pq, parent)
      # the parent now has a :processed entry for the leaf, and the parent
      # itself is NOT a child of any grandparent (no parent field on its row)
      assert {:ok, %{^child => "leaf-done"}} = Flows.children_values(conn, pq, parent)
      assert {:ok, nil} == Connector.command(conn, ["HGET", Keyspace.job_key(pq, parent), "parent"])
    end

    test "a crash AFTER @flow_deliver but BEFORE the LTRIM re-delivers idempotently (no double-DECR)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      # the exact crash window D-3 closes: the sweep applied @flow_deliver on the
      # parent's slot (HSETNX recorded the child, DECR fired) but crashed BEFORE
      # the outbox LTRIM, so the SAME entry is still at the head and re-drains
      # next tick. Simulate it precisely on a 3-child flow: complete + deliver
      # the first child (deps 3 -> 2, the entry LTRIM'd), then RE-INJECT the
      # identical entry (the crash survivor the LTRIM never reached) and re-drain
      # -- HSETNX finds the child already :processed (returns 0), DECRs NOTHING,
      # the survivor is consumed, deps STAYS 2. The DECR fired exactly once for
      # that child across the two deliveries.
      parent = BrandedId.generate!("JOB")
      kids = Enum.map(1..3, fn _ -> BrandedId.generate!("JOB") end)

      {:ok, _} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: Enum.map(kids, fn id -> %{id: id, payload: "c", queue: cq} end)
        })

      assert {:ok, 3} == Flows.dependencies(conn, pq, parent)

      # complete + deliver the FIRST child only -> deps 3 -> 2
      {:ok, {first, _, 1}} = Jobs.claim(conn, cq, 60_000)
      :ok = Jobs.complete(conn, cq, first, 1, "r-" <> first)
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, 2} == Flows.dependencies(conn, pq, parent)

      # the crash survivor: the SAME delivered entry, never LTRIM'd, re-injected.
      # The entry's FIRST field is the PARENT queue (pq) -- exactly what
      # @complete emits (parent_queue, parent_id, child_id, result), so the
      # deliver rebuilds the parent's keys on the PARENT's slot. Re-drain: a
      # no-op DECR-wise (HSETNX 0), the survivor consumed.
      survivor = pq <> <<0>> <> parent <> <<0>> <> first <> <<0>> <> ("r-" <> first)
      {:ok, _} = Connector.command(conn, ["RPUSH", Keyspace.queue_key(cq, "flow:outbox"), survivor])
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)
      # deps STILL 2 -- the redelivered child decremented EXACTLY once total
      assert {:ok, 2} == Flows.dependencies(conn, pq, parent)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, parent)
      assert {:ok, 0} == Connector.command(conn, ["LLEN", Keyspace.queue_key(cq, "flow:outbox")])

      # the remaining two children complete; one sweep drains BOTH their entries
      # -> deps 0, parent released EXACTLY once (the redeliver never under-counted,
      # so the final DECR-to-zero is reached, not overshot).
      remaining = Enum.reject(kids, &(&1 == first))

      Enum.each(remaining, fn _ ->
        {:ok, {kid, _, 1}} = Jobs.claim(conn, cq, 60_000)
        :ok = Jobs.complete(conn, cq, kid, 1, "r-" <> kid)
      end)

      assert {:ok, 2} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, 0} == Flows.dependencies(conn, pq, parent)
      assert {:ok, :pending} == Metrics.get_job_state(conn, pq, parent)
      assert {:ok, {^parent, "P", 1}} = Jobs.claim(conn, pq, 60_000)
      # all three legs recorded exactly once (3 distinct :processed entries)
      {:ok, values} = Flows.children_values(conn, pq, parent)
      assert map_size(values) == 3
    end
  end

  # -- helpers --------------------------------------------------------------

  # Add a 1-child cross-queue flow (parent in pq, child in cq); return
  # {parent_id, child_id}.
  defp add_one(conn, pq, cq) do
    parent = BrandedId.generate!("JOB")
    child = BrandedId.generate!("JOB")

    {:ok, {^parent, [^child]}} =
      Flows.add(conn, pq, %{
        parent: %{id: parent, payload: "P"},
        children: [%{id: child, payload: "c", queue: cq}]
      })

    {parent, child}
  end

  defp purge(queues) do
    {:ok, conn} = Connector.start_link(port: 6390)

    Enum.each(queues, fn q ->
      {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
      if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    end)

    GenServer.stop(conn)
  end
end
