// The LiveView client for the codemojex Mini App — authored in TypeScript against the
// typed @echo/phoenix* packages, typechecked (`tsc --noEmit`) and built here (vite lib
// mode, phoenix externalized), then the built app.js is committed to echo's
// priv/static/assets — the same "ship-with" tier as phoenix.js / phoenix_live_view.js.
// It carries NO game code: the GameIsland hook dynamic-imports the game bundle from the
// edge (edge.codemoji.games) at runtime and bridges it to the LiveView socket.
import { Socket } from "@echo/phoenix";
import { LiveSocket, type Hook, type HookInterface } from "@echo/phoenix_live_view";

declare global {
  interface Window {
    liveSocket: LiveSocket;
  }
}

// handleEvent returns a CallbackRef (an object), not an unsubscribe function; derive
// its type from the interface rather than re-exporting it from the package entry.
type EventRef = ReturnType<HookInterface["handleEvent"]>;

// The handle a mounted game bundle returns: LiveView pushes prop diffs via update(),
// and the hook tears it down via unmount() on destroy.
interface GameHandle {
  update(payload: unknown): void;
  unmount?(): void;
}

// The game bundle's module contract (dynamic-imported at runtime from the edge).
interface GameModule {
  mount(el: HTMLElement, props: unknown, bridge: Bridge): GameHandle;
}

// The bridge handed to the game: outbound events go to the LiveView channel; inbound
// server events are fanned out to the game's registered listeners.
interface Bridge {
  pushEvent(event: string, payload: unknown): void;
  onServerEvent(cb: (name: string, payload: unknown) => void): () => void;
}

// Per-hook instance state (the `T` in Hook<T>): the server-event refs to unregister on
// destroy, the game's listener set, and the live game handle.
interface GameIslandState {
  refs?: EventRef[];
  listeners?: Set<(name: string, payload: unknown) => void>;
  handle?: GameHandle | null;
}

// --- Vite dev hot-wire -------------------------------------------------------------
// GAME_DEV_URL points data-bundle at the game's Vite dev server SOURCE entry (e.g.
// http://127.0.0.1:5173/src/index.tsx). A built bundle is always game-[hash].js, so a
// .ts/.tsx pathname on an absolute http(s) URL is a structural dev signal — no host
// attribute, no echo/ edit. In that case the page must install Vite's HMR client and
// the react-refresh preamble BEFORE the entry executes (the documented Vite
// backend-integration contract); the imports are awaited so ordering is deterministic.

/** The dev-server origin when `bundle` is a Vite source entry, else null. */
export function devOriginOf(bundle: string): string | null {
  let url: URL;
  try {
    url = new URL(bundle);
  } catch {
    return null; // relative specifiers are never a dev server
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") return null;
  const path = url.pathname;
  return path.endsWith(".ts") || path.endsWith(".tsx") ? url.origin : null;
}

type Importer = (url: string) => Promise<unknown>;
interface RefreshRuntime {
  injectIntoGlobalHook(w: Window): void;
}

/** Install the react-refresh preamble + the Vite HMR client from the dev origin.
 *  Idempotent (keyed on the preamble flag); throws on an unreachable dev server —
 *  the caller downgrades that to a warning and proceeds with the plain import. */
export async function wireViteDev(
  origin: string,
  importer: Importer = (u) => import(/* @vite-ignore */ u),
): Promise<void> {
  const w = window as unknown as Record<string, unknown>;
  if (w.__vite_plugin_react_preamble_installed__) return;

  const refresh = (await importer(`${origin}/@react-refresh`)) as { default?: RefreshRuntime };
  if (typeof refresh?.default?.injectIntoGlobalHook !== "function") {
    throw new Error(`no react-refresh runtime at ${origin}/@react-refresh`);
  }
  refresh.default.injectIntoGlobalHook(window);
  w.$RefreshReg$ = () => {};
  w.$RefreshSig$ = () => (type: unknown) => type;
  w.__vite_plugin_react_preamble_installed__ = true;

  await importer(`${origin}/@vite/client`);
}

// The bridge between the edge-loaded React game and the LiveView socket. The game
// bundle owns its own React; the host owns the socket. Typing it as Hook<GameIslandState>
// gives `this` the full HookInterface (el, pushEvent, handleEvent, removeHandleEvent).
// Exported for unit tests (the lib build has a single side-effect entry, so a named
// export changes nothing the browser evaluates — the module still bootstraps on import).
export const GameIsland: Hook<GameIslandState> = {
  async mounted() {
    const el = this.el;
    const bundle = el.dataset.bundle;
    if (!bundle) {
      console.error("GameIsland: no game bundle url (edge pointer + GAME_ASSET_URL both empty)");
      return;
    }
    const props = safeParse(el.dataset.props);
    const refs: EventRef[] = [];
    this.refs = refs;

    const bridge: Bridge = {
      pushEvent: (event, payload) => {
        this.pushEvent(event, payload);
      },
      onServerEvent: (cb) => {
        const set = (this.listeners ??= new Set());
        set.add(cb);
        return () => set.delete(cb);
      },
    };

    // Dev only: a .tsx/.ts source bundle means the Vite dev server — wire HMR first.
    const devOrigin = devOriginOf(bundle);
    if (devOrigin) {
      try {
        await wireViteDev(devOrigin);
      } catch (e) {
        console.warn("GameIsland: vite dev wire failed (dev server up?)", devOrigin, e);
      }
    }

    // In the dev loop a not-yet-started server is a routine state, not an exception —
    // fail loud in the console, leave the page (and the LiveView socket) alive.
    let mod: Partial<GameModule>;
    try {
      mod = (await import(/* @vite-ignore */ bundle)) as Partial<GameModule>;
    } catch (e) {
      console.error("GameIsland: game bundle failed to load", bundle, e);
      return;
    }
    const mount = mod?.mount;
    if (typeof mount !== "function") {
      console.error("GameIsland: game bundle has no mount(el, props, bridge) export");
      return;
    }
    this.handle = mount(el, props, bridge);

    // server -> client: full prop diffs and one-off events
    refs.push(this.handleEvent("game:update", (p) => this.handle?.update(p)));
    (["guess_rejected", "revealed", "golden_win"] as const).forEach((name) => {
      refs.push(
        this.handleEvent(name, (payload) =>
          this.listeners?.forEach((cb) => cb(name, payload)),
        ),
      );
    });
  },
  destroyed() {
    this.handle?.unmount?.();
    // A CallbackRef is removed via removeHandleEvent(ref) — NOT by calling it. (The old
    // raw app.js invoked each ref as `off()`, which threw at teardown; the type system
    // surfaced that in this migration.)
    this.refs?.forEach((ref) => this.removeHandleEvent(ref));
  },
};

export function safeParse(s: string | undefined): unknown {
  try {
    return JSON.parse(s || "{}");
  } catch {
    return {};
  }
}

const csrfToken =
  document.querySelector<HTMLMetaElement>("meta[name='csrf-token']")?.content ?? "";

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { GameIsland },
});
liveSocket.connect();
window.liveSocket = liveSocket;
