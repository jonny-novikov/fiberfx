---
name: operator-runs-deploys
description: "NEVER run `fly deploy` (or any deploy) — the Operator always runs deploys themselves; ask/hand off"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c36ee942-28f6-43e5-80f5-147072eaecaa
---

The Operator ALWAYS runs deploys themselves. Never run `fly deploy` (or any equivalent app-release/deploy command) on the Operator's infra — when a deploy is needed, stop and ask the Operator to run it, then verify the result.

**Why:** On the `echo-valkey` Fly setup (2026-06-25) I tried to run `fly deploy` as part of a cleanup; the Operator rejected the tool call and corrected: "ALWAYS ASK OPERATOR FOR DEPLOY." They then ran the deploy + released the IPs themselves and handed me the verify/operate steps.

**How to apply:** Deploys are the Operator's hard line. Operational actions *around* a deploy are fine and expected of me — verifying machine config (`fly machine status --display-config`), reading `fly ips list` / `fly secrets list`, starting a stopped machine for a check, opening a `fly proxy` tunnel, running an authenticated `PING`. But the release itself (`fly deploy`) is hand-off-only. Pattern for this stack: Operator deploys → I reconcile-verify (no services/autostop, no public IP, checks green) → I prove reachability over 6PN. Related infra notes: the echo-valkey node is private-by-design (6PN `echo-valkey.internal:6390`, AOF, single volume/machine, `requirepass` via the `VALKEY_EXTRA_FLAGS` secret).
