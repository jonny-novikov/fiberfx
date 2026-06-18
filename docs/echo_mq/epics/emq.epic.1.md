# Epic EMQ1 · EchoMQ v3.x command DSL

> **PROPOSED** — the first emq Epic ([the layer is emq.epic.0](./emq.epic.0.md)): rewrite the v1 command
> surface to a **BCS state-of-the-art v3.x** form and document it as a **forward-only DSL catalogue**, organized
> per feature. **No v1↔v3 matrix** — the old command reference is a development-supporting artifact, not the
> catalogue.

## Goal

Two halves, one epic:

1. **Rewrite** the v1 command surface in a BCS state-of-the-art manner — every v3 command lawful under the v2
   protocol (braced keyspace · branded `JOB` ids gated at the key builder · declared-keys A-1 · server clock ·
   slot-soundness · honest-row), evolved for what **BCS** and **EchoMesh** need. The rewrite ships rung by rung
   on the roadmap; this epic is its catalogue and its acceptance home.
2. **Document** the result as a v3.x **DSL catalogue** — forward-only, per-feature, queryable by an agent one
   feature at a time.

## What this catalogue is NOT

- **Not a v1↔v3 matrix.** The [`../emq.command-registry.md`](./emq.epic.1/emq.commands.registry.md) (the v1→v3 command
  registry — the feature-sorted successor to the former 1290-line `emq.1.specs.md` matrix) is a
  **development-supporting artifact** — a reference for *why* each v3 form re-derives its v1 analogue — never the
  catalogue. The v1 corpus (`../../../echo/apps/echomq/scripts/commands/`) is likewise read-only reference.
- **Not prose-per-command in one file.** The monolith failure mode (emq.epic.0 rationale) is the thing this
  epic exists to avoid.

## The DSL form (D0-2 — the near-term grammar)

The catalogue lives in [`./emq.epic.1/`](./emq.epic.1/) as **one md per feature** (`<feature>.md`). Each command
is an **`#{command}`-anchored section** inside its feature md, cross-referenced by that hash within and across
feature files. Each command section carries exactly these fields (and only what is relevant):

- **feature** — the capability it serves.
- **decision** — the v3 design choice (the v2-law re-derivation; the seam it keeps or drops).
- **BCS** — what the Branded Component System needs from it (the property it must carry).
- **EchoMesh** — its place on the CAP dial (consistency-first ↔ availability-first), proposed voice.
- **use-cases** — the real consumer scenarios (codemoji scoring / prize settlement, the operator runbook, …).
- **Given/When/Then** — acceptance in **Elixir**, referencing the executable story under
  [`../stories/`](../stories/) (`docs/echo_mq/stories/<feature>.stories.md`, generated from a story test —
  never hand-edited).

`#{command}` is the near-term DSL grammar: a stable anchor an agent (or a reader) resolves to one command's
definition without loading the feature, let alone the catalogue.

## The feature index (the catalogue)

The capability cut — *features*, not the mechanical command families of the dev-support matrix. Each row is a
slice `emq.epic.1/<feature>.md`; the v1 commands named are the **dev-support reference** that slice re-derives.

| Feature | What v3 covers | Builds on (rung) | v1 dev-support reference |
|---|---|---|---|
| **admission** | enqueue: immediate · delayed (visibility-fence) · idempotent | emq.0/emq.1 | addStandardJob · addDelayedJob · addPrioritizedJob |
| **scheduling** | run-at / run-in on one schedule set; promote | emq.1 | addDelayedJob · changeDelay · promote |
| **repeat** | repeatable registry; fresh-mint per occurrence; the pump cadence | emq.1 | addRepeatableJob · add/get/remove/updateJobScheduler · updateRepeatableJobMillis · removeRepeatable |
| **claim** | single-writer fetch; server-clock lease; attempts fence | emq.1 | moveToActive · moveJobFromActiveToWait · moveJobsToWait |
| **retry** | retry/backoff; the dead-letter morgue; reprocess | emq.1 | retryJob · reprocessJob · moveToDelayed |
| **flows** | parent/child fan-in; child-result reads; failure-policy + bulk | emq.3.1–3.4 | addParentJob · moveToWaitingChildren · removeChildDependency · removeUnprocessedChildren |
| **groups** | fair lanes (per-player/per-tenant); the rotating ring (priority's replacement) | emq.2/emq.4 | addPrioritizedJob · changePriority · getCountsPerPriority |
| **batches** | bulk add (`add_bulk`); bulk move/clean by window | emq.3.4 | add_bulk parity · moveJobsToWait · cleanJobsInSet |
| **locks** | lease extend (single + batch); release; stalled recovery | emq.2.3 | extendLock(s) · releaseLock · moveStalledJobsToWait |
| **metrics** | counts · state · throughput · introspection · membership | emq.2.1 | getCounts · getState(V2) · getMetrics · getRanges · isMaxed · isFinished · isJobInList · paginate · getRateLimitTtl · getDependencyCounts |
| **data** | update data/progress; logs; failure record | emq.2.2 | updateData · updateProgress · addLog · saveStacktrace |
| **lifecycle** | remove · dedup release · drain · obliterate · pause/resume | emq.2.2 | removeJob · removeDeduplicationKey · drain · obliterate · pause |

(The feature set is the catalogue's index; the Director curates it as the rewrite ships. `groups` and `batches`
are first-class features, not buried under a command family.)

## Scope

- **In** — the per-feature v3.x command DSL slices under `emq.epic.1/`; the epic's stories
  ([`./emq.epic.1/emq.1.stories.md`](./emq.epic.1/emq.1.stories.md)); the forward-only voice (v3 is PROPOSED
  until its rung ships); the `#{command}` cross-reference grammar.
- **Out** — the v1↔v3 **registry** as a deliverable (it is dev-support, the feature-sorted
  [`../emq.command-registry.md`](./emq.epic.1/emq.commands.registry.md) — successor to the former `emq.1.specs.md` matrix);
  the actual code rewrite (that is the roadmap's rungs — this epic catalogues and accepts it, it does not build
  it); any per-command file that would re-introduce the monolith.

## Acceptance — "catalogued" means

- Every feature slice exists under `emq.epic.1/`, each command an `#{command}`-anchored section with the six
  fields; an agent can load one feature and find every command in it (completeness is structural).
- Every command's Given/When/Then references an executable story under `../stories/` (generated, not asserted).
- No slice mentions a v1↔v3 matrix; every v3 claim is forward/PROPOSED until its rung is SHIPPED, then synced to
  the as-built present tense (the lag-1 reconcile, one altitude up).
- The catalogue is grounded NO-INVENT: every BCS/EchoMesh claim traces to the manuscripts; every v2-law claim to
  the design canon; every dev-support reference to a real v1 command.

---

Index: [emq.epic.0](./emq.epic.0.md) (the layer) · slices: [`./emq.epic.1/`](./emq.epic.1/) · stories:
[`../stories/`](../stories/) · dev-support: [`../emq.command-registry.md`](./emq.epic.1/emq.commands.registry.md) · the
rung layer: [`../specs/`](../specs/).
