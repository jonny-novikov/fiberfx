// The LiveView client for the codemojex Mini App. It is built locally and
// committed to priv/static/assets (the Engine image has no JS build step), so the
// machine serves it via Plug.Static. It carries NO game code: the EdgeReact hook
// dynamic-imports the game bundle from edge.codemoji.games at runtime.
// Bare specifiers, resolved by the <head> import map (Layouts.root) to the committed
// /assets/phoenix*.js. Same reuse convention as the edge game island
// (`import { Socket } from "@echo/phoenix"`), so there is exactly one Socket class in
// the page and the boot has no relative dependency on sibling files in this dir.
import { Socket } from "@echo/phoenix";
import { LiveSocket } from "@echo/phoenix_live_view";

// The bridge between the edge-loaded React game and the LiveView socket. The game
// bundle owns its own React; the host owns the socket. The contract is this object
// plus mount(el, props, bridge) plus the props shape — all versioned in the README.
const EdgeReact = {
  async mounted() {
    const el = this.el;
    const bundle = el.dataset.bundle;
    if (!bundle) {
      console.error("EdgeReact: no game bundle url (edge pointer + GAME_ASSET_URL both empty)");
      return;
    }
    const props = safeParse(el.dataset.props);
    this._unsubs = [];
    const bridge = {
      pushEvent: (event, payload) => this.pushEvent(event, payload),
      onServerEvent: (cb) => {
        this._listeners ||= new Set();
        this._listeners.add(cb);
        return () => this._listeners.delete(cb);
      },
    };

    const mod = await import(/* @vite-ignore */ bundle);
    if (!mod || typeof mod.mount !== "function") {
      console.error("EdgeReact: game bundle has no mount(el, props, bridge) export");
      return;
    }
    this._handle = mod.mount(el, props, bridge);

    // server -> client: full prop diffs and one-off events
    this._unsubs.push(this.handleEvent("game:update", (p) => this._handle && this._handle.update(p)));
    ["guess_rejected", "revealed", "golden_win"].forEach((name) =>
      this._unsubs.push(
        this.handleEvent(name, (payload) =>
          this._listeners && this._listeners.forEach((cb) => cb(name, payload))
        )
      )
    );
  },
  destroyed() {
    this._handle && this._handle.unmount && this._handle.unmount();
    (this._unsubs || []).forEach((off) => off && off());
  },
};

function safeParse(s) {
  try {
    return JSON.parse(s || "{}");
  } catch (_e) {
    return {};
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { EdgeReact },
});
liveSocket.connect();
window.liveSocket = liveSocket;
