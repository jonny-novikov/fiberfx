/**
 * Cross-cutting shapes shared across the vendored Phoenix client classes.
 *
 * These mirror DefinitelyTyped `@types/phoenix` exactly (see types-phoenix.d.ts).
 * Payloads/responses are `any` to match the untyped wire surface upstream uses.
 */

// --- The wire envelope ------------------------------------------------------
// Field set grounded in serializer.ts (encode/decode/binaryDecode return shape)
// and socket.ts onConnMessage destructuring: {topic, event, payload, ref, join_ref}.
// `status` rides on reply payloads ({status, response}) — kept optional here so
// the envelope itself can carry it where upstream reads `payload.status`.
export interface Message {
  join_ref: string | null
  ref: string | null
  topic: string
  event: string
  payload: any
  status?: string
}

// --- The unions (verbatim from @types/phoenix) ------------------------------
export type PushStatus = "ok" | "error" | "timeout"
export type ChannelState = "closed" | "errored" | "joined" | "joining" | "leaving"
export type ConnectionState = "connecting" | "open" | "closing" | "closed"
export type BinaryType = "arraybuffer" | "blob"
export type MessageRef = string

// --- Socket construction options (verbatim from @types/phoenix) -------------
export interface SocketConnectOption {
  authToken: string
  binaryType: BinaryType
  params: object | (() => object)
  transport: new (endpoint: string) => object
  timeout: number
  heartbeatIntervalMs: number
  longPollFallbackMs: number
  longpollerTimeout: number
  encode: (payload: object, callback: (encoded: any) => void | Promise<void>) => void
  decode: (payload: string, callback: (decoded: any) => void | Promise<void>) => void
  logger: (kind: string, message: string, data: any) => void
  reconnectAfterMs: (tries: number) => number
  rejoinAfterMs: (tries: number) => number
  vsn: string
  debug: boolean
  sessionStorage: object
}

// --- Callback aliases -------------------------------------------------------
// The socket keeps stateChangeCallbacks keyed by lifecycle event; the bound
// callbacks are heterogeneous (open/close/error/message), so the broad alias
// matches @types/phoenix's untyped-payload posture.
export type StateChangeCallback = (...args: any[]) => void

export type PresenceOnJoinCallback = (
  key?: string,
  currentPresence?: any,
  newPresence?: any,
) => void

export type PresenceOnLeaveCallback = (
  key?: string,
  currentPresence?: any,
  newPresence?: any,
) => void

export interface PresenceOpts {
  events?: { state: string; diff: string } | undefined
}
