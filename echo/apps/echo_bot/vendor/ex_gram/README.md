# vendor/ex_gram — a vendored, owned copy of ex_gram (minimal subset)

## What this directory is

A **vendored copy** of a minimal subset of [ex_gram](https://github.com/rockneurotiko/ex_gram),
carried as **owned source** inside `apps/echo_bot`. It is not a hex dependency and not a git
submodule — it is source the `echo_bot` engine owns and maintains in place. The `EchoBot` engine
core never names these modules; it reaches them **only** through the `EchoBot.Platform.Telegram`
adapter (F10.1-INV4).

## Provenance

- **Upstream**: ex_gram — <https://github.com/rockneurotiko/ex_gram> (Hex: <https://hexdocs.pm/ex_gram>).
- **Upstream version at vendoring**: ex_gram `~> 0.x` (the current line on Hex at the time of
  vendoring, 2026-06; the auto-generated Bot-API client tracking the live Telegram Bot API).
- **What was taken** (the minimal F10.1 subset — the `getUpdates` long-poll + `sendMessage` path):
  - `lib/ex_gram/client.ex` — the low-level Bot API client (`get_updates/2`, `send_message/4`),
    transport over OTP's built-in `:httpc`/`:ssl` (no Finch/Tesla/hackney).
  - `lib/ex_gram/model.ex` — the update/message decoders (`Update`, `Message`, `Chat`, `User` and
    their `decode_*` functions), a hand-narrowed slice of the upstream auto-generated model.
  - `lib/ex_gram/updater.ex` — the **updater shape**: `ExGram.Updater.Polling` (the long-poll loop)
    and `ExGram.Updater.Noup` (the `:noup` no-op updates source ex_gram ships for tests).
- **What was NOT taken**: the full auto-generated Bot-API surface, the bot DSL macros, the webhook
  updater (F10.5), the dispatcher/registry, the test helpers, and every method beyond
  `getUpdates`/`sendMessage`. The subset is deliberately minimal — only what F10.1 needs.

## What `echo_bot` adds around the copy

`echo_bot` does **not** modify the copy to add its abstractions; it **wraps** the copy. The
engine's platform surface is the `EchoBot.Platform` behaviour, and `EchoBot.Platform.Telegram`
implements it by calling into the vendored modules above. The **wrap — not the copy — is the
long-lived boundary**: later rungs (F10.6) replace the vendored internals with first-party code
behind the unchanged `EchoBot.Platform` port, on the engine's own schedule, with no engine-core
change. Only `EchoBot.Platform.Telegram` names a vendored module.

## License (preserved verbatim)

ex_gram is distributed under **THE BEER-WARE LICENSE (Revision 42)**, preserved here unchanged:

```
/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Rodrigo Navarro wrote this file. As long as you retain this notice you
 * can do whatever you want with this stuff. If we meet some day, and you think
 * this stuff is worth it, you can buy me a beer in return.
 * ----------------------------------------------------------------------------
 */
```

The notice is retained as the license requires. See the upstream repository for the canonical
license text.
