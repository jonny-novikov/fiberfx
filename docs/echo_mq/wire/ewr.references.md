# EchoWire — references

This program does **not** restate the shared bibliography. The Echo-wide reference set — the BEAM, RESP, Valkey,
the BCS papers — is [`../emq.references.md`](../emq.references.md); read it first. Below are only the sources
**specific to the wire client core**, each cited where a rung uses it.

## Primary sources (wire-specific)

- **rueidis / valkey-go** — the reference client this program ports its construction ergonomics from. Local
  checkout `go/valkey-go` (read-only, cited never copied). The patterns and their anchors are catalogued in
  [`ewr.features.md`](ewr.features.md): the fluent builder (`internal/cmds/gen_string.go`), the immutable
  command + `cf` flags (`internal/cmds/cmds.go:5-23,117`), auto-pipelining (`pipe.go:1097`), client-side
  caching (`pipe.go:1480`), and the two-tier error split (`message.go:149,154`).
- **RESP3** — the protocol the wire speaks; the decoder is `EchoMQ.RESP`. The 13-term `reply()` type
  (`echo/apps/echo_wire/lib/echo_mq/resp.ex:30`) is the authority for what a reply can be.
- **Valkey server-assisted client-side caching (`CLIENT TRACKING`)** — the substrate for Movement II. The
  RESP3 invalidation-push model (`> invalidate`) is what the caching seam (decision 3) would build on; the
  rueidis integration is the reference (`pipe.go:185,748`).

## The program's own canon

- The ruled design fork: [`design/ewr.design.md`](design/ewr.design.md).
- The method the fork follows: [`aaw.architect-approach.md`](../../aaw/aaw.architect-approach.md).
- The owned-wire floor it builds on: `echo/apps/echo_wire` (the connector, RESP, Script, the facade) and the
  bus's pool `echo/apps/echo_mq/lib/echo_mq/pool.ex`.

---

Shared bibliography: [`../emq.references.md`](../emq.references.md) · Roadmap: [`ewr.roadmap.md`](ewr.roadmap.md)
