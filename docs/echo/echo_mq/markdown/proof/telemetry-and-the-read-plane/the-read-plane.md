# The read plane

> Route: `/echomq/proof/telemetry-and-the-read-plane/the-read-plane` · Module 02 · dive 03.
> Grounds in `EchoMQ.Metrics` — `get_counts/3`, `get_job_state/3`, `get_metrics/3`, `get_rate_limit_ttl/3`,
> `is_maxed/2`, `lane_depth/3` (`echo/apps/echo_mq`). No Lua block — the read scripts are shipped and
> declared-keys, but the page teaches the Elixir verb, not a Lua body.

Where the meter **pushes** events as work happens, the read plane **pulls**: a caller asks a question, the bus
answers from the structures it already keeps. The defining property of the whole module is one sentence:
**every verb observes; none mutates.** A metric read never moves a set member, never re-schedules a job, never
spends a token. The state machine answers how it is doing without being changed by the asking — which is
exactly what you want from an introspection surface, because a metric that perturbs the thing it measures is
worse than no metric at all.

## Counts per state — read the structures, move nothing

`get_counts/3` answers a map of **state → count** over the bus's as-built structures. The four live states —
`pending`, `active`, `schedule`, `dead` — are sorted sets, so their count is a `ZCARD` of each set. The two
terminal outcomes — `completed`, `failed` — leave no set behind (completion deletes the job), so their count
is read from a small terminal-outcome counter the completion and dead-letter transitions keep. One read, two
kinds of structure, no member touched.

The verb is also **closed**: it validates every requested state name against the registered set first. An
unrecognized name is `{:error, {:unknown_state, name}}` — never an open read that quietly concatenates an
attacker-chosen string into a key. The closed registry is the same discipline the whole protocol rests on:
the bus answers a known set of questions, precisely.

```elixir
# echo_mq — EchoMQ.Metrics
# Count per requested state. Validate the names against the closed registry FIRST
# (an unknown name is a typed error, never an open read). The set states read
# ZCARD of their sorted set; the metric states read the terminal-outcome counter
# (completion deletes the job, so it leaves no set). The queue base is the
# declared slot root, so even a metric-only request pins the {q} slot. A pure read.
def get_counts(conn, queue, states) when is_binary(queue) and is_list(states) do
  with :ok <- validate_states(states) do
    {sets, metrics} = Enum.split_with(states, &(&1 in @set_states))
    base = Keyspace.queue_key(queue, "")
    keys = [base | Enum.map(sets, &Keyspace.queue_key(queue, &1))]

    case Connector.eval(conn, @counts, keys, metrics) do
      {:ok, counts} ->
        ordered = sets ++ metrics
        {:ok, ordered |> Enum.zip(counts) |> Map.new()}

      other ->
        other
    end
  end
end
```

## A job's state — which structure holds the id

`get_job_state/3` answers a different question: for **one** branded id, which state is it in? The read checks
the four set keys in order — `pending`, `active`, `scheduled`, `dead` — and answers the first that holds the
id by its score. If no set holds it, the read consults the **row** itself: a flow parent held out of every set
until its children complete carries `awaiting_children` on its row; a row that exists but sits in no set (an
id in flight between transitions) answers `unknown`; and no row at all answers `absent`. The id is gated by
`BrandedId.valid?/1` at the key builder, so an ill-formed id is refused before any wire command is sent.

The closed-set discipline appears again on the way out: the wire string is mapped through an explicit table
to its atom, never `String.to_existing_atom`. An unexpected wire string is a typed error, not an open
conversion that could raise — the read plane stays honest even about its own answers.

```elixir
# echo_mq — EchoMQ.Metrics
# The job's state by which structure holds the id. The four set keys are declared
# in KEYS; the id is gated at the key builder. The wire string maps through a
# closed table to its atom (never to_existing_atom) — an unexpected string is a
# typed error, never an open conversion. A pure read.
def get_job_state(conn, queue, job_id) when is_binary(job_id) do
  keys =
    Enum.map(@set_states, &Keyspace.queue_key(queue, &1)) ++ [Keyspace.job_key(queue, job_id)]

  case Connector.eval(conn, @state_lookup, keys, [job_id]) do
    {:ok, state} when is_binary(state) ->
      case @lookup_states do
        %{^state => atom} -> {:ok, atom}
        _ -> {:error, {:unknown_state, state}}
      end

    other ->
      other
  end
end
```

## The rest of the plane — throughput, the rate gate, lane depth

The same observe-never-mutate rule shapes the rest of the verbs:

- **`get_metrics/3`** — the terminal-transition throughput for `:completed` or `:failed`: the `count` the
  completion/dead-letter transition tallied, read honestly (the series length is reported as it stands, never
  a phantom).
- **`get_rate_limit_ttl/3`** — the remaining rate-limit TTL in milliseconds (`0` = not limited): the limiter
  string read against the configured `max`. A read of the gate, not a spend of it.
- **`is_maxed/2`** — the concurrency gate as a **read-and-refuse**: where the active set is at the configured
  ceiling, the refusal leads with the `EMQRATE` wire class, mapped to `{:error, :rate}`; otherwise `:ok`. No
  state transition, no member moved — a read of the ceiling and a typed refusal.
- **`lane_depth/3`** — the pending depth behind one group identity, delegating to the as-built `Lanes.depth`,
  which gates the group with `BrandedId`.

Across all of them, **every read script declares its keys** — the queue base is passed as a declared `KEYS`
root (so the `{q}` slot is pinned even for a read that requests no set key), never an `ARGV`-passed base
concatenated in-script. That is the protocol's slot-soundness law applied to the read plane: a multi-key read
stays legal on a cluster, and a state name an attacker chose can never become a key.

## Pattern & implementation

- **The pattern (Redis Patterns Applied):** read the system's state for an operator — counts, throughput, the
  rate-gate — without changing the work. `/redis-patterns/production-operations` teaches running the tier.
- **The implementation (echo_mq):** `EchoMQ.Metrics` is pure-read — `get_counts/3` (per-state counts),
  `get_job_state/3` (which structure holds an id), `get_metrics/3` (terminal throughput), `get_rate_limit_ttl`
  / `is_maxed/2` (the read-and-refuse gate), `lane_depth/3` — every verb observes, every read declares its
  keys, and an unregistered state name is a typed error, never an open read.

## References

### Sources
- [Valkey — ZCARD](https://valkey.io/commands/zcard/) — the cardinality `get_counts/3` reads each state set by.
- [Valkey — ZSCORE](https://valkey.io/commands/zscore/) — the membership test `get_job_state/3` resolves an id by.
- [Valkey — HGET](https://valkey.io/commands/hget/) — the terminal-outcome counter and the row fields the read plane reads.
- [Beck — Test-Driven Development](https://www.oreilly.com/library/view/test-driven-development/0321146530/) — observing behaviour by asserting the externally visible state, never by perturbing it.

### Related in this course
- `/echomq/proof/telemetry-and-the-read-plane` — the module this dive belongs to.
- `/echomq/proof/telemetry-and-the-read-plane/the-telemetry-surface` — the push side that emits as work happens.
- `/echomq/proof/telemetry-and-the-read-plane/zero-cost-when-absent` — the opt-in property the read plane has no dependency to share.
- `/echomq/queue` — the four state sets and the lifecycle the read plane reads.
- `/echomq/protocol` — the declared-keys law every read script obeys.
- `/redis-patterns/production-operations` — the production-operations pattern that doors here.
- `/bcs/together` — the manuscript chapter (B6) where the four libraries are one umbrella.
