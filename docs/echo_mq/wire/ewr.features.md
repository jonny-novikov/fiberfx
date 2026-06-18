# EchoWire — the valkey-go pattern catalog + the additive/MAJOR map

What the rueidis-derived client (`go/valkey-go`) does, and where each pattern lands in EchoWire: already in the
owned wire, a Movement-I additive layer, or a Movement-II seam that may cut the frozen connector. Scope is
[`ewr.roadmap.md`](ewr.roadmap.md); this catalog is the *why each rung exists* and the *blast-radius* of each.

## The map

| valkey-go pattern | reference anchor | EchoWire disposition | blast radius |
| --- | --- | --- | --- |
| Connection-level **auto-pipelining** | `DoMulti`, `pipe.go:1097` | **already present** — `Connector` (`send_pipe/5`..`drain/1`) | none (not re-ported) |
| **Transaction** wrapping (MULTI/EXEC) | `MultiCmd`/`ExecCmd`, `cmds.go` | **already present** — `Connector.transaction_pipeline/3` (:130) | none |
| **Reply suppression** (noreply) | `noRetTag`, `cmds.go:14` | **already present** — `Connector.noreply_pipeline/3` (:125) | none |
| **EVALSHA-first** scripting | `Lua`/`Exec`, `lua.go` | **already present** — `Script.new/2` + `Connector.eval/5` (:63) | none |
| **RESP3 decode** incl. push frames | `ValkeyMessage`, `message.go` | **already present** — `RESP` (the `reply()` type, resp.ex:30) | none |
| The fluent **command builder** | `B().Set()…Build()`, `gen_string.go` | **Movement I** — `EchoWire.Pipe` curated verbs (`ewr.1.1`) + the command value (`ewr.1.2`) | additive (above `pipeline/3`) |
| The immutable **command value + `cf` flags** | `Completed`, `cmds.go:117`; flags `cmds.go:5-23` | **Movement I** — `ewr.1.2`, flags **advisory** in the upper layer (seam 4) | additive |
| The **two-tier error split** | `NonValkeyError()` `message.go:149` / `Error()` `:154` | **Movement I** — `ewr.1.3`, a result classifier over `pipeline/3`'s return | additive |
| **Client-side caching** / CLIENT TRACKING | `DoCache` `pipe.go:1480`; handshake `:185`; `invalidate`→evict `:748` | **Movement II** — `ewr.2.x`, gated on a consumer | **MAJOR** (connector boot-step `:436`) |

## The fault line (why the split is exactly here)

The owned connector already does everything that is *connection behaviour* — pipelining, transactions, reply
suppression, scripting, decoding. So EchoWire's core adds only what is *above the wire*: how a caller
**assembles** `[[binary]]` before handing it to a verb that exists, and how it **reads** the result. Those are
pure functions over the connector's existing surface — additive-minor, no frozen touch, the 52-scenario
conformance untouched.

The one pattern that is **not** above the wire is server-assisted caching. Its send side composes from existing
verbs, but its coherence half — `CLIENT TRACKING ON [OPTIN|BCAST]` established at connect and re-established on
reconnect, and `invalidate` pushes turned into evictions — reaches into the connector's boot sequence
(`boot_rest/4`, connector.ex:436). That is a wire **MAJOR**, so it is held behind a seam with its own surfaced
fork, never folded into an additive rung.

## Out of scope (named, not built)

- **Cluster routing / key-slot dispatch.** rueidis computes a key slot per command (`ks`); EchoWire's curated
  verbs may carry slot metadata as advisory data (with the `cf` flags, `ewr.1.2`), but slot-aware routing has
  no consumer until a cluster deployment exists.
- **Connection retry/replay on the advisory flags.** The connector fails in-flight callers `:disconnected`
  without replay by design; promoting a `readonly`/`retryable` flag to replay behaviour is a separate
  connector decision (seam 4), not a core rung.

---

Roadmap: [`ewr.roadmap.md`](ewr.roadmap.md) · Design: [`design/ewr.design.md`](design/ewr.design.md) ·
References: [`ewr.references.md`](ewr.references.md)
