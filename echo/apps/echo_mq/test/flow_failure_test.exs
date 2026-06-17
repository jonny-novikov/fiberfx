defmodule EchoMQ.FlowFailureTest do
  @moduledoc """
  EMQ.3.4 -- the flow family's FAILURE half + bulk add. Today (emq.3.1-3.3) a
  flow parent is released ONLY when a child COMPLETES; a child that DIES
  (`@retry`'s dead-letter arm) never touches the parent, so the parent hangs in
  `awaiting_children` forever. emq.3.4 closes that gap with the v1 failure
  policies over the §6-reserved `:failed`/`:unsuccessful` subkeys:

    * `fail_parent_on_failure` (the v1 default) -- a dead child FAILS the parent
      (records `:failed`, moves the parent to `dead`);
    * `ignore_dependency_on_failure` -- a dead child SATISFIES the dependency
      (DECRs `:dependencies`, records `:unsuccessful`), the parent PROCEEDS;

  routed by an ADDITIVE branch in the shipped `@retry`'s dead-letter arm (the
  existing morgue body BYTE-FROZEN -- the branch fires only on host-supplied
  parent-fail keys / a fail marker the shipped callers never pass). A SAME-QUEUE
  child's death is ATOMIC (one EVAL, one slot -- the parent shares the dead
  child's slot {C}); a CROSS-QUEUE child's death EMITS a fail-entry into the
  child's own-slot `flow:outbox` atomically with the morgue transition (no drop
  window) and the sweep's `@flow_fail_deliver` applies it on the parent's slot
  {P} (eventually-consistent, idempotent by the `:failed`/`:unsuccessful` HSETNX
  guard).

  This mints a parent + children ACROSS queues and routes failure across slots,
  so it is a mint/process-touching suite -- run under the >=100-iteration
  determinism loop owning the machine (one green run is NOT proof; the same-ms
  mint collision flakes only across runs). Per-test sub-queues; Valkey 6390 the
  truth row.
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
    base = "emq34.ff#{System.unique_integer([:positive])}"
    pq = base <> ".P"
    cq = base <> ".C"
    on_exit(fn -> purge([pq, cq]) end)
    %{conn: conn, pq: pq, cq: cq}
  end

  # -- the policy on the add (emq.3.4-D2) -----------------------------------

  describe "the failure-policy options on add/3 (emq.3.4-D2)" do
    test "a cross-queue child's row carries parent_policy ('fp' default, 'id' opt-in)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      parent = BrandedId.generate!("JOB")
      def_child = BrandedId.generate!("JOB")
      ign_child = BrandedId.generate!("JOB")

      {:ok, _} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [
            # no flag -> default fail_parent_on_failure -> 'fp'
            %{id: def_child, payload: "d", queue: cq},
            # ignore_dependency_on_failure -> 'id'
            %{id: ign_child, payload: "i", queue: cq, ignore_dependency_on_failure: true}
          ]
        })

      assert {:ok, "fp"} ==
               Connector.command(conn, ["HGET", Keyspace.job_key(cq, def_child), "parent_policy"])

      assert {:ok, "id"} ==
               Connector.command(conn, ["HGET", Keyspace.job_key(cq, ign_child), "parent_policy"])
    end

    test "a same-queue child's row also carries parent_policy (host-written, @enqueue_flow frozen)", %{
      conn: conn,
      pq: pq
    } do
      parent = BrandedId.generate!("JOB")
      def_child = BrandedId.generate!("JOB")
      ign_child = BrandedId.generate!("JOB")

      {:ok, _} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [
            %{id: def_child, payload: "d"},
            %{id: ign_child, payload: "i", ignore_dependency_on_failure: true}
          ]
        })

      assert {:ok, "fp"} ==
               Connector.command(conn, ["HGET", Keyspace.job_key(pq, def_child), "parent_policy"])

      assert {:ok, "id"} ==
               Connector.command(conn, ["HGET", Keyspace.job_key(pq, ign_child), "parent_policy"])
    end

    test "an explicit fail_parent_on_failure: false WITHOUT ignore_dependency is still 'fp'", %{
      conn: conn,
      pq: pq
    } do
      # the policy token is driven by ignore_dependency_on_failure (the explicit
      # proceed opt-in); fail_parent_on_failure: false alone (without the ignore
      # opt-in) is NOT the proceed policy -- it resolves to the default 'fp'.
      parent = BrandedId.generate!("JOB")
      child = BrandedId.generate!("JOB")

      {:ok, _} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [%{id: child, payload: "c", fail_parent_on_failure: false}]
        })

      assert {:ok, "fp"} ==
               Connector.command(conn, ["HGET", Keyspace.job_key(pq, child), "parent_policy"])
    end
  end

  # -- same-queue fail_parent_on_failure (atomic) ---------------------------

  describe "same-queue fail_parent_on_failure (emq.3.4-D3, INV5) -- atomic, one EVAL" do
    test "a same-queue child's death fails the parent atomically (parent dead, child in :failed)", %{
      conn: conn,
      pq: pq
    } do
      parent = BrandedId.generate!("JOB")
      child = BrandedId.generate!("JOB")

      {:ok, {^parent, [^child]}} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [%{id: child, payload: "c"}]
        })

      {:ok, {^child, _, 1}} = Jobs.claim(conn, pq, 60_000)
      # one attempt, max 1 -> dead-letters; the SAME EVAL fails the parent
      assert {:ok, :dead} == Jobs.retry(conn, pq, child, 1, 10, 1, "boom")

      # the parent is DEAD with the child recorded in :failed -> its error
      assert {:ok, :dead} == Metrics.get_job_state(conn, pq, parent)
      # the parent ROW's state field is 'dead' too (the set membership AND the
      # row field both pin the morgue transition -- a mutation of either is caught)
      assert {:ok, "dead"} ==
               Connector.command(conn, ["HGET", Keyspace.job_key(pq, parent), "state"])

      assert {:ok, "boom"} ==
               Connector.command(conn, ["HGET", Keyspace.job_key(pq, parent) <> ":failed", child])

      # the parent is in the dead set, NOT in pending, NOT awaiting_children
      {:ok, dead_score} =
        Connector.command(conn, ["ZSCORE", Keyspace.queue_key(pq, "dead"), parent])

      refute is_nil(dead_score)

      assert {:ok, nil} ==
               Connector.command(conn, ["ZSCORE", Keyspace.queue_key(pq, "pending"), parent])

      # the parent is NOT claimable (it is dead, not pending)
      assert :empty == Jobs.claim(conn, pq, 60_000)
    end

    test "a sibling completing does NOT release a parent already failed by a dead child", %{
      conn: conn,
      pq: pq
    } do
      # fail_parent (default) on both children: the first child dies -> the
      # parent is dead. The second child completing then runs the @complete
      # fan-in, which decrements :dependencies, but the parent is already dead --
      # it is not resurrected to pending (the dead row stays dead).
      parent = BrandedId.generate!("JOB")
      c1 = BrandedId.generate!("JOB")
      c2 = BrandedId.generate!("JOB")

      {:ok, {^parent, [^c1, ^c2]}} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [%{id: c1, payload: "c1"}, %{id: c2, payload: "c2"}]
        })

      # kill the first child -> the parent is dead
      {:ok, {first, _, 1}} = Jobs.claim(conn, pq, 60_000)
      {:ok, :dead} = Jobs.retry(conn, pq, first, 1, 10, 1, "boom")
      assert {:ok, :dead} == Metrics.get_job_state(conn, pq, parent)

      # complete the second child: the fan-in DECRs deps, but the parent stays dead
      {:ok, {second, _, stok}} = Jobs.claim(conn, pq, 60_000)
      :ok = Jobs.complete(conn, pq, second, stok, "ok")
      assert {:ok, :dead} == Metrics.get_job_state(conn, pq, parent)
      # the parent is NOT a pending member (a dead-then-released bug would add it)
      assert {:ok, nil} ==
               Connector.command(conn, ["ZSCORE", Keyspace.queue_key(pq, "pending"), parent])
    end
  end

  # -- same-queue ignore_dependency_on_failure (atomic, proceed) ------------

  describe "same-queue ignore_dependency_on_failure (emq.3.4-D3, INV6) -- satisfy-and-record" do
    test "an ignored child's death decrements deps + records :unsuccessful; the parent proceeds", %{
      conn: conn,
      pq: pq
    } do
      parent = BrandedId.generate!("JOB")
      ignored = BrandedId.generate!("JOB")
      good = BrandedId.generate!("JOB")

      {:ok, {^parent, [^ignored, ^good]}} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [
            %{id: ignored, payload: "i", ignore_dependency_on_failure: true},
            %{id: good, payload: "g"}
          ]
        })

      # the ignored child dies -> deps 2 -> 1, recorded in :unsuccessful, the
      # parent NOT failed (still awaiting the good child)
      {:ok, {^ignored, _, 1}} = Jobs.claim(conn, pq, 60_000)
      {:ok, :dead} = Jobs.retry(conn, pq, ignored, 1, 10, 1, "skip-me")
      assert {:ok, 1} == Flows.dependencies(conn, pq, parent)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, parent)

      assert {:ok, "skip-me"} ==
               Connector.command(conn, [
                 "HGET",
                 Keyspace.job_key(pq, parent) <> ":unsuccessful",
                 ignored
               ])

      # the good child completes -> deps 0, the parent RELEASED to pending
      {:ok, {^good, _, gtok}} = Jobs.claim(conn, pq, 60_000)
      :ok = Jobs.complete(conn, pq, good, gtok, "g-done")
      assert {:ok, 0} == Flows.dependencies(conn, pq, parent)
      assert {:ok, :pending} == Metrics.get_job_state(conn, pq, parent)
      assert {:ok, {^parent, "P", 1}} = Jobs.claim(conn, pq, 60_000)
    end

    test "the ignored child is in :unsuccessful XOR :processed (the disjoint reads, B4)", %{
      conn: conn,
      pq: pq
    } do
      parent = BrandedId.generate!("JOB")
      ignored = BrandedId.generate!("JOB")
      good = BrandedId.generate!("JOB")

      {:ok, _} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [
            %{id: ignored, payload: "i", ignore_dependency_on_failure: true},
            %{id: good, payload: "g"}
          ]
        })

      {:ok, {^ignored, _, 1}} = Jobs.claim(conn, pq, 60_000)
      {:ok, :dead} = Jobs.retry(conn, pq, ignored, 1, 10, 1, "skip-me")
      {:ok, {^good, _, gtok}} = Jobs.claim(conn, pq, 60_000)
      :ok = Jobs.complete(conn, pq, good, gtok, "g-done")

      # ignored_failures reads the ignored child; children_values excludes it
      assert {:ok, %{^ignored => "skip-me"}} = Flows.ignored_failures(conn, pq, parent)
      assert {:ok, %{^good => "g-done"}} = Flows.children_values(conn, pq, parent)
      {:ok, ign} = Flows.ignored_failures(conn, pq, parent)
      {:ok, done} = Flows.children_values(conn, pq, parent)
      # disjoint by construction: no child id appears in both reads
      assert MapSet.disjoint?(MapSet.new(Map.keys(ign)), MapSet.new(Map.keys(done)))
      # the ignored child is NOT in :processed (it produced no result)
      refute Map.has_key?(done, ignored)
    end
  end

  # -- cross-queue fail (eventually-consistent, durable, idempotent) --------

  describe "cross-queue fail_parent_on_failure (emq.3.4-D4, INV5/INV8) -- emit + sweep-deliver" do
    test "a cross-queue child's death emits ONE fail-entry AND morgues the child (one EVAL)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      {parent, child} = add_cross(conn, pq, cq, fail_parent: true)
      outbox = Keyspace.queue_key(cq, "flow:outbox")

      {:ok, {^child, _, 1}} = Jobs.claim(conn, cq, 60_000)
      assert {:ok, :dead} == Jobs.retry(conn, cq, child, 1, 10, 1, "boom-xq")

      # both effects of the ONE EVAL on {C}, BEFORE any sweep: the child in its
      # own morgue, one fail-entry in the outbox (no drop window -- INV8)
      assert {:ok, :dead} == Metrics.get_job_state(conn, cq, child)
      assert {:ok, 1} == Connector.command(conn, ["LLEN", outbox])

      # the fail-entry is exactly what @retry's xq:fp arm emits (policy before
      # error; error LAST, the remainder -- the complete-entry's result-last design):
      # '' \0 'fail' \0 parent_queue \0 parent_id \0 child_id \0 'fp' \0 error
      {:ok, [entry]} = Connector.command(conn, ["LRANGE", outbox, "0", "-1"])

      assert :binary.split(entry, <<0>>, [:global]) == [
               "",
               "fail",
               pq,
               parent,
               child,
               "fp",
               "boom-xq"
             ]

      # the parent is STILL held pre-sweep (eventually-consistent -- INV5)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, parent)
      assert {:ok, 1} == Flows.dependencies(conn, pq, parent)
    end

    test "the sweep delivers the fail on the parent's slot (parent dead, child in :failed)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      {parent, child} = add_cross(conn, pq, cq, fail_parent: true)
      {:ok, {^child, _, 1}} = Jobs.claim(conn, cq, 60_000)
      {:ok, :dead} = Jobs.retry(conn, cq, child, 1, 10, 1, "boom-xq")

      # run the child queue's deliver pass -> the parent fails on {P}
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, :dead} == Metrics.get_job_state(conn, pq, parent)

      assert {:ok, "boom-xq"} ==
               Connector.command(conn, ["HGET", Keyspace.job_key(pq, parent) <> ":failed", child])

      # the outbox is drained empty
      assert {:ok, 0} == Connector.command(conn, ["LLEN", Keyspace.queue_key(cq, "flow:outbox")])
    end

    test "a re-delivered fail fails the parent EXACTLY once (the :failed HSETNX guard, INV7)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      {parent, child} = add_cross(conn, pq, cq, fail_parent: true)
      {:ok, {^child, _, 1}} = Jobs.claim(conn, cq, 60_000)
      {:ok, :dead} = Jobs.retry(conn, cq, child, 1, 10, 1, "boom-xq")
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, :dead} == Metrics.get_job_state(conn, pq, parent)

      # re-inject the SAME fail-entry @retry emits (a sweep crash AFTER apply,
      # BEFORE LTRIM) -- BYTE-FAITHFUL to the producer, so the deliver targets
      # the REAL parent's slot and the HSETNX guard fires (child already in
      # :failed -> 0 -> no second fail). The :failed HASH stays a single entry.
      entry = fail_entry(pq, parent, child, "boom-xq", "fp")
      {:ok, _} = Connector.command(conn, ["RPUSH", Keyspace.queue_key(cq, "flow:outbox"), entry])
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)

      assert {:ok, :dead} == Metrics.get_job_state(conn, pq, parent)

      assert {:ok, 1} ==
               Connector.command(conn, ["HLEN", Keyspace.job_key(pq, parent) <> ":failed"])
    end

    test "a cross-queue child dies but the parent is UNCHANGED before the sweep (INV5)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      {parent, child} = add_cross(conn, pq, cq, fail_parent: true)
      {:ok, {^child, _, 1}} = Jobs.claim(conn, cq, 60_000)
      {:ok, :dead} = Jobs.retry(conn, cq, child, 1, 10, 1, "boom-xq")

      # NO sweep yet: the parent is unchanged (awaiting_children, deps 1, not in :failed)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, parent)
      assert {:ok, 1} == Flows.dependencies(conn, pq, parent)
      assert {:ok, %{}} == hgetall(conn, Keyspace.job_key(pq, parent) <> ":failed")
    end
  end

  describe "cross-queue ignore_dependency_on_failure (emq.3.4-D4, INV6) -- proceed via the sweep" do
    test "a cross-queue ignored child's death decrements the parent on the sweep tick", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      # a parent with 2 cross-queue children: one ignore_dependency (dies), one
      # default (completes). The ignored death is delivered via the sweep ->
      # deps DECR + :unsuccessful; the completion DECRs to zero -> released.
      parent = BrandedId.generate!("JOB")
      ignored = BrandedId.generate!("JOB")
      good = BrandedId.generate!("JOB")

      {:ok, _} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [
            %{id: ignored, payload: "i", queue: cq, ignore_dependency_on_failure: true},
            %{id: good, payload: "g", queue: cq}
          ]
        })

      assert {:ok, 2} == Flows.dependencies(conn, pq, parent)

      # the ignored child dies in cq; before the sweep, the parent is unchanged
      {:ok, {^ignored, _, 1}} = Jobs.claim(conn, cq, 60_000)
      {:ok, :dead} = Jobs.retry(conn, cq, ignored, 1, 10, 1, "skip-xq")
      assert {:ok, 2} == Flows.dependencies(conn, pq, parent)

      # the good child completes in cq (emits a complete-entry)
      {:ok, {^good, _, gtok}} = Jobs.claim(conn, cq, 60_000)
      :ok = Jobs.complete(conn, cq, good, gtok, "g-done")

      # one sweep drains BOTH entries (a fail-entry + a complete-entry): the
      # ignored DECRs + records :unsuccessful, the completion DECRs to zero ->
      # the parent is released
      assert {:ok, 2} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, 0} == Flows.dependencies(conn, pq, parent)
      assert {:ok, :pending} == Metrics.get_job_state(conn, pq, parent)

      # the ignored child is in :unsuccessful, the good child in :processed
      assert {:ok, %{^ignored => "skip-xq"}} = Flows.ignored_failures(conn, pq, parent)
      assert {:ok, %{^good => "g-done"}} = Flows.children_values(conn, pq, parent)
    end

    test "a re-delivered cross-queue ignore-fail does NOT double-DECR (INV7)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      # a parent with 2 cross-queue ignore children: kill one + deliver -> deps 1.
      # Re-inject that fail-entry (the crash survivor) -> the :unsuccessful HSETNX
      # finds it recorded -> NO second DECR (deps stays 1).
      parent = BrandedId.generate!("JOB")
      i1 = BrandedId.generate!("JOB")
      i2 = BrandedId.generate!("JOB")

      {:ok, _} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [
            %{id: i1, payload: "i1", queue: cq, ignore_dependency_on_failure: true},
            %{id: i2, payload: "i2", queue: cq, ignore_dependency_on_failure: true}
          ]
        })

      {:ok, {first, _, 1}} = Jobs.claim(conn, cq, 60_000)
      {:ok, :dead} = Jobs.retry(conn, cq, first, 1, 10, 1, "skip-1")
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, 1} == Flows.dependencies(conn, pq, parent)

      # the crash survivor: the SAME fail-entry, re-injected and re-drained
      survivor = fail_entry(pq, parent, first, "skip-1", "id")

      {:ok, _} =
        Connector.command(conn, ["RPUSH", Keyspace.queue_key(cq, "flow:outbox"), survivor])

      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)

      # deps STILL 1 -- decremented exactly once; the :unsuccessful HASH a single entry
      assert {:ok, 1} == Flows.dependencies(conn, pq, parent)

      assert {:ok, 1} ==
               Connector.command(conn, ["HLEN", Keyspace.job_key(pq, parent) <> ":unsuccessful"])

      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, parent)
    end
  end

  # -- the @retry byte-freeze on a non-flow job (INV1/INV3) -----------------

  describe "the failure branch is unreached for a non-flow job (INV1/INV3)" do
    test "a non-flow job dead-letters exactly as shipped (no parent touch, no fail-entry)", %{
      conn: conn,
      pq: pq
    } do
      # a plain (non-flow) job: no `parent` field, so retry/7 appends neither the
      # parent keys nor the fail marker -> the @retry failure branch is unreached.
      # The job dead-letters with last_error kept, browsable in the morgue --
      # the byte-frozen emq.1 behavior.
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, pq, id, "w")
      {:ok, {^id, _, 1}} = Jobs.claim(conn, pq, 60_000)
      assert {:ok, :dead} == Jobs.retry(conn, pq, id, 1, 10, 1, "gave up")

      assert {:ok, "dead"} == Connector.command(conn, ["HGET", Keyspace.job_key(pq, id), "state"])

      assert {:ok, "gave up"} ==
               Connector.command(conn, ["HGET", Keyspace.job_key(pq, id), "last_error"])

      assert {:ok, [id]} ==
               Connector.command(conn, [
                 "ZRANGE",
                 Keyspace.queue_key(pq, "dead"),
                 "+",
                 "-",
                 "BYLEX",
                 "REV"
               ])

      # NO flow:outbox was written (the cross-flow branch never fired)
      assert {:ok, 0} == Connector.command(conn, ["LLEN", Keyspace.queue_key(pq, "flow:outbox")])
    end

    test "a flow child that SCHEDULES a retry (not yet at max) does not touch the parent", %{
      conn: conn,
      pq: pq
    } do
      # the failure branch runs ONLY at-max-attempts (inside the morgue block).
      # A flow child retried below max takes the byte-frozen schedule arm -- the
      # parent is untouched until the child actually dies.
      parent = BrandedId.generate!("JOB")
      child = BrandedId.generate!("JOB")

      {:ok, {^parent, [^child]}} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [%{id: child, payload: "c"}]
        })

      {:ok, {^child, _, 1}} = Jobs.claim(conn, pq, 60_000)
      # max 3, attempt 1 -> schedules (not dead); the parent is UNTOUCHED
      assert {:ok, :scheduled} == Jobs.retry(conn, pq, child, 1, 10, 3, "transient")
      assert {:ok, 1} == Flows.dependencies(conn, pq, parent)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, parent)
      assert {:ok, %{}} == hgetall(conn, Keyspace.job_key(pq, parent) <> ":failed")
    end
  end

  # -- add_bulk (emq.3.4-D2) -------------------------------------------------

  describe "add_bulk/3 (emq.3.4-D2) -- N flows, fail-closed per flow" do
    test "lands N flows in one call, each by the add/3 mechanism", %{conn: conn, pq: pq} do
      p1 = BrandedId.generate!("JOB")
      p1c = BrandedId.generate!("JOB")
      p2 = BrandedId.generate!("JOB")
      p2c = BrandedId.generate!("JOB")

      flows = [
        %{parent: %{id: p1, payload: "P1"}, children: [%{id: p1c, payload: "a"}]},
        %{parent: %{id: p2, payload: "P2"}, children: [%{id: p2c, payload: "b"}]}
      ]

      assert {:ok, [{^p1, [^p1c]}, {^p2, [^p2c]}]} = Flows.add_bulk(conn, pq, flows)

      # both parents held, both children claimable
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, p1)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, p2)
      {:ok, {first, _, 1}} = Jobs.claim(conn, pq, 60_000)
      {:ok, {second, _, 1}} = Jobs.claim(conn, pq, 60_000)
      assert Enum.sort([first, second]) == Enum.sort([p1c, p2c])
    end

    test "a poison flow (cross-queue, non-JOB child) leaves its parent HELD, batch not aborted", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      good_p = BrandedId.generate!("JOB")
      good_c = BrandedId.generate!("JOB")
      poison_p = BrandedId.generate!("JOB")
      poison_bad = BrandedId.generate!("ORD")

      flows = [
        # a cross-queue poison flow FIRST: its parent lands held, then the
        # non-JOB child refuses -> the parent stays held, the flow omitted
        %{
          parent: %{id: poison_p, payload: "Px"},
          children: [%{id: poison_bad, payload: "x", queue: cq}]
        },
        %{parent: %{id: good_p, payload: "Pg"}, children: [%{id: good_c, payload: "g"}]}
      ]

      # only the good flow lands; the poison flow is omitted (its parent held)
      assert {:ok, [{^good_p, [^good_c]}]} = Flows.add_bulk(conn, pq, flows)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, good_p)
      # the poison parent is HELD (fail-closed per flow) -- present, never claimable
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, poison_p)
    end

    test "an ill-formed id in ANY flow raises at the gate BEFORE any wire (no flow lands)", %{
      conn: conn,
      pq: pq
    } do
      p1 = BrandedId.generate!("JOB")
      p1c = BrandedId.generate!("JOB")
      p2 = BrandedId.generate!("JOB")

      assert_raise ArgumentError, fn ->
        Flows.add_bulk(conn, pq, [
          %{parent: %{id: p1, payload: "P1"}, children: [%{id: p1c, payload: "a"}]},
          # an ill-formed child id (not a branded id) -> raises at Keyspace.job_key/2
          %{parent: %{id: p2, payload: "P2"}, children: [%{id: "not-branded", payload: "b"}]}
        ])
      end

      # the gate fires BEFORE any wire: NEITHER flow's parent landed
      assert {:ok, 0} == Connector.command(conn, ["EXISTS", Keyspace.job_key(pq, p1)])
      assert {:ok, 0} == Connector.command(conn, ["EXISTS", Keyspace.job_key(pq, p2)])
    end
  end

  # -- ignored_failures/3 (emq.3.4-D6) --------------------------------------

  describe "ignored_failures/3 (emq.3.4-D6) -- the host-only :unsuccessful read" do
    test "an empty parent reads {:ok, %{}}", %{conn: conn, pq: pq} do
      parent = BrandedId.generate!("JOB")
      assert {:ok, %{}} == Flows.ignored_failures(conn, pq, parent)
    end

    test "an ill-formed parent id raises at the key builder (INV4)", %{conn: conn, pq: pq} do
      assert_raise ArgumentError, fn -> Flows.ignored_failures(conn, pq, "not-branded") end
    end
  end

  # -- Stage-3 hardening (the Director's named shapes) ----------------------

  describe "R2 hardening -- a multi-child mixed-outcome flow (complete + fail + ignore)" do
    test "a same-queue parent with 3 children (one completes, one ignored-dies, one fail-dies) ends DEAD", %{
      conn: conn,
      pq: pq
    } do
      # the realistic mixed shape: a flow whose children resolve three different
      # ways. The fail_parent child's death is the decisive one -- it moves the
      # parent to `dead` regardless of the others (a fail-parent death is
      # terminal). The completed child records :processed, the ignored child
      # records :unsuccessful + DECRs, and the fail child records :failed + kills
      # the parent. The parent ends DEAD (the fail-parent wins).
      parent = BrandedId.generate!("JOB")
      good = BrandedId.generate!("JOB")
      ignored = BrandedId.generate!("JOB")
      poison = BrandedId.generate!("JOB")

      {:ok, {^parent, [^good, ^ignored, ^poison]}} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [
            %{id: good, payload: "g"},
            %{id: ignored, payload: "i", ignore_dependency_on_failure: true},
            %{id: poison, payload: "p"}
          ]
        })

      assert {:ok, 3} == Flows.dependencies(conn, pq, parent)

      # complete `good` (deps 3 -> 2, :processed records it)
      claim_complete(conn, pq, good, "g-done")
      assert {:ok, 2} == Flows.dependencies(conn, pq, parent)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, parent)

      # the ignored child dies (deps 2 -> 1, :unsuccessful records it, parent proceeds)
      claim_kill(conn, pq, ignored, "skip-me")
      assert {:ok, 1} == Flows.dependencies(conn, pq, parent)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, parent)

      # the poison (fail_parent) child dies -> the parent is DEAD (the decisive death)
      claim_kill(conn, pq, poison, "boom")
      assert {:ok, :dead} == Metrics.get_job_state(conn, pq, parent)
      assert {:ok, "boom"} == Connector.command(conn, ["HGET", Keyspace.job_key(pq, parent) <> ":failed", poison])

      # the three subkeys are disjoint: good in :processed, ignored in
      # :unsuccessful, poison in :failed -- never crossed
      assert {:ok, %{^good => "g-done"}} = Flows.children_values(conn, pq, parent)
      assert {:ok, %{^ignored => "skip-me"}} = Flows.ignored_failures(conn, pq, parent)
      {:ok, processed} = Flows.children_values(conn, pq, parent)
      {:ok, unsuccessful} = Flows.ignored_failures(conn, pq, parent)
      refute Map.has_key?(processed, poison)
      refute Map.has_key?(unsuccessful, poison)
      refute Map.has_key?(processed, ignored)
    end

    test "a cross-queue parent with 3 children across queues, the LAST deliver fails the parent", %{
      conn: conn,
      pq: pq
    } do
      # three children in three DISTINCT queues, each on its own slot/outbox. Two
      # ignore-dep (proceed), one fail-parent (kills). Each death is delivered on
      # its queue's sweep; the parent fails when the fail-parent entry is
      # delivered (eventually-consistent across the three independent sweeps).
      base = "emq34.ffx3#{System.unique_integer([:positive])}"
      qs = [base <> ".A", base <> ".B", base <> ".C"]
      on_exit(fn -> purge(qs) end)

      parent = BrandedId.generate!("JOB")
      [ia, ib, pc] = Enum.map(qs, fn _ -> BrandedId.generate!("JOB") end)
      [qa, qb, qc] = qs

      {:ok, _} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: [
            %{id: ia, payload: "ia", queue: qa, ignore_dependency_on_failure: true},
            %{id: ib, payload: "ib", queue: qb, ignore_dependency_on_failure: true},
            %{id: pc, payload: "pc", queue: qc}
          ]
        })

      assert {:ok, 3} == Flows.dependencies(conn, pq, parent)

      # kill the two ignore-dep children in their own queues + deliver each
      claim_kill(conn, qa, ia, "skip-a")
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, qa, 100)
      claim_kill(conn, qb, ib, "skip-b")
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, qb, 100)
      # the parent has proceeded twice (deps 3 -> 1) but is NOT failed -- still held
      assert {:ok, 1} == Flows.dependencies(conn, pq, parent)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, parent)

      # kill the fail-parent child + deliver -> the parent is DEAD on this tick
      claim_kill(conn, qc, pc, "boom-c")
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, qc, 100)
      assert {:ok, :dead} == Metrics.get_job_state(conn, pq, parent)
      assert {:ok, "boom-c"} == Connector.command(conn, ["HGET", Keyspace.job_key(pq, parent) <> ":failed", pc])
      assert {:ok, %{^ia => "skip-a", ^ib => "skip-b"}} = Flows.ignored_failures(conn, pq, parent)
    end
  end

  describe "R2 hardening -- the fail-deliver crash window (deliver applied, LTRIM never reached)" do
    test "a crash AFTER @flow_fail_deliver but BEFORE the LTRIM re-delivers idempotently (fail_parent)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      # the exact crash window emq.3.4 closes for the FAILURE path (the emq.3.3
      # complete-path precedent applied to fail): the sweep applied
      # @flow_fail_deliver on the parent's slot (the :failed HSETNX recorded the
      # child, the parent moved dead) but crashed BEFORE the outbox LTRIM, so the
      # SAME fail-entry is still at the head and re-drains next tick. Simulate it
      # precisely: complete the deliver (parent dead), then RE-INJECT the
      # identical fail-entry (the crash survivor the LTRIM never reached) and
      # re-drain -- the HSETNX finds the child already in :failed (0), fails the
      # parent NO second time, the survivor is consumed. The :failed HASH stays a
      # single entry; the parent is dead exactly once.
      {parent, child} = add_cross(conn, pq, cq, fail_parent: true)
      {:ok, {^child, _, 1}} = Jobs.claim(conn, cq, 60_000)
      {:ok, :dead} = Jobs.retry(conn, cq, child, 1, 10, 1, "boom-xq")
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, :dead} == Metrics.get_job_state(conn, pq, parent)
      assert {:ok, 0} == Connector.command(conn, ["LLEN", Keyspace.queue_key(cq, "flow:outbox")])

      # the crash survivor: the SAME fail-entry @retry emits, re-injected and re-drained
      survivor = fail_entry(pq, parent, child, "boom-xq", "fp")
      {:ok, _} = Connector.command(conn, ["RPUSH", Keyspace.queue_key(cq, "flow:outbox"), survivor])
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)

      # the parent is dead exactly once; the :failed HASH has one entry; the
      # survivor was consumed (the outbox drained)
      assert {:ok, :dead} == Metrics.get_job_state(conn, pq, parent)
      assert {:ok, 1} == Connector.command(conn, ["HLEN", Keyspace.job_key(pq, parent) <> ":failed"])
      assert {:ok, 0} == Connector.command(conn, ["LLEN", Keyspace.queue_key(cq, "flow:outbox")])
    end

    test "a partial multi-child crash window: the deliver re-runs without under/over-counting (ignore-dep)", %{
      conn: conn,
      pq: pq,
      cq: cq
    } do
      # 3 cross-queue ignore-dep children: complete+deliver the first (deps 3 ->
      # 2), then re-inject that survivor (deps STAYS 2 -- the HSETNX guard), then
      # the other two die + one sweep drains both (deps -> 0). The redeliver
      # never under-counted, so the final DECR-to-zero is reached exactly, the
      # parent proceeds released (the ignore-dep terminal state).
      parent = BrandedId.generate!("JOB")
      kids = Enum.map(1..3, fn _ -> BrandedId.generate!("JOB") end)

      {:ok, _} =
        Flows.add(conn, pq, %{
          parent: %{id: parent, payload: "P"},
          children: Enum.map(kids, fn id -> %{id: id, payload: "c", queue: cq, ignore_dependency_on_failure: true} end)
        })

      assert {:ok, 3} == Flows.dependencies(conn, pq, parent)

      # kill + deliver the first -> deps 2
      {:ok, {first, _, 1}} = Jobs.claim(conn, cq, 60_000)
      {:ok, :dead} = Jobs.retry(conn, cq, first, 1, 10, 1, "skip-1")
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, 2} == Flows.dependencies(conn, pq, parent)

      # the crash survivor of the first -> re-drain a no-op (deps STAYS 2)
      survivor = fail_entry(pq, parent, first, "skip-1", "id")
      {:ok, _} = Connector.command(conn, ["RPUSH", Keyspace.queue_key(cq, "flow:outbox"), survivor])
      assert {:ok, 1} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, 2} == Flows.dependencies(conn, pq, parent)

      # the other two die; one sweep drains both -> deps 0, parent released
      Enum.each(Enum.reject(kids, &(&1 == first)), fn _ ->
        {:ok, {kid, _, 1}} = Jobs.claim(conn, cq, 60_000)
        {:ok, :dead} = Jobs.retry(conn, cq, kid, 1, 10, 1, "skip")
      end)

      assert {:ok, 2} == Pump.deliver_flow_completions(conn, cq, 100)
      assert {:ok, 0} == Flows.dependencies(conn, pq, parent)
      assert {:ok, :pending} == Metrics.get_job_state(conn, pq, parent)
      # all three ignored failures recorded exactly once
      {:ok, unsuccessful} = Flows.ignored_failures(conn, pq, parent)
      assert map_size(unsuccessful) == 3
    end
  end

  describe "R2 hardening -- the fail_parent ONE-LEVEL boundary (B3, grandchildren OUT/V-1)" do
    test "a failed flow PARENT does NOT auto-propagate to a grandparent (emq.3.4 is FLAT)", %{
      conn: conn,
      pq: pq
    } do
      # emq.3.4 propagates failure ONE parent level. A failed flow parent is
      # moved to `dead` like any other dead job -- it does NOT auto-fail a
      # grandparent (the recursive tree is grandchildren / deep recursion, OUT
      # under V-1 -> emq.3.5). This asserts the boundary HOLDS: build a parent
      # that is ITSELF a flow child of a grandparent (it carries a `parent`
      # field), fail the parent's child so the parent dies, and assert the
      # GRANDPARENT is untouched -- no recursion was attempted.
      #
      # Construct the two-level shape by hand (emq.3.4's add/3 builds ONE level,
      # so the grandparent->parent edge is set directly to model what a
      # grandchildren rung WOULD build): a grandparent held with deps 1, a parent
      # that is its flow child AND itself a flow parent of a (great-)child.
      grandparent = BrandedId.generate!("JOB")
      parent = BrandedId.generate!("JOB")
      child = BrandedId.generate!("JOB")

      # the parent + its child as a normal one-level flow (parent fail_parent default)
      {:ok, {^parent, [^child]}} =
        Flows.add(conn, pq, %{parent: %{id: parent, payload: "P"}, children: [%{id: child, payload: "c"}]})

      # model the grandparent->parent edge a grandchildren rung would create:
      # the grandparent is held (deps 1), and the parent row carries a `parent`
      # field pointing at the grandparent (the upward edge emq.3.4 does NOT walk)
      {:ok, _} = Connector.command(conn, ["SET", Keyspace.job_key(pq, grandparent) <> ":dependencies", "1"])
      {:ok, _} = Connector.command(conn, ["HSET", Keyspace.job_key(pq, grandparent), "state", "awaiting_children"])
      {:ok, _} = Connector.command(conn, ["HSET", Keyspace.job_key(pq, parent), "parent", grandparent])

      # the child dies -> the PARENT is failed (one level: parent -> dead, child in :failed)
      {:ok, {^child, _, 1}} = Jobs.claim(conn, pq, 60_000)
      {:ok, :dead} = Jobs.retry(conn, pq, child, 1, 10, 1, "boom")
      assert {:ok, :dead} == Metrics.get_job_state(conn, pq, parent)
      assert {:ok, "boom"} == Connector.command(conn, ["HGET", Keyspace.job_key(pq, parent) <> ":failed", child])

      # the GRANDPARENT is UNTOUCHED -- emq.3.4 did NOT walk the upward edge:
      # its :dependencies is still 1 (not decremented), it is NOT dead, NOT in
      # :failed -- no grandchildren recursion was attempted (B3/V-1).
      assert {:ok, 1} == Flows.dependencies(conn, pq, grandparent)
      assert {:ok, :awaiting_children} == Metrics.get_job_state(conn, pq, grandparent)
      assert {:ok, %{}} == hgetall(conn, Keyspace.job_key(pq, grandparent) <> ":failed")
      # the dead parent's row carries the upward `parent` edge but emq.3.4 never
      # read it on the failure path (the @retry failure branch reads the dead
      # job's OWN parent only when the dead job is a child being failed -- here
      # the parent died as a PARENT, via its child's death, and its own `parent`
      # field is not consulted)
      assert {:ok, grandparent} == Connector.command(conn, ["HGET", Keyspace.job_key(pq, parent), "parent"])
    end
  end

  # -- helpers --------------------------------------------------------------

  # Claim a specific child (asserting it is the head) and complete it with a result.
  defp claim_complete(conn, q, expected_id, result) do
    {:ok, {id, _, tok}} = Jobs.claim(conn, q, 60_000)
    ^expected_id = id
    :ok = Jobs.complete(conn, q, id, tok, result)
  end

  # Claim a specific child (asserting it is the head) and fail it past max attempts.
  defp claim_kill(conn, q, expected_id, error) do
    {:ok, {id, _, tok}} = Jobs.claim(conn, q, 60_000)
    ^expected_id = id
    {:ok, :dead} = Jobs.retry(conn, q, id, tok, 10, 1, error)
  end

  # Add a 1-child cross-queue flow (parent in pq, child in cq); fail_parent
  # default true unless `fail_parent: false` (-> ignore_dependency). Returns
  # {parent_id, child_id}.
  defp add_cross(conn, pq, cq, opts) do
    parent = BrandedId.generate!("JOB")
    child = BrandedId.generate!("JOB")

    child_spec =
      if Keyword.get(opts, :fail_parent, true) do
        %{id: child, payload: "c", queue: cq}
      else
        %{id: child, payload: "c", queue: cq, ignore_dependency_on_failure: true}
      end

    {:ok, {^parent, [^child]}} =
      Flows.add(conn, pq, %{parent: %{id: parent, payload: "P"}, children: [child_spec]})

    {parent, child}
  end

  # The cross-queue FAIL-entry as @retry's cross-queue failure branch RPUSHes it
  # ('' \0 'fail' \0 parent_queue \0 parent_id \0 child_id \0 policy \0 error) --
  # BYTE-FAITHFUL to the producer (the emq.3.3 L-2 lesson: a re-injected wire
  # fixture counts only if it byte-matches the real emit, or the deliver's
  # HSETNX guard fires on a phantom shape and the test passes for the wrong
  # reason). Used by the idempotent-redeliver assertions.
  defp fail_entry(parent_queue, parent_id, child_id, error, policy) do
    # '' \0 fail \0 parent_queue \0 parent_id \0 child_id \0 policy \0 error
    # (policy before error; error LAST, the remainder) -- BYTE-FAITHFUL to
    # @retry's xq emit (the emq.3.3 L-2 lesson).
    Enum.join(["", "fail", parent_queue, parent_id, child_id, policy, error], <<0>>)
  end

  defp hgetall(conn, key) do
    case Connector.command(conn, ["HGETALL", key]) do
      {:ok, map} when is_map(map) ->
        {:ok, map}

      {:ok, flat} when is_list(flat) ->
        {:ok, Enum.chunk_every(flat, 2) |> Map.new(fn [k, v] -> {k, v} end)}

      other ->
        other
    end
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
