import { PHX_VIEW_SELECTOR } from "./constants";

import EntryUploader from "./entry_uploader";

import type View from "./view";
import type LiveSocket from "./live_socket";
import type UploadEntry from "./upload_entry";

export const logError = (msg: unknown, obj?: unknown) =>
  console.error && console.error(msg, obj);

// Live navigation can only stay within the current origin, as it joins the
// target over the existing socket. A full URL to a different origin (or a
// non-http(s) scheme, which resolves to an opaque "null" origin) is a
// programming error, so we fail loudly instead of attempting a broken join.
export const ensureSameOrigin = (
  href: string,
  kind: "patch" | "navigate",
): void => {
  let url: URL;
  try {
    url = new URL(href, window.location.href);
  } catch {
    throw new Error(
      `expected ${kind} destination to be a valid URL, got: ${href}`,
    );
  }
  if (url.origin !== window.location.origin) {
    throw new Error(
      `cannot ${kind} to "${href}" because its origin does not match the ` +
        `current origin "${window.location.origin}". Use window.location directly for cross-origin navigation.`,
    );
  }
};

export const isCid = (cid: unknown): cid is number | string => {
  const type = typeof cid;
  return type === "number" || (type === "string" && /^(0|[1-9]\d*)$/.test(cid as string));
};

export function detectDuplicateIds() {
  const ids = new Set();
  const elems = document.querySelectorAll("*[id]");
  for (let i = 0, len = elems.length; i < len; i++) {
    if (ids.has(elems[i].id)) {
      console.error(
        `Multiple IDs detected: ${elems[i].id}. Ensure unique element ids.`,
      );
    } else {
      ids.add(elems[i].id);
    }
  }
}

export function detectInvalidStreamInserts(inserts: Record<string, unknown>) {
  const errors = new Set();
  Object.keys(inserts).forEach((id) => {
    const streamEl = document.getElementById(id);
    if (
      streamEl &&
      streamEl.parentElement &&
      streamEl.parentElement.getAttribute("phx-update") !== "stream"
    ) {
      errors.add(
        `The stream container with id "${streamEl.parentElement.id}" is missing the phx-update="stream" attribute. Ensure it is set for streams to work properly.`,
      );
    }
  });
  errors.forEach((error) => console.error(error));
}

export const debug = (view: View, kind: string, msg: string, obj: unknown) => {
  if (view.liveSocket.isDebugEnabled()) {
    console.log(`${view.id} ${kind}: ${msg} - `, obj);
  }
};

// wraps value in closure or returns closure
export const closure = (val?: unknown) =>
  typeof val === "function"
    ? val
    : function () {
        return val;
      };

// obj is arbitrary wire/diff/location data round-tripped through JSON; the
// cloned shape is intentionally dynamic, so it stays `any`.
export const clone = (obj: any) => {
  return JSON.parse(JSON.stringify(obj));
};

export const closestPhxBinding = (
  startEl: Element,
  binding: string,
  borderEl?: Element,
) => {
  let el: Element | null = startEl;
  do {
    if (el.matches(`[${binding}]`) && !("disabled" in el && el.disabled)) {
      return el;
    }
    el = el.parentElement;
  } while (
    el !== null &&
    el.nodeType === 1 &&
    !((borderEl && borderEl.isSameNode(el)) || el.matches(PHX_VIEW_SELECTOR))
  );
  return null;
};

export const isObject = (obj: unknown) => {
  return obj !== null && typeof obj === "object" && !(obj instanceof Array);
};

export const isEqualObj = (obj1: unknown, obj2: unknown) =>
  JSON.stringify(obj1) === JSON.stringify(obj2);

// obj is a dynamic diff/object whose own enumerable keys are probed; `any`
// keeps the for-in over the untyped wire shape.
export const isEmpty = (obj: any) => {
  for (const x in obj) {
    return false;
  }
  return true;
};

export const maybe = <T, R>(el: T | null | undefined, callback: (el: T) => R) =>
  el && callback(el);

export const channelUploader = function (
  entries: UploadEntry[],
  // onError is the uploader-protocol error callback; its shape is defined by
  // the host application's custom uploaders, so it stays an untyped function.
  onError: (...args: any[]) => void,
  resp: { config: ConstructorParameters<typeof EntryUploader>[1] },
  liveSocket: LiveSocket,
) {
  entries.forEach((entry: UploadEntry) => {
    const entryUploader = new EntryUploader(entry, resp.config, liveSocket);
    entryUploader.upload();
  });
};

export const eventContainsFiles = (e: DragEvent) => {
  if (e.dataTransfer!.types) {
    for (let i = 0; i < e.dataTransfer!.types.length; i++) {
      if (e.dataTransfer!.types[i] === "Files") {
        return true;
      }
    }
  }
  return false;
};
