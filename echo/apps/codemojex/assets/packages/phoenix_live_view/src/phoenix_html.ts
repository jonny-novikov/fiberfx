"use strict";

(function() {
  var PolyfillEvent = eventConstructor();

  function eventConstructor(): typeof window.CustomEvent {
    if (typeof window.CustomEvent === "function") return window.CustomEvent;
    // IE<=9 Support
    function CustomEvent(event: string, params?: CustomEventInit) {
      params = params || {bubbles: false, cancelable: false, detail: undefined};
      var evt = document.createEvent('CustomEvent');
      evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail);
      return evt;
    }
    CustomEvent.prototype = window.Event.prototype;
    // the IE<=9 polyfill is an old-style constructor function; assert it to the
    // standard CustomEvent constructor shape for the `new PolyfillEvent(...)` call sites.
    return CustomEvent as unknown as typeof window.CustomEvent;
  }

  function buildHiddenInput(name: string, value: string | null) {
    var input = document.createElement("input");
    input.type = "hidden";
    input.name = name;
    input.value = value as string;
    return input;
  }

  function handleClick(element: HTMLElement, targetModifierKey: boolean) {
    var to = element.getAttribute("data-to"),
        method = buildHiddenInput("_method", element.getAttribute("data-method")),
        csrf = buildHiddenInput("_csrf_token", element.getAttribute("data-csrf")),
        form = document.createElement("form"),
        submit = document.createElement("input"),
        target = element.getAttribute("target");

    form.method = (element.getAttribute("data-method") === "get") ? "get" : "post";
    form.action = to as string;
    form.style.display = "none";

    if (target) form.target = target;
    else if (targetModifierKey) form.target = "_blank";

    form.appendChild(csrf);
    form.appendChild(method);
    document.body.appendChild(form);

    // Insert a button and click it instead of using `form.submit`
    // because the `submit` function does not emit a `submit` event.
    submit.type = "submit";
    form.appendChild(submit);
    submit.click();
  }

  window.addEventListener("click", function(e) {
    // duck-typed DOM walk: starts at the EventTarget and climbs `parentNode`
    // (ParentNode | null), gated each step by the runtime `element.getAttribute` check.
    var element: any = e.target;
    if (e.defaultPrevented) return;

    while (element && element.getAttribute) {
      var phoenixLinkEvent = new PolyfillEvent('phoenix.link.click', {
        "bubbles": true, "cancelable": true
      });

      if (!element.dispatchEvent(phoenixLinkEvent)) {
        e.preventDefault();
        e.stopImmediatePropagation();
        return false;
      }

      if (element.getAttribute("data-method") && element.getAttribute("data-to")) {
        handleClick(element, e.metaKey || e.shiftKey);
        e.preventDefault();
        return false;
      } else {
        element = element.parentNode;
      }
    }
  }, false);

  window.addEventListener('phoenix.link.click', function (e) {
    var message = (e.target as Element).getAttribute("data-confirm");
    if(message && !window.confirm(message)) {
      e.preventDefault();
    }
  }, false);
})();
