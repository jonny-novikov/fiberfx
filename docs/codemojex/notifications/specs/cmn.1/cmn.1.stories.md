# cmn.1 — acceptance stories (Given/When/Then)

> Derived FROM `cmn.1.md` (the body is authoritative; if these disagree, the body wins). Each story is
> Connextra form + Gherkin acceptance, names the invariant(s) it exercises (INVEST), and the Coverage map
> proves every Deliverable → its story.

## Story S1 — Template is a reusable definition referencing its audience (D1, INV1)

**As a** broadcast author, **I want** a `BroadcastTemplate` carrying content + placeholders + schedule +
period + a *reference* to its audience, **so that** one definition drives many runs and the audience is not
copied into the template.

- **Given** a valid `RGP` id and a content string with placeholders,
- **When** `Template.new/1` is called with content, placeholders, schedule, period, default_opts, and the
  `RGP` id,
- **Then** the returned template has a fresh `BTP` brand (`BrandedId.valid?/1` true, namespace `"BTP"`),
- **And** its `recipient_group` field is the `RGP` **id** (not a list of recipients) — INV1.

## Story S2 — Broadcast is born scheduled (D2, INV2)

**As a** broadcast author, **I want** a `Broadcast` instance to start in the `:scheduled` state, **so that**
the lifecycle begins before any fan-out and the state machine has a well-defined entry.

- **Given** a valid `BTP` template id,
- **When** `Broadcast.new/1` is called,
- **Then** the broadcast has a fresh `BCA` brand,
- **And** `state == :scheduled`,
- **And** `state` is one of the five declared atoms `{:scheduled, :fanning_out, :draining, :compacting,
  :completed}` — INV2.

## Story S3 — A delivery is chronological by construction (D3, INV3)

**As a** the compaction handler (cmn.3), **I want** each `BroadcastDelivery` keyed by a time-ordered branded
snowflake, **so that** results compact in chronological order with no sort and no timestamp column.

- **Given** a `BCA` broadcast id and a recipient,
- **When** two `Delivery.new/4` records are minted in succession,
- **Then** each has a fresh `BDV` brand of namespace `"BDV"`,
- **And** the second's id sorts AFTER the first's (mint order = chronological order) — INV3 *(positive proof:
  the test mints ≥2 and asserts the ordering; it does not assume it).*
- **And** a `:delivered` record carries a non-nil `message_id` and nil `reason`; a `:failed`/`:timed_out`
  record carries a `reason` from the closed set and nil `message_id`.

## Story S4 — RecipientGroup resolves each audience kind, minus suppression (D4, INV4)

**As a** the send path (cmn.2), **I want** `RecipientGroup.resolve` to return the recipient list for each
kind with suppressed chats removed, **so that** a broadcast fans out to exactly the live audience.

- **Given** a `RecipientGroup` of kind `:from_csv` with ids `[a, b, c]` and a suppression set `{b}`,
- **When** `resolve/1` is called,
- **Then** the result is `{:ok, [a, c]}` — the suppressed `b` is absent (INV4).
- **And** for kind `:group_of_n` with `n`, the result has at most `n` recipients;
- **And** for kind `:all`, the result is the known-player set (from `Codemojex.Store`) minus suppression;
- **And** for kind `:admin`, the result is the configured admin set.

## Story S5 — Suppression is the group's own gated state (D4, INV5)

**As a** the failure-feedback loop (cmn.4), **I want** the suppression set to live ON the `RecipientGroup` as
its own state, **so that** feedback is a message about identities, not a shared object graph.

- **Given** a `RecipientGroup`,
- **When** its `suppressed` set is inspected,
- **Then** it is a set of `telegram_user_id` values owned by the group (initially empty),
- **And** nothing outside the group holds a reference into its internal state — INV5 *(the cmn.4 write API
  is the only mutator; cmn.1 ships the field + the resolution-time subtraction)*.

## Story S6 — Brands are distinct, typed namespaces (D5)

**As a** the system, **I want** each entity minted under its own 3-letter brand, **so that** identity is the
type checked at every boundary.

- **Given** the four constructors,
- **When** each mints its id,
- **Then** the namespaces are exactly `BTP` (template), `BCA` (broadcast), `BDV` (delivery), `RGP` (group),
- **And** all four pass `EchoData.BrandedId.valid?/1`,
- **And** none collides with an existing codemojex/echo brand.

---

## Coverage map (every Deliverable → its story)

| Deliverable | Story | Invariant(s) |
|---|---|---|
| D1 `BroadcastTemplate` | S1 | INV1 |
| D2 `Broadcast` (+ states) | S2 | INV2 |
| D3 `BroadcastDelivery` | S3 | INV3 |
| D4 `RecipientGroup` + resolve | S4, S5 | INV4, INV5 |
| D5 brand registration | S6 | — |

**Gate-liveness note:** S3's INV3 is proved POSITIVELY — the test mints ≥2 deliveries and asserts the
second sorts after the first; a no-op that mints zero or one must NOT satisfy the story. S4's suppression
subtraction is proved with a NON-EMPTY suppression set (a present precondition that actually exercises the
subtraction), not an empty one that would pass vacuously.
