---
name: echo-mq-stories-generator
description: echo_mq BDD self-documenting tests → mix echo_mq.stories generates docs/echo_mq/stories/ feature catalogue
metadata: 
  node_type: memory
  type: project
  originSessionId: 142777a0-b394-462f-8040-9731fa1fdc0e
---

The echo_mq app has a **BDD self-documenting-tests → generated-stories** pipeline (built 2026-06-15 at the Operator's request, NOT in CLAUDE.md):

- **The DSL** `EchoMQ.Story` (`echo/apps/echo_mq/test/support/echo_mq/story.ex`) — `use EchoMQ.Story, feature: "X"` + `scenario`/`given_`/`when_`/`then_`/`and_`/`but_`. Each `scenario` emits a real ExUnit `test` AND registers its Given/When/Then steps, harvested from the block AST at compile time into `__stories__/0`. Two macro gotchas: `scenario` must emit `ExUnit.Case.test` **fully-qualified** (hygiene — a bare `test` resolves in EchoMQ.Story's context and won't compile); the step macros expand **inline** to their body (no wrapper), so a var bound in `given_` is visible in `then_`. Needs `elixirc_paths(:test) = ["lib", "test/support"]` (added to mix.exs).
- **The generator** `mix echo_mq.stories` (`echo/apps/echo_mq/lib/mix/tasks/echo_mq.stories.ex`) — reads each story module's compile-time `__stories__/0` **offline (no Valkey)** and writes `docs/echo_mq/stories/<feature>.stories.md` (one file per feature) + a `README.md` catalogue. Paths anchored on `__DIR__` (cwd-independent); `--out` override. Generation needs no Valkey because a scenario reaches the catalogue only by *compiling*.
- **The story tests** `echo/apps/echo_mq/test/stories/*_story_test.exs` (`:valkey`, `async: false`) — real acceptance tests vs the live API. Two built: `flows` (children_values/dependencies) + `groups` (Lanes admission/rotation/pause/limit).

To add a feature: drop `test/stories/<f>_story_test.exs` using the DSL, run `mix echo_mq.stories` (re-run after editing a scenario — the docs are generated-from-code, never hand-edited). As of build it was UNCOMMITTED (Operator commits out-of-band) — verify on disk before relying. Related: [[echomq-umbrella-app]], [[echo-mq-three-movements]], [[jonnify-cms-toolchain]].
