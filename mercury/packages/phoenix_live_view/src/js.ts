import DOM from "./dom";
import ARIA from "./aria";

const focusStack: HTMLElement[] = [];
const default_transition_time = 200;

// The cross-boundary internal View / LiveSocket instances (default-exported classes in
// view.ts / live_socket.ts). Kept structurally open (any) to avoid coupling this command
// table to those modules and the cascade a hard import would cause.
type ViewLike = any;
type LiveSocketLike = any;
// A JS-command spec arriving over the wire as raw JSON (string or nested arrays) — dynamic, untypeable.
type PhxEvent = any;
// A single JS-command's argument bundle (also raw wire JSON), e.g. { names, transition, time, blocking }.
type CommandArgs = any;
// The opaque component-context value carried across the View boundary (a cid/target tuple) — passed through, never inspected here.
type TargetCtx = any;

const JS = {
  // private
  exec(
    e: Event,
    eventType: string | null,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    defaults?: CommandArgs,
  ) {
    const [defaultKind, defaultArgs] = defaults || [
      null,
      { callback: defaults && defaults.callback },
    ];
    const commands = Array.isArray(phxEvent)
      ? phxEvent
      : typeof phxEvent === "string" && phxEvent.startsWith("[")
        ? JSON.parse(phxEvent)
        : [[defaultKind, defaultArgs]];

    // args is the wire command's argument bundle — dynamic JSON, untypeable
    commands.forEach(([kind, args]: [string, any]) => {
      if (kind === defaultKind) {
        // always prefer the args, but keep existing keys from the defaultArgs
        args = { ...defaultArgs, ...args };
        args.callback = args.callback || defaultArgs.callback;
      }
      this.filterToEls(view.liveSocket, sourceEl, args).forEach(
        (el: HTMLElement) => {
          // dynamic dispatch onto exec_<kind> — the method name is computed from wire data
          (this as any)[`exec_${kind}`](
            e,
            eventType,
            phxEvent,
            view,
            sourceEl,
            el,
            args,
          );
        },
      );
    });
  },

  isVisible(el: HTMLElement) {
    return !!(
      el.offsetWidth ||
      el.offsetHeight ||
      el.getClientRects().length > 0
    );
  },

  // returns true if any part of the element is inside the viewport
  isInViewport(el: HTMLElement) {
    const rect = el.getBoundingClientRect();
    const windowHeight =
      window.innerHeight || document.documentElement.clientHeight;
    const windowWidth =
      window.innerWidth || document.documentElement.clientWidth;

    return (
      rect.right > 0 &&
      rect.bottom > 0 &&
      rect.left < windowWidth &&
      rect.top < windowHeight
    );
  },

  // private

  // commands

  exec_exec(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
    { attr, to }: CommandArgs,
  ) {
    const encodedJS = el.getAttribute(attr);
    if (!encodedJS) {
      throw new Error(`expected ${attr} to contain JS command on "${to}"`);
    }
    view.liveSocket.execJS(el, encodedJS, eventType);
  },

  exec_dispatch(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
    { event, detail, bubbles, blocking }: CommandArgs,
  ) {
    detail = detail || {};
    detail.dispatcher = sourceEl;
    if (blocking) {
      const promise = new Promise((resolve, _reject) => {
        detail.done = resolve;
      });
      view.liveSocket.asyncTransition(promise);
    }
    DOM.dispatchEvent(el, event, { detail, bubbles });
  },

  exec_push(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
    args: CommandArgs,
  ) {
    const {
      event,
      data,
      target,
      page_loading,
      loading,
      value,
      dispatcher,
      callback,
    } = args;
    const pushOpts: Record<string, unknown> = {
      loading,
      value,
      target,
      page_loading: !!page_loading,
      originalEvent: e,
    };
    const targetSrc =
      eventType === "change" && dispatcher ? dispatcher : sourceEl;
    const phxTarget =
      target || targetSrc.getAttribute(view.binding("target")) || targetSrc;
    const handler = (targetView: ViewLike, targetCtx: TargetCtx) => {
      if (!targetView.isConnected()) {
        return;
      }
      if (eventType === "change") {
        let { newCid, _target } = args;
        _target =
          _target ||
          (DOM.isFormAssociated(sourceEl)
            ? (sourceEl as HTMLInputElement).name
            : undefined);
        if (_target) {
          pushOpts._target = _target;
        }
        targetView.pushInput(
          sourceEl,
          targetCtx,
          newCid,
          event || phxEvent,
          pushOpts,
          callback,
        );
      } else if (eventType === "submit") {
        const { submitter } = args;
        targetView.submitForm(
          sourceEl,
          targetCtx,
          event || phxEvent,
          submitter,
          pushOpts,
          callback,
        );
      } else {
        targetView.pushEvent(
          eventType,
          sourceEl,
          targetCtx,
          event || phxEvent,
          data,
          pushOpts,
          callback,
        );
      }
    };
    // in case of formRecovery, targetView and targetCtx are passed as argument
    // as they are looked up in a template element, not the real DOM
    if (args.targetView && args.targetCtx) {
      handler(args.targetView, args.targetCtx);
    } else {
      view.withinTargets(phxTarget, handler);
    }
  },

  exec_navigate(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
    { href, replace }: CommandArgs,
  ) {
    view.liveSocket.historyRedirect(
      e,
      href,
      replace ? "replace" : "push",
      null,
      sourceEl,
    );
  },

  exec_patch(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
    { href, replace }: CommandArgs,
  ) {
    view.liveSocket.pushHistoryPatch(
      e,
      href,
      replace ? "replace" : "push",
      sourceEl,
    );
  },

  exec_focus(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
  ) {
    ARIA.attemptFocus(el);
    // in case the JS.focus command is in a JS.show/hide/toggle chain, for show we need
    // to wait for JS.show to have updated the element's display property (see exec_toggle)
    // but that run in nested animation frames, therefore we need to use them here as well
    window.requestAnimationFrame(() => {
      window.requestAnimationFrame(() => ARIA.attemptFocus(el));
    });
  },

  exec_focus_first(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
  ) {
    ARIA.focusFirstInteractive(el) || ARIA.focusFirst(el);
    // if you wonder about the nested animation frames, see exec_focus
    window.requestAnimationFrame(() => {
      window.requestAnimationFrame(
        () => ARIA.focusFirstInteractive(el) || ARIA.focusFirst(el),
      );
    });
  },

  exec_push_focus(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
  ) {
    focusStack.push(el || sourceEl);
  },

  exec_pop_focus(
    _e: Event,
    _eventType: string,
    _phxEvent: PhxEvent,
    _view: ViewLike,
    _sourceEl: HTMLElement,
    _el: HTMLElement,
  ) {
    const el = focusStack.pop();
    if (el) {
      el.focus();
      // if you wonder about the nested animation frames, see exec_focus
      window.requestAnimationFrame(() => {
        window.requestAnimationFrame(() => el.focus());
      });
    }
  },

  exec_add_class(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
    { names, transition, time, blocking }: CommandArgs,
  ) {
    this.addOrRemoveClasses(el, names, [], transition, time, view, blocking);
  },

  exec_remove_class(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
    { names, transition, time, blocking }: CommandArgs,
  ) {
    this.addOrRemoveClasses(el, [], names, transition, time, view, blocking);
  },

  exec_toggle_class(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
    { names, transition, time, blocking }: CommandArgs,
  ) {
    this.toggleClasses(el, names, transition, time, view, blocking);
  },

  exec_toggle_attr(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
    { attr: [attr, val1, val2] }: CommandArgs,
  ) {
    this.toggleAttr(el, attr, val1, val2);
  },

  exec_ignore_attrs(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
    { attrs }: CommandArgs,
  ) {
    this.ignoreAttrs(el, attrs);
  },

  exec_transition(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
    { time, transition, blocking }: CommandArgs,
  ) {
    this.addOrRemoveClasses(el, [], [], transition, time, view, blocking);
  },

  exec_toggle(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
    { display, ins, outs, time, blocking }: CommandArgs,
  ) {
    this.toggle(eventType, view, el, display, ins, outs, time, blocking);
  },

  exec_show(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
    { display, transition, time, blocking }: CommandArgs,
  ) {
    this.show(eventType, view, el, display, transition, time, blocking);
  },

  exec_hide(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
    { display, transition, time, blocking }: CommandArgs,
  ) {
    this.hide(eventType, view, el, display, transition, time, blocking);
  },

  exec_set_attr(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
    { attr: [attr, val] }: CommandArgs,
  ) {
    this.setOrRemoveAttrs(el, [[attr, val]], []);
  },

  exec_remove_attr(
    e: Event,
    eventType: string,
    phxEvent: PhxEvent,
    view: ViewLike,
    sourceEl: HTMLElement,
    el: HTMLElement,
    { attr }: CommandArgs,
  ) {
    this.setOrRemoveAttrs(el, [], [attr]);
  },

  ignoreAttrs(el: HTMLElement, attrs: unknown[]) {
    DOM.putPrivate(el, "JS:ignore_attrs", {
      apply: (fromEl: HTMLElement, toEl: HTMLElement) => {
        let fromAttributes = Array.from(fromEl.attributes);
        let fromAttributeNames = fromAttributes.map((attr) => attr.name);
        Array.from(toEl.attributes)
          .filter((attr) => {
            return !fromAttributeNames.includes(attr.name);
          })
          .forEach((attr) => {
            if (DOM.attributeIgnored(attr, attrs)) {
              toEl.removeAttribute(attr.name);
            }
          });
        fromAttributes.forEach((attr) => {
          if (DOM.attributeIgnored(attr, attrs)) {
            toEl.setAttribute(attr.name, attr.value);
          }
        });
      },
    });
  },

  onBeforeElUpdated(fromEl: HTMLElement, toEl: HTMLElement) {
    const ignoreAttrs = DOM.private(fromEl, "JS:ignore_attrs");
    if (ignoreAttrs) {
      ignoreAttrs.apply(fromEl, toEl);
    }
  },

  // utils for commands

  show(
    eventType: string | null,
    view: ViewLike,
    el: HTMLElement,
    display: string | null | undefined,
    // transition is the dynamic [run, start, end] class triple from the wire — kept any so the
    // empty-array `[].concat(...)` accumulation downstream type-checks unchanged.
    transition: any,
    time: number | null | undefined,
    blocking: boolean | undefined,
  ) {
    if (!this.isVisible(el)) {
      this.toggle(
        eventType,
        view,
        el,
        display,
        transition,
        null,
        time,
        blocking,
      );
    }
  },

  hide(
    eventType: string | null,
    view: ViewLike,
    el: HTMLElement,
    display: string | null | undefined,
    // transition: dynamic wire [run, start, end] class triple — kept any for the `[].concat(...)` pattern.
    transition: any,
    time: number | null | undefined,
    blocking: boolean | undefined,
  ) {
    if (this.isVisible(el)) {
      this.toggle(
        eventType,
        view,
        el,
        display,
        null,
        transition,
        time,
        blocking,
      );
    }
  },

  toggle(
    eventType: string | null,
    view: ViewLike,
    el: HTMLElement,
    display: string | null | undefined,
    // ins/outs are dynamic wire [run, start, end] class triples — kept any so the empty-array
    // `[].concat(...)` / inner `.concat()` accumulation downstream type-checks unchanged.
    ins: any,
    outs: any,
    time: number | null | undefined,
    blocking: boolean | undefined,
  ) {
    time = time || default_transition_time;
    const [inClasses, inStartClasses, inEndClasses] = ins || [[], [], []];
    const [outClasses, outStartClasses, outEndClasses] = outs || [[], [], []];
    if (inClasses.length > 0 || outClasses.length > 0) {
      if (this.isVisible(el)) {
        const onStart = () => {
          this.addOrRemoveClasses(
            el,
            outStartClasses,
            inClasses.concat(inStartClasses).concat(inEndClasses),
          );
          window.requestAnimationFrame(() => {
            this.addOrRemoveClasses(el, outClasses, []);
            window.requestAnimationFrame(() =>
              this.addOrRemoveClasses(el, outEndClasses, outStartClasses),
            );
          });
        };
        const onEnd = () => {
          this.addOrRemoveClasses(el, [], outClasses.concat(outEndClasses));
          DOM.putSticky(
            el,
            "toggle",
            (currentEl: HTMLElement) => (currentEl.style.display = "none"),
          );
          el.dispatchEvent(new Event("phx:hide-end"));
        };
        el.dispatchEvent(new Event("phx:hide-start"));
        if (blocking === false) {
          onStart();
          setTimeout(onEnd, time);
        } else {
          view.transition(time, onStart, onEnd);
        }
      } else {
        if (eventType === "remove") {
          return;
        }
        const onStart = () => {
          this.addOrRemoveClasses(
            el,
            inStartClasses,
            outClasses.concat(outStartClasses).concat(outEndClasses),
          );
          const stickyDisplay = display || this.defaultDisplay(el);
          window.requestAnimationFrame(() => {
            // first add the starting + active class, THEN make the element visible
            // otherwise if we toggled the visibility earlier css animations
            // would flicker, as the element becomes visible before the active animation
            // class is set (see https://github.com/phoenixframework/phoenix_live_view/issues/3456)
            this.addOrRemoveClasses(el, inClasses, []);
            // addOrRemoveClasses uses a requestAnimationFrame itself, therefore we need to move the putSticky
            // into the next requestAnimationFrame...
            window.requestAnimationFrame(() => {
              DOM.putSticky(
                el,
                "toggle",
                (currentEl: HTMLElement) => (currentEl.style.display = stickyDisplay),
              );
              this.addOrRemoveClasses(el, inEndClasses, inStartClasses);
            });
          });
        };
        const onEnd = () => {
          this.addOrRemoveClasses(el, [], inClasses.concat(inEndClasses));
          el.dispatchEvent(new Event("phx:show-end"));
        };
        el.dispatchEvent(new Event("phx:show-start"));
        if (blocking === false) {
          onStart();
          setTimeout(onEnd, time);
        } else {
          view.transition(time, onStart, onEnd);
        }
      }
    } else {
      if (this.isVisible(el)) {
        window.requestAnimationFrame(() => {
          el.dispatchEvent(new Event("phx:hide-start"));
          DOM.putSticky(
            el,
            "toggle",
            (currentEl: HTMLElement) => (currentEl.style.display = "none"),
          );
          el.dispatchEvent(new Event("phx:hide-end"));
        });
      } else {
        window.requestAnimationFrame(() => {
          el.dispatchEvent(new Event("phx:show-start"));
          const stickyDisplay = display || this.defaultDisplay(el);
          DOM.putSticky(
            el,
            "toggle",
            (currentEl: HTMLElement) => (currentEl.style.display = stickyDisplay),
          );
          el.dispatchEvent(new Event("phx:show-end"));
        });
      }
    }
  },

  toggleClasses(
    el: HTMLElement,
    classes: string[],
    // transition: dynamic wire [run, start, end] class triple — kept any for the `[].concat(...)` pattern.
    transition: any,
    time: number | null | undefined,
    view: ViewLike,
    blocking: boolean | undefined,
  ) {
    window.requestAnimationFrame(() => {
      const [prevAdds, prevRemoves] = DOM.getSticky(el, "classes", [[], []]);
      const newAdds = classes.filter(
        (name) => prevAdds.indexOf(name) < 0 && !el.classList.contains(name),
      );
      const newRemoves = classes.filter(
        (name) => prevRemoves.indexOf(name) < 0 && el.classList.contains(name),
      );
      this.addOrRemoveClasses(
        el,
        newAdds,
        newRemoves,
        transition,
        time,
        view,
        blocking,
      );
    });
  },

  toggleAttr(el: HTMLElement, attr: string, val1: string, val2?: string) {
    if (el.hasAttribute(attr)) {
      if (val2 !== undefined) {
        // toggle between val1 and val2
        if (el.getAttribute(attr) === val1) {
          this.setOrRemoveAttrs(el, [[attr, val2]], []);
        } else {
          this.setOrRemoveAttrs(el, [[attr, val1]], []);
        }
      } else {
        // remove attr
        this.setOrRemoveAttrs(el, [], [attr]);
      }
    } else {
      this.setOrRemoveAttrs(el, [[attr, val1]], []);
    }
  },

  addOrRemoveClasses(
    el: HTMLElement,
    adds: string[],
    removes: string[],
    // transition: dynamic wire [run, start, end] class triple — kept any so the empty-array
    // `[].concat(transitionRun)` accumulation below type-checks unchanged.
    transition?: any,
    time?: number | null,
    view?: ViewLike,
    blocking?: boolean | undefined,
  ) {
    time = time || default_transition_time;
    const [transitionRun, transitionStart, transitionEnd] = transition || [
      [],
      [],
      [],
    ];
    if (transitionRun.length > 0) {
      const onStart = () => {
        this.addOrRemoveClasses(
          el,
          transitionStart,
          [].concat(transitionRun).concat(transitionEnd),
        );
        window.requestAnimationFrame(() => {
          this.addOrRemoveClasses(el, transitionRun, []);
          window.requestAnimationFrame(() =>
            this.addOrRemoveClasses(el, transitionEnd, transitionStart),
          );
        });
      };
      const onDone = () =>
        this.addOrRemoveClasses(
          el,
          adds.concat(transitionEnd),
          removes.concat(transitionRun).concat(transitionStart),
        );
      if (blocking === false) {
        onStart();
        setTimeout(onDone, time);
      } else {
        view.transition(time, onStart, onDone);
      }
      return;
    }

    window.requestAnimationFrame(() => {
      const [prevAdds, prevRemoves] = DOM.getSticky(el, "classes", [[], []]);
      const keepAdds = adds.filter(
        (name) => prevAdds.indexOf(name) < 0 && !el.classList.contains(name),
      );
      const keepRemoves = removes.filter(
        (name) => prevRemoves.indexOf(name) < 0 && el.classList.contains(name),
      );
      const newAdds = prevAdds
        .filter((name: string) => removes.indexOf(name) < 0)
        .concat(keepAdds);
      const newRemoves = prevRemoves
        .filter((name: string) => adds.indexOf(name) < 0)
        .concat(keepRemoves);

      DOM.putSticky(el, "classes", (currentEl: HTMLElement) => {
        currentEl.classList.remove(...newRemoves);
        currentEl.classList.add(...newAdds);
        return [newAdds, newRemoves];
      });
    });
  },

  setOrRemoveAttrs(
    el: HTMLElement,
    sets: [string, string][],
    removes: string[],
  ) {
    const [prevSets, prevRemoves] = DOM.getSticky(el, "attrs", [[], []]);

    const alteredAttrs = sets.map(([attr, _val]) => attr).concat(removes);
    const newSets = prevSets
      .filter(([attr, _val]: [string, string]) => !alteredAttrs.includes(attr))
      .concat(sets);
    const newRemoves = prevRemoves
      .filter((attr: string) => !alteredAttrs.includes(attr))
      .concat(removes);

    // If element ID is touched via JavaScript, mark it for cheap lookup during morphdom
    if (sets.some(([attr, _val]) => attr === "id")) {
      DOM.putPrivate(el, "clientsideIdAttribute", true);
    }

    DOM.putSticky(el, "attrs", (currentEl: HTMLElement) => {
      newRemoves.forEach((attr: string) => currentEl.removeAttribute(attr));
      newSets.forEach(([attr, val]: [string, string]) =>
        currentEl.setAttribute(attr, val),
      );
      return [newSets, newRemoves];
    });
  },

  hasAllClasses(el: HTMLElement, classes: string[]) {
    return classes.every((name) => el.classList.contains(name));
  },

  isToggledOut(el: HTMLElement, outClasses: string[]) {
    return !this.isVisible(el) || this.hasAllClasses(el, outClasses);
  },

  filterToEls(
    liveSocket: LiveSocketLike,
    sourceEl: HTMLElement,
    { to }: CommandArgs,
  ) {
    const defaultQuery = () => {
      if (typeof to === "string") {
        return document.querySelectorAll(to);
      } else if (to.closest) {
        const toEl = sourceEl.closest(to.closest);
        return toEl ? [toEl] : [];
      } else if (to.inner) {
        return sourceEl.querySelectorAll(to.inner);
      }
    };
    return to
      ? liveSocket.jsQuerySelectorAll(sourceEl, to, defaultQuery)
      : [sourceEl];
  },

  defaultDisplay(el: HTMLElement) {
    return (
      ({ tr: "table-row", td: "table-cell" } as { [tag: string]: string })[
        el.tagName.toLowerCase()
      ] || "block"
    );
  },

  // val is the raw wire transition value: a space-delimited class string OR a nested
  // [run, start, end] array whose elements are themselves string-or-array — genuinely dynamic, kept any.
  transitionClasses(val: any) {
    if (!val) {
      return null;
    }

    let [trans, tStart, tEnd] = Array.isArray(val)
      ? val
      : [val.split(" "), [], []];
    trans = Array.isArray(trans) ? trans : trans.split(" ");
    tStart = Array.isArray(tStart) ? tStart : tStart.split(" ");
    tEnd = Array.isArray(tEnd) ? tEnd : tEnd.split(" ");
    return [trans, tStart, tEnd];
  },
};

export default JS;
