# BCS.3 · agent guide

> How to build the B3 batches (`/bcs/bus`): requirements, do-NOTs, the **verified grounding bank** (the senior
> read every figure below directly in the manuscript chapters and the committed rung records — cite from here
> and the named sources; re-derive nothing, invent nothing), per-module briefs, and the verification commands.
> All seven modules (B3.1–B3.7) are manuscript-ready; build in waves of ≤2. Spec of record:
> [`bcs.3.specs.md`](bcs.3.specs.md) · chapter doc: [`bcs.3.md`](bcs.3.md).

## References

- The triad: [`bcs.3.md`](bcs.3.md) · [`bcs.3.specs.md`](bcs.3.specs.md) (the module ladder + invariants + DoD).
- The course docs: [`../bcs.md`](../bcs.md) (contract; the identity MUST-NOT list) ·
  [`../bcs.toc.md`](../bcs.toc.md) · [`../bcs.roadmap.md`](../bcs.roadmap.md) (grounding map).
- The design exemplars: the built B2 chapter landing (`html/bcs/elixir-core/index.html`), a built B2 hub
  (`html/bcs/elixir-core/otp-application/index.html`), a built B2 dive
  (`html/bcs/elixir-core/otp-application/the-export-list.html`). Copy head/header/footer/scripts from a built
  BCS page of the same surface — never another course.
- The manuscript (each module's content spine, read-only): `../content/bcs3.md` (the Part preface — the chapter
  landing's spine) · `../content/bcs3.1.md`–`bcs3.6.md` · `../content/bcsA.md`; the committed evidence under
  `../content/echo_data/runtimes/elixir/` (`bcs_rung_3_1`…`3_6_check.out`, `emq_connector_check.out`).

## Requirements

- **BCS.3-R1** — md mirror first (`docs/echo/bcs/markdown/bus/<route>.md`), then the HTML, per page.
  [US: BCS.3-US1]
- **BCS.3-R2** — build each page to the ladder in [`bcs.3.specs.md`](bcs.3.specs.md); dives are fixed (D-B3.1),
  not redesigned. [US: BCS.3-US3]
- **BCS.3-R3** — every figure from the bank below or re-verified in the named `content/` file before use; the
  rung records quoted verbatim in source-labelled `figure.frozen` blocks. [US: BCS.3-US1]
- **BCS.3-R4** — a fresh `BCS…` stamp per page: `apps/jonnify-cms/bin/cms stamp mint --ns BCS` →
  `stamp decode <id>` → update the panel's static timestamp dd. [US: BCS.3-US2]
- **BCS.3-R5** — gate every page with the command below; ship only at STATUS: PASS. [US: BCS.3-US2]
- **BCS.3-R6** — any rival figure (B3.6) travels with the record's asymmetry line (D-B3.3). [US: BCS.3-US3]

## Do NOT

- Do not copy dark-editorial tokens, fonts, or card classes; copy only built BCS pages.
- Do not anchor unbuilt routes; defer cross-links to concurrent siblings (the orchestrator restores them
  post-wave); unbuilt modules and B4–B8 are named in `<strong>`, not linked.
- Do not edit `../content/**`, the course landing, the chapter landing (orchestrator-only), or the TOC.
- Do not fetch anything external; no storage APIs; honour `prefers-reduced-motion`.
- Do not write a figure absent from the bank and the sources; do not assert Appendix B (`bcsB.md`), EMQ 3.0
  Streams, or Parts V–VIII as written ("the manuscript plans…" — D-B3.2).
- Do not run git. Mind the gate traps: `just`/`simply`/`obviously` in visible prose; the literal substring
  `/future`; a perceptual verb on a tool (a script/queue/connector/fence does not "see"/"want"/"know"/"decide";
  transcript lines inside `figure.frozen` are exempt).

## Per-module briefs + the verified grounding bank

Pager law (all modules): hub prev = `/bcs/bus`, next = own first dive; dives chain hub → dive1 → dive2 → dive3
→ back to the hub. Crumbs mirror the route. `Related`: the chapter landing, built B2 modules where the content
meets them (`/bcs/elixir-core/property-stores` for stores, `/bcs/elixir-core/otp-application` for supervision),
and the doors (`/echomq` protocol depth, `/redis-patterns` substrate, `/elixir` umbrella).

### B3.1 `fence-and-keyspace` — teaches `../content/bcs3.1.md`

Dives: `the-key-grammar` · `the-fence-live` · `the-co-location-law`.

The transcript, verbatim (source: `bcs_rung_3_1_check.out`):

```
F1 map ok -- the part's map: emq:{orders}:pending | emq:{orders}:job:ORD0NgWEfAEJfs | {emq}:version | {emq}:locks -- 17 bytes before the payload
F2 gate ok -- the job position is gated: a fourteen-byte decimal and a fourteen-byte slug both raise before any wire is touched; kind policy waits for the enqueue script
F3 fence ok -- the fence holds on a live wire: GET {emq}:version answers echomq:2.0.0 through the fenced connector itself
F4 binary ok -- binary payloads with embedded CRLF and NUL survive 500/500 round trips through job keys in two pipelines
F5 slot ok -- co-location law: pending, active, meta, and the job row of {orders} all answer slot 105; {fills} answers 4165 -- multi-key scripts stay legal on the clustered day (vector 12739 holds)
PASS 5/5
```

Verified figures and teaching points (source: `bcs3.1.md`):

- Per-queue keys are `emq:{q}:<type>`; the braced base `{emq}:` is reserved for deployment-scoped facts (the
  version fence is "the canonical tenant and loneliness there is a feature"). Seventeen bytes of grammar,
  fourteen of identity — Chapter 1.3's economy carried onto the bus.
- The division of labor (the chapter's normative sentence): "the key function owns *wellformedness* … while
  *kind policy* … belongs to the enqueue script, because keys are grammar and scripts are law."
- The Elixir grammar, verbatim from the How:
  ```elixir
  def queue_key(queue, type) when is_binary(queue) and is_binary(type),
    do: IO.iodata_to_binary(["emq:{", queue, "}:", type])

  def job_key(queue, branded) do
    if EchoData.BrandedId.valid?(branded) do
      queue_key(queue, "job:") <> branded
    else
      raise ArgumentError, "job_key requires a valid branded id"
    end
  end
  ```
  and the Go counterpart (`func JobKey(queue, id string) (string, error)` with `brandedid.Parse` in the same
  position).
- The co-location consequence: "if a script needs keys from two queues, the design is wrong before the script
  is." The slot function is "committed, correct, and parked" — single-instance is the part's stated topology.
- Decisions: the grammar is closed · wellformedness at the key, policy at the script · the hashtag is the queue
  · the slot function committed and parked.
- Files: `runtimes/elixir/lib/echo_mq/{keyspace,connector,resp,script}.ex`.

Sources: Valkey protocol spec `https://valkey.io/topics/protocol/` (length-prefixed bulk strings — F4) ·
Valkey cluster spec `https://valkey.io/topics/cluster-spec/` (hash slots, CRC16 mod 16384, hash tags — F5).

### B3.2 `jobs-are-entities` — teaches `../content/bcs3.2.md`

Dives: `the-job-row` · `enqueue-one-script` · `the-orders-dividend`.

The transcript, verbatim (source: `bcs_rung_3_2_check.out`):

```
boot: the registry grows by one -- JOB, work as a kind with identity and lifecycle
J1 surface ok -- the bus module's surface: enqueue, browse, pending_size -- scripts and key shapes are nobody's business
J2 idempotent ok -- enqueue is one script and idempotent by id: first call enqueued, second answered duplicate, the row untouched and pending holds 1
J3 kind ok -- kind policy lives in the script: an ORD id in the job position answers EMQKIND on the wire -- the key let it pass, the law did not
J4 dividend ok -- the order theorem's dividend: newest-first browse over the ids themselves returns the last five minted in reverse mint order; the very first job sits at the head; 301 pending, no second index anywhere
J5 cargo ok -- the cargo law holds: the payload carries ORD0Nt6z93U3dY and a quantity, never a row -- decoded and re-parsed on the far side of the wire
PASS 5/5
```

Verified figures and teaching points (source: `bcs3.2.md`):

- The row is a hash of exactly three fields — `state`, `attempts`, `payload` — "and deliberately nothing more.
  No `enqueued_at` field exists because the two-clocks law already placed that fact."
- Pending is a sorted set, every member at score zero; equal scores order lexicographically — byte-by-byte,
  which for branded ids is mint order — so one set is "simultaneously the FIFO … and the browse index … and
  the time-range index."
- The enqueue script, verbatim from the chapter (quote whole — it is the contract):
  ```lua
  if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
    return redis.error_reply('EMQKIND job id must be JOB-namespaced')
  end
  if redis.call('EXISTS', KEYS[1]) == 1 then
    return 0
  end
  redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
  redis.call('ZADD', KEYS[2], 0, ARGV[1])
  return 1
  ```
  Act order is normative: "Policy before existence before write."
- The wire class discovered live: the rung's first run failed J3 — the engine wraps class-less errors in its
  generic `ERR`; the fix is the `EMQKIND` class word, "exactly the way the boot fence types its refusal."
- The client-side match, verbatim:
  ```elixir
  case Connector.eval(conn, @enqueue, keys, [job_id, payload]) do
    {:ok, 1} -> {:ok, :enqueued}
    {:ok, 0} -> {:ok, :duplicate}
    {:error, {:server, "EMQKIND" <> _}} -> {:error, :kind}
    other -> other
  end
  ```
- Decisions: D-10 the registry grows by `JOB` · policy before existence before write · `duplicate` is a success
  shape · refusals carry their own wire class · pending stays score-zero forever (3.3's schedule is a separate
  set).
- Files: `runtimes/elixir/lib/echo_mq/jobs.ex`.

Sources: Valkey ZRANGE `https://valkey.io/commands/zrange/` (REV/BYLEX; equal-score lex order) · Valkey sorted
sets `https://valkey.io/topics/sorted-sets/` (same-score lex family as a generic index).

### B3.3 `state-machine` — teaches `../content/bcs3.3.md`

Dives: `claim-the-token-mint` · `the-fencing-token` · `the-morgue-and-the-reaper`.

The transcript, verbatim (source: `bcs_rung_3_3_check.out`):

```
L1 surface ok -- the machine's surface: claim, complete, retry, promote, reap join enqueue, browse, pending_size -- five new verbs, every transition one script
L2 happy ok -- claim hands out the oldest job with a server-clock lease and fencing token 1; complete with the right token retires the row -- nothing remains
L3 fence ok -- a stale token is refused on the wire: EMQSTALE; the lease holder's work survives the zombie's complete
L4 schedule ok -- retry parks the job in the schedule, promote moves the due back to pending, and the next claim hands token 2 -- one job, two lives, one counter
L5 dead ok -- attempts 2 against max 2 is the morgue: state dead, last_error kept, and the dead set browses in mint order like everything else
L6 reap ok -- a 40 ms lease expires unanswered; reap returns the orphan to pending and the next claim holds token 2 -- crash recovery is one zset scan on the server's clock
PASS 6/6
```

Verified figures and teaching points (source: `bcs3.3.md`):

- The four sets and their score semantics: `pending` score-zero (lex = mint order) · `active` scored by lease
  deadline ("the in-flight roster and the expiry index") · `schedule` scored by run-at · `dead` score-zero
  ("the morgue browses newest-first like everything else … the order theorem's third appearance on the bus").
- The claim script, verbatim from the chapter (quote whole):
  ```lua
  local popped = redis.call('ZPOPMIN', KEYS[1])
  if #popped == 0 then return {} end
  local id = popped[1]
  local jk = ARGV[1] .. id
  local att = redis.call('HINCRBY', jk, 'attempts', 1)
  redis.call('HSET', jk, 'state', 'active')
  local t = redis.call('TIME')
  local now = t[1] * 1000 + math.floor(t[2] / 1000)
  redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)
  return {id, redis.call('HGET', jk, 'payload'), att}
  ```
  Three design facts: the clock is the server's (`TIME` inside the script, skew-immune); the token is minted by
  `HINCRBY` (monotonic per job by construction — Kleppmann's requirement); the job key is constructed from a
  prefix — "the bundle's one sanctioned exception to declared keys," safe because of the co-location law.
- The verification half, verbatim:
  ```lua
  local att = redis.call('HGET', KEYS[2], 'attempts')
  if att ~= ARGV[2] then return redis.error_reply('EMQSTALE complete token mismatch') end
  ```
  ```elixir
  {:error, {:server, "EMQSTALE" <> _}} -> {:error, :stale}
  ```
- Decisions: the server clock owns leases · `attempts` is the fencing token ("a second token field would be a
  second authority") · one constructed key, sanctioned by grammar · `EMQSTALE` joins `EMQKIND` · completion
  deletes (the receipt is 3.5's business).
- Boundaries to teach honestly: no lease extension yet; reap caps at one hundred per call; backoff policy lives
  above the wire ("Lua is the wrong home for judgment").
- Files: `runtimes/elixir/lib/echo_mq/jobs.ex` (five `Script.new` constants).

Sources: Valkey programmability `https://valkey.io/topics/programmability/` (atomic script execution) ·
Kleppmann `https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html` (the fencing-token
argument) · Valkey replication `https://valkey.io/topics/replication/` (the frozen-time rule for scripts).

### B3.4 `fair-lanes` — teaches `../content/bcs3.4.md`

Dives: `the-ring-and-the-rotation` · `ceilings-and-pauses` · `park-dont-poll`.

The transcript, verbatim (source: `bcs_rung_3_4_check.out`):

```
G1 surface ok -- the lanes surface: enqueue, claim, limit, pause, resume, depth -- six verbs over the same machine; the consumer exports start_link and child_spec -- the loop is a supervised citizen
G2 rotation ok -- twelve claims walk the ring four full turns -- three lanes, strict rotation -- and every lane serves in mint order; a lane named by a non-id raises before any wire is touched
G3 starvation ok -- the storm stays in its lane: the quiet lane's last job is served at position 40 of 420 while the flat queue, fed the same arrival order, serves its first quiet job at position 401 -- rotation is the refusal
G4 limit ok -- limit 2 holds: two leases out and the third claim answers empty with the lane parked at its ceiling and gactive reading 2; one complete reopens the lane and the next claim is served
G5 pause ok -- pause removes the lane from rotation with its backlog intact at depth 3; resume returns it and the ring serves the parked three in mint order
G6 park ok -- parked on the wake key the consumer spends 0 commands in a 400 ms idle window where a 10 ms poller spent 37; the wake answers an enqueue in 0 ms against a 5000 ms beat -- park, don't poll
G7 rhythm ok -- the loop owns the rhythm: a 60 ms lease left orphaned is reaped on the beat and served with token 2; a flaky job retries through the schedule and lands with token 2 -- the lane's count clears, the ring empties
G8 window ok -- the reap window closes on both machines: a holder completing token 1 after the reaper retires the job everywhere -- no ghost in the lane, none in pending, the ring empties and the count clears
PASS 8/8
```

Verified figures and teaching points (source: `bcs3.4.md`):

- A lane is `emq:{q}:g:<group>:pending` — score-zero like 3.2's pending. The ring at `emq:{q}:ring` is a plain
  list under one invariant: "*the ring contains exactly the serviceable lanes* — nonempty, unpaused, below
  their concurrency ceiling — *and every transition maintains it*." Park states are derived, not stored;
  `paused` is the one explicit marker.
- `LMOVE` with the same source and destination is the documented list-rotation primitive; quiet-lane positions
  land "at 2, 4, ... 40 by arithmetic."
- The claim's heart, verbatim from the How:
  ```lua
  local g = redis.call('LMOVE', KEYS[1], KEYS[1], 'LEFT', 'RIGHT')
  if not g then return {} end
  local lane = ARGV[1] .. 'g:' .. g .. ':pending'
  local popped = redis.call('ZPOPMIN', lane)
  -- token mint and lease exactly as Chapter 3.3 wrote them, then:
  local act = redis.call('HINCRBY', ARGV[1] .. 'gactive', g, 1)
  local lim = redis.call('HGET', ARGV[1] .. 'glimit', g)
  if lim and act >= tonumber(lim) then
    redis.call('LREM', KEYS[1], 0, g)
  elseif redis.call('ZCARD', lane) == 0 then
    redis.call('LREM', KEYS[1], 0, g)
  end
  ```
- The loop, verbatim:
  ```elixir
  defp loop(s) do
    {:ok, _} = Jobs.reap(s.conn, s.queue)
    {:ok, _} = Jobs.promote(s.conn, s.queue, s.pump_batch)
    drain(s)            # rotating claims until :empty
    park(s)             # BLPOP on the wake key, beat_ms as the timeout
    loop(s)
  end
  ```
- The wake design: every ring insert pushes onto `emq:{q}:wake`; the consumer `BLPOP`s on a **dedicated
  connector** ("a blocking verb on a shared pipeline would make one consumer's park everyone's head-of-line");
  `LTRIM` caps the list; over-delivery is harmless ("a spurious wake costs one empty claim, a missed wake would
  cost a stall, and the design buys the cheap failure").
- Decisions: lanes are named by identities (the group must parse as a branded id) · the ring invariant is the
  design · the constructed-key exception, second use, same sanction · pause stops claims, not flight · the wake
  rides every ring insert · the membership helper repeats in six scripts (a server-side library is "the
  Functions evaluation's day") · one machine, not two.
- Boundaries: rotation equalizes counts, not costs (weighted/deficit variants are a future knob); ring
  membership is `LPOS`/`LREM`, linear; reap does not consult `max_attempts`; one consumer per dedicated
  connector is the law.
- Files: `runtimes/elixir/lib/echo_mq/lanes.ex` (six verbs, five scripts), `lib/echo_mq/consumer.ex`, the grown
  `lib/echo_mq/jobs.ex`.

Sources: Valkey LMOVE `https://valkey.io/commands/lmove/` · Valkey BLPOP `https://valkey.io/commands/blpop/` ·
Shreedhar & Varghese, Deficit Round-Robin
`https://openscholarship.wustl.edu/cgi/viewcontent.cgi?article=1339&context=cse_research`.

### B3.5 `bus-meets-stores` — teaches `../content/bcs3.5.md`

Dives: `the-round-trip` · `exactly-once-by-name` · `one-more-owner`.

The transcript, verbatim (source: `bcs_rung_3_5_check.out`):

```
B1 surface ok -- the consumer grows one verb: stop -- drain and stop, with child_spec and start_link as Chapter 3.4 shipped them; the stores' modules are untouched by this chapter
B2 round trip ok -- a fill leaves as two names and two numbers and lands as two property writes through the tree -- the ORD row filled qty 7 at 105, the PRT position absorbing the job's name as its receipt, the row on the bus gone
B3 torn ok -- a handler torn between two writes is one job's failure, not the loop's: the crash converts to a typed retry (last_error: torn between writes), the same pid serves attempt 2, the position declines the name it already absorbed -- qty 12 once, never 17 -- and the order completes
B4 owner ok -- the consumer is one more owner: stopped dead mid-fill, the one_for_one tree restores it alone -- the stores never blink and their rows survive -- the orphaned lease reaps on the new pid's beat and qty lands 15 exactly once with token 2
B5 audit ok -- the audit trail is the store itself: five fills page newest-first by name alone, every row carrying the JOB that wrote it, the position remembering all five names for qty 18
B6 stop ok -- stop is a drain on both paths: the supervisor's terminate_child settles the fill in hand and never claims the next -- depth 1 remains with attempts 0 -- and a bare loop answers stop with a normal exit
PASS 6/6
```

Verified figures and teaching points (source: `bcs3.5.md`):

- The thesis: a row that remembers the names it has absorbed turns at-least-once delivery into exactly-once
  *effect*. Helland's recipient-remembers requirement, answered the BCS way: "remember the *name*."
- The guard idiom, verbatim from the How (the rung's committed handler):
  ```elixir
  fills =
    case PropertyStore.get(:positions35, prt) do
      {:ok, %{fills: f}} -> f
      _ -> %{}
    end

  unless Map.has_key?(fills, job) do
    f2 = Map.put(fills, job, qty)
    :ok = PropertyStore.put(:positions35, prt, %{fills: f2, qty: f2 |> Map.values() |> Enum.sum()})
  end
  ```
- The isolation idiom, verbatim (one rescue, one typed retry):
  ```elixir
  verdict =
    try do
      s.handler.(%{id: id, payload: payload, attempts: att, group: group})
    rescue
      e -> {:error, Exception.message(e)}
    catch
      :exit, reason -> {:error, "exit: " <> inspect(reason)}
      :throw, value -> {:error, "throw: " <> inspect(value)}
    end
  ```
- The tree: three children under `one_for_one` — two property stores and the consumer — "the loop that drives
  the bus is a peer of the stores it feeds."
- The two-industries frame (Why): the double fill on the desk; the Dark Engine's apply-damage redelivered
  ("kills the player twice"). Keep the guard "a *map of names*, not a last-writer field."
- Decisions: results are property writes carrying provenance · every row guards itself by the names it has
  absorbed · the consumer traps exits · failure converts; violation crashes · the lane's lifetime is the owner's
  choice.
- Boundaries: no cross-store transaction ("the recipe yields exactly-once per row"); replay belongs to EMQ 3.0
  Streams (D-3); store durability unchanged (D-2); the absorbed-names map grows (compaction is a future knob).
- Files: `runtimes/elixir/lib/echo_mq/consumer.ex` (hardened); the Part II stores cited as shipped and
  untouched.

Sources: Helland, Life beyond Distributed Transactions, CIDR 2007
`http://cidrdb.org/cidr2007/papers/cidr07p15.pdf` · Erlang/OTP supervisor
`https://www.erlang.org/doc/apps/stdlib/supervisor.html`.

### B3.6 `conformance` — teaches `../content/bcs3.6.md`

Dives: `the-committed-harness` · `the-referee-habit` · `the-rivals-numbers`.

The transcript opens with the referee header and the asymmetry — **quote these with any rival figure (D-B3.3)**
(source: `bcs_rung_3_6_check.out`):

```
referee header: Valkey 9.1.0 (save '', appendonly no) vs PostgreSQL PostgreSQL 16.14 (synchronous_commit on) | Oban 2.18.3 engine Basic queue bench limit 10 | Elixir 1.14.0 OTP 25 | schedulers 1
the asymmetry, stated first: the rival's enqueue is durable and transactional (a WAL flush per commit); the bus's enqueue is volatile by decision D-2 and pays no fsync -- every number below carries that trade
```

Key gate lines, verbatim (the full record is long — quote the slice your dive teaches; the hub's frozen block
may quote the header + C1/C2/C3/C5/C6 + `PASS 6/6`):

```
C1 surface ok -- the conformance harness exports run and scenarios -- fourteen wire-level contracts a port can drive verbatim; Jobs grows batch admission: enqueue_many, same script, one flush
CONFORMANCE 14/14
C2 conformance ok -- fourteen of fourteen contracts hold against the live server -- the tower's behavior is now a portable artifact
C3 referee ok -- measured (bus): 11422 sequential enqueues per second; 78980 batched per second over 5000 in one flush; 7000 rows pending, every verdict enqueued -- both inside the derived bands
C4 rival ok -- the rival is real in this container: one job inserted, woken by NOTIFY, performed by the queue's worker, acknowledged completed in oban_jobs
C5 numbers ok -- measured: sequential enqueue 11422/s bus vs 619/s rival; batched 78980/s bus vs 13716/s rival (7000 rival rows landed); end-to-end median 0.3 ms bus vs 8.8 ms rival; drain of 3000: 6092/s bus vs 944/s rival -- the derived order holds, and the rival's slower row is the durable one
C6 advantage ok -- the rival's advantage in its own row: enqueue is atomic with the business write -- one transaction carries the fill and its job, rollback erases both, commit lands both; the bus cannot say this sentence -- its enqueue and its store write are two systems, the torn window of Chapter 3.5 is the price, and the provenance guard is the mitigation, not the cure
PASS 6/6
```

The fourteen `CONF` lines (fence, mint, duplicate, kind, order, claim, stale, complete, retry, dead, reap,
rotate, pause, limit) are in the record verbatim — `the-committed-harness` quotes them whole. The `derive` lines
(bus sequential/batched, rival sequential/batched, latency, drain) are in the record verbatim —
`the-referee-habit` quotes them beside their measurements.

Verified teaching points (source: `bcs3.6.md`):

- The harness drew blood on day one: `eval`'s load-on-`NOSCRIPT` retry returned the retried reply raw; on a
  cold cache "a legitimate `EMQSTALE` refusal came back wearing the wrong shape." Fix: four lines
  (`map_script_reply/1`); the pin: the stale scenario now issues `SCRIPT FLUSH` first. "A conformance suite
  that has never caught anything is decoration; this one paid rent before it shipped."
- The confessed miss: the rival's batched band was re-derived (jsonb encoding + index maintenance) to
  `expect 8,000 to 40,000 per second` before the committed run — "Bands adjusted after the fact are not
  derivations unless the adjustment is itself derived and confessed."
- Every gap traces to one structural fact: sequential = a WAL flush per commit; batched = the flush amortizes;
  latency = `NOTIFY` delivers only at commit; drain = an UPDATE and its own commit per job. "The rival is not
  slow; the rival is *durable per row*."
- The advantage row, verbatim from the How:
  ```elixir
  Ecto.Multi.new()
  |> Ecto.Multi.insert(:fill, fill_changeset)
  |> Oban.insert(:job, fn %{fill: fill} -> Worker.new(%{fill_id: fill.id}) end)
  |> Repo.transaction()
  ```
- Driving the harness:
  ```elixir
  {:ok, c} = EchoMQ.Connector.start_link(port: 6390)
  {:ok, 14} = EchoMQ.Conformance.run(c, "conf")
  ```
- Decisions: conformance is scenarios over the wire · every catch becomes a pin · derivations print into the
  record, repairs confess · the rival runs whole, local, at its defaults · the advantage is a gate · one surface
  addition (`enqueue_many/3`), one fix.
- Boundaries: one core, loopback, one container — "the ratios travel better than the absolutes"; the rival
  pinned (Oban 2.18.3, Basic engine, PostgreSQL 16.14).
- Files: `runtimes/elixir/lib/echo_mq/conformance.ex`, the grown `jobs.ex`, the fixed `connector.ex`.

Sources: Oban docs `https://hexdocs.pm/oban/Oban.html` · PostgreSQL async commit
`https://www.postgresql.org/docs/current/wal-async-commit.html` · PostgreSQL NOTIFY
`https://www.postgresql.org/docs/current/sql-notify.html`.

### B3.7 `the-connector` — teaches `../content/bcsA.md` (Appendix A)

Dives: `resp-one-pass` · `the-typed-fence` · `measured-on-the-wire`.

There is no `PASS n/n`-suffixed rung transcript quoted in `bcsA.md` itself; the evidence is the committed
`emq_connector_check.out` (`PASS 8/8`) and the appendix's own Measured section. Verified figures (source:
`bcsA.md` — quote these phrasings, not re-derivations):

- Four modules, "four hundred fifty lines, zero dependencies beyond the identity canon, and a gate record that
  ends `PASS 8/8`." Against "the same Valkey 9.1.0 the storage chapter measured, listening on `:6390`."
- The module table (quote as the surface map): `EchoMQ.RESP` (`encode/1`, `parse/1`) · `EchoMQ.Script` (`new/2`,
  SHA1 at construction) · `EchoMQ.Keyspace` (`queue_key/2`, `job_key/2`, `reserve/1`, `version_key/0`,
  `prefix_bytes/2`, `slot/1`, `hashtag/1`) · `EchoMQ.Connector` (`start_link/1`, `command/3`, `pipeline/3`,
  `eval/5`, `stats/1`, `wire_version/0`).
- Design points: RESP2 one-pass, iodata out, `:incomplete` continuation, server errors as values
  (`{:error_reply, msg}`); pipelining as the primitive (pending-FIFO `{from, want, acc}`, `active: :once`);
  EVALSHA-first with the load-once assertion; the fence typed and fatal (`{:error, {:version_fence, got}}`;
  reconnect re-fences); eight `:counters` slots; capped jittered backoff failing pending callers with
  `{:error, :disconnected}`.
- Measured (quote verbatim phrasing): the fence claimed `echomq:2.0.0` and refused the planted mismatch; a
  six-byte CRLF binary round-tripped; `emq:{orders}:job:ORD0NsVQMCRgHI`; `slot 105 == 105` against `8507`
  (payments), vector `12739`; `script_loads=1`; `10000-command pipeline returned 1..10000 in order`; sequential
  INCR `29456` ops/s; pipelined SET `454483` ops/s ("fifteen times the sequential figure on the same socket");
  pipelined EVALSHA `161192` ops/s; supervisor restart → re-fenced and served; `prefix = 17 bytes`.
- Boundaries: RESP2 deliberately (no `HELLO`, no RESP3 push types — "the upgrade is a contained follow-up");
  one connection per process ("a pool is a supervisor of N of these"); the restart gate kills the process, not
  the server. **Appendix B** (the production connector — authenticated boot, bounded in-flight, heartbeat,
  RESP3 negotiated whole) has a committed spec and two committed rungs but no prose — living-status voice only
  (D-B3.2).
- Files: the four modules above; `runtimes/elixir/emq_connector_check.exs` + `.out`.

Sources: Valkey protocol spec `https://valkey.io/topics/protocol/` · Valkey 8.1.0 GA
`https://valkey.io/blog/valkey-8-1-0-ga/`.

## Agent stories

- **BCS.3-AS1 [implements BCS.3-US3]** — Per module: author the md mirrors (hub + dives), then the pages,
  copying the design from the named model. Acceptance gate: every figure on the pages appears in this bank or
  the named manuscript file, character for character; the rung record is quoted verbatim in a `figure.frozen`
  block.
- **BCS.3-AS2 [implements BCS.3-US1]** — Interactives per surface: hub ≥1, dive ≥2, pure functions over the
  module's own fixed dataset (the gate explorer, the key-grammar composer over fixed queue names, the slot
  table, the token-fence simulator over fixed tokens, the ring rotation walk, the two-column referee table),
  live readout, static degrade.
- **BCS.3-AS3 [implements BCS.3-US2]** — Gate, then self-audit: figure provenance, identity leak, clamp
  spacing, route-tag form, stamp decode, md mirror present, the asymmetry line beside any rival figure.

## Build order

1. Orchestrator: chapter landing (`/bcs/bus`) from this triad — gate it.
2. Waves of ≤2 module agents, suggested: B3.1+B3.2 → B3.3+B3.4 → B3.5+B3.6 → B3.7. (Defer cross-sibling links
   within a wave; restore after the wave lands.)
3. Orchestrator after each wave: restore deferred links → relink the chapter landing's cards → after the first
   green wave relink the course landing (B3 card + footer) → sync [`../bcs.toc.md`](../bcs.toc.md) → final
   verification.

## The verification sequence

```bash
# Gate (per page; all ten must PASS)
FLAGS="--routes-from /bcs=html/bcs --routes-from /echomq=html/echomq --routes-from /redis-patterns=html/redis-patterns --routes-from /elixir=elixir --chapter-alias b1=ideas,b2=elixir-core,b3=bus,b4=cache,b5=go,b6=node,b7=fly,b8=trading --require-refs"
apps/jonnify-cms/bin/cms check ${=FLAGS} html/bcs/bus/<path>.html

# Stamp (per page)
apps/jonnify-cms/bin/cms stamp mint --ns BCS && apps/jonnify-cms/bin/cms stamp decode <id>

# Batch audits (all must return nothing)
grep -rn '/future' html/bcs/bus/
grep -rnEi '\b(revolutionary|blazing|magical|simply|just|obviously|effortless)\b' html/bcs/bus/
grep -rn 'localStorage\|sessionStorage\|Cormorant\|Manrope\|PT Serif' html/bcs/bus/
grep -rnE 'clamp\([^)]*[0-9](\+|-)[0-9]' html/bcs/bus/
grep -rnE '\b(script|queue|connector|fence|consumer|store|gate|system|boundary|bus|id|ring|lane) (sees?|wants?|knows?|decides?)\b' html/bcs/bus/

# Live crawl (server on :8765; 000 = server down, not route missing)
curl -s -o /dev/null -w '%{http_code}\n' localhost:8765/bcs/bus
```

## Comprehensive prompt

Build your assigned B3 module of the BCS course. Read [`bcs.3.specs.md`](bcs.3.specs.md) (your module's row in
the ladder is your structure — do not redesign it), your manuscript chapter under `../content/`, and your
module's section of this guide (your verified figures and sources). Author the md mirrors first
(`docs/echo/bcs/markdown/bus/<route>.md`), then the pages, copying the contract-sheet design from the named
built BCS page — never another course. Quote every figure verbatim from the bank; render the rung record in a
source-labelled `figure.frozen` block; mint and decode-verify a fresh `BCS…` stamp per page; keep every internal
link resolving (defer the sibling-module link per your brief); carry the asymmetry line with any rival figure.
Gate each page with the command above; ship only at STATUS: PASS. Touch only your module's routes. Never run
git.

---

Index: ../bcs.md · TOC: ../bcs.toc.md · Roadmap: ../bcs.roadmap.md · Chapter: ./bcs.3.md · Spec: ./bcs.3.specs.md
