import type Channel from "./channel"
import type {
  PresenceOnJoinCallback,
  PresenceOnLeaveCallback,
  PresenceOpts,
} from "./types"

// A single presence meta entry carries a `phx_ref` plus arbitrary user metadata
// (the user-supplied fields are genuinely dynamic wire JSON, hence the index any).
interface PresenceMeta {
  phx_ref: string
  // arbitrary user-attached metadata fields on a meta — dynamic wire JSON.
  [key: string]: any
}
// A presence value bundles the meta list for one key (plus any extra wire fields).
interface PresenceEntry {
  metas: PresenceMeta[]
  // arbitrary extra fields a presence value may carry — dynamic wire JSON.
  [key: string]: any
}
// The presence map: arbitrary keys (user/device ids) → presence entries.
type PresenceMap = Record<string, PresenceEntry>
// A diff is two presence maps: who joined and who left.
interface PresenceDiff {
  joins: PresenceMap
  leaves: PresenceMap
}

/**
 * Initializes the Presence
 * @param {Channel} channel - The Channel
 * @param {Object} opts - The options,
 *        for example `{events: {state: "state", diff: "diff"}}`
 */
export default class Presence {
  state: PresenceMap
  pendingDiffs: PresenceDiff[]
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

  list<T = PresenceEntry>(by?: (key: string, presence: PresenceEntry) => T): T[]{ return Presence.list(this.state, by) }

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
  static syncState(currentState: object, newState: object, onJoin?: PresenceOnJoinCallback, onLeave?: PresenceOnLeaveCallback): PresenceMap{
    let state = this.clone(currentState) as PresenceMap
    let joins: PresenceMap = {}
    let leaves: PresenceMap = {}

    this.map(state, (key, presence) => {
      if(!(newState as PresenceMap)[key]){
        leaves[key] = presence
      }
    })
    this.map(newState, (key, newPresence) => {
      let currentPresence = state[key]
      if(currentPresence){
        let newRefs = newPresence.metas.map((m: PresenceMeta) => m.phx_ref)
        let curRefs = currentPresence.metas.map((m: PresenceMeta) => m.phx_ref)
        let joinedMetas = newPresence.metas.filter((m: PresenceMeta) => curRefs.indexOf(m.phx_ref) < 0)
        let leftMetas = currentPresence.metas.filter((m: PresenceMeta) => newRefs.indexOf(m.phx_ref) < 0)
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
  static syncDiff(state: object, diff: { joins: object; leaves: object }, onJoin?: PresenceOnJoinCallback, onLeave?: PresenceOnLeaveCallback): PresenceMap{
    let {joins, leaves} = this.clone(diff) as PresenceDiff
    if(!onJoin){ onJoin = function (){ } }
    if(!onLeave){ onLeave = function (){ } }

    this.map(joins, (key, newPresence) => {
      let currentPresence = (state as PresenceMap)[key]
      ;(state as PresenceMap)[key] = this.clone(newPresence)
      if(currentPresence){
        let joinedRefs = (state as PresenceMap)[key].metas.map((m: PresenceMeta) => m.phx_ref)
        let curMetas = currentPresence.metas.filter((m: PresenceMeta) => joinedRefs.indexOf(m.phx_ref) < 0)
        ;(state as PresenceMap)[key].metas.unshift(...curMetas)
      }
      // onJoin is guaranteed defined by the guard above.
      onJoin!(key, currentPresence, newPresence)
    })
    this.map(leaves, (key, leftPresence) => {
      let currentPresence = (state as PresenceMap)[key]
      if(!currentPresence){ return }
      let refsToRemove = leftPresence.metas.map((m: PresenceMeta) => m.phx_ref)
      currentPresence.metas = currentPresence.metas.filter((p: PresenceMeta) => {
        return refsToRemove.indexOf(p.phx_ref) < 0
      })
      // onLeave is guaranteed defined by the guard above.
      onLeave!(key, currentPresence, leftPresence)
      if(currentPresence.metas.length === 0){
        delete (state as PresenceMap)[key]
      }
    })
    return state as PresenceMap
  }

  /**
   * Returns the array of presences, with selected metadata.
   *
   * @param {Object} presences
   * @param {Function} chooser
   *
   * @returns {Presence}
   */
  static list<T = PresenceEntry>(presences: object, chooser?: (key: string, presence: PresenceEntry) => T): T[]{
    if(!chooser){ chooser = function (key, pres){ return pres as unknown as T } }

    return this.map(presences, (key, presence) => {
      // chooser is guaranteed defined by the guard above.
      return chooser!(key, presence)
    })
  }

  // private

  static map<V = PresenceEntry, R = V>(obj: object, func: (key: string, value: V) => R): R[]{
    return Object.getOwnPropertyNames(obj).map(key => func(key, (obj as Record<string, V>)[key]))
  }

  static clone<T>(obj: T): T{ return JSON.parse(JSON.stringify(obj)) }
}
