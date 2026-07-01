# admin.5 desk ladder · framed forks & design decisions

Supplements the roadmap ([`admin.roadmap.md`](./admin.roadmap.md)) for the Shell desk ladder. admin.5.1 (rooms +
players list desks) is a full triad with **no open fork** — the client-side + frontend-only ruling is in hand.
admin.5.2 (master-detail) and admin.5.3 (the live game path) were **fork-heavy**: their interaction / integration
models were the Operator's call, so this doc framed each arm (Rationale · 5W · Steelman · Steward). **The Operator
has now RULED all three (ledger D-6):** each fork below carries a **RULED** banner naming its chosen arm, and the
arms are retained as decision-context. admin.5.2 is authored to a full triad on its ruling (Arm C); admin.5.3's
node-only interim direction is a strong design entry (its triad is authored at its own build run); admin.5.4 is a
roadmap entry on 5.4-a.
Index: [`admin.md`](./admin.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md).

## The grounded surface (what the forks rest on — no invention)

- **The detail routes (admin.1, shipped, Bearer-gated).** `GET /rooms/:id` → `RoomDetail = { room: RoomSummary,
  games: [{ id (GAM), status, free, prizePool, endsMs, insertedAt }] }`. `GET /players/:id` → `PlayerDetail = {
  player: PlayerSummary, guesses: [{ id (GES), gameId, points, atMs, insertedAt }], ledger: unknown[] }`. `GET
  /games/:id` → `GameDetail = { game: GameSummary, board: [{ player, score }], guesses: [GuessSummary] }`. So a
  **static** detail (a room's games, a player's guesses, a game's board + guesses) is buildable HTTP-only; the
  *live* game view is the one part that needs more than the read plane.
- **The game island** (`mercury/codemojex/apps/game/src/index.tsx`). The library-mount contract is `mount(el:
  HTMLElement, props: GameProps, bridge: Bridge) => { update, unmount }`. The island **owns its own React** (no
  shared-runtime contract with a host), is built by vite as a content-hashed ESM library, uploaded to
  `edge.codemoji.games`, and dynamic-imported by a Phoenix `GameIsland` hook in the player app. The only contract
  is that `mount` signature + the `GameProps` shape + the `Bridge`.
- **The channel model** (`apps/game/src/channel/model.ts`). `createGameModel()` builds on `@mercury/effector`'s
  `createChannel`: a `$props` store (`GameProps | null`), a `serverEvent` for one-off frames, and outbound pushes
  `submit_guess` / `lock` / `unlock`. It **mirrors the `GameLive` contract exactly** — a **player** contract. The
  inbound frames are `game:update` / `revealed` / `golden_win` / `guess_rejected`. A spectator needs the inbound
  props with **no** outbound pushes.
- **The `@mercury/ui` pieces (all in the barrel; compose, additive-only).** Detail / layout: `Collapsible`,
  `Popover`, `HoverCard`, `Card`, `ScrollArea`, `DataList`, `ListRow`, `Table`, `Tabs`, `Badge`, `Stat`. No
  operator `Panel` / `Split` primitive exists — a split is composed locally from `Card` + `ScrollArea` (the
  admin.5-F1 → Arm B precedent), or a new primitive is a `/mercury-ship` fork.
- **The two-clock seam** (admin.5-D5 / INV4). Every desk reads an `@mercury/effector` store via `useUnit`; a
  `channel` model can `sample` into the same store with no view rewrite. This is the seam admin.5.3's live feed
  seats on.

---

## admin.5.2-F1 — the detail-interaction model (+ the master-detail selected-id seam)

> **RULED (Operator, D-6) → Arm C (side panel / master-detail).** The `$selectedId` + keyed `fetchDetailFx(id)`
> seam; a side pane composed LOCALLY (`Card` + `ScrollArea`, no new primitive) beside the narrowed list. Authored
> to a full triad — `admin.5.2.{md,stories.md,llms.md}`. The arms below are retained as decision-context.

**Rationale.** admin.5.1 gives list desks; the operator then needs a room's games and a player's guesses / ledger,
read from `GET /rooms/:id` + `GET /players/:id`. How that detail surfaces — in place, as a peek, or in a
persistent side pane — is a UX decision that also fixes the store seam (a keyed `fetchDetailFx(id)` + a
`$selectedId`), and it sets the pattern the admin.5.3 room→game→live path extends. All arms are buildable from the
barrel today (no new primitive), so this is a taste / density fork, not a capability one.

**5W.** Who — the operator reading detail beside a list · What — the detail surface + the selected-id seam · When
— admin.5.2, after the list desks · Where — `apps/dashboard/src/views/*` (app-local compose) · Why — the detail
must read at operator density and extend cleanly into the live game path.

**Steelman.**
- **Arm A — inline `Collapsible` row-expand.** A row click opens a `Collapsible` beneath it with the detail (a
  room's games as a nested `Table`; a player's recent guesses). The list stays in view; no navigation; smallest
  seam (a per-row or single-open expand + one keyed detail fetch). Best when detail is shallow; awkward for the
  player ledger (a long, scrollable second list crammed under a row).
- **Arm B — `Popover` / `HoverCard` peek.** A row click (or hover) anchors a `Popover` detail card to the row.
  Lightest touch, good for a glance (a room's game count, a player's balances); non-committal. Poor for dense or
  scrollable detail (the ledger), ephemeral (dismisses on outside-click), and it does not extend to the live game
  pane (admin.5.3).
- **Arm C — side `Panel` / master-detail split.** A `$selectedId` store drives a side pane (`Card` + `ScrollArea`,
  composed locally) that renders the `:id` detail beside the narrowed list. Classic master-detail; scales to rich
  detail (the room's games list, the player's guesses + ledger); the selected-id seam is **exactly** what
  admin.5.3 extends (room → select a game → the live pane replaces the static detail). Costs the most layout and
  narrows the list; a `/mercury-ship` `AppShell` / `SplitPane` extraction stays deferred (rule-of-three).

**Steward.** Lean **Arm C (side panel / master-detail)** as the desk-ladder's spine: one `$selectedId` +
`fetchDetailFx(id)` seam serves rooms, players, and — extended — admin.5.3's room→game→live path, and it holds the
player ledger without cramming. Keep **Arm A (Collapsible)** as the fallback if the Operator rules that detail
stays shallow and the list unbroken (a lighter rung). **Arm B (Popover)** suits a future quick-glance affordance (a
balance peek) but is the weakest primary detail model. Whatever the ruling, the detail stays app-local composed
(admin.5-F1 → Arm B holds); a shared split primitive is a later `/mercury-ship` concern.

---

## admin.5.3 — the live game path (room → game → the embedded live view)

> **RULED (Operator, D-6) → PHASED (interim now / live later).** admin.5.3 ships a NODE-ONLY interim FIRST — a
> spectator board re-rendered from `GET /games/:id` via `@mercury/ui` + a poll, in a side-by-side split, the
> room→game nav extending admin.5.2's `$selectedId` seam (frontend-only, zero echo/ coupling). The TRUE live
> island-mount + a read-only echo/ `game:spectate:<id>` topic is a LATER live-upgrade rung — a `/codemojex-ship`
> ENGINE fork — swappable with no rewrite (the two-clock seam). Per fork: **F1 → Arm C interim / Arm A later ·
> F2 → Arm C poll / Arm A (echo/) later · F3 → Arm A side-by-side.** admin.5.3's full triad is authored at its
> own build run; this section is its ruled design entry.

The critical navigational path ends at the **actual live game**. Three forks compose it: how the game view is
embedded (F1), how a spectator feed reaches it (F2), and how the game + events split is laid out (F3). A
**static / polled** version of this path is node-buildable today from `GET /games/:id` (board + guesses); the
**live** upgrade couples to the engine and forks to `/codemojex-ship`. The Operator can ship the static split
first and add live later — the two-clock seam makes that a no-rewrite upgrade.

### admin.5.3-F1 — the game-embed model

> **RULED → Arm C (re-render) interim now · Arm A (workspace-`mount` the island) later.** Reject Arm B (iframe).

**Rationale.** The console must show the real game view at a selected game. The game island is built for CDN
dynamic-import by the player app, owns its own React, and takes `mount(el, props, bridge)`. Reaching it from the
dashboard is the integration fork.

**5W.** Who — the operator watching a game · What — the game view inside the console · When — admin.5.3 · Where —
`apps/dashboard/src/views` mounting `@codemojex/game` vs an iframe vs a re-render · Why — fidelity to the real
game vs bundle weight vs coupling.

**Steelman.**
- **Arm A — workspace-`mount` the island.** Add `@codemojex/game` as a workspace dep (or alias its `src`) and call
  `mount(el, spectatorProps, noopBridge)` in a `useEffect`. The operator is shown the **exact** player view (one
  source of truth for the board), and a read-only `bridge` disables interaction. Cost: the island bundles its own
  React, so the dashboard carries a second React runtime in that view (weight, and a build-config step — the
  island targets a CDN lib, not a workspace consumer); it depends on F2 for spectator `GameProps`.
- **Arm B — iframe the deployed edge game.** Embed `edge.codemoji.games/<game>` in an `<iframe>`. Full isolation,
  zero bundle coupling. But that URL is the **interactive player** surface (needs game context / player auth), not
  a spectator view; cross-origin messaging is needed to feed operator state; it is the wrong surface for an
  operator watch pane.
- **Arm C — re-render from `GameProps` / `GameDetail` via `@mercury/ui`.** Build a spectator board in the
  dashboard from the `GET /games/:id` `board` + `guesses` (static / polled) or from live `GameProps` (F2), using
  `@mercury/ui` (`Table` / `Stat` / `Badge`). No game bundle, no second React; node-buildable today for the static
  view. Cost: it **re-implements** the board and drifts from the real game view as the game evolves.

**Steward.** Lean **Arm A (workspace-mount the island)** as the live target — it is the one option that shows the
true game with no re-implementation — **paired with F2**'s spectator bridge for read-only `GameProps`, and with
**Arm C (re-render)** as the **zero-coupling interim**: ship the static / polled spectator board from `GET
/games/:id` node-only now, and swap to the mounted island when the engine spectator channel (F2) lands. Reject
**Arm B (iframe)** for the operator watch — it embeds the player surface. This is a genuine architecture +
dependency fork (a new workspace dep on `@codemojex/game`, a second React runtime in one view) — the Operator
rules it.

### admin.5.3-F2 — the spectator bridge (the read-only live feed)

> **RULED → Arm C (poll `GET /games/:id`) node-only interim now · Arm A (an engine spectator topic, a
> `/codemojex-ship` fork) later.** Avoid Arm B (muddies player authz).

**Rationale.** A live game view needs live `GameProps`. The shipped channel model is a **player** contract (it
pushes `submit_guess` / `lock` / `unlock` and mirrors `GameLive`); an operator spectator needs the inbound state
with no outbound pushes and no player identity. The feed is defined engine-side, so the live bridge is a coupling
surface.

**5W.** Who — the operator's read-only feed · What — a spectator channel delivering `GameProps` · When — admin.5.3
(live upgrade) · Where — the **engine** (`echo/`, the channel + authz) feeding the node `@mercury/effector`
`channel` adapter · Why — a live board without granting the operator player actions.

**Steelman.**
- **Arm A — an engine spectator topic (`echo/`).** The engine exposes a read-only `game:spectate:<id>` (or an
  admin-token-gated join on the existing topic) that pushes `game:update` frames and accepts no player pushes. The
  node side seats it on the existing `createChannel` adapter and `sample`s into the game store — no node rewrite.
  This is an **`echo/` change → a `/codemojex-ship` fork** (the engine writer owns the topic + authz).
- **Arm B — join the existing `game:<id>` topic read-only.** The dashboard joins the player topic and never
  pushes. Smallest engine change — but that topic is a player-authz surface (it may reject a non-player join or
  expect player identity), so it still likely needs an engine authz tweak, and it risks exposing player-only
  frames to an operator.
- **Arm C — poll `GET /games/:id` (no channel).** A dashboard interval re-fetches the game detail for a near-live
  board. **Zero engine coupling, node-only**; not truly live (poll latency), and it loads the read plane. The
  honest interim that pairs with F1 → Arm C.

**Steward.** Lean **Arm A (an engine spectator topic)** as the correct live home — a read-only, operator-gated feed
keeps player authz clean — recorded as a **`/codemojex-ship` fork** (the node side is ready on the two-clock
seam; the engine work is out of this program's boundary). Ship **Arm C (poll)** as the node-only interim so
admin.5.3 delivers a live-ish view without blocking on the engine. Avoid **Arm B** (it muddies player authz). This
fork's engine arm is explicitly **not** a codemojex-node deliverable — it forks OUT to `/codemojex-ship`.

### admin.5.3-F3 — the split-view layout (game | events)

> **RULED → Arm A (side-by-side split).** Composed locally from `Card` + `ScrollArea`; Arm B (stacked) the narrow fallback.

**Rationale.** admin.5.3 is a **split** — the game view beside the events / guesses feed (the guesses from
`GameDetail.guesses` plus live `revealed` / `guess_rejected` server events). The split's shape is a layout choice,
decidable once F1 is ruled; it is the lowest-stakes of the three.

**5W.** Who — the operator watching game + activity · What — the two-pane arrangement · When — admin.5.3 · Where —
`apps/dashboard/src/views` composed from `Card` + `ScrollArea` · Why — game and activity legible together.

**Steelman.**
- **Arm A — side-by-side split** (game pane | events pane), each a `ScrollArea`. Both visible at once; the master
  detail idiom; best on a wide operator screen; narrower panes.
- **Arm B — stacked** (game on top, events below). Simpler, degrades better on a narrow viewport; the operator
  scrolls between them.
- **Arm C — tabbed** (Game | Events). One at a time; least context; simplest layout.

**Steward.** Lean **Arm A (side-by-side)**, composed locally from `Card` + `ScrollArea` (no new primitive — the
admin.5-F1 → Arm B rule), with a graceful **Arm B (stacked)** fallback at a narrow width. **Arm C (tabbed)** loses
the at-a-glance value of a watch pane. This arm is a layout ruling, not an architecture one — the Operator can
confirm it alongside F1.

---

## admin.5.4 — the forward slot

> **RULED (Operator, D-6) → 5.4-a (observability & shared filter-state).** A header `Stat` strip (live counts) +
> URL-encoded filter/search + per-desk auto-refresh; frontend-only. 5.4-b (operator actions / the write twin) is
> deferred to pair with admin.2. admin.5.4 stays a roadmap entry (no triad yet). The candidates below are kept as
> context.

The Operator left admin.5.4 undescribed. Two candidate directions extend the desk ladder's arc; each is a
one-paragraph sketch, **PROPOSED — not a committed spec** until the Operator picks. Neither is authored as a triad.

- **Proposal 5.4-a — cross-desk observability & shared filter-state.** A console-wide surface over the desks: a
  header `Stat` strip (live counts — open games, active rooms, players) and a shared, URL-encoded filter / search
  state so an operator's view is linkable and survives a refresh, plus a lightweight auto-refresh cadence per
  desk. Value: the console reads as an operator **dashboard**, not three isolated tables; still frontend-only
  (reads the existing read plane, computes counts client-side). A natural consolidation after three desks exist.
- **Proposal 5.4-b — operator actions on the desks (the read plane's write twin).** Fold the first management
  actions onto the desks — the shipped `PATCH /rooms/:id/status` (open / close a room) surfaced as a guarded
  action on the rooms desk, with a `Modal` / `AlertDialog` confirm and an optimistic store update. Value: the
  console becomes operational rather than observational — the frontend face of admin.2 (lifecycle management).
  Note: this crosses from read-only into **write** (a management surface), so it pairs with admin.2 and is a
  larger scope decision; it may also want an audit trail. The heavier, higher-value direction.

A third, lighter option — **export / snapshot** (download a desk's current rows as CSV/JSON) — is noted as a
minor add if the Operator prefers an observability quick-win instead of a new capability.

---

Roadmap: [`admin.roadmap.md`](./admin.roadmap.md) · Index: [`admin.md`](./admin.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md)
