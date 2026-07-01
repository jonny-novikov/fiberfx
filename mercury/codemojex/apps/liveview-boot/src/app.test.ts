import { describe, it, expect, vi, beforeEach } from "vitest";

// The two @echo/* client packages are mocked BEFORE ./app is imported so the module's
// load-time bootstrap (new LiveSocket("/live", Socket, ...).connect(); window.liveSocket =
// ...) runs inertly under jsdom instead of opening a real socket. vi.mock is hoisted above
// the import below by vitest, so the mocks are registered first.
vi.mock("@echo/phoenix", () => ({ Socket: class Socket {} }));
vi.mock("@echo/phoenix_live_view", () => ({
  LiveSocket: class LiveSocket {
    connect(): void {}
  },
}));

import { GameIsland, safeParse, devOriginOf, wireViteDev } from "./app";

// Fixture bundle specifiers. app.ts's `import(el.dataset.bundle)` resolves them relative
// to app.ts (both live in src/), exactly as it would an edge URL at runtime. One exports
// mount(); one omits it.
const BUNDLE = "./__fixtures__/mock-game.ts";
const NO_MOUNT_BUNDLE = "./__fixtures__/mock-game-no-mount.ts";

// The globalThis sink the mock-game fixture delegates to (see the fixture header).
interface GameTestSink {
  mount?: (el: HTMLElement, props: unknown, bridge: unknown) => void;
  handle?: { update(payload: unknown): void; unmount?(): void };
}
function setSink(sink: GameTestSink): void {
  (globalThis as unknown as { __gameTestSink?: GameTestSink }).__gameTestSink = sink;
}

// A minimal stand-in for the LiveView Hook `this`. handleEvent records each (event, cb)
// so a test can fire a server event, and returns a DISTINCT ref per call.
interface TestHook {
  el: HTMLElement;
  refs?: unknown[];
  listeners?: Set<(name: string, payload: unknown) => void>;
  handle?: { update(payload: unknown): void; unmount?(): void } | null;
  pushEvent: ReturnType<typeof vi.fn>;
  handleEvent: ReturnType<typeof vi.fn>;
  removeHandleEvent: ReturnType<typeof vi.fn>;
}

function makeHook(el: HTMLElement) {
  const handlers: Record<string, (payload: unknown) => void> = {};
  const hook: TestHook = {
    el,
    pushEvent: vi.fn(),
    handleEvent: vi.fn((event: string, cb: (payload: unknown) => void) => {
      handlers[event] = cb;
      return vi.fn(); // a distinct, spied ref per registration
    }),
    removeHandleEvent: vi.fn(),
  };
  // Fire a registered server-event handler as LiveView would push it.
  const fire = (event: string, payload: unknown): void => {
    const h = handlers[event];
    if (!h) throw new Error(`no handler registered for "${event}"`);
    h(payload);
  };
  return { hook, fire };
}

const callMounted = (hook: TestHook): Promise<void> =>
  (GameIsland.mounted as unknown as (this: TestHook) => Promise<void>).call(hook);
const callDestroyed = (hook: TestHook): void =>
  (GameIsland.destroyed as unknown as (this: TestHook) => void).call(hook);

beforeEach(() => {
  setSink({});
  vi.restoreAllMocks();
  // Isolate the dev-wire idempotency flag + preamble globals between tests.
  const w = window as unknown as Record<string, unknown>;
  delete w.__vite_plugin_react_preamble_installed__;
  delete w.$RefreshReg$;
  delete w.$RefreshSig$;
});

describe("safeParse", () => {
  it("parses valid JSON into the object", () => {
    expect(safeParse('{"a":1,"b":[2,3]}')).toEqual({ a: 1, b: [2, 3] });
  });

  it("returns {} for malformed JSON", () => {
    expect(safeParse("{not json")).toEqual({});
  });

  it("returns {} for undefined", () => {
    expect(safeParse(undefined)).toEqual({});
  });

  it("returns {} for the empty string", () => {
    expect(safeParse("")).toEqual({});
  });
});

describe("GameIsland.mounted", () => {
  it("does nothing when the element carries no bundle url", async () => {
    const errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});
    const { hook } = makeHook(document.createElement("div")); // no dataset.bundle

    await callMounted(hook);

    expect(errorSpy).toHaveBeenCalledOnce();
    expect(hook.handle).toBeUndefined();
    expect(hook.handleEvent).not.toHaveBeenCalled();
  });

  it("does nothing when the loaded bundle has no mount() export", async () => {
    const errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});
    const el = document.createElement("div");
    el.dataset.bundle = NO_MOUNT_BUNDLE;
    const { hook } = makeHook(el);

    await callMounted(hook);

    expect(errorSpy).toHaveBeenCalledOnce();
    expect(hook.handle).toBeUndefined();
    expect(hook.handleEvent).not.toHaveBeenCalled();
  });

  it("loads the bundle, mounts with (el, props, bridge), wires the 4 server handlers, and bridges events", async () => {
    const el = document.createElement("div");
    el.dataset.bundle = BUNDLE;
    el.dataset.props = JSON.stringify({ level: 3, seed: "abc" });

    const mountSpy = vi.fn();
    const updateSpy = vi.fn();
    const unmountSpy = vi.fn();
    setSink({ mount: mountSpy, handle: { update: updateSpy, unmount: unmountSpy } });

    const { hook, fire } = makeHook(el);
    await callMounted(hook);

    // mount() called once with the element, the PARSED props, and the bridge object
    expect(mountSpy).toHaveBeenCalledTimes(1);
    const [gotEl, gotProps, bridge] = mountSpy.mock.calls[0] as [
      HTMLElement,
      unknown,
      { pushEvent(e: string, p: unknown): void; onServerEvent(cb: (n: string, p: unknown) => void): () => void },
    ];
    expect(gotEl).toBe(el);
    expect(gotProps).toEqual({ level: 3, seed: "abc" });
    expect(bridge).toMatchObject({
      pushEvent: expect.any(Function),
      onServerEvent: expect.any(Function),
    });

    // the returned handle is stored, and all 4 server events are registered (4 refs)
    const sink = (globalThis as unknown as { __gameTestSink: GameTestSink }).__gameTestSink;
    expect(hook.handle).toBe(sink.handle);
    expect(hook.handleEvent.mock.calls.map((c) => c[0])).toEqual([
      "game:update",
      "guess_rejected",
      "revealed",
      "golden_win",
    ]);
    expect(hook.refs).toHaveLength(4);

    // bridge.pushEvent forwards to this.pushEvent
    bridge.pushEvent("guess", { cell: 5 });
    expect(hook.pushEvent).toHaveBeenCalledWith("guess", { cell: 5 });

    // a game:update push drives the handle's update()
    fire("game:update", { board: [1, 2] });
    expect(updateSpy).toHaveBeenCalledWith({ board: [1, 2] });

    // onServerEvent registers a listener; a one-off event fans out to it with (name, payload)
    const listener = vi.fn();
    const unsubscribe = bridge.onServerEvent(listener);
    fire("revealed", { idx: 2 });
    expect(listener).toHaveBeenCalledWith("revealed", { idx: 2 });

    // the returned unsubscribe removes it — a later fan-out no longer reaches it
    unsubscribe();
    listener.mockClear();
    fire("golden_win", { prize: 100 });
    expect(listener).not.toHaveBeenCalled();
  });

  it("defaults props to {} when dataset.props is malformed", async () => {
    const el = document.createElement("div");
    el.dataset.bundle = BUNDLE;
    el.dataset.props = "{bad json";
    const mountSpy = vi.fn();
    setSink({ mount: mountSpy, handle: { update: vi.fn(), unmount: vi.fn() } });

    const { hook } = makeHook(el);
    await callMounted(hook);

    expect(mountSpy.mock.calls[0]?.[1]).toEqual({});
  });
});

describe("devOriginOf", () => {
  it("returns the origin for an absolute http(s) .tsx/.ts source entry (the Vite dev server)", () => {
    expect(devOriginOf("http://127.0.0.1:5173/src/index.tsx")).toBe("http://127.0.0.1:5173");
    expect(devOriginOf("https://dev.local:5173/src/app.ts")).toBe("https://dev.local:5173");
  });

  it("returns null for every built-bundle shape (edge + same-origin .js)", () => {
    expect(devOriginOf("https://edge.codemoji.games/game-abc123.js")).toBeNull();
    expect(devOriginOf("http://localhost:4000/game/bundle")).toBeNull();
  });

  it("returns null for relative specifiers and non-http(s) protocols", () => {
    expect(devOriginOf("./__fixtures__/mock-game.ts")).toBeNull();
    expect(devOriginOf("/assets/game.ts")).toBeNull();
    expect(devOriginOf("ws://127.0.0.1:5173/src/index.tsx")).toBeNull();
  });
});

describe("wireViteDev", () => {
  const ORIGIN = "http://127.0.0.1:5173";

  function makeImporter() {
    const inject = vi.fn();
    const calls: string[] = [];
    const importer = vi.fn(async (url: string) => {
      calls.push(url);
      return url.endsWith("/@react-refresh") ? { default: { injectIntoGlobalHook: inject } } : {};
    });
    return { importer, inject, calls };
  }

  it("installs the preamble then the HMR client, in order, from the dev origin", async () => {
    const { importer, inject, calls } = makeImporter();

    await wireViteDev(ORIGIN, importer);

    expect(calls).toEqual([`${ORIGIN}/@react-refresh`, `${ORIGIN}/@vite/client`]);
    expect(inject).toHaveBeenCalledExactlyOnceWith(window);
    const w = window as unknown as Record<string, unknown>;
    expect(w.__vite_plugin_react_preamble_installed__).toBe(true);
    expect(typeof w.$RefreshReg$).toBe("function");
    const sig = (w.$RefreshSig$ as () => (t: unknown) => unknown)();
    expect(sig("x")).toBe("x"); // the identity transform the preamble contract specifies
  });

  it("is idempotent — a second wire (re-mount) never re-imports", async () => {
    const { importer } = makeImporter();
    await wireViteDev(ORIGIN, importer);
    await wireViteDev(ORIGIN, importer);
    expect(importer).toHaveBeenCalledTimes(2); // refresh + client, once
  });

  it("throws when the origin serves no react-refresh runtime (caller downgrades to a warning)", async () => {
    const importer = vi.fn(async () => ({}));
    await expect(wireViteDev(ORIGIN, importer)).rejects.toThrow(/react-refresh/);
    const w = window as unknown as Record<string, unknown>;
    expect(w.__vite_plugin_react_preamble_installed__).toBeUndefined();
  });
});

describe("GameIsland.mounted — the dev loop's failure states stay non-fatal", () => {
  it("an unreachable dev bundle warns (dev wire) + errors (entry) and leaves the hook inert", async () => {
    const warnSpy = vi.spyOn(console, "warn").mockImplementation(() => {});
    const errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});
    const el = document.createElement("div");
    // A source-entry URL (dev shape) on a port nothing listens on: the dev wire
    // rejects -> warn; the entry import rejects -> error; mounted never throws.
    el.dataset.bundle = "http://127.0.0.1:59999/src/index.tsx";
    const { hook } = makeHook(el);

    await expect(callMounted(hook)).resolves.toBeUndefined();

    expect(warnSpy).toHaveBeenCalledOnce();
    expect(errorSpy).toHaveBeenCalledOnce();
    expect(hook.handle).toBeUndefined();
    expect(hook.handleEvent).not.toHaveBeenCalled();
  });
});

describe("GameIsland.destroyed", () => {
  it("unmounts the handle and removes each ref via removeHandleEvent — never invoking a ref", () => {
    const unmountSpy = vi.fn();
    const ref1 = vi.fn();
    const ref2 = vi.fn();
    const hook = {
      el: document.createElement("div"),
      handle: { update: vi.fn(), unmount: unmountSpy },
      refs: [ref1, ref2],
      pushEvent: vi.fn(),
      handleEvent: vi.fn(),
      removeHandleEvent: vi.fn(),
    } as unknown as TestHook;

    callDestroyed(hook);

    expect(unmountSpy).toHaveBeenCalledTimes(1);
    expect(hook.removeHandleEvent).toHaveBeenCalledTimes(2);
    expect(hook.removeHandleEvent).toHaveBeenNthCalledWith(1, ref1);
    expect(hook.removeHandleEvent).toHaveBeenNthCalledWith(2, ref2);
    // The regression guard: a CallbackRef is removed via removeHandleEvent(ref), NOT
    // invoked as off() (the old raw app.js called each ref and threw at teardown).
    expect(ref1).not.toHaveBeenCalled();
    expect(ref2).not.toHaveBeenCalled();
  });

  it("is a safe no-op when nothing was mounted (no handle, no refs)", () => {
    const hook = {
      el: document.createElement("div"),
      pushEvent: vi.fn(),
      handleEvent: vi.fn(),
      removeHandleEvent: vi.fn(),
    } as unknown as TestHook;

    expect(() => callDestroyed(hook)).not.toThrow();
    expect(hook.removeHandleEvent).not.toHaveBeenCalled();
  });

  it("tolerates a handle without an unmount() method", () => {
    const ref = vi.fn();
    const hook = {
      el: document.createElement("div"),
      handle: { update: vi.fn() }, // no unmount
      refs: [ref],
      pushEvent: vi.fn(),
      handleEvent: vi.fn(),
      removeHandleEvent: vi.fn(),
    } as unknown as TestHook;

    expect(() => callDestroyed(hook)).not.toThrow();
    expect(hook.removeHandleEvent).toHaveBeenCalledWith(ref);
    expect(ref).not.toHaveBeenCalled();
  });
});
