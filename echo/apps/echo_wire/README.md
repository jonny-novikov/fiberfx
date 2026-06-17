# echo_wire -- the wire layer

RESP framing (`EchoMQ.RESP`), the single-owner socket connector
(`EchoMQ.Connector`), and the fenced script registry (`EchoMQ.Script`),
extracted as their own application with `EchoWire` as the front door.

## The name

The series' own vocabulary already calls this layer the wire -- every
committed record prices the wire, sweeps the wire, parks on the wire -- so
the application is `echo_wire`. Considered and declined: `echo_conn` (too
generic), `echo_resp` (names the framing, not the layer), `echo_link`
(collides with process-linking vocabulary).

## The names underneath

`EchoMQ.Connector`, `EchoMQ.RESP`, and `EchoMQ.Script` keep their module
names: the committed records and the article series cite them, and records
freeze. `EchoWire` delegates the full verb surface (`command`, `pipeline`,
`noreply_pipeline`, `transaction_pipeline`, `eval`, `push_command`,
`subscribe`, `stats`, `script/2`) and is the name new consumers should hold.

## Depends on

Nothing. stdlib and `:crypto`; telemetry events fire only when the
`:telemetry` application is present (runtime-guarded), so the library adds
no dependency to a host that does not already carry one.
