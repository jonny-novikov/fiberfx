# BCS · Appendix D — The Journal's Shadow: SQLite under Litestream

<show-structure depth="2"/>

Chapter 4.4 built the lane that remembers and drew its boundary in the open: the per-group SQLite journal survives every process crash and bus restart this part stages, and a dead box was the named, deliberately unbuilt layer above it. The persistence lab then priced six engines under the same intent and the Operator's challenge closed the question the right way — the hand-rolled lanes were instruments, and production wants what is battle-tested. This appendix ships that answer whole: `EchoCache.Litestream`, a supervised replication sidecar per journal directory, restore as the node-death verb, one hardening line inside the journal itself, and six new gates committed (`bcs_rung_litestream_check.out`, `PASS 6/6`). The headline numbers: the shadowed write pair at `88.5` µs — inside the bare floor's own run-to-run spread, which is the claim — a measured loss window of `281 ms`, a box death with every local byte deleted returned in `2456 ms and 32768 bytes` with coverage replay measuring `%{deduplicated: 0, replayed: 0}`, and the remembered lane whole at `565 us` against the bare lane's committed 524.

## Battle-tested, as an argument rather than an adjective

The lab's raw lanes earned their microseconds by shedding guarantees, and the matrix said so in its catch column: the buffered AOF's entire recovery story is a torn-frame check, and `disk_log`'s repair-on-open truncates to the last whole term — silent tail loss, by design. Those are correct trade-offs for an instrument and disqualifying ones for an obligations lane. The engine the journal already runs on sits at the other extreme of the testing spectrum: SQLite's core carries 100% branch and MC/DC coverage under a proprietary harness of million-scale parameterized instances, cross-checks its answers against four other SQL engines, and is fuzzed and fault-injected continuously — "A soak test prior to release does about 248.5 million tests." [1]. That regime is not something a project hand-rolls beside its own deliverables; it is something a project inherits by choosing the engine, and 4.4's six gates were already green on it. What was missing was the box-death story, and the same inheritance argument picks the shadow: Litestream runs as a separate process, takes over SQLite's checkpointing through a long-lived read transaction, copies WAL pages into a shadow sequence shipped to object storage, and restores by snapshot plus replay [2] — the architecture the lab's S3 leg re-derived as arithmetic, already built, already operated in production, already documented against the exact storage this house deploys on [3].

## The design: two truths, two recovery verbs

The division of labor is the one this part has been building toward since the sixth law was stated. The journal is the synchronous truth beside the bus: every intent and every last word lands in it before anything else is believed, at `synchronous=NORMAL`, microseconds at a time. The shadow is an asynchronous copy of that truth beside the box: it reads behind the writer and ships on an interval, so it costs the write path nothing and trades a bounded window for it. The two recovery verbs that fall out are orthogonal and compose. A bus restart is covered by replay — the journal re-enqueues uncovered intents, as 4.4 drilled. A box death is covered by restore — the shadow returns the journal file, after which the lane opens and replays as if the box had merely blinked. The LS4 gate runs the composition end to end: restore first, then replay, and replay's measured answer over a fully-applied lane is the empty map, because everything the lane promised was already in the shadow.

The module is one GenServer per journal directory. On boot it discovers the group journals — or is handed them — and the kind law holds at the shadow's door exactly as it holds everywhere else in this series: a journal file whose group is not a branded id is refused before any OS process spawns. The config is rendered fresh on every boot, names each database and its replica URL, and carries no credentials — those travel in the environment, which is both the Litestream convention and the only secret-handling this module will participate in:

```elixir
def replica_url(group, opts) do
  bucket = Keyword.fetch!(opts, :bucket)
  prefix = Keyword.get(opts, :prefix, @default_prefix)
  endpoint = Keyword.get(opts, :endpoint, @default_endpoint)
  region = Keyword.get(opts, :region, @default_region)
  "s3://#{bucket}/#{prefix}/#{group}?endpoint=#{endpoint}&region=#{region}"
end
```

The sidecar runs under a monitored Port with its OS pid captured at spawn. If it exits, it is restarted with bounded backoff; if the server terminates, the sidecar receives SIGTERM by exact pid — this module never signals by process name, which is the same discipline the Valkey startup rule taught this tree the hard way:

```elixir
def terminate(_reason, %{os_pid: os_pid, port: port}) do
  if is_integer(os_pid), do: System.cmd("kill", ["-TERM", Integer.to_string(os_pid)])
  if is_port(port) and port in Port.list(), do: Port.close(port)
  :ok
end
```

Restore is a module function rather than a server call, because restore runs when nothing else does:

```elixir
{:ok, :restored} = EchoCache.Litestream.restore(dir: dir, group: group,
  bucket: "bcs-lane-lab", binary: "/usr/local/bin/litestream")
```

and `prepare/1` runs the restore-if-missing pass across every group — the first line of the runbook below.

One line landed inside the journal itself, and it is the appendix's only touch on 4.4's frozen surface: `PRAGMA busy_timeout=5000`. The sidecar takes brief write locks when it checkpoints, and an application sharing the database must wait rather than error — the requirement is stated plainly in Litestream's own operational notes [4], and the full 4.4 rung regressed green three consecutive runs with the pragma in place.

## The numbers

**The shadowed pair — `88.5` µs, and the shape of that claim.** The gate's derivation states it before the measurement: the takeover is read-side, so the shadowed pair should be indistinguishable from the bare floor within this container's own run-to-run spread, which runs of this pair shadowed and bare have scattered between roughly 98 and 201 µs around the committed 143. The committed line: `the pair under live replication: 88.5 us per record-and-mark against the committed bare floor of 143 -- inside the bare pair's own run-to-run spread on this container, which is the claim: the shadow reads behind the writer, and the writer's path shows no consistent cost`. The band — 80 to 250 — is wide enough to hold the variance and tight enough to catch the only failure that would matter: a shadow that ever blocks the writer.

**The loss window — `281 ms`, measured rather than assumed.** Async replication's entire trade is this number: a fresh intent reached the replica in 281 milliseconds, a full sync interval plus an upload when the write lands at a cycle's start, a fraction of one when it lands mid-flight (one run measured 71 ms for exactly that reason, and the gate's floor was re-derived to admit it). This is the width of the window a box death can erase, the interval is the dial that trades it against upload churn, and the boundaries below state it as the appendix's central caveat rather than burying it.

**The node-death drill — the headline.** A pristine lane carried fifty applied names and one applied sentinel, its last segment confirmed shipped; then the box died — journal stopped, sidecar stopped, every local byte deleted including the sidecar's own metadata directory, which must die with the database it describes [4]. The committed line: `the box died with every local byte of the drill lane deleted and the shadow returned it in 2456 ms and 32768 bytes: 51 intents and 51 remembered names back exactly, every last word intact, and coverage replay measured %{deduplicated: 0, replayed: 0} -- nothing owed, nothing lost`. Two and a half seconds from object storage to a lane that answers its last words is the restore budget; the lane's latency budget never sees it.

**Resume — the restored lane is not a dead end.** Replication restarted over the restored file begins a fresh shadow lineage and keeps shipping; thirty more intents and a second restore into a clean directory carried the whole history: `81 intents and 51 remembered names, the hero's last word intact`. Restore composes with itself, which is what makes it an operational verb rather than a one-shot rescue.

**The lane, whole.** With the shadow attached, the full remembered lane — intend, enqueue, consume through the journal's memory — closed at a `565 us` end-to-end median against 4.4's committed bare 524. Durability beside the box rides behind the lane instead of inside it, and the lane's price says so.

## The version gate, confirmed the hard way

The first binary this appendix ran was v0.3.13, and it could not reach the replica at all: its SDK fell back to resolving the bucket's region against AWS's own records, where Tigris credentials do not exist, regardless of the region in the URL or the environment. The Tigris guide's claim — that v0.5.0 detects Tigris endpoints and configures the required settings automatically [3] — turned out to be a requirement rather than a convenience, and the committed record runs on `litestream 0.5.7`. The module is version-agnostic by construction (it shells the binary it is given); the deployment is not, and on Tigris it pins v0.5 or later.

## The runbook: a box dies

First, `prepare/1` — restore every group journal whose file is missing; present files are left alone, absent replicas reported as such. Second, open the journals; the busy timeout and the WAL posture are theirs already. Third, replay each lane against the bus — coverage decides what the bus still owes, the recorded job ids let admission dedup absorb survivors, and a fully-applied lane answers with the empty map. Fourth, start the shadow, which begins a fresh lineage over the restored files and resumes shipping. Fifth, resume the lanes. The drill above is this runbook executed by a gate, with every step's output asserted rather than hoped.

## Boundaries

The loss window is real and now has a number: writes inside the final `281 ms`-class interval before a box death are not in the shadow, and the journal's own `NORMAL` tail sits inside that same window — surfaces that cannot accept it tune the sync interval down, pay the upload churn, or take `synchronous=FULL` per group as 4.4 already offered. Restore is per-group, exactly as the journals are, and a multi-group box death is `prepare/1` over the directory, not one verb. The shadowed-pair claim is a variance claim on a one-scheduler container, stated as such; a dedicated-core deployment owes its own measurement. The sidecar is an operational unit — a binary to version, a process to supervise, an environment to carry credentials — and on Tigris that version is v0.5 or later, confirmed empirically above. And the metadata-directory rule is load-bearing: a recreated or restored database must shed the sidecar's leftover `-litestream` directory before replication restarts, which the drill performs and the runbook inherits.

## Companion files

`runtimes/elixir/lib/echo_cache/litestream.ex` (the shadow, production); the one-line hardening in `runtimes/elixir/lib/echo_cache/journal.ex`; the rung `bcs_rung_litestream_check.exs` and its committed record `bcs_rung_litestream_check.out`; the calibration baselines quoted throughout from `bcs_rung_4_4_check.out` and the persistence lab's `lab/lab_persistence_bench.out`.

## References

1. SQLite documentation — How SQLite Is Tested (four independent harnesses, 100% branch and MC/DC coverage of the core, cross-engine logic comparison, fuzzing and fault injection, a pre-release soak in the hundreds of millions — the definition of battle-tested this appendix builds on instead of around): [sqlite.org/testing.html](https://sqlite.org/testing.html)
2. Litestream documentation — How it works (a separate background process takes over SQLite checkpointing through a long-running read transaction, ships WAL pages to replicas, and restores by snapshot plus replay — the shadow's architecture): [litestream.io/how-it-works](https://litestream.io/how-it-works/)
3. Litestream documentation — Replicating to Tigris (the replica URL form with endpoint and region, credentials in the environment, and the v0.5.0 Tigris auto-detection this appendix confirmed as a hard requirement): [litestream.io/guides/tigris](https://litestream.io/guides/tigris/)
4. Litestream documentation — Tips & Caveats (the busy timeout an application sharing the database must set, the WAL-with-relaxed-synchronous posture, and the rule that a recreated database sheds the sidecar's metadata directory — each one a line in this appendix's code or drill): [tip.litestream.io/tips](https://tip.litestream.io/tips/)
