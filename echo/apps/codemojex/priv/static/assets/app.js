import { Socket as h } from "@echo/phoenix";
import { LiveSocket as u } from "@echo/phoenix_live_view";
const l = {
  async mounted() {
    const t = this.el, s = t.dataset.bundle;
    if (!s) {
      console.error("EdgeReact: no game bundle url (edge pointer + GAME_ASSET_URL both empty)");
      return;
    }
    const a = p(t.dataset.props), o = [];
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
      console.error("EdgeReact: game bundle has no mount(el, props, bridge) export");
      return;
    }
    this.handle = r(t, a, d), o.push(this.handleEvent("game:update", (e) => this.handle?.update(e))), ["guess_rejected", "revealed", "golden_win"].forEach((e) => {
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
function p(t) {
  try {
    return JSON.parse(t || "{}");
  } catch {
    return {};
  }
}
const m = document.querySelector("meta[name='csrf-token']")?.content ?? "", c = new u("/live", h, {
  params: { _csrf_token: m },
  hooks: { EdgeReact: l }
});
c.connect();
window.liveSocket = c;
