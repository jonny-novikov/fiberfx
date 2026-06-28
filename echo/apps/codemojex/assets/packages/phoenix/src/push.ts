import type Channel from "./channel"
import type {PushStatus} from "./types"

// The reply envelope a Push receives back over the wire. `response` is the
// untyped server payload, so it stays `any` (genuinely dynamic wire data).
type PushReply = {status: string; response?: any}

/**
 * Initializes the Push
 * @param {Channel} channel - The Channel
 * @param {string} event - The event, for example `"phx_join"`
 * @param {Object} payload - The payload, for example `{user_id: 123}`
 * @param {number} timeout - The push timeout in milliseconds
 */
export default class Push {
  channel: Channel
  event: string
  // Stored as a thunk: the constructor receives an `object` (per @types/phoenix)
  // but callers always pass a function, and `send()` invokes `this.payload()`.
  payload: () => object
  receivedResp: PushReply | null
  timeout: number
  // setTimeout handle (number under DOM / NodeJS.Timeout under @types/node) or null.
  timeoutTimer: ReturnType<typeof setTimeout> | null
  // callback `response` is the untyped server payload — kept `any` (dynamic wire data).
  recHooks: { status: string; callback: (response?: any) => any }[]
  sent: boolean
  // ref / refEvent are created on `startTimeout`/`reset`, never in the constructor;
  // `declare` keeps them type-only (emits no field) so runtime is unchanged.
  declare ref: string | null
  declare refEvent: string | null

  constructor(channel: Channel, event: string, payload: object, timeout: number){
    this.channel = channel
    this.event = event
    this.payload = (payload || function (){ return {} }) as () => object
    this.receivedResp = null
    this.timeout = timeout
    this.timeoutTimer = null
    this.recHooks = []
    this.sent = false
  }

  /**
   *
   * @param {number} timeout
   */
  resend(timeout: number): void{
    this.timeout = timeout
    this.reset()
    this.send()
  }

  /**
   *
   */
  send(): void{
    if(this.hasReceived("timeout")){ return }
    this.startTimeout()
    this.sent = true
    this.channel.socket.push({
      topic: this.channel.topic,
      event: this.event,
      payload: this.payload(),
      ref: this.ref,
      join_ref: this.channel.joinRef()
    })
  }

  /**
   *
   * @param {*} status
   * @param {*} callback
   */
  // callback is user-supplied and receives the dynamic wire response — `any` retained.
  receive(status: PushStatus, callback: (response?: any) => any): this{
    if(this.hasReceived(status)){
      callback(this.receivedResp.response)
    }

    this.recHooks.push({status, callback})
    return this
  }

  /**
   * @private
   */
  reset(): void{
    this.cancelRefEvent()
    this.ref = null
    this.refEvent = null
    this.receivedResp = null
    this.sent = false
  }

  /**
   * @private
   */
  matchReceive({status, response, _ref}: {status: string; response?: any; _ref?: unknown}): void{
    this.recHooks.filter(h => h.status === status)
      .forEach(h => h.callback(response))
  }

  /**
   * @private
   */
  cancelRefEvent(): void{
    if(!this.refEvent){ return }
    this.channel.off(this.refEvent)
  }

  /**
   * @private
   */
  cancelTimeout(): void{
    // `!` is type-only: clearTimeout ignores a null/undefined handle at runtime.
    clearTimeout(this.timeoutTimer!)
    this.timeoutTimer = null
  }

  /**
   * @private
   */
  startTimeout(): void{
    if(this.timeoutTimer){ this.cancelTimeout() }
    this.ref = this.channel.socket.makeRef()
    this.refEvent = this.channel.replyEventName(this.ref)

    this.channel.on(this.refEvent, (payload: PushReply) => {
      this.cancelRefEvent()
      this.cancelTimeout()
      this.receivedResp = payload
      this.matchReceive(payload)
    })

    this.timeoutTimer = setTimeout(() => {
      this.trigger("timeout", {})
    }, this.timeout)
  }

  /**
   * @private
   */
  // Type predicate (not a plain `boolean`): a true result also tells callers
  // `receivedResp` is non-null, so `receive()` can read `.response` unguarded.
  // `as boolean` is type-only — the `&&` short-circuit value is unchanged at runtime.
  hasReceived(status: string): this is Push & {receivedResp: PushReply}{
    return (this.receivedResp && this.receivedResp.status === status) as boolean
  }

  /**
   * @private
   */
  // response is the untyped server/wire payload forwarded to channel.trigger — kept `any`.
  trigger(status: string, response?: any): void{
    // refEvent is set by startTimeout before any trigger fires.
    this.channel.trigger(this.refEvent!, {status, response})
  }
}
