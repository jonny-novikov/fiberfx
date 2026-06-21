# EMQ3.1 · the build orchestration runbook — the stream verbs on the connector (S1 the writer, part 1)

> The authoritative run scope for shipping emq3.1 via `/echo-mq-ship` (Flat-L2, Director-supervised). The body
> ([`emq3.1.md`](emq3.1.md)) is the contract; the acceptance is [`emq3.1.stories.md`](emq3.1.stories.md); the Mars
> brief is [`emq3.1.llms.md`](emq3.1.llms.md). This runbook binds them to the pipeline stages + the gate ladder +
> the risk tier. **No decision the body has fixed is left open here — EXCEPT the four forks (3.1-A the verb-landing
> mechanism, 3.1-B the stream keyspace + the count delta, 3.1-C the version label, 3.1-D the push-safety /
> blocking-read boundary), which the Operator rules at the pre-build reconcile (the Director routes via
> AskUserQuestion). FORK 3.1-A is the ONLY one that changes the risk tier** — the recommended arm (ride the generic
> command path) is NORMAL; the frozen-touch arm (extend the connector) is HIGH (a frozen-line touch →
> Apollo-mandatory). 3.1-B/C/D do not change the tier (3.1-B is the key-type + conformance bookkeeping; 3.1-C is the
> label plane; 3.1-D's recommended bound is non-blocking — only a ruled BLOCK-now would add wire-hazard surface).
>
> **Framing law (propagated).** Third person for any agent; no gendered pronouns for agents; no perceptual or
> interior-state verbs for agents or software; no first-person narration. Bind this same clause in any sub-brief.

## The tier in one paragraph

EchoMQ 3.0 — the Stream Tier ([`../../emq.streams.md`](../../emq.streams.md), the Operator-blessed ladder) builds
**event streams on the certified wire under the v2 laws, no second protocol**, across six dependency-ordered rungs
in three milestones: **S1 the writer** (emq3.1 the verb floor — THIS rung; emq3.2 `EchoMQ.Stream` the writer law,
branded record ids, append == mint) → **S2 the readers** (emq3.3 consumer groups + the polyglot seam; emq3.4
retention as policy) → **S3 the memory** (emq3.5 the archive folded to the `Graft` engine; emq3.6 time-travel +
hydration). The tier hard-gates on `emq.0` ONLY (met) and stands on the closed BCS substrate — no Stream rung
depends on the parked emq.6/7/8 families. The version plane is additive-minor; the `echomq:3.0.0` MAJOR is a
DEFERRED cutover ratification (declared when the tier is whole). emq3.1 lands FIRST — emq3.2–3.6 each ride the
proven verb floor.

## The rung in one paragraph

emq3.1 builds the **stream-verb floor**: the five stream verbs (`XADD` · `XRANGE` · `XREADGROUP` · `XACK` ·
`XAUTOCLAIM`) reachable + proven on the certified connector — round-trips, a pipelined `XADD` batch, push-safe under
RESP3. The mechanism is the certified-wire posture: the as-built `EchoMQ.Connector` is ALREADY a generic RESP client
(`command/3` takes `(conn, parts, timeout)`; `RESP.encode/1` is verb-agnostic — `connector.ex:47-54`, `resp.ex:20-28`),
so the verbs ride the shipped generic command path with ZERO `echo_wire` edit (the recommended FORK 3.1-A arm). The
stream key is `emq:{q}:stream:<name>` (a NEW §6 braced type via the total `queue_key/2`, no grammar edit — FORK
3.1-B). The writer LAW (`EchoMQ.Stream`, branded record ids, append == mint) is emq3.2, NOT this rung; the blocking
consumer-group read (`XREADGROUP BLOCK`) is emq3.3, NOT this rung (FORK 3.1-D — emq3.1 scopes to non-blocking
round-trips). All under the v2 master invariant (braced keyspace · branded `JOB` ids gated · declared keys A-1 · the
server clock where leases are touched [none here] · inline `Script.new/2` [none added] · additive-minor conformance
· additive registration is a protocol minor).

## Mode

**Flat-L2, Director-supervised.** Venus (reconcile/author the triad — DONE; loads `echo-mq-architect`) → Mars-1
(build to the brief — `echo-mq-implementor`) → Director solo review (independent gate re-run on Valkey 6390 + an
adversarial probe + a net-zero mutation spot-check) → Mars-2 (remediate + harden) → Director ship (one LAW-4
pathspec commit). **Apollo (`echo-mq-evaluator`) is an OPTIONAL fast-finisher on the recommended FORK 3.1-A arm**
(closure + stories) — verb plumbing, no shipped-script edit, no new process. **IF FORK 3.1-A is ruled the
frozen-touch arm, Apollo is MANDATORY** (a frozen-line touch — the most fenced act of the master invariant). The
≥100 determinism loop is NOT the proof here (a verb-plumbing rung mints no id and starts no process — a multi-seed
sweep is the honest posture, FORK 3.1-D/INV8).

## The forks are OPEN — the Operator's pre-build decisions (the recommended arm is the strawman)

> **The four forks are surfaced four-part in the body ([`emq3.1.md`](emq3.1.md) §The rung's forks) — Rationale ·
> 5W · Steelman · Steward (the recommendation + the trade-off). Venus surfaced each re-grounded against the
> re-probed connector (`connector.ex:47-54`), the verb-agnostic codec (`resp.ex:20-28`), and the total `queue_key/2`
> (`keyspace.ex:13-15`); the Operator rules at the pre-build reconcile (the Director routes via AskUserQuestion).**
>
> - **FORK 3.1-A — the verb-landing mechanism → RECOMMEND: ride the existing generic command path (NORMAL).** The
>   reconcile proves the connector is already a generic RESP client (`command/3` + verb-agnostic `RESP.encode/1`), so
>   the verbs ride the shipped path with ZERO `echo_wire` edit. The steelman (a typed connector seam) is answered:
>   the typed ergonomics belong in emq3.2's `EchoMQ.Stream` module ABOVE the wire, and touching the frozen connector
>   converts NORMAL → HIGH for zero plumbing gain. **THIS is the only fork that changes the risk tier.**
> - **FORK 3.1-B — the stream keyspace + the count delta → RECOMMEND: `emq:{q}:stream:<name>` as a new §6 braced
>   type (via the total `queue_key/2`, no grammar edit), +1 conformance scenario (`stream_verbs`, 73 → 74).** The
>   braced per-queue grammar matches the tier's per-key hash-tagged design; one scenario gates the verb FLOOR as one
>   capability. The steelman (a cross-queue key, or a per-verb +5 decomposition) is answered: streams bind to a
>   queue's slot by design (the branded record id is minted in that queue's universe), and the per-verb behavior is
>   gated at the rungs that build it (emq3.3/3.4).
> - **FORK 3.1-C — the version label → RECOMMEND: a MINOR step `2.5.2` → `2.6.0` (open the Stream Tier family).**
>   The position-encoded convention resets the patch on a family-opening (the emq.5.1 `2.5.0` precedent); the Stream
>   Tier unambiguously opens a new milestone family. The WIRE stays `echomq:2.4.2` (the deferred cutover) either way.
> - **FORK 3.1-D — push-safety / blocking reads → RECOMMEND: non-blocking round-trips only; DEFER `XREADGROUP BLOCK`
>   to emq3.3.** A `BLOCK` command on the single-owner socket stalls every caller behind it; the blocking read is
>   meaningless without the consumer-group lifecycle (emq3.3). The honest bound: emq3.1 is the verb reach
>   (non-blocking), emq3.3 is the readers (blocking + the group lifecycle, designed against the single-owner socket).
>
> **The label (recommended):** the rung steps to **`2.6.0`** (`mix.exs:7`, opening the Stream Tier family — FORK
> 3.1-C); the wire `@wire_version` stays FROZEN at `echomq:2.4.2` (the two-planes model, the deferred cutover). The
> risk tier (recommended): **NORMAL + a multi-seed sweep** (no id mint, no process in the verb path).

## The as-built floor (re-probed at Venus's reconcile, this run — Mars RE-PROBES each at Stage-0; the lag-1 law)

- **Toolchain:** Erlang 28.5.0.1 / Elixir 1.18.4 (`echo/.tool-versions`, re-probe `asdf current` from the app dir).
  Valkey on **6390** → PONG. `{emq}:version` = `echomq:2.4.2` == `@wire_version` (the boot fence passes).
- **THE LOAD-BEARING RECONCILE — the connector is ALREADY a generic RESP client (the FORK 3.1-A answer):**
  `Connector.command/3` (`connector.ex:47-54`) takes `(conn, [parts], timeout)`, `parts :: [binary() | integer() |
  atom()]`; it is `pipeline(conn, [parts], timeout)` of one. `RESP.encode/1` (`resp.ex:20-28`) encodes `[verb |
  args]` as `*N\r\n` + a `$len` bulk per element — `bulk/1` over binary/integer/atom/iodata, NO command whitelist.
  So `XADD foo * f v` is just another `parts` list → **emq3.1 rides the shipped path, ZERO `echo_wire` edit
  (NORMAL).** The moduledoc names it: *"a purpose-built Valkey client … pipelining as the primitive"*
  (`connector.ex:2-10`).
- **`pipeline/3` (connector.ex:56-60) — the pipelined `XADD` batch path:** a list of command-lists → `{:ok,
  [reply]}` in call order (the FIFO pairing). `EchoWire.Pipe.command/2` (`pipe.ex:496-497`) appends a raw
  command-list verbatim (the ewr.1.2 escape hatch; `exec/1` = one `pipeline/3` call, `pipe.ex:16-22`).
- **`RESP.parse/1` (resp.ex:45-87) — the verb-agnostic decoder:** arrays (`*`, `:59`) → lists (an `XRANGE` reply is
  a nested array `[id, [field, value, …]]`), maps (`%`, `:63`), error replies as values (`{:error_reply, msg}`,
  `:47`), **push frames (`>`) → `{:push, […]}` out of band (`:60`)** — the moduledoc `:13-15`.
- **`push_command/3` (connector.ex:99-102) — the SUBSCRIBE-family out-of-band path:** *"Send a command whose replies
  arrive out of band … Requires a RESP3 connection."* The precedent for the blocking-read path (emq3.3, deferred —
  FORK 3.1-D). emq3.1 does NOT use it (the non-blocking verb forms round-trip on the FIFO via `command/3`).
- **`Keyspace.queue_key/2` (keyspace.ex:13-15) — the total braced grammar:** builds `emq:{q}:<type>` for ANY
  `<type>`, the hash applied transparently. `emq:{q}:stream:<name>` rides it with NO grammar edit (FORK 3.1-B);
  `slot/1` (`keyspace.ex:43-44`) is the CRC16 over the hashtag, so a stream key and that queue's `pending` key share
  a slot. No `stream`-specific code exists yet (`grep -i stream lib/echo_mq/keyspace.ex` = 0; `EchoMQ.Stream` does
  NOT exist — it is emq3.2).
- **`EchoMQ.Events` (events.ex) — the ephemeral pub/sub seam, the push-safety counterpart:** subscribes over
  `Connector.subscribe/2`, dispatches on `{:emq_push, …}` (`events.ex:7-15`); explicitly defers the durable stream —
  *"the durable replayable receipt is emq3.2's `EchoMQ.Stream`, not this"* (`events.ex:36`). emq3.1's push-safety
  proof (US3) round-trips a stream IN BAND while this seam delivers a push OUT of band.
- **Conformance = 73 (LIVE):** `conformance_run_test.exs:58` `{:ok, 73}`; `conformance_scenarios_test.exs`
  `@run_order` = 73 names (the keyword list in `conformance.ex` `scenarios/0`, `:95` onward — counted: 73 entries).
  The additive-minor law: extend `scenarios/0` + the probe in the SAME change, the prior 73 byte-unchanged, re-pin
  in both pins (FORK 3.1-B recommend +1 → 74).
- **The version model (two-planes, emq.4.3 D-4) — as built:** `mix.exs:7` version "2.5.2" = the rung LABEL read by
  nobody at runtime; `@wire_version` "echomq:2.4.2" = the wire constant, frozen by committed records. The rung label
  steps to **2.6.0** on the recommended FORK 3.1-C arm (opening the Stream Tier family — the position-encoded
  convention resets the patch). Conformance goes **73 → 74** (FORK 3.1-B recommend +1).

## The pipeline — the stages

### Stage 0/1 — Venus (architect): the triad + the pre-build reconcile + the forks surfaced — DONE
The triad is authored ([`emq3.1.md`](emq3.1.md) body authoritative; [`emq3.1.stories.md`](emq3.1.stories.md) +
[`emq3.1.llms.md`](emq3.1.llms.md) derived) with the reconcile deltas carried (the connector-is-a-generic-RESP-client
answer = ZERO `echo_wire` edit / NORMAL, the 73 count, the `emq:{q}:stream:<name>` key type via the total
`queue_key/2`, the `EchoMQ.Events` push-safety counterpart, the two-planes version) and the four forks surfaced
four-part with the recommended arm. **Director gate:** read the body + this runbook (the files, not the report);
route FORK 3.1-A/B/C/D to the Operator (AskUserQuestion) — FORK 3.1-A FIRST (it sets the risk tier); record the
rulings; then release Mars.

### Stage 1 — Mars-1 (implementor): build to the ruled arms
Re-probe the floor (Stage-0, the lag-1 law — every anchor above; CONFIRM the connector is a generic RESP client and
`grep claim_batch|stream|EchoMQ.Stream` the lib is greenfield for stream surface). Build **R1** (the five verbs
reachable through the ruled FORK 3.1-A path — the generic `command/3`, or the frozen-touch connector seam if ruled),
**R2** (the pipelined `XADD` batch), **R3** (push-safety under RESP3 — in-band verbs + an out-of-band push; no
`BLOCK`, the ruled FORK 3.1-D), **R4** (the `emq:{q}:stream:<name>` key type — the ruled FORK 3.1-B), **R5** (the
wire-frozen battery — `echo_wire` diff EMPTY on the recommended arm; `@wire_version` 2.4.2; no new script; §6
unedited), **R6** (the `stream_verbs` conformance scenario — FORK 3.1-B RULED +1 + the 73→74 re-pin in both pins),
and self-verify the per-app gate ladder + a **multi-seed sweep** (NOT the ≥100 loop — a verb-plumbing rung).
**Stories:** Mars writes the `:valkey` proof to US1 (the five verbs, a POSITIVE proof — each reply asserted against
the appended data) + US2 (the pipelined batch — N ids in order, read back in mint order) + US3 (push-safety — an
in-band stream round-trip + a concurrent out-of-band push). Cite the spec line for every public call; the verbs are
`parts` lists (NO new `Script.new/2`); the conformance additive-minor mechanics. Report the gate results before
going idle.

### Stage 2 — Director: solo review (a REAL pass)
Independent gate re-run on Valkey 6390 (not Mars's word): `compile --warnings-as-errors`, `mix test --include
valkey`, `Conformance.run/2 → {:ok, 74}`. The adversarial probes:
1. **The verb round-trip no-op-defeater** — for each of the five verbs, assert the reply against the APPENDED data
   (`XRANGE` reads back the exact `XADD`-appended entry; `XACK` returns 1 for a genuinely-pending entry); a
   round-trip that asserts nothing about the reply, or an `XRANGE` over an empty stream, is a vacuous pass (RED).
2. **The pipelined-order probe** — append N >= 2 entries in one pipeline → assert N ids in call order AND N entries
   read back in mint order; a 1-entry "pipeline" proves nothing (confirm N >= 2). Mutate the append to drop one →
   the batch must under-return (US2 RED).
3. **The push-safety probe** — round-trip an in-band stream sequence WHILE a push is published → assert BOTH the
   stream replies are correct AND the push is delivered out of band (the FIFO stays aligned); a proof with no
   concurrent push proves nothing. Grep the proof's verb forms for `BLOCK` → MUST be empty (FORK 3.1-D — the
   blocking read is emq3.3's).
4. **The stream-key slot probe** — `Keyspace.slot(queue_key(q, "stream:s"))` == `Keyspace.slot(queue_key(q,
   "pending"))` (same hashtag, same slot — the braced grammar); the §6 grammar in `keyspace.ex` unedited (`git diff
   keyspace.ex` empty).
5. **The wire-frozen battery** — the `echo_wire` `git diff` against HEAD is EMPTY (the recommended FORK 3.1-A arm —
   the connector untouched); `{emq}:version` reads `echomq:2.4.2`; NO new `Script.new/2` in the lib diff (`grep -c
   'Script.new'` on the lib diff = 0); the closed `EMQKIND`/`EMQSTALE` registry byte-unchanged. [On the
   frozen-touch arm: the one named connector seam is the only `echo_wire` edit — and Apollo is MANDATORY.]
6. **The additive-minor conformance** — the git-diff of `scenarios/0` shows ONLY the `stream_verbs` addition; the
   prior 73 byte-unchanged (name + contract + verdict body git-verified); both pins re-pin to 74;
   `Conformance.run/2` prints 74 lines.
7. **A net-zero mutation spot-check** — two distinct load-bearing tests proven to BITE (the verb round-trip
   assertion + the push-safety out-of-band delivery), reverted net-zero.

The **determinism posture is a multi-seed sweep** (a verb-plumbing rung — no id mint, no process in the verb path):
the Director runs several `--seed` values green and confirms the explicit determinism statement; the ≥100 loop is
NOT required here (stated honestly — IF the proof is found to mint a branded id, which it should not, the posture
flips to the loop).

### Stage 3 — Mars-2 (implementor): remediate + harden + the full gate ladder
Apply the Director's findings. Run the FULL per-app gate ladder + a multi-seed sweep. Wire-frozen + boundary +
FROZEN-WIRE confirmations (the `echo_wire` diff EMPTY on the recommended arm). Report (an interim before idle —
silence reads as a stall, emq.4.3 L-2).

### Stage 4 — Apollo (evaluator): OPTIONAL fast-finisher on the recommended arm (MANDATORY iff FORK 3.1-A frozen-touch)
On the recommended FORK 3.1-A arm (verb plumbing, no shipped-script edit, no new process): Apollo is an OPTIONAL
fast-finisher (closure + stories), NOT a ship precondition. **IF FORK 3.1-A is ruled the frozen-touch arm (a
connector edit), Apollo is MANDATORY** — the post-build reconcile (does the as-built code satisfy the spec's
promises?); the §11.2-charter adversarial verification (the wire-frozen / declared-keys / push-safety probes
applied to the connector edit); re-run the per-app gate ladder independently; re-verify the conformance count is
byte-unchanged with the new scenario probe-registered; sync the spec to what shipped; the mentoring loop.

### Stage 5 — Venus (architect): the post-build reconcile
Sync the triad to what shipped — the ruled verb-landing mechanism (the `echo_wire` disposition: EMPTY diff on the
recommended arm, or the named seam on the frozen-touch arm), the stream key type, the scenario set + the final count
N, the version label, the blocking-read bound (deferred to emq3.3). Surgical sync, body authoritative. (The
`emq3.1.md` body is edited at THIS stage — the as-built reconcile syncs the strawman POST-build, never pre-build;
the STRAWMAN banner flips to SHIPPED.)

### Stage 6 — Director: closure + ONE LAW-4 commit
One Director pathspec commit of the rung's measured surface (the code + the triad + the `emq3-1` ledger). Re-verify
`git diff --cached --name-only` is purely the rung before committing (the Operator pre-stages out-of-band — exclude
`AM`-status files); split an entangled tree into separate scoped commits per concern. Mark emq3.1 SHIPPED in the
roadmap/progress/`emq.streams.md`, note the Stream Tier verb floor landed (emq3.2 the writer law now rides the
proven verbs). No push unless asked.

## Risk tier — NORMAL (recommended FORK 3.1-A) + a multi-seed sweep

| Dimension | Grade |
|---|---|
| **Risk** | **NORMAL** (on the recommended FORK 3.1-A arm) — the verbs ride the shipped generic command path (ZERO `echo_wire` edit), no new script, no destructive at-rest op, no frozen-line edit, no new process, no wire break. **HIGH iff FORK 3.1-A is ruled the frozen-touch arm** (a connector edit — the most fenced act of the master invariant). |
| **Apollo** | **Optional fast-finisher** (closure + stories) on the recommended arm — NOT a ship precondition. **MANDATORY iff FORK 3.1-A frozen-touch** (a frozen-line touch). |
| **Determinism** | **A multi-seed sweep** + the explicit statement — REQUIRED; the **≥100 loop is NOT** (a verb-plumbing rung mints no branded id and starts no process in the verb path: the same-millisecond mint hazard the loop owns is ABSENT). Unlike emq.5.1 (which minted JOB-ids to flood the pending set + leased on the server clock → the loop required). IF the proof is found to mint a branded id (it should not — that is emq3.2's writer law), the posture flips to the ≥100 loop (the escalation named). |
| **Byte-freeze / wire** | `@wire_version` UNCHANGED at `echomq:2.4.2` (additive registration — the verbs are a protocol minor, not a wire edit); the `echo_wire` `git diff` EMPTY on the recommended arm; NO new `Script.new/2` (verb plumbing); the §6 grammar unedited; the closed `EMQKIND`/`EMQSTALE` registry byte-unchanged; `mix.exs` rung label → **2.6.0** (recommended FORK 3.1-C, opening the Stream Tier family, label-only). |

The grade is stated forward so the build runs at the right rigor the instant the Operator rules the four forks —
NORMAL on the recommended FORK 3.1-A arm, HIGH (Apollo-mandatory) on the frozen-touch arm.

## Acceptance — "shipped" means

- FORK 3.1-A/B/C/D ruled (the Operator's verb-landing + keyspace/count + label + push-safety/blocking calls
  recorded); the body re-derived to the ruled arms (Stage-5); the STRAWMAN banner flipped to SHIPPED.
- R1–R7 built and green: the five stream verbs reachable + proven on the certified connector (the ruled FORK 3.1-A
  path); the pipelined `XADD` batch (N ids in call order, read back in mint order); push-safety under RESP3 (in-band
  verbs + an out-of-band push; no `BLOCK` — the ruled FORK 3.1-D); the `emq:{q}:stream:<name>` §6 key type (the
  ruled FORK 3.1-B, via the total `queue_key/2`); the conformance scenario(s) (additive minor — prior 73
  byte-unchanged, re-pinned 73 → the ruled total in both pins); the wire-frozen battery (the `echo_wire` diff EMPTY
  on the recommended arm, `@wire_version` 2.4.2, no new script, §6 unedited).
- The proof: the `:valkey` stream-verb suite green per-app; a **multi-seed sweep** green (NOT the ≥100 loop — a
  verb-plumbing rung); honest-row (Valkey 6390). Apollo an optional fast-finisher (recommended arm) / mandatory
  (frozen-touch arm).
- INV1–8 verified as runnable checks; the body remains authoritative; the as-built reconcile syncs the strawman
  post-build (Stage-5); one LAW-4 pathspec commit (Stage-6); the Stream Tier verb floor landed (emq3.2 the writer
  law now rides the proven verbs).

## The Stage-6 commit pathspec (Director-only — the emq3.1 BUILD; adjust to the ruled touch-set)

```bash
# THE CODE (the additive touch-set, recommended FORK 3.1-A arm — NO echo_wire edit):
#   echo/apps/echo_mq/lib/echo_mq/conformance.ex   (the stream_verbs scenario + the count prose)
#   echo/apps/echo_mq/test/stream_verbs_test.exs   (the :valkey stream-verb proof — NEW; US1 + US2 + US3)
#   echo/apps/echo_mq/test/conformance_run_test.exs       (re-pin {:ok, 74})
#   echo/apps/echo_mq/test/conformance_scenarios_test.exs (re-pin @run_order → 74 names)
#   echo/apps/echo_mq/mix.exs                       (the rung label — 2.6.0, recommended FORK 3.1-C)
# THE DOCS:
#   docs/echo_mq/specs/emq3/emq3.1.{md,stories.md,llms.md,prompt.md}
#   docs/echo_mq/emq.streams.md                     (IFF a Stage-5 tier sync is needed — the emq3.1 SHIPPED note)
#   docs/echo_mq/specs/progress/emq3-1.progress.md  (+ the registry)
# EXCLUDED: echo_wire/* (UNTOUCHED on the recommended arm — the echo_wire diff MUST be EMPTY; the connector is the
#   one named seam touched ONLY if FORK 3.1-A is ruled the frozen-touch arm), keyspace.ex (no grammar edit),
#   jobs.ex/lanes.ex (no script edit), apps/echomq (the capability reference), mix.lock (no real dep moved),
#   the .claude/ calibration diffs (harness-fenced), any AM-status out-of-band file.
```
