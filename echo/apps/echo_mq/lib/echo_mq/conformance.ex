defmodule EchoMQ.Conformance do
  @moduledoc """
  The bus contract as seventy-nine runnable scenarios. Each scenario drives the
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
  gactive honest), and -- since the batches family opened (emq.5.1, the batch-claim
  spine) -- the batch claim's three behaviors (a batch of size N served EXACTLY
  N oldest-mint members in mint order on one shared server-clock lease, the
  under-fill short batch / oversized-clamp / empty / queue-wide-pause semantics, and
  partial-failure isolation where one retried member leaves the rest free to
  complete -- the batch a claim unit resolved over the byte-frozen @complete/@retry,
  not a resolution unit), the shaping cadence (emq.5.2 -- the size-floor and
  latency-ceiling flush over the pure shaper, partial-failure through the
  cadence), the grouped batch (emq.5.3 -- the homogeneous affinity batch, the
  glimit-headroom ceiling, the fairness interleaving witness), and -- since the
  family CLOSED (emq.5.4) -- the RESOLVE half (the exhaustive/disjoint partition
  over a resolved batch, the dynamic-delay re-score that moves an active member
  to schedule attempts-preserved, the delay token-fence), and -- since EchoMQ
  3.0's Stream Tier opened (emq3.1, S1 the writer part 1) -- the stream-verb floor
  (stream_verbs: the five stream verbs round-trip on the certified connector over
  an emq:{q}:stream:<name> braced key, a pipelined XADD batch returns its ids in
  call order, and the in-band verbs do not disturb the out-of-band push routing
  under RESP3 -- the verbs ride the SHIPPED generic command path verb-agnostically,
  no wire edit, no new script), and -- the writer law (emq3.2, S1 the writer
  part 2) -- the append-order theorem (stream_append: EchoMQ.Stream.append mints
  an EVT-branded record id host-side and appends it under its EXPLICIT A1 xadd id
  with the branded string as the id field, N>=2 records read back in mint order
  == id-sort order, a wrong-kind record id raises before any wire with no key
  written, and a contrived out-of-order append surfaces :nonmonotonic on the
  id<=top rejection -- the append is XADD issued direct, no new script, no new
  wire class), and -- the reader law (emq3.3, S2 the readers part 1) -- the
  consumer group's at-least-once grouped delivery with crash re-delivery
  (stream_group: two EchoMQ.Stream.append branded records are group-read with
  XREADGROUP >, one XACKed and one LEFT un-acked, then a forced XAUTOCLAIM
  RE-DELIVERS the SAME un-acked branded receipt while the acked one is not
  re-claimed -- a POSITIVE re-delivery proof, the at-least-once mechanism
  EchoMQ.StreamConsumer's beat folds in, the group verbs issued direct, no new
  script, no new wire class), and -- retention as policy (emq3.4, S2 the readers
  part 2) -- the destructive trim's bounded blast radius (stream_retention:
  EchoMQ.Stream.trim/4 bounds a stream to a DECLARED window over XTRIM issued
  direct, proven POSITIVELY over BOTH forms -- entries appended INSIDE and BELOW
  a MAXLEN window and a MINID window, a trim leaves the in-window entries
  SURVIVING and the below-window entries GONE, the removed-count exact, the MINID
  floor the exact half-open [dt, ∞) edge derived from Snowflake.min_for/1; a
  no-op that deletes nothing is a LOUD failure -- INV4 -- no new script, no new
  wire class, no keyspace subkey). A port of the client conforms when it drives
  the same server to the same seventy-eight verdicts -- the scenarios are
  wire-level on purpose, so the harness ports by translation, not by faith.
  Scenarios run on per-scenario sub-queues and purge what they mint. Chapter 3.6,
  extended 3.7, then the emq.2 cluster (parity, closed at emq.2.4), then the
  emq.3 flow family (opened at emq.3.1, crossed queues at emq.3.3, failure half
  at emq.3.4, closed at emq.3.5 with grandchildren), then Movement II's groups
  family (opened at emq.4.1 with the control plane, the recovery axis at emq.4.2),
  then the batches family (opened at emq.5.1 with the batch-claim spine, shaped
  at emq.5.2, grouped at emq.5.3, closed at emq.5.4 with the partitioned finish +
  dynamic delay), then EchoMQ 3.0's Stream Tier (opened at emq3.1 with the
  stream-verb floor, the writer law at emq3.2 with the append-order theorem, the
  reader law at emq3.3 with the consumer group's at-least-once grouped delivery +
  crash re-delivery, retention as policy at emq3.4 with the destructive trim's
  bounded blast radius).
  """

  alias EchoData.BrandedId

  alias EchoMQ.BatchShaper.Core, as: ShaperCore

  alias EchoMQ.{
    Admin,
    BatchFinish,
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
    Stalled,
    Stream
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
      native_lock_refuses: "ewr.2.6: remove_job honors the native lock field -- a job held by the field alone refuses EMQLOCK untouched, and self-heals to removable once the field expires, no sweep",
      weighted_proportion: "two branded lanes weighted 3:1 and both flooded are served approximately 3:1 over a window with the lighter lane served NON-ZERO -- a higher weight serves proportionally more, never all (emq.4.4)",
      starvation_drill: "under sustained skew (one heavy lane flooded, light lanes trickling) EVERY lane's pending depth reaches zero over the drill window -- no lane starves, the capstone guarantee (emq.4.4)",
      batch_claim: "a batch claim of size N from a flooded pending set serves EXACTLY the N oldest-mint members in mint order, each at attempts 1, all leased on ONE shared server-clock deadline -- the count-variant ZPOPMIN loop inside the script, never a client multi-key pop (emq.5.1)",
      batch_claim_short: "an under-fill is a short batch: a request for N with M<N pending returns exactly M (never over-popping), an oversized request beyond the depth returns the depth, an empty pending set returns :empty, and a queue-wide pause returns :empty pending-untouched (emq.5.1)",
      batch_partial_failure: "partial-failure isolation: one member of a claimed batch retried (scheduled, last_error kept) leaves the rest free to complete; after promote a fresh batch finds ONLY the poison at attempts 2 -- the batch is a claim unit, resolved over the byte-frozen @complete/@retry, not a resolution unit (emq.5.1)",
      batch_shaping_floor: "the size-floor flush: a queue flooded to >= min_size makes the pure shaper decide {:flush, depth}, the cadence drains ONE batch of >= min_size via the byte-frozen claim_batch/4 over flat pending, settling each member -- the floor leg of min_size/timeout shaping (emq.5.2)",
      batch_shaping_timeout: "the latency-ceiling flush: a trickle of M < min_size held until timeout makes the shaper decide {:flush, M} against an INJECTED clock (the partial, < min_size); below the ceiling it is :wait; an empty window (depth 0) at the ceiling flushes nothing -- the soft floor, bounded by timeout, no real-time flake (emq.5.2)",
      batch_shaping_partial_failure: "the partial-failure isolation through the cadence: the batch handler's per-member verdict map fails one member (retried, last_error kept) and completes the rest, an ABSENT member fail-safe-retries (missing verdict), each member emitting its own per-member lifecycle event -- emq.5.1's isolation driven by the shaping consumer's verdict mapping (emq.5.2)",
      grouped_batch_affinity: "the affinity batch is HOMOGENEOUS: a ring-rotated grouped batch claim over two flooded branded lanes serves EVERY member from the ONE group the rotation landed on (the row group field and the lane both that group, never the sibling), each at attempts 1, all leased on ONE shared server-clock deadline -- the @gwclaim grouped multi-pop re-used, never the flat cross-group @bclaim (emq.5.3)",
      grouped_batch_ceiling: "the glimit headroom clamp: a lane limited to 3 and flooded 8 deep serves EXACTLY 3 in one batch (gactive == glimit == 3, never over-popping past the ceiling), a second claim answers :empty (the lane de-ringed at its ceiling) until a complete frees headroom, then the freed slot serves again -- a grouped batch never pushes a group past its concurrency ceiling (emq.5.3)",
      grouped_batch_fairness: "under sustained skew one HEAVY lane flooded deep and light lanes trickling, the ring-rotated grouped batch interleaves WITHIN a bounded EARLY window -- every light lane is served inside the first ring cycles while the heavy lane is still deep (the no-op-defeater: a FIFO/serve-heavy-first batch starves the light lanes early), and every lane drains to zero (the liveness floor) -- the emq.4.4-L1 interleaving witness for the grouped batch (emq.5.3)",
      batch_partition: "a claimed batch resolves as an EXHAUSTIVE, DISJOINT partition over its members: a mixed batch (a completed member, a retried member, a member retried PAST the cap that lands dead, a delayed member) classifies into %{completed, retried, dead, delayed} so completed ++ retried ++ dead ++ delayed is a permutation of the claimed ids and the four buckets are pairwise disjoint, dead EMERGES from the @retry {:ok, :dead} outcome (NOT a caller verdict), and an absent verdict fail-safe-retries -- the pure EchoMQ.BatchFinish classifier, never a silent complete (emq.5.4)",
      batch_delay: "the dynamic-delay re-score: a claimed (active) member delayed by ms moves to the schedule set with state scheduled and attempts PRESERVED (NOT reset to 0 -- the delay is not a failure), absent from active and invisible to claim until its server-clock score is due, then promote returns it to pending and a fresh claim mints the NEXT token (the attempt history continued, not restarted) -- the inverse of @claim: it releases the lease and mints nothing, one atomic EVAL so the member is never in neither set (emq.5.4)",
      batch_delay_stale: "the delay is token-fenced: a claimed member reaped and re-claimed by another worker (a new token) refuses the original holder's delay EMQSTALE -> {:error, :stale}, the new holder's active-set lease untouched, and the new holder's delay with the live token settles; a delay on a missing row answers {:error, :gone} -- the complete/5 / retry/7 fencing, so a stale holder cannot yank a member from its new owner (emq.5.4)",
      stream_verbs: "the stream-verb floor (emq3.1): the five stream verbs (XADD/XRANGE/XREADGROUP/XACK/XAUTOCLAIM) round-trip on the certified connector over an emq:{q}:stream:<name> braced key -- XADD answers the entry id and XRANGE reads back the EXACT appended entry, XREADGROUP (NO BLOCK) reads the group's unseen entries, XACK answers the count, XAUTOCLAIM re-claims a pending entry -- plus a pipelined XADD batch returns N ids in call order read back in mint order, and the in-band verbs do not disturb the out-of-band push routing under RESP3 (a concurrent push is still delivered on the {:emq_push, ...} seam); the verbs ride the SHIPPED generic command path verb-agnostically, no echo_wire edit, no new script -- the floor every later Stream rung stands on (emq3.1)",
      stream_append: "the writer law (emq3.2): EchoMQ.Stream.append mints an EVT-branded record id host-side and appends it under its EXPLICIT A1 xadd id (the real Unix-ms and the 22-bit node|seq tail) with the branded string as the id field -- N>=2 records read back in MINT ORDER == id-sort order (the order theorem, stream order == id sort == mint order, no second index), a wrong-kind record id RAISES before any wire with NO key written (the host-side kind door, one brand per stream), and a contrived out-of-order append surfaces {:error, :nonmonotonic} on the id<=top rejection (the liveness check, never swallowed); the append is XADD issued direct, no new script, no new wire class (emq3.2)",
      stream_group: "the reader law (emq3.3): a consumer group delivers at-least-once with crash re-delivery -- two EchoMQ.Stream.append branded records are group-read with XREADGROUP > (both enter the PEL), ONE is XACKed (retires) and ONE is LEFT un-acked, then a forced XAUTOCLAIM (min-idle 0) RE-DELIVERS the SAME un-acked branded receipt while the acked one is NOT re-claimed -- a POSITIVE re-delivery proof (an ack-everything pass is a LOUD failure), the at-least-once mechanism EchoMQ.StreamConsumer's beat folds in; the group verbs are issued DIRECT, no new script, no new wire class (emq3.3)",
      stream_retention: "retention as policy (emq3.4): EchoMQ.Stream.trim/4 bounds a stream to a DECLARED window over XTRIM issued DIRECT, the blast radius bounded POSITIVELY -- entries are appended INSIDE and BELOW a window over BOTH forms (MAXLEN keep-newest-N and MINID below-a-mint-instant-floor derived from Snowflake.min_for/1) and a trim leaves the in-window entries SURVIVING (their branded receipts still read back) while the below-window entries are GONE, the removed-count exact under = -- a real DELETION and a real SURVIVAL in the same verdict (a no-op that deletes nothing is a LOUD failure, INV4), and the MINID floor is the exact half-open [dt, ∞) edge (a dt-1ms entry trims, a dt entry survives); the trim is XTRIM issued DIRECT, no new script, no new wire class, no new keyspace subkey (the policy is BEAM-side) (emq3.4)",
      stream_archived: "the archive seam cache (emq3.5): the store-side fold consumer caches the archive watermark W (the branded EVT id of the highest-folded record) to emq:{q}:stream:<name>:archived so a POLYGLOT reader discovers the archive/live-tail seam without a store call -- a CACHE, never the source of truth (the engine's frontier is). Proven BUS-PURE + POSITIVELY (conformance is bus-only -- no engine here -- so this proves the CACHE CONTRACT, not the cross-app fold): an empty stream has no cached seam (get_archived -> :empty), a put of W reads back the EXACT W, a second put OVERWRITES it (the fold advances W each cycle), clear_archived DELetes it (the NAMED cleanup on obliterate) and get_archived answers :empty again -- a stock SET/GET/DEL over Connector.command/3, no new script, no new wire class, no keyspace grammar edit (the :archived sub rides the existing emq:{q}:stream:<name>:<sub> form) (emq3.5)",
      stream_time_travel: "time-travel as a mint-time window read (emq3.6): EchoMQ.Stream.read_window/5 reads a CLOSED [t0,t1] window over XRANGE issued DIRECT, the bounds host-computed (from = the SHIPPED minid_floor/1 lower floor, to = the NEW maxid_ceil/1 inclusive upper inverse \"<ms>-0x3FFFFF\"), proven POSITIVELY against the id-filtered truth -- EVT records minted at KNOWN, distinct instants BELOW, INSIDE, and ABOVE the window (the deterministic min_for-mint precedent) are read by a STRADDLING read_window and the result EQUALS Enum.filter(full_read, mint_instant in [t0,t1]) (the window ACTUALLY excludes the below-t0 and above-t1 records -- a window that excludes nothing is a LOUD failure, INV-TT), the bounds exact at the millisecond (a t0 record IN and a t0-1ms record OUT at the lower edge; a t1 record IN and a t1+1ms record OUT at the inclusive upper edge, INV-BOUND), read_since/4's [t0,inf) open upper agrees with the full read from t0, and no raw min_for/1 integer ever reaches the wire; the read is XRANGE issued DIRECT through the byte-frozen read/6, no new script, no new wire class, no keyspace grammar edit (the bounds are BEAM-computed) (emq3.6)"
    ]
  end

  @doc """
  Runs all scenarios against `conn`, on sub-queues of `queue`. Prints one
  CONF line per scenario and a closing tally. Returns `{:ok, n}` when all
  pass (n == 79 today -- the live total, grown by additive minor; the count is
  re-pinned in both pinning tests, `conformance_run_test.exs` `{:ok, n}` and
  `conformance_scenarios_test.exs` `@run_order`), `{:error, failed_names}`
  otherwise. The set spans the eighteen state-machine scenarios, the emq.2
  parity cluster (read / operator / watch planes + the parity closer), the
  emq.3 flow family (single-queue / cross-queue / failure-half / grandchildren),
  Movement II's groups family (the emq.4.1 control plane, the emq.4.2 group-aware
  recovery, the emq.4.4 weighted rotation + starvation drill), the batches family
  -- the emq.5.1 batch-claim spine's three (batch_claim, batch_claim_short,
  batch_partial_failure), the emq.5.2 batch-shaping cadence's three
  (batch_shaping_floor, batch_shaping_timeout, batch_shaping_partial_failure),
  the emq.5.3 grouped batch's three (grouped_batch_affinity,
  grouped_batch_ceiling, grouped_batch_fairness), the emq.5.4 resolve half's
  three (the exhaustive/disjoint partition batch_partition, the dynamic-delay
  re-score batch_delay, the delay token-fence batch_delay_stale) -- and -- since
  EchoMQ 3.0's Stream Tier opened (emq3.1) -- the stream-verb floor (stream_verbs:
  the five stream verbs round-trip on the certified connector, a pipelined XADD
  batch in call order, push-safe under RESP3) -- and the writer law (emq3.2) --
  the append-order theorem (stream_append: EchoMQ.Stream.append mints an
  EVT-branded record id and appends it under its A1 xadd id, N>=2 reads back in
  mint order == id-sort order, the host-side kind door, the :nonmonotonic
  liveness) -- and the reader law (emq3.3) -- the consumer group's at-least-once
  grouped delivery (stream_group: two branded records group-read with XREADGROUP
  >, one XACKed and one left un-acked, a forced XAUTOCLAIM re-delivers the SAME
  un-acked branded receipt -- a POSITIVE re-delivery proof, never ack-everything)
  -- and retention as policy (emq3.4) -- the destructive trim's bounded blast
  radius (stream_retention: EchoMQ.Stream.trim/4 bounds a stream to a DECLARED
  window over XTRIM issued direct, proven POSITIVELY over BOTH forms -- in-window
  entries SURVIVE and below-window entries are GONE, the removed-count exact, the
  MINID floor the exact half-open [dt, ∞) edge from Snowflake.min_for/1; a no-op
  is a LOUD failure, INV4) -- and the archive (emq3.5) -- the archive seam cache
  (stream_archived: the store-side fold consumer caches the archive watermark W
  to emq:{q}:stream:<name>:archived so a polyglot reader discovers the
  archive/live-tail seam without a store call, a CACHE never the source of truth;
  proven BUS-PURE -- an empty stream has no seam, a put reads back the EXACT W, a
  second put overwrites, clear_archived DELetes and the seam is :empty again -- a
  stock SET/GET/DEL, no new script, no new wire class, no keyspace grammar edit)
  -- and time-travel (emq3.6) -- the mint-time window read (stream_time_travel:
  EchoMQ.Stream.read_window/5 reads a CLOSED [t0,t1] window over XRANGE issued
  direct, the bounds host-computed from the SHIPPED minid_floor/1 + the new
  maxid_ceil/1 inclusive upper inverse, proven POSITIVELY against the id-filtered
  truth -- a STRADDLING window EQUALS Enum.filter(full_read, mint_instant in
  [t0,t1]) and ACTUALLY excludes the below/above records, the bounds exact at the
  millisecond, no raw min_for integer to the wire; XRANGE direct through the
  byte-frozen read/6, no new script, no new wire class, no keyspace grammar edit).
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

  defp apply_scenario(:weighted_proportion, conn, q) do
    # the weighted rotation (emq.4.4-D1, Fork B Arm 2): a lane carries a weight
    # and the rotation serves a higher-weight lane proportionally more per turn,
    # never all of it. The proof is POSITIVE and no-op-defeating: two lanes
    # weighted 3:1, both flooded far past the window, are served approximately
    # 3:1 over a window AND the lighter lane is served NON-ZERO. A weight-ignored
    # rotation serves them ~1:1 (a WEIGHT-IGNORED failure); a serve-to-exhaustion
    # rotation serves the heavy lane to zero before the light one (a STARVATION
    # failure). Both are caught by the band + the non-zero floor. Each served job
    # carries a server-clock lease (wclaim/3 leases on TIME, asserted via the
    # active set's score). The groups are branded PRT ids gated pre-wire.
    a = BrandedId.generate!("PRT")
    b = BrandedId.generate!("PRT")
    :ok = Lanes.weight(conn, q, a, 3)
    :ok = Lanes.weight(conn, q, b, 1)
    # flood both lanes far past the window (60 each; the window serves 80)
    for _ <- 1..60 do
      {:ok, :enqueued} = Lanes.enqueue(conn, q, a, BrandedId.generate!("JOB"), "wa")
      {:ok, :enqueued} = Lanes.enqueue(conn, q, b, BrandedId.generate!("JOB"), "wb")
    end

    active = Keyspace.queue_key(q, "active")

    # drive the rotation over a window, tallying serves per lane and proving
    # every served job got a TIME-derived lease (a non-nil active score)
    {counts, leased_ok} =
      Enum.reduce(1..40, {%{a => 0, b => 0}, true}, fn _, {acc, ok} ->
        case Lanes.wclaim(conn, q, 60_000) do
          {:ok, served} ->
            grp = served |> hd() |> elem(3)
            n = length(served)

            leases =
              Enum.all?(served, fn {id, _p, _att, _g} ->
                match?({:ok, s} when not is_nil(s), Connector.command(conn, ["ZSCORE", active, id]))
              end)

            {Map.update!(acc, grp, &(&1 + n)), ok and leases}

          :empty ->
            {acc, ok}
        end
      end)

    served_a = counts[a]
    served_b = counts[b]

    cond do
      not leased_ok -> {:fail, {:no_server_clock_lease, counts}}
      served_b == 0 -> {:fail, {:lighter_lane_starved, counts}}
      # the 3:1 band: A served between 2x and 4x B (weighted schemes are exactly
      # proportional only in the limit -- the band is the honest bound)
      served_a < served_b * 2 -> {:fail, {:weight_ignored, counts}}
      served_a > served_b * 4 -> {:fail, {:over_served, counts}}
      true -> :ok
    end
  end

  defp apply_scenario(:starvation_drill, conn, q) do
    # the starvation drill (emq.4.4, the CAPSTONE guarantee): under sustained
    # skew -- one HEAVY lane flooded DEEP, several LIGHT lanes trickling -- no
    # lane starves. The load-bearing no-op-defeater is INTERLEAVING within a
    # bounded EARLY window: with the heavy lane needing ~40 turns to exhaust at
    # weight 5, a FIFO / serve-heavy-to-exhaustion-first rotation serves ZERO
    # from a light lane in the first handful of turns (it is STUCK at its
    # backlog), while fair round-robin reaches BOTH light lanes within the first
    # ring cycle -- the drill goes RED under the FIFO mutation. (A terminal
    # depth-0 check alone is NOT a no-op-defeater: a drain-in-ring-order rotation
    # also empties every lane eventually, since the re-ring guard advances the
    # head as each lane empties.) The drill uses POSITIVE weights on every lane
    # (a zero-weight parked lane is the operator's pause/3, INV1, not a
    # starvation outcome); each light lane's initial depth > 0 (the liveness
    # floor); every served job is leased on the server clock (wclaim/3 over TIME).
    heavy = BrandedId.generate!("PRT")
    light1 = BrandedId.generate!("PRT")
    light2 = BrandedId.generate!("PRT")
    :ok = Lanes.weight(conn, q, heavy, 5)
    :ok = Lanes.weight(conn, q, light1, 1)
    :ok = Lanes.weight(conn, q, light2, 1)

    # flood the heavy lane DEEP (200 at weight 5 = 40 turns to exhaust alone);
    # trickle each light lane a small steady backlog
    for _ <- 1..200, do: {:ok, :enqueued} = Lanes.enqueue(conn, q, heavy, BrandedId.generate!("JOB"), "h")
    for _ <- 1..6, do: {:ok, :enqueued} = Lanes.enqueue(conn, q, light1, BrandedId.generate!("JOB"), "l1")
    for _ <- 1..6, do: {:ok, :enqueued} = Lanes.enqueue(conn, q, light2, BrandedId.generate!("JOB"), "l2")

    # the liveness floor: every light lane started with real backlog
    {:ok, 6} = Lanes.depth(conn, q, light1)
    {:ok, 6} = Lanes.depth(conn, q, light2)

    active = Keyspace.queue_key(q, "active")

    # THE INTERLEAVING WITNESS: drive a bounded 9-turn early window (3 ring
    # cycles), recording which lanes were served and proving every served job
    # carried a TIME-derived lease
    {early, leased_ok} =
      Enum.reduce(1..9, {MapSet.new(), true}, fn _, {seen, ok} ->
        case Lanes.wclaim(conn, q, 60_000) do
          {:ok, served} ->
            leases =
              Enum.all?(served, fn {id, _p, _att, _g} ->
                match?({:ok, s} when not is_nil(s), Connector.command(conn, ["ZSCORE", active, id]))
              end)

            grps = Enum.map(served, fn {_id, _p, _att, g} -> g end)
            {MapSet.union(seen, MapSet.new(grps)), ok and leases}

          :empty ->
            {seen, ok}
        end
      end)

    # drain the rest (the heavy lane's deep backlog) to prove every lane reaches
    # zero (the liveness assertion)
    Enum.reduce_while(1..120, nil, fn _, _ ->
      case Lanes.wclaim(conn, q, 60_000) do
        {:ok, _} -> {:cont, nil}
        :empty -> {:halt, nil}
      end
    end)

    cond do
      not leased_ok ->
        {:fail, :no_server_clock_lease}

      # the no-op-defeater: both light lanes were served INSIDE the early window
      not (MapSet.member?(early, light1) and MapSet.member?(early, light2)) ->
        {:fail, {:light_lane_starved_early, early}}

      true ->
        # the liveness assertion: every lane drained to zero
        with {:ok, 0} <- Lanes.depth(conn, q, heavy),
             {:ok, 0} <- Lanes.depth(conn, q, light1),
             {:ok, 0} <- Lanes.depth(conn, q, light2) do
          :ok
        else
          other -> {:fail, {:lane_not_drained, other}}
        end
    end
  end

  # The batch-claim spine (emq.5.1): a count-variant ZPOPMIN loop INSIDE the
  # script leases up to `size` heads on ONE server-clock deadline. The
  # no-op-defeater is a flooded set (K=8) claimed for size=4: EXACTLY 4 served
  # (a batch that serves fewer than size from a flooded set under-served -- a
  # LOUD failure), the 4 OLDEST-mint ids in mint order (identical to 4 sequential
  # claim/3 pops, the order theorem), each at attempts 1 (per-member HINCRBY), all
  # on the SAME active deadline (one TIME read -- distinct deadlines would mean a
  # per-member re-read). size>=2 against K>size exercises the BATCH, not the
  # single-pop path.
  defp apply_scenario(:batch_claim, conn, q) do
    size = 4
    k = 8

    ids =
      for _ <- 1..k do
        id = BrandedId.generate!("JOB")
        {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "b")
        id
      end

    case Jobs.claim_batch(conn, q, size, 60_000) do
      {:ok, members} when length(members) == size ->
        claimed = Enum.map(members, fn {id, _p, _a} -> id end)
        atts = Enum.map(members, fn {_id, _p, a} -> a end)

        deadlines =
          Enum.map(claimed, fn id ->
            case Connector.command(conn, ["ZSCORE", Keyspace.queue_key(q, "active"), id]) do
              {:ok, s} -> s
              _ -> nil
            end
          end)

        states =
          Enum.map(claimed, fn id ->
            Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "state"])
          end)

        cond do
          # the size lowest-score (oldest-mint) ids, in mint order
          claimed != Enum.take(ids, size) -> {:fail, {:not_mint_order, claimed}}
          # each member's first-claim token
          atts != List.duplicate(1, size) -> {:fail, {:attempts, atts}}
          # ONE shared lease deadline for the whole batch (a single TIME read)
          length(Enum.uniq(deadlines)) != 1 or hd(deadlines) == nil ->
            {:fail, {:not_one_shared_lease, deadlines}}

          # every served row moved to active
          Enum.any?(states, &(&1 != {:ok, "active"})) -> {:fail, {:state, states}}
          true -> :ok
        end

      other ->
        {:fail, {:under_served, other}}
    end
  end

  # The under-fill / oversized / empty / paused semantics (emq.5.1, FORK 5.1-C =
  # the short batch). The no-op-defeater: M=3 pending, a request for N=7 must
  # return EXACTLY 3 (never over-popping past the depth, never blocking, never
  # erroring); then the drained set returns :empty; then a fresh flooded-but-paused
  # queue returns :empty with the pending set UNTOUCHED (the queue-wide pause
  # honored host-side FIRST -- the claim/3 precedent).
  defp apply_scenario(:batch_claim_short, conn, q) do
    m = 3

    ids =
      for _ <- 1..m do
        id = BrandedId.generate!("JOB")
        {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "s")
        id
      end

    with {:ok, members} <- Jobs.claim_batch(conn, q, 7, 60_000),
         true <- length(members) == m or {:fail, {:short_wrong_count, members}},
         claimed = Enum.map(members, fn {id, _p, _a} -> id end),
         true <- claimed == ids or {:fail, {:short_not_mint_order, claimed}},
         # the drained set is the zero case -> :empty
         :empty <- Jobs.claim_batch(conn, q, 5, 60_000),
         # a paused queue-wide: :empty, pending untouched
         pq = q <> ".paused",
         pid = BrandedId.generate!("JOB"),
         {:ok, :enqueued} <- Jobs.enqueue(conn, pq, pid, "p"),
         :ok <- Admin.pause(conn, pq),
         :empty <- Jobs.claim_batch(conn, pq, 5, 60_000),
         {:ok, 1} <- Connector.command(conn, ["ZCARD", Keyspace.queue_key(pq, "pending")]) do
      purge(conn, pq)
      :ok
    else
      {:fail, _} = f ->
        f

      other ->
        {:fail, other}
    end
  end

  # Partial-failure isolation (emq.5.1, INV7): the batch is a CLAIM unit, not a
  # RESOLUTION unit -- resolved member-by-member over the byte-frozen
  # @complete/@retry, NO new resolution Lua. The no-op-defeater: a batch of 3,
  # member k actually FAILS (a real @retry -> scheduled, max 3 so it does not
  # dead), the other two complete -- one bad job never sinks the rest; after
  # promote a fresh batch finds ONLY k, its own token advanced to 2 (per-member
  # fencing). A stale-token resolution is refused EMQSTALE by the shipped fencing.
  defp apply_scenario(:batch_partial_failure, conn, q) do
    ids =
      for _ <- 1..3 do
        id = BrandedId.generate!("JOB")
        {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "f")
        id
      end

    with {:ok, [poison | good]} <- Jobs.claim_batch(conn, q, 3, 60_000),
         {poison_id, _p, 1} <- poison,
         true <- poison_id == hd(ids) or {:fail, {:poison_not_oldest, poison_id}},
         # the live token still settles; a stale token is refused
         {:error, :stale} <- Jobs.complete(conn, q, poison_id, 99),
         {:ok, :scheduled} <- Jobs.retry(conn, q, poison_id, 1, 5, 3, "poison"),
         # the other two complete -- each transition independent of the poison
         :ok <- complete_all(conn, q, good),
         {:ok, "scheduled"} <-
           Connector.command(conn, ["HGET", Keyspace.job_key(q, poison_id), "state"]),
         {:ok, "poison"} <-
           Connector.command(conn, ["HGET", Keyspace.job_key(q, poison_id), "last_error"]),
         true <- good_rows_retired?(conn, q, good) or {:fail, :good_not_retired},
         _ <- Process.sleep(30),
         {:ok, 1} <- Jobs.promote(conn, q, 10),
         # after promote, only the poison remains -- at attempts 2 (its own token)
         {:ok, [{^poison_id, _pp, 2}]} <- Jobs.claim_batch(conn, q, 5, 60_000) do
      :ok
    else
      {:fail, _} = f -> f
      other -> {:fail, other}
    end
  end

  # The SIZE-FLOOR flush (emq.5.2, INV-Floor+Ceiling the floor / INV-ClaimPath /
  # INV-PureCore): a queue flooded to >= min_size makes the pure shaper decide
  # {:flush, depth}; the cadence drains ONE batch of >= min_size via the
  # byte-frozen claim_batch/4 over the flat pending set, settling each member.
  # The no-op-defeater: BELOW the floor with time remaining the shaper decides
  # :wait (it does NOT flush early), and the floor flush carries the full
  # observed depth (>= min_size), in mint order, at attempts 1.
  defp apply_scenario(:batch_shaping_floor, conn, q) do
    min_size = 4
    timeout = 200
    n = 6

    ids =
      for _ <- 1..n do
        id = BrandedId.generate!("JOB")
        {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "sf")
        id
      end

    with {:ok, depth} <- Jobs.pending_size(conn, q),
         # the pure decision: below the floor (with time left) waits; at the
         # floor (here the full depth >= min_size) flushes the observed depth
         :wait <- ShaperCore.decide(min_size - 1, 0, min_size, timeout),
         {:flush, ^depth} <- ShaperCore.decide(depth, 0, min_size, timeout),
         # drive the flush exactly as BatchConsumer.flush does -- one claim_batch
         {:ok, members} <- Jobs.claim_batch(conn, q, depth, 60_000),
         true <- length(members) >= min_size or {:fail, {:below_floor, members}},
         claimed = Enum.map(members, fn {id, _p, _a} -> id end),
         true <- claimed == Enum.take(ids, length(members)) or {:fail, {:not_mint_order, claimed}},
         atts = Enum.map(members, fn {_id, _p, a} -> a end),
         true <- atts == List.duplicate(1, length(members)) or {:fail, {:attempts, atts}},
         # each member settles individually through the byte-frozen @complete
         :ok <- complete_all(conn, q, members),
         true <- good_rows_retired?(conn, q, members) or {:fail, :not_retired} do
      :ok
    else
      {:fail, _} = f -> f
      other -> {:fail, other}
    end
  end

  # The LATENCY-CEILING flush (emq.5.2, INV-Floor+Ceiling the ceiling/soft floor/
  # empty case / INV-PureCore the injected clock): a trickle of M < min_size held
  # until timeout makes the shaper decide {:flush, M} (the partial, < min_size)
  # against the INJECTED elapsed -- no real-time sleep, no flake. The
  # no-op-defeater: BELOW the ceiling the shaper waits; an EMPTY window (depth 0)
  # at the ceiling flushes NOTHING (re-open, no batch); the partial flush carries
  # EXACTLY M members (< min_size).
  defp apply_scenario(:batch_shaping_timeout, conn, q) do
    min_size = 5
    timeout = 200
    m = 2

    ids =
      for _ <- 1..m do
        id = BrandedId.generate!("JOB")
        {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "ct")
        id
      end

    with {:ok, ^m} <- Jobs.pending_size(conn, q),
         # below both floor and ceiling -> wait (the window stays open)
         :wait <- ShaperCore.decide(m, timeout - 1, min_size, timeout),
         # the ceiling fires with M < min_size -> flush the partial (exactly M)
         {:flush, ^m} <- ShaperCore.decide(m, timeout, min_size, timeout),
         # an empty window at the ceiling -> wait (no batch, re-open) -- the
         # zero-member "batch" carries no work (D2 empty case)
         :wait <- ShaperCore.decide(0, timeout, min_size, timeout),
         # drive the partial flush -- exactly M served, < min_size
         {:ok, members} <- Jobs.claim_batch(conn, q, m, 60_000),
         true <- length(members) == m or {:fail, {:partial_wrong_count, members}},
         true <- m < min_size or {:fail, :not_a_partial},
         claimed = Enum.map(members, fn {id, _p, _a} -> id end),
         true <- claimed == ids or {:fail, {:partial_not_mint_order, claimed}},
         :ok <- complete_all(conn, q, members) do
      :ok
    else
      {:fail, _} = f -> f
      other -> {:fail, other}
    end
  end

  # The partial-failure isolation THROUGH THE CADENCE (emq.5.2, INV-PartialFailure
  # / INV-Events): the batch handler's per-member verdict map fails one member,
  # completes a second, and OMITS the third -- proving the fail-safe
  # (absent -> retry "missing verdict", D2 sub-decision: unprocessed work must
  # not silently retire). The verdict map is mapped exactly as
  # BatchConsumer.settle does (the :ok members complete, the {:error} members
  # retry with their reason, the absent member retries "missing verdict"), each
  # member emitting its own per-member lifecycle event. The no-op-defeater: the
  # OMITTED member must NOT complete -- after promote a fresh batch finds BOTH
  # retried members (the poison + the missing-verdict one) at attempts 2, the
  # completed member gone.
  defp apply_scenario(:batch_shaping_partial_failure, conn, q) do
    ids =
      for _ <- 1..3 do
        id = BrandedId.generate!("JOB")
        {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "spf")
        id
      end

    with {:ok, [{poison_id, _pp, 1} = poison, {good_id, _gp, 1} = good, {miss_id, _mp, 1} = miss]} <-
           Jobs.claim_batch(conn, q, 3, 60_000),
         true <- poison_id == hd(ids) or {:fail, {:poison_not_oldest, poison_id}},
         # the per-member verdict map the batch handler returns -- the THIRD
         # member (miss_id) is DELIBERATELY OMITTED to exercise the fail-safe
         verdicts = %{poison_id => {:error, "poison"}, good_id => :ok},
         # map it exactly as BatchConsumer.settle/3 does (per-member, fail-safe
         # default for an absent member), publishing per-member events
         :ok <- settle_batch(conn, q, [poison, good, miss], verdicts),
         # the poison retried with its own reason kept
         {:ok, "scheduled"} <-
           Connector.command(conn, ["HGET", Keyspace.job_key(q, poison_id), "state"]),
         {:ok, "poison"} <-
           Connector.command(conn, ["HGET", Keyspace.job_key(q, poison_id), "last_error"]),
         # the good member completed -- its row retired
         {:ok, 0} <- Connector.command(conn, ["EXISTS", Keyspace.job_key(q, good_id)]),
         # the OMITTED member fail-safe-retried (NOT silently completed) with the
         # "missing verdict" reason -- the no-op-defeater
         {:ok, "scheduled"} <-
           Connector.command(conn, ["HGET", Keyspace.job_key(q, miss_id), "state"]),
         {:ok, "missing verdict"} <-
           Connector.command(conn, ["HGET", Keyspace.job_key(q, miss_id), "last_error"]),
         _ <- Process.sleep(30),
         {:ok, 2} <- Jobs.promote(conn, q, 10),
         # after promote, BOTH retried members remain (poison + missing-verdict),
         # the completed member gone -- each at attempts 2 (its own token)
         {:ok, reclaimed} <- Jobs.claim_batch(conn, q, 5, 60_000),
         reclaimed_ids = Enum.map(reclaimed, fn {id, _p, _a} -> id end),
         true <- Enum.sort(reclaimed_ids) == Enum.sort([poison_id, miss_id]) or
                   {:fail, {:wrong_survivors, reclaimed_ids}},
         true <- Enum.all?(reclaimed, fn {_id, _p, a} -> a == 2 end) or
                   {:fail, {:not_second_token, reclaimed}} do
      :ok
    else
      {:fail, _} = f -> f
      other -> {:fail, other}
    end
  end

  # The grouped (affinity-respecting) batch claim is HOMOGENEOUS (emq.5.3-D1,
  # INV-Affinity): a ring-rotated grouped batch serves EVERY member from the ONE
  # group the rotation landed on -- never a cross-group mix (a cross-group batch
  # is the flat @bclaim, a different rung). The no-op-defeater: TWO branded lanes
  # are flooded, one bclaim/3 is taken, and EVERY returned member's row `group`
  # field must equal the served group (and the members must all come from that
  # one lane's g:<g>:pending set, NONE from the sibling). The second proof is the
  # ONE shared server-clock lease (the @gbclaim single TIME read -- INV-ServerClock):
  # every served member carries the SAME active-set deadline (distinct deadlines
  # would mean a per-member re-read). The groups are branded PRT ids gated pre-wire.
  defp apply_scenario(:grouped_batch_affinity, conn, q) do
    a = BrandedId.generate!("PRT")
    b = BrandedId.generate!("PRT")
    # flood two lanes; the batch must draw from exactly ONE of them
    a_ids = for _ <- 1..5, do: enqueue_lane(conn, q, a, "ga")
    b_ids = for _ <- 1..5, do: enqueue_lane(conn, q, b, "gb")

    active = Keyspace.queue_key(q, "active")

    case Lanes.bclaim(conn, q, 60_000) do
      {:ok, served} when served != [] ->
        served_groups = served |> Enum.map(fn {_id, _p, _att, g} -> g end) |> Enum.uniq()
        served_ids = Enum.map(served, fn {id, _p, _att, _g} -> id end)

        # every member's ROW group field, read back independently of the tuple
        row_groups =
          served_ids
          |> Enum.map(fn id ->
            case Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "group"]) do
              {:ok, g} -> g
              _ -> nil
            end
          end)
          |> Enum.uniq()

        deadlines =
          served_ids
          |> Enum.map(fn id ->
            case Connector.command(conn, ["ZSCORE", active, id]) do
              {:ok, s} -> s
              _ -> nil
            end
          end)

        # the served group is whichever lane the rotation landed on
        g = hd(served_groups)
        sibling_ids = if g == a, do: b_ids, else: a_ids
        own_ids = if g == a, do: a_ids, else: b_ids

        cond do
          # the tuple group is homogeneous -- one group across the whole batch
          length(served_groups) != 1 -> {:fail, {:heterogeneous_tuple, served_groups}}
          # the ROW group agrees, homogeneous, and equals the served group
          row_groups != [g] -> {:fail, {:heterogeneous_row, row_groups}}
          # every served id came from the served lane's flood, none from the sibling
          not Enum.all?(served_ids, &(&1 in own_ids)) -> {:fail, {:not_from_lane, served_ids}}
          Enum.any?(served_ids, &(&1 in sibling_ids)) -> {:fail, {:from_sibling, served_ids}}
          # ONE shared lease deadline for the whole batch (a single TIME read)
          length(Enum.uniq(deadlines)) != 1 or hd(deadlines) == nil ->
            {:fail, {:not_one_shared_lease, deadlines}}

          true ->
            :ok
        end

      other ->
        {:fail, {:empty_batch, other}}
    end
  end

  # The glimit headroom clamp on the grouped batch (emq.5.3-D1, INV-Ceiling): the
  # served count increments the group's gactive by the ACTUAL number served, and
  # K is clamped by the glimit headroom so a batch NEVER pushes gactive past
  # glimit. The no-op-defeater: a lane limited to 3 and flooded 8 deep serves
  # EXACTLY 3 in one batch (an over-pop past the ceiling is a LOUD failure),
  # gactive[g] == glimit == 3, and a SECOND claim answers :empty (the lane
  # de-ringed at its ceiling, the @gbclaim k<=0 guard) -- until a complete/5 frees
  # one slot, when the freed headroom serves again. The group is a branded PRT id.
  defp apply_scenario(:grouped_batch_ceiling, conn, q) do
    g = BrandedId.generate!("PRT")
    :ok = Lanes.limit(conn, q, g, 3)
    ids = for _ <- 1..8, do: enqueue_lane(conn, q, g, "gc")

    gactive = Keyspace.queue_key(q, "gactive")

    with {:ok, served} <- Lanes.bclaim(conn, q, 60_000),
         # EXACTLY the headroom served -- never the full depth, never over the ceiling
         true <- length(served) == 3 or {:fail, {:over_or_under_popped, length(served)}},
         # the oldest-mint three, homogeneous in g (the lane is the unit)
         claimed = Enum.map(served, fn {id, _p, _att, _grp} -> id end),
         true <- claimed == Enum.take(ids, 3) or {:fail, {:not_mint_order, claimed}},
         true <- Enum.all?(served, fn {_id, _p, _att, grp} -> grp == g end) or
                   {:fail, {:not_homogeneous, served}},
         # gactive charged to the ceiling exactly (== glimit)
         {:ok, "3"} <- Connector.command(conn, ["HGET", gactive, g]),
         # the lane is de-ringed at its ceiling: a second claim serves nothing
         :empty <- Lanes.bclaim(conn, q, 60_000),
         # free one slot -> the freed headroom serves again (the ring reopened)
         {first_id, _fp, first_att, ^g} = hd(served),
         :ok <- Jobs.complete(conn, q, first_id, first_att),
         {:ok, [{next_id, _np, 1, ^g}]} <- Lanes.bclaim(conn, q, 60_000),
         # the freed slot served the NEXT oldest-mint member, not a re-serve
         true <- next_id == Enum.at(ids, 3) or {:fail, {:wrong_next, next_id}} do
      :ok
    else
      {:fail, _} = f -> f
      other -> {:fail, other}
    end
  end

  # The grouped batch preserves fairness BY CONSTRUCTION (emq.5.3-D1, INV-Fairness,
  # the emq.4.4-L1 carry): the ring-rotated grouped batch must NOT let a heavy lane
  # monopolize the ring. The load-bearing no-op-defeater is INTERLEAVING within a
  # bounded EARLY window (the starvation_drill shape, conformance.ex:1992-2073):
  # with the heavy lane flooded DEEP, a FIFO / serve-heavy-to-exhaustion rotation
  # serves ZERO from a light lane in the first handful of turns (STUCK at the heavy
  # backlog), while the fair rotation reaches BOTH light lanes within the first ring
  # cycles -- the drill goes RED under a no-rotation mutation. (A terminal depth-0
  # check ALONE is a weak no-op-defeater: a drain-in-ring-order rotation also
  # empties every lane eventually as the re-ring guard advances the head.) Each
  # light lane starts with real backlog (the liveness floor); every served member
  # is leased on the server clock (@gbclaim over TIME). Groups are branded PRT ids.
  #
  # NOTE: bclaim/3 is HEADROOM-bounded (no glimit set here), so a single batch on
  # the heavy lane would drain its whole depth in one turn -- defeating the
  # interleaving probe. A glimit on EVERY lane caps each batch to that lane's
  # ceiling per turn, so the ring must rotate to make progress across lanes; the
  # early window then witnesses the round-robin (the operator's real multi-tenant
  # config -- every tenant has a concurrency ceiling).
  defp apply_scenario(:grouped_batch_fairness, conn, q) do
    heavy = BrandedId.generate!("PRT")
    light1 = BrandedId.generate!("PRT")
    light2 = BrandedId.generate!("PRT")
    # a per-lane ceiling caps each batch per turn -> the ring must rotate to serve
    # across lanes (without it a headroom-bounded batch drains the heavy lane whole)
    :ok = Lanes.limit(conn, q, heavy, 2)
    :ok = Lanes.limit(conn, q, light1, 2)
    :ok = Lanes.limit(conn, q, light2, 2)

    # flood the heavy lane DEEP; trickle each light lane a small steady backlog
    for _ <- 1..40, do: enqueue_lane(conn, q, heavy, "h")
    for _ <- 1..4, do: enqueue_lane(conn, q, light1, "l1")
    for _ <- 1..4, do: enqueue_lane(conn, q, light2, "l2")

    # the liveness floor: every light lane started with real backlog
    {:ok, 4} = Lanes.depth(conn, q, light1)
    {:ok, 4} = Lanes.depth(conn, q, light2)

    active = Keyspace.queue_key(q, "active")

    # THE INTERLEAVING WITNESS: drive a bounded early window, recording which lanes
    # were served and proving every served member carried a TIME-derived lease.
    # A ceiling of 2 means each lane yields 2 per turn then de-rings until a
    # complete frees it -- so the batches must complete-and-reclaim to keep the
    # ring live across the window (the worker drains then settles, the real loop).
    {early, leased_ok} =
      Enum.reduce(1..9, {MapSet.new(), true}, fn _, {seen, ok} ->
        case Lanes.bclaim(conn, q, 60_000) do
          {:ok, served} ->
            leases =
              Enum.all?(served, fn {id, _p, _att, _g} ->
                match?({:ok, s} when not is_nil(s), Connector.command(conn, ["ZSCORE", active, id]))
              end)

            grps = Enum.map(served, fn {_id, _p, _att, g} -> g end)
            # settle each served member so the lane's headroom reopens for the ring
            Enum.each(served, fn {id, _p, att, _g} -> Jobs.complete(conn, q, id, att) end)
            {MapSet.union(seen, MapSet.new(grps)), ok and leases}

          :empty ->
            {seen, ok}
        end
      end)

    # drain the rest (the heavy lane's deep backlog) to prove every lane reaches
    # zero (the liveness assertion), settling each batch to keep the ring live
    Enum.reduce_while(1..200, nil, fn _, _ ->
      case Lanes.bclaim(conn, q, 60_000) do
        {:ok, served} ->
          Enum.each(served, fn {id, _p, att, _g} -> Jobs.complete(conn, q, id, att) end)
          {:cont, nil}

        :empty ->
          {:halt, nil}
      end
    end)

    cond do
      not leased_ok ->
        {:fail, :no_server_clock_lease}

      # the no-op-defeater: both light lanes were served INSIDE the early window
      not (MapSet.member?(early, light1) and MapSet.member?(early, light2)) ->
        {:fail, {:light_lane_starved_early, early}}

      true ->
        # the liveness assertion: every lane drained to zero
        with {:ok, 0} <- Lanes.depth(conn, q, heavy),
             {:ok, 0} <- Lanes.depth(conn, q, light1),
             {:ok, 0} <- Lanes.depth(conn, q, light2) do
          :ok
        else
          other -> {:fail, {:lane_not_drained, other}}
        end
    end
  end

  # The PARTITIONED FINISH (emq.5.4, INV-Partition): a claimed batch resolves as
  # an EXHAUSTIVE, DISJOINT partition over its members. A mixed batch is built --
  # a member completed (:ok), a member retried below the cap ({:error} ->
  # scheduled), a member retried AT the cap ({:error} -> the OUTCOME {:ok, :dead}
  # emerges, NOT a caller verdict), a member delayed ({:delay, ms}), and a member
  # whose verdict is OMITTED (the fail-safe -> retried) -- each resolved through
  # the real byte-frozen transition, its {verdict, outcome} collected, and
  # classified by the pure EchoMQ.BatchFinish.partition/2. The no-op-defeater:
  # the dead member must NOT report `retried` (it hit the cap), the omitted
  # member must NOT report `completed` (the fail-safe), and the buckets must be a
  # permutation of the claimed ids (exhaustive) with no overlap (disjoint).
  defp apply_scenario(:batch_partition, conn, q) do
    # five members: [done, sched, dead, delayed, omitted] in mint order. The
    # `dead` member is pre-aged to ONE attempt below its cap so the partition's
    # resolving retry (cap 1) lands it dead on its FIRST resolve here.
    ids =
      for _ <- 1..5 do
        id = BrandedId.generate!("JOB")
        {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "p")
        id
      end

    [done, sched, dead, delayed, omitted] = ids

    with {:ok, members} <- Jobs.claim_batch(conn, q, 5, 60_000),
         claimed = Enum.map(members, fn {id, _p, _a} -> id end),
         true <- claimed == ids or {:fail, {:not_mint_order, claimed}},
         tok = Map.new(members, fn {id, _p, att} -> {id, att} end),
         # the verdict map -- `omitted` is DELIBERATELY absent (the fail-safe)
         verdicts = %{
           done => :ok,
           sched => {:error, "boom"},
           dead => {:error, "gave up"},
           delayed => {:delay, 30}
         },
         # resolve each member through the real transition, collecting the
         # {verdict, outcome} pair the partition classifies (the cap for `dead`
         # is 1 so its attempts-1 retry lands {:ok, :dead}; the others use a high
         # cap so they schedule)
         resolved =
           Map.new(members, fn {id, _p, att} ->
             v = Map.get(verdicts, id, {:error, "missing verdict"})

             outcome =
               case v do
                 :ok ->
                   Jobs.complete(conn, q, id, att)

                 {:delay, ms} ->
                   Jobs.delay(conn, q, id, att, ms)

                 {:error, reason} when id == dead ->
                   Jobs.retry(conn, q, id, att, 5, 1, to_string(reason))

                 {:error, reason} ->
                   Jobs.retry(conn, q, id, att, 5, 9, to_string(reason))
               end

             {id, {v, outcome}}
           end),
         part = BatchFinish.partition(claimed, resolved),
         # EXHAUSTIVE: the four buckets are a permutation of the claimed ids
         all = part.completed ++ part.retried ++ part.dead ++ part.delayed,
         true <- Enum.sort(all) == Enum.sort(ids) or {:fail, {:not_exhaustive, part}},
         # DISJOINT: no id appears twice (the concatenation has no duplicate)
         true <- length(all) == length(Enum.uniq(all)) or {:fail, {:not_disjoint, part}},
         # the members landed in the RIGHT buckets -- dead EMERGED from the
         # outcome, the omitted member fail-safe-retried (NOT completed)
         true <- part.completed == [done] or {:fail, {:completed, part.completed}},
         true <- part.dead == [dead] or {:fail, {:dead, part.dead}},
         true <- part.delayed == [delayed] or {:fail, {:delayed, part.delayed}},
         true <-
           Enum.sort(part.retried) == Enum.sort([sched, omitted]) or
             {:fail, {:retried, part.retried}},
         # the actual at-rest states confirm the outcomes the partition reports
         {:ok, "dead"} <- Connector.command(conn, ["HGET", Keyspace.job_key(q, dead), "state"]),
         {:ok, "scheduled"} <-
           Connector.command(conn, ["HGET", Keyspace.job_key(q, sched), "state"]),
         {:ok, "scheduled"} <-
           Connector.command(conn, ["HGET", Keyspace.job_key(q, delayed), "state"]),
         {:ok, "scheduled"} <-
           Connector.command(conn, ["HGET", Keyspace.job_key(q, omitted), "state"]),
         {:ok, 0} <- Connector.command(conn, ["EXISTS", Keyspace.job_key(q, done)]),
         _ = tok do
      :ok
    else
      {:fail, _} = f -> f
      other -> {:fail, other}
    end
  end

  # The DYNAMIC-DELAY re-score (emq.5.4, INV-Delay-Rescore / INV-Delay-Atomic /
  # INV-ServerClock): a claimed (active) member at attempts 1 delayed by ms moves
  # to the SCHEDULE set -- state scheduled, attempts STILL 1 (PRESERVED, not reset
  # to 0 the way @schedule's first-write would), absent from active, invisible to
  # claim until its server-clock score is due. Then promote returns it to pending
  # and a fresh claim mints attempts 2 (the history CONTINUED, not restarted --
  # the no-op-defeater for the attempts-reset). The member is in EXACTLY one of
  # {active, schedule, pending} at every observation (the atomic re-score, never
  # the lost-member window of a host two-step).
  defp apply_scenario(:batch_delay, conn, q) do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "later")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)

    active = Keyspace.queue_key(q, "active")
    schedule = Keyspace.queue_key(q, "schedule")

    with :ok <- Jobs.delay(conn, q, id, 1, 40),
         # the row re-scored: state scheduled, attempts PRESERVED at 1
         {:ok, "scheduled"} <- Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "state"]),
         {:ok, "1"} <- Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "attempts"]),
         # in schedule, ABSENT from active (the lease released) -- exactly one set
         {:ok, score} when not is_nil(score) <- Connector.command(conn, ["ZSCORE", schedule, id]),
         {:ok, nil} <- Connector.command(conn, ["ZSCORE", active, id]),
         # invisible to claim behind the schedule fence until due
         :empty <- Jobs.claim(conn, q, 60_000),
         _ <- Process.sleep(60),
         # promote releases it back to pending on the server clock
         {:ok, 1} <- Jobs.promote(conn, q, 10),
         # a fresh claim mints attempts 2 -- the history CONTINUED, not restarted
         {:ok, {^id, "later", 2}} <- Jobs.claim(conn, q, 60_000),
         :ok <- Jobs.complete(conn, q, id, 2) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  # The DELAY TOKEN FENCE (emq.5.4, INV-Delay-Token): only the current
  # attempts-token holder may delay. A member is claimed (token 1), its lease
  # reaped and re-claimed by another worker (token 2 -- token 1 is now stale); the
  # stale token's delay is refused EMQSTALE -> {:error, :stale}, the new holder's
  # active-set lease (token 2) UNTOUCHED, and the new holder's delay with the live
  # token 2 settles (re-scores to schedule). A delay on a missing row answers
  # {:error, :gone}. The no-op-defeater: the stale delay must be REFUSED (not a
  # silent pass) and must not move the member out of the new holder's active lease.
  defp apply_scenario(:batch_delay_stale, conn, q) do
    # flush the script cache so the refusal exercises the load-and-retry path --
    # the cold-cache regression the :stale scenario guards (jobs.ex EVALSHA-first)
    {:ok, _} = Connector.command(conn, ["SCRIPT", "FLUSH"])
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 30)
    Process.sleep(60)
    # the lease lapsed -> reap returns it to pending; a re-claim mints token 2
    {:ok, 1} = Jobs.reap(conn, q)
    {:ok, {^id, _, 2}} = Jobs.claim(conn, q, 60_000)

    active = Keyspace.queue_key(q, "active")

    # the STALE token 1's delay is refused, the token-2 lease untouched
    with {:error, :stale} <- Jobs.delay(conn, q, id, 1, 50),
         {:ok, score} when not is_nil(score) <- Connector.command(conn, ["ZSCORE", active, id]),
         # the LIVE token 2's delay settles (re-scores to schedule, off active)
         :ok <- Jobs.delay(conn, q, id, 2, 50),
         {:ok, "scheduled"} <- Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "state"]),
         {:ok, nil} <- Connector.command(conn, ["ZSCORE", active, id]),
         # a delay on a MISSING row answers :gone
         {:error, :gone} <- Jobs.delay(conn, q, BrandedId.generate!("JOB"), 1, 50) do
      :ok
    else
      other -> {:fail, other}
    end
  end

  # -- the Stream Tier verb floor (emq3.1) ----------------------------------

  defp apply_scenario(:stream_verbs, conn, q) do
    # The stream-verb floor (emq3.1, S1 the writer part 1): the five stream verbs
    # round-trip on the CERTIFIED connector, a pipelined XADD batch returns its
    # ids in call order, and the in-band verbs do not disturb the out-of-band
    # push routing under RESP3 -- the floor every later Stream rung stands on.
    #
    # The verbs ride the SHIPPED generic command path (FORK 3.1-A): each is a
    # `parts` list through Connector.command/3 / pipeline/3 -- the connector is
    # already a generic RESP client (RESP.encode/1 is verb-agnostic), so the
    # verbs reach the wire with NO connector edit and NO new script. The stream
    # key is the braced emq:{q}:stream:<name> via the total queue_key/2 (a NEW
    # Section 6 type on the {q} slot, no grammar edit). The branded record id is
    # emq3.2's writer law -- this rung appends with the server `*` id, sufficient
    # to prove the plumbing. NO verb carries a BLOCK argument (FORK 3.1-D defers
    # the blocking consumer-group read to emq3.3). A vacuous round-trip (a reply
    # asserted against nothing) is a LOUD failure -- each reply is asserted
    # against the appended data.
    key = Keyspace.queue_key(q, "stream:s")

    with :ok <- stream_roundtrip(conn, key),
         :ok <- stream_group_roundtrip(conn, key),
         :ok <- stream_pipeline_batch(conn, q),
         :ok <- stream_push_safe(conn, q) do
      :ok
    end
  end

  defp apply_scenario(:stream_append, conn, q) do
    # The writer law (emq3.2, S1 the writer part 2): EchoMQ.Stream.append mints
    # an EVT-branded record id host-side and appends it under its EXPLICIT A1
    # xadd id ("<real-Unix-ms>-<22-bit node|seq tail>") with the 14-byte branded
    # string stored as the stream `id` field. Three capabilities, one verb-floor
    # scenario, all POSITIVE (a vacuous pass is a LOUD failure):
    #
    #   1. the ORDER THEOREM -- N>=2 records read back in MINT ORDER == id-sort
    #      order (stream order == id sort == mint order, no second index);
    #   2. the host-side KIND DOOR -- a wrong-kind record id RAISES before any
    #      wire, with NO key written (one brand per stream, symmetric with
    #      Keyspace.job_key/2);
    #   3. the :nonmonotonic LIVENESS -- a contrived out-of-order append surfaces
    #      {:error, :nonmonotonic} on the id<=top rejection, never swallowed.
    #
    # Driven through the PUBLIC EchoMQ.Stream surface (the harness drives the
    # real surface, not a re-implementation -- the writer has no process/timing
    # hazard that would force a deterministic mirror). The append is XADD issued
    # direct: no new script, no new wire class.
    with :ok <- stream_append_order(conn, q),
         :ok <- stream_append_kind_door(conn, q),
         :ok <- stream_append_nonmonotonic(conn, q) do
      :ok
    end
  end

  defp apply_scenario(:stream_group, conn, q) do
    # The reader law (emq3.3, S2 the readers part 1): the consumer group's
    # at-least-once grouped delivery, proven POSITIVELY by an un-acked entry
    # actually RE-DELIVERED (US7/INV9 -- a scenario that XACKs every entry and
    # asserts nothing about re-delivery is the TRD.9.1 false-green class, a LOUD
    # failure). Two EVT records are appended via EchoMQ.Stream.append (the real
    # writer's branded receipts); a group reads both with XREADGROUP ... > (the
    # entries enter the consumer's PEL); ONE is XACKed (retires from the PEL) and
    # ONE is LEFT un-acked; a forced XAUTOCLAIM (min-idle 0) re-claims the
    # un-acked entry and the SAME branded receipt returns (the at-least-once
    # mechanism the StreamConsumer's beat folds in). The verbs are issued DIRECT
    # (XGROUP / XREADGROUP / XACK / XAUTOCLAIM), no new script, no new wire class.
    with :ok <- stream_group_redeliver(conn, q) do
      :ok
    end
  end

  defp apply_scenario(:stream_retention, conn, q) do
    # Retention as policy (emq3.4, S2 the readers part 2): EchoMQ.Stream.trim/4
    # bounds a stream to a DECLARED window over XTRIM issued DIRECT. The blast
    # radius is proven POSITIVELY (the destructive-op invariant, INV4 -- a no-op
    # that deletes nothing is the TRD.9.1 false-green class, a LOUD failure): for
    # BOTH window forms the scenario appends entries INSIDE and BELOW the window,
    # trims, and asserts a real DELETION (below-window GONE) AND a real SURVIVAL
    # (in-window receipts still read back) in the SAME verdict, the removed-count
    # exact under `=`. The MINID floor is the exact half-open [dt, ∞) edge (a
    # dt-1ms entry trims, a dt entry survives), derived from Snowflake.min_for/1.
    # XTRIM is issued DIRECT: no new script, no new wire class, no keyspace subkey
    # (the policy is BEAM-side, D-3).
    with :ok <- stream_retention_maxlen(conn, q),
         :ok <- stream_retention_minid(conn, q) do
      :ok
    end
  end

  defp apply_scenario(:stream_archived, conn, q) do
    # The archive seam cache (emq3.5, S3 the memory part 1): the BUS-PURE face of
    # the archive. The store-side fold consumer (EchoStore.StreamArchive.Driver),
    # after folding a slice into the native engine and advancing the watermark W,
    # caches W to emq:{q}:stream:<name>:archived so a POLYGLOT reader discovers
    # where the archive ends and the live tail begins WITHOUT a store call -- a
    # CACHE, never the source of truth (the engine's frontier is). Conformance is
    # bus-only (no engine here), so this scenario proves the CACHE CONTRACT a
    # polyglot reader observes, NOT the cross-app fold (the fold/restore/merge is
    # the store-side ExUnit suite). Proven POSITIVELY (a vacuous pass is a LOUD
    # failure): a real put, a real read-back of the EXACT branded W, a real DEL,
    # and the post-DEL :empty -- the seam round-trips and cleans up. A stock
    # SET/GET/DEL over EchoMQ.Connector.command/3: no new script, no new wire
    # class, no keyspace grammar edit (the :archived sub rides the existing
    # emq:{q}:stream:<name>:<sub> form on the shared {q} slot).
    with :ok <- stream_archived_roundtrip(conn, q),
         :ok <- stream_archived_cleanup(conn, q) do
      :ok
    end
  end

  defp apply_scenario(:stream_time_travel, conn, q) do
    # Time-travel as a mint-time window read (emq3.6, S3 the memory part 2): the
    # BUS-PURE half. EchoMQ.Stream.read_window/5 reads a CLOSED [t0,t1] window
    # over XRANGE issued DIRECT, the bounds host-computed -- from = the SHIPPED
    # minid_floor/1 lower floor, to = the NEW maxid_ceil/1 inclusive upper
    # inverse "<ms>-0x3FFFFF" (the largest id mintable at-or-before t1). Proven
    # POSITIVELY against the id-filtered truth (INV-TT/INV-BOUND -- a window that
    # excludes nothing is the TRD.9.1 false-green class, a LOUD failure): EVT
    # records minted at KNOWN, distinct instants BELOW, INSIDE, and ABOVE the
    # window (the deterministic min_for-mint, the stream_retention_minid
    # precedent) are read by a STRADDLING read_window and the result EQUALS
    # Enum.filter(full_read, mint_instant in [t0,t1]) -- the window ACTUALLY
    # excludes the below-t0 and above-t1 records. The bounds are exact at the
    # millisecond (the lower floor: a t0 record IN, a t0-1ms record OUT; the
    # inclusive upper: a t1 record IN, a t1+1ms record OUT). read_since/4's
    # [t0,inf) open upper agrees with the full read from t0. No raw min_for/1
    # integer ever reaches the wire (the F-1-class discipline). XRANGE is issued
    # DIRECT through the byte-frozen read/6: no new script, no new wire class, no
    # keyspace grammar edit (the bounds are BEAM-computed, D-2 Arm 5).
    with :ok <- stream_time_travel_window(conn, q),
         :ok <- stream_time_travel_edges(conn, q),
         :ok <- stream_time_travel_since(conn, q) do
      :ok
    end
  end

  # Append one EVT record at a CONTROLLED, KNOWN mint instant `dt`: the branded
  # id's snowflake IS min_for(dt) (seq 0 at that ms), so its mint instant is
  # exactly `dt` (Snowflake.to_datetime(min_for(dt)) == dt) -- the deterministic
  # mint the bus-side time-travel assertions stand on (no next_branded live-clock
  # hazard; the window straddle is exact by construction). The
  # stream_retention_append_at precedent.
  defp time_travel_append_at(conn, q, name, %DateTime{} = dt) do
    branded = BrandedId.encode!("EVT", EchoData.Snowflake.min_for(dt))
    ok!(Stream.append_id(conn, q, name, branded, [{"at", DateTime.to_iso8601(dt)}]))
  end

  # The mint instant of a branded EVT id (its snowflake -> DateTime) -- the
  # id-filter the window read is asserted EQUAL to (INV-TT).
  defp time_travel_instant(branded) do
    {:ok, "EVT", snow} = BrandedId.parse(branded)
    EchoData.Snowflake.to_datetime(snow)
  end

  # (1) INV-TT the straddle: records BELOW t0, INSIDE [t0,t1], and ABOVE t1; a
  # read_window over [t0,t1] returns EXACTLY the inside records in mint order,
  # EQUAL to the id-filtered full read (the window actually EXCLUDES the below
  # and above records -- never a vacuous all-or-nothing read).
  defp stream_time_travel_window(conn, q) do
    t0 = ~U[2025-05-01 09:00:00.000Z]
    t1 = ~U[2025-05-01 09:00:00.300Z]

    below = for d <- 3..1//-1, do: time_travel_append_at(conn, q, "tt", shift_ms(t0, -d))
    inside = for ms <- [0, 100, 300], do: time_travel_append_at(conn, q, "tt", shift_ms(t0, ms))
    above = for d <- 1..3, do: time_travel_append_at(conn, q, "tt", shift_ms(t1, d))

    with {:ok, full} <- Stream.read(conn, q, "tt"),
         full_ids = for({b, _f} <- full, do: b),
         # the id-filtered truth: the full read filtered by each id's mint instant.
         filtered = for(b <- full_ids, DateTime.compare(time_travel_instant(b), t0) != :lt and DateTime.compare(time_travel_instant(b), t1) != :gt, do: b),
         {:ok, win} <- Stream.read_window(conn, q, "tt", t0, t1),
         win_ids = for({b, _f} <- win, do: b),
         # the window read EQUALS the id-filter, in mint order.
         true <- win_ids == filtered,
         true <- win_ids == inside,
         # the window ACTUALLY excludes (the no-vacuous-pass proof): no below, no above.
         true <- Enum.all?(below, fn b -> b not in win_ids end),
         true <- Enum.all?(above, fn b -> b not in win_ids end),
         # and it is a STRICT subset of the full read (the bounds filtered).
         true <- length(win_ids) < length(full_ids) do
      :ok
    else
      other -> {:fail, {:time_travel_window, other}}
    end
  end

  # (2) INV-BOUND the exact-ms edges: the lower floor (a t0 record IN, a t0-1ms
  # record OUT) and the INCLUSIVE upper (a t1 record IN, a t1+1ms record OUT) --
  # the maxid_ceil "<ms>-0x3FFFFF" admits any seq at t1's ms and excludes the
  # first id of t1+1ms; never a raw min_for integer to the wire.
  defp stream_time_travel_edges(conn, q) do
    t0 = ~U[2025-06-10 06:30:00.000Z]
    t1 = ~U[2025-06-10 06:30:00.250Z]

    e_lo_out = time_travel_append_at(conn, q, "tte", shift_ms(t0, -1))
    e_lo_in = time_travel_append_at(conn, q, "tte", t0)
    e_hi_in = time_travel_append_at(conn, q, "tte", t1)
    e_hi_out = time_travel_append_at(conn, q, "tte", shift_ms(t1, 1))

    with {:ok, win} <- Stream.read_window(conn, q, "tte", t0, t1),
         ids = for({b, _f} <- win, do: b),
         # the lower edge is exact (the half-open floor minid_floor proves): t0 IN, t0-1ms OUT.
         true <- e_lo_in in ids,
         true <- e_lo_out not in ids,
         # the upper edge is exact + INCLUSIVE (maxid_ceil): t1 IN, t1+1ms OUT.
         true <- e_hi_in in ids,
         true <- e_hi_out not in ids,
         # the window is exactly the two in-edge records (nothing else).
         true <- ids == [e_lo_in, e_hi_in],
         # no raw min_for integer reaches the wire: the bound is "ms-seq", never the snowflake int.
         floor = Stream.minid_floor(t0),
         ceil = Stream.maxid_ceil(t1),
         true <- floor == "#{EchoData.Snowflake.unix_ms(EchoData.Snowflake.min_for(t0))}-0",
         true <- ceil == "#{EchoData.Snowflake.unix_ms(EchoData.Snowflake.min_for(t1))}-#{0x3FFFFF}",
         true <- floor != Integer.to_string(EchoData.Snowflake.min_for(t0)) do
      :ok
    else
      other -> {:fail, {:time_travel_edges, other}}
    end
  end

  # (3) read_since/4 the open [t0,inf) upper: everything at-or-after t0 (the
  # below-t0 records excluded), agreeing with the full read filtered from t0.
  defp stream_time_travel_since(conn, q) do
    t0 = ~U[2025-07-01 00:00:00.100Z]

    below = for d <- 2..1//-1, do: time_travel_append_at(conn, q, "tts", shift_ms(t0, -d))
    at_or_after = for ms <- [0, 50, 200], do: time_travel_append_at(conn, q, "tts", shift_ms(t0, ms))

    with {:ok, since} <- Stream.read_since(conn, q, "tts", t0),
         ids = for({b, _f} <- since, do: b),
         # everything at-or-after t0 (the half-open [t0,inf) floor), in mint order.
         true <- ids == at_or_after,
         # the below-t0 records are EXCLUDED (the floor filters the open lower edge).
         true <- Enum.all?(below, fn b -> b not in ids end) do
      :ok
    else
      other -> {:fail, {:time_travel_since, other}}
    end
  end

  # (1) the order theorem: N EVT records append (the branded receipt), read back
  # in MINT order == id-sort order, payloads in append order -- the writer law's
  # whole point, asserted against the appended data (N>=2, never a vacuous read).
  defp stream_append_order(conn, q) do
    n = 5
    receipts = for i <- 1..n, do: ok!(Stream.append(conn, q, "wl", [{"seq", "v#{i}"}]))

    with {:ok, read} <- Stream.read(conn, q, "wl"),
         brandeds = for({b, _f} <- read, do: b),
         true <- brandeds == receipts,
         true <- brandeds == Enum.sort(receipts),
         vals = for({_b, f} <- read, do: Map.get(f, "seq")),
         true <- vals == for(i <- 1..n, do: "v#{i}"),
         true <- Enum.all?(receipts, &(BrandedId.namespace(&1) == "EVT")) do
      :ok
    else
      other -> {:fail, {:order, other}}
    end
  end

  # (2) the host-side kind door: a wrong-namespace record id RAISES before any
  # wire (the stream key stays ABSENT -- the raise is policy before existence
  # before write); a valid EVT append on the SAME stream then succeeds.
  defp stream_append_kind_door(conn, q) do
    ord = BrandedId.generate!("ORD")
    key = Stream.stream_key(q, "kd")

    raised =
      try do
        Stream.append_id(conn, q, "kd", ord, [{"f", "v"}])
        false
      rescue
        ArgumentError -> true
      end

    with true <- raised,
         {:ok, 0} <- Connector.command(conn, ["EXISTS", key]),
         {:ok, _branded} <- Stream.append(conn, q, "kd", [{"f", "v"}]) do
      :ok
    else
      other -> {:fail, {:kind_door, other}}
    end
  end

  # (3) the :nonmonotonic liveness: two EVT ids minted in mint order (older
  # first) appended OUT of order -- the newer lands, the older's A1 id is then
  # below the stream top, so Valkey rejects it and the writer SURFACES
  # {:error, :nonmonotonic} (never swallowed, never retried with `*`). The
  # rejected append wrote nothing (XLEN == 1).
  defp stream_append_nonmonotonic(conn, q) do
    older = BrandedId.generate!("EVT")
    newer = BrandedId.generate!("EVT")
    key = Stream.stream_key(q, "nm")

    with true <- older < newer,
         {:ok, ^newer} <- Stream.append_id(conn, q, "nm", newer, [{"f", "v"}]),
         {:error, :nonmonotonic} <- Stream.append_id(conn, q, "nm", older, [{"f", "v"}]),
         {:ok, 1} <- Connector.command(conn, ["XLEN", key]) do
      :ok
    else
      other -> {:fail, {:nonmonotonic, other}}
    end
  end

  # The reader law's POSITIVE re-delivery proof (emq3.3, US7/INV9): append two
  # EVT records (the real writer's branded receipts), read the group so both
  # enter the consumer's PEL, XACK ONE and LEAVE ONE un-acked, then force an
  # XAUTOCLAIM (min-idle 0) and assert the SAME un-acked branded receipt returns
  # while the acked one does NOT. A vacuous ack-everything pass is impossible
  # here: the un-acked entry MUST re-appear in the claimed set, or the scenario
  # FAILS. The branded id (the stored "id" field) is correlated to its xadd id
  # (the wire position used for XACK / XAUTOCLAIM) so the assertion is on the
  # canonical receipt, not the volatile wire id.
  defp stream_group_redeliver(conn, q) do
    key = Stream.stream_key(q, "rg")
    keep_branded = ok!(Stream.append(conn, q, "rg", [{"seq", "keep"}]))
    hold_branded = ok!(Stream.append(conn, q, "rg", [{"seq", "hold"}]))

    with {:ok, "OK"} <- Connector.command(conn, ["XGROUP", "CREATE", key, "grp", "0"]),
         {:ok, read} <-
           Connector.command(conn, ["XREADGROUP", "GROUP", "grp", "c1", "COUNT", "10", "STREAMS", key, ">"]),
         entries when is_list(entries) and length(entries) == 2 <- stream_entries(read, key),
         pairs = for([xid, kv] <- entries, do: {field_value(kv, "id"), xid}),
         {:ok, keep_xid} <- fetch_xid(pairs, keep_branded),
         {:ok, hold_xid} <- fetch_xid(pairs, hold_branded),
         # XACK the keep entry (retires from the PEL); LEAVE the hold entry
         {:ok, 1} <- Connector.command(conn, ["XACK", key, "grp", keep_xid]),
         # force the re-claim of the un-acked hold entry (min-idle 0) to c2
         {:ok, [_cursor, claimed | _]} <-
           Connector.command(conn, ["XAUTOCLAIM", key, "grp", "c2", "0", "0", "COUNT", "10"]),
         claimed_brandeds = for([_xid, kv] <- claimed, do: field_value(kv, "id")),
         # the un-acked hold entry RE-DELIVERED (the SAME branded receipt); the
         # acked keep entry is NOT re-claimed (it left the PEL) -- a positive
         # re-delivery proof, never an ack-everything no-op.
         true <- hold_branded in claimed_brandeds,
         false <- keep_branded in claimed_brandeds,
         _ = keep_xid,
         _ = hold_xid do
      :ok
    else
      other -> {:fail, {:stream_group, other}}
    end
  end

  # the MAXLEN form: append K, trim to keep the newest M (= exact), assert the
  # K-M oldest GONE and the M newest SURVIVING in mint order, removed == K-M.
  defp stream_retention_maxlen(conn, q) do
    k = 6
    keep = 2
    receipts = for i <- 1..k, do: ok!(Stream.append(conn, q, "ret_ml", [{"seq", "v#{i}"}]))
    {below, in_window} = Enum.split(receipts, k - keep)

    with {:ok, removed} <- Stream.trim(conn, q, "ret_ml", {:maxlen, keep, false}),
         true <- removed == k - keep,
         {:ok, read} <- Stream.read(conn, q, "ret_ml"),
         survivors = for({b, _f} <- read, do: b),
         # a real SURVIVAL: every in-window receipt still reads back, in order.
         true <- survivors == in_window,
         # a real DELETION: every below-window receipt is gone (not a no-op).
         true <- Enum.all?(below, fn b -> b not in survivors end) do
      :ok
    else
      other -> {:fail, {:retention_maxlen, other}}
    end
  end

  # the MINID form: append entries below AND at/above a mint instant (CHOSEN
  # milliseconds via Snowflake.min_for/1, ascending mint order), trim by
  # MINID(dt), assert the below-floor GONE and the at/above-floor SURVIVING --
  # plus the exact half-open edge (the dt entry survives, its ms == the floor).
  defp stream_retention_minid(conn, q) do
    dt = ~U[2025-03-01 12:00:00.500Z]
    below = for d <- 3..1//-1, do: stream_retention_append_at(conn, q, "ret_mi", shift_ms(dt, -d))
    at_or_above = for d <- 0..2, do: stream_retention_append_at(conn, q, "ret_mi", shift_ms(dt, d))

    with {:ok, removed} <- Stream.trim(conn, q, "ret_mi", {:minid, dt, false}),
         # exact accounting under `=`: exactly the below-floor entries removed.
         true <- removed == length(below),
         {:ok, read} <- Stream.read(conn, q, "ret_mi"),
         survivors = for({b, _f} <- read, do: b),
         # the below-floor entries are GONE; the at/above-floor SURVIVE (the
         # half-open edge: the dt entry, ms == the floor ms, survives).
         true <- Enum.all?(below, fn b -> b not in survivors end),
         true <- Enum.all?(at_or_above, fn b -> b in survivors end),
         # the floor is derived from min_for/1, never the raw snowflake integer.
         ms = EchoData.Snowflake.unix_ms(EchoData.Snowflake.min_for(dt)),
         true <- Stream.minid_floor(dt) == "#{ms}-0" do
      :ok
    else
      other -> {:fail, {:retention_minid, other}}
    end
  end

  # append an EVT record minted at a CHOSEN millisecond instant `dt` via the
  # writer's caller-supplied-id path (Snowflake.min_for/1 -> the snowflake at
  # dt's ms, tail 0) -- so the floor edge is exact and seed-independent.
  defp stream_retention_append_at(conn, q, name, %DateTime{} = dt) do
    branded = BrandedId.encode!("EVT", EchoData.Snowflake.min_for(dt))
    ok!(Stream.append_id(conn, q, name, branded, [{"at", DateTime.to_iso8601(dt)}]))
  end

  defp shift_ms(%DateTime{} = dt, ms), do: DateTime.add(dt, ms, :millisecond)

  # The seam-cache round-trip (emq3.5): an empty stream has NO cached seam
  # (get_archived -> :empty); a put of a real EVT watermark W reads back the
  # EXACT W (the polyglot seam a non-BEAM reader reads); a SECOND put OVERWRITES
  # it (the fold advances W each cycle). All POSITIVE (the put/get is asserted
  # against the appended W, never a vacuous read).
  defp stream_archived_roundtrip(conn, q) do
    name = "arc"
    w1 = BrandedId.generate!("EVT")
    w2 = BrandedId.generate!("EVT")

    with :empty <- Stream.get_archived(conn, q, name),
         {:ok, "OK"} <- Stream.put_archived(conn, q, name, w1),
         {:ok, ^w1} <- Stream.get_archived(conn, q, name),
         {:ok, "OK"} <- Stream.put_archived(conn, q, name, w2),
         {:ok, ^w2} <- Stream.get_archived(conn, q, name) do
      :ok
    else
      other -> {:fail, {:archived_roundtrip, other}}
    end
  end

  # The seam-cache cleanup (emq3.5): clear_archived DELetes the cached seam (the
  # NAMED cleanup on stream obliterate, so no stale seam outlives the stream),
  # after which get_archived answers :empty again -- the seam is GONE, not stale.
  defp stream_archived_cleanup(conn, q) do
    name = "arc_clr"
    w = BrandedId.generate!("EVT")

    with {:ok, "OK"} <- Stream.put_archived(conn, q, name, w),
         {:ok, ^w} <- Stream.get_archived(conn, q, name),
         {:ok, 1} <- Stream.clear_archived(conn, q, name),
         :empty <- Stream.get_archived(conn, q, name),
         {:ok, 0} <- Stream.clear_archived(conn, q, name) do
      :ok
    else
      other -> {:fail, {:archived_cleanup, other}}
    end
  end

  # the entry list off an XREADGROUP reply for `key` (RESP3 map or RESP2 nested
  # array stream->entries form) -- the full [[xid, kv], ...] list, [] if absent.
  defp stream_entries(reply, key) when is_map(reply) do
    case Map.get(reply, key) do
      entries when is_list(entries) -> entries
      _ -> []
    end
  end

  defp stream_entries(reply, key) when is_list(reply) do
    case List.keyfind(reply, key, 0) do
      {^key, entries} when is_list(entries) -> entries
      _ -> []
    end
  end

  defp stream_entries(_reply, _key), do: []

  # the xadd id paired with `branded` in the [{branded, xid}, ...] list.
  defp fetch_xid(pairs, branded) do
    case List.keyfind(pairs, branded, 0) do
      {^branded, xid} -> {:ok, xid}
      _ -> {:error, {:no_xid, branded}}
    end
  end

  # the value of field `target` in a flat [k, v, k, v, ...] XADD field list.
  defp field_value([k, v | _], k), do: v
  defp field_value([_k, _v | rest], target), do: field_value(rest, target)
  defp field_value(_, _), do: nil

  # unwrap a {:ok, v} append (the scenario aborts loudly on any other shape).
  defp ok!({:ok, v}), do: v

  # US1 -- XADD then XRANGE reads back the EXACT appended entry. The XADD reply is
  # the server-minted "<ms>-<seq>" id; XRANGE - + answers the nested array
  # [[id, [field, value]]] (parsed by RESP.parse/1's array branch).
  defp stream_roundtrip(conn, key) do
    with {:ok, id} when is_binary(id) <- Connector.command(conn, ["XADD", key, "*", "field", "value"]),
         true <- id =~ ~r/^\d+-\d+$/,
         {:ok, [[^id, ["field", "value"]]]} <- Connector.command(conn, ["XRANGE", key, "-", "+"]) do
      :ok
    else
      other -> {:fail, {:roundtrip, other}}
    end
  end

  # US1 -- the consumer-group verbs (NO BLOCK): XGROUP CREATE (non-blocking
  # setup), XREADGROUP reads the group's unseen entries for c1 (the entry now
  # pending against c1), XACK answers the genuinely-pending count 1, and
  # XAUTOCLAIM (min-idle-time 0) re-claims a pending entry to c2 -- the
  # [cursor, claimed, deleted] triple, the claimed entry positively the one c1 left.
  defp stream_group_roundtrip(conn, key) do
    gkey = key <> ":g"

    with {:ok, id} <- Connector.command(conn, ["XADD", gkey, "*", "k", "v"]),
         {:ok, "OK"} <- Connector.command(conn, ["XGROUP", "CREATE", gkey, "grp", "0"]),
         {:ok, read} <-
           Connector.command(conn, ["XREADGROUP", "GROUP", "grp", "c1", "COUNT", "10", "STREAMS", gkey, ">"]),
         ^id <- stream_entry_id(read, gkey),
         {:ok, 1} <- Connector.command(conn, ["XACK", gkey, "grp", id]),
         {:ok, id2} <- Connector.command(conn, ["XADD", gkey, "*", "k2", "v2"]),
         {:ok, _} <-
           Connector.command(conn, ["XREADGROUP", "GROUP", "grp", "c1", "COUNT", "10", "STREAMS", gkey, ">"]),
         {:ok, [_cursor, claimed, _deleted]} <-
           Connector.command(conn, ["XAUTOCLAIM", gkey, "grp", "c2", "0", "0"]),
         true <- Enum.any?(claimed, fn [cid | _] -> cid == id2 end) do
      :ok
    else
      other -> {:fail, {:group_roundtrip, other}}
    end
  end

  # US2 -- a pipelined XADD batch through the shipped Connector.pipeline/3: N (>= 2)
  # appends in one pipeline return N ids in call order; XRANGE reads back exactly
  # N entries in mint order (the server * ids are monotonic), payloads v1..vN.
  # The connector is the SOLE owner of the wire (no second pipelining mechanism).
  defp stream_pipeline_batch(conn, q) do
    key = Keyspace.queue_key(q, "stream:batch")
    n = 4
    cmds = for i <- 1..n, do: ["XADD", key, "*", "seq", "v#{i}"]

    with {:ok, ids} when length(ids) == n <- Connector.pipeline(conn, cmds),
         true <- Enum.all?(ids, &is_binary/1),
         {:ok, entries} when length(entries) == n <- Connector.command(conn, ["XRANGE", key, "-", "+"]),
         read_ids = for([eid | _] <- entries, do: eid),
         true <- read_ids == ids,
         read_vals = for([_eid, ["seq", v]] <- entries, do: v),
         true <- read_vals == for(i <- 1..n, do: "v#{i}") do
      :ok
    else
      other -> {:fail, {:pipeline_batch, other}}
    end
  end

  # US3 -- push-safety under RESP3: an in-band XADD/XRANGE/XACK sequence on a
  # SUBSCRIBED RESP3 connection round-trips WHILE a concurrent push is published
  # (out of band, on the EchoMQ.Events seam). The stream replies stay correct (the
  # FIFO aligned) AND the push is still delivered as {:emq_push, ...}, never
  # enqueued on the reply FIFO. NO verb carries a BLOCK argument (FORK 3.1-D). The
  # subscriber rides its OWN disposable connection (stopped at the end).
  defp stream_push_safe(conn, q) do
    key = Keyspace.queue_key(q, "stream:ps")
    chan = Events.channel(q)
    {:ok, sub} = Connector.start_link(port: 6390, protocol: 3, push_to: self())
    :ok = Connector.subscribe(sub, chan)
    # let the SUBSCRIBE land before the publish (no lost-wakeup race)
    Process.sleep(50)

    verdict =
      with {:ok, id} <- Connector.command(sub, ["XADD", key, "*", "f", "v"]),
           true <- id =~ ~r/^\d+-\d+$/,
           # the concurrent push on the PASSED conn (the publisher) -- out of band
           {:ok, 1} <- Connector.command(conn, ["PUBLISH", chan, "ping"]),
           # in-band XRANGE on the SAME subscribed connection -- the FIFO aligned
           {:ok, [[^id, ["f", "v"]]]} <- Connector.command(sub, ["XRANGE", key, "-", "+"]),
           # the third in-band verb (XACK over a group); XGROUP CREATE is
           # non-blocking setup, XREADGROUP carries NO BLOCK arg
           {:ok, "OK"} <- Connector.command(sub, ["XGROUP", "CREATE", key, "g", "0"]),
           {:ok, _} <-
             Connector.command(sub, ["XREADGROUP", "GROUP", "g", "c", "STREAMS", key, ">"]),
           {:ok, 1} <- Connector.command(sub, ["XACK", key, "g", id]),
           # the concurrent push WAS delivered out of band (the load-bearing
           # assertion -- no concurrent push would prove nothing)
           :ok <- await_push(chan, "ping") do
        :ok
      else
        other -> {:fail, {:push_safe, other}}
      end

    try do
      GenServer.stop(sub)
    catch
      :exit, _ -> :ok
    end

    verdict
  end

  # Pull the first entry id from an XREADGROUP reply for `key`, tolerant of the
  # RESP3 map shape (%{key => [[id, fields], ...]}) and the RESP2 nested-array
  # shape ([[key, [[id, fields], ...]]]) -- the connection-dependent
  # stream->entries form. nil if the stream is absent/empty.
  defp stream_entry_id(reply, key) when is_map(reply) do
    case Map.get(reply, key) do
      [[id | _] | _] -> id
      _ -> nil
    end
  end

  defp stream_entry_id(reply, key) when is_list(reply) do
    case List.keyfind(reply, key, 0) do
      {^key, [[id | _] | _]} -> id
      _ -> nil
    end
  end

  defp stream_entry_id(_reply, _key), do: nil

  # A bounded wait for the out-of-band push on `chan` carrying `body` (the
  # {:emq_push, ["message", chan, body]} the connector routes off the FIFO).
  defp await_push(chan, body) do
    receive do
      {:emq_push, ["message", ^chan, ^body]} -> :ok
    after
      1_000 -> {:fail, :no_push}
    end
  end

  # Map a per-member verdict map over the served batch exactly as
  # EchoMQ.BatchConsumer.settle/3 does -- the :ok members retire through the
  # byte-frozen complete/5, the {:error, reason} members retry through the
  # byte-frozen retry/7 (the reason -> last_error), and a served member ABSENT
  # from the map fail-safe-retries ("missing verdict", D2 sub-decision). Each
  # settled member emits its own lifecycle event through the byte-frozen
  # Events.publish/5 (D3 -- per-member, the id gated). The cadence's settle
  # logic, exercised at the wire level.
  defp settle_batch(conn, q, members, verdicts) do
    Enum.each(members, fn {id, _payload, att} ->
      case Map.get(verdicts, id, {:error, "missing verdict"}) do
        :ok ->
          Jobs.complete(conn, q, id, att)
          _ = Events.publish(conn, q, "completed", id)

        {:error, reason} ->
          Jobs.retry(conn, q, id, att, 1, 5, to_string(reason))
          _ = Events.publish(conn, q, "failed", id)
      end
    end)

    :ok
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

  # Mint a fresh branded JOB id, enqueue it onto `group`'s lane through the
  # shipped Lanes.enqueue/5, and return the id -- the grouped-lane flood idiom of
  # the emq.4/emq.5.3 scenarios (the reassign/lane_drain/weighted_proportion
  # precedent). The order theorem holds: successive ids are minted distinct and
  # lexically ordered, so `for _ <- 1..n` yields the lane's mint-order backlog.
  defp enqueue_lane(conn, q, group, payload) do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Lanes.enqueue(conn, q, group, id, payload)
    id
  end

  # Complete each member of a batch through the shipped, byte-frozen @complete
  # with its own live token (emq.5.1 partial-failure isolation -- the worker
  # resolves each member independently). :ok iff every completion settled.
  defp complete_all(conn, q, members) do
    Enum.reduce_while(members, :ok, fn {id, _p, att}, _ ->
      case Jobs.complete(conn, q, id, att) do
        :ok -> {:cont, :ok}
        other -> {:halt, {:fail, {:complete, id, other}}}
      end
    end)
  end

  # Whether every member's row has been retired (deleted by @complete) -- the
  # other-members-settled half of the partial-failure isolation property.
  defp good_rows_retired?(conn, q, members) do
    Enum.all?(members, fn {id, _p, _att} ->
      Connector.command(conn, ["EXISTS", Keyspace.job_key(q, id)]) == {:ok, 0}
    end)
  end

  defp purge(conn, q) do
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    :ok
  end
end
