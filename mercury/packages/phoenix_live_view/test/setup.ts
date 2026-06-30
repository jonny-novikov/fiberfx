// Test environment setup for the vitest+jsdom port of the upstream suite.
//
// jsdom does not implement the `CSS` interface, but the LiveView client calls
// `CSS.escape(...)` (src/view.ts, src/live_socket.ts, src/dom_patch.ts) to build
// selectors. In a real browser this is the native, spec-compliant implementation;
// here we restore it with the canonical CSSOM `CSS.escape` polyfill (the algorithm
// from https://drafts.csswg.org/cssom/#serialize-an-identifier) so the suite
// exercises the same selector-escaping path the browser would.

if (typeof (globalThis as any).CSS === "undefined" || typeof (globalThis as any).CSS.escape !== "function") {
  const cssEscape = (value: string): string => {
    const str = String(value);
    const length = str.length;
    let index = -1;
    let codeUnit: number;
    let result = "";
    const firstCodeUnit = str.charCodeAt(0);

    if (length === 1 && firstCodeUnit === 0x002d) {
      // "-" alone must be escaped.
      return "\\" + str;
    }

    while (++index < length) {
      codeUnit = str.charCodeAt(index);
      // NULL → U+FFFD REPLACEMENT CHARACTER.
      if (codeUnit === 0x0000) {
        result += "�";
        continue;
      }

      if (
        // Control chars and DEL.
        (codeUnit >= 0x0001 && codeUnit <= 0x001f) ||
        codeUnit === 0x007f ||
        // First char is a digit.
        (index === 0 && codeUnit >= 0x0030 && codeUnit <= 0x0039) ||
        // Second char is a digit and the first is "-".
        (index === 1 && codeUnit >= 0x0030 && codeUnit <= 0x0039 && firstCodeUnit === 0x002d)
      ) {
        result += "\\" + codeUnit.toString(16) + " ";
        continue;
      }

      if (
        codeUnit >= 0x0080 ||
        codeUnit === 0x002d ||
        codeUnit === 0x005f ||
        (codeUnit >= 0x0030 && codeUnit <= 0x0039) ||
        (codeUnit >= 0x0041 && codeUnit <= 0x005a) ||
        (codeUnit >= 0x0061 && codeUnit <= 0x007a)
      ) {
        // The character itself is safe.
        result += str.charAt(index);
        continue;
      }

      // Otherwise, escape it.
      result += "\\" + str.charAt(index);
    }
    return result;
  };

  (globalThis as any).CSS = { ...(globalThis as any).CSS, escape: cssEscape };
}
