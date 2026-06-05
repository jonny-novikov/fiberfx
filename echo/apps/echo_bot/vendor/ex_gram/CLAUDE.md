# CLAUDE.md — vendor/ex_gram (owned-fork directive)

This directory is a **vendored fork of ex_gram maintained by the ex_gram team**. The Operator is
the ex_gram team, tasked by the main maintainer to build the next-generation bot modules on top of
this code. Treat the contents here as **owned source**.

## Ownership

- Agents **may Read, Write, and modify this code directly**. It is not a read-only third-party
  dependency — it is the team's own copy, edited in place like any other source under `apps/`.
- Changes here are **not** submitted as upstream pull requests to ex_gram main. There is **no
  fork-back obligation** — the copy diverges on the engine's own schedule.
- Provenance and the preserved Beer-Ware license live in `README.md` (read it for what was taken
  from upstream and what the wrap adds).

## The one surviving constraint

Ownership removes the third-party constraints but **one** constraint survives: the `echo_bot`
engine core reaches this code **only** through `EchoBot.Platform.Telegram`. No module outside that
adapter names a vendored module (F10.1-INV4). The wrap — `EchoBot.Platform.Telegram` against the
`EchoBot.Platform` behaviour — is the long-lived boundary; the copy's internals are replaceable
behind it (F10.6) with no engine-core change. When editing this code, keep that single boundary:
the adapter is the only caller.

## Prose discipline (propagation clause — carry into every artifact and edit here)

Impersonal and structural. No first-person narration. No gendered pronouns for agents or modules.
No perceptual or interior-state verbs with a module or an agent as the subject. Describe what the
code does and what the contract requires, not what anything "sees", "wants", "knows", or "feels".
Carry this clause forward into any sub-prompt, comment, or document emitted while working here.
