const ze = "consecutive-reloads";
const Ge = [
  "phx-click-loading",
  "phx-change-loading",
  "phx-submit-loading",
  "phx-keydown-loading",
  "phx-keyup-loading",
  "phx-blur-loading",
  "phx-focus-loading",
  "phx-hook-loading"
], Yt = "phx-drop-target-active", Y = "data-phx-component", At = "data-phx-view", Qt = "data-phx-link", si = "track-static", we = "data-phx-link-state", yt = "data-phx-ref-loading", W = "data-phx-ref-src", x = "data-phx-ref-lock", Ae = "phx-pending-refs", Ye = "track-uploads", et = "data-phx-upload-ref", ue = "data-phx-preflighted-refs", ni = "data-phx-done-refs", Dt = "drop-target", ne = "data-phx-active-refs", Nt = "phx:live-file:updated", Qe = "data-phx-skip", re = "data-phx-id", ye = "data-phx-prune", ke = "phx-connected", lt = "phx-loading", mt = "phx-error", Ee = "phx-client-error", kt = "phx-server-error", dt = "data-phx-parent-id", fe = "data-phx-main", tt = "data-phx-root-id", oe = "viewport-top", ae = "viewport-bottom", ri = "viewport-overrun-target", oi = "trigger-action", Jt = "phx-has-focused", ai = [
  "text",
  "textarea",
  "number",
  "email",
  "password",
  "search",
  "tel",
  "url",
  "date",
  "time",
  "datetime-local",
  "color",
  "range"
], Ze = ["checkbox", "radio"], xt = "phx-has-submitted", Q = "data-phx-session", It = `[${Q}]`, le = "data-phx-sticky", ct = "data-phx-static", he = "data-phx-readonly", bt = "data-phx-disabled", Se = "disable-with", Xt = "data-phx-disable-with-restore", Et = "hook", li = "debounce", hi = "throttle", Wt = "update", Bt = "stream", St = "data-phx-stream", pe = "data-phx-portal", ut = "data-phx-teleported", at = "data-phx-teleported-src", jt = "data-phx-runtime-hook", ci = "data-phx-pid", di = "key", K = "phxPrivate", Ce = "auto-recover", _e = "no-unused-field", Ht = "phx:live-socket:debug", Zt = "phx:live-socket:profiling", te = "phx:live-socket:latency-sim", Ft = "phx:nav-history-position", ui = "progress", Te = "mounted", Pe = "__phoenix_reload_status__", fi = 1, Re = 3, pi = 200, mi = 500, gi = "phx-", vi = 3e4, Ct = "debounce-trigger", _t = "throttled", xe = "debounce-prev-key", bi = {
  debounce: 300,
  throttle: 300
}, Ie = [yt, W, x], X = "s", ee = "r", U = "c", R = "k", z = "kc", Le = "e", Oe = "r", De = "t", nt = "p", gt = "stream";
class wi {
  liveSocket;
  entry;
  offset;
  chunkSize;
  chunkTimeout;
  chunkTimer;
  errored;
  uploadChannel;
  constructor(t, e, i) {
    const { chunk_size: s, chunk_timeout: r } = e;
    this.liveSocket = i, this.entry = t, this.offset = 0, this.chunkSize = s, this.chunkTimeout = r, this.chunkTimer = null, this.errored = !1, this.uploadChannel = i.channel(`lvu:${t.ref}`, {
      token: t.metadata()
    });
  }
  error(t) {
    this.errored || (this.uploadChannel.leave(), this.errored = !0, this.chunkTimer != null && clearTimeout(this.chunkTimer), this.entry.error(t));
  }
  upload() {
    this.uploadChannel.onError((t) => this.error(t)), this.uploadChannel.join().receive("ok", (t) => this.readNextChunk()).receive(
      "error",
      ({ reason: t }) => this.error(t)
    );
  }
  isDone() {
    return this.offset >= this.entry.file.size;
  }
  readNextChunk() {
    const t = new window.FileReader(), e = this.entry.file.slice(
      this.offset,
      this.chunkSize + this.offset
    );
    t.onload = (i) => {
      if (i.target?.error === null)
        this.offset += i.target.result.byteLength, this.pushChunk(i.target.result);
      else
        return T("Read error: " + i.target?.error);
    }, t.readAsArrayBuffer(e);
  }
  pushChunk(t) {
    this.uploadChannel.isJoined() && this.uploadChannel.push("chunk", t, this.chunkTimeout).receive("ok", () => {
      this.entry.progress(this.offset / this.entry.file.size * 100), this.isDone() || (this.chunkTimer = setTimeout(
        () => this.readNextChunk(),
        this.liveSocket.getLatencySim() || 0
      ));
    }).receive(
      "error",
      ({ reason: e }) => this.error(e)
    );
  }
}
const T = (n, t) => console.error && console.error(n, t), He = (n, t) => {
  let e;
  try {
    e = new URL(n, window.location.href);
  } catch {
    throw new Error(
      `expected ${t} destination to be a valid URL, got: ${n}`
    );
  }
  if (e.origin !== window.location.origin)
    throw new Error(
      `cannot ${t} to "${n}" because its origin does not match the current origin "${window.location.origin}". Use window.location directly for cross-origin navigation.`
    );
}, ot = (n) => {
  const t = typeof n;
  return t === "number" || t === "string" && /^(0|[1-9]\d*)$/.test(n);
};
function Ai() {
  const n = /* @__PURE__ */ new Set(), t = document.querySelectorAll("*[id]");
  for (let e = 0, i = t.length; e < i; e++)
    n.has(t[e].id) ? console.error(
      `Multiple IDs detected: ${t[e].id}. Ensure unique element ids.`
    ) : n.add(t[e].id);
}
function yi(n) {
  const t = /* @__PURE__ */ new Set();
  Object.keys(n).forEach((e) => {
    const i = document.getElementById(e);
    i && i.parentElement && i.parentElement.getAttribute("phx-update") !== "stream" && t.add(
      `The stream container with id "${i.parentElement.id}" is missing the phx-update="stream" attribute. Ensure it is set for streams to work properly.`
    );
  }), t.forEach((e) => console.error(e));
}
const ki = (n, t, e, i) => {
  n.liveSocket.isDebugEnabled() && console.log(`${n.id} ${t}: ${e} - `, i);
}, Tt = (n) => typeof n == "function" ? n : function() {
  return n;
}, Vt = (n) => JSON.parse(JSON.stringify(n)), ht = (n, t, e) => {
  let i = n;
  do {
    if (i.matches(`[${t}]`) && !("disabled" in i && i.disabled))
      return i;
    i = i.parentElement;
  } while (i !== null && i.nodeType === 1 && !(e && e.isSameNode(i) || i.matches(It)));
  return null;
}, vt = (n) => n !== null && typeof n == "object" && !(n instanceof Array), Ei = (n, t) => JSON.stringify(n) === JSON.stringify(t), Fe = (n) => {
  for (const t in n)
    return !1;
  return !0;
}, wt = (n, t) => n && t(n), Si = function(n, t, e, i) {
  n.forEach((s) => {
    new wi(s, e.config, i).upload();
  });
}, Ci = (n) => {
  if (n.dataTransfer.types) {
    for (let t = 0; t < n.dataTransfer.types.length; t++)
      if (n.dataTransfer.types[t] === "Files")
        return !0;
  }
  return !1;
}, V = {
  canPushState() {
    return typeof history.pushState < "u";
  },
  dropLocal(n, t, e) {
    return n.removeItem(this.localKey(t, e));
  },
  updateLocal(n, t, e, i, s) {
    const r = this.getLocal(n, t, e), o = this.localKey(t, e), a = r === null ? i : s(r);
    return n.setItem(o, JSON.stringify(a)), a;
  },
  getLocal(n, t, e) {
    return JSON.parse(n.getItem(this.localKey(t, e)));
  },
  // state is history.state, typed `any` by the DOM lib — arbitrary serializable history metadata.
  updateCurrentState(n) {
    this.canPushState() && history.replaceState(
      n(history.state || {}),
      "",
      window.location.href
    );
  },
  pushState(n, t, e) {
    if (this.canPushState()) {
      if (e !== window.location.href) {
        if (t.type == "redirect" && t.scroll) {
          const i = history.state || {};
          i.scroll = t.scroll, history.replaceState(i, "", window.location.href);
        }
        delete t.scroll, history[n + "State"](t, "", e || null), window.requestAnimationFrame(() => {
          const i = this.getHashTargetEl(window.location.hash);
          i ? i.scrollIntoView() : t.type === "redirect" && window.scroll(0, 0);
        });
      }
    } else e && this.redirect(e);
  },
  setCookie(n, t, e) {
    const i = typeof e == "number" ? ` max-age=${e};` : "";
    document.cookie = `${n}=${t};${i} path=/`;
  },
  getCookie(n) {
    return document.cookie.replace(
      new RegExp(`(?:(?:^|.*;s*)${n}s*=s*([^;]*).*$)|^.*$`),
      "$1"
    );
  },
  deleteCookie(n) {
    document.cookie = `${n}=; max-age=-1; path=/`;
  },
  redirect(n, t = null, e = (i) => {
    window.location.href = i;
  }) {
    t && this.setCookie("__phoenix_flash__", t, 60), e(n);
  },
  localKey(n, t) {
    return `${n}-${t}`;
  },
  getHashTargetEl(n) {
    const t = n.toString().substring(1);
    if (t !== "")
      return document.getElementById(t) || document.querySelector(`a[name="${t}"]`);
  }
}, h = {
  byId(n) {
    return document.getElementById(n) || T(`no id found for ${n}`);
  },
  elementFromTarget(n) {
    return n instanceof Node ? n.nodeType === Node.ELEMENT_NODE ? n : n.parentElement : null;
  },
  removeClass(n, t) {
    n.classList.remove(t), n.classList.length === 0 && n.removeAttribute("class");
  },
  all(n, t, e) {
    if (!n)
      return [];
    const i = Array.from(n.querySelectorAll(t));
    return e && i.forEach(e), i;
  },
  childNodeLength(n) {
    const t = document.createElement("template");
    return t.innerHTML = n, t.content.childElementCount;
  },
  isUploadInput(n) {
    return n.type === "file" && n.getAttribute(et) !== null;
  },
  isAutoUpload(n) {
    return n.hasAttribute("data-phx-auto-upload");
  },
  findUploadInputs(n) {
    const t = n.id, e = this.all(
      document,
      `input[type="file"][${et}][form="${t}"]`
    );
    return this.all(n, `input[type="file"][${et}]`).concat(
      e
    );
  },
  findComponent(n, t, e = document) {
    return e.querySelector(
      `[${At}="${n}"][${Y}="${t}"]`
    );
  },
  getComponent(n, t, e = document) {
    const i = this.findComponent(n, t, e);
    if (!i)
      throw new Error(
        `no component found matching viewId ${n} and cid ${t}`
      );
    return i;
  },
  isPhxDestroyed(n) {
    return !!(n.id && h.private(n, "destroyed"));
  },
  wantsNewTab(n) {
    const t = n.ctrlKey || n.shiftKey || n.metaKey || n.button && n.button === 1, e = n.target instanceof HTMLAnchorElement && n.target.hasAttribute("download"), i = n.target.hasAttribute("target") && n.target.getAttribute("target").toLowerCase() === "_blank", s = n.target.hasAttribute("target") && !n.target.getAttribute("target").startsWith("_");
    return t || i || e || s;
  },
  isUnloadableFormSubmit(n) {
    return n.target && n.target.getAttribute("method") === "dialog" || n.submitter && n.submitter.getAttribute("formmethod") === "dialog" ? !1 : !n.defaultPrevented && !this.wantsNewTab(n);
  },
  isNewPageClick(n, t) {
    const e = n.target instanceof HTMLAnchorElement ? n.target.getAttribute("href") : null;
    let i;
    if (n.defaultPrevented || e === null || this.wantsNewTab(n) || e.startsWith("mailto:") || e.startsWith("tel:") || n.target.isContentEditable)
      return !1;
    try {
      i = new URL(e);
    } catch {
      try {
        i = new URL(e, t);
      } catch {
        return !0;
      }
    }
    return i.host === t.host && i.protocol === t.protocol && i.pathname === t.pathname && i.search === t.search ? i.hash === "" && !i.href.endsWith("#") : i.protocol.startsWith("http");
  },
  markPhxChildDestroyed(n) {
    this.isPhxChild(n) && n.setAttribute(Q, ""), this.putPrivate(n, "destroyed", !0);
  },
  findPhxChildrenInFragment(n, t) {
    const e = document.createElement("template");
    return e.innerHTML = n, this.findPhxChildren(e.content, t);
  },
  isIgnored(n, t) {
    return (n.getAttribute(t) || n.getAttribute("data-phx-update")) === "ignore";
  },
  isPhxUpdate(n, t, e) {
    return n.getAttribute && e.indexOf(n.getAttribute(t)) >= 0;
  },
  findPhxSticky(n) {
    return this.all(n, `[${le}]`);
  },
  findPhxChildren(n, t) {
    return this.all(n, `${It}[${dt}="${t}"]`);
  },
  findExistingParentCIDs(n, t) {
    const e = /* @__PURE__ */ new Set(), i = /* @__PURE__ */ new Set();
    return t.forEach((s) => {
      this.all(
        document,
        `[${At}="${n}"][${Y}="${s}"]`
      ).forEach((r) => {
        e.add(s), this.all(r, `[${At}="${n}"][${Y}]`).map((o) => parseInt(o.getAttribute(Y))).forEach((o) => i.add(o));
      });
    }), i.forEach((s) => e.delete(s)), e;
  },
  // el carries a `phxPrivate` bag of arbitrary, dynamically-keyed values
  // (cycles, hooks, timers, flags); the bag itself is genuinely untyped.
  private(n, t) {
    return n[K] && n[K][t];
  },
  deletePrivate(n, t) {
    n[K] && delete n[K][t];
  },
  // value is an arbitrary private-bag payload — intentionally dynamic
  putPrivate(n, t, e) {
    n[K] || (n[K] = {}), n[K][t] = e;
  },
  // defaultVal / the update result are arbitrary private-bag payloads
  updatePrivate(n, t, e, i) {
    const s = this.private(n, t);
    s === void 0 ? this.putPrivate(n, t, i(e)) : this.putPrivate(n, t, i(s));
  },
  syncPendingAttrs(n, t) {
    n.hasAttribute(W) && (Ge.forEach((e) => {
      n.classList.contains(e) && t.classList.add(e);
    }), Ie.filter((e) => n.hasAttribute(e)).forEach(
      (e) => {
        t.setAttribute(e, n.getAttribute(e));
      }
    ));
  },
  copyPrivates(n, t) {
    t[K] && (n[K] = t[K]);
  },
  putTitle(n) {
    const t = document.querySelector("title");
    if (t) {
      const { prefix: e, suffix: i, default: s } = t.dataset, r = typeof n != "string" || n.trim() === "";
      if (r && typeof s != "string")
        return;
      const o = r ? s : n;
      document.title = `${e || ""}${o || ""}${i || ""}`;
    } else
      document.title = n;
  },
  debounce(n, t, e, i, s, r, o, a) {
    let l = n.getAttribute(e), c = n.getAttribute(s);
    l === "" && (l = i), c === "" && (c = r);
    const f = l || c;
    switch (f) {
      case null:
        return a();
      case "blur":
        this.incCycle(n, "debounce-blur-cycle", () => {
          o() && a();
        }), this.once(n, "debounce-blur") && n.addEventListener(
          "blur",
          () => this.triggerCycle(n, "debounce-blur-cycle")
        );
        return;
      default:
        const p = parseInt(f), m = () => c ? this.deletePrivate(n, _t) : a(), g = this.incCycle(n, Ct, m);
        if (isNaN(p))
          return T(`invalid throttle/debounce value: ${f}`);
        if (c) {
          let v = !1;
          if (t.type === "keydown") {
            const w = this.private(n, xe);
            this.putPrivate(n, xe, t.key), v = w !== t.key;
          }
          if (!v && this.private(n, _t))
            return !1;
          {
            a();
            const w = setTimeout(() => {
              o() && this.triggerCycle(n, Ct);
            }, p);
            this.putPrivate(n, _t, w);
          }
        } else
          setTimeout(() => {
            o() && this.triggerCycle(n, Ct, g);
          }, p);
        const d = n.form;
        d && this.once(d, "bind-debounce") && d.addEventListener("submit", () => {
          Array.from(new FormData(d).entries(), ([v]) => {
            const w = d.elements.namedItem(v), O = w instanceof RadioNodeList ? w[0] : w;
            O && (this.incCycle(O, Ct), this.deletePrivate(O, _t));
          });
        }), this.once(n, "bind-debounce") && n.addEventListener("blur", () => {
          clearTimeout(this.private(n, _t)), o() && this.triggerCycle(n, Ct);
        });
    }
  },
  triggerCycle(n, t, e) {
    const [i, s] = this.private(n, t);
    e || (e = i), e === i && (this.incCycle(n, t), s());
  },
  once(n, t) {
    return this.private(n, t) === !0 ? !1 : (this.putPrivate(n, t, !0), !0);
  },
  incCycle(n, t, e = function() {
  }) {
    let [i] = this.private(n, t) || [0, e];
    return i++, this.putPrivate(n, t, [i, e]), i;
  },
  // maintains or adds privately used hook information
  // fromEl and toEl can be the same element in the case of a newly added node
  // fromEl and toEl can be any HTML node type, so we need to check if it's an element node
  maintainPrivateHooks(n, t, e, i) {
    n.hasAttribute && n.hasAttribute("data-phx-hook") && !t.hasAttribute("data-phx-hook") && t.setAttribute("data-phx-hook", n.getAttribute("data-phx-hook")), t.hasAttribute && (t.hasAttribute(e) || t.hasAttribute(i)) && t.setAttribute("data-phx-hook", "Phoenix.InfiniteScroll");
  },
  // hook is a user-supplied custom-element hook instance — opaque to the DOM layer
  putCustomElHook(n, t) {
    n.isConnected ? n.setAttribute("data-phx-hook", "") : console.error(`
        hook attached to non-connected DOM element
        ensure you are calling createHook within your connectedCallback. ${n.outerHTML}
      `), this.putPrivate(n, "custom-el-hook", t);
  },
  getCustomElHook(n) {
    return this.private(n, "custom-el-hook");
  },
  isUsedInput(n) {
    return n.nodeType === Node.ELEMENT_NODE && (this.private(n, Jt) || this.private(n, xt));
  },
  resetForm(n) {
    Array.from(n.elements).forEach((t) => {
      this.deletePrivate(t, Jt), this.deletePrivate(t, xt);
    });
  },
  isPhxChild(n) {
    return n.getAttribute && n.getAttribute(dt);
  },
  isPhxSticky(n) {
    return n.getAttribute && n.getAttribute(le) !== null;
  },
  isChildOfAny(n, t) {
    return !!t.find((e) => e.contains(n));
  },
  firstPhxChild(n) {
    return this.isPhxChild(n) ? n : this.all(n, `[${dt}]`)[0];
  },
  isPortalTemplate(n) {
    return n.tagName === "TEMPLATE" && n.hasAttribute(pe);
  },
  closestViewEl(n) {
    const t = n.closest(
      `[${ut}],${It}`
    );
    return t ? t.hasAttribute(ut) ? this.byId(t.getAttribute(ut)) : t.hasAttribute(Q) ? t : null : null;
  },
  dispatchEvent(n, t, e = {}) {
    let i = !0;
    n.nodeName === "INPUT" && n.type === "file" && t === "click" && (i = !1);
    const o = {
      bubbles: e.bubbles === void 0 ? i : !!e.bubbles,
      cancelable: !0,
      detail: e.detail || {}
    }, a = t === "click" ? new MouseEvent("click", o) : new CustomEvent(t, o);
    n.dispatchEvent(a);
  },
  cloneNode(n, t) {
    if (typeof t > "u")
      return n.cloneNode(!0);
    {
      const e = n.cloneNode(!1);
      return e.innerHTML = t, e;
    }
  },
  // merge attributes from source to target
  // if an element is ignored, we only merge data attributes
  // including removing data attributes that are no longer in the source
  mergeAttrs(n, t, e = {}) {
    const i = new Set(e.exclude || []), s = e.isIgnored, r = t.attributes;
    for (let a = r.length - 1; a >= 0; a--) {
      const l = r[a].name;
      if (i.has(l)) {
        if (l === "value") {
          const c = t.value ?? t.getAttribute(l);
          n.value === c && n.setAttribute("value", t.getAttribute(l));
        }
      } else {
        const c = t.getAttribute(l);
        n.getAttribute(l) !== c && (!s || s && l.startsWith("data-")) && n.setAttribute(l, c);
      }
    }
    const o = n.attributes;
    for (let a = o.length - 1; a >= 0; a--) {
      const l = o[a].name;
      s ? l.startsWith("data-") && !t.hasAttribute(l) && !Ie.includes(l) && n.removeAttribute(l) : t.hasAttribute(l) || n.removeAttribute(l);
    }
  },
  mergeFocusedInput(n, t) {
    n instanceof HTMLSelectElement || h.mergeAttrs(n, t, { exclude: ["value"] }), t.readOnly ? n.setAttribute("readonly", !0) : n.removeAttribute("readonly");
  },
  hasSelectionRange(n) {
    return n.setSelectionRange && (n.type === "text" || n.type === "textarea");
  },
  restoreFocus(n, t, e) {
    if (n instanceof HTMLSelectElement && n.focus(), !h.isTextualInput(n))
      return;
    n.matches(":focus") || n.focus(), this.hasSelectionRange(n) && n.setSelectionRange(t, e);
  },
  /**
   * Returns true if the element is an input that can be focused and edited by the user,
   * so we can skip patching it if it has focus.
   */
  isEditableInput(n) {
    return this.isFormAssociated(n) && !(n instanceof HTMLButtonElement) && !(n instanceof HTMLInputElement && n.type === "button");
  },
  isFormAssociated(n) {
    if (!(n instanceof HTMLElement)) return !1;
    if (n.localName) {
      const t = customElements.get(n.localName);
      if (t)
        return t.formAssociated === !0;
    }
    return n instanceof HTMLInputElement || n instanceof HTMLSelectElement || n instanceof HTMLTextAreaElement || n instanceof HTMLButtonElement;
  },
  syncAttrsToProps(n) {
    n instanceof HTMLInputElement && Ze.indexOf(n.type.toLocaleLowerCase()) >= 0 && (n.checked = n.getAttribute("checked") !== null);
  },
  isTextualInput(n) {
    return ai.indexOf(n.type) >= 0;
  },
  isNowTriggerFormExternal(n, t) {
    return n.getAttribute && n.getAttribute(t) !== null && document.body.contains(n);
  },
  cleanChildNodes(n, t) {
    if (h.isPhxUpdate(n, t, ["append", "prepend", Bt])) {
      const e = [];
      n.childNodes.forEach((i) => {
        (!("id" in i) || !i.id) && (!(i.nodeType === Node.TEXT_NODE && i.nodeValue && i.nodeValue.trim() === "") && i.nodeType !== Node.COMMENT_NODE && T(
          `only HTML element tags with an id are allowed inside containers with phx-update.

removing illegal node: "${("outerHTML" in i && i.outerHTML || i.nodeValue || "").trim()}"

`
        ), e.push(i));
      }), e.forEach((i) => i.remove());
    }
  },
  replaceRootContainer(n, t, e) {
    const i = /* @__PURE__ */ new Set([
      "id",
      Q,
      ct,
      fe,
      tt
    ]);
    if (n.tagName.toLowerCase() === t.toLowerCase())
      return Array.from(n.attributes).filter((s) => !i.has(s.name.toLowerCase())).forEach((s) => n.removeAttribute(s.name)), Object.keys(e).filter((s) => !i.has(s.toLowerCase())).forEach((s) => n.setAttribute(s, e[s])), n;
    {
      const s = document.createElement(t);
      return Object.keys(e).forEach(
        (r) => s.setAttribute(r, e[r])
      ), i.forEach((r) => {
        const o = n.getAttribute(r);
        o !== null && s.setAttribute(r, o);
      }), s.innerHTML = n.innerHTML, n.replaceWith(s), s;
    }
  },
  // defaultVal is either a literal fallback or a thunk producing one — dynamic
  getSticky(n, t, e) {
    const i = (h.private(n, "sticky") || []).find(
      ([s]) => t === s
    );
    if (i) {
      const [s, r, o] = i;
      return o;
    } else
      return typeof e == "function" ? e() : e;
  },
  deleteSticky(n, t) {
    this.updatePrivate(n, "sticky", [], (e) => e.filter(([i, s]) => i !== t));
  },
  // op stashes an arbitrary per-element result keyed by name; callers narrow el
  // to concrete subtypes (HTMLElement etc.), so op's param stays dynamic
  putSticky(n, t, e) {
    const i = e(n);
    this.updatePrivate(n, "sticky", [], (s) => {
      const r = s.findIndex(
        ([o]) => t === o
      );
      return r >= 0 ? s[r] = [t, e, i] : s.push([t, e, i]), s;
    });
  },
  applyStickyOperations(n) {
    const t = h.private(n, "sticky");
    t && t.forEach(([e, i, s]) => this.putSticky(n, e, i));
  },
  isLocked(n) {
    return n.hasAttribute && n.hasAttribute(x);
  },
  // ignoredAttributes is a list of attribute-name patterns; callers may type it
  // loosely (unknown[]), so keep the element type precise but the list dynamic
  attributeIgnored(n, t) {
    return t.some(
      (e) => n.name == e || e === "*" || e.includes("*") && n.name.match(e) != null
    );
  }
};
class Pt {
  ref;
  fileEl;
  file;
  view;
  // preflight metadata returned by the server (resp.entries[ref]); opaque wire
  // JSON probed for `.uploader` and forwarded as the channel token.
  meta;
  _isCancelled;
  _isDone;
  _progress;
  _lastProgressSent;
  _onDone;
  _onElUpdated;
  autoUpload;
  static isActive(t, e) {
    const i = e._phxRef === void 0, r = t.getAttribute(ne).split(",").indexOf(L.genFileRef(e)) >= 0;
    return e.size > 0 && (i || r);
  }
  static isPreflighted(t, e) {
    return t.getAttribute(ue).split(",").indexOf(L.genFileRef(e)) >= 0 && this.isActive(t, e);
  }
  static isPreflightInProgress(t) {
    return t._preflightInProgress === !0;
  }
  static markPreflightInProgress(t) {
    t._preflightInProgress = !0;
  }
  constructor(t, e, i, s) {
    this.ref = L.genFileRef(e), this.fileEl = t, this.file = e, this.view = i, this.meta = null, this._isCancelled = !1, this._isDone = !1, this._progress = 0, this._lastProgressSent = -1, this._onDone = function() {
    }, this._onElUpdated = this.onElUpdated.bind(this), this.fileEl.addEventListener(Nt, this._onElUpdated), this.autoUpload = s;
  }
  metadata() {
    return this.meta;
  }
  progress(t) {
    this._progress = Math.floor(t), this._progress > this._lastProgressSent && (this._progress >= 100 ? (this._progress = 100, this._lastProgressSent = 100, this._isDone = !0, this.view.pushFileProgress(this.fileEl, this.ref, 100, () => {
      L.untrackFile(this.fileEl, this.file), this._onDone();
    })) : (this._lastProgressSent = this._progress, this.view.pushFileProgress(this.fileEl, this.ref, this._progress)));
  }
  isCancelled() {
    return this._isCancelled;
  }
  cancel() {
    this.file._preflightInProgress = !1, this._isCancelled = !0, this._isDone = !0, this._onDone();
  }
  isDone() {
    return this._isDone;
  }
  error(t = "failed") {
    this.fileEl.removeEventListener(Nt, this._onElUpdated), this.view.pushFileProgress(this.fileEl, this.ref, { error: t }), this.isAutoUpload() || L.clearFiles(this.fileEl);
  }
  isAutoUpload() {
    return this.autoUpload;
  }
  //private
  onDone(t) {
    this._onDone = () => {
      this.fileEl.removeEventListener(Nt, this._onElUpdated), t();
    };
  }
  onElUpdated() {
    this.fileEl.getAttribute(ne).split(",").indexOf(this.ref) === -1 && (L.untrackFile(this.fileEl, this.file), this.cancel());
  }
  toPreflightPayload() {
    return {
      last_modified: this.file.lastModified,
      name: this.file.name,
      relative_path: this.file.webkitRelativePath,
      size: this.file.size,
      type: this.file.type,
      ref: this.ref,
      meta: typeof this.file.meta == "function" ? this.file.meta() : void 0
    };
  }
  // uploaders is the host application's registry of custom uploader callbacks,
  // whose shapes are app-defined; values stay `any`.
  uploader(t) {
    if (this.meta.uploader) {
      const e = t[this.meta.uploader] || T(`no uploader configured for ${this.meta.uploader}`);
      return { name: this.meta.uploader, callback: e };
    } else
      return { name: "channel", callback: Si };
  }
  // resp is the opaque preflight response; we index resp.entries by ref.
  zipPostFlight(t) {
    this.meta = t.entries[this.ref], this.meta || T(`no preflight upload response returned with ref ${this.ref}`, {
      input: this.fileEl,
      response: t
    });
  }
}
let _i = 0;
class L {
  autoUpload;
  view;
  onComplete;
  _entries;
  numEntriesInProgress;
  static genFileRef(t) {
    const e = t._phxRef;
    return e !== void 0 ? e : (t._phxRef = (_i++).toString(), t._phxRef);
  }
  static getEntryDataURL(t, e) {
    const i = this.activeFiles(t).find(
      (s) => this.genFileRef(s) === e
    );
    return i ? URL.createObjectURL(i) : null;
  }
  static hasUploadsInProgress(t) {
    let e = 0;
    return h.findUploadInputs(t).forEach((i) => {
      i.getAttribute(ue) !== i.getAttribute(ni) && e++;
    }), e > 0;
  }
  static serializeUploads(t) {
    const e = this.activeFiles(t), i = {};
    return e.forEach((s) => {
      const r = { path: t.name }, o = t.getAttribute(et);
      i[o] = i[o] || [], r.ref = this.genFileRef(s), r.last_modified = s.lastModified, r.name = s.name || r.ref, r.relative_path = s.webkitRelativePath, r.type = s.type, r.size = s.size, typeof s.meta == "function" && (r.meta = s.meta()), i[o].push(r);
    }), i;
  }
  static clearFiles(t) {
    t.value = null, t.removeAttribute(et), h.putPrivate(t, "files", []);
  }
  static untrackFile(t, e) {
    h.putPrivate(
      t,
      "files",
      h.private(t, "files").filter((i) => !Object.is(i, e))
    );
  }
  static trackFiles(t, e, i) {
    if (t.getAttribute("multiple") !== null) {
      const s = e.filter(
        (r) => !this.activeFiles(t).find(
          (o) => Object.is(o, r)
        )
      );
      h.updatePrivate(
        t,
        "files",
        [],
        (r) => r.concat(s)
      ), t.value = "";
    } else
      i && i.files.length > 0 && (t.files = i.files), h.putPrivate(t, "files", e);
  }
  static activeFileInputs(t) {
    const e = h.findUploadInputs(t);
    return Array.from(e).filter(
      (i) => i.files && this.activeFiles(i).length > 0
    );
  }
  static activeFiles(t) {
    return (h.private(t, "files") || []).filter(
      (e) => Pt.isActive(t, e)
    );
  }
  static inputsAwaitingPreflight(t) {
    const e = h.findUploadInputs(t);
    return Array.from(e).filter(
      (i) => this.filesAwaitingPreflight(i).length > 0
    );
  }
  static filesAwaitingPreflight(t) {
    return this.activeFiles(t).filter(
      (e) => !Pt.isPreflighted(t, e) && !Pt.isPreflightInProgress(e)
    );
  }
  static markPreflightInProgress(t) {
    t.forEach((e) => Pt.markPreflightInProgress(e.file));
  }
  constructor(t, e, i) {
    this.autoUpload = h.isAutoUpload(t), this.view = e, this.onComplete = i, this._entries = Array.from(
      L.filesAwaitingPreflight(t) || []
    ).map((s) => new Pt(t, s, e, this.autoUpload)), L.markPreflightInProgress(this._entries), this.numEntriesInProgress = this._entries.length;
  }
  isAutoUpload() {
    return this.autoUpload;
  }
  entries() {
    return this._entries;
  }
  initAdapterUpload(t, e, i) {
    this._entries = this._entries.map((r) => (r.isCancelled() ? (this.numEntriesInProgress--, this.numEntriesInProgress === 0 && this.onComplete()) : (r.zipPostFlight(t), r.onDone(() => {
      this.numEntriesInProgress--, this.numEntriesInProgress === 0 && this.onComplete();
    })), r));
    const s = this._entries.reduce(
      // callback is the host-supplied uploader (or channelUploader); its shape
      // is app-defined, so it stays `any`.
      (r, o) => {
        if (!o.meta)
          return r;
        const { name: a, callback: l } = o.uploader(i.uploaders);
        return r[a] = r[a] || { callback: l, entries: [] }, r[a].entries.push(o), r;
      },
      {}
    );
    for (const r in s) {
      const { callback: o, entries: a } = s[r];
      o(a, e, t, i);
    }
  }
}
const J = {
  anyOf(n, t) {
    return t.some((e) => n instanceof e);
  },
  isFocusable(n, t = !1) {
    return n instanceof HTMLAnchorElement && n.rel !== "ignore" || n instanceof HTMLAreaElement && n.href !== void 0 || !("disabled" in n && n.disabled) && this.anyOf(n, [
      HTMLInputElement,
      HTMLSelectElement,
      HTMLTextAreaElement,
      HTMLButtonElement
    ]) || n instanceof HTMLIFrameElement || n instanceof HTMLElement && n.tabIndex >= 0 && n.getAttribute("aria-hidden") !== "true" || !t && n.getAttribute("tabindex") !== null && n.getAttribute("aria-hidden") !== "true";
  },
  attemptFocus(n, t = !1) {
    if (this.isFocusable(n, t))
      try {
        n.focus();
      } catch {
      }
    return !!document.activeElement && document.activeElement.isSameNode(n);
  },
  focusFirstInteractive(n) {
    let t = n.firstElementChild;
    for (; t; ) {
      if (this.attemptFocus(t, !0) || this.focusFirstInteractive(t))
        return !0;
      t = t.nextElementSibling;
    }
    return !1;
  },
  focusFirst(n) {
    let t = n.firstElementChild;
    for (; t; ) {
      if (this.attemptFocus(t) || this.focusFirst(t))
        return !0;
      t = t.nextElementSibling;
    }
    return !1;
  },
  focusLast(n) {
    let t = n.lastElementChild;
    for (; t; ) {
      if (this.attemptFocus(t) || this.focusLast(t))
        return !0;
      t = t.previousElementSibling;
    }
    return !1;
  }
}, ti = (n) => ["HTML", "BODY"].indexOf(n.nodeName.toUpperCase()) >= 0 ? null : ["scroll", "auto"].indexOf(getComputedStyle(n).overflowY) >= 0 ? n : ti(n.parentElement), Me = (n) => n ? n.scrollTop : document.documentElement.scrollTop || document.body.scrollTop, me = (n) => n ? n.getBoundingClientRect().bottom : window.innerHeight || document.documentElement.clientHeight, ge = (n) => n ? n.getBoundingClientRect().top : 0, Ti = (n, t) => {
  const e = n.getBoundingClientRect();
  return Math.ceil(e.top) >= ge(t) && Math.floor(e.top) <= me(t);
}, Pi = (n, t) => {
  const e = n.getBoundingClientRect();
  return Math.ceil(e.bottom) >= ge(t) && Math.floor(e.bottom) <= me(t);
}, Ue = (n, t) => {
  const e = n.getBoundingClientRect();
  return Math.ceil(e.top) >= ge(t) && Math.floor(e.top) <= me(t);
}, Ri = {
  mounted() {
    this.scrollContainer = ti(this.el);
    let n = Me(this.scrollContainer), t = !1;
    const e = 500;
    let i = null;
    const s = this.throttle(
      e,
      (a, l) => {
        i = () => !0, this.liveSocket.js().push(this.el, a, {
          value: { id: l.id, _overran: !0 },
          callback: () => {
            i = null;
          }
        });
      }
    ), r = this.throttle(
      e,
      (a, l) => {
        i = () => l.scrollIntoView({ block: "start" }), this.liveSocket.js().push(this.el, a, {
          value: { id: l.id },
          callback: () => {
            i = null, window.requestAnimationFrame(() => {
              Ue(l, this.scrollContainer) || l.scrollIntoView({ block: "start" });
            });
          }
        });
      }
    ), o = this.throttle(
      e,
      (a, l) => {
        i = () => l.scrollIntoView({ block: "end" }), this.liveSocket.js().push(this.el, a, {
          value: { id: l.id },
          callback: () => {
            i = null, window.requestAnimationFrame(() => {
              Ue(l, this.scrollContainer) || l.scrollIntoView({ block: "end" });
            });
          }
        });
      }
    );
    this.onScroll = (a) => {
      const l = Me(this.scrollContainer);
      if (i)
        return n = l, i();
      const c = this.findOverrunTarget(), f = this.el.getAttribute(
        this.liveSocket.binding("viewport-top")
      ), p = this.el.getAttribute(
        this.liveSocket.binding("viewport-bottom")
      ), m = this.el.lastElementChild, g = this.el.firstElementChild, d = l < n, v = l > n;
      d && f && !t && c.top >= 0 ? (t = !0, s(f, g)) : v && t && c.top <= 0 && (t = !1), f && d && g && Ti(g, this.scrollContainer) ? r(f, g) : p && v && m && Pi(m, this.scrollContainer) && o(p, m), n = l;
    }, this.scrollContainer ? this.scrollContainer.addEventListener("scroll", this.onScroll) : window.addEventListener("scroll", this.onScroll);
  },
  updated() {
    this.scrollContainer && !this.scrollContainer.isConnected && (this.destroyed(), this.mounted());
  },
  destroyed() {
    this.scrollContainer ? this.scrollContainer.removeEventListener("scroll", this.onScroll) : window.removeEventListener("scroll", this.onScroll);
  },
  throttle(n, t) {
    let e = 0, i;
    return (...s) => {
      const r = Date.now(), o = n - (r - e);
      o <= 0 || o > n ? (i && (clearTimeout(i), i = null), e = r, t(...s)) : i || (i = setTimeout(() => {
        e = Date.now(), i = null, t(...s);
      }, o));
    };
  },
  findOverrunTarget() {
    let n;
    const t = this.el.getAttribute(
      this.liveSocket.binding(ri)
    );
    if (t) {
      const e = document.getElementById(t);
      if (e)
        n = e.getBoundingClientRect();
      else
        throw new Error("did not find element with id " + t);
    } else
      n = this.el.getBoundingClientRect();
    return n;
  }
}, xi = {
  activeRefs() {
    return this.el.getAttribute(ne);
  },
  preflightedRefs() {
    return this.el.getAttribute(ue);
  },
  mounted() {
    this.js().ignoreAttributes(this.el, ["value"]), this.preflightedWas = this.preflightedRefs();
  },
  updated() {
    const n = this.preflightedRefs();
    this.preflightedWas !== n && (this.preflightedWas = n, n === "" && this.__view().cancelSubmit(this.el.form)), this.activeRefs() === "" && (this.el.value = ""), this.el.dispatchEvent(new CustomEvent(Nt));
  }
}, Ii = {
  mounted() {
    this.ref = this.el.getAttribute("data-phx-entry-ref"), this.inputEl = document.getElementById(
      this.el.getAttribute(et)
    ), this.url = L.getEntryDataURL(this.inputEl, this.ref), this.el.src = this.url;
  },
  destroyed() {
    URL.revokeObjectURL(this.url);
  }
}, Li = {
  LiveFileUpload: xi,
  LiveImgPreview: Ii,
  FocusWrap: {
    mounted() {
      this.focusStart = this.el.firstElementChild, this.focusEnd = this.el.lastElementChild, this.focusStart.addEventListener("focus", (n) => {
        if (!n.relatedTarget || !this.el.contains(n.relatedTarget)) {
          const t = n.target.nextElementSibling;
          J.attemptFocus(t) || J.focusFirst(t);
        } else
          J.focusLast(this.el);
      }), this.focusEnd.addEventListener("focus", (n) => {
        if (!n.relatedTarget || !this.el.contains(n.relatedTarget)) {
          const t = n.target.previousElementSibling;
          J.attemptFocus(t) || J.focusLast(t);
        } else
          J.focusFirst(this.el);
      }), this.el.contains(document.activeElement) || (this.el.addEventListener("phx:show-end", () => this.el.focus()), window.getComputedStyle(this.el).display !== "none" && J.focusFirst(this.el));
    }
  },
  InfiniteScroll: Ri
};
class ce {
  static onUnlock(t, e) {
    if (!h.isLocked(t) && !t.closest(`[${x}]`))
      return e();
    const i = t.closest(`[${x}]`), s = i.closest(`[${x}]`).getAttribute(x);
    i.addEventListener(
      `phx:undo-lock:${s}`,
      () => {
        e();
      },
      { once: !0 }
    );
  }
  el;
  loadingRef;
  lockRef;
  constructor(t) {
    this.el = t, this.loadingRef = t.hasAttribute(yt) ? parseInt(t.getAttribute(yt), 10) : null, this.lockRef = t.hasAttribute(x) ? parseInt(t.getAttribute(x), 10) : null;
  }
  // public
  maybeUndo(t, e, i) {
    if (!this.isWithin(t)) {
      h.updatePrivate(this.el, Ae, [], (s) => (s.push(t), s));
      return;
    }
    this.undoLocks(t, e, i), this.undoLoading(t, e), h.updatePrivate(this.el, Ae, [], (s) => s.filter((r) => {
      let o = {
        detail: { ref: r, event: e },
        bubbles: !0,
        cancelable: !1
      };
      return this.loadingRef && this.loadingRef > r && this.el.dispatchEvent(
        new CustomEvent(`phx:undo-loading:${r}`, o)
      ), this.lockRef && this.lockRef > r && this.el.dispatchEvent(
        new CustomEvent(`phx:undo-lock:${r}`, o)
      ), r > t;
    })), this.isFullyResolvedBy(t) && this.el.removeAttribute(W);
  }
  // private
  isWithin(t) {
    return !(this.loadingRef !== null && this.loadingRef > t && this.lockRef !== null && this.lockRef > t);
  }
  // Check for cloned PHX_REF_LOCK element that has been morphed behind
  // the scenes while this element was locked in the DOM.
  // When we apply the cloned tree to the active DOM element, we must
  //
  //   1. execute pending mounted hooks for nodes now in the DOM
  //   2. undo any ref inside the cloned tree that has since been ack'd
  undoLocks(t, e, i) {
    if (!this.isLockUndoneBy(t))
      return;
    const s = h.private(this.el, x);
    s && (i(s), h.deletePrivate(this.el, x)), this.el.removeAttribute(x);
    const r = {
      detail: { ref: t, event: e },
      bubbles: !0,
      cancelable: !1
    };
    this.el.dispatchEvent(
      new CustomEvent(`phx:undo-lock:${this.lockRef}`, r)
    );
  }
  undoLoading(t, e) {
    if (!this.isLoadingUndoneBy(t)) {
      this.canUndoLoading(t) && this.el.classList.contains("phx-submit-loading") && this.el.classList.remove("phx-change-loading");
      return;
    }
    if (this.canUndoLoading(t)) {
      this.el.removeAttribute(yt);
      const i = this.el.getAttribute(bt), s = this.el.getAttribute(he);
      s !== null && "readOnly" in this.el && (this.el.readOnly = s === "true", this.el.removeAttribute(he)), i !== null && "disabled" in this.el && (this.el.disabled = i === "true", this.el.removeAttribute(bt));
      const r = this.el.getAttribute(Xt);
      r !== null && (this.el.textContent = r, this.el.removeAttribute(Xt));
      const o = {
        detail: { ref: t, event: e },
        bubbles: !0,
        cancelable: !1
      };
      this.el.dispatchEvent(
        new CustomEvent(`phx:undo-loading:${this.loadingRef}`, o)
      );
    }
    Ge.forEach((i) => {
      (i !== "phx-submit-loading" || this.canUndoLoading(t)) && h.removeClass(this.el, i);
    });
  }
  isLoadingUndoneBy(t) {
    return this.loadingRef === null ? !1 : this.loadingRef <= t;
  }
  /** @internal */
  isLockUndoneBy(t) {
    return this.lockRef === null ? !1 : this.lockRef <= t;
  }
  isFullyResolvedBy(t) {
    return (this.loadingRef === null || this.loadingRef <= t) && (this.lockRef === null || this.lockRef <= t);
  }
  // only remove the phx-submit-loading class if we are not locked
  canUndoLoading(t) {
    return this.lockRef === null || this.lockRef <= t;
  }
}
class Oi {
  containerId;
  updateType;
  elementsToModify;
  elementIdsToAdd;
  constructor(t, e, i) {
    const s = /* @__PURE__ */ new Set(), r = new Set(
      [...e.children].map((a) => a.id)
    ), o = [];
    Array.from(t.children).forEach((a) => {
      if (a.id && (s.add(a.id), r.has(a.id))) {
        const l = a.previousElementSibling && a.previousElementSibling.id;
        o.push({
          elementId: a.id,
          previousElementId: l
        });
      }
    }), this.containerId = e.id, this.updateType = i, this.elementsToModify = o, this.elementIdsToAdd = [...r].filter((a) => !s.has(a));
  }
  // We do the following to optimize append/prepend operations:
  //   1) Track ids of modified elements & of new elements
  //   2) All the modified elements are put back in the correct position in the DOM tree
  //      by storing the id of their previous sibling
  //   3) New elements are going to be put in the right place by morphdom during append.
  //      For prepend, we move them to the first position in the container
  perform() {
    const t = h.byId(this.containerId);
    t && (this.elementsToModify.forEach((e) => {
      e.previousElementId ? wt(
        document.getElementById(e.previousElementId),
        (i) => {
          wt(
            document.getElementById(e.elementId),
            (s) => {
              s.previousElementSibling && s.previousElementSibling.id == i.id || i.insertAdjacentElement("afterend", s);
            }
          );
        }
      ) : wt(document.getElementById(e.elementId), (i) => {
        i.previousElementSibling == null || t.insertAdjacentElement("afterbegin", i);
      });
    }), this.updateType == "prepend" && this.elementIdsToAdd.reverse().forEach((e) => {
      wt(
        document.getElementById(e),
        (i) => t.insertAdjacentElement("afterbegin", i)
      );
    }));
  }
}
var $e = 11;
function Di(n, t) {
  var e = t.attributes, i, s, r, o, a;
  if (!(t.nodeType === $e || n.nodeType === $e)) {
    for (var l = e.length - 1; l >= 0; l--)
      i = e[l], s = i.name, r = i.namespaceURI, o = i.value, r ? (s = i.localName || s, a = n.getAttributeNS(r, s), a !== o && (i.prefix === "xmlns" && (s = i.name), n.setAttributeNS(r, s, o))) : (a = n.getAttribute(s), a !== o && n.setAttribute(s, o));
    for (var c = n.attributes, f = c.length - 1; f >= 0; f--)
      i = c[f], s = i.name, r = i.namespaceURI, r ? (s = i.localName || s, t.hasAttributeNS(r, s) || n.removeAttributeNS(r, s)) : t.hasAttribute(s) || n.removeAttribute(s);
  }
}
var Mt, Hi = "http://www.w3.org/1999/xhtml", $ = typeof document > "u" ? void 0 : document, Fi = !!$ && "content" in $.createElement("template"), Mi = !!$ && $.createRange && "createContextualFragment" in $.createRange();
function Ui(n) {
  var t = $.createElement("template");
  return t.innerHTML = n, t.content.childNodes[0];
}
function $i(n) {
  Mt || (Mt = $.createRange(), Mt.selectNode($.body));
  var t = Mt.createContextualFragment(n);
  return t.childNodes[0];
}
function Ni(n) {
  var t = $.createElement("body");
  return t.innerHTML = n, t.childNodes[0];
}
function Bi(n) {
  return n = n.trim(), Fi ? Ui(n) : Mi ? $i(n) : Ni(n);
}
function Ut(n, t) {
  var e = n.nodeName, i = t.nodeName, s, r;
  return e === i ? !0 : (s = e.charCodeAt(0), r = i.charCodeAt(0), s <= 90 && r >= 97 ? e === i.toUpperCase() : r <= 90 && s >= 97 ? i === e.toUpperCase() : !1);
}
function ji(n, t) {
  return !t || t === Hi ? $.createElement(n) : $.createElementNS(t, n);
}
function Vi(n, t) {
  for (var e = n.firstChild; e; ) {
    var i = e.nextSibling;
    t.appendChild(e), e = i;
  }
  return t;
}
function ie(n, t, e) {
  n[e] !== t[e] && (n[e] = t[e], n[e] ? n.setAttribute(e, "") : n.removeAttribute(e));
}
var Ne = {
  OPTION: function(n, t) {
    var e = n.parentNode;
    if (e) {
      var i = e.nodeName.toUpperCase();
      i === "OPTGROUP" && (e = e.parentNode, i = e && e.nodeName.toUpperCase()), i === "SELECT" && !e.hasAttribute("multiple") && (n.hasAttribute("selected") && !t.selected && (n.setAttribute("selected", "selected"), n.removeAttribute("selected")), e.selectedIndex = -1);
    }
    ie(n, t, "selected");
  },
  /**
   * The "value" attribute is special for the <input> element since it sets
   * the initial value. Changing the "value" attribute without changing the
   * "value" property will have no effect since it is only used to the set the
   * initial value.  Similar for the "checked" attribute, and "disabled".
   */
  INPUT: function(n, t) {
    ie(n, t, "checked"), ie(n, t, "disabled"), n.value !== t.value && (n.value = t.value), t.hasAttribute("value") || n.removeAttribute("value");
  },
  TEXTAREA: function(n, t) {
    var e = t.value;
    n.value !== e && (n.value = e);
    var i = n.firstChild;
    if (i) {
      var s = i.nodeValue;
      if (s == e || !e && s == n.placeholder)
        return;
      i.nodeValue = e;
    }
  },
  SELECT: function(n, t) {
    if (!t.hasAttribute("multiple")) {
      for (var e = -1, i = 0, s = n.firstChild, r, o; s; )
        if (o = s.nodeName && s.nodeName.toUpperCase(), o === "OPTGROUP")
          r = s, s = r.firstChild, s || (s = r.nextSibling, r = null);
        else {
          if (o === "OPTION") {
            if (s.hasAttribute("selected")) {
              e = i;
              break;
            }
            i++;
          }
          s = s.nextSibling, !s && r && (s = r.nextSibling, r = null);
        }
      n.selectedIndex = e;
    }
  }
}, Rt = 1, Be = 11, je = 3, Ve = 8;
function rt() {
}
function Ji(n) {
  if (n)
    return n.getAttribute && n.getAttribute("id") || n.id;
}
function Xi(n) {
  return function(e, i, s) {
    if (s || (s = {}), typeof i == "string")
      if (e.nodeName === "#document" || e.nodeName === "HTML") {
        var r = i;
        i = $.createElement("html"), i.innerHTML = r;
      } else if (e.nodeName === "BODY") {
        var o = i;
        i = $.createElement("html"), i.innerHTML = o;
        var a = i.querySelector("body");
        a && (i = a);
      } else
        i = Bi(i);
    else i.nodeType === Be && (i = i.firstElementChild);
    var l = s.getNodeKey || Ji, c = s.onBeforeNodeAdded || rt, f = s.onNodeAdded || rt, p = s.onBeforeElUpdated || rt, m = s.onElUpdated || rt, g = s.onBeforeNodeDiscarded || rt, d = s.onNodeDiscarded || rt, v = s.onBeforeElChildrenUpdated || rt, w = s.skipFromChildren || rt, O = s.addChild || function(A, y) {
      return A.appendChild(y);
    }, M = s.childrenOnly === !0, H = /* @__PURE__ */ Object.create(null), k = [];
    function C(A) {
      k.push(A);
    }
    function P(A, y) {
      if (A.nodeType === Rt)
        for (var I = A.firstChild; I; ) {
          var S = void 0;
          y && (S = l(I)) ? C(S) : (d(I), I.firstChild && P(I, y)), I = I.nextSibling;
        }
    }
    function N(A, y, I) {
      g(A) !== !1 && (y && y.removeChild(A), d(A), P(A, I));
    }
    function u(A) {
      if (A.nodeType === Rt || A.nodeType === Be)
        for (var y = A.firstChild; y; ) {
          var I = l(y);
          I && (H[I] = y), u(y), y = y.nextSibling;
        }
    }
    u(e);
    function b(A) {
      f(A);
      for (var y = A.firstChild; y; ) {
        var I = y.nextSibling, S = l(y);
        if (S) {
          var _ = H[S];
          _ && Ut(y, _) ? (y.parentNode.replaceChild(_, y), j(_, y)) : b(y);
        } else
          b(y);
        y = I;
      }
    }
    function B(A, y, I) {
      for (; y; ) {
        var S = y.nextSibling;
        (I = l(y)) ? C(I) : N(
          y,
          A,
          !0
          /* skip keyed nodes */
        ), y = S;
      }
    }
    function j(A, y, I) {
      var S = l(y);
      if (S && delete H[S], !I) {
        var _ = p(A, y);
        if (_ === !1 || (_ instanceof HTMLElement && (A = _, u(A)), n(A, y), m(A), v(A, y) === !1))
          return;
      }
      A.nodeName !== "TEXTAREA" ? F(A, y) : Ne.TEXTAREA(A, y);
    }
    function F(A, y) {
      var I = w(A, y), S = y.firstChild, _ = A.firstChild, ft, Z, pt, Lt, it;
      t: for (; S; ) {
        for (Lt = S.nextSibling, ft = l(S); !I && _; ) {
          if (pt = _.nextSibling, S.isSameNode && S.isSameNode(_)) {
            S = Lt, _ = pt;
            continue t;
          }
          Z = l(_);
          var Ot = _.nodeType, st = void 0;
          if (Ot === S.nodeType && (Ot === Rt ? (ft ? ft !== Z && ((it = H[ft]) ? pt === it ? st = !1 : (A.insertBefore(it, _), Z ? C(Z) : N(
            _,
            A,
            !0
            /* skip keyed nodes */
          ), _ = it, Z = l(_)) : st = !1) : Z && (st = !1), st = st !== !1 && Ut(_, S), st && j(_, S)) : (Ot === je || Ot == Ve) && (st = !0, _.nodeValue !== S.nodeValue && (_.nodeValue = S.nodeValue))), st) {
            S = Lt, _ = pt;
            continue t;
          }
          Z ? C(Z) : N(
            _,
            A,
            !0
            /* skip keyed nodes */
          ), _ = pt;
        }
        if (ft && (it = H[ft]) && Ut(it, S))
          I || O(A, it), j(it, S);
        else {
          var Gt = c(S);
          Gt !== !1 && (Gt && (S = Gt), S.actualize && (S = S.actualize(A.ownerDocument || $)), O(A, S), b(S));
        }
        S = Lt, _ = pt;
      }
      B(A, _, Z);
      var be = Ne[A.nodeName];
      be && be(A, y);
    }
    var D = e, q = D.nodeType, ve = i.nodeType;
    if (!M) {
      if (q === Rt)
        ve === Rt ? Ut(e, i) || (d(e), D = Vi(e, ji(i.nodeName, i.namespaceURI))) : D = i;
      else if (q === je || q === Ve) {
        if (ve === q)
          return D.nodeValue !== i.nodeValue && (D.nodeValue = i.nodeValue), D;
        D = i;
      }
    }
    if (D === i)
      d(e);
    else {
      if (i.isSameNode && i.isSameNode(D))
        return;
      if (j(D, i, M), k)
        for (var Kt = 0, ii = k.length; Kt < ii; Kt++) {
          var zt = H[k[Kt]];
          zt && N(zt, zt.parentNode, !1);
        }
    }
    return !M && D !== e && e.parentNode && (D.actualize && (D = D.actualize(e.ownerDocument || $)), e.parentNode.replaceChild(D, e)), D;
  };
}
var de = Xi(Di);
class $t {
  view;
  liveSocket;
  container;
  rootID;
  html;
  streams;
  streamInserts;
  streamComponentRestore;
  targetCID;
  pendingRemoves;
  phxRemove;
  targetContainer;
  beforeUpdatedCallbacks;
  afterAddedCallbacks;
  afterUpdatedCallbacks;
  afterPhxChildAddedCallbacks;
  afterDiscardedCallbacks;
  afterTransitionsDiscardedCallbacks;
  withChildren;
  undoRef;
  constructor(t, e, i, s, r, o = {}) {
    this.view = t, this.liveSocket = t.liveSocket, this.container = e, this.rootID = t.root.id, this.html = i, this.streams = s, this.streamInserts = {}, this.streamComponentRestore = {}, this.targetCID = r, this.pendingRemoves = [], this.phxRemove = this.liveSocket.binding("remove"), this.targetContainer = r ? h.getComponent(this.view.id, r) : e, this.beforeUpdatedCallbacks = [], this.afterAddedCallbacks = [], this.afterUpdatedCallbacks = [], this.afterPhxChildAddedCallbacks = [], this.afterDiscardedCallbacks = [], this.afterTransitionsDiscardedCallbacks = [], this.withChildren = o.withChildren || o.undoRef !== void 0 || !1, this.undoRef = o.undoRef ?? null;
  }
  beforeUpdated(t) {
    this.beforeUpdatedCallbacks.push(t);
  }
  afterAdded(t) {
    this.afterAddedCallbacks.push(t);
  }
  afterUpdated(t) {
    this.afterUpdatedCallbacks.push(t);
  }
  afterPhxChildAdded(t) {
    this.afterPhxChildAddedCallbacks.push(t);
  }
  afterDiscarded(t) {
    this.afterDiscardedCallbacks.push(t);
  }
  afterTransitionsDiscarded(t) {
    this.afterTransitionsDiscardedCallbacks.push(t);
  }
  markPrunableContentForRemoval() {
    const t = this.liveSocket.binding(Wt);
    h.all(
      this.container,
      `[${t}=append] > *, [${t}=prepend] > *`,
      (e) => {
        e.setAttribute(ye, "");
      }
    );
  }
  perform(t) {
    const { view: e, liveSocket: i, html: s, container: r } = this;
    let o = this.targetContainer;
    if (this.targetCID) {
      const k = o.closest(`[${x}]`);
      if (k && !k.isSameNode(o)) {
        const C = h.private(k, x);
        if (C && (o = C.querySelector(
          `[data-phx-component="${this.targetCID}"]`
        ), !o))
          return;
      }
    }
    const a = i.getActiveElement(), { selectionStart: l, selectionEnd: c } = a && h.hasSelectionRange(a) ? a : {}, f = i.binding(Wt), p = i.binding(oe), m = i.binding(ae), g = i.binding(oi), d = [], v = [], w = [];
    let O = [], M = null;
    const H = (k, C, P = this.withChildren) => {
      const N = {
        // normally, we are running with childrenOnly, as the patch HTML for a LV
        // does not include the LV attrs (data-phx-session, etc.)
        // when we are patching a live component, we do want to patch the root element as well;
        // another case is the recursive patch of a stream item that was kept on reset (-> onBeforeNodeAdded)
        childrenOnly: k.getAttribute(Y) === null && !P,
        getNodeKey: (u) => !(u instanceof Element) || h.isPhxDestroyed(u) ? null : t ? u.id : h.private(u, "clientsideIdAttribute") ? u.getAttribute(re) : u.id || u.getAttribute(re),
        // skip indexing from children when container is stream
        skipFromChildren: (u) => u.getAttribute(f) === Bt,
        // tell morphdom how to add a child
        addChild: (u, b) => {
          const { ref: B, streamAt: j } = this.getStreamInsert(b);
          if (B === void 0)
            return u.appendChild(b);
          if (this.setStreamRef(b, B), j === 0)
            u.insertAdjacentElement("afterbegin", b);
          else if (j === -1) {
            const F = u.lastElementChild;
            if (F && !F.hasAttribute(St)) {
              const D = Array.from(u.children).find(
                (q) => !q.hasAttribute(St)
              );
              u.insertBefore(b, D ?? null);
            } else
              u.appendChild(b);
          } else if (j > 0) {
            const F = Array.from(u.children)[j];
            u.insertBefore(b, F);
          }
        },
        onBeforeNodeAdded: (u) => {
          if (!(u instanceof Element))
            return u;
          if (this.getStreamInsert(u)?.updateOnly && !this.streamComponentRestore[u.id])
            return !1;
          h.maintainPrivateHooks(u, u, p, m);
          let b = u;
          return this.streamComponentRestore[u.id] && (b = this.streamComponentRestore[u.id], delete this.streamComponentRestore[u.id], H(b, u, !0)), b;
        },
        onNodeAdded: (u) => {
          if (!(u instanceof Element)) {
            d.push(u);
            return;
          }
          this.maybeReOrderStream(u, !0), h.isPortalTemplate(u) && O.push(() => this.teleport(u, H)), u instanceof HTMLImageElement && u.srcset ? u.srcset = u.srcset : u instanceof HTMLVideoElement && u.autoplay && u.play(), h.isNowTriggerFormExternal(u, g) && (M = u), (h.isPhxChild(u) && e.ownsElement(u) || h.isPhxSticky(u) && e.ownsElement(u.parentNode)) && this.trackAfterPhxChildAdded(u), u.nodeName === "SCRIPT" && u.hasAttribute(jt) && this.handleRuntimeHook(u, C), d.push(u);
        },
        onNodeDiscarded: (u) => this.onNodeDiscarded(u),
        onBeforeNodeDiscarded: (u) => {
          if (!(u instanceof Element) || u.getAttribute(ye) !== null)
            return !0;
          if (u.parentElement !== null && u.id && h.isPhxUpdate(u.parentElement, f, [
            Bt,
            "append",
            "prepend"
          ]) || u.getAttribute(ut) || this.maybePendingRemove(u) || this.skipCIDSibling(u))
            return !1;
          if (h.isPortalTemplate(u)) {
            const b = document.getElementById(
              u.content.firstElementChild?.id || ""
            );
            b && (b.remove(), N.onNodeDiscarded(b), this.view.dropPortalElementId(b.id));
          }
          return !0;
        },
        onElUpdated: (u) => {
          h.isNowTriggerFormExternal(u, g) && (M = u), v.push(u), this.maybeReOrderStream(u, !1);
        },
        onBeforeElUpdated: (u, b) => {
          if (u.id && u.isSameNode(k) && u.id !== b.id)
            return N.onNodeDiscarded(u), u.replaceWith(b), N.onNodeAdded(b);
          h.syncPendingAttrs(u, b), h.maintainPrivateHooks(
            u,
            b,
            p,
            m
          ), h.cleanChildNodes(b, f);
          const B = a && u.isSameNode(a) && h.isEditableInput(u), j = B && this.isChangedSelect(u, b);
          if (this.skipCIDSibling(b))
            return this.maybeCloneLockedElement(u, B), this.copyNestedPrivateLock(u, b), this.maybeReOrderStream(u), !1;
          if (h.isPhxSticky(u))
            return [Q, ct, tt].map((F) => [
              F,
              u.getAttribute(F),
              b.getAttribute(F)
            ]).forEach(([F, D, q]) => {
              q && D !== q && u.setAttribute(F, q);
            }), !1;
          if (h.isIgnored(u, f) || u.form && u.form.isSameNode(M))
            return this.trackBeforeUpdated(u, b), h.mergeAttrs(u, b, {
              isIgnored: h.isIgnored(u, f)
            }), v.push(u), h.applyStickyOperations(u), !1;
          if (u.type === "number" && u.validity && u.validity.badInput)
            return !1;
          if (u = this.maybeCloneLockedElement(u, B), h.isPhxChild(b)) {
            const F = u.getAttribute(Q);
            return h.mergeAttrs(u, b, { exclude: [ct] }), F !== "" && u.setAttribute(Q, F), u.setAttribute(tt, this.rootID), h.applyStickyOperations(u), !1;
          }
          return this.copyNestedPrivateLock(u, b), h.copyPrivates(b, u), h.isPortalTemplate(b) ? (O.push(() => this.teleport(b, H)), u.content.replaceChildren(b.content.cloneNode(!0)), !1) : B && u.type !== "hidden" && !j ? (this.trackBeforeUpdated(u, b), h.mergeFocusedInput(u, b), h.syncAttrsToProps(u), v.push(u), h.applyStickyOperations(u), !1) : (j && u.blur(), h.isPhxUpdate(b, f, ["append", "prepend"]) && w.push(
            new Oi(
              u,
              b,
              b.getAttribute(f)
            )
          ), h.syncAttrsToProps(b), h.applyStickyOperations(b), this.trackBeforeUpdated(u, b), u);
        }
      };
      de(
        k,
        C,
        N
      );
    };
    if (this.trackBeforeUpdated(r, r), i.time("morphdom", () => {
      this.streams.forEach(([C, P, N, u]) => {
        P.forEach(
          ([b, B, j, F]) => {
            this.streamInserts[b] = {
              ref: C,
              streamAt: B,
              limit: j,
              reset: u,
              updateOnly: F
            };
          }
        ), u !== void 0 && h.all(document, `[${St}="${C}"]`, (b) => {
          this.removeStreamChildElement(b);
        }), N.forEach((b) => {
          const B = document.getElementById(b);
          B && this.removeStreamChildElement(B);
        });
      }), t && h.all(this.container, `[${f}=${Bt}]`).filter((C) => this.view.ownsElement(C)).forEach((C) => {
        Array.from(C.children).forEach((P) => {
          this.removeStreamChildElement(P, !0);
        });
      }), H(o, s);
      let k = 0;
      for (; O.length > 0 && k < 5; ) {
        const C = O.slice();
        O = [], C.forEach((P) => P()), k++;
      }
      this.view.portalElementIds.forEach((C) => {
        const P = document.getElementById(C);
        if (P) {
          const N = P.getAttribute(at);
          N && (document.getElementById(N) || (P.remove(), this.onNodeDiscarded(P), this.view.dropPortalElementId(C)));
        }
      });
    }), i.isDebugEnabled() && (Ai(), yi(this.streamInserts), Array.from(document.querySelectorAll("input[name=id]")).forEach(
      (k) => {
        k instanceof HTMLInputElement && k.form && console.error(
          `Detected an input with name="id" inside a form! This will cause problems when patching the DOM.
`,
          k
        );
      }
    )), w.length > 0 && i.time("post-morph append/prepend restoration", () => {
      w.forEach((k) => k.perform());
    }), i.silenceEvents(
      () => h.restoreFocus(
        a,
        l,
        c
      )
    ), h.dispatchEvent(document, "phx:update"), d.forEach((k) => this.trackAfterAdded(k)), v.forEach((k) => this.trackAfterUpdated(k)), this.transitionPendingRemoves(), M) {
      i.unload();
      const k = h.private(M, "submitter");
      if (k && k.name && o.contains(k)) {
        const C = document.createElement("input");
        C.type = "hidden";
        const P = k.getAttribute("form");
        P && C.setAttribute("form", P), C.name = k.name, C.value = k.value, k.parentElement.insertBefore(C, k);
      }
      Object.getPrototypeOf(M).submit.call(
        M
      );
    }
    return !0;
  }
  trackBeforeUpdated(t, e) {
    this.beforeUpdatedCallbacks.forEach((i) => i(t, e));
  }
  trackAfterAdded(t) {
    this.afterAddedCallbacks.forEach((e) => e(t));
  }
  trackAfterUpdated(t) {
    this.afterUpdatedCallbacks.forEach((e) => e(t));
  }
  trackAfterPhxChildAdded(t) {
    this.afterPhxChildAddedCallbacks.forEach((e) => e(t));
  }
  trackAfterDiscarded(t) {
    this.afterDiscardedCallbacks.forEach((e) => e(t));
  }
  trackAfterTransitionsDiscarded(t) {
    this.afterTransitionsDiscardedCallbacks.forEach((e) => e(t));
  }
  onNodeDiscarded(t) {
    (h.isPhxChild(t) || h.isPhxSticky(t)) && this.liveSocket.destroyViewByEl(t), this.trackAfterDiscarded(t);
  }
  maybePendingRemove(t) {
    return t.getAttribute && t.getAttribute(this.phxRemove) !== null ? (this.pendingRemoves.push(t), !0) : !1;
  }
  removeStreamChildElement(t, e = !1) {
    !e && !this.view.ownsElement(t) || (this.streamInserts[t.id] ? (this.streamComponentRestore[t.id] = t, t.remove()) : this.maybePendingRemove(t) || (t.remove(), this.onNodeDiscarded(t)));
  }
  getStreamInsert(t) {
    return (t.id ? this.streamInserts[t.id] : {}) || {};
  }
  setStreamRef(t, e) {
    h.putSticky(
      t,
      St,
      (i) => (
        // ref is always defined at the call sites (they guard on streamAt/ref);
        // the cast is erased at runtime.
        i.setAttribute(St, e)
      )
    );
  }
  maybeReOrderStream(t, e = !1) {
    const { ref: i, streamAt: s, reset: r } = this.getStreamInsert(t);
    if (s !== void 0 && (this.setStreamRef(t, i), !(!r && !e) && t.parentElement)) {
      if (s === 0)
        this.moveOrInsertBefore(
          t.parentElement,
          t,
          t.parentElement.firstElementChild
        );
      else if (s > 0) {
        const o = Array.from(t.parentElement.children), a = o.indexOf(t);
        if (s >= o.length - 1)
          this.moveOrInsertBefore(t.parentElement, t, null);
        else {
          const l = o[s];
          a > s ? this.moveOrInsertBefore(t.parentElement, t, l) : this.moveOrInsertBefore(
            t.parentElement,
            t,
            l.nextElementSibling
          );
        }
      }
      this.maybeLimitStream(t);
    }
  }
  // Reorder a child within its parent. When supported, use the atomic
  // moveBefore (https://developer.mozilla.org/en-US/docs/Web/API/Node/moveBefore)
  // so connected custom elements (and other state-bearing nodes like iframes)
  // are not disconnected and reconnected by the move. Falls back to
  // insertBefore otherwise. Passing `ref === null` moves to the end.
  // See also https://github.com/phoenixframework/phoenix_live_view/issues/4212.
  moveOrInsertBefore(t, e, i) {
    if (typeof t.moveBefore == "function")
      try {
        t.moveBefore(e, i);
        return;
      } catch {
      }
    t.insertBefore(e, i);
  }
  maybeLimitStream(t) {
    const { limit: e } = this.getStreamInsert(t);
    if (e !== null) {
      const i = Array.from(t.parentElement.children);
      e < 0 && i.length > e * -1 ? i.slice(0, i.length + e).forEach((s) => this.removeStreamChildElement(s)) : e >= 0 && i.length > e && i.slice(e).forEach((s) => this.removeStreamChildElement(s));
    }
  }
  transitionPendingRemoves() {
    const { pendingRemoves: t, liveSocket: e } = this;
    t.length > 0 && e.transitionRemoves(t, this.view, () => {
      t.forEach((i) => {
        const s = h.firstPhxChild(i);
        s && e.destroyViewByEl(s), i.remove();
      }), this.trackAfterTransitionsDiscarded(t);
    });
  }
  isChangedSelect(t, e) {
    return !(t instanceof HTMLSelectElement) || t.multiple ? !1 : t.options.length !== e.options.length ? !0 : (e.value = t.value, !t.isEqualNode(e));
  }
  skipCIDSibling(t) {
    return t.nodeType === Node.ELEMENT_NODE && t.hasAttribute(Qe);
  }
  maybeCloneLockedElement(t, e) {
    if (!t.hasAttribute(W)) return t;
    const i = new ce(t);
    if (!t.hasAttribute(x) || this.undoRef !== null && i.isLockUndoneBy(this.undoRef))
      return t;
    h.applyStickyOperations(t);
    const s = t.hasAttribute(x) ? h.private(t, x) || t.cloneNode(!0) : null;
    return s ? (h.putPrivate(t, x, s), e ? t : s) : t;
  }
  copyNestedPrivateLock(t, e) {
    this.undoRef === null || !h.private(e, x) || h.putPrivate(t, x, h.private(e, x));
  }
  indexOf(t, e) {
    return Array.from(t.children).indexOf(e);
  }
  teleport(t, e) {
    const i = t.getAttribute(pe), s = document.querySelector(i);
    if (!s)
      throw new Error(
        "portal target with selector " + i + " not found"
      );
    const r = t.content.firstElementChild;
    if (this.skipCIDSibling(r))
      return;
    if (!r?.id)
      throw new Error(
        "phx-portal template must have a single root element with ID!"
      );
    const o = document.getElementById(r.id);
    let a;
    o ? (s.contains(o) || s.appendChild(o), a = o) : (a = document.createElement(r.tagName), s.appendChild(a)), r.setAttribute(ut, this.view.id), r.setAttribute(at, t.id), e(a, r, !0), r.removeAttribute(ut), r.removeAttribute(at), this.view.pushPortalElementId(r.id);
  }
  handleRuntimeHook(t, e) {
    const i = t.getAttribute(jt);
    let s = t.hasAttribute("nonce") ? t.getAttribute("nonce") : null;
    if (t.hasAttribute("nonce")) {
      const o = document.createElement("template");
      o.innerHTML = e, s = o.content.querySelector(`script[${jt}="${CSS.escape(i)}"]`)?.getAttribute("nonce") ?? null;
    }
    const r = document.createElement("script");
    r.textContent = t.textContent, h.mergeAttrs(r, t, { isIgnored: !1 }), s && (r.nonce = s), t.replaceWith(r), t = r;
  }
}
const Wi = /* @__PURE__ */ new Set([
  "area",
  "base",
  "br",
  "col",
  "command",
  "embed",
  "hr",
  "img",
  "input",
  "keygen",
  "link",
  "meta",
  "param",
  "source",
  "track",
  "wbr"
]), qi = /* @__PURE__ */ new Set(["'", '"']), Je = (n, t, e) => {
  let i = 0, s = !1, r, o, a, l, c, f;
  const p = n.match(/^(\s*(?:<!--.*?-->\s*)*)<([^\s\/>]+)/);
  if (p === null)
    throw new Error(`malformed html ${n}`);
  for (i = p[0].length, r = p[1], a = p[2], l = i, i; i < n.length && n.charAt(i) !== ">"; i++)
    if (n.charAt(i) === "=") {
      const d = n.slice(i - 3, i) === " id";
      i++;
      const v = n.charAt(i);
      if (qi.has(v)) {
        const w = i;
        for (i++, i; i < n.length && n.charAt(i) !== v; i++)
          ;
        if (d) {
          c = n.slice(w + 1, i);
          break;
        }
      }
    }
  let m = n.length - 1;
  for (s = !1; m >= r.length + a.length; ) {
    const d = n.charAt(m);
    if (s)
      d === "-" && n.slice(m - 3, m) === "<!-" ? (s = !1, m -= 4) : m -= 1;
    else if (d === ">" && n.slice(m - 2, m) === "--")
      s = !0, m -= 3;
    else {
      if (d === ">")
        break;
      m -= 1;
    }
  }
  o = n.slice(m + 1, n.length);
  const g = Object.keys(t).map((d) => t[d] === !0 ? d : `${d}="${t[d]}"`).join(" ");
  if (e) {
    const d = c ? ` id="${c}"` : "";
    Wi.has(a) ? f = `<${a}${d}${g === "" ? "" : " "}${g}/>` : f = `<${a}${d}${g === "" ? "" : " "}${g}></${a}>`;
  } else {
    const d = n.slice(l, m + 1);
    f = `<${a}${g === "" ? "" : " "}${g}${d}`;
  }
  return [f, r, o];
};
class Xe {
  viewId;
  // the rendered tree is raw, recursive wire JSON keyed by numeric-string
  // indices plus internal markers (STATIC/COMPONENTS/KEYED/…); genuinely dynamic
  rendered;
  magicId;
  // diff is the raw wire diff payload (same dynamic shape as `rendered`)
  static extract(t) {
    const { [Oe]: e, [Le]: i, [De]: s } = t;
    return delete t[Oe], delete t[Le], delete t[De], { diff: t, title: s, reply: e || null, events: i || [] };
  }
  constructor(t, e) {
    this.viewId = t, this.rendered = {}, this.magicId = 0, this.mergeDiff(e);
  }
  parentViewId() {
    return this.viewId;
  }
  toString(t) {
    const { buffer: e, streams: i } = this.recursiveToString(
      this.rendered,
      this.rendered[U],
      t,
      !0,
      {}
    );
    return { buffer: e, streams: i };
  }
  recursiveToString(t, e = t[U], i, s, r) {
    i = i ? new Set(i) : null;
    const o = {
      buffer: "",
      components: e,
      onlyCids: i,
      streams: /* @__PURE__ */ new Set()
    };
    return this.toOutputBuffer(t, null, o, s, r), { buffer: o.buffer, streams: o.streams };
  }
  componentCIDs(t) {
    return Object.keys(t[U] || {}).map((e) => parseInt(e));
  }
  isComponentOnlyDiff(t) {
    return t[U] ? Object.keys(t).length === 1 : !1;
  }
  getComponent(t, e) {
    return t[U][e];
  }
  resetRender(t) {
    this.rendered[U][t] && (this.rendered[U][t].reset = !0);
  }
  mergeDiff(t) {
    const e = t[U], i = {};
    if (delete t[U], this.rendered = this.mutableMerge(this.rendered, t), this.rendered[U] = this.rendered[U] || {}, e) {
      const s = this.rendered[U];
      for (const r in e)
        e[r] = this.cachedFindComponent(r, e[r], s, e, i);
      for (const r in e)
        s[r] = e[r];
      t[U] = e;
    }
  }
  cachedFindComponent(t, e, i, s, r) {
    if (r[t])
      return r[t];
    {
      let o, a, l = e[X];
      if (ot(l)) {
        let c;
        l > 0 ? c = this.cachedFindComponent(l, s[l], i, s, r) : c = i[-l], a = c[X], o = this.cloneMerge(c, e, !0), o[X] = a;
      } else
        o = e[X] !== void 0 || i[t] === void 0 ? e : this.cloneMerge(i[t], e, !1);
      return r[t] = o, o;
    }
  }
  mutableMerge(t, e) {
    return e[X] !== void 0 ? e : (this.doMutableMerge(t, e), t);
  }
  doMutableMerge(t, e) {
    if (e[R])
      this.mergeKeyed(t, e);
    else
      for (const i in e) {
        const s = e[i], r = t[i];
        vt(s) && s[X] === void 0 && vt(r) ? this.doMutableMerge(r, s) : t[i] = s;
      }
    t[ee] && (t.newRender = !0);
  }
  clone(t) {
    return "structuredClone" in window ? structuredClone(t) : JSON.parse(JSON.stringify(t));
  }
  // keyed comprehensions
  mergeKeyed(t, e) {
    const i = this.clone(t);
    if (Object.entries(e[R]).forEach(([s, r]) => {
      if (s !== z)
        if (Array.isArray(r)) {
          const [o, a] = r;
          t[R][s] = i[R][o], this.doMutableMerge(t[R][s], a);
        } else if (typeof r == "number") {
          const o = r;
          t[R][s] = i[R][o];
        } else typeof r == "object" && (t[R][s] || (t[R][s] = {}), this.doMutableMerge(t[R][s], r));
    }), e[R][z] < t[R][z])
      for (let s = e[R][z]; s < t[R][z]; s++)
        delete t[R][s];
    t[R][z] = e[R][z], e[gt] && (t[gt] = e[gt]), e[nt] && (t[nt] = e[nt]);
  }
  // Merges cid trees together, copying statics from source tree.
  //
  // The `pruneMagicId` is passed to control pruning the magicId of the
  // target. We must always prune the magicId when we are sharing statics
  // from another component. If not pruning, we replicate the logic from
  // mutableMerge, where we set newRender to true if there is a root
  // (effectively forcing the new version to be rendered instead of skipped)
  //
  cloneMerge(t, e, i) {
    let s;
    if (e[R])
      s = this.clone(t), this.mergeKeyed(s, e);
    else {
      s = { ...t, ...e };
      for (const r in s) {
        const o = e[r], a = t[r];
        vt(o) && o[X] === void 0 && vt(a) ? s[r] = this.cloneMerge(a, o, i) : o === void 0 && vt(a) && (s[r] = this.cloneMerge(a, {}, i));
      }
    }
    return i ? (delete s.magicId, delete s.newRender) : t[ee] && (s.newRender = !0), s;
  }
  componentToString(t) {
    const { buffer: e, streams: i } = this.recursiveCIDToString(
      this.rendered[U],
      t,
      null
    ), [s] = Je(e, {});
    return { buffer: s, streams: i };
  }
  pruneCIDs(t) {
    t.forEach((e) => delete this.rendered[U][e]);
  }
  // private
  get() {
    return this.rendered;
  }
  isNewFingerprint(t = {}) {
    return !!t[X];
  }
  templateStatic(t, e) {
    return typeof t == "number" ? e[t] : t;
  }
  nextMagicID() {
    return this.magicId++, `m${this.magicId}-${this.parentViewId()}`;
  }
  // Converts rendered tree to output buffer.
  //
  // changeTracking controls if we can apply the PHX_SKIP optimization.
  toOutputBuffer(t, e, i, s, r = {}) {
    if (t[R])
      return this.comprehensionToBuffer(
        t,
        e,
        i,
        s
      );
    t[nt] && (e = t[nt], delete t[nt]);
    let { [X]: o } = t;
    o = this.templateStatic(o, e), t[X] = o;
    const a = t[ee], l = i.buffer;
    a && (i.buffer = ""), s && a && !t.magicId && (t.newRender = !0, t.magicId = this.nextMagicID()), i.buffer += o[0];
    for (let c = 1; c < o.length; c++)
      this.dynamicToBuffer(t[c - 1], e, i, s), i.buffer += o[c];
    if (a) {
      let c = !1, f;
      s || t.magicId ? (c = s && !t.newRender, f = { [re]: t.magicId, ...r }) : f = r, c && (f[Qe] = !0);
      const [p, m, g] = Je(
        i.buffer,
        f,
        c
      );
      t.newRender = !1, i.buffer = l + m + p + g;
    }
  }
  comprehensionToBuffer(t, e, i, s) {
    const r = e || t[nt], o = this.templateStatic(t[X], e);
    t[X] = o, delete t[nt];
    for (let a = 0; a < t[R][z]; a++) {
      i.buffer += o[0];
      for (let l = 1; l < o.length; l++)
        this.dynamicToBuffer(
          t[R][a][l - 1],
          r,
          i,
          s
        ), i.buffer += o[l];
    }
    if (t[gt]) {
      const a = t[gt], [l, c, f, p] = a || [null, {}, [], null];
      a !== void 0 && (t[R][z] > 0 || f.length > 0 || p) && (delete t[gt], t[R] = {
        [z]: 0
      }, i.streams.add(a));
    }
  }
  dynamicToBuffer(t, e, i, s) {
    if (typeof t == "number") {
      const { buffer: r, streams: o } = this.recursiveCIDToString(
        i.components,
        t,
        i.onlyCids
      );
      i.buffer += r, i.streams = /* @__PURE__ */ new Set([...i.streams, ...o]);
    } else vt(t) ? this.toOutputBuffer(t, e, i, s, {}) : i.buffer += t;
  }
  recursiveCIDToString(t, e, i) {
    const s = t[e] || T(`no component for CID ${e}`, t), r = { [Y]: e, [At]: this.viewId }, o = i && !i.has(e);
    s.newRender = !o, s.magicId = `c${e}-${this.parentViewId()}`;
    const a = !s.reset, { buffer: l, streams: c } = this.recursiveToString(
      s,
      t,
      i,
      a,
      r
    );
    return delete s.reset, { buffer: l, streams: c };
  }
}
const We = [], qe = 200, E = {
  // private
  exec(n, t, e, i, s, r) {
    const [o, a] = r || [
      null,
      { callback: r && r.callback }
    ];
    (Array.isArray(e) ? e : typeof e == "string" && e.startsWith("[") ? JSON.parse(e) : [[o, a]]).forEach(([c, f]) => {
      c === o && (f = { ...a, ...f }, f.callback = f.callback || a.callback), this.filterToEls(i.liveSocket, s, f).forEach(
        (p) => {
          this[`exec_${c}`](
            n,
            t,
            e,
            i,
            s,
            p,
            f
          );
        }
      );
    });
  },
  isVisible(n) {
    return !!(n.offsetWidth || n.offsetHeight || n.getClientRects().length > 0);
  },
  // returns true if any part of the element is inside the viewport
  isInViewport(n) {
    const t = n.getBoundingClientRect(), e = window.innerHeight || document.documentElement.clientHeight, i = window.innerWidth || document.documentElement.clientWidth;
    return t.right > 0 && t.bottom > 0 && t.left < i && t.top < e;
  },
  // private
  // commands
  exec_exec(n, t, e, i, s, r, { attr: o, to: a }) {
    const l = r.getAttribute(o);
    if (!l)
      throw new Error(`expected ${o} to contain JS command on "${a}"`);
    i.liveSocket.execJS(r, l, t);
  },
  exec_dispatch(n, t, e, i, s, r, { event: o, detail: a, bubbles: l, blocking: c }) {
    if (a = a || {}, a.dispatcher = s, c) {
      const f = new Promise((p, m) => {
        a.done = p;
      });
      i.liveSocket.asyncTransition(f);
    }
    h.dispatchEvent(r, o, { detail: a, bubbles: l });
  },
  exec_push(n, t, e, i, s, r, o) {
    const {
      event: a,
      data: l,
      target: c,
      page_loading: f,
      loading: p,
      value: m,
      dispatcher: g,
      callback: d
    } = o, v = {
      loading: p,
      value: m,
      target: c,
      page_loading: !!f,
      originalEvent: n
    }, w = t === "change" && g ? g : s, O = c || w.getAttribute(i.binding("target")) || w, M = (H, k) => {
      if (H.isConnected())
        if (t === "change") {
          let { newCid: C, _target: P } = o;
          P = P || (h.isFormAssociated(s) ? s.name : void 0), P && (v._target = P), H.pushInput(
            s,
            k,
            C,
            a || e,
            v,
            d
          );
        } else if (t === "submit") {
          const { submitter: C } = o;
          H.submitForm(
            s,
            k,
            a || e,
            C,
            v,
            d
          );
        } else
          H.pushEvent(
            t,
            s,
            k,
            a || e,
            l,
            v,
            d
          );
    };
    o.targetView && o.targetCtx ? M(o.targetView, o.targetCtx) : i.withinTargets(O, M);
  },
  exec_navigate(n, t, e, i, s, r, { href: o, replace: a }) {
    i.liveSocket.historyRedirect(
      n,
      o,
      a ? "replace" : "push",
      null,
      s
    );
  },
  exec_patch(n, t, e, i, s, r, { href: o, replace: a }) {
    i.liveSocket.pushHistoryPatch(
      n,
      o,
      a ? "replace" : "push",
      s
    );
  },
  exec_focus(n, t, e, i, s, r) {
    J.attemptFocus(r), window.requestAnimationFrame(() => {
      window.requestAnimationFrame(() => J.attemptFocus(r));
    });
  },
  exec_focus_first(n, t, e, i, s, r) {
    J.focusFirstInteractive(r) || J.focusFirst(r), window.requestAnimationFrame(() => {
      window.requestAnimationFrame(
        () => J.focusFirstInteractive(r) || J.focusFirst(r)
      );
    });
  },
  exec_push_focus(n, t, e, i, s, r) {
    We.push(r || s);
  },
  exec_pop_focus(n, t, e, i, s, r) {
    const o = We.pop();
    o && (o.focus(), window.requestAnimationFrame(() => {
      window.requestAnimationFrame(() => o.focus());
    }));
  },
  exec_add_class(n, t, e, i, s, r, { names: o, transition: a, time: l, blocking: c }) {
    this.addOrRemoveClasses(r, o, [], a, l, i, c);
  },
  exec_remove_class(n, t, e, i, s, r, { names: o, transition: a, time: l, blocking: c }) {
    this.addOrRemoveClasses(r, [], o, a, l, i, c);
  },
  exec_toggle_class(n, t, e, i, s, r, { names: o, transition: a, time: l, blocking: c }) {
    this.toggleClasses(r, o, a, l, i, c);
  },
  exec_toggle_attr(n, t, e, i, s, r, { attr: [o, a, l] }) {
    this.toggleAttr(r, o, a, l);
  },
  exec_ignore_attrs(n, t, e, i, s, r, { attrs: o }) {
    this.ignoreAttrs(r, o);
  },
  exec_transition(n, t, e, i, s, r, { time: o, transition: a, blocking: l }) {
    this.addOrRemoveClasses(r, [], [], a, o, i, l);
  },
  exec_toggle(n, t, e, i, s, r, { display: o, ins: a, outs: l, time: c, blocking: f }) {
    this.toggle(t, i, r, o, a, l, c, f);
  },
  exec_show(n, t, e, i, s, r, { display: o, transition: a, time: l, blocking: c }) {
    this.show(t, i, r, o, a, l, c);
  },
  exec_hide(n, t, e, i, s, r, { display: o, transition: a, time: l, blocking: c }) {
    this.hide(t, i, r, o, a, l, c);
  },
  exec_set_attr(n, t, e, i, s, r, { attr: [o, a] }) {
    this.setOrRemoveAttrs(r, [[o, a]], []);
  },
  exec_remove_attr(n, t, e, i, s, r, { attr: o }) {
    this.setOrRemoveAttrs(r, [], [o]);
  },
  ignoreAttrs(n, t) {
    h.putPrivate(n, "JS:ignore_attrs", {
      apply: (e, i) => {
        let s = Array.from(e.attributes), r = s.map((o) => o.name);
        Array.from(i.attributes).filter((o) => !r.includes(o.name)).forEach((o) => {
          h.attributeIgnored(o, t) && i.removeAttribute(o.name);
        }), s.forEach((o) => {
          h.attributeIgnored(o, t) && i.setAttribute(o.name, o.value);
        });
      }
    });
  },
  onBeforeElUpdated(n, t) {
    const e = h.private(n, "JS:ignore_attrs");
    e && e.apply(n, t);
  },
  // utils for commands
  show(n, t, e, i, s, r, o) {
    this.isVisible(e) || this.toggle(
      n,
      t,
      e,
      i,
      s,
      null,
      r,
      o
    );
  },
  hide(n, t, e, i, s, r, o) {
    this.isVisible(e) && this.toggle(
      n,
      t,
      e,
      i,
      null,
      s,
      r,
      o
    );
  },
  toggle(n, t, e, i, s, r, o, a) {
    o = o || qe;
    const [l, c, f] = s || [[], [], []], [p, m, g] = r || [[], [], []];
    if (l.length > 0 || p.length > 0)
      if (this.isVisible(e)) {
        const d = () => {
          this.addOrRemoveClasses(
            e,
            m,
            l.concat(c).concat(f)
          ), window.requestAnimationFrame(() => {
            this.addOrRemoveClasses(e, p, []), window.requestAnimationFrame(
              () => this.addOrRemoveClasses(e, g, m)
            );
          });
        }, v = () => {
          this.addOrRemoveClasses(e, [], p.concat(g)), h.putSticky(
            e,
            "toggle",
            (w) => w.style.display = "none"
          ), e.dispatchEvent(new Event("phx:hide-end"));
        };
        e.dispatchEvent(new Event("phx:hide-start")), a === !1 ? (d(), setTimeout(v, o)) : t.transition(o, d, v);
      } else {
        if (n === "remove")
          return;
        const d = () => {
          this.addOrRemoveClasses(
            e,
            c,
            p.concat(m).concat(g)
          );
          const w = i || this.defaultDisplay(e);
          window.requestAnimationFrame(() => {
            this.addOrRemoveClasses(e, l, []), window.requestAnimationFrame(() => {
              h.putSticky(
                e,
                "toggle",
                (O) => O.style.display = w
              ), this.addOrRemoveClasses(e, f, c);
            });
          });
        }, v = () => {
          this.addOrRemoveClasses(e, [], l.concat(f)), e.dispatchEvent(new Event("phx:show-end"));
        };
        e.dispatchEvent(new Event("phx:show-start")), a === !1 ? (d(), setTimeout(v, o)) : t.transition(o, d, v);
      }
    else
      this.isVisible(e) ? window.requestAnimationFrame(() => {
        e.dispatchEvent(new Event("phx:hide-start")), h.putSticky(
          e,
          "toggle",
          (d) => d.style.display = "none"
        ), e.dispatchEvent(new Event("phx:hide-end"));
      }) : window.requestAnimationFrame(() => {
        e.dispatchEvent(new Event("phx:show-start"));
        const d = i || this.defaultDisplay(e);
        h.putSticky(
          e,
          "toggle",
          (v) => v.style.display = d
        ), e.dispatchEvent(new Event("phx:show-end"));
      });
  },
  toggleClasses(n, t, e, i, s, r) {
    window.requestAnimationFrame(() => {
      const [o, a] = h.getSticky(n, "classes", [[], []]), l = t.filter(
        (f) => o.indexOf(f) < 0 && !n.classList.contains(f)
      ), c = t.filter(
        (f) => a.indexOf(f) < 0 && n.classList.contains(f)
      );
      this.addOrRemoveClasses(
        n,
        l,
        c,
        e,
        i,
        s,
        r
      );
    });
  },
  toggleAttr(n, t, e, i) {
    n.hasAttribute(t) ? i !== void 0 ? n.getAttribute(t) === e ? this.setOrRemoveAttrs(n, [[t, i]], []) : this.setOrRemoveAttrs(n, [[t, e]], []) : this.setOrRemoveAttrs(n, [], [t]) : this.setOrRemoveAttrs(n, [[t, e]], []);
  },
  addOrRemoveClasses(n, t, e, i, s, r, o) {
    s = s || qe;
    const [a, l, c] = i || [
      [],
      [],
      []
    ];
    if (a.length > 0) {
      const f = () => {
        this.addOrRemoveClasses(
          n,
          l,
          [].concat(a).concat(c)
        ), window.requestAnimationFrame(() => {
          this.addOrRemoveClasses(n, a, []), window.requestAnimationFrame(
            () => this.addOrRemoveClasses(n, c, l)
          );
        });
      }, p = () => this.addOrRemoveClasses(
        n,
        t.concat(c),
        e.concat(a).concat(l)
      );
      o === !1 ? (f(), setTimeout(p, s)) : r.transition(s, f, p);
      return;
    }
    window.requestAnimationFrame(() => {
      const [f, p] = h.getSticky(n, "classes", [[], []]), m = t.filter(
        (w) => f.indexOf(w) < 0 && !n.classList.contains(w)
      ), g = e.filter(
        (w) => p.indexOf(w) < 0 && n.classList.contains(w)
      ), d = f.filter((w) => e.indexOf(w) < 0).concat(m), v = p.filter((w) => t.indexOf(w) < 0).concat(g);
      h.putSticky(n, "classes", (w) => (w.classList.remove(...v), w.classList.add(...d), [d, v]));
    });
  },
  setOrRemoveAttrs(n, t, e) {
    const [i, s] = h.getSticky(n, "attrs", [[], []]), r = t.map(([l, c]) => l).concat(e), o = i.filter(([l, c]) => !r.includes(l)).concat(t), a = s.filter((l) => !r.includes(l)).concat(e);
    t.some(([l, c]) => l === "id") && h.putPrivate(n, "clientsideIdAttribute", !0), h.putSticky(n, "attrs", (l) => (a.forEach((c) => l.removeAttribute(c)), o.forEach(
      ([c, f]) => l.setAttribute(c, f)
    ), [o, a]));
  },
  hasAllClasses(n, t) {
    return t.every((e) => n.classList.contains(e));
  },
  isToggledOut(n, t) {
    return !this.isVisible(n) || this.hasAllClasses(n, t);
  },
  filterToEls(n, t, { to: e }) {
    const i = () => {
      if (typeof e == "string")
        return document.querySelectorAll(e);
      if (e.closest) {
        const s = t.closest(e.closest);
        return s ? [s] : [];
      } else if (e.inner)
        return t.querySelectorAll(e.inner);
    };
    return e ? n.jsQuerySelectorAll(t, e, i) : [t];
  },
  defaultDisplay(n) {
    return { tr: "table-row", td: "table-cell" }[n.tagName.toLowerCase()] || "block";
  },
  // val is the raw wire transition value: a space-delimited class string OR a nested
  // [run, start, end] array whose elements are themselves string-or-array — genuinely dynamic, kept any.
  transitionClasses(n) {
    if (!n)
      return null;
    let [t, e, i] = Array.isArray(n) ? n : [n.split(" "), [], []];
    return t = Array.isArray(t) ? t : t.split(" "), e = Array.isArray(e) ? e : e.split(" "), i = Array.isArray(i) ? i : i.split(" "), [t, e, i];
  }
}, ei = (n, t) => ({
  exec(e, i) {
    n.execJS(e, i, t);
  },
  show(e, i = {}) {
    const s = n.owner(e);
    E.show(
      t,
      s,
      e,
      i.display,
      E.transitionClasses(i.transition),
      i.time,
      i.blocking
    );
  },
  hide(e, i = {}) {
    const s = n.owner(e);
    E.hide(
      t,
      s,
      e,
      null,
      E.transitionClasses(i.transition),
      i.time,
      i.blocking
    );
  },
  toggle(e, i = {}) {
    const s = n.owner(e), r = E.transitionClasses(i.in), o = E.transitionClasses(i.out);
    E.toggle(
      t,
      s,
      e,
      i.display,
      r,
      o,
      i.time,
      i.blocking
    );
  },
  addClass(e, i, s = {}) {
    const r = Array.isArray(i) ? i : i.split(" "), o = n.owner(e);
    E.addOrRemoveClasses(
      e,
      r,
      [],
      E.transitionClasses(s.transition),
      s.time,
      o,
      s.blocking
    );
  },
  removeClass(e, i, s = {}) {
    const r = Array.isArray(i) ? i : i.split(" "), o = n.owner(e);
    E.addOrRemoveClasses(
      e,
      [],
      r,
      E.transitionClasses(s.transition),
      s.time,
      o,
      s.blocking
    );
  },
  toggleClass(e, i, s = {}) {
    const r = Array.isArray(i) ? i : i.split(" "), o = n.owner(e);
    E.toggleClasses(
      e,
      r,
      E.transitionClasses(s.transition),
      s.time,
      o,
      s.blocking
    );
  },
  transition(e, i, s = {}) {
    const r = n.owner(e);
    E.addOrRemoveClasses(
      e,
      [],
      [],
      E.transitionClasses(i),
      s.time,
      r,
      s.blocking
    );
  },
  setAttribute(e, i, s) {
    E.setOrRemoveAttrs(e, [[i, s]], []);
  },
  removeAttribute(e, i) {
    E.setOrRemoveAttrs(e, [], [i]);
  },
  toggleAttribute(e, i, s, r) {
    E.toggleAttr(e, i, s, r);
  },
  push(e, i, s = {}) {
    n.withinOwners(e, (r) => {
      const o = s.value || {};
      delete s.value;
      let a = new CustomEvent("phx:exec", { detail: { sourceElement: e } });
      E.exec(a, t, i, r, e, ["push", { data: o, ...s }]);
    });
  },
  navigate(e, i = {}) {
    He(e, "navigate");
    const s = new CustomEvent("phx:exec");
    n.historyRedirect(
      s,
      e,
      i.replace ? "replace" : "push",
      null,
      null
    );
  },
  patch(e, i = {}) {
    He(e, "patch");
    const s = new CustomEvent("phx:exec");
    n.pushHistoryPatch(
      s,
      e,
      i.replace ? "replace" : "push",
      null
    );
  },
  ignoreAttributes(e, i) {
    E.ignoreAttrs(e, Array.isArray(i) ? i : [i]);
  }
}), se = "hookId", Ke = "deadHook";
let Ki = 1;
class G {
  el;
  __listeners;
  __isDisconnected;
  __view;
  __liveSocket;
  get liveSocket() {
    return this.__liveSocket();
  }
  /** @internal */
  static makeID() {
    return Ki++;
  }
  /** @internal */
  static elementID(t) {
    return h.private(t, se);
  }
  /** @internal */
  static deadHook(t) {
    return h.private(t, Ke) === !0;
  }
  /** @internal */
  constructor(t, e, i) {
    if (this.el = e, this.__attachView(t), this.__listeners = /* @__PURE__ */ new Set(), this.__isDisconnected = !1, h.putPrivate(this.el, se, G.makeID()), t && t.isDead && h.putPrivate(this.el, Ke, !0), i) {
      const s = /* @__PURE__ */ new Set([
        "el",
        "liveSocket",
        "__view",
        "__listeners",
        "__isDisconnected",
        "constructor",
        // Standard object properties
        // Core ViewHook API methods
        "js",
        "pushEvent",
        "pushEventTo",
        "handleEvent",
        "removeHandleEvent",
        "upload",
        "uploadTo",
        // Internal lifecycle callers
        "__mounted",
        "__updated",
        "__beforeUpdate",
        "__destroyed",
        "__reconnected",
        "__disconnected",
        "__cleanup__"
      ]);
      for (const o in i)
        Object.prototype.hasOwnProperty.call(i, o) && (this[o] = i[o], s.has(o) && console.warn(
          `Hook object for element #${e.id} overwrites core property '${o}'!`
        ));
      [
        "mounted",
        "beforeUpdate",
        "updated",
        "destroyed",
        "disconnected",
        "reconnected"
      ].forEach((o) => {
        i[o] && typeof i[o] == "function" && (this[o] = i[o]);
      });
    }
  }
  /** @internal */
  __attachView(t) {
    t ? (this.__view = () => t, this.__liveSocket = () => t.liveSocket) : (this.__view = () => {
      throw new Error(
        `hook not yet attached to a live view: ${this.el.outerHTML}`
      );
    }, this.__liveSocket = () => {
      throw new Error(
        `hook not yet attached to a live view: ${this.el.outerHTML}`
      );
    });
  }
  // Default lifecycle methods
  mounted() {
  }
  beforeUpdate() {
  }
  updated() {
  }
  destroyed() {
  }
  disconnected() {
  }
  reconnected() {
  }
  // Internal lifecycle callers - called by the View
  /** @internal */
  __mounted() {
    this.mounted();
  }
  /** @internal */
  __updated() {
    this.updated();
  }
  /** @internal */
  __beforeUpdate() {
    this.beforeUpdate();
  }
  /** @internal */
  __destroyed() {
    this.destroyed(), h.deletePrivate(this.el, se);
  }
  /** @internal */
  __reconnected() {
    this.__isDisconnected && (this.__isDisconnected = !1, this.reconnected());
  }
  /** @internal */
  __disconnected() {
    this.__isDisconnected = !0, this.disconnected();
  }
  js() {
    return {
      ...ei(this.__view().liveSocket, "hook"),
      exec: (t) => {
        this.__view().liveSocket.execJS(this.el, t, "hook");
      }
    };
  }
  pushEvent(t, e, i) {
    const s = this.__view().pushHookEvent(
      this.el,
      null,
      t,
      e || {}
    );
    if (i === void 0)
      return s.then(({ reply: r }) => r);
    s.then(
      ({ reply: r, ref: o }) => i(r, o)
    ).catch(() => {
    });
  }
  pushEventTo(t, e, i, s) {
    if (s === void 0) {
      const r = [];
      this.__view().withinTargets(
        t,
        (a, l) => {
          r.push({ view: a, targetCtx: l });
        }
      );
      const o = r.map(({ view: a, targetCtx: l }) => a.pushHookEvent(
        this.el,
        l,
        e,
        i || {}
      ));
      return Promise.allSettled(o);
    }
    this.__view().withinTargets(
      t,
      (r, o) => {
        r.pushHookEvent(this.el, o, e, i || {}).then(
          ({ reply: a, ref: l }) => s(a, l)
        ).catch(() => {
        });
      }
    );
  }
  handleEvent(t, e) {
    const i = {
      event: t,
      callback: (s) => e(s.detail)
    };
    return window.addEventListener(
      `phx:${t}`,
      i.callback
    ), this.__listeners.add(i), i;
  }
  removeHandleEvent(t) {
    window.removeEventListener(
      `phx:${t.event}`,
      t.callback
    ), this.__listeners.delete(t);
  }
  // return mirrors View.dispatchUploads, which is untyped (any) upstream
  upload(t, e) {
    return this.__view().dispatchUploads(null, t, e);
  }
  uploadTo(t, e, i) {
    return this.__view().withinTargets(
      t,
      (s, r) => {
        s.dispatchUploads(r, e, i);
      }
    );
  }
  /** @internal */
  __cleanup__() {
    this.__listeners.forEach(
      (t) => this.removeHandleEvent(t)
    );
  }
}
const zi = (n, t) => {
  const e = n.endsWith("[]");
  let i = e ? n.slice(0, -2) : n;
  return i = i.replace(/([^\[\]]+)(\]?$)/, `${t}$1$2`), e && (i += "[]"), i;
};
class qt {
  static closestView(t) {
    const e = t.closest(It);
    return e ? h.private(e, "view") : null;
  }
  liveSocket;
  id;
  el;
  isDead;
  root;
  portalElementIds;
  channel;
  rendered;
  flash;
  parent;
  ref;
  lastAckRef;
  childJoins;
  loaderTimer;
  disconnectedTimer;
  // raw wire diffs queued for replay after join — dynamic JSON shapes
  pendingDiffs;
  redirect;
  href;
  joinCount;
  joinAttempts;
  joinPending;
  destroyed;
  joinCallback;
  stopCallback;
  // root stores [view, op] tuples for children + itself; on a rejoin a child
  // stores bare ops (() => void) instead — hence the union
  pendingJoinOps;
  viewHooks;
  // queued form submits: [formEl, ref, opts, callback]
  formSubmits;
  children;
  pendingForms;
  formsForRecovery;
  constructor(t, e, i, s = null, r = null) {
    this.rendered = null, this.isDead = !1, this.liveSocket = e, this.flash = s, this.parent = i, this.root = i ? i.root : this, this.el = t;
    const o = h.private(this.el, "view");
    if (o !== void 0 && o.isDead !== !0)
      throw T(
        `The DOM element for this view has already been bound to a view.

        An element can only ever be associated with a single view!
        Please ensure that you are not trying to initialize multiple LiveSockets on the same page.
        This could happen if you're accidentally trying to render your root layout more than once.
        Ensure that the template set on the LiveView is different than the root layout.
      `,
        { view: o }
      ), new Error("Cannot bind multiple views to the same DOM element.");
    h.putPrivate(this.el, "view", this), this.id = this.el.id, this.el.setAttribute(tt, this.root.id), this.ref = 0, this.lastAckRef = null, this.childJoins = 0, this.loaderTimer = null, this.disconnectedTimer = null, this.pendingDiffs = [], this.pendingForms = /* @__PURE__ */ new Set(), this.redirect = !1, this.href = null, this.joinCount = this.parent ? this.parent.joinCount - 1 : 0, this.joinAttempts = 0, this.joinPending = !0, this.destroyed = !1, this.joinCallback = function(a) {
      a && a();
    }, this.stopCallback = function() {
    }, this.pendingJoinOps = [], this.viewHooks = {}, this.formSubmits = [], this.children = this.parent ? null : {}, this.root.children[this.id] = {}, this.formsForRecovery = {}, this.channel = this.liveSocket.channel(`lv:${this.id}`, () => {
      const a = this.href && this.expandURL(this.href);
      return {
        redirect: this.redirect ? a : void 0,
        url: this.redirect ? void 0 : a || void 0,
        params: this.connectParams(r),
        session: this.getSession(),
        static: this.getStatic(),
        flash: this.flash ?? void 0,
        sticky: this.el.hasAttribute(le)
      };
    }), this.portalElementIds = /* @__PURE__ */ new Set();
  }
  setHref(t) {
    this.href = t;
  }
  setRedirect(t) {
    this.redirect = !0, this.href = t;
  }
  isMain() {
    return this.el.hasAttribute(fe);
  }
  connectParams(t) {
    const e = this.liveSocket.params(this.el), i = h.all(document, `[${this.binding(si)}]`).map(
      (s) => "src" in s && s.src || "href" in s && s.href
    ).filter((s) => typeof s == "string");
    return i.length > 0 && (e._track_static = i), e._mounts = this.joinCount, e._mount_attempts = this.joinAttempts, e._live_referer = t ?? void 0, this.joinAttempts++, e;
  }
  isConnected() {
    return this.channel.canPush();
  }
  getSession() {
    return this.el.getAttribute(Q);
  }
  getStatic() {
    const t = this.el.getAttribute(ct);
    return t === "" ? null : t;
  }
  destroy(t = function() {
  }) {
    this.destroyAllChildren(), this.destroyPortalElements(), this.destroyed = !0, h.deletePrivate(this.el, "view"), delete this.root.children[this.id], this.parent && delete this.root.children[this.parent.id][this.id], this.loaderTimer != null && clearTimeout(this.loaderTimer);
    const e = () => {
      t();
      for (const i in this.viewHooks)
        this.destroyHook(this.viewHooks[i]);
    };
    h.markPhxChildDestroyed(this.el), this.log("destroyed", () => ["the child has been removed from the parent"]), this.channel.leave().receive("ok", e).receive("error", e).receive("timeout", e);
  }
  setContainerClasses(...t) {
    this.el.classList.remove(
      ke,
      lt,
      mt,
      Ee,
      kt
    ), this.el.classList.add(...t);
  }
  showLoader(t) {
    if (this.loaderTimer != null && clearTimeout(this.loaderTimer), t)
      this.loaderTimer = setTimeout(() => this.showLoader(), t);
    else {
      for (const e in this.viewHooks)
        this.viewHooks[e].__disconnected();
      this.setContainerClasses(lt);
    }
  }
  execAll(t) {
    h.all(
      this.el,
      `[${t}]`,
      (e) => this.liveSocket.execJS(e, e.getAttribute(t))
    );
  }
  hideLoader() {
    this.loaderTimer != null && clearTimeout(this.loaderTimer), this.disconnectedTimer != null && clearTimeout(this.disconnectedTimer), this.setContainerClasses(ke), this.execAll(this.binding("connected"));
  }
  triggerReconnected() {
    for (const t in this.viewHooks)
      this.viewHooks[t].__reconnected();
  }
  log(t, e) {
    this.liveSocket.log(this, t, e);
  }
  transition(t, e, i = function() {
  }) {
    this.liveSocket.transition(t, e, i);
  }
  // calls the callback with the view and target element for the given phxTarget
  // targets can be:
  //  * an element itself, then it is simply passed to liveSocket.owner;
  //  * a CID (Component ID), then we first search the component's element in the DOM
  //  * a selector, then we search the selector in the DOM and call the callback
  //    for each element found with the corresponding owner view
  withinTargets(t, e, i = document) {
    if (t instanceof HTMLElement || t instanceof SVGElement)
      return this.liveSocket.owner(
        t,
        (s) => e(s, t)
      );
    if (ot(t))
      h.findComponent(this.id, t, i) ? e(
        this,
        typeof t == "number" ? t : parseInt(t)
      ) : T(`no component found matching phx-target of ${t}`);
    else {
      const s = Array.from(i.querySelectorAll(t));
      s.length === 0 && T(
        `nothing found matching the phx-target selector "${t}"`
      ), s.forEach(
        (r) => this.liveSocket.owner(r, (o) => e(o, r))
      );
    }
  }
  applyDiff(t, e, i) {
    this.log(t, () => ["", Vt(e)]);
    const { diff: s, reply: r, events: o, title: a } = Xe.extract(e), l = o.reduce(
      (f, p) => (p.length === 3 && p[2] == !0 ? f.pre.push(p.slice(0, -1)) : f.post.push(p), f),
      { pre: [], post: [] }
    );
    this.liveSocket.dispatchEvents(l.pre);
    const c = () => {
      i({ diff: s, reply: r, events: l.post }), (typeof a == "string" || t == "mount" && this.isMain()) && window.requestAnimationFrame(() => h.putTitle(a));
    };
    "onDocumentPatch" in this.liveSocket.domCallbacks ? this.liveSocket.triggerDOM("onDocumentPatch", [c]) : c();
  }
  onJoin(t) {
    const { rendered: e, container: i, liveview_version: s, pid: r } = t;
    if (i) {
      const [o, a] = i;
      this.el = h.replaceRootContainer(this.el, o, a), h.putPrivate(this.el, "view", this);
    }
    this.childJoins = 0, this.joinPending = !0, this.flash = null, this.root === this && (this.formsForRecovery = this.getFormsForRecovery()), this.isMain() && window.history.state === null && V.pushState("replace", {
      type: "patch",
      id: this.id,
      position: this.liveSocket.currentHistoryPosition
    }), s !== this.liveSocket.version() && console.warn(
      `LiveView asset version mismatch. JavaScript version ${this.liveSocket.version()} vs. server ${s}. To avoid issues, please ensure that your assets use the same version as the server.`
    ), r && this.el.setAttribute(ci, r), V.dropLocal(
      this.liveSocket.localStorage,
      window.location.pathname,
      ze
    ), this.applyDiff("mount", e, ({ diff: o, events: a }) => {
      this.rendered = new Xe(this.id, o);
      const [l, c] = this.renderContainer(null, "join");
      this.dropPendingRefs(), this.joinCount++, this.joinAttempts = 0, this.maybeRecoverForms(l, () => {
        this.onJoinComplete(t, l, c, a);
      });
    });
  }
  dropPendingRefs() {
    h.all(document, `[${W}="${this.refSrc()}"]`, (t) => {
      t.removeAttribute(yt), t.removeAttribute(W), t.removeAttribute(x);
    });
  }
  onJoinComplete({ live_patch: t }, e, i, s) {
    if (this.joinCount > 1 || this.parent && !this.parent.isJoinPending())
      return this.applyJoinPatch(t, e, i, s);
    h.findPhxChildrenInFragment(e, this.id).filter(
      (o) => {
        const a = o.id && this.el.querySelector(`[id="${o.id}"]`), l = a && a.getAttribute(ct);
        return l && o.setAttribute(ct, l), a && a.setAttribute(tt, this.root.id), this.joinChild(o);
      }
    ).length === 0 ? this.parent ? (this.root.pendingJoinOps.push([
      this,
      () => this.applyJoinPatch(t, e, i, s)
    ]), this.parent.ackJoin(this)) : (this.onAllChildJoinsComplete(), this.applyJoinPatch(t, e, i, s)) : this.root.pendingJoinOps.push([
      this,
      () => this.applyJoinPatch(t, e, i, s)
    ]);
  }
  attachTrueDocEl() {
    const t = h.byId(this.id);
    if (!t)
      throw new Error("unable to find root element for view");
    this.el = t, h.putPrivate(this.el, "view", this), this.el.setAttribute(tt, this.root.id);
  }
  // this is invoked for dead and live views, so we must filter by
  // by owner to ensure we aren't duplicating hooks across disconnect
  // and connected states. This also handles cases where hooks exist
  // in a root layout with a LV in the body
  execNewMounted(t = document) {
    let e = this.binding(oe), i = this.binding(ae);
    this.all(
      t,
      `[${e}], [${i}]`,
      (s) => {
        h.maintainPrivateHooks(
          s,
          s,
          e,
          i
        ), this.maybeAddNewHook(s);
      }
    ), this.all(
      t,
      `[${this.binding(Et)}], [data-phx-${Et}]`,
      (s) => {
        this.maybeAddNewHook(s);
      }
    ), this.all(t, `[${this.binding(Te)}]`, (s) => {
      this.maybeMounted(s);
    });
  }
  all(t, e, i) {
    h.all(t, e, (s) => {
      this.ownsElement(s) && i(s);
    });
  }
  applyJoinPatch(t, e, i, s) {
    this.joinCount > 1 && this.pendingJoinOps.length && (this.pendingJoinOps.forEach((o) => typeof o == "function" && o()), this.pendingJoinOps = []), this.attachTrueDocEl();
    const r = new $t(this, this.el, e, i, null);
    if (r.markPrunableContentForRemoval(), this.performPatch(r, !1, !0), this.joinNewChildren(), this.execNewMounted(), this.joinPending = !1, this.liveSocket.dispatchEvents(s), this.applyPendingUpdates(), t) {
      const { kind: o, to: a } = t;
      this.liveSocket.historyPatch(a, o);
    }
    this.hideLoader(), this.joinCount > 1 && this.triggerReconnected(), this.stopCallback();
  }
  triggerBeforeUpdateHook(t, e) {
    this.liveSocket.triggerDOM("onBeforeElUpdated", [t, e]);
    const i = this.getHook(t), s = i && h.isIgnored(t, this.binding(Wt));
    if (i && !t.isEqualNode(e) && !(s && Ei(t.dataset, e.dataset)))
      return i.__beforeUpdate(), i;
  }
  maybeMounted(t) {
    const e = t.getAttribute(this.binding(Te)), i = e && h.private(t, "mounted");
    e && !i && (this.liveSocket.execJS(t, e), h.putPrivate(t, "mounted", !0));
  }
  maybeAddNewHook(t) {
    const e = this.addHook(t);
    e && e.__mounted();
  }
  performPatch(t, e, i = !1) {
    const s = [];
    let r = !1;
    const o = /* @__PURE__ */ new Set();
    return this.liveSocket.triggerDOM("onPatchStart", [t.targetContainer]), t.afterAdded((a) => {
      this.liveSocket.triggerDOM("onNodeAdded", [a]);
      const l = this.binding(oe), c = this.binding(ae);
      h.maintainPrivateHooks(a, a, l, c), this.maybeAddNewHook(a), a.getAttribute && this.maybeMounted(a);
    }), t.afterPhxChildAdded((a) => {
      h.isPhxSticky(a) ? this.liveSocket.joinRootViews() : r = !0;
    }), t.beforeUpdated((a, l) => {
      this.triggerBeforeUpdateHook(a, l) && o.add(a.id), E.onBeforeElUpdated(a, l);
    }), t.afterUpdated((a) => {
      if (o.has(a.id)) {
        const l = this.getHook(a);
        l && l.__updated();
      }
    }), t.afterDiscarded((a) => {
      a.nodeType === Node.ELEMENT_NODE && s.push(a);
    }), t.afterTransitionsDiscarded(
      (a) => this.afterElementsRemoved(a, e)
    ), t.perform(i), this.afterElementsRemoved(s, e), this.liveSocket.triggerDOM("onPatchEnd", [t.targetContainer]), r;
  }
  afterElementsRemoved(t, e) {
    const i = [];
    t.forEach((s) => {
      const r = h.all(
        s,
        `[${At}="${this.id}"][${Y}]`
      ), o = h.all(
        s,
        `[${this.binding(Et)}], [data-phx-hook]`
      );
      r.concat(s).forEach((a) => {
        const l = this.componentID(a);
        ot(l) && i.indexOf(l) === -1 && a.getAttribute(At) === this.id && i.push(l);
      }), o.concat(s).forEach((a) => {
        const l = this.getHook(a);
        l && this.destroyHook(l);
      });
    }), e && this.maybePushComponentsDestroyed(i);
  }
  joinNewChildren() {
    h.findPhxChildren(document, this.id).forEach((t) => this.joinChild(t));
  }
  maybeRecoverForms(t, e) {
    const i = this.binding("change"), s = this.root.formsForRecovery, r = document.createElement("template");
    if (r.innerHTML = t, !r.content.firstElementChild)
      return;
    h.all(r.content, `[${pe}]`).forEach((l) => {
      l instanceof HTMLTemplateElement && r.content.firstElementChild?.appendChild(
        l.content.firstElementChild
      );
    });
    const o = r.content.firstElementChild;
    o.id = this.id, o.setAttribute(tt, this.root.id), o.setAttribute(Q, this.getSession()), o.setAttribute(ct, this.getStatic() ?? ""), this.parent && o.setAttribute(dt, this.parent.id), h.putPrivate(o, "view", this);
    const a = (
      // we go over all forms in the new DOM; because this is only the HTML for the current
      // view, we can be sure that all forms are owned by this view:
      h.all(r.content, "form").filter((l) => l.id && s[l.id]).filter((l) => !this.pendingForms.has(l.id)).filter(
        (l) => s[l.id].getAttribute(i) === l.getAttribute(i)
      ).map((l) => [s[l.id], l])
    );
    if (a.length === 0)
      return e();
    a.forEach(([l, c], f) => {
      this.pendingForms.add(c.id), this.pushFormRecovery(
        l,
        c,
        r.content.firstElementChild,
        () => {
          this.pendingForms.delete(c.id), f === a.length - 1 && e();
        }
      );
    });
  }
  getChildById(t) {
    return this.root.children[this.id][t];
  }
  getDescendentByEl(t) {
    return t.id === this.id ? this : this.children && this.children[t.getAttribute(dt)]?.[t.id];
  }
  destroyDescendent(t) {
    for (const e in this.root.children)
      for (const i in this.root.children[e])
        if (i === t)
          return this.root.children[e][i].destroy();
  }
  joinChild(t) {
    if (!this.getChildById(t.id)) {
      const i = new qt(t, this.liveSocket, this);
      return this.root.children[this.id][i.id] = i, i.join(), this.childJoins++, !0;
    }
  }
  isJoinPending() {
    return this.joinPending;
  }
  ackJoin(t) {
    this.childJoins--, this.childJoins === 0 && (this.parent ? this.parent.ackJoin(this) : this.onAllChildJoinsComplete());
  }
  onAllChildJoinsComplete() {
    this.pendingForms.clear(), this.formsForRecovery = {}, this.joinCallback(() => {
      this.pendingJoinOps.forEach(([t, e]) => {
        t.isDestroyed() || e();
      }), this.pendingJoinOps = [];
    });
  }
  update(t, e, i = !1) {
    if (this.isJoinPending() || this.liveSocket.hasPendingLink() && this.root.isMain())
      return i || this.pendingDiffs.push({ diff: t, events: e }), !1;
    this.rendered.mergeDiff(t);
    let s = !1;
    return this.rendered.isComponentOnlyDiff(t) ? this.liveSocket.time("component patch complete", () => {
      h.findExistingParentCIDs(
        this.id,
        this.rendered.componentCIDs(t)
      ).forEach((o) => {
        this.componentPatch(
          this.rendered.getComponent(t, o),
          o
        ) && (s = !0);
      });
    }) : Fe(t) || this.liveSocket.time("full patch complete", () => {
      const [r, o] = this.renderContainer(t, "update"), a = new $t(this, this.el, r, o, null);
      s = this.performPatch(a, !0);
    }), this.liveSocket.dispatchEvents(e), s && this.joinNewChildren(), !0;
  }
  // streams is the dynamic stream-diff set consumed by DOMPatch (Set<Stream>)
  renderContainer(t, e) {
    return this.liveSocket.time(`toString diff (${e})`, () => {
      const i = this.el.tagName, s = t ? this.rendered.componentCIDs(t) : null, { buffer: r, streams: o } = this.rendered.toString(s);
      return [`<${i}>${r}</${i}>`, o];
    });
  }
  componentPatch(t, e) {
    if (Fe(t)) return !1;
    const { buffer: i, streams: s } = this.rendered.componentToString(e), r = new $t(this, this.el, i, s, e);
    return this.performPatch(r, !0);
  }
  getHook(t) {
    return this.viewHooks[G.elementID(t)];
  }
  addHook(t) {
    const e = G.elementID(t);
    if (!(t.getAttribute && !this.ownsElement(t)))
      if (e && !this.viewHooks[e]) {
        if (G.deadHook(t))
          return;
        const i = h.getCustomElHook(t) || T(`no hook found for custom element: ${t.id}`);
        return this.viewHooks[e] = i, i.__attachView(this), i;
      } else {
        if (e || !t.getAttribute)
          return;
        {
          const i = t.getAttribute(`data-phx-${Et}`) || t.getAttribute(this.binding(Et));
          if (!i)
            return;
          const s = this.liveSocket.getHookDefinition(i);
          if (s) {
            if (!t.id) {
              T(
                `no DOM ID for hook "${i}". Hooks require a unique ID on each element.`,
                t
              );
              return;
            }
            let r;
            try {
              if (typeof s == "function" && s.prototype instanceof G)
                r = new s(this, t);
              else if (typeof s == "object" && s !== null)
                r = new G(this, t, s);
              else {
                T(
                  `Invalid hook definition for "${i}". Expected a class extending ViewHook or an object definition.`,
                  t
                );
                return;
              }
            } catch (o) {
              const a = o instanceof Error ? o.message : String(o);
              T(`Failed to create hook "${i}": ${a}`, t);
              return;
            }
            return this.viewHooks[G.elementID(r.el)] = r, r;
          } else i !== null && T(`unknown hook found for "${i}"`, t);
        }
      }
  }
  destroyHook(t) {
    const e = G.elementID(t.el);
    t.__destroyed(), t.__cleanup__(), delete this.viewHooks[e];
  }
  applyPendingUpdates() {
    this.pendingDiffs = this.pendingDiffs.filter(
      ({ diff: t, events: e }) => !this.update(t, e, !0)
    ), this.eachChild((t) => t.applyPendingUpdates());
  }
  eachChild(t) {
    const e = this.root.children[this.id] || {};
    for (const i in e)
      t(this.getChildById(i));
  }
  onChannel(t, e) {
    this.liveSocket.onChannel(this.channel, t, (i) => {
      this.isJoinPending() ? this.joinCount > 1 ? this.pendingJoinOps.push(() => e(i)) : this.root.pendingJoinOps.push([this, () => e(i)]) : this.liveSocket.requestDOMUpdate(() => e(i));
    });
  }
  bindChannel() {
    this.liveSocket.onChannel(this.channel, "diff", (t) => {
      this.liveSocket.requestDOMUpdate(() => {
        this.applyDiff(
          "update",
          t,
          ({ diff: e, events: i }) => this.update(e, i)
        );
      });
    }), this.onChannel(
      "redirect",
      ({ to: t, flash: e }) => this.onRedirect({ to: t, flash: e })
    ), this.onChannel("live_patch", (t) => this.onLivePatch(t)), this.onChannel("live_redirect", (t) => this.onLiveRedirect(t)), this.channel.onError((t) => this.onError(t)), this.channel.onClose((t) => this.onClose(t));
  }
  destroyAllChildren() {
    this.eachChild((t) => t.destroy());
  }
  onLiveRedirect(t) {
    const { to: e, kind: i, flash: s } = t, r = this.expandURL(e), o = new CustomEvent("phx:server-navigate", {
      detail: { to: e, kind: i, flash: s }
    });
    this.liveSocket.historyRedirect(o, r, i, s);
  }
  onLivePatch(t) {
    const { to: e, kind: i } = t;
    this.href = this.expandURL(e), this.liveSocket.historyPatch(e, i);
  }
  expandURL(t) {
    return t.startsWith("/") ? `${window.location.protocol}//${window.location.host}${t}` : t;
  }
  onRedirect({
    to: t,
    flash: e,
    reloadToken: i
  }) {
    this.liveSocket.redirect(t, e ?? null, i ?? null);
  }
  isDestroyed() {
    return this.destroyed;
  }
  joinDead() {
    this.isDead = !0;
  }
  join(t) {
    this.showLoader(this.liveSocket.loaderTimeout), this.bindChannel(), this.isMain() && (this.stopCallback = this.liveSocket.withPageLoading({
      to: this.href,
      kind: "initial"
    })), this.joinCallback = (e) => {
      e = e || function() {
      }, t ? t(this.joinCount, e) : e();
    }, this.wrapPush(() => this.channel.join(), {
      ok: (e) => this.liveSocket.requestDOMUpdate(() => this.onJoin(e)),
      error: (e) => this.onJoinError(e),
      timeout: () => this.onJoinError({ reason: "timeout" })
    });
  }
  onJoinError(t) {
    if (t.events && this.liveSocket.dispatchEvents(t.events), t.reason === "reload") {
      this.log("error", () => [
        `failed mount with ${t.status}. Falling back to page reload`,
        t
      ]), this.onRedirect({
        to: this.liveSocket.main.href,
        reloadToken: t.token
      });
      return;
    } else if (t.reason === "unauthorized" || t.reason === "stale") {
      this.log("error", () => [
        "unauthorized live_redirect. Falling back to page request",
        t
      ]), this.onRedirect({ to: this.liveSocket.main.href, flash: this.flash });
      return;
    }
    if ((t.redirect || t.live_redirect) && (this.joinPending = !1, this.channel.leave()), t.redirect)
      return this.onRedirect(t.redirect);
    if (t.live_redirect)
      return this.onLiveRedirect(t.live_redirect);
    if (this.log("error", () => ["unable to join", t]), this.isMain())
      this.displayError(
        [lt, mt, kt],
        { unstructuredError: t, errorKind: "server" }
      ), this.liveSocket.isConnected() && this.liveSocket.reloadWithJitter(this);
    else {
      this.joinAttempts >= Re && (this.root.displayError(
        [lt, mt, kt],
        { unstructuredError: t, errorKind: "server" }
      ), this.log("error", () => [
        `giving up trying to mount after ${Re} tries`,
        t
      ]), this.destroy());
      const e = h.byId(this.el.id);
      e ? (h.mergeAttrs(e, this.el), this.displayError(
        [lt, mt, kt],
        { unstructuredError: t, errorKind: "server" }
      ), this.el = e) : this.destroy();
    }
  }
  onClose(t) {
    if (!this.isDestroyed()) {
      if (this.isMain() && this.liveSocket.hasPendingLink() && t !== "leave")
        return this.liveSocket.reloadWithJitter(this);
      this.destroyAllChildren(), this.liveSocket.dropActiveElement(this), this.liveSocket.isUnloaded() && this.showLoader(pi);
    }
  }
  onError(t) {
    this.onClose(t), this.liveSocket.isConnected() && this.log("error", () => ["view crashed", t]), this.liveSocket.isUnloaded() || (this.liveSocket.isConnected() ? this.displayError(
      [lt, mt, kt],
      { unstructuredError: t, errorKind: "server" }
    ) : this.displayError(
      [lt, mt, Ee],
      { unstructuredError: t, errorKind: "client" }
    ));
  }
  displayError(t, e = {}) {
    this.isMain() && h.dispatchEvent(window, "phx:page-loading-start", {
      detail: { to: this.href, kind: "error", ...e }
    }), this.showLoader(), this.setContainerClasses(...t), this.delayedDisconnected();
  }
  delayedDisconnected() {
    this.disconnectedTimer = setTimeout(() => {
      this.execAll(this.binding("disconnected"));
    }, this.liveSocket.disconnectedTimeout);
  }
  wrapPush(t, e) {
    const i = this.liveSocket.getLatencySim(), s = i ? (r) => setTimeout(() => !this.isDestroyed() && r(), i) : (r) => !this.isDestroyed() && r();
    s(() => {
      t().receive(
        "ok",
        (r) => s(() => e.ok && e.ok(r))
      ).receive(
        "error",
        (r) => s(() => e.error && e.error(r))
      ).receive(
        "timeout",
        () => s(() => e.timeout && e.timeout())
      );
    });
  }
  pushWithReply(t, e, i) {
    if (!this.isConnected())
      return Promise.reject(new Error("no connection"));
    const [s, [r], o] = t ? t({ payload: i }) : [null, [], {}], a = this.joinCount;
    let l = function() {
    };
    return o.page_loading && (l = this.liveSocket.withPageLoading({
      kind: "element",
      target: r
    })), typeof i.cid != "number" && delete i.cid, new Promise((c, f) => {
      this.wrapPush(() => this.channel.push(e, i, vi), {
        ok: (p) => {
          s !== null && (this.lastAckRef = s);
          const m = (g) => {
            p.redirect && this.onRedirect(p.redirect), p.live_patch && this.onLivePatch(p.live_patch), p.live_redirect && this.onLiveRedirect(p.live_redirect), l(), c({ resp: p, reply: g, ref: s });
          };
          p.diff ? this.liveSocket.requestDOMUpdate(() => {
            this.applyDiff("update", p.diff, ({ diff: g, reply: d, events: v }) => {
              s !== null && this.undoRefs(s, i.event), this.update(g, v), m(d);
            });
          }) : (s !== null && this.undoRefs(s, i.event), m(null));
        },
        error: (p) => f(new Error(`failed with reason: ${JSON.stringify(p)}`)),
        timeout: () => {
          f(new Error("timeout")), this.joinCount === a && this.liveSocket.reloadWithJitter(this, () => {
            this.log("timeout", () => [
              "received timeout while communicating with server. Falling back to hard refresh for recovery"
            ]);
          });
        }
      });
    });
  }
  undoRefs(t, e, i) {
    if (!this.isConnected())
      return;
    const s = `[${W}="${this.refSrc()}"]`;
    i ? (i = new Set(i), h.all(document, s, (r) => {
      i && !i.has(r) || (h.all(
        r,
        s,
        (o) => this.undoElRef(o, t, e)
      ), this.undoElRef(r, t, e));
    })) : h.all(document, s, (r) => this.undoElRef(r, t, e));
  }
  undoElRef(t, e, i) {
    new ce(t).maybeUndo(e, i, (r) => {
      const o = new $t(this, t, r, /* @__PURE__ */ new Set(), null, {
        undoRef: e
      }), a = this.performPatch(o, !0);
      h.all(
        t,
        `[${W}="${this.refSrc()}"]`,
        (l) => this.undoElRef(l, e, i)
      ), a && this.joinNewChildren();
    });
  }
  refSrc() {
    return this.el.id;
  }
  putRef(t, e, i, s = {}) {
    const r = this.ref++, o = this.binding(Se);
    if (s.loading) {
      const a = h.all(document, s.loading).map((l) => ({ el: l, lock: !0, loading: !0 }));
      t = t.concat(a);
    }
    for (const { el: a, lock: l, loading: c } of t) {
      if (!l && !c)
        throw new Error("putRef requires lock or loading");
      if (a.setAttribute(W, this.refSrc()), c && a.setAttribute(yt, r.toString()), l && a.setAttribute(x, r.toString()), !c || s.submitter && !(a === s.submitter || a === s.form))
        continue;
      const f = new Promise((d) => {
        a.addEventListener(`phx:undo-lock:${r}`, () => d(g), {
          once: !0
        });
      }), p = new Promise((d) => {
        a.addEventListener(
          `phx:undo-loading:${r}`,
          () => d(g),
          { once: !0 }
        );
      });
      a.classList.add(`phx-${i}-loading`);
      const m = a.getAttribute(o);
      m !== null && (a.getAttribute(Xt) || a.setAttribute(Xt, a.textContent || ""), m !== "" && (a.textContent = m), a.setAttribute(
        bt,
        a.getAttribute(bt) || ("disabled" in a ? String(a.disabled) : "")
      ), a.setAttribute("disabled", ""));
      const g = {
        event: e,
        eventType: i,
        ref: r,
        isLoading: c,
        isLocked: l,
        lockElements: t.filter(({ lock: d }) => d).map(({ el: d }) => d),
        loadingElements: t.filter(({ loading: d }) => d).map(({ el: d }) => d),
        unlock: (d) => {
          d = Array.isArray(d) ? d : [d], this.undoRefs(r, e, d);
        },
        lockComplete: f,
        loadingComplete: p,
        lock: (d) => new Promise((v) => {
          if (this.isAcked(r))
            return v(g);
          d.setAttribute(x, r), d.setAttribute(W, this.refSrc()), d.addEventListener(
            `phx:lock-stop:${r}`,
            () => v(g),
            { once: !0 }
          );
        })
      };
      s.payload && (g.payload = s.payload), s.target && (g.target = s.target), s.originalEvent && (g.originalEvent = s.originalEvent), a.dispatchEvent(
        new CustomEvent("phx:push", {
          detail: g,
          bubbles: !0,
          cancelable: !1
        })
      ), e && a.dispatchEvent(
        new CustomEvent(`phx:push:${e}`, {
          detail: g,
          bubbles: !0,
          cancelable: !1
        })
      );
    }
    return [r, t.map(({ el: a }) => a), s];
  }
  isAcked(t) {
    return this.lastAckRef !== null && this.lastAckRef >= t;
  }
  componentID(t) {
    const e = t.getAttribute && t.getAttribute(Y);
    return e ? parseInt(e) : null;
  }
  targetComponentID(t, e, i = {}) {
    if (ot(e))
      return e;
    const s = i.target || t.getAttribute(this.binding("target"));
    return ot(s) ? typeof s == "number" ? s : parseInt(s) : e && (s !== null || i.target) ? this.closestComponentID(e) : null;
  }
  // returns the resolved component id (a cid) or null; the return annotation
  // is required because this method recurses through `maybe`
  closestComponentID(t) {
    return ot(t) ? t : t ? wt(
      // We either use the closest data-phx-component binding, or -
      // in case of portals - continue with the portal source.
      // This is necessary if teleporting an element outside of its LiveComponent.
      t.closest(`[${Y}],[${at}]`),
      (e) => {
        if (e.hasAttribute(Y))
          return this.ownsElement(e) && this.componentID(e);
        if (e.hasAttribute(at)) {
          const i = h.byId(e.getAttribute(at));
          return this.closestComponentID(i);
        }
      }
    ) : null;
  }
  pushHookEvent(t, e, i, s) {
    if (!this.isConnected())
      return this.log("hook", () => [
        "unable to push hook event. LiveView not connected",
        i,
        s
      ]), Promise.reject(
        new Error("unable to push hook event. LiveView not connected")
      );
    const r = () => this.putRef([{ el: t, loading: !0, lock: !0 }], i, "hook", {
      payload: s,
      target: e
    });
    return this.pushWithReply(r, "event", {
      type: "hook",
      event: i,
      value: s,
      cid: this.closestComponentID(e)
    }).then(
      ({ resp: o, reply: a, ref: l }) => ({ reply: a, ref: l })
    );
  }
  extractMeta(t, e, i) {
    const s = this.binding("value-");
    for (let r = 0; r < t.attributes.length; r++) {
      e || (e = {});
      const o = t.attributes[r].name;
      o.startsWith(s) && (e[o.replace(s, "")] = t.getAttribute(o));
    }
    if (t.value !== void 0 && !(t instanceof HTMLFormElement) && (e || (e = {}), e.value = t.value, t.tagName === "INPUT" && Ze.indexOf(t.type) >= 0 && !t.checked && delete e.value), i) {
      e || (e = {});
      for (const r in i)
        e[r] = i[r];
    }
    return e;
  }
  serializeForm(t, e = {}, i = []) {
    const { submitter: s } = e;
    let r;
    if (s && s.name) {
      const m = document.createElement("input");
      m.type = "hidden";
      const g = s.getAttribute("form");
      g && m.setAttribute("form", g), m.name = s.name, m.value = s.value, s.parentElement.insertBefore(m, s), r = m;
    }
    const o = new FormData(t), a = [];
    o.forEach((m, g, d) => {
      m instanceof File && a.push(g);
    }), a.forEach((m) => o.delete(m));
    const l = new URLSearchParams(), { inputsUnused: c, onlyHiddenInputs: f } = Array.from(t.elements).reduce(
      (m, g) => {
        if (!h.isFormAssociated(g))
          return m;
        const { inputsUnused: d, onlyHiddenInputs: v } = m, w = g.name;
        if (!w)
          return m;
        d[w] === void 0 && (d[w] = !0), v[w] === void 0 && (v[w] = !0);
        const O = g.hasAttribute(
          this.binding(_e)
        ), M = h.private(g, Jt) || h.private(g, xt) || O, H = g.type === "hidden";
        return d[w] = d[w] && !M, v[w] = v[w] && H, m;
      },
      {
        inputsUnused: {},
        onlyHiddenInputs: {}
      }
    ), p = t.hasAttribute(
      this.binding(_e)
    );
    for (const [m, g] of o.entries())
      if (i.length === 0 || i.indexOf(m) >= 0) {
        const d = c[m], v = f[m];
        !p && d && !(s && s.name == m) && !v && l.append(zi(m, "_unused_"), ""), typeof g == "string" && l.append(m, g);
      }
    return s && r && s.parentElement.removeChild(r), l.toString();
  }
  pushEvent(t, e, i, s, r, o = {}, a) {
    this.pushWithReply(
      (l) => this.putRef([{ el: e, loading: !0, lock: !0 }], s, t, {
        ...o,
        payload: l?.payload
      }),
      "event",
      {
        type: t,
        event: s,
        value: this.extractMeta(e, r, o.value),
        cid: this.targetComponentID(e, i, o)
      }
    ).then(({ reply: l }) => a && a(l)).catch((l) => T("Failed to push event", l));
  }
  pushFileProgress(t, e, i, s = function() {
  }) {
    this.liveSocket.withinOwners(
      t.form,
      (r, o) => {
        r.pushWithReply(null, "progress", {
          event: t.getAttribute(r.binding(ui)),
          ref: t.getAttribute(et),
          entry_ref: e,
          progress: i,
          cid: r.targetComponentID(t.form, o)
        }).then(() => s()).catch(
          (a) => T("Failed to push file progress", a)
        );
      }
    );
  }
  pushInput(t, e, i, s, r, o) {
    if (!t.form)
      throw new Error("form events require the input to be inside a form");
    let a;
    const l = ot(i) ? i : this.targetComponentID(t.form, e, r), c = (d) => this.putRef(
      [
        { el: t, loading: !0, lock: !0 },
        { el: t.form, loading: !0, lock: !0 }
      ],
      s,
      "change",
      { ...r, payload: d?.payload }
    );
    let f;
    const p = this.extractMeta(t.form, {}, r.value), m = {};
    t instanceof HTMLButtonElement && (m.submitter = t), t.getAttribute(this.binding("change")) ? f = this.serializeForm(t.form, m, [
      t.name
    ]) : f = this.serializeForm(t.form, m), h.isUploadInput(t) && t.files && t.files.length > 0 && L.trackFiles(t, Array.from(t.files)), a = L.serializeUploads(t);
    const g = {
      type: "form",
      event: s,
      value: f,
      meta: {
        // no target was implicitly sent as "undefined" in LV <= 1.0.5, therefore
        // we have to keep it. In 1.0.6 we switched from passing meta as URL encoded data
        // to passing it directly in the event, but the JSON encode would drop keys with
        // undefined values.
        _target: r._target || "undefined",
        ...p
      },
      uploads: a,
      cid: l
    };
    this.pushWithReply(c, "event", g).then(({ resp: d }) => {
      h.isUploadInput(t) && h.isAutoUpload(t) ? ce.onUnlock(t, () => {
        if (L.filesAwaitingPreflight(t).length > 0) {
          const [v, w] = c();
          this.undoRefs(v, s, [t.form]), this.uploadFiles(
            t.form,
            s,
            e,
            v,
            l,
            (O) => {
              o && o(d), this.triggerAwaitingSubmit(t.form, s), this.undoRefs(v, s);
            }
          );
        }
      }) : o && o(d);
    }).catch((d) => T("Failed to push input event", d));
  }
  triggerAwaitingSubmit(t, e) {
    const i = this.getScheduledSubmit(t);
    if (i) {
      const [s, r, o, a] = i;
      this.cancelSubmit(t, e), a();
    }
  }
  getScheduledSubmit(t) {
    return this.formSubmits.find(
      ([e, i, s, r]) => e.isSameNode(t)
    );
  }
  scheduleSubmit(t, e, i, s) {
    if (this.getScheduledSubmit(t))
      return !0;
    this.formSubmits.push([t, e, i, s]);
  }
  cancelSubmit(t, e) {
    this.formSubmits = this.formSubmits.filter(
      ([i, s, r, o]) => i.isSameNode(t) ? (this.undoRefs(s, e), !1) : !0
    );
  }
  disableForm(t, e, i = {}) {
    const s = (d) => !(ht(
      d,
      `${this.binding(Wt)}=ignore`,
      d.form
    ) || ht(d, "data-phx-update=ignore", d.form)), r = (d) => d.hasAttribute(this.binding(Se)), o = (d) => d.tagName == "BUTTON", a = (d) => ["INPUT", "TEXTAREA"].includes(d.tagName), l = Array.from(t.elements), c = l.filter(r), f = l.filter(o).filter(s), p = l.filter(a).filter(s);
    f.forEach((d) => {
      d.setAttribute(bt, d.disabled.toString()), d.disabled = !0;
    }), p.forEach((d) => {
      d.setAttribute(he, d.readOnly.toString()), d.readOnly = !0, d instanceof HTMLInputElement && d.files && (d.setAttribute(bt, d.disabled.toString()), d.disabled = !0);
    });
    const m = c.concat(f).concat(p).map((d) => ({ el: d, loading: !0, lock: !0 })), g = [
      { el: t, loading: !0, lock: !1 },
      ...m
    ].reverse();
    return this.putRef(g, e, "submit", i);
  }
  pushFormSubmit(t, e, i, s, r, o) {
    const a = (c) => this.disableForm(t, i, {
      ...r,
      form: t,
      payload: c?.payload,
      submitter: s
    });
    h.putPrivate(t, "submitter", s);
    const l = this.targetComponentID(t, e);
    if (L.hasUploadsInProgress(t)) {
      const [c, f] = a(), p = () => this.pushFormSubmit(
        t,
        e,
        i,
        s,
        r,
        o
      );
      return this.scheduleSubmit(t, c, r, p);
    } else if (L.inputsAwaitingPreflight(t).length > 0) {
      const [c, f] = a(), p = () => [c, f, r];
      this.uploadFiles(
        t,
        i,
        e,
        c,
        l,
        (m) => {
          if (L.inputsAwaitingPreflight(t).length > 0)
            return this.undoRefs(c, i);
          const g = this.extractMeta(t, {}, r.value), d = this.serializeForm(t, { submitter: s });
          this.pushWithReply(p, "event", {
            type: "form",
            event: i,
            value: d,
            meta: g,
            cid: l
          }).then(({ resp: v }) => o(v)).catch((v) => T("Failed to push form submit", v));
        }
      );
    } else if (!(t.hasAttribute(W) && t.classList.contains("phx-submit-loading"))) {
      const c = this.extractMeta(t, {}, r.value), f = this.serializeForm(t, { submitter: s });
      this.pushWithReply(a, "event", {
        type: "form",
        event: i,
        value: f,
        meta: c,
        cid: l
      }).then(({ resp: p }) => o(p)).catch((p) => T("Failed to push form submit", p));
    }
  }
  uploadFiles(t, e, i, s, r, o) {
    const a = this.joinCount, l = L.activeFileInputs(t);
    let c = l.length;
    l.forEach((f) => {
      const p = new L(f, this, () => {
        c--, c === 0 && o();
      }), m = p.entries().map((d) => d.toPreflightPayload());
      if (m.length === 0) {
        c--;
        return;
      }
      const g = {
        ref: f.getAttribute(et),
        entries: m,
        cid: this.targetComponentID(f.form, i)
      };
      this.log("upload", () => ["sending preflight request", g]), this.pushWithReply(null, "allow_upload", g).then(({ resp: d }) => {
        if (this.log("upload", () => ["got preflight response", d]), p.entries().forEach((v) => {
          d.entries && !d.entries[v.ref] && this.handleFailedEntryPreflight(
            v.ref,
            "failed preflight",
            p
          );
        }), d.error || Object.keys(d.entries).length === 0)
          this.undoRefs(s, e), (d.error || []).map(([w, O]) => {
            this.handleFailedEntryPreflight(w, O, p);
          });
        else {
          const v = (w) => {
            this.channel.onError(() => {
              this.joinCount === a && w();
            });
          };
          p.initAdapterUpload(d, v, this.liveSocket);
        }
      }).catch((d) => T("Failed to push upload", d));
    });
  }
  handleFailedEntryPreflight(t, e, i) {
    if (i.isAutoUpload()) {
      const s = i.entries().find((r) => r.ref === t.toString());
      s && s.cancel();
    } else
      i.entries().map((s) => s.cancel());
    this.log("upload", () => [`error for entry ${t}`, e]);
  }
  dispatchUploads(t, e, i) {
    const s = this.targetCtxElement(t) || this.el, r = h.findUploadInputs(s).filter(
      (o) => o.name === e
    );
    r.length === 0 ? T(`no live file inputs found matching the name "${e}"`) : r.length > 1 ? T(`duplicate live file inputs found matching the name "${e}"`) : h.dispatchEvent(r[0], Ye, {
      detail: { files: i }
    });
  }
  targetCtxElement(t) {
    return ot(t) ? h.findComponent(this.id, t) : t || null;
  }
  pushFormRecovery(t, e, i, s) {
    const r = this.binding("change"), o = e.getAttribute(this.binding("target")) || e, a = e.getAttribute(this.binding(Ce)) || e.getAttribute(this.binding("change")), l = Array.from(t.elements).filter(
      (p) => h.isFormAssociated(p) && p.name && !p.hasAttribute(r)
    );
    if (l.length === 0) {
      s();
      return;
    }
    l.forEach(
      (p) => p.hasAttribute(et) && L.clearFiles(p)
    );
    const c = l.find((p) => p.type !== "hidden") || l[0];
    let f = 0;
    this.withinTargets(
      o,
      (p, m) => {
        const g = this.targetComponentID(e, m);
        f++;
        let d = new CustomEvent("phx:form-recovery", {
          detail: { sourceElement: t }
        });
        E.exec(d, "change", a, this, c, [
          "push",
          {
            _target: c.name,
            targetView: p,
            targetCtx: m,
            newCid: g,
            callback: () => {
              f--, f === 0 && s();
            }
          }
        ]);
      },
      i
    );
  }
  pushLinkPatch(t, e, i, s) {
    const r = this.liveSocket.setPendingLink(e), o = t.isTrusted && t.type !== "popstate", a = i ? () => this.putRef(
      [{ el: i, loading: o, lock: !0 }],
      null,
      "click"
    ) : null, l = () => this.liveSocket.redirect(window.location.href, null, null), c = e.startsWith("/") ? `${location.protocol}//${location.host}${e}` : e;
    this.pushWithReply(a, "live_patch", { url: c }).then(
      ({ resp: f }) => {
        this.liveSocket.requestDOMUpdate(() => {
          if (f.link_redirect)
            this.liveSocket.replaceMain(e, null, s, r);
          else {
            if (f.redirect)
              return;
            this.liveSocket.commitPendingLink(r) && (this.href = e), this.applyPendingUpdates(), s && s(r);
          }
        });
      },
      ({ error: f, timeout: p }) => l()
    );
  }
  getFormsForRecovery() {
    if (this.joinCount === 0)
      return {};
    const t = this.binding("change");
    return h.all(
      document,
      `#${CSS.escape(this.id)} form[${t}], [${ut}="${CSS.escape(this.id)}"] form[${t}]`
    ).filter((e) => e instanceof HTMLFormElement).filter((e) => e.id).filter((e) => e.elements.length > 0).filter(
      (e) => e.getAttribute(this.binding(Ce)) !== "ignore"
    ).map((e) => {
      const i = e.cloneNode(!0);
      de(i, e, {
        onBeforeElUpdated: (r, o) => (h.copyPrivates(r, o), r.getAttribute("form") === e.id && r.parentNode ? (r.parentNode.removeChild(r), !1) : !0)
      });
      const s = document.querySelectorAll(
        `[form="${CSS.escape(e.id)}"]`
      );
      return Array.from(s).forEach((r) => {
        const o = r.cloneNode(!0);
        de(o, r), h.copyPrivates(o, r), o.removeAttribute("form"), i.appendChild(o);
      }), i;
    }).reduce(
      (e, i) => (e[i.id] = i, e),
      {}
    );
  }
  maybePushComponentsDestroyed(t) {
    let e = t.filter((s) => h.findComponent(this.id, s) === null);
    const i = (s) => {
      this.isDestroyed() || T("Failed to push components destroyed", s);
    };
    e.length > 0 && (e.forEach((s) => this.rendered.resetRender(s)), this.pushWithReply(null, "cids_will_destroy", { cids: e }).then(() => {
      this.liveSocket.requestDOMUpdate(() => {
        let s = e.filter((r) => h.findComponent(this.id, r) === null);
        s.length > 0 && this.pushWithReply(null, "cids_destroyed", {
          cids: s
        }).then(({ resp: r }) => {
          this.rendered.pruneCIDs(r.cids);
        }).catch(i);
      });
    }).catch(i));
  }
  ownsElement(t) {
    let e = h.closestViewEl(t);
    return t.getAttribute(dt) === this.id || e && e.id === this.id || !e && this.isDead;
  }
  submitForm(t, e, i, s, r = {}) {
    h.putPrivate(t, xt, !0), Array.from(t.elements).forEach((a) => h.putPrivate(a, xt, !0)), this.liveSocket.blurActiveElement(), this.pushFormSubmit(t, e, i, s, r, () => {
      this.liveSocket.restorePreviouslyActiveFocus();
    });
  }
  binding(t) {
    return this.liveSocket.binding(t);
  }
  // phx-portal
  pushPortalElementId(t) {
    this.portalElementIds.add(t);
  }
  dropPortalElementId(t) {
    this.portalElementIds.delete(t);
  }
  destroyPortalElements() {
    this.liveSocket.unloaded || this.portalElementIds.forEach((t) => {
      const e = document.getElementById(t);
      e && e.remove();
    });
  }
}
const Yi = (n) => h.isUsedInput(n);
class Qi {
  socket;
  /** @internal */
  unloaded = !1;
  bindingPrefix;
  viewLogger;
  // indexed by runtime event-name string; the per-event callback shapes vary
  // by event, so the map stays `any` to keep string indexing sound
  metadataCallbacks;
  defaults;
  prevActive;
  silenced;
  /** @internal */
  main;
  outgoingMainEl;
  clickStartedAtTarget;
  linkRef;
  roots;
  href;
  pendingLink;
  currentLocation;
  hooks;
  /** @internal */
  loaderTimeout;
  reloadWithJitterTimer;
  maxReloads;
  reloadJitterMin;
  reloadJitterMax;
  failsafeJitter;
  /** @internal */
  localStorage;
  sessionStorage;
  boundTopLevelEvents;
  boundEventNames;
  blockPhxChangeWhileComposing;
  serverCloseRef;
  /** @internal */
  domCallbacks;
  transitions;
  /** @internal */
  currentHistoryPosition;
  /** @internal */
  params;
  /** @internal */
  // user-supplied uploader callbacks keyed by name — opaque hook objects
  uploaders;
  /** @internal */
  disconnectedTimeout;
  /**
   * Creates a new LiveSocket instance.
   */
  constructor(t, e, i = {}) {
    if (!e || e.constructor.name === "Object")
      throw new Error(`
      a phoenix Socket must be provided as the second argument to the LiveSocket constructor. For example:

          import {Socket} from "phoenix"
          import {LiveSocket} from "phoenix_live_view"
          let liveSocket = new LiveSocket("/live", Socket, {...})
      `);
    this.socket = new e(t, i), this.bindingPrefix = i.bindingPrefix || gi, this.params = Tt(i.params || {}), this.viewLogger = i.viewLogger, this.metadataCallbacks = i.metadata || {}, this.defaults = Object.assign(Vt(bi), i.defaults || {}), this.prevActive = null, this.silenced = !1, this.main = null, this.outgoingMainEl = null, this.clickStartedAtTarget = null, this.linkRef = 1, this.roots = {}, this.href = window.location.href, this.pendingLink = null, this.currentLocation = Vt(window.location), this.hooks = i.hooks || {}, this.uploaders = i.uploaders || {}, this.loaderTimeout = i.loaderTimeout || fi, this.disconnectedTimeout = i.disconnectedTimeout || mi, this.reloadWithJitterTimer = null, this.maxReloads = i.maxReloads || 10, this.reloadJitterMin = i.reloadJitterMin || 5e3, this.reloadJitterMax = i.reloadJitterMax || 1e4, this.failsafeJitter = i.failsafeJitter || 3e4, this.localStorage = i.localStorage || window.localStorage, this.sessionStorage = i.sessionStorage || window.sessionStorage, this.boundTopLevelEvents = !1, this.boundEventNames = /* @__PURE__ */ new Set(), this.blockPhxChangeWhileComposing = i.blockPhxChangeWhileComposing || !1, this.serverCloseRef = null, this.domCallbacks = Object.assign(
      {
        jsQuerySelectorAll: null,
        onPatchStart: Tt(),
        onPatchEnd: Tt(),
        onNodeAdded: Tt(),
        onBeforeElUpdated: Tt()
      },
      i.dom || {}
    ), this.transitions = new Gi(), this.currentHistoryPosition = parseInt(this.sessionStorage.getItem(Ft) || "0") || 0, window.addEventListener("pagehide", (s) => {
      this.unloaded = !0;
    }), this.socket.onOpen(() => {
      this.isUnloaded() && window.location.reload();
    });
  }
  // public
  /**
   * Returns the version of the LiveView client.
   */
  version() {
    return "1.2.3";
  }
  /**
   * Returns true if profiling is enabled. See {@link enableProfiling} and {@link disableProfiling}.
   */
  isProfileEnabled() {
    return this.sessionStorage.getItem(Zt) === "true";
  }
  /**
   * Returns true if debugging is enabled. See {@link enableDebug} and {@link disableDebug}.
   */
  isDebugEnabled() {
    return this.sessionStorage.getItem(Ht) === "true";
  }
  /**
   * Returns true if debugging is disabled. See {@link enableDebug} and {@link disableDebug}.
   */
  isDebugDisabled() {
    return this.sessionStorage.getItem(Ht) === "false";
  }
  /**
   * Enables debugging.
   *
   * When debugging is enabled, the LiveView client will log debug information to the console.
   * See [Debugging client events](https://phoenix-live-view.hexdocs.pm/js-interop.html#debugging-client-events) for more information.
   */
  enableDebug() {
    this.sessionStorage.setItem(Ht, "true");
  }
  /**
   * Enables profiling.
   *
   * When profiling is enabled, the LiveView client will log profiling information to the console.
   */
  enableProfiling() {
    this.sessionStorage.setItem(Zt, "true");
  }
  /**
   * Disables debugging.
   */
  disableDebug() {
    this.sessionStorage.setItem(Ht, "false");
  }
  /**
   * Disables profiling.
   */
  disableProfiling() {
    this.sessionStorage.removeItem(Zt);
  }
  /**
   * Enables latency simulation.
   *
   * When latency simulation is enabled, the LiveView client will add a delay to requests and responses from the server.
   * See [Simulating Latency](https://phoenix-live-view.hexdocs.pm/js-interop.html#simulating-latency) for more information.
   */
  enableLatencySim(t) {
    this.enableDebug(), console.log(
      "latency simulator enabled for the duration of this browser session. Call disableLatencySim() to disable"
    ), this.sessionStorage.setItem(te, t.toString());
  }
  /**
   * Disables latency simulation.
   */
  disableLatencySim() {
    this.sessionStorage.removeItem(te);
  }
  /**
   * Returns the current latency simulation upper bound.
   */
  getLatencySim() {
    const t = this.sessionStorage.getItem(te);
    return t ? parseInt(t) : null;
  }
  /**
   * Returns the Phoenix Socket instance.
   */
  getSocket() {
    return this.socket;
  }
  /**
   * Connects to the LiveView server.
   */
  connect() {
    window.location.hostname === "localhost" && !this.isDebugDisabled() && this.enableDebug();
    const t = () => {
      this.resetReloadStatus(), this.joinRootViews() ? (this.bindTopLevelEvents(), this.socket.connect()) : this.main ? this.socket.connect() : this.bindTopLevelEvents({ dead: !0 }), this.joinDeadView();
    };
    ["complete", "loaded", "interactive"].indexOf(document.readyState) >= 0 ? t() : document.addEventListener("DOMContentLoaded", () => t());
  }
  /**
   * Disconnects from the LiveView server.
   */
  disconnect(t) {
    this.reloadWithJitterTimer != null && clearTimeout(this.reloadWithJitterTimer), this.serverCloseRef && (this.socket.off([this.serverCloseRef]), this.serverCloseRef = null), this.socket.disconnect(t);
  }
  /**
   * Can be used to replace the transport used by the underlying Phoenix Socket.
   */
  replaceTransport(t) {
    this.reloadWithJitterTimer != null && clearTimeout(this.reloadWithJitterTimer), this.socket.replaceTransport(t), this.connect();
  }
  /**
   * Executes an encoded JS command, targeting the given element.
   *
   * See [`Phoenix.LiveView.JS`](https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html) for more information.
   */
  execJS(t, e, i = null) {
    const s = new CustomEvent("phx:exec", { detail: { sourceElement: t } });
    this.owner(
      t,
      (r) => E.exec(s, i, e, r, t)
    );
  }
  /**
   * Returns an object with methods to manipulate the DOM and execute JavaScript.
   * The applied changes integrate with server DOM patching.
   *
   * See [JavaScript interoperability](https://phoenix-live-view.hexdocs.pm/js-interop.html) for more information.
   */
  js() {
    return ei(this, "js");
  }
  // private
  /** @internal */
  unload() {
    this.unloaded || (this.main && this.isConnected() && this.log(this.main, "socket", () => ["disconnect for page nav"]), this.unloaded = !0, this.destroyAllViews(), this.disconnect());
  }
  /** @internal */
  triggerDOM(t, e) {
    this.domCallbacks[t](...e);
  }
  /** @internal */
  time(t, e) {
    if (!this.isProfileEnabled() || !console.time)
      return e();
    console.time(t);
    const i = e();
    return console.timeEnd(t), i;
  }
  /** @internal */
  log(t, e, i) {
    if (this.viewLogger) {
      const [s, r] = i();
      this.viewLogger(t, e, s, r);
    } else if (this.isDebugEnabled()) {
      const [s, r] = i();
      ki(t, e, s, r);
    }
  }
  /** @internal */
  requestDOMUpdate(t) {
    this.transitions.after(t);
  }
  /** @internal */
  asyncTransition(t) {
    this.transitions.addAsyncTransition(t);
  }
  /** @internal */
  transition(t, e, i = function() {
  }) {
    this.transitions.addTransition(t, e, i);
  }
  /** @internal */
  // `data` is the raw wire payload pushed over the channel — dynamic JSON
  onChannel(t, e, i) {
    t.on(e, (s) => {
      const r = this.getLatencySim();
      r ? setTimeout(() => i(s), r) : i(s);
    });
  }
  /** @internal */
  reloadWithJitter(t, e) {
    this.reloadWithJitterTimer != null && clearTimeout(this.reloadWithJitterTimer), this.disconnect();
    const i = this.reloadJitterMin, s = this.reloadJitterMax;
    let r = Math.floor(Math.random() * (s - i + 1)) + i;
    const o = V.updateLocal(
      this.localStorage,
      window.location.pathname,
      ze,
      0,
      (a) => a + 1
    );
    o >= this.maxReloads && (r = this.failsafeJitter), this.reloadWithJitterTimer = setTimeout(() => {
      t.isDestroyed() || t.isConnected() || (t.destroy(), e ? e() : this.log(t, "join", () => [
        `encountered ${o} consecutive reloads`
      ]), o >= this.maxReloads && this.log(t, "join", () => [
        `exceeded ${this.maxReloads} consecutive reloads. Entering failsafe mode`
      ]), this.pendingLink !== null ? window.location.href = this.pendingLink : window.location.reload());
    }, r);
  }
  /** @internal */
  getHookDefinition(t) {
    if (t)
      return this.maybeInternalHook(t) || this.hooks[t] || this.maybeRuntimeHook(t);
  }
  /** @internal */
  maybeInternalHook(t) {
    return t && t.startsWith("Phoenix.") && Li[t.split(".")[1]];
  }
  /** @internal */
  maybeRuntimeHook(t) {
    const e = document.querySelector(
      `script[${jt}="${CSS.escape(t)}"]`
    );
    if (!e)
      return;
    let i = window[`phx_hook_${t}`];
    if (!i || typeof i != "function") {
      T("a runtime hook must be a function", e);
      return;
    }
    const s = i();
    if (s && (typeof s == "object" || typeof s == "function"))
      return s;
    T(
      "runtime hook must return an object with hook callbacks or an instance of ViewHook",
      e
    );
  }
  /** @internal */
  isUnloaded() {
    return this.unloaded;
  }
  /** @internal */
  isConnected() {
    return this.socket.isConnected();
  }
  /** @internal */
  getBindingPrefix() {
    return this.bindingPrefix;
  }
  /** @internal */
  binding(t) {
    return `${this.getBindingPrefix()}${t}`;
  }
  /** @internal */
  channel(t, e) {
    return this.socket.channel(t, e);
  }
  /** @internal */
  joinDeadView() {
    const t = document.body;
    if (t && !this.isPhxView(t) && !this.isPhxView(document.firstElementChild)) {
      const e = this.newRootView(t);
      e.setHref(this.getHref()), e.joinDead(), this.main || (this.main = e), window.requestAnimationFrame(() => {
        e.execNewMounted(), this.maybeScroll(history.state?.scroll);
      });
    }
  }
  /** @internal */
  joinRootViews() {
    let t = !1;
    return h.all(
      document,
      `${It}:not([${dt}])`,
      (e) => {
        if (!this.getRootById(e.id)) {
          const i = this.newRootView(e);
          h.isPhxSticky(e) || i.setHref(this.getHref()), i.join(), e.hasAttribute(fe) && (this.main = i);
        }
        t = !0;
      }
    ), t;
  }
  /** @internal */
  redirect(t, e, i) {
    i && V.setCookie(Pe, i, 60), this.unload(), V.redirect(t, e);
  }
  /** @internal */
  replaceMain(t, e, i = null, s = this.setPendingLink(t)) {
    if (!this.main)
      return;
    const r = this.currentLocation.href;
    this.outgoingMainEl = this.outgoingMainEl || this.main.el;
    const o = h.findPhxSticky(document) || [], a = h.all(
      this.outgoingMainEl,
      `[${this.binding("remove")}]`
    ).filter((f) => !h.isChildOfAny(f, o)), l = h.cloneNode(this.outgoingMainEl, ""), c = this.main;
    c.showLoader(this.loaderTimeout), c.destroy(), this.main = this.newRootView(l, e, r), this.main.setRedirect(t), this.transitionRemoves(a, c), this.main.join((f, p) => {
      f === 1 && this.commitPendingLink(s) && this.requestDOMUpdate(() => {
        a.forEach((m) => m.remove()), o.forEach((m) => l.appendChild(m)), this.outgoingMainEl.replaceWith(l), this.outgoingMainEl = null, i && i(s), p();
      });
    });
  }
  /** @internal */
  transitionRemoves(t, e, i) {
    const s = this.binding("remove"), r = (o) => {
      o.preventDefault(), o.stopImmediatePropagation();
    };
    t.forEach((o) => {
      for (const l of this.boundEventNames)
        o.addEventListener(l, r, !0);
      const a = new CustomEvent("phx:exec", { detail: { sourceElement: o } });
      E.exec(a, "remove", o.getAttribute(s), e, o);
    }), this.requestDOMUpdate(() => {
      t.forEach((o) => {
        for (const a of this.boundEventNames)
          o.removeEventListener(a, r, !0);
      }), i && i();
    });
  }
  /** @internal */
  isPhxView(t) {
    return t.getAttribute && t.getAttribute(Q) !== null;
  }
  /** @internal */
  newRootView(t, e, i) {
    const s = new qt(t, this, null, e, i);
    return this.roots[s.id] = s, s;
  }
  /** @internal */
  // callback return is forwarded opaquely to varied call sites — passthrough
  owner(t, e) {
    let i;
    const s = h.closestViewEl(t);
    if (s)
      i = h.private(s, "view");
    else {
      if (!t.isConnected)
        return null;
      i = this.main;
    }
    return i && e ? e(i) : i;
  }
  /** @internal */
  withinOwners(t, e) {
    this.owner(t, (i) => e(i, t));
  }
  /** @internal */
  getViewByEl(t) {
    const e = t.getAttribute(tt);
    return wt(
      this.getRootById(e),
      (i) => i.getDescendentByEl(t)
    );
  }
  /** @internal */
  getRootById(t) {
    return this.roots[t];
  }
  /** @internal */
  destroyAllViews() {
    for (const t in this.roots)
      this.roots[t].destroy(), delete this.roots[t];
    this.main = null;
  }
  /** @internal */
  destroyViewByEl(t) {
    const e = this.getRootById(t.getAttribute(tt));
    e && e.id === t.id ? (e.destroy(), delete this.roots[e.id]) : e && e.destroyDescendent(t.id);
  }
  /** @internal */
  getActiveElement() {
    return document.activeElement;
  }
  /** @internal */
  dropActiveElement(t) {
    this.prevActive && t.ownsElement(this.prevActive) && (this.prevActive = null);
  }
  /** @internal */
  restorePreviouslyActiveFocus() {
    this.prevActive && this.prevActive !== document.body && this.prevActive instanceof HTMLElement && this.prevActive.focus();
  }
  /** @internal */
  blurActiveElement() {
    this.prevActive = this.getActiveElement(), this.prevActive !== document.body && this.prevActive instanceof HTMLElement && this.prevActive.blur();
  }
  /** @internal */
  bindTopLevelEvents({ dead: t } = {}) {
    this.boundTopLevelEvents || (this.boundTopLevelEvents = !0, this.serverCloseRef = this.socket.onClose((e) => {
      if (e && e.code === 1e3 && this.main)
        return this.reloadWithJitter(this.main);
    }), document.body.addEventListener("click", function() {
    }), window.addEventListener(
      "pageshow",
      (e) => {
        e.persisted && (this.getSocket().disconnect(), this.withPageLoading({ to: window.location.href, kind: "redirect" }), window.location.reload());
      },
      !0
    ), t || this.bindNav(), this.bindClicks(), t || this.bindForms(), this.bind(
      { keyup: "keyup", keydown: "keydown" },
      (e, i, s, r, o, a) => {
        const l = r.getAttribute(this.binding(di)), c = e.key && e.key.toLowerCase();
        if (l && l.toLowerCase() !== c)
          return;
        const f = { key: e.key, ...this.eventMeta(i, e, r) };
        E.exec(e, i, o, s, r, [
          "push",
          { data: f }
        ]);
      }
    ), this.bind(
      { blur: "focusout", focus: "focusin" },
      (e, i, s, r, o, a) => {
        if (!a) {
          const l = { ...this.eventMeta(i, e, r) };
          E.exec(e, i, o, s, r, [
            "push",
            { data: l }
          ]);
        }
      }
    ), this.bind(
      { blur: "blur", focus: "focus" },
      (e, i, s, r, o, a) => {
        if (a === "window") {
          const l = this.eventMeta(i, e, r);
          E.exec(e, i, o, s, r, [
            "push",
            { data: l }
          ]);
        }
      }
    ), this.on("dragover", (e) => e.preventDefault()), this.on("dragenter", (e) => {
      let i = e.target && h.elementFromTarget(e.target);
      if (!i)
        return;
      const s = ht(i, this.binding(Dt));
      !s || !(s instanceof HTMLElement) || Ci(e) && this.js().addClass(s, Yt);
    }), this.on("dragleave", (e) => {
      let i = e.target && h.elementFromTarget(e.target);
      if (!i)
        return;
      const s = ht(i, this.binding(Dt));
      if (!s || !(s instanceof HTMLElement))
        return;
      const r = s.getBoundingClientRect();
      (e.clientX <= r.left || e.clientX >= r.right || e.clientY <= r.top || e.clientY >= r.bottom) && this.js().removeClass(s, Yt);
    }), this.on("drop", (e) => {
      let i = e.target && h.elementFromTarget(e.target);
      if (!i)
        return;
      e.preventDefault();
      const s = ht(i, this.binding(Dt));
      if (!s || !(s instanceof HTMLElement) || (this.js().removeClass(s, Yt), !e.dataTransfer))
        return;
      const r = s.getAttribute(this.binding(Dt)), o = r && document.getElementById(r), a = Array.from(e.dataTransfer.files || []);
      !o || !(o instanceof HTMLInputElement) || o.disabled || a.length === 0 || !(o.files instanceof FileList) || (L.trackFiles(o, a, e.dataTransfer), o.dispatchEvent(new Event("input", { bubbles: !0 })));
    }), this.on(Ye, (e) => {
      const i = e.target && h.elementFromTarget(e.target);
      if (!h.isUploadInput(i))
        return;
      const s = Array.from(e.detail.files || []).filter(
        (r) => r instanceof File || r instanceof Blob
      );
      L.trackFiles(
        i,
        s
      ), i.dispatchEvent(new Event("input", { bubbles: !0 }));
    }));
  }
  /** @internal */
  eventMeta(t, e, i) {
    const s = this.metadataCallbacks[t];
    return s ? s(e, i) : {};
  }
  /** @internal */
  setPendingLink(t) {
    return this.linkRef++, this.pendingLink = t, this.resetReloadStatus(), this.linkRef;
  }
  /**
   * @internal
   * anytime we are navigating or connecting, drop reload cookie in case
   * we issue the cookie but the next request was interrupted and the server never dropped it
   */
  resetReloadStatus() {
    V.deleteCookie(Pe);
  }
  /** @internal */
  commitPendingLink(t) {
    return this.linkRef !== t ? !1 : (this.pendingLink !== null && (this.href = this.pendingLink, this.pendingLink = null), !0);
  }
  /** @internal */
  getHref() {
    return this.href;
  }
  /** @internal */
  hasPendingLink() {
    return !!this.pendingLink;
  }
  /** @internal */
  bind(t, e) {
    for (const i in t) {
      const s = t[i];
      this.on(s, (r) => {
        const o = this.binding(i), a = this.binding(`window-${i}`), l = r.target instanceof Element && r.target.getAttribute(o);
        r.target instanceof Element && (l ? this.debounce(r.target, r, s, () => {
          this.withinOwners(r.target, (c) => {
            e(
              r,
              i,
              c,
              r.target,
              l,
              null
            );
          });
        }) : h.all(document, `[${a}]`, (c) => {
          const f = c.getAttribute(a);
          this.debounce(c, r, s, () => {
            this.withinOwners(c, (p) => {
              e(
                r,
                i,
                p,
                c,
                f,
                "window"
              );
            });
          });
        }));
      });
    }
  }
  /** @internal */
  bindClicks() {
    this.on("mousedown", (t) => this.clickStartedAtTarget = t.target), this.bindClick();
  }
  /** @internal */
  bindClick() {
    const t = this.binding("click");
    window.addEventListener(
      "click",
      (e) => {
        let i = e.target && h.elementFromTarget(e.target);
        if (!i)
          return;
        e.detail === 0 && (this.clickStartedAtTarget = i);
        const s = this.clickStartedAtTarget || i;
        if (i = ht(i, t), this.dispatchClickAway(e, s), this.clickStartedAtTarget = null, !i)
          return;
        const r = i.getAttribute(t);
        if (!r) {
          h.isNewPageClick(e, window.location) && this.unload();
          return;
        }
        i.getAttribute("href") === "#" && e.preventDefault(), !i.hasAttribute(W) && this.debounce(i, e, "click", () => {
          this.withinOwners(i, (o) => {
            E.exec(e, "click", r, o, i, [
              "push",
              { data: this.eventMeta("click", e, i) }
            ]);
          });
        });
      },
      !1
    );
  }
  /** @internal */
  // clickStartedAt arrives as an EventTarget but is used via Element APIs
  // (.closest/.contains/.isSameNode) — the boundary mismatch is intentional
  dispatchClickAway(t, e) {
    const i = this.binding("click-away"), s = e.closest(`[${at}]`), r = s && h.byId(s.getAttribute(at));
    h.all(document, `[${i}]`, (o) => {
      let a = e;
      s && !s.contains(o) && (a = r), o.isSameNode(a) || o.contains(a) || // When clicking a link with custom method,
      // phoenix_html triggers a click on a submit button
      // of a hidden form appended to the body. For such cases
      // where the clicked target is hidden, we skip click-away.
      //
      // Also, when we have a portal, we don't want to check the visibility
      // of the portal source, as it's a <template> that is always not visible.
      // Instead, check the visibility of the original click target.
      !E.isVisible(e) || this.withinOwners(o, (l) => {
        const c = o.getAttribute(i);
        E.isVisible(o) && E.isInViewport(o) && E.exec(t, "click", c, l, o, [
          "push",
          { data: this.eventMeta("click", t, t.target) }
        ]);
      });
    });
  }
  /** @internal */
  bindNav() {
    if (!V.canPushState())
      return;
    history.scrollRestoration && (history.scrollRestoration = "manual");
    let t = null;
    window.addEventListener("scroll", (e) => {
      t != null && clearTimeout(t), t = setTimeout(() => {
        V.updateCurrentState(
          (i) => Object.assign(i, { scroll: window.scrollY })
        );
      }, 100);
    }), window.addEventListener(
      "popstate",
      (e) => {
        if (!this.registerNewLocation(window.location))
          return;
        const { type: i, backType: s, id: r, scroll: o, position: a } = e.state || {}, l = window.location.href, c = a > this.currentHistoryPosition, f = c ? i : s || i;
        this.currentHistoryPosition = a || 0, this.sessionStorage.setItem(
          Ft,
          this.currentHistoryPosition.toString()
        ), h.dispatchEvent(window, "phx:navigate", {
          detail: {
            href: l,
            patch: f === "patch",
            pop: !0,
            direction: c ? "forward" : "backward"
          }
        }), this.requestDOMUpdate(() => {
          const p = () => {
            this.maybeScroll(o);
          };
          this.main && this.main.isConnected() && f === "patch" && r === this.main.id ? this.main.pushLinkPatch(e, l, null, p) : this.replaceMain(l, null, p);
        });
      },
      !1
    ), window.addEventListener(
      "click",
      (e) => {
        let i = e.target && h.elementFromTarget(e.target);
        if (!i)
          return;
        const s = ht(
          i,
          Qt
        ), r = s && s.getAttribute(Qt);
        if (!r || !this.isConnected() || !this.main || h.wantsNewTab(e))
          return;
        const o = s.href instanceof SVGAnimatedString ? s.href.baseVal : s.href, a = s.getAttribute(we);
        if (a !== "replace" && a !== "push")
          throw new Error(
            `expected ${we} to be "replace" or "push", got: ${a}`
          );
        e.preventDefault(), e.stopImmediatePropagation(), this.pendingLink !== o && this.requestDOMUpdate(() => {
          if (r === "patch")
            this.pushHistoryPatch(e, o, a, s);
          else if (r === "redirect")
            this.historyRedirect(e, o, a, null, s);
          else
            throw new Error(
              `expected ${Qt} to be "patch" or "redirect", got: ${r}`
            );
          const l = s.getAttribute(this.binding("click"));
          l && this.requestDOMUpdate(() => this.execJS(s, l, "click"));
        });
      },
      !1
    );
  }
  /** @internal */
  maybeScroll(t) {
    typeof t == "number" && requestAnimationFrame(() => {
      window.scrollTo(0, t);
    });
  }
  /** @internal */
  dispatchEvent(t, e = {}) {
    h.dispatchEvent(window, `phx:${t}`, { detail: e });
  }
  /** @internal */
  dispatchEvents(t) {
    t.forEach(([e, i]) => this.dispatchEvent(e, i));
  }
  /** @internal */
  // `info` is forwarded as a page-loading event detail — dynamic payload;
  // callback return is forwarded opaquely to the caller — passthrough
  withPageLoading(t, e) {
    h.dispatchEvent(window, "phx:page-loading-start", { detail: t });
    const i = () => h.dispatchEvent(window, "phx:page-loading-stop", { detail: t });
    return e ? e(i) : i;
  }
  /** @internal */
  pushHistoryPatch(t, e, i, s) {
    if (!this.isConnected() || !(this.main && this.main.isMain()))
      return V.redirect(e);
    this.withPageLoading({ to: e, kind: "patch" }, (r) => {
      this.main.pushLinkPatch(t, e, s, (o) => {
        this.historyPatch(e, i, o), r();
      });
    });
  }
  /** @internal */
  historyPatch(t, e, i = this.setPendingLink(t)) {
    this.commitPendingLink(i) && (this.currentHistoryPosition++, this.sessionStorage.setItem(
      Ft,
      this.currentHistoryPosition.toString()
    ), V.updateCurrentState((s) => ({ ...s, backType: "patch" })), V.pushState(
      e,
      {
        type: "patch",
        id: this.main.id,
        position: this.currentHistoryPosition
      },
      t
    ), h.dispatchEvent(window, "phx:navigate", {
      detail: { patch: !0, href: t, pop: !1, direction: "forward" }
    }), this.registerNewLocation(window.location));
  }
  /** @internal */
  historyRedirect(t, e, i, s, r) {
    const o = r && t.isTrusted && t.type !== "popstate";
    if (o && r.classList.add("phx-click-loading"), !this.isConnected() || !(this.main && this.main.isMain()))
      return V.redirect(e, s);
    if (/^\/$|^\/[^\/]+.*$/.test(e)) {
      const { protocol: l, host: c } = window.location;
      e = `${l}//${c}${e}`;
    }
    const a = window.scrollY;
    this.withPageLoading({ to: e, kind: "redirect" }, (l) => {
      this.replaceMain(e, s, (c) => {
        c === this.linkRef && (this.currentHistoryPosition++, this.sessionStorage.setItem(
          Ft,
          this.currentHistoryPosition.toString()
        ), V.updateCurrentState((f) => ({
          ...f,
          backType: "redirect"
        })), V.pushState(
          i,
          {
            type: "redirect",
            id: this.main.id,
            scroll: a,
            position: this.currentHistoryPosition
          },
          e
        ), h.dispatchEvent(window, "phx:navigate", {
          detail: { href: e, patch: !1, pop: !1, direction: "forward" }
        }), this.registerNewLocation(window.location)), o && r.classList.remove("phx-click-loading"), l();
      });
    });
  }
  /** @internal */
  registerNewLocation(t) {
    const { pathname: e, search: i } = this.currentLocation;
    return e + i === t.pathname + t.search ? !1 : (this.currentLocation = Vt(t), !0);
  }
  /** @internal */
  bindForms() {
    let t = 0, e = !1;
    this.on("submit", (i) => {
      if (!(i.target instanceof HTMLFormElement)) return;
      const s = i.target.getAttribute(this.binding("submit")), r = i.target.getAttribute(this.binding("change"));
      !e && r && !s && (e = !0, i.preventDefault(), this.withinOwners(i.target, (o) => {
        o.disableForm(i.target), window.requestAnimationFrame(() => {
          h.isUnloadableFormSubmit(i) && this.unload(), i.target.submit();
        });
      }));
    }), this.on("submit", (i) => {
      if (!(i.target instanceof HTMLFormElement)) return;
      const s = i.target.getAttribute(this.binding("submit"));
      if (!s) {
        h.isUnloadableFormSubmit(i) && this.unload();
        return;
      }
      i.preventDefault(), i.target.disabled = !0, this.withinOwners(i.target, (r) => {
        E.exec(i, "submit", s, r, i.target, [
          "push",
          { submitter: i.submitter }
        ]);
      });
    });
    for (const i of ["change", "input"])
      this.on(i, (s) => {
        if (!h.isFormAssociated(s.target))
          return;
        if (s instanceof CustomEvent && s.target.form === void 0) {
          if (s.detail && s.detail.dispatcher)
            throw new Error(
              `dispatching a custom ${i} event is only supported on input elements inside a form`
            );
          return;
        }
        const r = s.target, o = this.binding("change");
        if (this.blockPhxChangeWhileComposing && s instanceof InputEvent && s.isComposing) {
          const d = `composition-listener-${i}`;
          h.private(r, d) || (h.putPrivate(r, d, !0), r.addEventListener(
            "compositionend",
            () => {
              r.dispatchEvent(new Event(i, { bubbles: !0 })), h.deletePrivate(r, d);
            },
            { once: !0 }
          ));
          return;
        }
        const a = r.getAttribute(o), l = r.form && r.form.getAttribute(o), c = a || l;
        if (!c || r.type === "number" && r.validity && r.validity.badInput)
          return;
        const f = a ? r : r.form, p = t;
        t++;
        const { at: m, type: g } = h.private(r, "prev-iteration") || {};
        m === p - 1 && i === "change" && g === "input" || (h.putPrivate(r, "prev-iteration", {
          at: p,
          type: i
        }), this.debounce(r, s, i, () => {
          this.withinOwners(f, (d) => {
            h.putPrivate(r, Jt, !0), E.exec(s, "change", c, d, r, [
              "push",
              { _target: r.name, dispatcher: f }
            ]);
          });
        }));
      });
    this.on("reset", (i) => {
      const s = i.target;
      h.resetForm(s);
      const r = Array.from(s.elements).find(
        (o) => "type" in o && o.type === "reset"
      );
      r && window.requestAnimationFrame(() => {
        r.dispatchEvent(
          new Event("input", { bubbles: !0, cancelable: !1 })
        );
      });
    });
  }
  /** @internal */
  debounce(t, e, i, s) {
    if (i === "blur" || i === "focusout")
      return s();
    const r = this.binding(li), o = this.binding(hi), a = this.defaults.debounce.toString(), l = this.defaults.throttle.toString();
    this.withinOwners(t, (c) => {
      const f = () => !c.isDestroyed() && document.body.contains(t);
      h.debounce(
        t,
        e,
        r,
        a,
        o,
        l,
        f,
        () => {
          s();
        }
      );
    });
  }
  /** @internal */
  silenceEvents(t) {
    this.silenced = !0, t(), this.silenced = !1;
  }
  /** @internal */
  on(t, e) {
    this.boundEventNames.add(t), window.addEventListener(t, (i) => {
      this.silenced || e(i);
    });
  }
  /** @internal */
  jsQuerySelectorAll(t, e, i) {
    const s = this.domCallbacks.jsQuerySelectorAll;
    return s ? s(t, e, i) : i();
  }
}
class Gi {
  transitions;
  promises;
  pendingOps;
  constructor() {
    this.transitions = /* @__PURE__ */ new Set(), this.promises = /* @__PURE__ */ new Set(), this.pendingOps = [];
  }
  reset() {
    this.transitions.forEach((t) => {
      clearTimeout(t), this.transitions.delete(t);
    }), this.promises.clear(), this.flushPendingOps();
  }
  after(t) {
    this.size() === 0 ? t() : this.pushPendingOp(t);
  }
  addTransition(t, e, i) {
    e();
    const s = setTimeout(() => {
      this.transitions.delete(s), i(), this.flushPendingOps();
    }, t);
    this.transitions.add(s);
  }
  addAsyncTransition(t) {
    this.promises.add(t), t.then(() => {
      this.promises.delete(t), this.flushPendingOps();
    });
  }
  pushPendingOp(t) {
    this.pendingOps.push(t);
  }
  size() {
    return this.transitions.size + this.promises.size;
  }
  flushPendingOps() {
    if (this.size() > 0)
      return;
    const t = this.pendingOps.shift();
    t && (t(), this.flushPendingOps());
  }
}
function Zi(n, t) {
  let e = h.getCustomElHook(n);
  if (e)
    return e;
  n.hasAttribute("id") || T(
    "Elements passed to createHook need to have a unique id attribute",
    n
  );
  let i = new G(qt.closestView(n), n, t);
  return h.putCustomElHook(n, i), i;
}
function ts(n, t) {
  return L.getEntryDataURL(n, t);
}
export {
  Qi as LiveSocket,
  G as ViewHook,
  Zi as createHook,
  ts as getFileURLForUpload,
  Yi as isUsedInput
};
