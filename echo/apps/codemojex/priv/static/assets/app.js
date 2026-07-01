import { Socket as h } from "@echo/phoenix";
import { LiveSocket as l } from "@echo/phoenix_live_view";
const u = {
  async mounted() {
    const t = this.el, s = t.dataset.bundle;
    if (!s) {
      console.error("GameIsland: no game bundle url (edge pointer + GAME_ASSET_URL both empty)");
      return;
    }
    const c = m(t.dataset.props), o = [];
    this.refs = o;
    const d = {
      pushEvent: (e, n) => {
        this.pushEvent(e, n);
      },
      onServerEvent: (e) => {
        const n = this.listeners ??= /* @__PURE__ */ new Set();
        return n.add(e), () => n.delete(e);
      }
    }, r = (await import(
      /* @vite-ignore */
      s
    ))?.mount;
    if (typeof r != "function") {
      console.error("GameIsland: game bundle has no mount(el, props, bridge) export");
      return;
    }
    this.handle = r(t, c, d), o.push(this.handleEvent("game:update", (e) => this.handle?.update(e))), ["guess_rejected", "revealed", "golden_win"].forEach((e) => {
      o.push(
        this.handleEvent(
          e,
          (n) => this.listeners?.forEach((i) => i(e, n))
        )
      );
    });
  },
  destroyed() {
    this.handle?.unmount?.(), this.refs?.forEach((t) => this.removeHandleEvent(t));
  }
};
function m(t) {
  try {
    return JSON.parse(t || "{}");
  } catch {
    return {};
  }
}
const p = document.querySelector("meta[name='csrf-token']")?.content ?? "", a = new l("/live", h, {
  params: { _csrf_token: p },
  hooks: { GameIsland: u }
});
a.connect();
window.liveSocket = a;
