import type Channel from "./channel"
import type {
  PresenceOnJoinCallback,
  PresenceOnLeaveCallback,
  PresenceOpts,
} from "./types"

/**
 * Initializes the Presence
 * @param {Channel} channel - The Channel
 * @param {Object} opts - The options,
 *        for example `{events: {state: "state", diff: "diff"}}`
 */
export default class Presence {
  // The presence map is genuinely untyped wire data (arbitrary keys → metas).
  state: any
  pendingDiffs: any[]
  channel: Channel
  joinRef: string | null
  caller: {
    onJoin: PresenceOnJoinCallback
    onLeave: PresenceOnLeaveCallback
    onSync: () => void | Promise<void>
  }

  constructor(channel: Channel, opts: PresenceOpts = {}){
    let events = opts.events || {state: "presence_state", diff: "presence_diff"}
    this.state = {}
    this.pendingDiffs = []
    this.channel = channel
    this.joinRef = null
    this.caller = {
      onJoin: function (){ },
      onLeave: function (){ },
      onSync: function (){ }
    }

    this.channel.on(events.state, newState => {
      let {onJoin, onLeave, onSync} = this.caller

      this.joinRef = this.channel.joinRef()
      this.state = Presence.syncState(this.state, newState, onJoin, onLeave)

      this.pendingDiffs.forEach(diff => {
        this.state = Presence.syncDiff(this.state, diff, onJoin, onLeave)
      })
      this.pendingDiffs = []
      onSync()
    })

    this.channel.on(events.diff, diff => {
      let {onJoin, onLeave, onSync} = this.caller

      if(this.inPendingSyncState()){
        this.pendingDiffs.push(diff)
      } else {
        this.state = Presence.syncDiff(this.state, diff, onJoin, onLeave)
        onSync()
      }
    })
  }

  onJoin(callback: PresenceOnJoinCallback): void{ this.caller.onJoin = callback }

  onLeave(callback: PresenceOnLeaveCallback): void{ this.caller.onLeave = callback }

  onSync(callback: () => void | Promise<void>): void{ this.caller.onSync = callback }

  list<T = any>(by?: (key: string, presence: any) => T): T[]{ return Presence.list(this.state, by) }

  inPendingSyncState(): boolean{
    return !this.joinRef || (this.joinRef !== this.channel.joinRef())
  }

  // lower-level public static API

  /**
   * Used to sync the list of presences on the server
   * with the client's state. An optional `onJoin` and `onLeave` callback can
   * be provided to react to changes in the client's local presences across
   * disconnects and reconnects with the server.
   *
   * @returns {Presence}
   */
  static syncState(currentState: object, newState: object, onJoin?: PresenceOnJoinCallback, onLeave?: PresenceOnLeaveCallback): any{
    let state = this.clone(currentState)
    let joins: Record<string, any> = {}
    let leaves: Record<string, any> = {}

    this.map(state, (key, presence) => {
      if(!(newState as Record<string, any>)[key]){
        leaves[key] = presence
      }
    })
    this.map(newState, (key, newPresence) => {
      let currentPresence = state[key]
      if(currentPresence){
        let newRefs = newPresence.metas.map((m: any) => m.phx_ref)
        let curRefs = currentPresence.metas.map((m: any) => m.phx_ref)
        let joinedMetas = newPresence.metas.filter((m: any) => curRefs.indexOf(m.phx_ref) < 0)
        let leftMetas = currentPresence.metas.filter((m: any) => newRefs.indexOf(m.phx_ref) < 0)
        if(joinedMetas.length > 0){
          joins[key] = newPresence
          joins[key].metas = joinedMetas
        }
        if(leftMetas.length > 0){
          leaves[key] = this.clone(currentPresence)
          leaves[key].metas = leftMetas
        }
      } else {
        joins[key] = newPresence
      }
    })
    return this.syncDiff(state, {joins: joins, leaves: leaves}, onJoin, onLeave)
  }

  /**
   *
   * Used to sync a diff of presence join and leave
   * events from the server, as they happen. Like `syncState`, `syncDiff`
   * accepts optional `onJoin` and `onLeave` callbacks to react to a user
   * joining or leaving from a device.
   *
   * @returns {Presence}
   */
  static syncDiff(state: object, diff: { joins: object; leaves: object }, onJoin?: PresenceOnJoinCallback, onLeave?: PresenceOnLeaveCallback): any{
    let {joins, leaves} = this.clone(diff)
    if(!onJoin){ onJoin = function (){ } }
    if(!onLeave){ onLeave = function (){ } }

    this.map(joins, (key, newPresence) => {
      let currentPresence = (state as Record<string, any>)[key]
      ;(state as Record<string, any>)[key] = this.clone(newPresence)
      if(currentPresence){
        let joinedRefs = (state as Record<string, any>)[key].metas.map((m: any) => m.phx_ref)
        let curMetas = currentPresence.metas.filter((m: any) => joinedRefs.indexOf(m.phx_ref) < 0)
        ;(state as Record<string, any>)[key].metas.unshift(...curMetas)
      }
      // onJoin is guaranteed defined by the guard above.
      onJoin!(key, currentPresence, newPresence)
    })
    this.map(leaves, (key, leftPresence) => {
      let currentPresence = (state as Record<string, any>)[key]
      if(!currentPresence){ return }
      let refsToRemove = leftPresence.metas.map((m: any) => m.phx_ref)
      currentPresence.metas = currentPresence.metas.filter((p: any) => {
        return refsToRemove.indexOf(p.phx_ref) < 0
      })
      // onLeave is guaranteed defined by the guard above.
      onLeave!(key, currentPresence, leftPresence)
      if(currentPresence.metas.length === 0){
        delete (state as Record<string, any>)[key]
      }
    })
    return state
  }

  /**
   * Returns the array of presences, with selected metadata.
   *
   * @param {Object} presences
   * @param {Function} chooser
   *
   * @returns {Presence}
   */
  static list<T = any>(presences: object, chooser?: (key: string, presence: any) => T): T[]{
    if(!chooser){ chooser = function (key, pres){ return pres } }

    return this.map(presences, (key, presence) => {
      // chooser is guaranteed defined by the guard above.
      return chooser!(key, presence)
    })
  }

  // private

  static map(obj: any, func: (key: string, value: any) => any): any[]{
    return Object.getOwnPropertyNames(obj).map(key => func(key, obj[key]))
  }

  static clone(obj: any): any{ return JSON.parse(JSON.stringify(obj)) }
}
