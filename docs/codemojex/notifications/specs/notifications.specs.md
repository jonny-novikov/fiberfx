# codemojex Broadcast System — spec index + rung ladder

> The spec-driven build plan for the v2 BCS Broadcast architecture. **Canon:**
> `docs/codemojex/notifications/notifications.design.md` (the design is authoritative; these specs derive
> from it). **Source of truth per rung:** the `<rung>.md` body (the `.stories.md` + `.llms.md` may lag — the
> body wins). DESIGN/SPEC ONLY; Mars builds to the per-rung `.llms.md` brief.

## The ladder

| Rung | Title | App | Risk | Depends | Triad |
|---|---|---|---|---|---|
| **cmn.1** | BCS entities + brands + RecipientGroup resolution | codemojex | LOW | — | `cmn.1/` ✅ authored |
| **emq.throttle** | `EchoMQ.Throttle` — Valkey server-clock token bucket | echo_mq | **HIGH** | — | `emq.throttle/` ✅ authored |
| **cmn.2** | Broadcast state machine + send path (Throttle-gated fan-out) | codemojex | MED | cmn.1, emq.throttle | stub below |
| **cmn.3** | Batched durability + chronological compaction → Result row | codemojex | MED | cmn.2 | stub below |
| **cmn.4** | RecipientGroup failure feedback (403 → suppression) | codemojex | MED | cmn.3 | stub below |
| **cmn.5** | Dashboard counters (Valkey HINCRBY live tiles) + read API | codemojex | LOW | cmn.3 | stub below |

**Build order:** cmn.1 → emq.throttle → cmn.2 → cmn.3 → cmn.4 → cmn.5.
emq.throttle is independent of cmn.1 (parallelizable); cmn.2 needs both. **emq.throttle is HIGH-risk** —
Apollo mandatory (a new process/keyspace surface under the wire master invariant); the rest are normal-risk
(Apollo optional fast-finisher).

## Brands (assigned; verified free against the taken set)

`BroadcastTemplate` = **BTP** · `Broadcast` = **BCA** · `BroadcastDelivery` = **BDV** · `RecipientGroup` =
**RGP**. Minted via `EchoData.BrandedId.generate!/1`. `BDV` time-ordering is load-bearing (free chronological
compaction).

## The conformance pin (echo_mq)

`EchoMQ.Conformance.run/2 → {:ok, 59}` today (`apps/echo_mq/test/conformance_run_test.exs:48`). emq.throttle
adds ONE scenario → re-pin to `{:ok, 60}` in both pinning tests under the additive-minor law (prior
scenarios byte-unchanged + git-verified, the new one probe-registered).

---

## Stubs — cmn.2 .. cmn.5 (carve next; the design §2–§6 is the source)

### cmn.2 — Broadcast state machine + send path
- **Deliverable:** the `Broadcast` (BCA) lifecycle `scheduled → fanning_out → draining → compacting →
  completed`; schedule via `EchoMQ.Repeat.register/6` / `Jobs.enqueue_at/6`; audience resolution from the
  `RGP`; fan-out (Flow parent→children per D-4) of per-recipient sends; each send gated by
  `EchoMQ.Throttle.take` (27/s) **then** the per-chat `RateLimiter` (1/s); `EchoBot.deliver/3` widened to
  `{:ok, %{message_id: id}}`; a `BDV` produced per terminal outcome.
- **Invariants:** ack/retry/drop control flow byte-identical to today (over-budget → `enqueue_in` defer+ack,
  never block/drop); the throttle gate precedes the per-chat gate; state transitions are the only writers of
  the BCA state component.
- **Stories to derive:** schedule fires → fanning_out; throttle refuses past 27/s → defer; per-recipient
  delivery produces a BDV; success carries message_id; the machine reaches draining when fan-out completes.

### cmn.3 — Batched durability + compaction
- **Deliverable:** batched `BDV` writes (`batch_size`, default 500); crash-resume from the last persisted
  batch; the `compacting` handler folding `BDV` records in `BDV`-id (chronological) order via
  `EchoData.Timeline` into ONE Result array; the `Codemojex.Schemas.BroadcastResult` row (`deliveries` +
  `failures` + `totals`); trim transient `BDV` records at compaction.
- **Invariants:** compaction order = mint order (no sort — the snowflake property); 100k `BDV` → 1 Result
  row + 0 transient records; the `failures` column extracts without a full-array scan; a persistence failure
  never crashes the run.
- **Stories:** N deliveries compact to 1 row in chronological order; failures land in the `failures` column;
  transient records trimmed; crash mid-run resumes from the last batch.

### cmn.4 — RecipientGroup failure feedback
- **Deliverable:** on BCA completion, every `status ∈ {blocked, chat_not_found, deactivated}` recipient is
  added to the `RGP` suppression set (or a failed-group); the next broadcast's resolution excludes the
  suppression set.
- **Invariants:** suppression is permanent (re-subscribe is a separate opt-in); feedback is a message about
  identities (the suppressed ids), not an object graph; the `RGP`'s suppression set is its own gated state.
- **Stories:** a 403 suppresses that user; the next broadcast skips suppressed recipients; a transient
  failure does NOT suppress.

### cmn.5 — Dashboard counters
- **Deliverable:** Valkey `HINCRBY` per `broadcast × status × reason` (key `cm:bcast:rollup:{<BCA-id>}`) +
  per-day rollup; ticked during `draining`; TTL = period + grace; the read API (`HGETALL` + the Result
  `totals`/`failures`).
- **Invariants:** counters are codemojex app keys (NOT the `emq:{q}:` grammar); best-effort (a lost
  increment self-heals from the Result `totals`); bounded by cardinality (1 hash/broadcast).
- **Stories:** a delivery increments the right counter; `HGETALL` matches the broadcast's tallies; a lost
  increment is reconciled by the Result.
