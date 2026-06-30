let R = (a) => typeof a == "function" ? a : function() {
  return a;
};
const B = typeof self < "u" ? self : null, k = typeof window < "u" ? window : null, m = B || k || globalThis, _ = "2.0.0", b = { connecting: 0, open: 1, closing: 2, closed: 3 }, P = 100, N = 1e4, x = 1e3, u = {
  closed: "closed",
  errored: "errored",
  joined: "joined",
  joining: "joining",
  leaving: "leaving"
}, T = {
  close: "phx_close",
  error: "phx_error",
  join: "phx_join",
  reply: "phx_reply",
  leave: "phx_leave"
}, w = {
  longpoll: "longpoll",
  websocket: "websocket"
}, M = {
  complete: 4
}, A = "base64url.bearer.phx.";
class E {
  channel;
  event;
  // Stored as a thunk: the constructor receives an `object` (per @types/phoenix)
  // but callers always pass a function, and `send()` invokes `this.payload()`.
  payload;
  receivedResp;
  timeout;
  // setTimeout handle (number under DOM / NodeJS.Timeout under @types/node) or null.
  timeoutTimer;
  // callback `response` is the untyped server payload — kept `any` (dynamic wire data).
  recHooks;
  sent;
  constructor(e, t, s, i) {
    this.channel = e, this.event = t, this.payload = s || function() {
      return {};
    }, this.receivedResp = null, this.timeout = i, this.timeoutTimer = null, this.recHooks = [], this.sent = !1;
  }
  /**
   *
   * @param {number} timeout
   */
  resend(e) {
    this.timeout = e, this.reset(), this.send();
  }
  /**
   *
   */
  send() {
    this.hasReceived("timeout") || (this.startTimeout(), this.sent = !0, this.channel.socket.push({
      topic: this.channel.topic,
      event: this.event,
      payload: this.payload(),
      ref: this.ref,
      join_ref: this.channel.joinRef()
    }));
  }
  /**
   *
   * @param {*} status
   * @param {*} callback
   */
  // callback is user-supplied and receives the dynamic wire response — `any` retained.
  receive(e, t) {
    return this.hasReceived(e) && t(this.receivedResp.response), this.recHooks.push({ status: e, callback: t }), this;
  }
  /**
   * @private
   */
  reset() {
    this.cancelRefEvent(), this.ref = null, this.refEvent = null, this.receivedResp = null, this.sent = !1;
  }
  /**
   * @private
   */
  matchReceive({ status: e, response: t, _ref: s }) {
    this.recHooks.filter((i) => i.status === e).forEach((i) => i.callback(t));
  }
  /**
   * @private
   */
  cancelRefEvent() {
    this.refEvent && this.channel.off(this.refEvent);
  }
  /**
   * @private
   */
  cancelTimeout() {
    clearTimeout(this.timeoutTimer), this.timeoutTimer = null;
  }
  /**
   * @private
   */
  startTimeout() {
    this.timeoutTimer && this.cancelTimeout(), this.ref = this.channel.socket.makeRef(), this.refEvent = this.channel.replyEventName(this.ref), this.channel.on(this.refEvent, (e) => {
      this.cancelRefEvent(), this.cancelTimeout(), this.receivedResp = e, this.matchReceive(e);
    }), this.timeoutTimer = setTimeout(() => {
      this.trigger("timeout", {});
    }, this.timeout);
  }
  /**
   * @private
   */
  // Type predicate (not a plain `boolean`): a true result also tells callers
  // `receivedResp` is non-null, so `receive()` can read `.response` unguarded.
  // `as boolean` is type-only — the `&&` short-circuit value is unchanged at runtime.
  hasReceived(e) {
    return this.receivedResp && this.receivedResp.status === e;
  }
  /**
   * @private
   */
  // response is the untyped server/wire payload forwarded to channel.trigger — kept `any`.
  trigger(e, t) {
    this.channel.trigger(this.refEvent, { status: e, response: t });
  }
}
class H {
  callback;
  timerCalc;
  // The timer handle holds the `setTimeout` return (NodeJS.Timeout under
  // @types/node) or null when idle/reset. `clearTimeout` rejects the null arm
  // under strict, so the two clear sites cast the handle (type-only) rather
  // than changing the runtime no-op of `clearTimeout(null)`.
  timer;
  tries;
  constructor(e, t) {
    this.callback = e, this.timerCalc = t, this.timer = null, this.tries = 0;
  }
  reset() {
    this.tries = 0, clearTimeout(this.timer);
  }
  /**
   * Cancels any previous scheduleTimeout and schedules callback
   */
  scheduleTimeout() {
    clearTimeout(this.timer), this.timer = setTimeout(() => {
      this.tries = this.tries + 1, this.callback();
    }, this.timerCalc(this.tries + 1));
  }
}
class O {
  state;
  topic;
  params;
  socket;
  // Binding callbacks are heterogeneous: each receives an event's wire payload
  // plus ref/joinRef — genuinely dynamic, so (...args: any[]) => any per @types/phoenix.
  bindings;
  bindingRef;
  timeout;
  joinedOnce;
  joinPush;
  pushBuffer;
  stateChangeRefs;
  rejoinTimer;
  constructor(e, t, s) {
    this.state = u.closed, this.topic = e, this.params = R(t || {}), this.socket = s, this.bindings = [], this.bindingRef = 0, this.timeout = this.socket.timeout, this.joinedOnce = !1, this.joinPush = new E(this, T.join, this.params, this.timeout), this.pushBuffer = [], this.stateChangeRefs = [], this.rejoinTimer = new H(() => {
      this.socket.isConnected() && this.rejoin();
    }, this.socket.rejoinAfterMs), this.stateChangeRefs.push(this.socket.onError(() => this.rejoinTimer.reset())), this.stateChangeRefs.push(
      this.socket.onOpen(() => {
        this.rejoinTimer.reset(), this.isErrored() && this.rejoin();
      })
    ), this.joinPush.receive("ok", () => {
      this.state = u.joined, this.rejoinTimer.reset(), this.pushBuffer.forEach((i) => i.send()), this.pushBuffer = [];
    }), this.joinPush.receive("error", () => {
      this.state = u.errored, this.socket.isConnected() && this.rejoinTimer.scheduleTimeout();
    }), this.onClose(() => {
      this.rejoinTimer.reset(), this.socket.hasLogger() && this.socket.log("channel", `close ${this.topic} ${this.joinRef()}`), this.state = u.closed, this.socket.remove(this);
    }), this.onError((i) => {
      this.socket.hasLogger() && this.socket.log("channel", `error ${this.topic}`, i), this.isJoining() && this.joinPush.reset(), this.state = u.errored, this.socket.isConnected() && this.rejoinTimer.scheduleTimeout();
    }), this.joinPush.receive("timeout", () => {
      this.socket.hasLogger() && this.socket.log("channel", `timeout ${this.topic} (${this.joinRef()})`, this.joinPush.timeout), new E(this, T.leave, R({}), this.timeout).send(), this.state = u.errored, this.joinPush.reset(), this.socket.isConnected() && this.rejoinTimer.scheduleTimeout();
    }), this.on(T.reply, (i, o) => {
      this.trigger(this.replyEventName(o), i);
    });
  }
  /**
   * Join the channel
   * @param {integer} timeout
   * @returns {Push}
   */
  join(e = this.timeout) {
    if (this.joinedOnce)
      throw new Error("tried to join multiple times. 'join' can only be called a single time per channel instance");
    return this.timeout = e, this.joinedOnce = !0, this.rejoin(), this.joinPush;
  }
  /**
   * Hook into channel close
   * @param {Function} callback
   */
  // payload/ref/joinRef are raw wire data passed through to the hook — dynamic.
  onClose(e) {
    this.on(T.close, e);
  }
  /**
   * Hook into channel errors
   * @param {Function} callback
   */
  // reason is an arbitrary error payload from the wire/transport — dynamic.
  onError(e) {
    return this.on(T.error, (t) => e(t));
  }
  /**
   * Subscribes on channel events
   *
   * Subscription returns a ref counter, which can be used later to
   * unsubscribe the exact event listener
   *
   * @example
   * const ref1 = channel.on("event", do_stuff)
   * const ref2 = channel.on("event", do_other_stuff)
   * channel.off("event", ref1)
   * // Since unsubscription, do_stuff won't fire,
   * // while do_other_stuff will keep firing on the "event"
   *
   * @param {string} event
   * @param {Function} callback
   * @returns {integer} ref
   */
  // callback receives an event's wire payload (+ ref/joinRef) — genuinely dynamic.
  on(e, t) {
    let s = this.bindingRef++;
    return this.bindings.push({ event: e, ref: s, callback: t }), s;
  }
  /**
   * Unsubscribes off of channel events
   *
   * Use the ref returned from a channel.on() to unsubscribe one
   * handler, or pass nothing for the ref to unsubscribe all
   * handlers for the given event.
   *
   * @example
   * // Unsubscribe the do_stuff handler
   * const ref1 = channel.on("event", do_stuff)
   * channel.off("event", ref1)
   *
   * // Unsubscribe all handlers from event
   * channel.off("event")
   *
   * @param {string} event
   * @param {integer} ref
   */
  off(e, t) {
    this.bindings = this.bindings.filter((s) => !(s.event === e && (typeof t > "u" || t === s.ref)));
  }
  /**
   * @private
   */
  canPush() {
    return this.socket.isConnected() && this.isJoined();
  }
  /**
   * Sends a message `event` to phoenix with the payload `payload`.
   * Phoenix receives this in the `handle_in(event, payload, socket)`
   * function. if phoenix replies or it times out (default 10000ms),
   * then optionally the reply can be received.
   *
   * @example
   * channel.push("event")
   *   .receive("ok", payload => console.log("phoenix replied:", payload))
   *   .receive("error", err => console.log("phoenix errored", err))
   *   .receive("timeout", () => console.log("timed out pushing"))
   * @param {string} event
   * @param {Object} payload
   * @param {number} [timeout]
   * @returns {Push}
   */
  push(e, t, s = this.timeout) {
    if (t = t || {}, !this.joinedOnce)
      throw new Error(`tried to push '${e}' to '${this.topic}' before joining. Use channel.join() before pushing events`);
    let i = new E(this, e, function() {
      return t;
    }, s);
    return this.canPush() ? i.send() : (i.startTimeout(), this.pushBuffer.push(i)), i;
  }
  /** Leaves the channel
   *
   * Unsubscribes from server events, and
   * instructs channel to terminate on server
   *
   * Triggers onClose() hooks
   *
   * To receive leave acknowledgements, use the `receive`
   * hook to bind to the server ack, ie:
   *
   * @example
   * channel.leave().receive("ok", () => alert("left!") )
   *
   * @param {integer} timeout
   * @returns {Push}
   */
  leave(e = this.timeout) {
    this.rejoinTimer.reset(), this.joinPush.cancelTimeout(), this.state = u.leaving;
    let t = () => {
      this.socket.hasLogger() && this.socket.log("channel", `leave ${this.topic}`), this.trigger(T.close, "leave");
    }, s = new E(this, T.leave, R({}), e);
    return s.receive("ok", () => t()).receive("timeout", () => t()), s.send(), this.canPush() || s.trigger("ok", {}), s;
  }
  /**
   * Overridable message hook
   *
   * Receives all events for specialized message handling
   * before dispatching to the channel callbacks.
   *
   * Must return the payload, modified or unmodified
   * @param {string} event
   * @param {Object} payload
   * @param {integer} ref
   * @returns {Object}
   */
  // Overridable hook over the raw wire message (payload/ref/joinRef) — dynamic JSON.
  onMessage(e, t, s, i) {
    return t;
  }
  /**
   * @private
   */
  // payload/joinRef come straight off the wire envelope — dynamic.
  isMember(e, t, s, i) {
    return this.topic !== e ? !1 : i && i !== this.joinRef() ? (this.socket.hasLogger() && this.socket.log("channel", "dropping outdated message", { topic: e, event: t, payload: s, joinRef: i }), !1) : !0;
  }
  /**
   * @private
   */
  joinRef() {
    return this.joinPush.ref;
  }
  /**
   * @private
   */
  rejoin(e = this.timeout) {
    this.isLeaving() || (this.socket.leaveOpenTopic(this.topic), this.state = u.joining, this.joinPush.resend(e));
  }
  /**
   * @private
   */
  // payload/ref/joinRef are raw wire data dispatched to bindings — dynamic.
  trigger(e, t, s, i) {
    let o = this.onMessage(e, t, s, i);
    if (t && !o)
      throw new Error("channel onMessage callbacks must return the payload, modified or unmodified");
    let n = this.bindings.filter((r) => r.event === e);
    for (let r = 0; r < n.length; r++)
      n[r].callback(o, s, i || this.joinRef());
  }
  /**
   * @private
   */
  replyEventName(e) {
    return `chan_reply_${e}`;
  }
  /**
   * @private
   */
  isClosed() {
    return this.state === u.closed;
  }
  /**
   * @private
   */
  isErrored() {
    return this.state === u.errored;
  }
  /**
   * @private
   */
  isJoined() {
    return this.state === u.joined;
  }
  /**
   * @private
   */
  isJoining() {
    return this.state === u.joining;
  }
  /**
   * @private
   */
  isLeaving() {
    return this.state === u.leaving;
  }
}
class j {
  // `body` is caller-dynamic (string | FormData | …) and stays `any`.
  // `global as any` probes browser globals (incl. the IE-only XDomainRequest, absent from lib.dom).
  static request(e, t, s, i, o, n, r) {
    if (m.XDomainRequest) {
      let h = new m.XDomainRequest();
      return this.xdomainRequest(h, e, t, i, o, n, r);
    } else if (m.XMLHttpRequest) {
      let h = new m.XMLHttpRequest();
      return this.xhrRequest(h, e, t, s, i, o, n, r);
    } else {
      if (m.fetch && m.AbortController)
        return this.fetchRequest(e, t, s, i, o, n, r);
      throw new Error("No suitable XMLHttpRequest implementation found");
    }
  }
  static fetchRequest(e, t, s, i, o, n, r) {
    let h = {
      method: e,
      headers: s,
      body: i
    }, l = null;
    return o && (l = new AbortController(), setTimeout(() => l.abort(), o), h.signal = l.signal), m.fetch(t, h).then((c) => c.text()).then((c) => this.parseJSON(c)).then((c) => r && r(c)).catch((c) => {
      c.name === "AbortError" && n ? n() : r && r(null);
    }), l;
  }
  // req is the IE-only XDomainRequest object — absent from lib.dom, so genuinely `any`.
  static xdomainRequest(e, t, s, i, o, n, r) {
    return e.timeout = o, e.open(t, s), e.onload = () => {
      let h = this.parseJSON(e.responseText);
      r && r(h);
    }, n && (e.ontimeout = n), e.onprogress = () => {
    }, e.send(i), e;
  }
  // body stays `any` (caller-dynamic request body forwarded to req.send).
  static xhrRequest(e, t, s, i, o, n, r, h) {
    e.open(t, s, !0), e.timeout = n;
    for (let [l, c] of Object.entries(i))
      e.setRequestHeader(l, c);
    return e.onerror = () => h && h(null), e.onreadystatechange = () => {
      if (e.readyState === M.complete && h) {
        let l = this.parseJSON(e.responseText);
        h(l);
      }
    }, r && (e.ontimeout = r), e.send(o), e;
  }
  // Returns parsed JSON of arbitrary shape (or null) — genuinely dynamic, so `any`.
  static parseJSON(e) {
    if (!e || e === "")
      return null;
    try {
      return JSON.parse(e);
    } catch {
      return console && console.log("failed to parse JSON response", e), null;
    }
  }
  // values are dynamic (string | number | nested object), so the value type is `any`.
  static serialize(e, t) {
    let s = [];
    for (var i in e) {
      if (!Object.prototype.hasOwnProperty.call(e, i))
        continue;
      let o = t ? `${t}[${i}]` : i, n = e[i];
      typeof n == "object" ? s.push(this.serialize(n, o)) : s.push(encodeURIComponent(o) + "=" + encodeURIComponent(n));
    }
    return s.join("&");
  }
  // `object` matches the caller (Socket passes `params(): object`); the cast to the
  // index-accessible shape `serialize` consumes is type-only.
  static appendParams(e, t) {
    if (Object.keys(t).length === 0)
      return e;
    let s = e.match(/\?/) ? "&" : "?";
    return `${e}${s}${this.serialize(t)}`;
  }
}
let $ = (a) => {
  let e = "", t = new Uint8Array(a), s = t.byteLength;
  for (let i = 0; i < s; i++)
    e += String.fromCharCode(t[i]);
  return btoa(e);
};
class y {
  authToken;
  endPoint;
  token;
  skipHeartbeat;
  // The only operation performed on a stored request handle is `.abort()`; the
  // concrete handle (XHR | AbortController | XDomainRequest) comes back `any`
  // from Ajax.request, so the abortable shape is the precise contract.
  reqs;
  awaitingBatchAck;
  currentBatch;
  // setTimeout handle (NodeJS.Timeout under @types/node) or null when idle;
  // cleared via clearTimeout with a non-null cast (the timer.ts pattern).
  currentBatchTimer;
  batchBuffer;
  // The four transport-event callbacks the Socket assigns to. `onopen`/`onclose`
  // carry an open/close event envelope (genuinely transport-shaped → any);
  // `onerror` is always a status code or "timeout"; `onmessage` carries {data}.
  onopen;
  onerror;
  onmessage;
  onclose;
  pollEndpoint;
  readyState;
  timeout;
  constructor(e, t) {
    t && t.length === 2 && t[1].startsWith(A) && (this.authToken = atob(t[1].slice(A.length))), this.endPoint = null, this.token = null, this.skipHeartbeat = !0, this.reqs = /* @__PURE__ */ new Set(), this.awaitingBatchAck = !1, this.currentBatch = null, this.currentBatchTimer = null, this.batchBuffer = [], this.onopen = function() {
    }, this.onerror = function() {
    }, this.onmessage = function() {
    }, this.onclose = function() {
    }, this.pollEndpoint = this.normalizeEndpoint(e), this.readyState = b.connecting, setTimeout(() => this.poll(), 0);
  }
  normalizeEndpoint(e) {
    return e.replace("ws://", "http://").replace("wss://", "https://").replace(new RegExp("(.*)/" + w.websocket), "$1/" + w.longpoll);
  }
  endpointURL() {
    return j.appendParams(this.pollEndpoint, { token: this.token });
  }
  // `wasClean` is genuinely `any`: upstream passes a boolean on most paths but a
  // status number (e.g. 500) on the server-error path into this slot.
  closeAndRetry(e, t, s) {
    this.close(e, t, s), this.readyState = b.connecting;
  }
  ontimeout() {
    this.onerror("timeout"), this.closeAndRetry(1005, "timeout", !1);
  }
  isActive() {
    return this.readyState === b.open || this.readyState === b.connecting;
  }
  poll() {
    const e = { Accept: "application/json" };
    this.authToken && (e["X-Phoenix-AuthToken"] = this.authToken), this.ajax("GET", e, null, () => this.ontimeout(), (t) => {
      if (t) {
        var { status: s, token: i, messages: o } = t;
        if (s === 410 && this.token !== null) {
          this.onerror(410), this.closeAndRetry(3410, "session_gone", !1);
          return;
        }
        this.token = i;
      } else
        s = 0;
      switch (s) {
        case 200:
          o.forEach((n) => {
            setTimeout(() => this.onmessage({ data: n }), 0);
          }), this.poll();
          break;
        case 204:
          this.poll();
          break;
        case 410:
          this.readyState = b.open, this.onopen({}), this.poll();
          break;
        case 403:
          this.onerror(403), this.close(1008, "forbidden", !1);
          break;
        case 0:
        case 500:
          this.onerror(500), this.closeAndRetry(1011, "internal server error", 500);
          break;
        default:
          throw new Error(`unhandled poll status ${s}`);
      }
    });
  }
  // we collect all pushes within the current event loop by
  // setTimeout 0, which optimizes back-to-back procedural
  // pushes against an empty buffer
  send(e) {
    typeof e != "string" && (e = $(e)), this.currentBatch ? this.currentBatch.push(e) : this.awaitingBatchAck ? this.batchBuffer.push(e) : (this.currentBatch = [e], this.currentBatchTimer = setTimeout(() => {
      this.batchSend(this.currentBatch), this.currentBatch = null;
    }, 0));
  }
  batchSend(e, t = 0) {
    this.awaitingBatchAck = !0;
    const s = t + P, i = e.slice(t, s);
    this.ajax("POST", { "Content-Type": "application/x-ndjson" }, i.join(`
`), () => this.onerror("timeout"), (o) => {
      !o || o.status !== 200 ? (this.awaitingBatchAck = !1, this.onerror(o && o.status), this.closeAndRetry(1011, "internal server error", !1)) : s < e.length ? this.batchSend(e, s) : this.batchBuffer.length > 0 ? (this.batchSend(this.batchBuffer), this.batchBuffer = []) : this.awaitingBatchAck = !1;
    });
  }
  // `wasClean` stays `any` — see closeAndRetry; it lands in CloseEventInit which
  // contractually wants a boolean, but a status number flows here on one path.
  close(e, t, s) {
    for (let o of this.reqs)
      o.abort();
    this.readyState = b.closed;
    let i = Object.assign({ code: 1e3, reason: void 0, wasClean: !0 }, { code: e, reason: t, wasClean: s });
    this.batchBuffer = [], clearTimeout(this.currentBatchTimer), this.currentBatchTimer = null, typeof CloseEvent < "u" ? this.onclose(new CloseEvent("close", i)) : this.onclose(i);
  }
  // `body` is a request body string or null; `resp` is the raw decoded wire JSON
  // ({status, token, messages}) — genuinely dynamic, so it stays `any`.
  ajax(e, t, s, i, o) {
    let n, r = () => {
      this.reqs.delete(n), i();
    };
    n = j.request(e, this.endpointURL(), t, s, this.timeout, r, (h) => {
      this.reqs.delete(n), this.isActive() && o(h);
    }), this.reqs.add(n);
  }
}
class v {
  state;
  pendingDiffs;
  channel;
  joinRef;
  caller;
  constructor(e, t = {}) {
    let s = t.events || { state: "presence_state", diff: "presence_diff" };
    this.state = {}, this.pendingDiffs = [], this.channel = e, this.joinRef = null, this.caller = {
      onJoin: function() {
      },
      onLeave: function() {
      },
      onSync: function() {
      }
    }, this.channel.on(s.state, (i) => {
      let { onJoin: o, onLeave: n, onSync: r } = this.caller;
      this.joinRef = this.channel.joinRef(), this.state = v.syncState(this.state, i, o, n), this.pendingDiffs.forEach((h) => {
        this.state = v.syncDiff(this.state, h, o, n);
      }), this.pendingDiffs = [], r();
    }), this.channel.on(s.diff, (i) => {
      let { onJoin: o, onLeave: n, onSync: r } = this.caller;
      this.inPendingSyncState() ? this.pendingDiffs.push(i) : (this.state = v.syncDiff(this.state, i, o, n), r());
    });
  }
  onJoin(e) {
    this.caller.onJoin = e;
  }
  onLeave(e) {
    this.caller.onLeave = e;
  }
  onSync(e) {
    this.caller.onSync = e;
  }
  list(e) {
    return v.list(this.state, e);
  }
  inPendingSyncState() {
    return !this.joinRef || this.joinRef !== this.channel.joinRef();
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
  static syncState(e, t, s, i) {
    let o = this.clone(e), n = {}, r = {};
    return this.map(o, (h, l) => {
      t[h] || (r[h] = l);
    }), this.map(t, (h, l) => {
      let c = o[h];
      if (c) {
        let p = l.metas.map((f) => f.phx_ref), d = c.metas.map((f) => f.phx_ref), g = l.metas.filter((f) => d.indexOf(f.phx_ref) < 0), C = c.metas.filter((f) => p.indexOf(f.phx_ref) < 0);
        g.length > 0 && (n[h] = l, n[h].metas = g), C.length > 0 && (r[h] = this.clone(c), r[h].metas = C);
      } else
        n[h] = l;
    }), this.syncDiff(o, { joins: n, leaves: r }, s, i);
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
  static syncDiff(e, t, s, i) {
    let { joins: o, leaves: n } = this.clone(t);
    return s || (s = function() {
    }), i || (i = function() {
    }), this.map(o, (r, h) => {
      let l = e[r];
      if (e[r] = this.clone(h), l) {
        let c = e[r].metas.map((d) => d.phx_ref), p = l.metas.filter((d) => c.indexOf(d.phx_ref) < 0);
        e[r].metas.unshift(...p);
      }
      s(r, l, h);
    }), this.map(n, (r, h) => {
      let l = e[r];
      if (!l)
        return;
      let c = h.metas.map((p) => p.phx_ref);
      l.metas = l.metas.filter((p) => c.indexOf(p.phx_ref) < 0), i(r, l, h), l.metas.length === 0 && delete e[r];
    }), e;
  }
  /**
   * Returns the array of presences, with selected metadata.
   *
   * @param {Object} presences
   * @param {Function} chooser
   *
   * @returns {Presence}
   */
  static list(e, t) {
    return t || (t = function(s, i) {
      return i;
    }), this.map(e, (s, i) => t(s, i));
  }
  // private
  static map(e, t) {
    return Object.getOwnPropertyNames(e).map((s) => t(s, e[s]));
  }
  static clone(e) {
    return JSON.parse(JSON.stringify(e));
  }
}
const S = {
  HEADER_LENGTH: 1,
  META_LENGTH: 4,
  KINDS: { push: 0, reply: 1, broadcast: 2 },
  encode(a, e) {
    if (a.payload.constructor === ArrayBuffer)
      return e(this.binaryEncode(a));
    {
      let t = [a.join_ref, a.ref, a.topic, a.event, a.payload];
      return e(JSON.stringify(t));
    }
  },
  // rawPayload is the raw wire frame — a JSON string or an ArrayBuffer.
  // decoded carries through to the untyped Message envelope, so stays `any`.
  decode(a, e) {
    if (a.constructor === ArrayBuffer)
      return e(this.binaryDecode(a));
    {
      let [t, s, i, o, n] = JSON.parse(a);
      return e({ join_ref: t, ref: s, topic: i, event: o, payload: n });
    }
  },
  // private
  binaryEncode(a) {
    let { join_ref: e, ref: t, event: s, topic: i, payload: o } = a, n = new TextEncoder(), r = n.encode(e), h = n.encode(t), l = n.encode(i), c = n.encode(s);
    this.assertFieldSize(r.byteLength, "join_ref"), this.assertFieldSize(h.byteLength, "ref"), this.assertFieldSize(l.byteLength, "topic"), this.assertFieldSize(c.byteLength, "event");
    let p = this.META_LENGTH + r.byteLength + h.byteLength + l.byteLength + c.byteLength, d = new ArrayBuffer(this.HEADER_LENGTH + p), g = new Uint8Array(d), C = new DataView(d), f = 0;
    C.setUint8(f++, this.KINDS.push), C.setUint8(f++, r.byteLength), C.setUint8(f++, h.byteLength), C.setUint8(f++, l.byteLength), C.setUint8(f++, c.byteLength), g.set(r, f), f += r.byteLength, g.set(h, f), f += h.byteLength, g.set(l, f), f += l.byteLength, g.set(c, f), f += c.byteLength;
    var L = new Uint8Array(d.byteLength + o.byteLength);
    return L.set(g, 0), L.set(new Uint8Array(o), d.byteLength), L.buffer;
  },
  assertFieldSize(a, e) {
    if (a > 255)
      throw new Error(`unable to convert ${e} to binary: must be less than or equal to 255 bytes, but is ${a} bytes`);
  },
  binaryDecode(a) {
    let e = new DataView(a), t = e.getUint8(0), s = new TextDecoder();
    switch (t) {
      case this.KINDS.push:
        return this.decodePush(a, e, s);
      case this.KINDS.reply:
        return this.decodeReply(a, e, s);
      case this.KINDS.broadcast:
        return this.decodeBroadcast(a, e, s);
    }
  },
  decodePush(a, e, t) {
    let s = e.getUint8(1), i = e.getUint8(2), o = e.getUint8(3), n = this.HEADER_LENGTH + this.META_LENGTH - 1, r = t.decode(a.slice(n, n + s));
    n = n + s;
    let h = t.decode(a.slice(n, n + i));
    n = n + i;
    let l = t.decode(a.slice(n, n + o));
    n = n + o;
    let c = a.slice(n, a.byteLength);
    return { join_ref: r, ref: null, topic: h, event: l, payload: c };
  },
  decodeReply(a, e, t) {
    let s = e.getUint8(1), i = e.getUint8(2), o = e.getUint8(3), n = e.getUint8(4), r = this.HEADER_LENGTH + this.META_LENGTH, h = t.decode(a.slice(r, r + s));
    r = r + s;
    let l = t.decode(a.slice(r, r + i));
    r = r + i;
    let c = t.decode(a.slice(r, r + o));
    r = r + o;
    let p = t.decode(a.slice(r, r + n));
    r = r + n;
    let d = a.slice(r, a.byteLength), g = { status: p, response: d };
    return { join_ref: h, ref: l, topic: c, event: T.reply, payload: g };
  },
  decodeBroadcast(a, e, t) {
    let s = e.getUint8(1), i = e.getUint8(2), o = this.HEADER_LENGTH + 2, n = t.decode(a.slice(o, o + s));
    o = o + s;
    let r = t.decode(a.slice(o, o + i));
    o = o + i;
    let h = a.slice(o, a.byteLength);
    return { join_ref: null, ref: null, topic: n, event: r, payload: h };
  }
};
class D {
  stateChangeCallbacks;
  channels;
  sendBuffer;
  ref;
  fallbackRef;
  timeout;
  // The transport class and the live connection are genuinely-untyped pluggable
  // surfaces (WebSocket | LongPoll | custom); `any` matches that, as @types does
  // not model the Socket's internal connection object.
  transport;
  conn;
  primaryPassedHealthCheck;
  longPollFallbackMs;
  fallbackTimer;
  sessionStore;
  establishedConnections;
  defaultEncoder;
  defaultDecoder;
  closeWasClean;
  disconnecting;
  binaryType;
  connectClock;
  pageHidden;
  encode;
  decode;
  heartbeatIntervalMs;
  rejoinAfterMs;
  reconnectAfterMs;
  logger;
  longpollerTimeout;
  params;
  endPoint;
  vsn;
  heartbeatTimeoutTimer;
  heartbeatTimer;
  pendingHeartbeatRef;
  reconnectTimer;
  authToken;
  constructor(e, t = {}) {
    this.stateChangeCallbacks = { open: [], close: [], error: [], message: [] }, this.channels = [], this.sendBuffer = [], this.ref = 0, this.fallbackRef = null, this.timeout = t.timeout || N, this.transport = t.transport || m.WebSocket || y, this.primaryPassedHealthCheck = !1, this.longPollFallbackMs = t.longPollFallbackMs, this.fallbackTimer = null, this.sessionStore = t.sessionStorage || m && m.sessionStorage, this.establishedConnections = 0, this.defaultEncoder = S.encode.bind(S), this.defaultDecoder = S.decode.bind(S), this.closeWasClean = !0, this.disconnecting = !1, this.binaryType = t.binaryType || "arraybuffer", this.connectClock = 1, this.pageHidden = !1, this.transport !== y ? (this.encode = t.encode || this.defaultEncoder, this.decode = t.decode || this.defaultDecoder) : (this.encode = this.defaultEncoder, this.decode = this.defaultDecoder);
    let s = null;
    k && k.addEventListener && (k.addEventListener("pagehide", (i) => {
      this.conn && (this.disconnect(), s = this.connectClock);
    }), k.addEventListener("pageshow", (i) => {
      s === this.connectClock && (s = null, this.connect());
    }), k.addEventListener("visibilitychange", () => {
      document.visibilityState === "hidden" ? this.pageHidden = !0 : (this.pageHidden = !1, !this.isConnected() && !this.closeWasClean && this.teardown(() => this.connect()));
    })), this.heartbeatIntervalMs = t.heartbeatIntervalMs || 3e4, this.rejoinAfterMs = (i) => t.rejoinAfterMs ? t.rejoinAfterMs(i) : [1e3, 2e3, 5e3][i - 1] || 1e4, this.reconnectAfterMs = (i) => t.reconnectAfterMs ? t.reconnectAfterMs(i) : [10, 50, 100, 150, 200, 250, 500, 1e3, 2e3][i - 1] || 5e3, this.logger = t.logger || null, !this.logger && t.debug && (this.logger = (i, o, n) => {
      console.log(`${i}: ${o}`, n);
    }), this.longpollerTimeout = t.longpollerTimeout || 2e4, this.params = R(t.params || {}), this.endPoint = `${e}/${w.websocket}`, this.vsn = t.vsn || _, this.heartbeatTimeoutTimer = null, this.heartbeatTimer = null, this.pendingHeartbeatRef = null, this.reconnectTimer = new H(() => {
      if (this.pageHidden) {
        this.log("Not reconnecting as page is hidden!"), this.teardown();
        return;
      }
      this.teardown(() => this.connect());
    }, this.reconnectAfterMs), this.authToken = t.authToken;
  }
  /**
   * Returns the LongPoll transport reference
   */
  getLongPollTransport() {
    return y;
  }
  /**
   * Disconnects and replaces the active transport
   *
   * @param {Function} newTransport - The new transport class to instantiate
   *
   */
  replaceTransport(e) {
    this.connectClock++, this.closeWasClean = !0, clearTimeout(this.fallbackTimer), this.reconnectTimer.reset(), this.conn && (this.conn.close(), this.conn = null), this.transport = e;
  }
  /**
   * Returns the socket protocol
   *
   * @returns {string}
   */
  protocol() {
    return location.protocol.match(/^https/) ? "wss" : "ws";
  }
  /**
   * The fully qualified socket url
   *
   * @returns {string}
   */
  endPointURL() {
    let e = j.appendParams(
      j.appendParams(this.endPoint, this.params()),
      { vsn: this.vsn }
    );
    return e.charAt(0) !== "/" ? e : e.charAt(1) === "/" ? `${this.protocol()}:${e}` : `${this.protocol()}://${location.host}${e}`;
  }
  /**
   * Disconnects the socket
   *
   * See https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent#Status_codes for valid status codes.
   *
   * @param {Function} callback - Optional callback which is called after socket is disconnected.
   * @param {integer} code - A status code for disconnection (Optional).
   * @param {string} reason - A textual description of the reason to disconnect. (Optional)
   */
  disconnect(e, t, s) {
    this.connectClock++, this.disconnecting = !0, this.closeWasClean = !0, clearTimeout(this.fallbackTimer), this.reconnectTimer.reset(), this.teardown(() => {
      this.disconnecting = !1, e && e();
    }, t, s);
  }
  /**
   *
   * @param {Object} params - The params to send when connecting, for example `{user_id: userToken}`
   *
   * Passing params to connect is deprecated; pass them in the Socket constructor instead:
   * `new Socket("/socket", {params: {user_id: userToken}})`.
   */
  connect(e) {
    e && (console && console.log("passing params to connect is deprecated. Instead pass :params to the Socket constructor"), this.params = R(e)), !(this.conn && !this.disconnecting) && (this.longPollFallbackMs && this.transport !== y ? this.connectWithFallback(y, this.longPollFallbackMs) : this.transportConnect());
  }
  /**
   * Logs the message. Override `this.logger` for specialized logging. noops by default
   * @param {string} kind
   * @param {string} msg
   * @param {Object} data
   */
  // `data` is heterogeneous diagnostic payload (matches SocketConnectOption.logger).
  log(e, t, s) {
    this.logger && this.logger(e, t, s);
  }
  /**
   * Returns true if a logger has been set on this socket.
   */
  hasLogger() {
    return this.logger !== null;
  }
  /**
   * Registers callbacks for connection open events
   *
   * @example socket.onOpen(function(){ console.info("the socket was opened") })
   *
   * @param {Function} callback
   */
  onOpen(e) {
    let t = this.makeRef();
    return this.stateChangeCallbacks.open.push([t, e]), t;
  }
  /**
   * Registers callbacks for connection close events
   * @param {Function} callback
   */
  onClose(e) {
    let t = this.makeRef();
    return this.stateChangeCallbacks.close.push([t, e]), t;
  }
  /**
   * Registers callbacks for connection error events
   *
   * @example socket.onError(function(error){ alert("An error occurred") })
   *
   * @param {Function} callback
   */
  onError(e) {
    let t = this.makeRef();
    return this.stateChangeCallbacks.error.push([t, e]), t;
  }
  /**
   * Registers callbacks for connection message events
   * @param {Function} callback
   */
  onMessage(e) {
    let t = this.makeRef();
    return this.stateChangeCallbacks.message.push([t, e]), t;
  }
  /**
   * Pings the server and invokes the callback with the RTT in milliseconds
   * @param {Function} callback
   *
   * Returns true if the ping was pushed or false if unable to be pushed.
   */
  ping(e) {
    if (!this.isConnected())
      return !1;
    let t = this.makeRef(), s = Date.now();
    this.push({ topic: "phoenix", event: "heartbeat", payload: {}, ref: t });
    let i = this.onMessage((o) => {
      o.ref === t && (this.off([i]), e(Date.now() - s));
    });
    return !0;
  }
  /**
   * @private
   *
   * @param {Function}
   */
  transportName(e) {
    switch (e) {
      case y:
        return "LongPoll";
      default:
        return e.name;
    }
  }
  /**
   * @private
   */
  transportConnect() {
    this.connectClock++, this.closeWasClean = !1;
    let e;
    this.authToken && (e = ["phoenix", `${A}${btoa(this.authToken).replace(/=/g, "")}`]), this.conn = new this.transport(this.endPointURL(), e), this.conn.binaryType = this.binaryType, this.conn.timeout = this.longpollerTimeout, this.conn.onopen = () => this.onConnOpen(), this.conn.onerror = (t) => this.onConnError(t), this.conn.onmessage = (t) => this.onConnMessage(t), this.conn.onclose = (t) => this.onConnClose(t);
  }
  getSession(e) {
    return this.sessionStore && this.sessionStore.getItem(e);
  }
  storeSession(e, t) {
    this.sessionStore && this.sessionStore.setItem(e, t);
  }
  connectWithFallback(e, t = 2500) {
    clearTimeout(this.fallbackTimer);
    let s = !1, i = !0, o, n, r = this.transportName(e), h = (l) => {
      this.log("transport", `falling back to ${r}...`, l), this.off([o, n]), i = !1, this.replaceTransport(e), this.transportConnect();
    };
    if (this.getSession(`phx:fallback:${r}`))
      return h("memorized");
    this.fallbackTimer = setTimeout(h, t), n = this.onError((l) => {
      this.log("transport", "error", l), i && !s && (clearTimeout(this.fallbackTimer), h(l));
    }), this.fallbackRef && this.off([this.fallbackRef]), this.fallbackRef = this.onOpen(() => {
      if (s = !0, !i) {
        let l = this.transportName(e);
        return this.primaryPassedHealthCheck || this.storeSession(`phx:fallback:${l}`, "true"), this.log("transport", `established ${l} fallback`);
      }
      clearTimeout(this.fallbackTimer), this.fallbackTimer = setTimeout(h, t), this.ping((l) => {
        this.log("transport", "connected to primary after", l), this.primaryPassedHealthCheck = !0, clearTimeout(this.fallbackTimer);
      });
    }), this.transportConnect();
  }
  clearHeartbeats() {
    clearTimeout(this.heartbeatTimer), clearTimeout(this.heartbeatTimeoutTimer);
  }
  onConnOpen() {
    this.hasLogger() && this.log("transport", `${this.transportName(this.transport)} connected to ${this.endPointURL()}`), this.closeWasClean = !1, this.disconnecting = !1, this.establishedConnections++, this.flushSendBuffer(), this.reconnectTimer.reset(), this.resetHeartbeat(), this.stateChangeCallbacks.open.forEach(([, e]) => e());
  }
  /**
   * @private
   */
  heartbeatTimeout() {
    this.pendingHeartbeatRef && (this.pendingHeartbeatRef = null, this.hasLogger() && this.log("transport", "heartbeat timeout. Attempting to re-establish connection"), this.triggerChanError(), this.closeWasClean = !1, this.teardown(() => this.reconnectTimer.scheduleTimeout(), x, "heartbeat timeout"));
  }
  resetHeartbeat() {
    this.conn && this.conn.skipHeartbeat || (this.pendingHeartbeatRef = null, this.clearHeartbeats(), this.heartbeatTimer = setTimeout(() => this.sendHeartbeat(), this.heartbeatIntervalMs));
  }
  teardown(e, t, s) {
    if (!this.conn)
      return e && e();
    const i = this.conn;
    this.waitForBufferDone(i, () => {
      t ? i.close(t, s || "") : i.close(), this.waitForSocketClosed(i, () => {
        this.conn === i && (this.conn.onopen = function() {
        }, this.conn.onerror = function() {
        }, this.conn.onmessage = function() {
        }, this.conn.onclose = function() {
        }, this.conn = null), e && e();
      });
    });
  }
  // `conn` is the live pluggable transport (WS|LongPoll|custom) — `any` matches
  // `this.conn`; @types models no internal connection object.
  waitForBufferDone(e, t, s = 1) {
    if (s === 5 || !e.bufferedAmount) {
      t();
      return;
    }
    setTimeout(() => {
      this.waitForBufferDone(e, t, s + 1);
    }, 150 * s);
  }
  // `conn` is the live pluggable transport (WS|LongPoll|custom) — see above.
  waitForSocketClosed(e, t, s = 1) {
    if (s === 5 || e.readyState === b.closed) {
      t();
      return;
    }
    setTimeout(() => {
      this.waitForSocketClosed(e, t, s + 1);
    }, 150 * s);
  }
  // `event` is a CloseEvent from WS or a plain {code,reason,wasClean} from
  // LongPoll's no-CloseEvent fallback — a cross-transport close envelope.
  onConnClose(e) {
    this.conn && (this.conn.onclose = () => {
    });
    let t = e && e.code;
    this.hasLogger() && this.log("transport", "close", e), this.triggerChanError(), this.clearHeartbeats(), !this.closeWasClean && t !== 1e3 && this.reconnectTimer.scheduleTimeout(), this.stateChangeCallbacks.close.forEach(([, s]) => s(e));
  }
  /**
   * @private
   */
  onConnError(e) {
    this.hasLogger() && this.log("transport", "error", e);
    let t = this.transport, s = this.establishedConnections;
    this.stateChangeCallbacks.error.forEach(([, i]) => {
      i(e, t, s);
    }), (t === this.transport || s > 0) && this.triggerChanError();
  }
  /**
   * @private
   */
  triggerChanError() {
    this.channels.forEach((e) => {
      e.isErrored() || e.isLeaving() || e.isClosed() || e.trigger(T.error);
    });
  }
  /**
   * @returns {string}
   */
  connectionState() {
    switch (this.conn && this.conn.readyState) {
      case b.connecting:
        return "connecting";
      case b.open:
        return "open";
      case b.closing:
        return "closing";
      default:
        return "closed";
    }
  }
  /**
   * @returns {boolean}
   */
  isConnected() {
    return this.connectionState() === "open";
  }
  /**
   * @private
   *
   * @param {Channel}
   */
  remove(e) {
    this.off(e.stateChangeRefs), this.channels = this.channels.filter((t) => t !== e);
  }
  /**
   * Removes `onOpen`, `onClose`, `onError,` and `onMessage` registrations.
   *
   * @param {refs} - list of refs returned by calls to
   *                 `onOpen`, `onClose`, `onError,` and `onMessage`
   */
  off(e) {
    for (let t in this.stateChangeCallbacks)
      this.stateChangeCallbacks[t] = this.stateChangeCallbacks[t].filter(([s]) => e.indexOf(s) === -1);
  }
  /**
   * Initiates a new channel for the given topic
   *
   * @param {string} topic
   * @param {Object} chanParams - Parameters for the channel
   * @returns {Channel}
   */
  channel(e, t = {}) {
    let s = new O(e, t, this);
    return this.channels.push(s), s;
  }
  /**
   * @param {Object} data
   */
  push(e) {
    if (this.hasLogger()) {
      let { topic: t, event: s, payload: i, ref: o, join_ref: n } = e;
      this.log("push", `${t} ${s} (${n}, ${o})`, i);
    }
    this.isConnected() ? this.encode(e, (t) => this.conn.send(t)) : this.sendBuffer.push(() => this.encode(e, (t) => this.conn.send(t)));
  }
  /**
   * Return the next message ref, accounting for overflows
   * @returns {string}
   */
  makeRef() {
    let e = this.ref + 1;
    return e === this.ref ? this.ref = 0 : this.ref = e, this.ref.toString();
  }
  sendHeartbeat() {
    this.pendingHeartbeatRef && !this.isConnected() || (this.pendingHeartbeatRef = this.makeRef(), this.push({ topic: "phoenix", event: "heartbeat", payload: {}, ref: this.pendingHeartbeatRef }), this.heartbeatTimeoutTimer = setTimeout(() => this.heartbeatTimeout(), this.heartbeatIntervalMs));
  }
  flushSendBuffer() {
    this.isConnected() && this.sendBuffer.length > 0 && (this.sendBuffer.forEach((e) => e()), this.sendBuffer = []);
  }
  // `rawMessage` is the transport message-event envelope; `.data` is the raw
  // wire frame (string | ArrayBuffer) handed to the decoder — genuinely dynamic.
  onConnMessage(e) {
    this.decode(e.data, (t) => {
      let { topic: s, event: i, payload: o, ref: n, join_ref: r } = t;
      n && n === this.pendingHeartbeatRef && (this.clearHeartbeats(), this.pendingHeartbeatRef = null, this.heartbeatTimer = setTimeout(() => this.sendHeartbeat(), this.heartbeatIntervalMs)), this.hasLogger() && this.log("receive", `${o.status || ""} ${s} ${i} ${n && "(" + n + ")" || ""}`, o);
      for (let h = 0; h < this.channels.length; h++) {
        const l = this.channels[h];
        l.isMember(s, i, o, r) && l.trigger(i, o, n, r);
      }
      for (let h = 0; h < this.stateChangeCallbacks.message.length; h++) {
        let [, l] = this.stateChangeCallbacks.message[h];
        l(t);
      }
    });
  }
  leaveOpenTopic(e) {
    let t = this.channels.find((s) => s.topic === e && (s.isJoined() || s.isJoining()));
    t && (this.hasLogger() && this.log("transport", `leaving duplicate topic "${e}"`), t.leave());
  }
}
export {
  O as Channel,
  y as LongPoll,
  v as Presence,
  S as Serializer,
  D as Socket
};
