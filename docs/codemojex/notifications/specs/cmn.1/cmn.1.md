# cmn.1 — BCS entities + brands + RecipientGroup resolution

> **Status:** SPEC (Venus). Source of truth = this body. DESIGN/SPEC ONLY — Mars builds. Canon:
> `docs/codemojex/notifications/notifications.design.md` §2 (the BCS entity/component model).
> **Risk:** LOW (pure data + resolution; no send, no wire, no Lua).

## 1. Intent

Found the four BCS entities of the Broadcast system as **components-as-data** with **branded-id identities**,
plus `RecipientGroup` audience resolution. This rung ships the *vocabulary and the audience*, not the send
path (cmn.2) or persistence (cmn.3). It is the BCS foundation: entities are branded identities, their data
are plain bundles, and the only values crossing a boundary are identities and messages about identities
(`mesh.8.1`).

## 2. Deliverables

| # | Deliverable | Surface |
|---|---|---|
| D1 | `BroadcastTemplate` component + constructor | `Codemojex.Broadcast.Template` (new) — brand `BTP` |
| D2 | `Broadcast` component + initial state | `Codemojex.Broadcast` (new) — brand `BCA`, state `:scheduled` at construction |
| D3 | `BroadcastDelivery` component + constructor | `Codemojex.Broadcast.Delivery` (new) — brand `BDV` |
| D4 | `RecipientGroup` component + **resolution** | `Codemojex.Broadcast.RecipientGroup` (new) — brand `RGP`; `resolve/1..2` over `[all, admin, group_of_n, from_csv]` |
| D5 | Brand registration | `BTP`/`BCA`/`BDV`/`RGP` minted via `EchoData.BrandedId.generate!/1` |

## 3. Surface contracts

> Real grounding: `EchoData.BrandedId.generate!/1` (`echo/apps/echo_data/lib/echo_data/branded_id.ex:93`)
> mints a 14-byte typed snowflake from a 3-byte namespace; `valid?/1` (`:95`). The codemojex player store is
> `Codemojex.Store` (`store.ex`) — `RecipientGroup.all` resolves from it (D-6 confirms the exact read).

### 3.1 `BroadcastTemplate` (`BTP`)
- **Constructor** `new(attrs) :: %Template{}` — fields: `id` (minted `BTP`), `content` (text with
  placeholders), `placeholders` (declared keys), `schedule` (`%{every_ms, first_in_ms}` | `%{at_ms}`),
  `period` (compaction window, ms), `default_opts` (keyword), `recipient_group` (`RGP` id — **a ref, never an
  embedded list**).
- **Pre:** `content` is a binary; `period` a positive integer; `recipient_group` a valid `RGP` id.
- **Post:** an immutable component bundle; `id` is a fresh `BTP` brand.
- **Invariant INV1:** the audience is referenced by `RGP` id, not embedded (the BCS law).

### 3.2 `Broadcast` (`BCA`)
- **Constructor** `new(template_id) :: %Broadcast{}` — fields: `id` (minted `BCA`), `template_id` (`BTP` ref),
  `recipient_group_id` (copied from the template — the audience snapshot ref), `state` (`:scheduled`),
  `started_at`/`completed_at` (nil), `totals` (`%{}`).
- **State machine (declared here; transitions ship in cmn.2):** the legal states are
  `:scheduled | :fanning_out | :draining | :compacting | :completed` and the legal edges are exactly
  `scheduled→fanning_out→draining→compacting→completed` (no skips, no back-edges).
- **Pre:** `template_id` is a valid `BTP` id.
- **Post:** `state == :scheduled`; `id` a fresh `BCA` brand.
- **Invariant INV2:** `state` is one of the five declared atoms; cmn.1 only constructs at `:scheduled`.

### 3.3 `BroadcastDelivery` (`BDV`)
- **Constructor** `new(broadcast_id, telegram_user_id, status, opts) :: %Delivery{}` — fields: `id` (minted
  `BDV` — **mint time = delivery time**), `broadcast_id` (`BCA` ref), `telegram_user_id`, `status`
  (`:delivered | :failed | :timed_out`), `message_id` (integer | nil), `reason`
  (`:blocked | :chat_not_found | :deactivated | :other | nil`), `attempt`.
- **Pre:** `status` in the closed set; `message_id` present iff `status == :delivered`; `reason` present iff
  `status != :delivered`.
- **Post:** a component bundle; `id` a fresh `BDV` brand (time-ordered).
- **Invariant INV3:** the `BDV` id is a branded snowflake — its mint order IS chronological order (the
  property cmn.3 compaction relies on; asserted here so the foundation is correct by construction).

### 3.4 `RecipientGroup` (`RGP`) — the audience + the failure sink
- **Constructor** `new(kind, params) :: %RecipientGroup{}` — fields: `id` (minted `RGP`), `kind`
  (`:all | :admin | :group_of_n | :from_csv`), `params` (kind-specific: `:group_of_n` → `%{n: …}`;
  `:from_csv` → `%{ids: [...]}`), `suppressed` (a set of suppressed `telegram_user_id`, initially empty).
- **`resolve(group) :: {:ok, [telegram_user_id]} | {:error, term}`** — resolves the kind to the recipient
  list, **minus** the suppression set:
  - `:all` — every known player id (from `Codemojex.Store`; exact read per D-6).
  - `:admin` — the configured admin chat set (config, per D-6).
  - `:group_of_n` — a bounded subset of `n` (a deterministic sample/cohort).
  - `:from_csv` — the `params.ids` list.
- **Pre:** `kind` in the closed set; `params` valid for the kind.
- **Post:** a list of `telegram_user_id`, with `suppressed` removed.
- **Invariant INV4:** `resolve` always subtracts `suppressed` (a suppressed chat is never returned — the
  feedback loop cmn.4 writes is honored at resolution).
- **Invariant INV5:** the suppression set is the `RGP`'s own state; feedback (cmn.4) is a message about ids
  (the suppressed `telegram_user_id`s), not an object graph.

## 4. Out of scope (named, to bound the rung)

- The send path, the state-machine **transitions**, `Throttle`, `EchoBot.deliver/3` widening → **cmn.2**.
- Batched persistence, compaction, the Result row → **cmn.3**.
- The cmn.4 **write** side of suppression (cmn.1 only *honors* `suppressed` at resolution) → **cmn.4**.
- Dashboard counters → **cmn.5**.

## 5. Acceptance (full Given/When/Then in `cmn.1.stories.md`)

Every Deliverable has a story; the Coverage map in the stories file proves D1–D5 → stories. Headlines:
- A template/broadcast/delivery/group constructs with a fresh, valid brand of the right namespace.
- A `Broadcast` constructs at `:scheduled`.
- A `BDV`'s id is a valid branded snowflake; two `BDV`s minted in order sort in mint order (INV3 — the
  chronological property, asserted positively, not assumed).
- `resolve` returns the right list per kind, with the suppression set subtracted (INV4).
- The audience is a ref on the template, never an embedded list (INV1).

## 6. Gate ladder (per-app, codemojex)

Re-probe `asdf current` / `.tool-versions` from `echo/apps/codemojex`; `TMPDIR=/tmp mix compile
--warnings-as-errors`; `TMPDIR=/tmp mix test` inside the app dir. No Valkey/wire is touched by cmn.1 (pure
data + resolution), so no `--include valkey`, no conformance change, no determinism loop (no id-mint hazard
beyond the standard branded mint, which `EchoData` already proves). A multi-seed construction sweep + an
honest determinism-posture statement suffices.
