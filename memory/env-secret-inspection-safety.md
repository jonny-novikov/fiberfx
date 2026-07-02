---
name: env-secret-inspection-safety
description: How to inspect/transform .env secret files WITHOUT leaking values into the transcript — key-only listing + file→file transforms (leaked twice before this rule)
project: aaw
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 466fdd7e-18b5-4685-aa04-c820181e763a
---

When handling `.env`-style secret files, never print their contents.

**List keys only** (works for BOTH `KEY=value` and `KEY: value`):
`grep -oE '^[A-Za-z_][A-Za-z0-9_]*' file`. Do NOT use `sed -E 's/=.*/=<set>/'` to "mask" — it
silently FAILS on colon-separated files (e.g. `fly storage create` / Tigris output is `KEY: value`),
so the values print in full.

**Transform secrets file→file via a redirected block**, so values go to disk, not stdout:
```
val() { grep -E "^$1:" "$SRC" | head -1 | sed -E "s/^$1:[[:space:]]*//"; }
{ printf 'DEST_KEY="%s"\n' "$(val SRC_KEY)"; ... } >> "$DEST"   # the block's stdout -> the file
```
To verify, re-list keys (masking the secret ones) or `source` in a subshell and print only
`${#var}` lengths / non-secret values — never the secret value.

**Why:** transcripts may be shared/persisted. This was learned the hard way — a Telegram bot token
(a `${VAR:-...}` expansion quirk) and a Tigris keypair (the `sed`-mask-on-`:`-format miss) both leaked
into the session before this rule. **How to apply:** key-only listing; file→file transforms; flag any
inadvertent leak to the Operator so they can rotate. Related: [[codemojex-livereact-render]].
