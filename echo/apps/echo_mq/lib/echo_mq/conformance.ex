defmodule EchoMQ.Conformance do
  @moduledoc """
  The bus contract as fifty-five runnable scenarios. Each scenario drives the
  public surface (and, where the contract is the wire itself, raw commands)
  against a live server and asserts the externally visible verdict: the
  fence, the row shape, idempotent admission, the kind law, the lex law,
  the token discipline, the schedule, the morgue, the reaper, the lanes, and
  -- since Chapter 3.7 -- the scheduler vocabulary (scheduled release,
  repeat occurrence, the poison-job drill, connector resubscribe), and --
  since the emq.2 parity cluster -- the read plane (introspection, metrics,
  the rate-gate: emq.2.1), the operator plane (queue-wide pause, drain,
  obliterate, and the job-mutation verbs: emq.2.2), the watch plane (the
  lock-extension verb, the stalled-recovery sweep, the event stream, the
  telemetry surface, and the cooperative cancel: emq.2.3), and -- since the
  parity CLOSER (emq.2.4) -- the five depth behaviors the cluster's verbs gained
  proof for (the in-flight unknown read, the consult-before-claim contract, the
  bounded-complete dedup release, the batch lock-extension partial, and the
  group-aware stalled recover branch) plus the emq.2.2 obliterate fix's
  grouped-row clearance (obliterate del_job's a grouped-but-unclaimed job's row
  before clearing its lane), and -- since the flow family opened (emq.3.1,
  extended emq.3.2) -- the single-queue flow's three behaviors (the atomic add
  with the parent held awaiting_children, the fan-in release with the idempotent
  decrement, and the child-result reads with distinct results read back keyed by
  child id and the dependency count counting down) plus the cross-queue flow's
  eventually-consistent fan-in (a cross-queue child emits to the child-slot
  outbox on completion, the parent held until its sweep delivers the decrement
  on the parent's slot, the deliver idempotent), and -- since the flow family's
  failure half (emq.3.4) -- the failure-policy's three behaviors (a
  fail_parent_on_failure child's death fails the parent same-queue atomically and
  cross-queue on the sweep tick, an ignore_dependency_on_failure child's death
  satisfies-and-records so the parent proceeds, and a bulk add lands N flows
  fail-closed per flow), and -- since the flow family's CLOSER (emq.3.5,
  grandchildren / deep recursion) -- the recursive flow's two behaviors (a
  three-level flow completes UP the tree over the byte-frozen @complete for
  free, and a death propagates UP every level by the recursive failure hook,
  idempotent per hop), and -- since Movement II opened on the groups family
  (emq.4.1, the control plane) -- the control plane's two behaviors (the lane
  re-assignment: a grouped pending member moves to a destination lane at score 0,
  its row group is rewritten, and a claim+complete charges the destination lane's
  ceiling, not the source's -- the move is sound past the ZSET swap; and the
  lane-scoped destructive drain: one lane's pending rows + logs + set + its ring
  entry are deleted while a sibling lane, the in-flight gactive counter, and the
  repeat registry survive -- the blast radius matches the contract), and -- since
  the groups family's recovery axis (emq.4.2, group-aware recovery) -- the
  group-scoped stalled-sweep (a named group's expired-lease members recovered into
  its own lane g:<g>:pending while a sibling group's expired members are left in
  active for the queue-wide reaper -- the scoping filter, on the server clock,
  gactive honest). A port of the client conforms when it drives the same server to
  the same fifty-five verdicts -- the scenarios are wire-level on purpose, so the
  harness ports by translation, not by faith. Scenarios run on per-scenario
  sub-queues and purge what they mint.
  Chapter 3.6, extended 3.7, then the emq.2 cluster (parity, closed at emq.2.4),
  then the emq.3 flow family (opened at emq.3.1, crossed queues at emq.3.3,
  failure half at emq.3.4, closed at emq.3.5 with grandchildren), then Movement
  II's groups family (opened at emq.4.1 with the control plane, the recovery axis
  at emq.4.2).
  """

  alias EchoData.BrandedId

  alias EchoMQ.{
    Admin,
    Cancel,
    Connector,
    Events,
    Flows,
    Jobs,
    Keyspace,
    Lanes,
    Meter,
    Metrics,
    Pump,
    Repeat,
    Stalled
  }

  @doc "The scenario names and their one-line contracts, in run order."
  def scenarios do
    [
      fence: "the version fence is claimed before any work and reads the current wire version",
      mint: "enqueue admits a JOB name and writes the three-field row: state pending, attempts 0, payload",
      duplicate: "a second enqueue of the same name answers duplicate and changes nothing",
      kind: "an ORD name in the job position is refused by the kind law before any write",
      order: "the pending set walked REV BYLEX answers newest-first by name alone",
      claim: "claim mints token 1, returns the payload, and moves the row to active",
      stale: "a stale token's completion is refused EMQSTALE; the live token still settles",
      complete: "complete retires the row everywhere -- nothing remains to browse",
      retry: "retry schedules with last_error kept; promote returns it; the next claim mints token 2",
      dead: "the attempts cap dead-letters with last_error kept, browsable in the morgue",
      reap: "an expired lease is returned to pending by one server-clock scan",
      rotate: "two lanes claim in strict rotation -- the ring is the rota",
      pause: "pause parks a lane with its backlog intact; resume returns it to rotation",
      limit: "the concurrency ceiling answers empty at the limit and reopens on complete",
      schedule: "run-in parks on the schedule set invisible to claim; promote releases it once due",
      repeat: "one registration fires two occurrences with two distinct branded ids in mint order",
      backoff: "the poison drill: a job dead-letters at exactly max attempts with last_error kept",
      resubscribe: "a subscribed connector loses its socket and the channel answers after reconnect",
      counts: "counts answer the cardinality of each as-built set; an unregistered state name is an error",
      state: "a job reads its state by which set holds the id; a missing job reads absent",
      metrics: "a completed job increments the completed counter the metrics read answers; no phantom",
      dedup: "a parked dedup key reads back its branded id; an absent key reads absent",
      rate: "the concurrency gate refuses EMQRATE at the ceiling and answers ok below it",
      lane_depth: "per-lane introspection answers each group's separate backlog over the lane sets",
      queue_pause: "a queue-wide pause claims empty with a non-empty pending; resume restores the head",
      drain: "drain empties pending and deletes the rows; active jobs survive in flight",
      obliterate: "obliterate clears every set of a paused queue; a non-paused queue refuses EMQSTATE",
      update_data: "update_data replaces the row payload; a missing job is a typed absent",
      update_progress: "update_progress writes the row progress field and emits the progress event; a missing job is a typed absent",
      job_logs: "add_log appends to the logs subkey and keep-N trims; get_job_logs reads in order",
      remove_job: "remove_job clears an unlocked job from its set; a locked job refuses EMQLOCK untouched",
      reprocess_job: "reprocess_job moves dead to pending; a non-dead job refuses EMQSTATE untouched",
      lock_extend: "an extended lease survives the reaper past its original deadline; a stale token refuses EMQSTALE",
      stalled: "a lease that lapsed without extension is recovered below the stall threshold and dead-lettered at it",
      events: "a subscriber receives a lifecycle event over the connector pub/sub seam after a host-side publish",
      telemetry: "an attached [:emq, ...] handler receives a job-lifecycle telemetry event",
      cancel: "a cancelled cooperative token answers cancelled and check! raises; an un-cancelled token answers ok",
      unknown_state: "a row that exists but sits in no set reads unknown -- distinct from absent and the four set states",
      rate_consult: "the consult-before-claim contract: at the ceiling is_maxed refuses and a skipping claimer leaves active at the ceiling",
      dedup_release: "remove_job with the caller's dedup_id releases the de: key iff it points at the job; an orphan is left un-swept",
      extend_locks_batch: "the batch lock extension answers exactly the un-extendable ids of a [live, stale, gone] batch",
      stalled_group: "a lapsed GROUPED lease recovers into the lane g:<g>:pending set, not the flat pending",
      obliterate_grouped: "obliterate del_job's a grouped-but-unclaimed job's row before clearing its lane, leaving no leaked row",
      reassign: "a grouped pending member moves to a destination lane at score 0, its row group is rewritten, and a claim+complete charges the destination lane's ceiling -- not the source's",
      lane_drain: "draining one lane deletes its pending rows, their logs, the lane set, and its ring entry, returning the count -- a sibling lane, the in-flight gactive counter, and the repeat registry are untouched",
      reap_group: "a group-scoped sweep recovers ONLY the named group's expired-lease members into its lane g:<g>:pending at score 0 with gactive decremented, leaving a sibling group's expired members in active for the queue-wide reaper -- the server clock, ring-respecting",
      flow_add: "a single-queue flow lands atomically: N+1 distinct JOB ids, the children claimable, the parent awaiting_children with :dependencies = N and withheld from pending",
      flow_fanin: "the parent claims empty until the last child completes, then claimable; the :processed subkey records each child; a double-complete decrements exactly once",
      flow_children_values: "two children complete with DISTINCT results; children_values reads back the results keyed by child id (not the ids); dependencies counts down to 0; the reads are pure",
      flow_cross_queue: "a cross-queue child completes to the child-slot outbox; the parent stays held pre-sweep; the sweep delivers the decrement on the parent's slot and releases it; a re-deliver of the same child decrements exactly once",
      flow_fail_parent: "a fail_parent_on_failure child that dies fails the parent: same-queue atomically, cross-queue on the sweep tick; the parent moves to dead with the child in :failed; a re-delivered fail fails the parent exactly once",
      flow_ignore_dep: "an ignore_dependency_on_failure child that dies satisfies-and-records: :dependencies decremented, the child in :unsuccessful (not :processed), the parent proceeds; ignored_failures reads it back; children_values excludes it",
      flow_add_bulk: "add_bulk lands N flows in one call, each by the add/3 mechanism, fail-closed per flow: N parents land, each flow's children claimable, a poison flow leaves its own parent held without aborting the batch",
      flow_grandchild: "a three-level flow (root -> intermediate node -> grandchild) completes UP the tree over the byte-frozen @complete: the grandchild completes and releases the node to pending (claimable), the node completes and releases the root -- multi-level completion composes for free",
      flow_grandchild_fail: "a three-level fail_parent_on_failure flow propagates a death UP every level (the recursive failure hook): the grandchild dies, the node dies, the root dies (the node in the root's :failed); an ignore_dependency_on_failure top hop lets the root proceed; a re-delivered death fails the root exactly once",
      pool_enqueue: "pool-fronted enqueue is idempotent: a duplicate id through the pool answers duplicate and changes nothing; the row and pending entry match a single-connector enqueue",
      pool_order: "score-0 mint order holds across pool members: ids enqueued round-robin through the pool browse newest-first by name alone (REV BYLEX), identical to the single-connector order",
      native_lock_field: "ewr.2.6 native expiry: a lock field folded into the job hash carries an observable hash-field TTL (HPTTL) and self-clears at its deadline with no sweep, the rest of the row surviving",
      native_lock_refuses: "ewr.2.6: remove_job honors the native lock field -- a job held by the field alone refuses EMQLOCK untouched, and self-heals to removable once the field expires, no sweep"
    ]
  end

  @doc """
  Runs all scenarios against `conn`, on sub-queues of `queue`. Prints one
  CONF line per scenario and a closing tally. Returns `{:ok, n}` when all
  pass (n == 54 today -- the eighteen state-machine scenarios, the emq.2.1
  read plane's six, the emq.2.2 operator plane's eight (queue_pause, drain,
  obliterate, update_data, update_progress, job_logs, remove_job,
  reprocess_job), the emq.2.3 watch plane's five (lock_extend, stalled,
  events, telemetry, cancel), the emq.2.4 parity-closer's five depth
  scenarios (unknown_state, rate_consult, dedup_release, extend_locks_batch,
  stalled_group), the emq.2.2 obliterate fix's grouped-row scenario
  (obliterate_grouped), the emq.3 flow family's three single-queue scenarios
  (flow_add, flow_fanin, flow_children_values), the emq.3.3 cross-queue
  flow scenario (flow_cross_queue), the emq.3.4 failure-half's three
  scenarios (flow_fail_parent, flow_ignore_dep, flow_add_bulk), the
  emq.3.5 closer's two recursion scenarios (flow_grandchild,
  flow_grandchild_fail), and the emq.4.1 control plane's two (the lane
  re-assignment reassign and the lane-scoped destructive drain lane_drain)),
  `{:error, failed_names}` otherwise.
  """
  def run(conn, queue) when is_binary(queue) do
    results =
      for {name, contract} <- scenarios() do
        q = queue <> "." <> Atom.to_string(name)

        verdict =
          try do
            apply_scenario(name, conn, q)
          rescue
            e -> {:fail, Exception.message(e)}
          end
        purge(conn, q)
        ok = verdict == :ok
        IO.puts("CONF #{name} #{if ok, do: "ok", else: "FAIL #{inspect(verdict)}"} -- #{contract}")
        {name, ok}
      end

    failed = for {name, false} <- results, do: name
    IO.puts("CONFORMANCE #{length(results) - length(failed)}/#{length(results)}")
    if failed == [], do: {:ok, length(results)}, else: {:error, failed}
  end

  # -- scenarios ------------------------------------------------------------

  defp apply_scenario(:fence, conn, _q) do
    # The wire fence CLIMBS per rung (Fork-2, D-3): assert the live key tracks
    # the connector's current @wire_version rather than a hardcoded literal, so
    # this scenario never needs a per-rung edit. Connector.wire_version/0 is the
    # single source -- the fence (connector.ex:fence/2) claims/verifies this exact
    # value on connect.
    expected = Connector.wire_version()

    case Connector.command(conn, ["GET", Keyspace.version_key()]) do
      {:ok, ^expected} -> :ok
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:mint, conn, q) do
    id = BrandedId.generate!("JOB")

    with {:ok, :enqueued} <- Jobs.enqueue(conn, q, id, "cargo"),
         {:ok, row} <- Connector.command(conn, ["HGETALL", Keyspace.job_key(q, id)]) do
      if pairs(row) == %{"state" => "pending", "attempts" => "0", "payload" => "cargo"},
        do: :ok,
        else: {:fail, row}
    end
  end

  defp apply_scenario(:duplicate, conn, q) do
    id = BrandedId.generate!("JOB")

    with {:ok, :enqueued} <- Jobs.enqueue(conn, q, id, "once"),
         {:ok, :duplicate} <- Jobs.enqueue(conn, q, id, "twice"),
         {:ok, "once"} <- Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "payload"]) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:kind, conn, q) do
    id = BrandedId.generate!("ORD")

    with {:error, :kind} <- Jobs.enqueue(conn, q, id, "x"),
         {:ok, 0} <- Connector.command(conn, ["EXISTS", Keyspace.job_key(q, id)]) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:order, conn, q) do
    ids = for _ <- 1..3, do: BrandedId.generate!("JOB")
    Enum.each(ids, fn id -> {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "o") end)

    case Connector.command(conn, ["ZRANGE", Keyspace.queue_key(q, "pending"), "+", "-", "BYLEX", "REV"]) do
      {:ok, walked} -> if walked == Enum.reverse(ids), do: :ok, else: {:fail, walked}
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:claim, conn, q) do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "work")

    with {:ok, {^id, "work", 1}} <- Jobs.claim(conn, q, 60_000),
         {:ok, "active"} <- Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "state"]) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:stale, conn, q) do
    # flush the server's script cache so the refusal exercises the
    # load-and-retry path -- the cold-cache regression this harness caught
    {:ok, _} = Connector.command(conn, ["SCRIPT", "FLUSH"])
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)

    with {:error, :stale} <- Jobs.complete(conn, q, id, 99),
         :ok <- Jobs.complete(conn, q, id, 1) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:complete, conn, q) do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
    :ok = Jobs.complete(conn, q, id, 1)

    with {:ok, 0} <- Connector.command(conn, ["EXISTS", Keyspace.job_key(q, id)]),
         {:ok, 0} <- Connector.command(conn, ["ZCARD", Keyspace.queue_key(q, "active")]) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:retry, conn, q) do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
    {:ok, :scheduled} = Jobs.retry(conn, q, id, 1, 10, 3, "boom")

    with {:ok, "scheduled"} <- Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "state"]),
         {:ok, "boom"} <- Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "last_error"]),
         _ <- Process.sleep(30),
         {:ok, 1} <- Jobs.promote(conn, q, 10),
         {:ok, {^id, _, 2}} <- Jobs.claim(conn, q, 60_000),
         :ok <- Jobs.complete(conn, q, id, 2) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:dead, conn, q) do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
    {:ok, :dead} = Jobs.retry(conn, q, id, 1, 10, 1, "gave up")

    with {:ok, "dead"} <- Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "state"]),
         {:ok, "gave up"} <- Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "last_error"]),
         {:ok, [^id]} <-
           Connector.command(conn, ["ZRANGE", Keyspace.queue_key(q, "dead"), "+", "-", "BYLEX", "REV"]) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:reap, conn, q) do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 30)
    Process.sleep(60)

    with {:ok, 1} <- Jobs.reap(conn, q),
         {:ok, "pending"} <- Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "state"]),
         {:ok, {^id, _, 2}} <- Jobs.claim(conn, q, 60_000),
         :ok <- Jobs.complete(conn, q, id, 2) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:rotate, conn, q) do
    [a, b] = for _ <- 1..2, do: BrandedId.generate!("PRT")

    for grp <- [a, b], _ <- 1..2 do
      {:ok, :enqueued} = Lanes.enqueue(conn, q, grp, BrandedId.generate!("JOB"), "r")
    end

    served =
      for _ <- 1..4 do
        {:ok, {_id, _p, 1, grp}} = Lanes.claim(conn, q, 60_000)
        grp
      end

    if served == [a, b, a, b], do: :ok, else: {:fail, served}
  end

  defp apply_scenario(:pause, conn, q) do
    [a, b] = for _ <- 1..2, do: BrandedId.generate!("PRT")

    for grp <- [a, b], _ <- 1..2 do
      {:ok, :enqueued} = Lanes.enqueue(conn, q, grp, BrandedId.generate!("JOB"), "p")
    end

    :ok = Lanes.pause(conn, q, a)
    {:ok, {_, _, 1, ^b}} = Lanes.claim(conn, q, 60_000)
    {:ok, {_, _, 1, ^b}} = Lanes.claim(conn, q, 60_000)

    with :empty <- Lanes.claim(conn, q, 60_000),
         {:ok, 2} <- Lanes.depth(conn, q, a),
         :ok <- Lanes.resume(conn, q, a),
         {:ok, {_, _, 1, ^a}} <- Lanes.claim(conn, q, 60_000) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:limit, conn, q) do
    a = BrandedId.generate!("PRT")
    :ok = Lanes.limit(conn, q, a, 1)
    [j1, _j2] = for _ <- 1..2, do: BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, a, j1, "l")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, a, BrandedId.generate!("JOB"), "l")
    {:ok, {^j1, _, 1, ^a}} = Lanes.claim(conn, q, 60_000)

    with :empty <- Lanes.claim(conn, q, 60_000),
         :ok <- Jobs.complete(conn, q, j1, 1),
         {:ok, {_, _, 1, ^a}} <- Lanes.claim(conn, q, 60_000) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:schedule, conn, q) do
    id = BrandedId.generate!("JOB")

    with {:ok, :scheduled} <- Jobs.enqueue_in(conn, q, id, "later", 30),
         {:ok, "scheduled"} <- Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "state"]),
         :empty <- Jobs.claim(conn, q, 60_000),
         _ <- Process.sleep(50),
         {:ok, 1} <- Jobs.promote(conn, q, 10),
         {:ok, {^id, "later", 1}} <- Jobs.claim(conn, q, 60_000),
         :ok <- Jobs.complete(conn, q, id, 1) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:repeat, conn, q) do
    name = "report"
    {:ok, :registered} = Repeat.register(conn, q, name, 10, "daily", 0)

    first = drain_one(conn, q, name)
    Process.sleep(20)
    second = drain_one(conn, q, name)
    :ok = drain_pending(conn, q)
    {:ok, :cancelled} = Repeat.cancel(conn, q, name)

    cond do
      first == :none or second == :none -> {:fail, {:no_occurrence, first, second}}
      first == second -> {:fail, {:reused_id, first}}
      # a later occurrence mints a later (lexically greater) branded id;
      # mint order is the sort key, so first < second
      first >= second -> {:fail, {:not_mint_ordered, first, second}}
      true -> :ok
    end
  end

  defp apply_scenario(:backoff, conn, q) do
    # the poison-job drill: a persistently failing handler exhausts its
    # attempts and dead-letters at exactly the cap, last_error browsable.
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "poison")
    max = 3
    policy = {:exponential, 1, 10}

    verdict =
      Enum.reduce_while(1..max, nil, fn _, _ ->
        {:ok, {^id, _, att}} = Jobs.claim(conn, q, 60_000)
        delay = EchoMQ.Backoff.delay_ms(policy, att)

        case Jobs.retry(conn, q, id, att, delay, max, "boom #{att}") do
          {:ok, :scheduled} ->
            # the curve parks the retry delay ms out; wait the delay, then
            # release it so the next claim can exhaust the next attempt
            Process.sleep(delay + 5)
            {:ok, 1} = Jobs.promote(conn, q, 10)
            {:cont, {:scheduled, att}}

          {:ok, :dead} ->
            {:halt, {:dead, att}}
        end
      end)

    with {:dead, ^max} <- verdict,
         {:ok, "dead"} <- Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "state"]),
         {:ok, "boom 3"} <- Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "last_error"]),
         {:ok, [^id]} <-
           Connector.command(conn, ["ZRANGE", Keyspace.queue_key(q, "dead"), "+", "-", "BYLEX", "REV"]) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:resubscribe, conn, q) do
    # a subscribed connector loses its socket; after the reconnect path
    # restores it, the channel answers again without a caller restart. The
    # passed conn is the publisher; the subscriber is a RESP3 connection with
    # a tight reconnect so the kill recovers within the scenario.
    chan = "emq:{" <> q <> "}:chan"

    {:ok, sub} =
      Connector.start_link(port: 6390, protocol: 3, push_to: self(), backoff_initial: 20, backoff_max: 50)

    :ok = Connector.subscribe(sub, chan)
    sub_id = client_id(sub)
    {:ok, 1} = Connector.command(conn, ["PUBLISH", chan, "before"])

    pre =
      receive do
        {:emq_push, ["message", ^chan, "before"]} -> :ok
      after
        1_000 -> :fail_pre
      end

    # kill the subscriber's socket from the publisher connection (by the
    # subscriber's client id); the subscriber's reconnect path restores the
    # socket and re-issues the recorded subscription
    {:ok, _} = Connector.command(conn, ["CLIENT", "KILL", "ID", sub_id])
    if wait_reconnected(sub, 50), do: :ok, else: :no_reconnect

    {:ok, 1} = Connector.command(conn, ["PUBLISH", chan, "after"])

    post =
      receive do
        {:emq_push, ["message", ^chan, "after"]} -> :ok
      after
        2_000 -> :fail_post
      end

    GenServer.stop(sub)

    cond do
      pre != :ok -> {:fail, {:pre, pre}}
      post != :ok -> {:fail, {:post, post}}
      true -> :ok
    end
  end

  defp apply_scenario(:counts, conn, q) do
    # the oldest pending is claimed into active (ZPOPMIN is mint order), so the
    # to-be-active job is enqueued first, then three that stay pending
    act = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, act, "c")
    {:ok, {^act, _, 1}} = Jobs.claim(conn, q, 60_000)
    pend = for _ <- 1..3, do: BrandedId.generate!("JOB")
    Enum.each(pend, fn id -> {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "c") end)
    sched = BrandedId.generate!("JOB")
    {:ok, :scheduled} = Jobs.enqueue_in(conn, q, sched, "c", 60_000)

    with {:ok, %{"pending" => 3, "active" => 1, "schedule" => 1, "dead" => 0}} <-
           Metrics.get_counts(conn, q, ["pending", "active", "schedule", "dead"]),
         {:error, {:unknown_state, "wait"}} <- Metrics.get_counts(conn, q, ["wait"]) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:state, conn, q) do
    claimed = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, claimed, "s")
    {:ok, {^claimed, _, 1}} = Jobs.claim(conn, q, 60_000)
    sched = BrandedId.generate!("JOB")
    {:ok, :scheduled} = Jobs.enqueue_in(conn, q, sched, "s", 60_000)
    missing = BrandedId.generate!("JOB")

    with {:ok, :active} <- Metrics.get_job_state(conn, q, claimed),
         {:ok, :scheduled} <- Metrics.get_job_state(conn, q, sched),
         {:ok, :absent} <- Metrics.get_job_state(conn, q, missing),
         {:ok, %{"state" => "active", "attempts" => "1", "payload" => "s"}} <-
           Metrics.get_job(conn, q, claimed),
         :absent <- Metrics.get_job(conn, q, missing) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:metrics, conn, q) do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "m")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)

    with {:ok, %{count: 0, data_points: 0}} <- Metrics.get_metrics(conn, q, :completed),
         :ok <- Jobs.complete(conn, q, id, 1),
         {:ok, %{count: 1, data_points: 0}} <- Metrics.get_metrics(conn, q, :completed) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:dedup, conn, q) do
    did = "order-42"
    id = BrandedId.generate!("JOB")
    {:ok, _} = Connector.command(conn, ["SET", Keyspace.queue_key(q, "de:" <> did), id])
    absent = "never-parked"

    with {:ok, ^id} <- Metrics.get_deduplication_job_id(conn, q, did),
         :absent <- Metrics.get_deduplication_job_id(conn, q, absent) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:rate, conn, q) do
    # configure a concurrency ceiling of 1 in meta, then drive one job to
    # active so the gate is at the ceiling; a second is below before the claim.
    {:ok, _} = Connector.command(conn, ["HSET", Keyspace.queue_key(q, "meta"), "concurrency", "1"])

    open = Metrics.is_maxed(conn, q)
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "r")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
    maxed = Metrics.is_maxed(conn, q)

    cond do
      open != :ok -> {:fail, {:open, open}}
      maxed != {:error, :rate} -> {:fail, {:maxed, maxed}}
      true -> :ok
    end
  end

  defp apply_scenario(:lane_depth, conn, q) do
    [a, b] = for _ <- 1..2, do: BrandedId.generate!("PRT")
    for _ <- 1..2, do: {:ok, :enqueued} = Lanes.enqueue(conn, q, a, BrandedId.generate!("JOB"), "l")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, b, BrandedId.generate!("JOB"), "l")

    case Metrics.lane_depths(conn, q, [a, b]) do
      {:ok, depths} -> if depths == %{a => 2, b => 1}, do: :ok, else: {:fail, depths}
      other -> {:fail, other}
    end
  end

  # -- emq.2.2 operator plane ----------------------------------------------

  defp apply_scenario(:queue_pause, conn, q) do
    keep = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, keep, "p")

    with :ok <- Admin.pause(conn, q),
         :empty <- Jobs.claim(conn, q, 60_000),
         {:ok, %{"pending" => 1}} <- Metrics.get_counts(conn, q, ["pending"]),
         :ok <- Admin.resume(conn, q),
         {:ok, {^keep, "p", 1}} <- Jobs.claim(conn, q, 60_000) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:drain, conn, q) do
    live = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, live, "active")
    {:ok, {^live, _, 1}} = Jobs.claim(conn, q, 60_000)
    waiting = for _ <- 1..3, do: BrandedId.generate!("JOB")
    Enum.each(waiting, fn id -> {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "waiting") end)

    with {:ok, 3} <- Admin.drain(conn, q),
         {:ok, %{"pending" => 0, "active" => 1}} <- Metrics.get_counts(conn, q, ["pending", "active"]),
         {:ok, :active} <- Metrics.get_job_state(conn, q, live),
         {:ok, 0} <- Connector.command(conn, ["EXISTS", Keyspace.job_key(q, hd(waiting))]) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:obliterate, conn, q) do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "x")

    # a non-paused queue refuses, changing nothing
    refused = Admin.obliterate(conn, q)
    {:ok, %{"pending" => still}} = Metrics.get_counts(conn, q, ["pending"])

    :ok = Admin.pause(conn, q)
    obliterated = Admin.obliterate(conn, q)

    {:ok, after_counts} =
      Metrics.get_counts(conn, q, ["pending", "active", "schedule", "dead"])

    cond do
      refused != {:error, :not_paused} -> {:fail, {:refused, refused}}
      still != 1 -> {:fail, {:changed_on_refusal, still}}
      obliterated != :ok -> {:fail, {:obliterate, obliterated}}
      after_counts != %{"pending" => 0, "active" => 0, "schedule" => 0, "dead" => 0} ->
        {:fail, {:not_cleared, after_counts}}

      true ->
        :ok
    end
  end

  defp apply_scenario(:update_data, conn, q) do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "old")
    missing = BrandedId.generate!("JOB")

    with :ok <- Jobs.update_data(conn, q, id, "new"),
         {:ok, %{"payload" => "new"}} <- Metrics.get_job(conn, q, id),
         {:error, :gone} <- Jobs.update_data(conn, q, missing, "x") do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:update_progress, conn, q) do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    missing = BrandedId.generate!("JOB")

    # a subscriber on the per-queue events channel is established BEFORE the
    # update (no lost-wakeup race) and the receive is bounded (no hang/flake)
    chan = "emq:{" <> q <> "}:events"
    {:ok, sub} = Connector.start_link(port: 6390, protocol: 3, push_to: self())
    :ok = Connector.subscribe(sub, chan)

    verdict =
      with :ok <- Jobs.update_progress(conn, q, id, "50"),
           {:ok, "50"} <- Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "progress"]),
           msg when is_binary(msg) <- await_event(chan),
           # cjson key order is not guaranteed -- assert the fields, not byte order
           true <-
             String.contains?(msg, ~s("event":"progress")) and String.contains?(msg, id) and
               String.contains?(msg, ~s("progress":"50")),
           {:error, :gone} <- Jobs.update_progress(conn, q, missing, "1") do
        :ok
      else
        other -> {:fail, other}
      end

    # the subscriber shares the harness with the resubscribe scenario (which
    # kills connections); tolerate it being already dead at stop time
    try do
      GenServer.stop(sub)
    catch
      :exit, _ -> :ok
    end

    verdict
  end

  defp apply_scenario(:job_logs, conn, q) do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    missing = BrandedId.generate!("JOB")

    with {:ok, 1} <- Jobs.add_log(conn, q, id, "line-1"),
         {:ok, 2} <- Jobs.add_log(conn, q, id, "line-2"),
         {:ok, ["line-1", "line-2"]} <- Jobs.get_job_logs(conn, q, id),
         {:ok, 2} <- Jobs.add_log(conn, q, id, "line-3", 2),
         {:ok, ["line-2", "line-3"]} <- Jobs.get_job_logs(conn, q, id),
         {:error, :gone} <- Jobs.add_log(conn, q, missing, "x"),
         {:error, :gone} <- Jobs.get_job_logs(conn, q, missing) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:remove_job, conn, q) do
    # an unlocked job with a held dedup key: remove clears it and releases the key
    did = "dedup-7"
    free = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, free, "w")
    {:ok, _} = Connector.command(conn, ["SET", Keyspace.queue_key(q, "de:" <> did), free])

    # a locked job: remove refuses EMQLOCK, leaving it in place
    held = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, held, "w")
    {:ok, _} = Connector.command(conn, ["SET", Keyspace.job_key(q, held) <> ":lock", "worker-1"])

    with :ok <- Jobs.remove_job(conn, q, free, did),
         {:ok, :absent} <- Metrics.get_job_state(conn, q, free),
         :absent <- Metrics.get_deduplication_job_id(conn, q, did),
         {:error, :locked} <- Jobs.remove_job(conn, q, held),
         {:ok, :pending} <- Metrics.get_job_state(conn, q, held) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:reprocess_job, conn, q) do
    # dead-letter a job, then reprocess it back to pending
    dead = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, dead, "w")
    {:ok, {^dead, _, 1}} = Jobs.claim(conn, q, 60_000)
    {:ok, :dead} = Jobs.retry(conn, q, dead, 1, 10, 1, "gave up")

    # a live (pending) job is not reprocessable
    live = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, live, "w")

    with :ok <- Jobs.reprocess_job(conn, q, dead),
         {:ok, :pending} <- Metrics.get_job_state(conn, q, dead),
         {:ok, %{"state" => "pending"}} <- Metrics.get_job(conn, q, dead),
         {:ok, nil} <- Connector.command(conn, ["HGET", Keyspace.job_key(q, dead), "last_error"]),
         {:error, :not_dead} <- Jobs.reprocess_job(conn, q, live),
         {:ok, :pending} <- Metrics.get_job_state(conn, q, live) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  # -- the watch plane (emq.2.3) --------------------------------------------

  defp apply_scenario(:lock_extend, conn, q) do
    # claim with a tiny lease, extend it past the original deadline, prove the
    # reaper does NOT reclaim it; then a stale token refuses EMQSTALE.
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 50)

    with :ok <- Jobs.extend_lock(conn, q, id, 1, 60_000),
         :ok <- (Process.sleep(120) && :ok),
         {:ok, 0} <- Jobs.reap(conn, q),
         {:ok, members} <-
           Connector.command(conn, ["ZRANGE", Keyspace.queue_key(q, "active"), "0", "-1"]),
         true <- id in members,
         {:error, :stale} <- Jobs.extend_lock(conn, q, id, 2, 60_000),
         {:error, :gone} <- Jobs.extend_lock(conn, q, BrandedId.generate!("JOB"), 1, 60_000) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:stalled, conn, q) do
    # a lease that lapsed without extension recovers below the threshold, and a
    # second lapse at the threshold dead-letters with last_error stalled.
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 30)

    with false <- Stalled.job_stalled?(conn, q, id),
         :ok <- (Process.sleep(80) && :ok),
         {:ok, %{recovered: [^id], dead: []}} <- Stalled.check(conn, q, max_stalled: 2),
         true <- Stalled.job_stalled?(conn, q, id),
         {:ok, :pending} <- Metrics.get_job_state(conn, q, id),
         {:ok, {^id, _, 2}} <- Jobs.claim(conn, q, 30),
         :ok <- (Process.sleep(80) && :ok),
         {:ok, %{recovered: [], dead: [^id]}} <- Stalled.check(conn, q, max_stalled: 2),
         {:ok, :dead} <- Metrics.get_job_state(conn, q, id),
         {:ok, "stalled"} <-
           Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "last_error"]) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:events, conn, q) do
    # a subscriber on the per-queue events channel receives a host-side
    # published lifecycle event (the watch plane's pub/sub seam).
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")

    chan = Events.channel(q)
    {:ok, sub} = Connector.start_link(port: 6390, protocol: 3, push_to: self())
    :ok = Connector.subscribe(sub, chan)
    # let the SUBSCRIBE land before the publish (no lost-wakeup race)
    Process.sleep(50)

    verdict =
      with {:ok, {^id, _, 1}} <- Jobs.claim(conn, q, 60_000),
           :ok <- Jobs.complete(conn, q, id, 1),
           :ok <- Events.publish(conn, q, :completed, id),
           msg when is_binary(msg) <- await_event(chan),
           true <-
             String.contains?(msg, ~s("event":"completed")) and String.contains?(msg, id),
           # the name extracts to the expected atom (the dispatch key)
           :completed <- Events.event_name(msg) do
        :ok
      else
        other -> {:fail, other}
      end

    try do
      GenServer.stop(sub)
    catch
      :exit, _ -> :ok
    end

    verdict
  end

  defp apply_scenario(:telemetry, conn, q) do
    # The telemetry surface's TWO-MODE contract (D3/INV6 -- the Connector.emit/3
    # zero-cost precedent). :telemetry is an OPTIONAL dependency (the bus
    # declares none -- mix.lock unchanged); under the per-app test it may be
    # absent. So this asserts the real verdict of the surface in EITHER mode:
    #   present -> an attached [:emq, ...] handler receives the lifecycle event;
    #   absent  -> attach + emit answer :ok as safe no-ops (no event delivered).
    test = self()
    hid = "conf-telemetry-#{System.unique_integer([:positive])}"
    :ok = Meter.attach(hid, [:job, :complete], fn event, meas, meta, _ ->
      send(test, {:telemetry_fired, event, meas, meta})
    end)

    # a real lifecycle transition, then the emit (the surface fires; the
    # contract -- the payload-shape matrix -- is emq.8, NOT asserted here).
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
    :ok = Jobs.complete(conn, q, id, 1)
    :ok = Meter.job_completed(q, id, "w", self(), 1234)

    verdict =
      if :erlang.function_exported(:telemetry, :execute, 3) do
        # telemetry present: the surface fires the [:emq, ...] event
        receive do
          {:telemetry_fired, [:emq, :job, :complete], meas, meta} ->
            if meas.duration == 1234 and meta.job_id == id, do: :ok, else: {:fail, {meas, meta}}
        after
          1_000 -> {:fail, :no_telemetry_event}
        end
      else
        # telemetry absent: emission is a safe no-op (zero cost), no event
        receive do
          {:telemetry_fired, _, _, _} -> {:fail, :fired_without_telemetry}
        after
          100 -> :ok
        end
      end

    # detach via apply (the bus carries no :telemetry dep -- the Meter guard
    # precedent); a no-:telemetry host never attached, so the detach is moot.
    if :erlang.function_exported(:telemetry, :detach, 1), do: apply(:telemetry, :detach, [hid])
    verdict
  end

  defp apply_scenario(:cancel, _conn, _q) do
    # the cooperative cancellation token, host-side (no wire identity).
    token = Cancel.new()

    with true <- is_reference(token),
         :ok <- Cancel.check(token),
         :ok <- Cancel.check!(token),
         :ok <- Cancel.cancel(self(), token, :stop),
         {:cancelled, :stop} <- Cancel.check(token),
         :ok <- Cancel.cancel(self(), token, :again),
         {:cancelled, :again} <-
           (try do
              Cancel.check!(token)
              :not_raised
            rescue
              e in EchoMQ.Cancel.Cancelled -> {:cancelled, e.reason}
            end) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  # -- the parity closer (emq.2.4) ------------------------------------------

  defp apply_scenario(:unknown_state, conn, q) do
    # a row that EXISTS but is in none of the four sets reads :unknown -- the
    # in-flight read distinct from :absent (no row) and the four set states.
    # Construct it by claiming (active holds it) then ZREM-ing it WITHOUT a
    # transition: the row survives, no set holds it. emq.2.4-D5.
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
    {:ok, 1} = Connector.command(conn, ["ZREM", Keyspace.queue_key(q, "active"), id])

    with {:ok, :unknown} <- Metrics.get_job_state(conn, q, id),
         {:ok, %{"state" => "active"}} <- Metrics.get_job(conn, q, id),
         {:ok, :absent} <- Metrics.get_job_state(conn, q, BrandedId.generate!("JOB")) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:rate_consult, conn, q) do
    # the consult-before-claim contract (emq.2.4-D2, Arm 2): at the ceiling
    # is_maxed/2 refuses {:error, :rate}; a claimer that consults and SKIPS the
    # claim leaves the active set at the ceiling and the waiting job in pending.
    {:ok, _} = Connector.command(conn, ["HSET", Keyspace.queue_key(q, "meta"), "concurrency", "1"])
    held = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, held, "held")
    {:ok, {^held, _, 1}} = Jobs.claim(conn, q, 60_000)
    waiting = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, waiting, "wait")

    claimed =
      case Metrics.is_maxed(conn, q) do
        {:error, :rate} -> :skipped
        :ok -> Jobs.claim(conn, q, 60_000)
      end

    with :skipped <- claimed,
         {:ok, %{"active" => 1, "pending" => 1}} <-
           Metrics.get_counts(conn, q, ["active", "pending"]),
         :ok <- Jobs.complete(conn, q, held, 1),
         :ok <- Metrics.is_maxed(conn, q) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:dedup_release, conn, q) do
    # the bounded-complete dedup release (emq.2.4-D4): remove_job with the
    # caller's dedup_id releases the de: key iff it points at the job; an orphan
    # with no live referrer is left un-swept (the declared-keys honest limit).
    did = "conf-dedup"
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, _} = Connector.command(conn, ["SET", Keyspace.queue_key(q, "de:" <> did), id])

    orphan_did = "conf-orphan"
    {:ok, _} =
      Connector.command(conn, ["SET", Keyspace.queue_key(q, "de:" <> orphan_did), BrandedId.generate!("JOB")])

    with {:ok, ^id} <- Metrics.get_deduplication_job_id(conn, q, did),
         :ok <- Jobs.remove_job(conn, q, id, did),
         :absent <- Metrics.get_deduplication_job_id(conn, q, did),
         {:ok, orphan} when is_binary(orphan) <-
           Metrics.get_deduplication_job_id(conn, q, orphan_did) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:extend_locks_batch, conn, q) do
    # the batch lock extension partial-batch (emq.2.4-C2): a [live, stale, gone]
    # batch answers exactly the un-extendable ids -- the live extends, the stale
    # (wrong token) and the gone (no row) are returned.
    live = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, live, "w")
    {:ok, {^live, _, live_tok}} = Jobs.claim(conn, q, 60_000)
    stale = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, stale, "w")
    {:ok, {^stale, _, _}} = Jobs.claim(conn, q, 60_000)
    gone = BrandedId.generate!("JOB")

    case Jobs.extend_locks(conn, q, [{live, live_tok}, {stale, 999}, {gone, 1}], 90_000) do
      {:ok, failed} ->
        if Enum.sort(failed) == Enum.sort([stale, gone]) and live not in failed,
          do: :ok,
          else: {:fail, failed}

      other ->
        {:fail, other}
    end
  end

  defp apply_scenario(:stalled_group, conn, q) do
    # the group-aware stalled recover branch (emq.2.4-C2): a lapsed GROUPED lease
    # recovers into the lane g:<g>:pending set (distinct from the flat branch).
    g = BrandedId.generate!("PRT")
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, g, id, "g")
    {:ok, {^id, _, 1, ^g}} = Lanes.claim(conn, q, 30)
    Process.sleep(80)

    with {:ok, %{recovered: [^id], dead: []}} <- Stalled.check(conn, q, max_stalled: 2),
         {:ok, score} when not is_nil(score) <-
           Connector.command(conn, ["ZSCORE", Keyspace.queue_key(q, "g:" <> g <> ":pending"), id]),
         {:ok, nil} <-
           Connector.command(conn, ["ZSCORE", Keyspace.queue_key(q, "pending"), id]),
         {:ok, {^id, _, 2, ^g}} <- Lanes.claim(conn, q, 60_000) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:obliterate_grouped, conn, q) do
    # the grouped-row obliterate (emq.2.2 fix): a grouped-but-unclaimed job
    # lives ONLY in its lane g:<g>:pending set, never in a flat set, so the
    # original obliterate DELed the lane ZSET but leaked the job row. The fix
    # del_job's each lane member before DELing the lane. Obliterate a paused
    # queue holding one grouped pending job and assert NO row, NO lane, NO
    # keyspace footprint remains -- distinct from :obliterate, which populates
    # only a FLAT set and so never exercises the lane branch.
    g = BrandedId.generate!("PRT")
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, g, id, "g")

    with {:ok, 1} <- Connector.command(conn, ["EXISTS", Keyspace.job_key(q, id)]),
         :ok <- Admin.pause(conn, q),
         :ok <- Admin.obliterate(conn, q),
         {:ok, 0} <- Connector.command(conn, ["EXISTS", Keyspace.job_key(q, id)]),
         {:ok, 0} <- Connector.command(conn, ["EXISTS", Keyspace.queue_key(q, "g:" <> g <> ":pending")]),
         {:ok, []} <- Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"]) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:reassign, conn, q) do
    # the control plane's headline move (emq.4.1-D2): a grouped pending member
    # moves from its source lane to a destination lane in one atomic script. The
    # proof is the FULL cycle, not the ZSET swap alone: the member must leave
    # g:<src>:pending, enter g:<dst>:pending at score 0, AND its row group must be
    # rewritten to dst -- because the byte-frozen @gclaim/@complete read HGET
    # <row> 'group' to find the lane and the gactive counter. A claim+complete of
    # the moved member must therefore charge gactive[dst], NOT gactive[src]; a
    # stale row group would silently charge the wrong lane (gate-invisible without
    # this cycle). src is derived in-script from the row -- arity 4, never passed.
    src = BrandedId.generate!("PRT")
    dst = BrandedId.generate!("PRT")
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, src, id, "move-me")

    gactive = Keyspace.queue_key(q, "gactive")
    src_lane = Keyspace.queue_key(q, "g:" <> src <> ":pending")
    dst_lane = Keyspace.queue_key(q, "g:" <> dst <> ":pending")

    with {:ok, :reassigned} <- Lanes.reassign(conn, q, id, dst),
         # the member left src and entered dst at score 0 (FIFO-by-mint kept).
         # ZSCORE answers a numeric score whose wire form (the float 0.0 on RESP3,
         # "0" on RESP2) is connection-dependent, so the score VALUE is checked,
         # not its representation; absence is a clean nil either way.
         {:ok, nil} <- Connector.command(conn, ["ZSCORE", src_lane, id]),
         {:ok, dst_score} when dst_score in [0, "0", +0.0] <-
           Connector.command(conn, ["ZSCORE", dst_lane, id]),
         # the load-bearing write: the row now records dst
         {:ok, ^dst} <- Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "group"]),
         # a same-group move is an idempotent no-op
         {:ok, :noop} <- Lanes.reassign(conn, q, id, dst),
         # the moved member is served as part of dst's rotation, with group = dst
         {:ok, {^id, "move-me", 1, ^dst}} <- Lanes.claim(conn, q, 60_000),
         # in flight, the row's group drove the increment to dst's ceiling, not src's
         {:ok, "1"} <- Connector.command(conn, ["HGET", gactive, dst]),
         {:ok, nil} <- Connector.command(conn, ["HGET", gactive, src]),
         # complete charges dst's counter back down (self-cleaning to absent)
         :ok <- Jobs.complete(conn, q, id, 1),
         {:ok, nil} <- Connector.command(conn, ["HGET", gactive, dst]),
         {:ok, nil} <- Connector.command(conn, ["HGET", gactive, src]) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:lane_drain, conn, q) do
    # the lane-scoped destructive drain (emq.4.1-D5): draining one lane empties
    # its pending backlog (rows + §6 logs + the lane set) and drops its ring
    # entry, returning the count -- and NOTHING else. The proof is the blast
    # radius: an in-flight member of the SAME lane (claimed -> active, counted in
    # gactive) survives, a SIBLING lane survives, and the repeat registry
    # survives. A drain that over-reached would corrupt accounting or destroy a
    # tenant's other work -- gate-invisible without this scope assertion.
    a = BrandedId.generate!("PRT")
    b = BrandedId.generate!("PRT")
    [a1, a2, a3] = for _ <- 1..3, do: BrandedId.generate!("JOB")
    b1 = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, a, a1, "a1")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, a, a2, "a2")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, a, a3, "a3")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, b, b1, "b1")

    # claim a1 from lane a -> it leaves the lane for active; gactive[a] = 1
    {:ok, {^a1, _, 1, ^a}} = Lanes.claim(conn, q, 60_000)
    # a2 carries a log line, to prove the §6 logs subkey is deleted
    {:ok, 1} = Jobs.add_log(conn, q, a2, "trace")
    # a repeat registration must survive a lane drain (the registry is not a lane)
    {:ok, :registered} = Repeat.register(conn, q, "rep", 60_000, "tick", 0)

    gactive = Keyspace.queue_key(q, "gactive")
    a_lane = Keyspace.queue_key(q, "g:" <> a <> ":pending")
    b_lane = Keyspace.queue_key(q, "g:" <> b <> ":pending")

    with {:ok, 2} <- Lanes.drain(conn, q, a),
         # the two pending rows + the lane set are gone
         {:ok, 0} <- Connector.command(conn, ["EXISTS", Keyspace.job_key(q, a2)]),
         {:ok, 0} <- Connector.command(conn, ["EXISTS", Keyspace.job_key(q, a3)]),
         {:ok, 0} <- Connector.command(conn, ["EXISTS", a_lane]),
         # a2's logs subkey is gone
         {:ok, 0} <- Connector.command(conn, ["EXISTS", Keyspace.job_key(q, a2) <> ":logs"]),
         # the ring no longer carries a, but still carries the sibling b
         {:ok, nil} <- Connector.command(conn, ["LPOS", Keyspace.queue_key(q, "ring"), a]),
         {:ok, pos} when is_integer(pos) <- Connector.command(conn, ["LPOS", Keyspace.queue_key(q, "ring"), b]),
         # the in-flight a1 is untouched: still active, gactive[a] still 1
         {:ok, :active} <- Metrics.get_job_state(conn, q, a1),
         {:ok, "1"} <- Connector.command(conn, ["HGET", gactive, a]),
         # the sibling lane b is intact (its row, its set)
         {:ok, 1} <- Connector.command(conn, ["EXISTS", Keyspace.job_key(q, b1)]),
         {:ok, 1} <- Connector.command(conn, ["ZCARD", b_lane]),
         # the repeat registry survives
         {:ok, 1} <- Connector.command(conn, ["EXISTS", Keyspace.queue_key(q, "repeat")]),
         # an empty/absent lane drains to 0, changing nothing
         {:ok, 0} <- Lanes.drain(conn, q, BrandedId.generate!("PRT")) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:reap_group, conn, q) do
    # the group-scoped stalled-sweep (emq.4.2-D2): recover ONE named group's
    # lapsed leases on demand, returning each to its OWN lane g:<g>:pending, NOT
    # the flat pending. The load-bearing proof is the TWO-group scoping: a sibling
    # group h whose member ALSO has an expired lease in the same `active` set must
    # be LEFT in active (the `g == ARGV[1]` filter). A one-group probe would pass
    # even with the filter absent -- the queue-wide @reap recovers every lapse --
    # so the sibling-left-behind assertion is what makes the filter falsifiable.
    # The gactive coherence is the second proof: the sweep HINCRBY gactive g -1
    # (the @reap accounting), so a re-claim+complete of the recovered member
    # charges an honest gactive[g]. The member returns to its own lane, so `group`
    # is a pure read (no HSET) -- the re-claim reads back group = g unchanged.
    g = BrandedId.generate!("PRT")
    h = BrandedId.generate!("PRT")
    id_g = BrandedId.generate!("JOB")
    id_h = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, g, id_g, "g")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, h, id_h, "h")

    # claim BOTH on a short lease (one claim per ring rotation), then expire
    {:ok, {first, _, 1, fg}} = Lanes.claim(conn, q, 30)
    {:ok, {second, _, 1, sg}} = Lanes.claim(conn, q, 30)
    claimed = MapSet.new([{first, fg}, {second, sg}])
    Process.sleep(80)

    active = Keyspace.queue_key(q, "active")
    g_lane = Keyspace.queue_key(q, "g:" <> g <> ":pending")
    gactive = Keyspace.queue_key(q, "gactive")

    with true <- MapSet.equal?(claimed, MapSet.new([{id_g, g}, {id_h, h}])),
         # in flight before recovery: gactive[g] = gactive[h] = 1
         {:ok, "1"} <- Connector.command(conn, ["HGET", gactive, g]),
         {:ok, "1"} <- Connector.command(conn, ["HGET", gactive, h]),
         # recover ONLY g
         {:ok, 1} <- Lanes.reap_group(conn, q, g),
         # g's member is back in its lane at score 0, absent from active and flat pending
         {:ok, gs} when not is_nil(gs) <- Connector.command(conn, ["ZSCORE", g_lane, id_g]),
         {:ok, nil} <- Connector.command(conn, ["ZSCORE", active, id_g]),
         {:ok, nil} <- Connector.command(conn, ["ZSCORE", Keyspace.queue_key(q, "pending"), id_g]),
         # THE SCOPING: h's member is STILL in active (not recovered, not touched)
         {:ok, hs} when not is_nil(hs) <- Connector.command(conn, ["ZSCORE", active, id_h]),
         {:ok, 0} <- Connector.command(conn, ["EXISTS", Keyspace.queue_key(q, "g:" <> h <> ":pending")]),
         # gactive[g] decremented to absent (HDEL at zero); gactive[h] untouched at 1
         {:ok, nil} <- Connector.command(conn, ["HGET", gactive, g]),
         {:ok, "1"} <- Connector.command(conn, ["HGET", gactive, h]),
         # the recovered member is served in g's lane, group = g unchanged, attempts 2
         {:ok, {^id_g, "g", 2, ^g}} <- Lanes.claim(conn, q, 60_000),
         # in flight again, gactive[g] honest at 1; a completion charges it back down
         {:ok, "1"} <- Connector.command(conn, ["HGET", gactive, g]),
         :ok <- Jobs.complete(conn, q, id_g, 2),
         {:ok, nil} <- Connector.command(conn, ["HGET", gactive, g]),
         # a well-formed group with no expired members recovers nothing
         {:ok, 0} <- Lanes.reap_group(conn, q, BrandedId.generate!("PRT")) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  # -- the flow family (emq.3.1) --------------------------------------------

  defp apply_scenario(:flow_add, conn, q) do
    # a single-queue flow lands atomically (emq.3.1-D2): a parent + 2 same-queue
    # children mint 3 distinct branded JOB ids, the children are claimable, and
    # the parent is held out of pending (state awaiting_children, :dependencies
    # = 2). (A cross-queue child is now ADMITTED -- emq.3.3 replaced the emq.3.1
    # reject_cross_queue/2 refusal with the cross-queue admit path; the
    # cross-queue capability is its own scenario, flow_cross_queue.)
    parent = BrandedId.generate!("JOB")
    c1 = BrandedId.generate!("JOB")
    c2 = BrandedId.generate!("JOB")
    distinct = length(Enum.uniq([parent, c1, c2])) == 3

    flow = %{
      parent: %{id: parent, payload: "P"},
      children: [%{id: c1, payload: "c1"}, %{id: c2, payload: "c2"}]
    }

    with true <- distinct,
         {:ok, {^parent, [^c1, ^c2]}} <- Flows.add(conn, q, flow),
         {:ok, "2"} <-
           Connector.command(conn, ["GET", Keyspace.job_key(q, parent) <> ":dependencies"]),
         {:ok, :awaiting_children} <- Metrics.get_job_state(conn, q, parent),
         {:ok, nil} <- Connector.command(conn, ["ZSCORE", Keyspace.queue_key(q, "pending"), parent]),
         {:ok, {first, _, 1}} when first in [c1, c2] <- Jobs.claim(conn, q, 60_000),
         {:ok, {second, _, 1}} when second in [c1, c2] and second != first <-
           Jobs.claim(conn, q, 60_000) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:flow_fanin, conn, q) do
    # the fan-in release (emq.3.1-D3): the parent stays :empty until the last
    # child completes, then is claimable; the :processed subkey records each
    # child; a double-complete of an already-completed child decrements the
    # parent's count by exactly 1 (the idempotent decrement, INV5).
    parent = BrandedId.generate!("JOB")
    c1 = BrandedId.generate!("JOB")
    c2 = BrandedId.generate!("JOB")

    flow = %{
      parent: %{id: parent, payload: "P"},
      children: [%{id: c1, payload: "c1"}, %{id: c2, payload: "c2"}]
    }

    {:ok, {^parent, [^c1, ^c2]}} = Flows.add(conn, q, flow)

    # claim + complete the first child; the parent is still held (count 1)
    {:ok, {first, _, ftok}} = Jobs.claim(conn, q, 60_000)
    :ok = Jobs.complete(conn, q, first, ftok)

    # a double-complete of the first child is refused -- the row is retired, so
    # @complete returns before the fan-in branch and decrements nothing (the
    # count stays 1, asserted below): the idempotent fan-in.
    {:error, :gone} = Jobs.complete(conn, q, first, ftok + 999)

    with {:ok, "1"} <-
           Connector.command(conn, ["GET", Keyspace.job_key(q, parent) <> ":dependencies"]),
         :empty <- claim_parent(conn, q, parent),
         {:ok, {second, _, stok}} <- Jobs.claim(conn, q, 60_000),
         :ok <- Jobs.complete(conn, q, second, stok),
         {:ok, "0"} <-
           Connector.command(conn, ["GET", Keyspace.job_key(q, parent) <> ":dependencies"]),
         {:ok, processed} when is_list(processed) <-
           Connector.command(conn, ["HKEYS", Keyspace.job_key(q, parent) <> ":processed"]),
         true <- Enum.sort(processed) == Enum.sort([first, second]),
         {:ok, :pending} <- Metrics.get_job_state(conn, q, parent),
         {:ok, {^parent, "P", 1}} <- Jobs.claim(conn, q, 60_000) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:flow_children_values, conn, q) do
    # the child-result reads (emq.3.2-D2/D3): a 2-child flow whose children
    # complete with DISTINCT results. children_values reads the parent's
    # :processed HASH back as the RESULTS keyed by child id (NOT the child-id
    # presence markers emq.3.1 wrote -- O1 closed, INV5); dependencies reads
    # the :dependencies counter down to 0 (Fork R2.A); both are PURE -- a
    # double-read leaves :dependencies + :processed byte-identical (INV2).
    parent = BrandedId.generate!("JOB")
    c1 = BrandedId.generate!("JOB")
    c2 = BrandedId.generate!("JOB")

    flow = %{
      parent: %{id: parent, payload: "P"},
      children: [%{id: c1, payload: "c1"}, %{id: c2, payload: "c2"}]
    }

    {:ok, {^parent, [^c1, ^c2]}} = Flows.add(conn, q, flow)

    # before any child completes: nothing processed, 2 outstanding
    {:ok, %{}} = Flows.children_values(conn, q, parent)
    {:ok, 2} = Flows.dependencies(conn, q, parent)

    # complete both children, each carrying a distinct result keyed to its id
    complete_with_result(conn, q)
    {:ok, 1} = Flows.dependencies(conn, q, parent)
    complete_with_result(conn, q)

    with {:ok, values} <- Flows.children_values(conn, q, parent),
         true <- values == %{c1 => "r-" <> c1, c2 => "r-" <> c2},
         {:ok, 0} <- Flows.dependencies(conn, q, parent),
         # the reads are pure: a re-read leaves the subkeys byte-identical
         {:ok, ^values} <- Flows.children_values(conn, q, parent),
         {:ok, 0} <- Flows.dependencies(conn, q, parent),
         {:ok, "0"} <-
           Connector.command(conn, ["GET", Keyspace.job_key(q, parent) <> ":dependencies"]) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:flow_cross_queue, conn, q) do
    # the cross-queue flow (emq.3.3): a parent in q, a child in a DIFFERENT
    # sub-queue (a different hashtag -> a different cluster slot, so no single
    # script spans them). The child completes to the child-slot OUTBOX
    # atomically with the active-ZREM (the drop window does not exist, INV7);
    # the parent stays HELD until the child-queue's sweep delivers the
    # decrement on the PARENT's slot (eventually-consistent, INV5); a
    # re-delivery of the same child decrements EXACTLY once (idempotent, INV6).
    cq = q <> ".xq"
    parent = BrandedId.generate!("JOB")
    child = BrandedId.generate!("JOB")

    flow = %{
      parent: %{id: parent, payload: "P"},
      children: [%{id: child, payload: "c", queue: cq}]
    }

    outbox = Keyspace.queue_key(cq, "flow:outbox")

    verdict =
      with true <- Keyspace.slot(Keyspace.job_key(q, parent)) != Keyspace.slot(Keyspace.job_key(cq, child)),
           {:ok, {^parent, [^child]}} <- Flows.add(conn, q, flow),
           # the parent is held: :dependencies = 1, awaiting_children, not pending
           {:ok, "1"} <-
             Connector.command(conn, ["GET", Keyspace.job_key(q, parent) <> ":dependencies"]),
           {:ok, :awaiting_children} <- Metrics.get_job_state(conn, q, parent),
           # the child claims + completes IN ITS OWN QUEUE
           {:ok, {^child, "c", 1}} <- Jobs.claim(conn, cq, 60_000),
           :ok <- Jobs.complete(conn, cq, child, 1, "r-" <> child),
           # emission atomic with completion (INV7): one outbox entry, child
           # gone from the child-queue active set -- BEFORE any sweep
           {:ok, 1} <- Connector.command(conn, ["LLEN", outbox]),
           {:ok, 0} <- Connector.command(conn, ["ZCARD", Keyspace.queue_key(cq, "active")]),
           # the parent is STILL held pre-sweep (eventually-consistent, INV5)
           {:ok, 1} <- Flows.dependencies(conn, q, parent),
           :empty <- claim_parent(conn, q, parent),
           # run the child-queue sweep's deliver pass: the decrement is applied
           # on the parent's slot, the parent released
           {:ok, 1} <- Pump.deliver_flow_completions(conn, cq, 100),
           {:ok, 0} <- Flows.dependencies(conn, q, parent),
           {:ok, :pending} <- Metrics.get_job_state(conn, q, parent),
           {:ok, %{^child => result}} <- Flows.children_values(conn, q, parent),
           true <- result == "r-" <> child,
           # idempotent re-delivery (INV6): re-push the same entry and re-drain
           # -- HSETNX finds the child already processed, decrements nothing. The
           # entry's FIRST field is the PARENT queue (q) -- exactly what @complete
           # emits (parent_queue, parent_id, child_id, result) -- so the deliver
           # rebuilds the parent's keys on the PARENT's slot and the guard fires.
           {:ok, _} <-
             Connector.command(conn, ["RPUSH", outbox, q <> <<0>> <> parent <> <<0>> <> child <> <<0>> <> "r-" <> child]),
           {:ok, 1} <- Pump.deliver_flow_completions(conn, cq, 100),
           {:ok, 0} <- Flows.dependencies(conn, q, parent),
           # the parent is claimable exactly once (released once, not twice)
           {:ok, {^parent, "P", 1}} <- Jobs.claim(conn, q, 60_000) do
        :ok
      else
        other -> {:fail, other}
      end

    # the child sub-queue is a DIFFERENT hashtag than q, so run/2's purge
    # (KEYS emq:{q}:*) does not reach it -- the probe purges its own child slot
    purge(conn, cq)
    verdict
  end

  # -- the flow family's failure half (emq.3.4) -----------------------------

  defp apply_scenario(:flow_fail_parent, conn, q) do
    # fail_parent_on_failure (emq.3.4-D3/D4, INV5/INV7): a flow child that DIES
    # (exhausts retries) FAILS the parent -- same-queue ATOMICALLY (one EVAL),
    # cross-queue on the SWEEP TICK (eventually-consistent). The parent moves to
    # `dead` with the child in :failed; a re-delivered cross-queue fail fails the
    # parent EXACTLY once (the :failed HSETNX guard).
    cq = q <> ".xqf"
    outbox = Keyspace.queue_key(cq, "flow:outbox")

    # SAME-QUEUE: a parent + a same-queue child (default policy fail_parent),
    # the child dies past max attempts -> the parent is dead atomically.
    sp = BrandedId.generate!("JOB")
    sc = BrandedId.generate!("JOB")
    {:ok, {^sp, [^sc]}} = Flows.add(conn, q, %{parent: %{id: sp, payload: "P"}, children: [%{id: sc, payload: "c"}]})
    {:ok, {^sc, _, 1}} = Jobs.claim(conn, q, 60_000)
    {:ok, :dead} = Jobs.retry(conn, q, sc, 1, 10, 1, "boom-sq")

    # CROSS-QUEUE: a parent in q, a child in cq with fail_parent; the death emits
    # a fail-entry atomically with the morgue transition (no drop window), the
    # parent unchanged pre-sweep, failed on the sweep tick.
    xp = BrandedId.generate!("JOB")
    xc = BrandedId.generate!("JOB")

    verdict =
      with {:ok, {^xp, [^xc]}} <-
             Flows.add(conn, q, %{
               parent: %{id: xp, payload: "P"},
               children: [%{id: xc, payload: "c", queue: cq, fail_parent_on_failure: true}]
             }),
           # the same-queue parent is DEAD with the child in :failed (atomic)
           {:ok, :dead} <- Metrics.get_job_state(conn, q, sp),
           {:ok, %{^sc => "boom-sq"}} <- hgetall(conn, Keyspace.job_key(q, sp) <> ":failed"),
           # the cross-queue child dies in its own queue
           {:ok, {^xc, _, 1}} <- Jobs.claim(conn, cq, 60_000),
           {:ok, :dead} <- Jobs.retry(conn, cq, xc, 1, 10, 1, "boom-xq"),
           # emission atomic with the morgue transition (INV8): one fail-entry on
           # {C}, the child in its own morgue -- BEFORE any sweep
           {:ok, 1} <- Connector.command(conn, ["LLEN", outbox]),
           {:ok, :dead} <- Metrics.get_job_state(conn, cq, xc),
           # the parent is STILL held pre-sweep (eventually-consistent, INV5)
           {:ok, :awaiting_children} <- Metrics.get_job_state(conn, q, xp),
           {:ok, 1} <- Flows.dependencies(conn, q, xp),
           # run the child-queue sweep's deliver pass: the parent fails on {P}
           {:ok, 1} <- Pump.deliver_flow_completions(conn, cq, 100),
           {:ok, :dead} <- Metrics.get_job_state(conn, q, xp),
           {:ok, %{^xc => "boom-xq"}} <- hgetall(conn, Keyspace.job_key(q, xp) <> ":failed"),
           # idempotent re-delivery (INV7): re-push the SAME fail-entry @retry
           # emits (leading empty field + 'fail' tag) and re-drain -- the :failed
           # HSETNX finds the child already recorded, fails the parent NO second
           # time. The entry is BYTE-FAITHFUL to @retry's xq:fp emit.
           {:ok, _} <-
             Connector.command(conn, [
               "RPUSH",
               outbox,
               fail_entry(q, xp, xc, "boom-xq", "fp")
             ]),
           {:ok, 1} <- Pump.deliver_flow_completions(conn, cq, 100),
           {:ok, %{^xc => "boom-xq"}} <- hgetall(conn, Keyspace.job_key(q, xp) <> ":failed"),
           {:ok, 1} <- hlen(conn, Keyspace.job_key(q, xp) <> ":failed") do
        :ok
      else
        other -> {:fail, other}
      end

    purge(conn, cq)
    verdict
  end

  defp apply_scenario(:flow_ignore_dep, conn, q) do
    # ignore_dependency_on_failure (emq.3.4-D3/D4/D6, INV6): a flow child that
    # dies is treated as a SATISFIED dependency -- :dependencies decremented, the
    # child recorded in :unsuccessful (NOT :processed), the parent PROCEEDS once
    # its other children finish. ignored_failures/3 reads the ignored child back;
    # children_values/3 excludes it (the two reads disjoint -- B4).
    # SAME-QUEUE: a parent + 2 children, one ignore_dependency that dies, one
    # that completes -> the parent is released, the ignored child in :unsuccessful.
    parent = BrandedId.generate!("JOB")
    ignored = BrandedId.generate!("JOB")
    good = BrandedId.generate!("JOB")

    {:ok, {^parent, [^ignored, ^good]}} =
      Flows.add(conn, q, %{
        parent: %{id: parent, payload: "P"},
        children: [
          %{id: ignored, payload: "i", ignore_dependency_on_failure: true},
          %{id: good, payload: "g"}
        ]
      })

    # claim + kill the ignored child (it is the head, mint-ordered first)
    {:ok, {^ignored, _, 1}} = Jobs.claim(conn, q, 60_000)
    {:ok, :dead} = Jobs.retry(conn, q, ignored, 1, 10, 1, "skip-me")
    # after the ignored death: deps decremented to 1, parent still held (one left)
    {:ok, 1} = Flows.dependencies(conn, q, parent)
    # claim + complete the good child -> deps 0, parent released
    {:ok, {^good, _, gtok}} = Jobs.claim(conn, q, 60_000)
    :ok = Jobs.complete(conn, q, good, gtok, "g-done")

    with {:ok, 0} <- Flows.dependencies(conn, q, parent),
         {:ok, :pending} <- Metrics.get_job_state(conn, q, parent),
         {:ok, {^parent, "P", 1}} <- Jobs.claim(conn, q, 60_000),
         # the ignored child is in :unsuccessful (its error), NOT in :processed
         {:ok, %{^ignored => "skip-me"}} <- Flows.ignored_failures(conn, q, parent),
         {:ok, values} <- Flows.children_values(conn, q, parent),
         # children_values holds ONLY the completed child (disjoint reads -- B4)
         true <- values == %{good => "g-done"},
         # the parent is NOT dead, NOT in :failed (it proceeded, not failed)
         {:ok, fail_map} <- hgetall(conn, Keyspace.job_key(q, parent) <> ":failed"),
         true <- fail_map == %{},
         # an empty parent reads {:ok, %{}}
         {:ok, %{}} <- Flows.ignored_failures(conn, q, BrandedId.generate!("JOB")) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:flow_add_bulk, conn, q) do
    # add_bulk (emq.3.4-D2): N flows in one call, each by the add/3 mechanism,
    # fail-closed PER FLOW. Three flows: two well-formed (land), one CROSS-QUEUE
    # poison flow with a non-JOB child (the parent lands first then the child
    # refuses EMQKIND -> its parent is left HELD, the flow omitted from the
    # result, the batch NOT aborted). A cross-queue poison flow is used because
    # the cross-queue add is parent-first (the parent is HELD on its slot before
    # the child is attempted -- the precise "leaves its parent held" the spec
    # names); a same-queue @enqueue_flow is atomic, so its poison leaves the
    # parent absent instead (also fail-closed -- the parent never runs -- but
    # not the HELD shape this probe asserts).
    cq = q <> ".bulkx"
    p1 = BrandedId.generate!("JOB")
    p1c = BrandedId.generate!("JOB")
    p2 = BrandedId.generate!("JOB")
    p2c = BrandedId.generate!("JOB")
    p3 = BrandedId.generate!("JOB")
    p3bad = BrandedId.generate!("ORD")

    flows = [
      %{parent: %{id: p1, payload: "P1"}, children: [%{id: p1c, payload: "a"}]},
      %{parent: %{id: p2, payload: "P2"}, children: [%{id: p2c, payload: "b"}]},
      # a CROSS-QUEUE poison flow: the parent lands held FIRST, then the non-JOB
      # child refuses EMQKIND, leaving p3 HELD (fail-closed per flow)
      %{parent: %{id: p3, payload: "P3"}, children: [%{id: p3bad, payload: "c", queue: cq}]}
    ]

    verdict =
      with {:ok, landed} <- Flows.add_bulk(conn, q, flows),
           # exactly the two well-formed flows landed, in input order
           true <- landed == [{p1, [p1c]}, {p2, [p2c]}],
           # both landed parents are held awaiting_children with deps = 1
           {:ok, :awaiting_children} <- Metrics.get_job_state(conn, q, p1),
           {:ok, :awaiting_children} <- Metrics.get_job_state(conn, q, p2),
           {:ok, 1} <- Flows.dependencies(conn, q, p1),
           {:ok, 1} <- Flows.dependencies(conn, q, p2),
           # the poison flow's parent is HELD (fail-closed per flow): present,
           # awaiting_children, never claimable -- the batch was not aborted
           {:ok, :awaiting_children} <- Metrics.get_job_state(conn, q, p3),
           # each landed flow's child is claimable
           claimed when claimed in [p1c, p2c] <- claim_id(conn, q),
           claimed2 when claimed2 in [p1c, p2c] and claimed2 != claimed <- claim_id(conn, q) do
        :ok
      else
        other -> {:fail, other}
      end

    purge(conn, cq)
    verdict
  end

  # -- the flow family's CLOSER: grandchildren / deep recursion (emq.3.5) ----

  defp apply_scenario(:flow_grandchild, conn, q) do
    # MULTI-LEVEL COMPLETION composes over the byte-frozen @complete for FREE
    # (emq.3.5-D3, INV5): a three-level flow (root -> an intermediate node -> a
    # grandchild). When the grandchild completes, the existing fan-in RELEASES
    # the node to `pending` as a REAL claimable job; claimed + completed, the
    # node's own @complete fans into the ROOT. No new completion script -- the
    # recursive ENQUEUE (add/3's nested-tree clause, D2) is what makes the tree
    # multi-level. Proved SAME-QUEUE (each hop atomic) AND CROSS-QUEUE (each hop
    # on a sweep tick, B1).
    #
    # SAME-QUEUE: root -> node -> grandchild, all in q.
    root = BrandedId.generate!("JOB")
    node = BrandedId.generate!("JOB")
    gc = BrandedId.generate!("JOB")

    {:ok, {^root, [{^node, [{^gc, []}]}]}} =
      Flows.add(conn, q, %{
        parent: %{id: root, payload: "R"},
        children: [%{id: node, payload: "N", children: [%{id: gc, payload: "G"}]}]
      })

    # both root and node are held; only the grandchild is claimable
    {:ok, :awaiting_children} = Metrics.get_job_state(conn, q, root)
    {:ok, :awaiting_children} = Metrics.get_job_state(conn, q, node)
    {:ok, 1} = Flows.dependencies(conn, q, root)
    {:ok, 1} = Flows.dependencies(conn, q, node)

    # complete the grandchild -> the node is RELEASED to pending (the free
    # recursion: an intermediate node becomes a real claimable job)
    {:ok, {^gc, "G", 1}} = Jobs.claim(conn, q, 60_000)
    :ok = Jobs.complete(conn, q, gc, 1, "g-done")

    # CROSS-QUEUE: a three-level chain across three different queues (three
    # different slots) -- each hop fans in on a sweep tick.
    nq = q <> ".xn"
    gq = q <> ".xg"
    xroot = BrandedId.generate!("JOB")
    xnode = BrandedId.generate!("JOB")
    xgc = BrandedId.generate!("JOB")

    verdict =
      with {:ok, "0"} <-
             Connector.command(conn, ["GET", Keyspace.job_key(q, node) <> ":dependencies"]),
           {:ok, :pending} <- Metrics.get_job_state(conn, q, node),
           # the root is STILL held (the node has not completed yet)
           {:ok, :awaiting_children} <- Metrics.get_job_state(conn, q, root),
           {:ok, 1} <- Flows.dependencies(conn, q, root),
           # the node carries the grandchild's result (it ran ON it -- emq.3.2)
           {:ok, %{^gc => "g-done"}} <- Flows.children_values(conn, q, node),
           # claim + complete the node -> the ROOT is released (recursion up)
           {:ok, {^node, "N", 1}} <- Jobs.claim(conn, q, 60_000),
           :ok <- Jobs.complete(conn, q, node, 1, "n-done"),
           {:ok, 0} <- Flows.dependencies(conn, q, root),
           {:ok, :pending} <- Metrics.get_job_state(conn, q, root),
           {:ok, {^root, "R", 1}} <- Jobs.claim(conn, q, 60_000),
           # --- the cross-queue three-level chain ---
           {:ok, {^xroot, [{^xnode, [{^xgc, []}]}]}} <-
             Flows.add(conn, q, %{
               parent: %{id: xroot, payload: "R"},
               children: [
                 %{id: xnode, payload: "N", queue: nq, children: [%{id: xgc, payload: "G", queue: gq}]}
               ]
             }),
           # the three nodes are on three DIFFERENT slots (the forcing constraint)
           true <- Keyspace.slot(Keyspace.job_key(q, xroot)) != Keyspace.slot(Keyspace.job_key(nq, xnode)),
           true <- Keyspace.slot(Keyspace.job_key(nq, xnode)) != Keyspace.slot(Keyspace.job_key(gq, xgc)),
           # the grandchild completes in ITS queue -> emits to gq's outbox
           {:ok, {^xgc, "G", 1}} <- Jobs.claim(conn, gq, 60_000),
           :ok <- Jobs.complete(conn, gq, xgc, 1, "xg-done"),
           # the node is still held pre-sweep (eventually-consistent, B1)
           {:ok, 1} <- Flows.dependencies(conn, nq, xnode),
           # the gq sweep delivers the decrement on the NODE's slot -> node released
           {:ok, 1} <- Pump.deliver_flow_completions(conn, gq, 100),
           {:ok, 0} <- Flows.dependencies(conn, nq, xnode),
           {:ok, :pending} <- Metrics.get_job_state(conn, nq, xnode),
           # claim + complete the node in ITS queue -> emits to nq's outbox
           {:ok, {^xnode, "N", 1}} <- Jobs.claim(conn, nq, 60_000),
           :ok <- Jobs.complete(conn, nq, xnode, 1, "xn-done"),
           # the root is still held pre-sweep
           {:ok, 1} <- Flows.dependencies(conn, q, xroot),
           # the nq sweep delivers on the ROOT's slot -> root released (recursion)
           {:ok, 1} <- Pump.deliver_flow_completions(conn, nq, 100),
           {:ok, 0} <- Flows.dependencies(conn, q, xroot),
           {:ok, :pending} <- Metrics.get_job_state(conn, q, xroot),
           {:ok, {^xroot, "R", 1}} <- Jobs.claim(conn, q, 60_000) do
        :ok
      else
        other -> {:fail, other}
      end

    # the node/grandchild sub-queues are different hashtags than q -- purge them
    purge(conn, nq)
    purge(conn, gq)
    verdict
  end

  defp apply_scenario(:flow_grandchild_fail, conn, q) do
    # the RECURSIVE FAILURE HOOK (emq.3.5-D4, INV6/INV7): a death propagates UP
    # EVERY level. A three-level fail_parent_on_failure flow -- the grandchild
    # dies, the intermediate node dies, the ROOT dies (the node in the root's
    # :failed). Proved SAME-QUEUE (the @retry sq:fp arm kills the node
    # atomically; the host re-emit propagates the node's death to the root) AND
    # CROSS-QUEUE (each hop on a sweep tick, the deliver-loop hook recursing). A
    # re-delivered death fails the root EXACTLY once (the :failed HSETNX guard).
    # A variant with ignore_dependency_on_failure at the TOP hop lets the root
    # PROCEED (the node recorded in the root's :unsuccessful).
    #
    # SAME-QUEUE: root -> node -> grandchild, all in q, all fail_parent.
    root = BrandedId.generate!("JOB")
    node = BrandedId.generate!("JOB")
    gc = BrandedId.generate!("JOB")

    {:ok, {^root, [{^node, [{^gc, []}]}]}} =
      Flows.add(conn, q, %{
        parent: %{id: root, payload: "R"},
        children: [%{id: node, payload: "N", children: [%{id: gc, payload: "G"}]}]
      })

    # kill the grandchild past max attempts via the PRODUCTION path (retry/7) ->
    # @retry's sq:fp arm fails the NODE atomically (the node moves to dead, the
    # grandchild in the node's :failed) AND retry/7 itself re-emits the node's
    # death UP into q's outbox (emq.3.5-D4, the recursive hook -- NO hand-call;
    # the host trigger fires inside retry/7). The sweep below delivers it on the
    # root's slot.
    {:ok, {^gc, _, 1}} = Jobs.claim(conn, q, 60_000)
    {:ok, :dead} = Jobs.retry(conn, q, gc, 1, 10, 1, "boom-gc")

    # CROSS-QUEUE: root in q, node in nq, grandchild in gq, all fail_parent.
    nq = q <> ".fxn"
    gq = q <> ".fxg"
    xroot = BrandedId.generate!("JOB")
    xnode = BrandedId.generate!("JOB")
    xgc = BrandedId.generate!("JOB")

    # the same-queue node is dead with the grandchild in its :failed (atomic)
    verdict =
      with {:ok, :dead} <- Metrics.get_job_state(conn, q, node),
           {:ok, %{^gc => "boom-gc"}} <- hgetall(conn, Keyspace.job_key(q, node) <> ":failed"),
           # the recursive re-emit was drained on q's own sweep: the ROOT is dead
           # with the NODE in the root's :failed (the death propagated UP a level)
           {:ok, 1} <- Pump.deliver_flow_completions(conn, q, 100),
           {:ok, :dead} <- Metrics.get_job_state(conn, q, root),
           {:ok, %{^node => "boom-gc"}} <- hgetall(conn, Keyspace.job_key(q, root) <> ":failed"),
           # --- the SAME-QUEUE 4-LEVEL chain (the recursion proof) ---
           # depth 3 finishes in ONE sweep tick (retry/7 re-emits node->root
           # directly), so it never exercises the RECURSIVE deliver-loop re-emit
           # (a node failed BY a sweep delivery re-emitting to ITS parent). A
           # 4-level same-queue chain forces TWO re-emit hops: retry/7 re-emits
           # n2->n1, then the deliver loop -- on failing n1 -- re-emits n1->root.
           :ok <- same_queue_recursion_depth4(conn, q),
           # --- the cross-queue three-level chain ---
           {:ok, {^xroot, [{^xnode, [{^xgc, []}]}]}} <-
             Flows.add(conn, q, %{
               parent: %{id: xroot, payload: "R"},
               children: [
                 %{
                   id: xnode,
                   payload: "N",
                   queue: nq,
                   fail_parent_on_failure: true,
                   children: [%{id: xgc, payload: "G", queue: gq, fail_parent_on_failure: true}]
                 }
               ]
             }),
           # the grandchild dies in gq -> a fail-entry emitted to gq's outbox
           {:ok, {^xgc, _, 1}} <- Jobs.claim(conn, gq, 60_000),
           {:ok, :dead} <- Jobs.retry(conn, gq, xgc, 1, 10, 1, "boom-xgc"),
           # the node is held pre-sweep (eventually-consistent, B1)
           {:ok, :awaiting_children} <- Metrics.get_job_state(conn, nq, xnode),
           # the gq sweep delivers the fail on the NODE's slot -> node dead; the
           # deliver-loop hook re-emits the node's death into nq's outbox
           {:ok, 1} <- Pump.deliver_flow_completions(conn, gq, 100),
           {:ok, :dead} <- Metrics.get_job_state(conn, nq, xnode),
           {:ok, %{^xgc => "boom-xgc"}} <- hgetall(conn, Keyspace.job_key(nq, xnode) <> ":failed"),
           # the root is still held pre-sweep (the node's death is in nq's outbox)
           {:ok, :awaiting_children} <- Metrics.get_job_state(conn, q, xroot),
           # the nq sweep delivers the node's death on the ROOT's slot -> root dead
           {:ok, 1} <- Pump.deliver_flow_completions(conn, nq, 100),
           {:ok, :dead} <- Metrics.get_job_state(conn, q, xroot),
           {:ok, %{^xnode => "boom-xgc"}} <- hgetall(conn, Keyspace.job_key(q, xroot) <> ":failed"),
           # idempotent re-delivery (INV7): re-push the SAME node-death fail-entry
           # the deliver-loop hook emits (BYTE-FAITHFUL via fail_entry/5 -- the
           # node is the "child", the root the parent, the node's policy 'fp') and
           # re-drain: the root's :failed HSETNX finds the node already recorded,
           # fails the root NO second time.
           {:ok, _} <-
             Connector.command(conn, [
               "RPUSH",
               Keyspace.queue_key(nq, "flow:outbox"),
               fail_entry(q, xroot, xnode, "boom-xgc", "fp")
             ]),
           {:ok, 1} <- Pump.deliver_flow_completions(conn, nq, 100),
           {:ok, 1} <- hlen(conn, Keyspace.job_key(q, xroot) <> ":failed"),
           # --- ignore_dependency_on_failure at the TOP hop: the root PROCEEDS ---
           {:ok, :ok} <- grandchild_ignore_top(conn, q) do
        :ok
      else
        other -> {:fail, other}
      end

    purge(conn, nq)
    purge(conn, gq)
    verdict
  end

  # -- Movement II groups family · the client floor (ewr.4.1) ---------------

  defp apply_scenario(:pool_enqueue, conn, q) do
    # POOL-FRONTED IDEMPOTENCY (ewr.4.1-D5, INV4/INV5): a duplicate id enqueued
    # through the pool answers :duplicate no matter which member runs it, and the
    # row + pending entry are byte-identical to a single-connector enqueue. The
    # @enqueue EXISTS refusal is server-side against the SERVER-GLOBAL state, so
    # the verdict is independent of the member -- this drives the SAME enqueue
    # through `via: Pool` and asserts via `conn` (the connector that sees the same
    # state). The pool is started with size >= 2 so round-robin spans distinct
    # members; the target is the POOL NAME (`via: Pool` is the dispatch module --
    # the EchoWire.Pipe conn/pool split, pipe.ex:75-82). The pool is stopped in
    # this scenario; run/2's purge clears the rows on `conn`'s slot.
    pool = :emq_conf_pool_enqueue
    {:ok, sup} = EchoMQ.Pool.start_link(name: pool, size: 2, port: 6390)

    verdict =
      try do
        id = BrandedId.generate!("JOB")

        with {:ok, :enqueued} <- Jobs.enqueue(pool, q, id, "cargo", via: EchoMQ.Pool),
             # the duplicate, on the NEXT member by round-robin (size 2), is
             # refused against the server-global state -- the first payload stands
             {:ok, :duplicate} <- Jobs.enqueue(pool, q, id, "again", via: EchoMQ.Pool),
             # the row read through `conn` is the three-field hash a single
             # connector would have written, the payload unchanged at "cargo"
             {:ok, row} <- Connector.command(conn, ["HGETALL", Keyspace.job_key(q, id)]),
             true <-
               pairs(row) == %{"state" => "pending", "attempts" => "0", "payload" => "cargo"},
             # exactly one pending entry for the id at score 0 (ZSCORE's wire form
             # is connection-dependent -- the float +0.0 on RESP3, "0" on RESP2)
             {:ok, s} when s in [0, "0", +0.0] <-
               Connector.command(conn, ["ZSCORE", Keyspace.queue_key(q, "pending"), id]),
             {:ok, 1} <- Connector.command(conn, ["ZCARD", Keyspace.queue_key(q, "pending")]) do
          :ok
        else
          other -> {:fail, other}
        end
      after
        Supervisor.stop(sup)
      end

    verdict
  end

  defp apply_scenario(:pool_order, conn, q) do
    # SCORE-0 MINT ORDER ACROSS POOL MEMBERS (ewr.4.1-D5, INV6): N ids minted in
    # sequence and enqueued ROUND-ROBIN through the pool browse newest-first by
    # name alone under ZRANGE REV BYLEX -- identical to a single-connector
    # enqueue. The order theorem (members are the ids, score is 0, byte order =
    # mint order) is independent of which member admitted each id. Five ids over
    # a size-2 pool distribute across both members, so the REV-BYLEX walk is a
    # real cross-member order proof. The standing ORDER-THEOREM NET-ZERO MUTATION
    # (ewr.1.1-L4): reversing/shuffling the enqueue order must break the
    # reverse-mint-order match -- the assertion below is `walked == reverse(ids)`,
    # so a shuffled enqueue order would NOT match (the mutation is killed). The
    # browse rides `conn` against the server-global pending set.
    pool = :emq_conf_pool_order
    {:ok, sup} = EchoMQ.Pool.start_link(name: pool, size: 2, port: 6390)

    verdict =
      try do
        ids = for _ <- 1..5, do: BrandedId.generate!("JOB")

        Enum.each(ids, fn id ->
          {:ok, :enqueued} = Jobs.enqueue(pool, q, id, "o", via: EchoMQ.Pool)
        end)

        case Connector.command(conn, [
               "ZRANGE",
               Keyspace.queue_key(q, "pending"),
               "+",
               "-",
               "BYLEX",
               "REV"
             ]) do
          {:ok, walked} -> if walked == Enum.reverse(ids), do: :ok, else: {:fail, walked}
          other -> {:fail, other}
        end
      after
        Supervisor.stop(sup)
      end

    verdict
  end

  defp apply_scenario(:native_lock_field, conn, q) do
    # ewr.2.6 NATIVE EXPIRY: the lock marker folded into the job hash as a `lock`
    # FIELD with its own hash-field TTL (HEXPIRE/HFE, Valkey >= 7.4). The TTL is
    # observable (HPTTL > 0) and the field SELF-CLEARS at its deadline with NO
    # sweep -- forced deterministically by HPEXPIREAT in the past (the server
    # clock), so the proof needs no real-time wait. The rest of the row survives.
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    jk = Keyspace.job_key(q, id)

    with {:ok, _} <- Connector.command(conn, ["HSET", jk, "lock", "worker-1"]),
         {:ok, _} <- Connector.command(conn, ["HEXPIRE", jk, "30", "FIELDS", "1", "lock"]),
         {:ok, 1} <- Connector.command(conn, ["HEXISTS", jk, "lock"]),
         {:ok, [ttl]} when is_integer(ttl) and ttl > 0 <-
           Connector.command(conn, ["HPTTL", jk, "FIELDS", "1", "lock"]),
         # force the deadline into the past -> the field self-clears, no sweep
         {:ok, _} <- Connector.command(conn, ["HPEXPIREAT", jk, "1", "FIELDS", "1", "lock"]),
         {:ok, 0} <- Connector.command(conn, ["HEXISTS", jk, "lock"]),
         {:ok, "pending"} <- Connector.command(conn, ["HGET", jk, "state"]) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  defp apply_scenario(:native_lock_refuses, conn, q) do
    # ewr.2.6: remove_job honors the native lock FIELD (HEXISTS jk lock), not only
    # the :lock string marker -- a job held by the field alone refuses EMQLOCK
    # untouched. When the field self-expires (forced past on the server clock, no
    # sweep), the lock self-heals and remove_job succeeds.
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    jk = Keyspace.job_key(q, id)

    with {:ok, _} <- Connector.command(conn, ["HSET", jk, "lock", "worker-1"]),
         # the field alone (no :lock string) makes remove_job refuse, untouched
         {:error, :locked} <- Jobs.remove_job(conn, q, id),
         {:ok, :pending} <- Metrics.get_job_state(conn, q, id),
         # the field self-expires -> the lock self-heals, remove_job now succeeds
         {:ok, _} <- Connector.command(conn, ["HPEXPIREAT", jk, "1", "FIELDS", "1", "lock"]),
         :ok <- Jobs.remove_job(conn, q, id),
         {:ok, :absent} <- Metrics.get_job_state(conn, q, id) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  # A three-level same-queue flow where the intermediate node's OWN policy
  # toward the root is ignore_dependency_on_failure: a fail_parent grandchild
  # kills the node, but the node's death is IGNORED by the root (recorded in the
  # root's :unsuccessful, the root's :dependencies decremented) so the root
  # PROCEEDS. Returns {:ok, :ok} or {:ok, {:fail, term}}.
  defp grandchild_ignore_top(conn, q) do
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
            # the grandchild's policy toward the NODE is fail-parent (kills node)
            children: [%{id: gc, payload: "G", fail_parent_on_failure: true}]
          }
        ]
      })

    {:ok, {^gc, _, 1}} = Jobs.claim(conn, q, 60_000)
    {:ok, :dead} = Jobs.retry(conn, q, gc, 1, 10, 1, "boom2")
    # the node died (sq:fp from the grandchild) AND retry/7 re-emitted the node's
    # death UP by the node's policy ('id') into q's outbox (NO hand-call -- the
    # production trigger fires inside retry/7); the sweep below delivers it ->
    # the root records the node in :unsuccessful + proceeds.

    result =
      with {:ok, :dead} <- Metrics.get_job_state(conn, q, node),
           {:ok, 1} <- Pump.deliver_flow_completions(conn, q, 100),
           # the root PROCEEDS (released to pending, NOT dead): deps 0, the node
           # recorded in the root's :unsuccessful (ignored), NOT in :failed
           {:ok, 0} <- Flows.dependencies(conn, q, root),
           {:ok, :pending} <- Metrics.get_job_state(conn, q, root),
           {:ok, %{^node => "boom2"}} <- Flows.ignored_failures(conn, q, root),
           {:ok, fail_map} <- hgetall(conn, Keyspace.job_key(q, root) <> ":failed"),
           true <- fail_map == %{},
           {:ok, {^root, "R", 1}} <- Jobs.claim(conn, q, 60_000) do
        :ok
      else
        other -> {:fail, other}
      end

    {:ok, result}
  end

  # A FOUR-level same-queue chain (root -> n1 -> n2 -> leaf, all in q,
  # fail_parent) -- the proof that the SAME-QUEUE recursive failure hook RECURSES
  # through the deliver loop, which a depth-3 chain cannot give (at depth 3 the
  # retry/7 trigger re-emits node->root directly in one tick). Here the death
  # takes TWO re-emit hops: retry/7 re-emits n2->n1 (hop 1), then the DELIVER
  # LOOP, on failing n1, re-emits n1->root (hop 2, the recursive hop). Returns
  # :ok or {:fail, term}.
  defp same_queue_recursion_depth4(conn, q) do
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

    # kill the leaf -> sq:fp fails n2 atomically; retry/7 re-emits n2->n1 (hop 1)
    {:ok, {^leaf, _, 1}} = Jobs.claim(conn, q, 60_000)
    {:ok, :dead} = Jobs.retry(conn, q, leaf, 1, 10, 1, "boom4")

    with {:ok, :dead} <- Metrics.get_job_state(conn, q, n2),
         # n1 + root both still held -- the death has only reached n2
         {:ok, :awaiting_children} <- Metrics.get_job_state(conn, q, n1),
         {:ok, :awaiting_children} <- Metrics.get_job_state(conn, q, root),
         # TICK 1: the deliver loop fails n1 AND re-emits n1->root (the RECURSIVE
         # hop -- n1 transitioned to dead via a sweep delivery, re-emits to root)
         {:ok, 1} <- Pump.deliver_flow_completions(conn, q, 100),
         {:ok, :dead} <- Metrics.get_job_state(conn, q, n1),
         {:ok, %{^n2 => "boom4"}} <- hgetall(conn, Keyspace.job_key(q, n1) <> ":failed"),
         # root STILL held after tick 1 (the n1->root hop is queued, not delivered)
         {:ok, :awaiting_children} <- Metrics.get_job_state(conn, q, root),
         # TICK 2: the deliver loop fails the root; root has no parent -> stop
         {:ok, 1} <- Pump.deliver_flow_completions(conn, q, 100),
         {:ok, :dead} <- Metrics.get_job_state(conn, q, root),
         {:ok, %{^n1 => "boom4"}} <- hgetall(conn, Keyspace.job_key(q, root) <> ":failed"),
         # the recursion terminated -- a 3rd tick is a no-op, root failed once
         {:ok, 0} <- Pump.deliver_flow_completions(conn, q, 100),
         {:ok, 1} <- hlen(conn, Keyspace.job_key(q, root) <> ":failed") do
      :ok
    else
      other -> {:fail, other}
    end
  end

  # Claim once and, if the returned id is NOT the parent, return it to the
  # head so the next claim sees it again -- used to assert the parent is not
  # yet a pending member without consuming a still-waiting child.
  defp claim_parent(conn, q, parent) do
    case Jobs.claim(conn, q, 60_000) do
      {:ok, {^parent, _, _}} ->
        {:fail, :parent_claimed_early}

      {:ok, {id, payload, _att}} ->
        {:ok, _} = Connector.command(conn, ["ZADD", Keyspace.queue_key(q, "pending"), "0", id])
        {:ok, _} = Connector.command(conn, ["HSET", Keyspace.job_key(q, id), "state", "pending"])
        {:ok, _} = Connector.command(conn, ["ZREM", Keyspace.queue_key(q, "active"), id])
        _ = payload
        :empty

      :empty ->
        :empty
    end
  end

  # Claim the next pending child and complete it with a DISTINCT result keyed
  # to its own id ("r-" <> id), the host-only Fork R1.B result arg threaded
  # through complete/5 into the existing ARGV[5] -- so :processed[id] holds the
  # result, not the presence marker.
  defp complete_with_result(conn, q) do
    {:ok, {id, _, tok}} = Jobs.claim(conn, q, 60_000)
    :ok = Jobs.complete(conn, q, id, tok, "r-" <> id)
    id
  end

  # -- helpers --------------------------------------------------------------

  # The cross-queue FAIL-entry as `@retry`'s cross-queue failure branch
  # (jobs.ex, the 'xq:fp'/'xq:id' arm) RPUSHes it: a LEADING EMPTY field + the
  # 'fail' tag + parent_queue + parent_id + child_id + policy + error, NUL-joined
  # (policy before error; the arbitrary-byte error LAST, the remainder -- the
  # complete-entry's result-last design) -- BYTE-FAITHFUL to the producer (the
  # emq.3.3 L-2 lesson: a hand-fabricated wire fixture counts only if it
  # byte-matches the real emit, or the deliver's guard fires on a phantom shape
  # and the test passes for the wrong reason). Used by the flow_fail_parent
  # re-delivery (idempotency) assertion.
  defp fail_entry(parent_queue, parent_id, child_id, error, policy) do
    Enum.join(["", "fail", parent_queue, parent_id, child_id, policy, error], <<0>>)
  end

  # HGETALL a hash key -> a `%{field => value}` map (RESP3 native map or the
  # RESP2 flat-list fallback), the shape children_values/3 reads. An empty/absent
  # hash reads `%{}`.
  defp hgetall(conn, key) do
    case Connector.command(conn, ["HGETALL", key]) do
      {:ok, map} when is_map(map) -> {:ok, map}
      {:ok, flat} when is_list(flat) -> {:ok, pairs(flat)}
      other -> other
    end
  end

  # HLEN a hash key -> the field count (the :failed HASH cardinality the
  # exactly-once idempotency assertion checks).
  defp hlen(conn, key), do: Connector.command(conn, ["HLEN", key])

  # Claim the next pending job and return its bare id (the bulk-add scenario
  # asserts which children are claimable, not their payloads).
  defp claim_id(conn, q) do
    case Jobs.claim(conn, q, 60_000) do
      {:ok, {id, _, _}} -> id
      other -> other
    end
  end

  # Sweep once for an occurrence of `name`, returning the minted id (the head
  # of pending) or :none. The pump's sweep, driven directly.
  defp drain_one(conn, q, name) do
    {:ok, [{^name, every, template}]} = Repeat.due(conn, q, 10)
    id = BrandedId.generate!("JOB")
    {:ok, _} = Jobs.enqueue(conn, q, id, template)
    {:ok, _} = Repeat.advance(conn, q, name, String.to_integer(every))
    id
  rescue
    MatchError -> :none
  end

  defp drain_pending(conn, q) do
    case Jobs.claim(conn, q, 60_000) do
      {:ok, {id, _, att}} ->
        Jobs.complete(conn, q, id, att)
        drain_pending(conn, q)

      :empty ->
        :ok
    end
  end

  defp client_id(conn) do
    {:ok, id} = Connector.command(conn, ["CLIENT", "ID"])
    Integer.to_string(id)
  end

  # the head of one bounded receive on a subscribed channel, or :timeout
  defp await_event(chan) do
    receive do
      {:emq_push, ["message", ^chan, payload]} -> payload
    after
      1_000 -> :timeout
    end
  end

  defp wait_reconnected(_conn, 0), do: false

  defp wait_reconnected(conn, n) do
    Process.sleep(20)

    case Connector.stats(conn).status do
      :connected -> true
      _ -> wait_reconnected(conn, n - 1)
    end
  end

  defp pairs(m) when is_map(m), do: m

  defp pairs(flat) when is_list(flat) do
    flat |> Enum.chunk_every(2) |> Map.new(fn [k, v] -> {k, v} end)
  end

  defp purge(conn, q) do
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    :ok
  end
end
