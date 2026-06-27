// The LiveView client for the codemojex Mini App. It is built locally and
// committed to priv/static/assets (the Engine image has no JS build step), so the
// machine serves it via Plug.Static. It carries NO board code: the EdgeReact hook
// dynamic-imports the board bundle from edge.codemoji.games at runtime.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

// The bridge between the edge-loaded React board and the LiveView socket. The board
// bundle owns its own React; the host owns the socket. The contract is this object
// plus mount(el, props, bridge) plus the props shape — all versioned in the README.
const EdgeReact = {
  async mounted() {
    const el = this.el;
    const bundle = el.dataset.bundle;
    if (!bundle) {
      console.error("EdgeReact: no board bundle url (edge pointer + BOARD_ASSET_URL both empty)");
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
      console.error("EdgeReact: board bundle has no mount(el, props, bridge) export");
      return;
    }
    this._handle = mod.mount(el, props, bridge);

    // server -> client: full prop diffs and one-off events
    this._unsubs.push(this.handleEvent("board:update", (p) => this._handle && this._handle.update(p)));
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
