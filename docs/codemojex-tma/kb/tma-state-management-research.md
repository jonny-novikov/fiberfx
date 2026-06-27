# Codemoji Telegram Mini App — Frontend Architecture & State Management Research Report

## TL;DR
- **Build the Codemoji client as a hand-written MVU/Elmish runtime layered on Effector**, using Effector's events as Elm "messages," `.on`/`sample` reducers as the "update" function, derived stores as the "model," and React (via `useUnit`) as a pure "view." This mirrors the Codemojex Phoenix/Elmish backend's immutable, time-travel-capable design more faithfully than any off-the-shelf store.
- **Time-travel is achievable on Effector but is partly hand-rolled**: snapshot state with the officially-supported Fork API (`serialize(scope)` → `fork({values})`/`hydrate`), and record an event log with the `effector/inspect` API; undo/redo can use community libs (`effector-history`) or a small custom history store. There is no first-party jump-to-state, so plan to build a thin devtools/history layer yourself.
- **For optimistic updates over Phoenix Channels**, use `channel.push().receive("ok"|"error"|"timeout")` with per-action correlation refs, keep a pending-mutations map keyed by a client-generated branded ID, apply optimistic patches immediately, and reconcile/rollback against server replies and broadcasts — always treating the server as the source of truth.

## Key Findings

1. **Effector maps cleanly onto MVU.** Effector is a reactive, framework-agnostic state manager — 12.9 kB minified+gzipped per Best of JS (the core `effector` package is ~10.4 KB gzipped and `effector-react` ~3.7 KB gzipped per bundlephobia figures) — whose four unit types (events, stores, effects, domains) plus operators (`combine`, `sample`, `split`, `restore`) form a directed reactive graph. Stores are immutable (no `setState`; updates only via events), which is exactly the Elm "Model is an immutable snapshot, Message is a delta, Update is a pure reducer" discipline.

2. **Time-travel building blocks exist but require assembly.** The Fork API's `serialize(scope)` returns a plain `{sid: value}` object that can be restored via `fork({values})` or `hydrate()`. The `effector/inspect` API streams every computation as a `Message{kind,name,value,sid}`, enabling an append-only event log. But `@effector/redux-devtools-adapter` is logging-only (no write-back jump-to-state), and undo/redo must come from community libraries or custom code.

3. **The two strongest MVU alternatives are Redux Toolkit (+ redux-undo/immer) and Zustand (+ immer + zundo).** Redux is the most literal Elm-architecture analog (single immutable store, reducers, mature time-travel via Redux DevTools and `redux-undo`'s past/present/future). Zustand+zundo is the lightweight, low-boilerplate option with `<700B` undo/redo middleware. XState is a strong contender for the *game-rules* layer but is a statechart engine, not a whole-app store.

4. **Optimistic UI over Phoenix Channels is well-trodden.** Phoenix's JS client gives `push(event, payload).receive("ok"/"error"/"timeout")` and server `handle_in/3` replies; correlation of async replies requires a client-supplied ref tracked in channel state. Best practice: apply optimistic state immediately, track pending ops in a map with rollback closures, reconcile when the authoritative reply/broadcast arrives, and trust the server value over the optimistic guess.

5. **Branded IDs + immutable structures fit both ends.** TypeScript branded types (`type KeyId = string & {__brand:'KeyId'}`) give zero-runtime-cost nominal IDs that mirror an Elixir "Branded ID" engine, preventing mixing of `EmojiId`/`SlotId`/`RoomId`/`KeyId`. Immer (structural sharing via proxies) or hand-rolled persistent structures keep snapshots cheap.

## Details

### A. Codemoji / Codemojex context and constraints

Codemoji is an emoji-code-guessing game with a Russian-language UI featuring a leaderboard, an emoji keyboard, guess slots, an info dashboard, a key/balance economy, and "golden room" mechanics. The frontend is a **Telegram Mini App** in React + TypeScript, hand-written, talking to **Codemojex**, a Phoenix (Elixir/OTP) backend written in an **Elmish style with immutable, time-travel-capable structures**, over **REST + Phoenix Channels**, with an Elixir game engine built on **Branded ID** objects.

The architectural mandate is *symmetry*: because the backend is immutable, message-driven (Elmish), and replayable, the frontend should be the same — an immutable model, explicit messages, a pure update function, side effects isolated as commands/effects, and the ability to snapshot/replay state. This is exactly the Elm Architecture (MVU), which Elmish itself implements: Model (immutable snapshot), Message (a discriminated-union delta), Command (instructions producing messages), Init (pure initial state), Update (pure `(state, msg) -> state'`), and View (pure function of state). The Phoenix/Elixir side often realizes "time-travel" via event sourcing (immutable append-only events + reducers that rebuild state by replay, with periodic snapshots), e.g. via the Commanded library and EventStore, or hand-rolled GenServer reducers.

**Telegram Mini App specifics that shape the build:**
- Use a Vite + React + TypeScript template (the official `Telegram-Mini-Apps/reactjs-template` uses `@tma.js/sdk`, TypeScript, and Vite; `mockTelegramEnv` lets you develop outside Telegram). The `@telegram-apps/telegram-ui` React library provides Telegram-native components.
- `window.Telegram.WebApp` (or `@tma.js/sdk`) exposes `ready()`, `initData`, `initDataUnsafe.user`, theme params, haptics, MainButton, fullscreen, and SecureStorage.
- **Security:** the client must send `initData` to the backend, which validates the HMAC-SHA256 signature (secret key = HMAC-SHA256 of the bot token with constant `"WebAppData"`) and checks `auth_date` freshness (commonly a 5-minute window) to prevent replay. Codemojex (Elixir) can validate via `:crypto.mac(:hmac, :sha256, "WebAppData", bot_token)`; a `telegram_miniapp_validation` hex package exists. Mobile clients won't load self-signed certs in dev — use a tunnel.

### B. Thread 1 — State management

#### B.1 Effector primitives and the MVU mapping

Effector's core units (from the official docs):
- **Event** (`createEvent`): "an entry point into the reactive data flow… a way to signal that 'something has happened.'" Events are the Elm **Message**. They can be `.prepend`-ed, `.map`-ped, filtered, merged.
- **Store** (`createStore`): a reactive, **immutable** value — "Store data is immutable. There is no setState, state changes occur through events." Stores compose the Elm **Model**. Derived stores via `$store.map(fn)` or `combine(...)` are computed/secondary model values.
- **Effect** (`createEffect`): isolates side effects (HTTP, channel pushes, timers); exposes `.pending`, `.done`, `.fail`, `.finally`. These are the Elm **Command** carriers.
- **Domain** (`createDomain`): a namespace over units (now largely superseded by Scope/Fork for isolation).
- **Operators:** `sample` ("the glue that binds units"; `{clock, source, filter, fn, target}` — read `source` when `clock` fires, optionally filter/transform, write to `target`); `combine` (derive one store from many, with diamond-problem batching via a "barrier"); `split` (pattern-match an event into cases — like a `switch` in an update function); `restore` (build stores from an object of values / event).
- **Scope** (`fork`): "a fully isolated instance of application" — an independent clone of all units, enabling multiple app instances (tests, SSR, and — crucially here — snapshots).

**Concrete MVU wiring for Codemoji** (illustrative):
```ts
// MESSAGES (events)
const emojiPicked   = createEvent<EmojiId>();
const slotCleared   = createEvent<SlotId>();
const guessSubmitted = createEvent();
const keySpent      = createEvent<KeyId>();

// MODEL (stores)
const $slots = createStore<ReadonlyArray<EmojiId | null>>(EMPTY_SLOTS)
  .on(emojiPicked, (slots, e) => placeInNextEmptySlot(slots, e))   // UPDATE (pure reducer)
  .on(slotCleared, (slots, s) => clearSlot(slots, s));

const $keys = createStore<number>(0).on(keySpent, (n) => Math.max(0, n - 1));
const $canSubmit = combine($slots, (slots) => slots.every(Boolean)); // derived model

// COMMAND (effect) + dataflow
const submitGuessFx = createEffect((slots: Guess) => channelPushGuess(slots));
sample({ clock: guessSubmitted, source: $slots, filter: $canSubmit, target: submitGuessFx });
```
The React view stays pure: `const { slots, canSubmit } = useUnit({ slots: $slots, canSubmit: $canSubmit })`. This is the Elm loop: view dispatches events → `sample`/`.on` reducers compute a new immutable model → React re-renders the changed slices. Effector "is designed to notify only subjects to change," giving fine-grained re-renders.

**Effector best practices** that reinforce MVU discipline: keep stores small and decentralized; never use `$store.getState()` inside logic (pass via `sample` `source`); use `.watch`/`patronum/debug` only for debugging; declare all units statically at module level; isolate side effects in effects; organize by responsibility scope (model folders with `index.ts` declarations + `init.ts` that wires `sample`/`split`).

#### B.2 Immutability discipline on Effector

Stores are already immutable; the rule is *return a new reference* in reducers (spread, or use Immer's `produce` for deep nested updates — Effector's docs explicitly mention using Immer for reference-type stores). For Codemoji's nested game state (slots, room, economy), **Immer** gives ergonomic immutable updates with structural sharing (proxy-based copy-on-write: unchanged subtrees are shared, changed nodes and their ancestors are recreated), which also enables cheap reference-equality checks for memoized selectors. For very large/long histories, **Mutative** is markedly faster — its own benchmark (Mutative v1.3.0 vs Immer v10.1.3) reports "Mutative - Freeze x 1,069 ops/sec" vs "Immer - Freeze x 392 ops/sec," and with default configs Mutative (5,323 ops/sec) vs Immer (320 ops/sec), claiming "2–6x faster than naive handcrafted reducer, and more than 10x faster than Immer" at ~4.16 KB min+gzip — or JSON-Patch-based diffs (RFC 6902, as in the "Travels" library) to reduce memory.

#### B.3 Time-travel on Effector (snapshots + event log + replay)

The single subagent investigation confirmed precisely what is and isn't supported:

- **Snapshots (officially supported).** `serialize(scope: Scope, {ignore?, onlyChanges?}): {[sid:string]: any}` returns a plain object keyed by store **sid**. It can be restored into a fresh scope: `fork({values: snapshot})` or `hydrate(scope, {values: snapshot})`. Note: `fork({values})` does **not** trigger watchers; `hydrate()` does. `onlyChanges` is deprecated since effector 23. For undo/redo you push each `serialize(scope)` onto a history array and restore on demand.
- **Event log (officially supported, monitoring only).** `import {inspect} from 'effector/inspect'; inspect({fn:(m)=>log(m)})` streams every kernel computation as `Message{kind,name,value,sid,trace}` — "Allows us to track any computations that have happened in the effector's kernel." Add `trace:true` to capture the causal chain. `createWatch({unit, fn, scope})` records a single unit's updates within a scope. You can push `{unit, params}` into an append-only command log.
- **Replay (hand-rolled).** Re-run a recorded event log onto a fresh `fork()` with `allSettled(unit, {scope, params})` in order. This is mechanically possible but undocumented; events must be deterministic and serializable, and `allSettled` discards effect return values.
- **SIDs are required for serialize.** A **sid** is a "stable hash identifier… preserved between environments." Because Effector uses many independent stores (unlike Redux's single tree), serialization needs stable keys. These are injected by `effector/babel-plugin` (built into the package) or the experimental `@effector/swc-plugin`. Without a sid, a store's value is omitted from `serialize`. Custom factories need registration in the plugin's `factories` list to keep sids unique.
- **DevTools.** `@effector/redux-devtools-adapter` (`attachReduxDevTools({scope, trace, name})`) mirrors the Inspect stream into Redux DevTools for inspection and tracing, with an optional `stateTab`. **It is logging-only** — it does not implement Redux DevTools' jump-to-state write-back into Effector scopes. So the DevTools "time-travel" slider won't restore Effector state; you must wire your own restore using `serialize`/`fork`/`hydrate`.
- **Community undo/redo.** `effector-history` (Kelin2025) — `createHistory({source:{...stores}, clock:[...events], strategies})` with `undo()`, `redo()`, `$history`, `maxLength`, and merge strategies (`replaceRepetitiveStrategy`, `skipDuplicatesStrategy`, custom). `@tanyaisinmybed/effector-undo` — single-store `createHistory({store, limit, events, filter})`. Both are snapshot-based. The canonical discussion is effector GitHub issue #315 (Undo/Redo).

**Recommended time-travel design for Codemoji:** keep a dedicated `historyModel` that (a) records each game-relevant event into an append-only log via `inspect`/`createWatch` (with `trace:true` in dev), and (b) snapshots `serialize(scope)` at meaningful checkpoints (e.g., after each confirmed server reconciliation, before entering a golden room). Use `effector-history` for in-session undo of local UI moves (e.g., placing/removing emoji before submit). For full replay/debugging, restore snapshots via `fork({values})`. This mirrors the backend's event-sourced snapshot+replay model exactly.

#### B.4 The two strongest alternatives

After evaluating hand-rolled Elmish runtimes (raj, ts-elmish, hyperapp), Redux Toolkit, XState, and Zustand, the two strongest alternatives for *this* use case are **Redux Toolkit (+ immer + redux-undo)** and **Zustand (+ immer + zundo)**, with **XState** noted as a complementary game-rules engine rather than a whole-app replacement.

**Alternative 1 — Redux Toolkit (RTK) + immer + redux-undo.** RTK is the most literal Elm Architecture analog in mainstream JS: a single immutable store, actions (messages), reducers (pure update), and unidirectional flow. Redux's own docs (Prior Art) credit "The Elm Architecture for a great intro to modeling state updates with reducers" and note that "Elm 'updaters' serve the same purpose as reducers in Redux." Immer is built into RTK's `createSlice`. Time-travel is its strongest suit: Redux DevTools provides true jump-to-state, action skip, import/export, and replay because each action deterministically produces a new snapshot; and `redux-undo` wraps any reducer to add `past/present/future` history with `UNDO`/`REDO`/`JUMP` actions and action filtering (`includeAction`/`excludeAction`, `groupBy`, `limit`). The trade-off is boilerplate and a single-tree model (vs. Effector's decentralized graph).

**Alternative 2 — Zustand + immer + zundo.** Zustand is a minimal hook-based store (maintained by the pmndrs/Poimandres collective); with the `immer` middleware you get ergonomic immutable updates, and **zundo** (authored by Charles Kornoelje, @_charkour, MIT — "used by several projects and teams including Alibaba, Dify.ai, Stability AI, Yext, KaotoIO, and NutSH.ai") adds undo/redo/time-travel in `<700 B` (v2 is "only ~800 bytes where v1 was a few KBs"). Its `temporal` middleware exposes a `TemporalState` of `{ pastStates, futureStates, undo: (steps?) => void, redo: (steps?) => void, clear, isTracking, pause, resume, setOnSave }`, with `limit`, `partialize` (track only chosen slices), and `equality` (avoid duplicate history). The Zustand ecosystem is widely used for game state (slices pattern, `subscribeWithSelector`, persistence). The trade-off: Zustand is less opinionated/explicit than MVU — discipline (messages, pure updates) must be self-imposed rather than enforced.

**Complementary — XState (statecharts).** XState models finite states, events, transitions, guards, context, parallel/hierarchical states, and has visualization. It's ideal for the *game-rules* layer ("idle → guessing → submitting → revealed → golden-room") where invalid states must be unrepresentable, and `@xstate/store` is a tiny Redux/Zustand-like option. But a statechart engine is not a full app store; pair it with one rather than treat it as the whole architecture.

#### B.5 Side-by-side comparison

**(a) Rationale.** Codemoji needs: immutable model; explicit messages/pure updates (MVU symmetry with Elmish backend); snapshot+replay time-travel; fine-grained reactivity for a busy game UI (keyboard, slots, timers, leaderboard); first-class TypeScript; small bundle (Telegram Mini App). The decision hinges on how literally each tool encodes MVU and how well it supports immutable snapshots/time-travel.

**(b) The 5W:**

| | **Effector** | **Redux Toolkit (+redux-undo)** | **Zustand (+zundo)** |
|---|---|---|---|
| **Who** | Created by Dmitry Boldyrev (zerobias); used by Aviasales and others; active community (patronum, farfetched, effector-react) | Maintained by the Redux team (Mark Erikson et al.); huge ecosystem | Maintained by pmndrs (Poimandres) collective; zundo by Charles Kornoelje (@_charkour) |
| **What** | Reactive, framework-agnostic graph of events/stores/effects; immutable stores; Fork API for scopes/SSR | Opinionated Redux: single immutable store, slices/reducers, Immer built-in, Thunks | Minimal hook store; middleware for immer, persist, temporal (zundo) |
| **When** | When you want event-driven, decentralized immutable logic with explicit dataflow and fine-grained updates | When you want the canonical Elm-architecture single store with best-in-class time-travel DevTools | When you want least boilerplate and a tiny bundle, with optional undo/redo |
| **Where** | Logic-heavy, real-time, multi-source apps; UI-agnostic core | Large apps needing predictable single-store auditing and tooling | Small-to-mid apps, games, where simplicity wins |
| **Why** | Closest to "many small immutable models + explicit messages"; Fork enables snapshot/replay symmetry with an event-sourced backend | Most mature, literal MVU; true jump-to-state time-travel; immer + redux-undo | Smallest, fastest to adopt; `<700 B` time-travel; great DX |

**(c) Recommendation (opinionated).** **Use Effector as the primary application store and MVU runtime, add Immer for deep immutable updates, and adopt `effector-history` (or a small custom history model) plus a `serialize`-based snapshot layer for time-travel.** Rationale: Effector's event-driven, decentralized, immutable graph is the closest JS analog to an Elmish, message-driven, immutable, replayable Phoenix backend; its Fork API gives genuine snapshot/restore symmetry with the backend's event-sourcing; and its fine-grained reactivity suits the busy Codemoji UI at a small bundle size (~13 KB gzipped for core + react bindings). Layer **XState (or `@xstate/store`) only for the game-rules state machine** (room lifecycle, golden-room phases) if those rules grow complex. Choose **Redux Toolkit instead of Effector** only if the team prioritizes the most mature, push-button time-travel DevTools and is comfortable with single-store boilerplate; choose **Zustand+zundo** only if bundle size and speed-to-ship dominate and the team will self-impose MVU discipline. For Codemoji's stated goals, Effector wins.

### C. Thread 2 — Optimistic-update reconciliation over Phoenix Channels

#### C.1 Phoenix Channels transport model

Clients connect a single multiplexed socket and `join` topics (e.g., `game:<roomId>`), each backed by a lightweight Erlang process holding `socket.assigns`. The JS client API:
- `channel.push(event, payload, timeout?)` returns a `Push` supporting `.receive("ok", fn)`, `.receive("error", fn)`, `.receive("timeout", fn)` (default 10000 ms). The server handles it in `handle_in(event, payload, socket)` and replies with `{:reply, {:ok, result}, socket}` / `{:reply, :error, socket}` or `{:noreply, socket}`.
- `channel.on(event, fn)` receives server-initiated broadcasts/pushes; `broadcast!/3` fans out to all topic subscribers.
- The client auto-handles reconnection (exponential backoff), `onError`/`onClose` callbacks, and a **PushBuffer** that queues outgoing messages while disconnected and flushes on reconnect; rejoin replays subscriptions.
- **Correlation:** the Phoenix JS `push().receive(...)` already correlates a reply to its push via an internal `ref`. For *server-initiated* pushes that need a client reply, the server gets no ref automatically — you must embed a unique id in the payload, track it in channel state, and match it in `handle_in/3` (or use `socket_ref/1` + async `reply/2` for deferred replies).

#### C.2 Optimistic update + reconciliation pattern

The canonical pattern (independent of transport) is: apply the optimistic change immediately, track the pending operation with a rollback, and reconcile on the authoritative response — "Don't just keep your optimistic value—trust the server."

A robust, multi-in-flight implementation tracks each operation independently:
```ts
const pending = new Map<MutationId, () => void>(); // id -> rollback

function optimistic<T>(id: MutationId, apply: () => void, rollback: () => void,
                       send: () => Promise<T>): Promise<T> {
  apply(); pending.set(id, rollback);
  return send()
    .then((res) => { pending.delete(id); return res; })
    .catch((err) => { rollback(); pending.delete(id); throw err; });
}
```
Mapped onto Effector + Phoenix for Codemoji:

```ts
const guessOptimistic = createEvent<{id: MutationId; guess: Guess}>();
const guessConfirmed  = createEvent<{id: MutationId; server: GameState}>();
const guessRejected   = createEvent<{id: MutationId; reason: string}>();

// optimistic placement applied immediately to $slots/$keys
$pending.on(guessOptimistic, (m, {id, guess}) => m.set(id, snapshotForRollback()));

const pushGuessFx = createEffect(({id, guess}: {id:MutationId; guess:Guess}) =>
  new Promise((resolve, reject) => {
    channel.push("guess:submit", { mutation_id: id, guess })
      .receive("ok",      (server) => resolve(server))
      .receive("error",   (reason) => reject(reason))
      .receive("timeout", ()       => reject("timeout"));
  }));

sample({ clock: guessOptimistic, target: pushGuessFx });
sample({ clock: pushGuessFx.done,   fn: ({result, params}) => ({id: params.id, server: result}), target: guessConfirmed });
sample({ clock: pushGuessFx.fail,   fn: ({error, params})  => ({id: params.id, reason: String(error)}), target: guessRejected });
```

**Reconciliation rules for Codemoji's mechanics:**
- **Placing an emoji guess / clearing a slot:** purely local UI state until submit — no server round-trip needed; use in-session undo (`effector-history`). Only `guess:submit` is a server mutation.
- **Spending a key / balance economy:** optimistically decrement `$keys` and mark the mutation pending; on `"ok"` reconcile to the server's authoritative balance (the server may return a different value if another device/transaction intervened — always overwrite with server truth); on `"error"`/`"timeout"` roll back the decrement and surface a non-blocking error. Use a client-generated **branded `MutationId`** for idempotency so the Elixir side can dedupe (idempotency keys via a MapSet or optimistic-concurrency keys, per Phoenix optimistic-update practice).
- **Golden room entry / state transitions:** model as XState/state-machine transitions guarded by server confirmation; apply an optimistic "entering" state, then confirm/abort on reply. Treat every incoming WebSocket message as *provisional* — "the server validates and the view adapts."
- **Concurrent edits / authority:** for shared/competitive state (leaderboard, room state broadcast to all players), prefer server-authoritative broadcasts; the optimistic layer only covers the local player's own pending actions. Reconcile broadcasts by id: if a broadcast supersedes a pending optimistic op, drop the pending op and adopt server state. For lost-update safety on shared resources, use version/`ETag`-style optimistic concurrency or "first-write-wins with a clear status message" (as Phoenix LiveView workflow guidance describes — e.g., "Already approved by Alex").
- **Ordering & races:** responses can arrive out of order; never assume FIFO. Key everything by `MutationId`, cancel/ignore stale replies, and let the latest server snapshot win. On reconnect, the PushBuffer flushes queued mutations — guard against double-apply with the idempotency id, and on rejoin request a fresh authoritative snapshot (the join reply can carry current `GameState`, like the chat "catching up" pattern).

#### C.3 Event-sourcing symmetry (why this fits Codemojex)

Because Codemojex is event-sourced/Elmish, the channel can carry **events/deltas** rather than full state, and both sides apply the same reducers — the approach Rapport used (Redux actions persisted to Postgres over Phoenix Channels, replayable to any point in time). The frontend's Effector event log and the backend's event store become two views of the same immutable timeline; snapshots (`serialize`) on the client correspond to backend snapshots, and replay reconstructs state on either side. This is the deepest form of the mandated front/back symmetry.

### D. Branded IDs and from-scratch data structures

Codemoji's Elixir engine uses **Branded ID** objects; mirror this in TypeScript with branded (nominal) types so structurally-identical primitives become distinct:
```ts
declare const __brand: unique symbol;
type Brand<T, B> = T & { readonly [__brand]: B };
type EmojiId = Brand<string, 'EmojiId'>;
type SlotId  = Brand<number, 'SlotId'>;
type RoomId  = Brand<string, 'RoomId'>;
type KeyId   = Brand<string, 'KeyId'>;
type MutationId = Brand<string, 'MutationId'>;
const RoomId = (s: string): RoomId => s as RoomId; // smart constructor, validate at boundaries
```
Branded types are compile-time only (zero runtime cost; the brand is erased), and prevent bugs like passing a `RoomId` where a `KeyId` is expected. Use a `unique symbol` brand (not a string `__brand`) to avoid autocomplete noise and accidental collisions, and validate/brand at trust boundaries (e.g., when parsing channel payloads or `initData`), optionally with Zod `.transform()`. The Effect library's `Brand.nominal`/`Brand.refined` is an alternative if you adopt Effect-style utilities.

**From-scratch game data structures (fit to mechanics):**
- **Guess slots:** a fixed-length `ReadonlyArray<EmojiId | null>` (or a typed tuple) — cheap to copy, trivially serializable, structurally shared via Immer.
- **Emoji keyboard / catalog:** an immutable `ReadonlyMap<EmojiId, EmojiMeta>` (or a record keyed by branded id) for O(1) lookup; render via Effector's `useList` for efficient list rendering.
- **Economy:** small immutable records (`{keys: number, balance: number, lastSyncedRev: number}`) with reducers; keep a pending-mutations `Map<MutationId, Rollback>`.
- **History/time-travel:** an append-only `ReadonlyArray<{event, payload, ts}>` event log plus periodic `serialize(scope)` snapshots; for memory-bounded undo use a ring buffer (`limit`) as `effector-history`/`zundo` do.
- For large/long-lived histories, prefer JSON-Patch deltas (RFC 6902) over full snapshots to bound memory (the "Travels"/Mutative approach), since snapshot memory grows as object-size × history-length.

## Recommendations

**Stage 0 — Scaffold (week 1).** Start from `Telegram-Mini-Apps/reactjs-template` (Vite + React + TS + `@tma.js/sdk`); add `@telegram-apps/telegram-ui`. Add Effector + `effector-react` + `effector/babel-plugin` (required for `serialize`/sids) + Immer. Implement `initData` HMAC validation on Codemojex before any gameplay. *Threshold to proceed:* `initData` verified server-side and a Phoenix Channel `join` round-trips an authoritative `GameState`.

**Stage 1 — MVU core (weeks 2–3).** Define branded IDs, immutable game model (slots, keyboard, economy, room), events (messages), `sample`/`split` reducers (update), and effects for channel pushes (commands). Keep React views pure via `useUnit`. Organize by responsibility-scope folders (`model/index.ts` + `model/init.ts`). *Threshold:* a full local guess flow works offline against a mocked channel.

**Stage 2 — Optimistic channel layer (weeks 3–4).** Wrap mutations (`guess:submit`, `key:spend`, `room:enter`) in the optimistic pattern with branded `MutationId`, pending-rollback map, and `receive("ok"/"error"/"timeout")` reconciliation; always overwrite with server truth; handle out-of-order replies, reconnect/PushBuffer double-apply (idempotency), and server broadcasts for shared state. *Threshold:* induced latency/failure (throttle, drop replies) shows correct rollback and reconciliation with no stuck pending ops.

**Stage 3 — Time-travel & devtools (week 5).** Add a `historyModel`: append-only event log via `effector/inspect` (`trace:true` in dev) + `serialize(scope)` checkpoints; wire `@effector/redux-devtools-adapter` for inspection; add `effector-history` for in-session undo/redo of local moves. Build a small custom restore (`fork({values})`/`hydrate`) since the DevTools slider can't write back. *Threshold:* you can snapshot, undo/redo local moves, and restore a checkpoint deterministically.

**Stage 4 — Game-rules hardening (week 6+).** If room/golden-room logic grows complex, extract it into an XState machine (or `@xstate/store`) with guards tied to server confirmations. Add property tests that replay recorded event logs against the backend to verify front/back determinism.

**Benchmarks that would change these recommendations:**
- If bundle size must be `<` ~15 KB for state and the team won't enforce MVU by hand → switch to **Zustand + zundo** (`<700 B` for the temporal middleware).
- If push-button jump-to-state DevTools and single-store auditing are top priority → switch to **Redux Toolkit + redux-undo**.
- If undo histories get large (state `>` ~10 KB × long history) and cause GC jank → move from full snapshots to **JSON-Patch deltas (Mutative/Travels)**.
- If game-rules states/transitions proliferate (many invalid-state bugs) → make **XState** the primary rules engine, not just a helper.

## Caveats
- **Effector time-travel is partly DIY.** Snapshots (`serialize`/`fork`/`hydrate`) and an inspect-based event log are supported, but **there is no first-party jump-to-state**; `@effector/redux-devtools-adapter` is logging-only, and event-replay-onto-fork is undocumented and constrained to deterministic, serializable events (`allSettled` discards effect results). Budget for a small custom history/restore layer.
- **SIDs/build-plugin dependency.** `serialize` requires `effector/babel-plugin` (or experimental `@effector/swc-plugin`); custom store factories must be registered to keep sids unique, or snapshots will collide/omit values.
- **Optimistic updates aren't for everything.** Avoid optimism for irreversible/authoritative actions (final scoring, payments/Telegram Stars, golden-room rewards) — prefer server-confirmed transitions. The literature warns optimistic UI suits high-success, reversible actions.
- **Source quality / dates.** Several how-to references are community blog posts (DEV, Medium) rather than primary docs; where possible this report relies on official Effector, Phoenix (HexDocs), and Telegram docs. Some Effector doc URLs are versioned (v21/v22) and APIs evolve (e.g., `onlyChanges` deprecated in v23, `useStore`/`useEvent` deprecated in favor of `useUnit`); verify against the current effector.dev docs at build time.
- **Telegram constraints.** Dev on iOS/Android can't use self-signed certs (use a tunnel); always re-validate `initData` server-side and enforce `auth_date` freshness; don't ship `mockTelegramEnv` to production.
- **Single-subagent scope.** The deepest verification effort was spent on the Effector time-travel question; the optimistic-Phoenix and alternatives sections rely on official docs plus reputable community patterns and were not independently re-verified to the same depth.