import {
  CHECKABLE_INPUTS,
  DEBOUNCE_PREV_KEY,
  DEBOUNCE_TRIGGER,
  FOCUSABLE_INPUTS,
  PHX_COMPONENT,
  PHX_VIEW_REF,
  PHX_TELEPORTED_REF,
  PHX_HAS_FOCUSED,
  PHX_HAS_SUBMITTED,
  PHX_MAIN,
  PHX_PARENT_ID,
  PHX_PRIVATE,
  PHX_REF_SRC,
  PHX_REF_LOCK,
  PHX_PENDING_ATTRS,
  PHX_ROOT_ID,
  PHX_SESSION,
  PHX_STATIC,
  PHX_UPLOAD_REF,
  PHX_VIEW_SELECTOR,
  PHX_STICKY,
  PHX_EVENT_CLASSES,
  THROTTLED,
  PHX_PORTAL,
  PHX_STREAM,
} from "./constants";

import { logError } from "./utils";

export type FormInputLike = HTMLElement & {
  readonly form?: HTMLFormElement | null;
  readonly type?: string;
  readonly validity?: ValidityState;
  readonly name?: string;
};

export type QueryableNode = Element | Document | DocumentFragment;

const DOM = {
  byId(id: string | null) {
    return document.getElementById(id!) || logError(`no id found for ${id}`);
  },

  elementFromTarget(target: EventTarget): Element | null {
    if (!(target instanceof Node)) {
      return null;
    }
    if (target.nodeType === Node.ELEMENT_NODE) {
      return target as Element;
    } else {
      return target.parentElement;
    }
  },

  removeClass(el: Element, className: string) {
    el.classList.remove(className);
    if (el.classList.length === 0) {
      el.removeAttribute("class");
    }
  },

  all(
    node: QueryableNode | null,
    query: string,
    callback?: (el: Element) => void,
  ): Element[] {
    if (!node) {
      return [];
    }
    const array = Array.from(node.querySelectorAll(query));
    if (callback) {
      array.forEach(callback);
    }
    return array;
  },

  childNodeLength(html: string) {
    const template = document.createElement("template");
    template.innerHTML = html;
    return template.content.childElementCount;
  },

  isUploadInput(el: Element): el is HTMLInputElement {
    return (
      (el as HTMLInputElement).type === "file" &&
      el.getAttribute(PHX_UPLOAD_REF) !== null
    );
  },

  isAutoUpload(inputEl: Element) {
    return inputEl.hasAttribute("data-phx-auto-upload");
  },

  findUploadInputs(node: Element): HTMLInputElement[] {
    const formId = node.id;
    const inputsOutsideForm = this.all(
      document,
      `input[type="file"][${PHX_UPLOAD_REF}][form="${formId}"]`,
    );
    return this.all(node, `input[type="file"][${PHX_UPLOAD_REF}]`).concat(
      inputsOutsideForm,
    ) as HTMLInputElement[];
  },

  findComponent(
    viewId: string,
    cid: string | number,
    doc: QueryableNode = document,
  ): Element | null {
    return doc.querySelector(
      `[${PHX_VIEW_REF}="${viewId}"][${PHX_COMPONENT}="${cid}"]`,
    );
  },

  getComponent(
    viewId: string,
    cid: number,
    doc: QueryableNode = document,
  ): Element {
    const el = this.findComponent(viewId, cid, doc);
    if (!el) {
      throw new Error(
        `no component found matching viewId ${viewId} and cid ${cid}`,
      );
    }
    return el;
  },

  isPhxDestroyed(node: Element) {
    return node.id && DOM.private(node, "destroyed") ? true : false;
  },

  wantsNewTab(e: Event) {
    const wantsNewTab =
      (e as MouseEvent).ctrlKey ||
      (e as MouseEvent).shiftKey ||
      (e as MouseEvent).metaKey ||
      ((e as MouseEvent).button && (e as MouseEvent).button === 1);
    const isDownload =
      e.target instanceof HTMLAnchorElement &&
      e.target.hasAttribute("download");
    const isTargetBlank =
      (e.target as Element).hasAttribute("target") &&
      (e.target as Element).getAttribute("target")!.toLowerCase() === "_blank";
    const isTargetNamedTab =
      (e.target as Element).hasAttribute("target") &&
      !(e.target as Element).getAttribute("target")!.startsWith("_");
    return wantsNewTab || isTargetBlank || isDownload || isTargetNamedTab;
  },

  isUnloadableFormSubmit(e: SubmitEvent) {
    // Ignore form submissions intended to close a native <dialog> element
    // https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dialog#usage_notes
    const isDialogSubmit =
      (e.target && (e.target as Element).getAttribute("method") === "dialog") ||
      (e.submitter && e.submitter.getAttribute("formmethod") === "dialog");

    if (isDialogSubmit) {
      return false;
    } else {
      return !e.defaultPrevented && !this.wantsNewTab(e);
    }
  },

  isNewPageClick(e: MouseEvent, currentLocation: Location) {
    const href =
      e.target instanceof HTMLAnchorElement
        ? e.target.getAttribute("href")
        : null;
    let url;

    if (e.defaultPrevented || href === null || this.wantsNewTab(e)) {
      return false;
    }
    if (href.startsWith("mailto:") || href.startsWith("tel:")) {
      return false;
    }
    if ((e.target as HTMLElement).isContentEditable) {
      return false;
    }

    try {
      url = new URL(href);
    } catch {
      try {
        url = new URL(href, currentLocation as unknown as string);
      } catch {
        // bad URL, fallback to let browser try it as external
        return true;
      }
    }

    if (
      url.host === currentLocation.host &&
      url.protocol === currentLocation.protocol
    ) {
      if (
        url.pathname === currentLocation.pathname &&
        url.search === currentLocation.search
      ) {
        return url.hash === "" && !url.href.endsWith("#");
      }
    }
    return url.protocol.startsWith("http");
  },

  markPhxChildDestroyed(el: Element) {
    if (this.isPhxChild(el)) {
      el.setAttribute(PHX_SESSION, "");
    }
    this.putPrivate(el, "destroyed", true);
  },

  findPhxChildrenInFragment(html: string, parentId: string) {
    const template = document.createElement("template");
    template.innerHTML = html;
    return this.findPhxChildren(template.content, parentId);
  },

  isIgnored(el: Element, phxUpdate: string) {
    return (
      (el.getAttribute(phxUpdate) || el.getAttribute("data-phx-update")) ===
      "ignore"
    );
  },

  isPhxUpdate(el: Element, phxUpdate: string, updateTypes: string[]) {
    return (
      el.getAttribute && updateTypes.indexOf(el.getAttribute(phxUpdate)!) >= 0
    );
  },

  findPhxSticky(el: Element) {
    return this.all(el, `[${PHX_STICKY}]`);
  },

  findPhxChildren(el: QueryableNode, parentId: string) {
    return this.all(el, `${PHX_VIEW_SELECTOR}[${PHX_PARENT_ID}="${parentId}"]`);
  },

  findExistingParentCIDs(viewId: string, cids: number[]) {
    // we only want to find parents that exist on the page
    // if a cid is not on the page, the only way it can be added back to the page
    // is if a parent adds it back, therefore if a cid does not exist on the page,
    // we should not try to render it by itself (because it would be rendered twice,
    // one by the parent, and a second time by itself)
    const parentCids = new Set();
    const childrenCids = new Set();

    cids.forEach((cid) => {
      this.all(
        document,
        `[${PHX_VIEW_REF}="${viewId}"][${PHX_COMPONENT}="${cid}"]`,
      ).forEach((parent) => {
        parentCids.add(cid);
        this.all(parent, `[${PHX_VIEW_REF}="${viewId}"][${PHX_COMPONENT}]`)
          .map((el) => parseInt(el.getAttribute(PHX_COMPONENT)!))
          .forEach((childCID) => childrenCids.add(childCID));
      });
    });

    childrenCids.forEach((childCid) => parentCids.delete(childCid));

    return parentCids;
  },

  // el carries a `phxPrivate` bag of arbitrary, dynamically-keyed values
  // (cycles, hooks, timers, flags); the bag itself is genuinely untyped.
  private(el: Element, key: string) {
    return (el as any)[PHX_PRIVATE] && (el as any)[PHX_PRIVATE][key];
  },

  deletePrivate(el: Element, key: string) {
    (el as any)[PHX_PRIVATE] && delete (el as any)[PHX_PRIVATE][key];
  },

  // value is an arbitrary private-bag payload — intentionally dynamic
  putPrivate(el: Element, key: string, value: any) {
    if (!(el as any)[PHX_PRIVATE]) {
      (el as any)[PHX_PRIVATE] = {};
    }
    (el as any)[PHX_PRIVATE][key] = value;
  },

  // defaultVal / the update result are arbitrary private-bag payloads
  updatePrivate(
    el: Element,
    key: string,
    defaultVal: any,
    updateFunc: (val: any) => any,
  ) {
    const existing = this.private(el, key);
    if (existing === undefined) {
      this.putPrivate(el, key, updateFunc(defaultVal));
    } else {
      this.putPrivate(el, key, updateFunc(existing));
    }
  },

  syncPendingAttrs(fromEl: Element, toEl: Element) {
    if (!fromEl.hasAttribute(PHX_REF_SRC)) {
      return;
    }
    PHX_EVENT_CLASSES.forEach((className) => {
      fromEl.classList.contains(className) && toEl.classList.add(className);
    });
    PHX_PENDING_ATTRS.filter((attr) => fromEl.hasAttribute(attr)).forEach(
      (attr) => {
        toEl.setAttribute(attr, fromEl.getAttribute(attr)!);
      },
    );
  },

  copyPrivates(target: Element, source: Element) {
    if ((source as any)[PHX_PRIVATE]) {
      (target as any)[PHX_PRIVATE] = (source as any)[PHX_PRIVATE];
    }
  },

  putTitle(str: string) {
    const titleEl = document.querySelector("title");
    if (titleEl) {
      const { prefix, suffix, default: defaultTitle } = titleEl.dataset;
      const isEmpty = typeof str !== "string" || str.trim() === "";
      if (isEmpty && typeof defaultTitle !== "string") {
        return;
      }

      const inner = isEmpty ? defaultTitle : str;
      document.title = `${prefix || ""}${inner || ""}${suffix || ""}`;
    } else {
      document.title = str;
    }
  },

  debounce(
    el: Element,
    event: Event,
    phxDebounce: string,
    defaultDebounce: string,
    phxThrottle: string,
    defaultThrottle: string,
    asyncFilter: () => boolean,
    callback: () => void,
  ) {
    let debounce = el.getAttribute(phxDebounce);
    let throttle = el.getAttribute(phxThrottle);

    if (debounce === "") {
      debounce = defaultDebounce;
    }
    if (throttle === "") {
      throttle = defaultThrottle;
    }
    const value = debounce || throttle;
    switch (value) {
      case null:
        return callback();

      case "blur":
        this.incCycle(el, "debounce-blur-cycle", () => {
          if (asyncFilter()) {
            callback();
          }
        });
        if (this.once(el, "debounce-blur")) {
          el.addEventListener("blur", () =>
            this.triggerCycle(el, "debounce-blur-cycle"),
          );
        }
        return;

      default:
        const timeout = parseInt(value!);
        const trigger = () =>
          throttle ? this.deletePrivate(el, THROTTLED) : callback();
        const currentCycle = this.incCycle(el, DEBOUNCE_TRIGGER, trigger);
        if (isNaN(timeout)) {
          return logError(`invalid throttle/debounce value: ${value}`);
        }
        if (throttle) {
          let newKeyDown = false;
          if (event.type === "keydown") {
            const prevKey = this.private(el, DEBOUNCE_PREV_KEY);
            this.putPrivate(el, DEBOUNCE_PREV_KEY, (event as KeyboardEvent).key);
            newKeyDown = prevKey !== (event as KeyboardEvent).key;
          }

          if (!newKeyDown && this.private(el, THROTTLED)) {
            return false;
          } else {
            callback();
            const t = setTimeout(() => {
              if (asyncFilter()) {
                this.triggerCycle(el, DEBOUNCE_TRIGGER);
              }
            }, timeout);
            this.putPrivate(el, THROTTLED, t);
          }
        } else {
          setTimeout(() => {
            if (asyncFilter()) {
              this.triggerCycle(el, DEBOUNCE_TRIGGER, currentCycle);
            }
          }, timeout);
        }

        const form = (el as HTMLInputElement).form;
        if (form && this.once(form, "bind-debounce")) {
          form.addEventListener("submit", () => {
            Array.from(new FormData(form).entries(), ([name]) => {
              const namedItem = form.elements.namedItem(name);
              const input =
                namedItem instanceof RadioNodeList ? namedItem[0] : namedItem;
              if (input) {
                this.incCycle(input, DEBOUNCE_TRIGGER);
                this.deletePrivate(input, THROTTLED);
              }
            });
          });
        }
        if (this.once(el, "bind-debounce")) {
          el.addEventListener("blur", () => {
            // because we trigger the callback here,
            // we also clear the throttle timeout to prevent the callback
            // from being called again after the timeout fires
            clearTimeout(this.private(el, THROTTLED));
            if (asyncFilter()) {
              this.triggerCycle(el, DEBOUNCE_TRIGGER);
            }
          });
        }
    }
  },

  triggerCycle(el: Element, key: string, currentCycle?: number) {
    const [cycle, trigger] = this.private(el, key);
    if (!currentCycle) {
      currentCycle = cycle;
    }
    if (currentCycle === cycle) {
      this.incCycle(el, key);
      trigger();
    }
  },

  once(el: Element, key: string) {
    if (this.private(el, key) === true) {
      return false;
    }
    this.putPrivate(el, key, true);
    return true;
  },

  incCycle(el: Element, key: string, trigger = function () {}) {
    let [currentCycle] = this.private(el, key) || [0, trigger];
    currentCycle++;
    this.putPrivate(el, key, [currentCycle, trigger]);
    return currentCycle;
  },

  // maintains or adds privately used hook information
  // fromEl and toEl can be the same element in the case of a newly added node
  // fromEl and toEl can be any HTML node type, so we need to check if it's an element node
  maintainPrivateHooks(
    fromEl: Element,
    toEl: Element,
    phxViewportTop: string,
    phxViewportBottom: string,
  ) {
    // maintain the hooks created with createHook
    if (
      fromEl.hasAttribute &&
      fromEl.hasAttribute("data-phx-hook") &&
      !toEl.hasAttribute("data-phx-hook")
    ) {
      toEl.setAttribute("data-phx-hook", fromEl.getAttribute("data-phx-hook")!);
    }
    // add hooks to elements with viewport attributes
    if (
      toEl.hasAttribute &&
      (toEl.hasAttribute(phxViewportTop) ||
        toEl.hasAttribute(phxViewportBottom))
    ) {
      toEl.setAttribute("data-phx-hook", "Phoenix.InfiniteScroll");
    }
  },

  // hook is a user-supplied custom-element hook instance — opaque to the DOM layer
  putCustomElHook(el: Element, hook: any) {
    if (el.isConnected) {
      el.setAttribute("data-phx-hook", "");
    } else {
      console.error(`
        hook attached to non-connected DOM element
        ensure you are calling createHook within your connectedCallback. ${el.outerHTML}
      `);
    }
    this.putPrivate(el, "custom-el-hook", hook);
  },

  getCustomElHook(el: Element) {
    return this.private(el, "custom-el-hook");
  },

  isUsedInput(el: Element) {
    return (
      el.nodeType === Node.ELEMENT_NODE &&
      (this.private(el, PHX_HAS_FOCUSED) || this.private(el, PHX_HAS_SUBMITTED))
    );
  },

  resetForm(form: HTMLFormElement) {
    Array.from(form.elements).forEach((input) => {
      this.deletePrivate(input, PHX_HAS_FOCUSED);
      this.deletePrivate(input, PHX_HAS_SUBMITTED);
    });
  },

  isPhxChild(node: Element) {
    return node.getAttribute && node.getAttribute(PHX_PARENT_ID);
  },

  isPhxSticky(node: Element) {
    return node.getAttribute && node.getAttribute(PHX_STICKY) !== null;
  },

  isChildOfAny(el: Element, parents: Element[]) {
    return !!parents.find((parent) => parent.contains(el));
  },

  firstPhxChild(el: Element) {
    return this.isPhxChild(el) ? el : this.all(el, `[${PHX_PARENT_ID}]`)[0];
  },

  isPortalTemplate(el: Element): el is HTMLTemplateElement {
    return el.tagName === "TEMPLATE" && el.hasAttribute(PHX_PORTAL);
  },

  closestViewEl(el: Element) {
    // find the closest portal or view element, whichever comes first
    const portalOrViewEl = el.closest(
      `[${PHX_TELEPORTED_REF}],${PHX_VIEW_SELECTOR}`,
    );
    if (!portalOrViewEl) {
      return null;
    }
    if (portalOrViewEl.hasAttribute(PHX_TELEPORTED_REF)) {
      // PHX_TELEPORTED_REF is set to the id of the view that owns the portal element
      return this.byId(portalOrViewEl.getAttribute(PHX_TELEPORTED_REF));
    } else if (portalOrViewEl.hasAttribute(PHX_SESSION)) {
      return portalOrViewEl;
    }
    return null;
  },

  dispatchEvent(
    target: EventTarget,
    name: string,
    // detail is arbitrary user-facing event payload; intentionally dynamic
    opts: { bubbles?: boolean; detail?: any } = {},
  ) {
    let defaultBubble = true;
    const isUploadTarget =
      (target as Element).nodeName === "INPUT" &&
      (target as HTMLInputElement).type === "file";
    if (isUploadTarget && name === "click") {
      defaultBubble = false;
    }
    const bubbles = opts.bubbles === undefined ? defaultBubble : !!opts.bubbles;
    const eventOpts = {
      bubbles: bubbles,
      cancelable: true,
      detail: opts.detail || {},
    };
    const event =
      name === "click"
        ? new MouseEvent("click", eventOpts)
        : new CustomEvent(name, eventOpts);
    target.dispatchEvent(event);
  },

  cloneNode(node: Element, html?: string): Element {
    if (typeof html === "undefined") {
      return node.cloneNode(true) as Element;
    } else {
      const cloned = node.cloneNode(false) as Element;
      cloned.innerHTML = html;
      return cloned;
    }
  },

  // merge attributes from source to target
  // if an element is ignored, we only merge data attributes
  // including removing data attributes that are no longer in the source
  mergeAttrs(
    target: Element,
    source: Element,
    opts: { exclude?: string[]; isIgnored?: boolean } = {},
  ) {
    const exclude = new Set(opts.exclude || []);
    const isIgnored = opts.isIgnored;
    const sourceAttrs = source.attributes;
    for (let i = sourceAttrs.length - 1; i >= 0; i--) {
      const name = sourceAttrs[i].name;
      if (!exclude.has(name)) {
        const sourceValue = source.getAttribute(name);
        if (
          target.getAttribute(name) !== sourceValue &&
          (!isIgnored || (isIgnored && name.startsWith("data-")))
        ) {
          target.setAttribute(name, sourceValue!);
        }
      } else {
        // We exclude the value from being merged on focused inputs, because the
        // user's input should always win.
        // We can still assign it as long as the value property is the same, though.
        // This prevents a situation where the updated hook is not being triggered
        // when an input is back in its "original state", because the attribute
        // was never changed, see:
        // https://github.com/phoenixframework/phoenix_live_view/issues/2163
        if (name === "value") {
          const sourceValue =
            (source as HTMLInputElement).value ?? source.getAttribute(name);
          if ((target as HTMLInputElement).value === sourceValue) {
            // actually set the value attribute to sync it with the value property
            target.setAttribute("value", source.getAttribute(name)!);
          }
        }
      }
    }

    const targetAttrs = target.attributes;
    for (let i = targetAttrs.length - 1; i >= 0; i--) {
      const name = targetAttrs[i].name;
      if (isIgnored) {
        if (
          name.startsWith("data-") &&
          !source.hasAttribute(name) &&
          !PHX_PENDING_ATTRS.includes(name)
        ) {
          target.removeAttribute(name);
        }
      } else {
        if (!source.hasAttribute(name)) {
          target.removeAttribute(name);
        }
      }
    }
  },

  mergeFocusedInput(target: Element, source: Element) {
    // skip selects because FF will reset highlighted index for any setAttribute
    if (!(target instanceof HTMLSelectElement)) {
      DOM.mergeAttrs(target, source, { exclude: ["value"] });
    }

    if ((source as HTMLInputElement).readOnly) {
      target.setAttribute("readonly", true as unknown as string);
    } else {
      target.removeAttribute("readonly");
    }
  },

  hasSelectionRange(
    el: Element | null,
  ): el is HTMLInputElement | HTMLTextAreaElement {
    // runtime feature-detect: el may be any element, only inputs/textareas
    // expose setSelectionRange — keep the existence check dynamic
    return (
      (el as any).setSelectionRange &&
      ((el as HTMLInputElement | null)!.type === "text" ||
        (el as HTMLInputElement | null)!.type === "textarea")
    );
  },

  restoreFocus(
    focused: Element | null,
    selectionStart: number | undefined,
    selectionEnd: number | undefined,
  ) {
    if (focused instanceof HTMLSelectElement) {
      focused.focus();
    }
    if (!DOM.isTextualInput(focused)) {
      return;
    }

    const wasFocused = focused!.matches(":focus");
    if (!wasFocused) {
      (focused as HTMLElement).focus();
    }
    if (this.hasSelectionRange(focused)) {
      focused.setSelectionRange(selectionStart as number, selectionEnd as number);
    }
  },

  /**
   * Returns true if the element is an input that can be focused and edited by the user,
   * so we can skip patching it if it has focus.
   */
  isEditableInput(el: Element | EventTarget | null): el is FormInputLike {
    return (
      this.isFormAssociated(el) &&
      !(el instanceof HTMLButtonElement) &&
      !(el instanceof HTMLInputElement && el.type === "button")
    );
  },

  isFormAssociated(el: Element | EventTarget | null): el is FormInputLike {
    if (!(el instanceof HTMLElement)) return false;
    if (el.localName) {
      const customEl = customElements.get(el.localName);
      if (customEl) {
        // Custom Elements may be form associated. This allows them
        // to participate within a form's lifecycle, including form
        // validity and form submissions.
        // The spec for Form Associated custom elements requires the
        // custom element's class to contain a static boolean value of `formAssociated`
        // which identifies this class as allowed to associate to a form.
        // See https://html.spec.whatwg.org/dev/custom-elements.html#custom-elements-face-example
        // for details.
        return (
          (customEl as { formAssociated?: boolean }).formAssociated === true
        );
      }
    }
    return (
      el instanceof HTMLInputElement ||
      el instanceof HTMLSelectElement ||
      el instanceof HTMLTextAreaElement ||
      el instanceof HTMLButtonElement
    );
  },

  syncAttrsToProps(el: Element) {
    if (
      el instanceof HTMLInputElement &&
      CHECKABLE_INPUTS.indexOf(el.type.toLocaleLowerCase()) >= 0
    ) {
      el.checked = el.getAttribute("checked") !== null;
    }
  },

  isTextualInput(el: Element | null) {
    return FOCUSABLE_INPUTS.indexOf((el as HTMLInputElement | null)!.type) >= 0;
  },

  isNowTriggerFormExternal(el: Element, phxTriggerExternal: string) {
    return (
      el.getAttribute &&
      el.getAttribute(phxTriggerExternal) !== null &&
      document.body.contains(el)
    );
  },

  cleanChildNodes(container: Element, phxUpdate: string) {
    if (
      DOM.isPhxUpdate(container, phxUpdate, ["append", "prepend", PHX_STREAM])
    ) {
      const toRemove: Array<ChildNode> = [];
      container.childNodes.forEach((childNode) => {
        if (!("id" in childNode) || !childNode.id) {
          // Skip warning if it's an empty text node (e.g. a new-line)
          const isEmptyTextNode =
            childNode.nodeType === Node.TEXT_NODE &&
            childNode.nodeValue &&
            childNode.nodeValue.trim() === "";
          if (!isEmptyTextNode && childNode.nodeType !== Node.COMMENT_NODE) {
            logError(
              "only HTML element tags with an id are allowed inside containers with phx-update.\n\n" +
                `removing illegal node: "${(("outerHTML" in childNode && (childNode.outerHTML as string)) || childNode.nodeValue || "").trim()}"\n\n`,
            );
          }
          toRemove.push(childNode);
        }
      });
      toRemove.forEach((childNode) => childNode.remove());
    }
  },

  replaceRootContainer(
    container: Element,
    tagName: string,
    attrs: Record<string, string>,
  ) {
    const retainedAttrs = new Set([
      "id",
      PHX_SESSION,
      PHX_STATIC,
      PHX_MAIN,
      PHX_ROOT_ID,
    ]);
    if (container.tagName.toLowerCase() === tagName.toLowerCase()) {
      Array.from(container.attributes)
        .filter((attr) => !retainedAttrs.has(attr.name.toLowerCase()))
        .forEach((attr) => container.removeAttribute(attr.name));

      Object.keys(attrs)
        .filter((name) => !retainedAttrs.has(name.toLowerCase()))
        .forEach((attr) => container.setAttribute(attr, attrs[attr]));

      return container;
    } else {
      const newContainer = document.createElement(tagName);
      Object.keys(attrs).forEach((attr) =>
        newContainer.setAttribute(attr, attrs[attr]),
      );
      retainedAttrs.forEach((attr) => {
        const value = container.getAttribute(attr);
        if (value !== null) {
          newContainer.setAttribute(attr, value);
        }
      });
      newContainer.innerHTML = container.innerHTML;
      container.replaceWith(newContainer);
      return newContainer;
    }
  },

  // defaultVal is either a literal fallback or a thunk producing one — dynamic
  getSticky(el: Element, name: string, defaultVal: any) {
    const op = (DOM.private(el, "sticky") || []).find(
      ([existingName]: any[]) => name === existingName,
    );
    if (op) {
      const [_name, _op, stashedResult] = op;
      return stashedResult;
    } else {
      return typeof defaultVal === "function" ? defaultVal() : defaultVal;
    }
  },

  deleteSticky(el: Element, name: string) {
    this.updatePrivate(el, "sticky", [], (ops) => {
      return ops.filter(([existingName, _]: any[]) => existingName !== name);
    });
  },

  // op stashes an arbitrary per-element result keyed by name; callers narrow el
  // to concrete subtypes (HTMLElement etc.), so op's param stays dynamic
  putSticky(el: Element, name: string, op: (el: any) => any) {
    const stashedResult = op(el);
    this.updatePrivate(el, "sticky", [], (ops) => {
      const existingIndex = ops.findIndex(
        ([existingName]: any[]) => name === existingName,
      );
      if (existingIndex >= 0) {
        ops[existingIndex] = [name, op, stashedResult];
      } else {
        ops.push([name, op, stashedResult]);
      }
      return ops;
    });
  },

  applyStickyOperations(el: Element) {
    const ops = DOM.private(el, "sticky");
    if (!ops) {
      return;
    }

    ops.forEach(([name, op, _stashed]: any[]) => this.putSticky(el, name, op));
  },

  isLocked(el: Element) {
    return el.hasAttribute && el.hasAttribute(PHX_REF_LOCK);
  },

  // ignoredAttributes is a list of attribute-name patterns; callers may type it
  // loosely (unknown[]), so keep the element type precise but the list dynamic
  attributeIgnored(attribute: Attr, ignoredAttributes: any[]) {
    return ignoredAttributes.some(
      (toIgnore: string) =>
        attribute.name == toIgnore ||
        toIgnore === "*" ||
        (toIgnore.includes("*") && attribute.name.match(toIgnore) != null),
    );
  },
};

export default DOM;
