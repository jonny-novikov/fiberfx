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

import { GameIsland, safeParse } from "./app";

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
