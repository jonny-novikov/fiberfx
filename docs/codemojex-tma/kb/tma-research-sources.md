# Codemoji Frontend Architecture — Research Sources

**Companion bibliography to:** *Codemoji Telegram Mini App — Frontend MVU Architecture & State Management with Effector*
**Compiled:** 27 June 2026
**Total resources:** 39 (grouped into 9 categories)

> **Note on dates.** The research tooling surfaced reliable **titles** and **links** for every source, but did **not** consistently carry **publication dates**. Where a date or version is derivable from the URL or the documentation version string, it is shown. Otherwise the field reads `n/a (verify at source)`. Exact dates can be fetched per source on request.

---

## Table of Contents

1. [Effector — Core Documentation & API](#1-effector--core-documentation--api)
2. [Effector — Ecosystem, Tooling & Time-Travel Libraries](#2-effector--ecosystem-tooling--time-travel-libraries)
3. [State Management Alternatives — Redux, Zustand, XState](#3-state-management-alternatives--redux-zustand-xstate)
4. [Immutability & Time-Travel Concepts](#4-immutability--time-travel-concepts)
5. [Phoenix Channels & Real-Time Transport](#5-phoenix-channels--real-time-transport)
6. [Optimistic Updates & Reconciliation](#6-optimistic-updates--reconciliation)
7. [Event Sourcing — Elixir & React](#7-event-sourcing--elixir--react)
8. [TypeScript Branded / Nominal Types](#8-typescript-branded--nominal-types)
9. [Telegram Mini Apps](#9-telegram-mini-apps)

---

## 1. Effector — Core Documentation & API

Primary docs for the chosen state manager. These ground the MVU mapping (events = messages, stores = model, effects = commands), the immutability discipline, and the snapshot/event-log primitives used for time-travel.

**1. Core concepts — Effector**
Publisher: effector.dev · Date: n/a (verify at source)
Link: https://effector.dev/en/introduction/core-concepts/
Abstract: Official introduction to Effector's four unit types — events, stores, effects, domains — and the reactive-graph model. Establishes that stores are immutable and that state changes only happen through events, which is the basis for treating Effector as an MVU runtime.

**2. createStore — Effector (v22)**
Publisher: effector.dev · Date: v22 docs
Link: https://v22.effector.dev/docs/api/effector/createStore/
Abstract: API reference for store creation, the immutable value container that serves as the "Model." Documents reducers via `.on`, derived stores, and update semantics (new reference required).

**3. Scope — Effector (v22)**
Publisher: effector.dev · Date: v22 docs
Link: https://v22.effector.dev/docs/api/effector/scope/
Abstract: Describes `fork()` and the Scope object — a fully isolated clone of all units. This is the foundation for snapshotting, restoring, and replaying application state (the core of the time-travel approach).

**4. serialize — Effector**
Publisher: effector.dev · Date: n/a (verify at source)
Link: https://effector.dev/en/api/effector/serialize/
Abstract: Reference for `serialize(scope)`, which returns a plain `{sid: value}` snapshot of all stores in a scope. Restored via `fork({values})`/`hydrate()`. Notes the `onlyChanges` deprecation in effector 23 and the SID requirement.

**5. inspect — Effector**
Publisher: effector.dev · Date: n/a (verify at source)
Link: https://effector.dev/en/api/effector/inspect/ (also https://effector.dev/docs/api/effector/inspect/)
Abstract: Documents the low-level `inspect` API that streams every kernel computation as a `Message{kind, name, value, sid, trace}`. Enables an append-only event log and causal tracing — the recording half of time-travel.

**6. Babel plugin — Effector**
Publisher: effector.dev · Date: n/a (verify at source)
Link: https://effector.dev/en/api/effector/babel-plugin/
Abstract: Explains how the build plugin injects stable SIDs and unit names. Required for `serialize` to work and for custom factories to keep unique IDs; without it, snapshots omit or collide store values.

**7. Best Practices and Recommendations — Effector**
Publisher: effector.dev · Date: n/a (verify at source)
Link: https://effector.dev/uz/guides/best-practices/
Abstract: Official guidance reinforcing MVU discipline: keep stores small and decentralized, never call `getState()` inside logic (pass via `sample` source), isolate side effects in effects, declare units statically, organize by responsibility scope.

**8. Effector changelog**
Publisher: changelog.effector.dev · Date: n/a (verify at source)
Link: https://changelog.effector.dev/
Abstract: Version history tracking API evolution relevant to the build — e.g. `onlyChanges` deprecation (v23), the move from `useStore`/`useEvent` to `useUnit`, and Fork API changes. Used to flag version-sensitive guidance.

**9. ".watch calls are (not) weird" — With Ease (Effector magazine)**
Publisher: withease.effector.dev · Date: n/a (verify at source)
Link: https://withease.effector.dev/magazine/watch_calls
Abstract: Community-maintained Effector magazine article on the semantics of `.watch` and why it should be confined to debugging rather than logic. Informs the recommendation to use `inspect`/`patronum` for observation instead of `.watch`.

---

## 2. Effector — Ecosystem, Tooling & Time-Travel Libraries

Tooling and community libraries that supply the parts Effector core does not ship — devtools logging, undo/redo, and the canonical undo/redo design discussion.

**10. effector/logger — Releases (GitHub)**
Publisher: GitHub (effector) · Date: n/a (verify at source)
Link: https://github.com/effector/logger/releases
Abstract: Release feed for the official Effector logger/devtools adapter. Relevant to the finding that the Redux DevTools adapter is logging-only (no jump-to-state write-back into Effector scopes).

**11. effector-history — Kelin2025 (GitHub)**
Publisher: GitHub (Kelin2025) · Date: n/a (verify at source)
Link: https://github.com/Kelin2025/effector-history
Abstract: Utility library implementing undo/redo for Effector via `createHistory({source, clock, strategies})` with `undo()`, `redo()`, `$history`, `maxLength`, and merge strategies. The recommended in-session undo solution for local UI moves.

**12. effector-undo — tanyaisinmybed (GitHub)**
Publisher: GitHub (tanyaisinmybed) · Date: n/a (verify at source)
Link: https://github.com/tanyaisinmybed/effector-undo
Abstract: Simpler single-store undo/redo for Effector — `createHistory({store, limit, events, filter})`. Snapshot-based alternative to effector-history for narrower history needs.

**13. effector Spacewatch 23 tracking issue — Issue #755 (GitHub)**
Publisher: GitHub (effector/effector) · Date: n/a (verify at source)
Link: https://github.com/effector/effector/issues/755
Abstract: Tracking issue for an Effector release milestone. Used as context for API maturity and roadmap when assessing time-travel/Fork-API stability.

**14. "Effector — State Manager You Should Give a Try" — ITNEXT**
Publisher: ITNEXT (Medium) · Author: Anton Kosykh · Date: n/a (verify at source)
Link: https://itnext.io/effector-state-manager-you-should-give-a-try-b46b917e51cc
Abstract: Practitioner overview of Effector's value proposition — fine-grained reactivity, decentralized stores, explicit dataflow. Supports the rationale for choosing Effector over single-tree stores for a busy game UI.

---

## 3. State Management Alternatives — Redux, Zustand, XState

Sources backing the side-by-side comparison and the two alternative recommendations (RTK + redux-undo; Zustand + zundo), plus XState as a game-rules engine.

**15. redux-undo — npm**
Publisher: npm · Date: v1.0.0-beta7 listing
Link: https://www.npmjs.com/package/redux-undo/v/1.0.0-beta7
Abstract: Higher-order reducer adding `past/present/future` history to any Redux reducer, with `UNDO`/`REDO`/`JUMP` actions and action filtering (`includeAction`, `excludeAction`, `groupBy`, `limit`). Basis for the RTK time-travel claim.

**16. zustand-game-patterns — LobeHub Skills**
Publisher: LobeHub · Date: n/a (verify at source)
Link: https://lobehub.com/skills/neversight-learn-skills.dev-zustand-game-patterns
Abstract: Catalogue of Zustand patterns for game state (slices, `subscribeWithSelector`, persistence). Supports the Zustand-as-game-store alternative and the zundo time-travel pairing.

**17. "Redux vs XState — What are the differences?" — StackShare**
Publisher: StackShare · Date: n/a (verify at source)
Link: https://stackshare.io/stackups/reduxjs-vs-xstate
Abstract: Comparison framing Redux (single immutable store + reducers) against XState (statecharts). Used to position XState as a complementary game-rules layer rather than a whole-app store.

**18. statelyai/xstate (GitHub)**
Publisher: GitHub (statelyai) · Date: n/a (verify at source)
Link: https://github.com/statelyai/xstate
Abstract: Official repository for XState — finite states, events, transitions, guards, context, parallel/hierarchical states, and `@xstate/store`. Backs the recommendation to model the room/golden-room lifecycle as a statechart.

---

## 4. Immutability & Time-Travel Concepts

Conceptual grounding for immutable updates, structural sharing, and the snapshot-vs-delta tradeoff for undo/redo memory.

**19. "Introducing Immer: Immutability the easy way" — Michel Weststrate (HackerNoon/Medium)**
Publisher: Medium (HackerNoon) · Author: Michel Weststrate · Date: n/a (verify at source)
Link: https://medium.com/hackernoon/introducing-immer-immutability-the-easy-way-9d73d8f71cb3
Abstract: The original Immer introduction by its author — proxy-based copy-on-write producing immutable next-states from "mutating" draft code. Basis for using Immer for deep immutable game-state updates.

**20. "What is Structural Sharing in Immutable Data Structures" — Generalist Programmer**
Publisher: generalistprogrammer.com · Date: n/a (verify at source)
Link: https://generalistprogrammer.com/glossary/structural-sharing
Abstract: Glossary explainer on structural sharing — unchanged subtrees are reused while changed nodes and their ancestors are recreated. Justifies cheap snapshots and reference-equality memoization.

**21. "Rethinking Undo/Redo — Why We Need Travels" — DEV Community**
Publisher: DEV Community (dev.to) · Author: unadlib · Date: n/a (verify at source)
Link: https://dev.to/unadlib/rethinking-undoredo-why-we-need-travels-2lcc
Abstract: Argues for JSON-Patch (RFC 6902) delta-based history (the "Travels"/Mutative approach) over full snapshots to bound memory, with benchmark context. Backs the large-history caveat and the delta-based fallback recommendation.

---

## 5. Phoenix Channels & Real-Time Transport

Primary Phoenix documentation for the REST + Channels transport — the push/reply lifecycle, server callbacks, reconnection, and the PushBuffer.

**22. Phoenix JavaScript client docs (Phoenix 1.8.7)**
Publisher: HexDocs · Date: Phoenix v1.8.7 docs
Link: https://hexdocs.pm/phoenix/js/
Abstract: Reference for the JS client — `push(event, payload, timeout).receive("ok"/"error"/"timeout")`, `channel.on`, reconnection with exponential backoff, and the PushBuffer that queues/flushes messages across disconnects. Core to the optimistic-mutation transport.

**23. Phoenix.Channel behaviour (Phoenix v1.8.8)**
Publisher: HexDocs · Date: Phoenix v1.8.8 docs
Link: https://hexdocs.pm/phoenix/Phoenix.Channel.html
Abstract: Server-side channel callbacks — `handle_in/3`, reply tuples (`{:reply, {:ok, result}, socket}`), `broadcast!/3`, and `socket_ref/1` for deferred async replies. Defines how the backend confirms/rejects optimistic mutations and correlates server-initiated pushes.

**24. Channels — Phoenix (v1.8.8)**
Publisher: HexDocs · Date: Phoenix v1.8.8 docs
Link: https://hexdocs.pm/phoenix/channels.html
Abstract: Conceptual guide to topics, joins, multiplexed sockets, and per-topic processes holding `socket.assigns`. Establishes the `game:<roomId>` topic model and the rejoin/catch-up pattern used on reconnect.

---

## 6. Optimistic Updates & Reconciliation

Patterns for applying local changes immediately and reconciling/rolling back against authoritative server responses — including concurrency control and the multi-user WebSocket case.

**25. "Optimistic UI Updates: Making Apps Feel Instant Without Breaking Things" — Murtazaweb**
Publisher: murtazaweb.com · Date: 22 March 2026 (from URL)
Link: https://murtazaweb.com/blog/2026-03-22-optimistic-ui-updates-patterns/
Abstract: Pattern guide for optimistic UI — apply immediately, track pending ops with rollbacks, and "trust the server" by overwriting optimistic values with authoritative responses. The core reconciliation discipline used in the report.

**26. "Optimistic updates with concurrency control" — First Resonance Engineering (Medium)**
Publisher: Medium (First Resonance Engineering) · Author: Alan Torres · Date: n/a (verify at source)
Link: https://medium.com/first-resonance-engineering/optimistic-updates-with-concurrency-control-6f1b07b8e98d
Abstract: Covers optimistic updates under concurrency — version/ETag-style optimistic concurrency and lost-update protection. Backs the shared-state reconciliation rules (leaderboard, room state) and idempotency keys.

**27. "How Optimistic Updates Make Apps Feel Faster" — OpenReplay**
Publisher: blog.openreplay.com · Date: n/a (verify at source)
Link: https://blog.openreplay.com/optimistic-updates-make-apps-faster/
Abstract: Explains when optimistic UI is appropriate (high-success, reversible actions) and when to avoid it. Supports the caveat that irreversible/authoritative actions (final scoring, payments, rewards) should be server-confirmed.

**28. "Orchestrating Multi-User Workflows in Phoenix LiveView with WebSockets" — DEV Community**
Publisher: DEV Community (dev.to) · Author: hexshift · Date: n/a (verify at source)
Link: https://dev.to/hexshift/orchestrating-multi-user-workflows-in-phoenix-liveview-with-websockets-g8d
Abstract: Multi-user real-time coordination over Phoenix WebSockets, including first-write-wins with clear status messaging ("Already approved by …"). Informs concurrent-edit handling for competitive/shared Codemoji state.

---

## 7. Event Sourcing — Elixir & React

Sources establishing the front/back symmetry argument: an event-sourced Elixir backend and a replayable front-end timeline as two views of the same immutable event log.

**29. event-sourcing.elixir — ktec (GitHub)**
Publisher: GitHub (ktec) · Date: n/a (verify at source)
Link: https://github.com/ktec/event-sourcing.elixir
Abstract: Elixir event-sourcing / virtual-actors reference. Context for how Codemojex can realize immutable, time-travel-capable state via append-only events plus reducers and periodic snapshots.

**30. "Event Sourcing in React, Redux & Elixir" — Rapport Blog (Medium)**
Publisher: Medium (Rapport Blog) · Author: Gary McAdam · Date: n/a (verify at source)
Link: https://medium.com/rapport-blog/event-sourcing-in-react-redux-elixir-how-we-write-fast-scalable-real-time-apps-at-rapport-4a26c3aa7529
Abstract: Case study persisting Redux actions to Postgres over Phoenix Channels and replaying them to any point in time. The canonical real-world example of the front/back event-log symmetry the report recommends.

---

## 8. TypeScript Branded / Nominal Types

Backing for mirroring the Elixir "Branded ID" engine with zero-runtime-cost nominal types in TypeScript (`EmojiId`, `SlotId`, `RoomId`, `KeyId`, `MutationId`).

**31. "Branded Types in TypeScript: Beyond Primitive Type Safety" — DEV Community**
Publisher: DEV Community (dev.to) · Author: Kuncheria Kuruvilla · Date: n/a (verify at source)
Link: https://dev.to/kuncheriakuruvilla/branded-types-in-typescript-beyond-primitive-type-safety-5bba
Abstract: Practical guide to branded types for nominal safety over structurally-identical primitives. Basis for the `Brand<T, B>` helper and smart-constructor pattern in the report.

**32. "Branded Types in TypeScript: From Structural to Nominal Typing" — Nana Adjei Manu**
Publisher: nanamanu.com · Author: Nana Adjei Manu · Date: n/a (verify at source)
Link: https://nanamanu.com/posts/branded-types-typescript/
Abstract: Explains TypeScript's structural typing and how branding simulates nominal typing, including `unique symbol` brands to avoid autocomplete noise. Informs the recommended brand implementation.

**33. "TypeScript Branded Types" — Viprasol Tech**
Publisher: viprasol.com · Date: n/a (verify at source)
Link: https://viprasol.com/blog/typescript-branded-types/
Abstract: Concise reference on branded-type construction and validation at trust boundaries. Supports branding channel payloads and `initData` on decode.

**34. "Branded Types" — Effect Documentation**
Publisher: effect.website · Date: n/a (verify at source)
Link: https://effect.website/docs/code-style/branded-types/
Abstract: Effect library's `Brand.nominal` / `Brand.refined` utilities. Offered as an alternative branding approach if Effect-style utilities are adopted alongside the ID system.

---

## 9. Telegram Mini Apps

Platform documentation and starter material — SDK, the React template, the creation handbook, and `initData` HMAC validation for auth.

**35. Telegram Mini Apps — official docs**
Publisher: core.telegram.org · Date: n/a (verify at source)
Link: https://core.telegram.org/bots/webapps
Abstract: Authoritative Telegram Web Apps reference — `window.Telegram.WebApp`, `ready()`, `initData`/`initDataUnsafe`, theme params, haptics, MainButton, and the `initData` signature scheme used for server-side auth.

**36. reactjs-template — Telegram-Mini-Apps (GitHub)**
Publisher: GitHub (Telegram-Mini-Apps) · Date: n/a (verify at source)
Link: https://github.com/Telegram-Mini-Apps/reactjs-template
Abstract: Official Mini App starter using React, `@tma.js/sdk`, TypeScript, and Vite, with `mockTelegramEnv` for out-of-Telegram development. The recommended scaffolding for the Codemoji client.

**37. "Telegram Mini Apps Creation Handbook" — DEV Community**
Publisher: DEV Community (dev.to) · Author: simplr_sh · Date: n/a (verify at source)
Link: https://dev.to/simplr_sh/telegram-mini-apps-creation-handbook-58em
Abstract: End-to-end walkthrough of building a Mini App. Context for project setup, the SDK surface, and Telegram-native UI components.

**38. "How Telegram Mini-Apps Handle User Authentication" — CRMChat**
Publisher: crmchat.ai · Date: n/a (verify at source)
Link: https://crmchat.ai/blog/how-telegram-mini-apps-handle-user-authentication
Abstract: Explains the `initData` auth flow — client sends `initData`, server validates the HMAC-SHA256 signature and `auth_date` freshness. Backs the mandatory server-side validation step before gameplay.

**39. "Telegram Bot 6.0 — Validating data received via the Web App" — GitHub Gist**
Publisher: GitHub Gist (konstantin24121) · Date: n/a (verify at source)
Link: https://gist.github.com/konstantin24121/49da5d8023532d66cc4db1136435a885
Abstract: Reference implementation of `initData` validation (secret = HMAC-SHA256 of bot token with constant `"WebAppData"`). Concrete basis for the Elixir `:crypto.mac/4` validation guidance.

---

## Summary by Group

| # | Group | Count |
|---|-------|-------|
| 1 | Effector — Core Documentation & API | 9 |
| 2 | Effector — Ecosystem, Tooling & Time-Travel Libraries | 5 |
| 3 | State Management Alternatives — Redux, Zustand, XState | 4 |
| 4 | Immutability & Time-Travel Concepts | 3 |
| 5 | Phoenix Channels & Real-Time Transport | 3 |
| 6 | Optimistic Updates & Reconciliation | 4 |
| 7 | Event Sourcing — Elixir & React | 2 |
| 8 | TypeScript Branded / Nominal Types | 4 |
| 9 | Telegram Mini Apps | 5 |
| | **Total** | **39** |

---

*Primary sources (official docs: Effector, Phoenix/HexDocs, Telegram, Effect, npm, GitHub) are weighted above community blog posts (DEV, Medium, StackShare, vendor blogs). Effector documentation URLs are version-sensitive (v22 paths vs. current unversioned docs); verify against current effector.dev before implementation.*
