# cmn.1 — agent brief (Mars build sheet)

> Derived FROM `cmn.1.md` (authoritative) + `cmn.1.stories.md`. Build to THIS; the body wins on any
> disagreement. DESIGN/SPEC doc — Mars writes the production code. No git.

## References (read first, in order)

1. **`docs/codemojex/notifications/notifications.design.md` §2** — the BCS entity/component model (brands,
   states, RecipientGroup). The why.
2. **`cmn.1.md`** — the surface contracts (§3) + invariants. The what.
3. **`echo/apps/echo_data/lib/echo_data/branded_id.ex`** — `generate!/1` (`:93`, mint from a 3-byte ns),
   `valid?/1` (`:95`), `decode/1` (`:55`). The id contract.
4. **`echo/apps/echo_data/lib/echo_data/bcs/`** — the reference BCS discipline (components-as-data,
   gate-on-namespace). Mirror the style; cmn.1 entities are plain structs (component bundles), not behaviour
   modules.
5. **`echo/apps/codemojex/lib/codemojex/store.ex`** — `Codemojex.Store` (the player store `:all` resolves
   from). `notifier.ex` — the existing `NOT`-brand mint pattern to mirror for the new brands.

## Requirements (numbered; each traces to a story + an invariant)

| R | Requirement | Story | Invariant |
|---|---|---|---|
| R1 | `Codemojex.Broadcast.Template.new/1` builds the `BTP` component; audience is an `RGP` **id ref** | S1 | INV1 |
| R2 | `Codemojex.Broadcast.new/1` builds the `BCA` component at `state: :scheduled`; the five legal states + edges are declared (transitions in cmn.2) | S2 | INV2 |
| R3 | `Codemojex.Broadcast.Delivery.new/4` builds the `BDV` component; id mint order = chronological order; `message_id`/`reason` presence rule | S3 | INV3 |
| R4 | `Codemojex.Broadcast.RecipientGroup.new/2` + `resolve/1..2` over `[all, admin, group_of_n, from_csv]`, subtracting `suppressed` | S4 | INV4 |
| R5 | the `RGP` `suppressed` set is the group's own state (cmn.1 ships the field + resolution-time subtraction; cmn.4 ships the writer) | S5 | INV5 |
| R6 | brands minted are exactly `BTP`/`BCA`/`BDV`/`RGP`, all `valid?/1`, no collision | S6 | — |

## Execution topology

**Runtime shape:** pure data + a resolution function. No process, no wire, no Lua, no Valkey. The entities
are structs constructed and passed; `RecipientGroup.resolve` reads the player store / config and returns a
list. (The processes — the `Broadcast` state machine as an owning system — arrive in cmn.2.)

**Build-order DAG (within cmn.1):**
```
brands (R6) ─┬─▶ Template (R1) ─┐
             ├─▶ Broadcast (R2) │
             ├─▶ Delivery (R3)  ├─▶ (all four constructible) ─▶ RecipientGroup.resolve (R4,R5)
             └─▶ RecipientGroup new (R4) ─┘
```

**Exact files touched (NEW unless noted):**
- `echo/apps/codemojex/lib/codemojex/broadcast/template.ex` — `Codemojex.Broadcast.Template`
- `echo/apps/codemojex/lib/codemojex/broadcast.ex` — `Codemojex.Broadcast` (the BCA component + state decls)
- `echo/apps/codemojex/lib/codemojex/broadcast/delivery.ex` — `Codemojex.Broadcast.Delivery`
- `echo/apps/codemojex/lib/codemojex/broadcast/recipient_group.ex` — `Codemojex.Broadcast.RecipientGroup`
- `echo/apps/codemojex/test/codemojex/broadcast/*_test.exs` — the S1–S6 acceptance tests
- (no change to `application.ex` in cmn.1 — nothing supervised yet)

## Agent stories (Directive + Acceptance gate)

- **A1 — Brands.** *Directive:* mint each entity under its namespace via `BrandedId.generate!/1`.
  *Acceptance:* S6 — namespaces are `BTP`/`BCA`/`BDV`/`RGP`, all `valid?/1`.
- **A2 — Template.** *Directive:* build the `BTP` component (content, placeholders, schedule, period,
  default_opts, `recipient_group` id-ref). *Acceptance:* S1 — fresh `BTP`; audience is an id, not a list
  (INV1).
- **A3 — Broadcast.** *Directive:* build the `BCA` component at `:scheduled`; declare the five states + the
  legal edges (no transition logic yet). *Acceptance:* S2 — `state == :scheduled`, a member of the five
  (INV2).
- **A4 — Delivery.** *Directive:* build the `BDV` component with the presence rule; ids time-ordered.
  *Acceptance:* S3 — two minted in order sort in mint order (INV3, positive proof); presence rule holds.
- **A5 — RecipientGroup.** *Directive:* build the `RGP` with a `suppressed` set; `resolve` each kind minus
  suppression. *Acceptance:* S4 (non-empty suppression subtracted; per-kind lists), S5 (suppressed is the
  group's own state) — INV4, INV5.

## Gate (run before reporting)

From `echo/apps/codemojex`: re-probe `asdf current`; `TMPDIR=/tmp mix compile --warnings-as-errors`;
`TMPDIR=/tmp mix test`. No Valkey, no conformance, no determinism loop (pure data). Report the multi-seed
construction sweep + an honest determinism-posture line.

## Prompt (the comprehensive task — no decision left open the body has not fixed)

> Build cmn.1: the four BCS Broadcast entities as component-bundle structs under
> `echo/apps/codemojex/lib/codemojex/broadcast/`, each minted under its 3-letter brand
> (`BTP`/`BCA`/`BDV`/`RGP`) via `EchoData.BrandedId.generate!/1`. `Template` carries content + placeholders +
> schedule + period + default_opts + an `RGP` id-ref (never an embedded recipient list). `Broadcast` is born
> at `state: :scheduled` and declares the five legal states `{scheduled, fanning_out, draining, compacting,
> completed}` (NO transition logic — that is cmn.2). `Delivery` carries
> `(telegram_user_id, status, message_id, reason, attempt)` with the presence rule (message_id iff delivered;
> reason iff not), its `BDV` id time-ordered. `RecipientGroup` carries `kind ∈ {all, admin, group_of_n,
> from_csv}`, kind params, and a `suppressed` set, and `resolve/1..2` returns the recipient list per kind
> MINUS the suppression set (`:all` from `Codemojex.Store`, `:admin` from config). Write the S1–S6 acceptance
> tests (S3 proves the chronological order POSITIVELY with ≥2 mints; S4 proves subtraction with a NON-EMPTY
> suppression set). Frame propagation: no gendered pronouns for agents; no perceptual/interior verbs; no
> first-person narration. Run the codemojex gate (`TMPDIR=/tmp`, warnings-as-errors) before reporting.
