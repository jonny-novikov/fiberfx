// The edge bundle entry. Built by vite as an ESM library, content-hashed, uploaded
// to edge.codemoji.games, and dynamic-imported by the GameIsland hook. It owns its
// own React (no shared-runtime contract with the host) — the ONLY contract is this
// mount signature + the GameProps shape + the Bridge.
//
// The screen is model-driven: mount binds a `createGameModel` over the host bridge
// (via @mercury/effector's bridgeChannel) and renders BridgeGame; update() fires
// the model's propsReceived instead of an imperative re-render. Under the Vite dev
// server the entry self-accepts HMR: an edit to a non-component module (this file,
// the model) remounts the island in place from the RETAINED latest props — the
// LiveView page and socket never reload. In the library build the import.meta.hot
// blocks are compile-time dead.
import { createRoot, type Root } from "react-dom/client";
import { GameEdge } from "@/GameEdge";
import { GameSmoke } from "@/GameSmoke";
import { BridgeGame } from "@/channel/BridgeGame";
import { createGameModel } from "@/channel/model";
import type { GameProps, Bridge } from "@/types";
import theme from "@/styles/theme.css?inline";

// The game DS rides INSIDE the bundle (cmt.4.1-D5, the ruled F-cmt41-1 arm): the
// Tailwind-compiled theme.css is imported ?inline (a string — no second CSS file
// the host must load) and injected ONCE as a <style data-cmjx-game> at mount.
// theme.css itself omits preflight, so the host LiveView page is never reset.
let styleInjected = false;
function injectTheme(): void {
  if (styleInjected || typeof document === "undefined") return;
  const el = document.createElement("style");
  el.dataset.cmjxGame = "";
  el.textContent = theme;
  document.head.appendChild(el);
  styleInjected = true;
}

// The stable facade a mount hands the host. Its identity survives a hot swap
// (import.meta.hot.data carries it), so the host's handle keeps working while
// the module graph underneath is replaced: `props` always holds the LATEST
// props (mount-time, then every update), `apply` points at the CURRENT model.
export interface LiveMount {
  el: HTMLElement;
  bridge: Bridge;
  props: GameProps;
  root: Root;
  apply: (p: GameProps) => void;
}

// Build a fresh model from THIS module graph and render the tree over it.
// Called at mount and again (from the NEW module) on an entry-level hot swap —
// so edited model/entry logic actually applies, seeded from the retained props.
function render(live: LiveMount): void {
  // The dev-flagged smoke (cmt.4.1-D7): an explicit VITE_GAME_SMOKE=1 build renders
  // the foundation probe instead of the game; with the flag off (the default) the
  // model-driven path below is exactly the shipped one.
  if (import.meta.env.VITE_GAME_SMOKE === "1") {
    live.apply = () => {};
    live.root.render(<GameSmoke />);
    return;
  }
  const model = createGameModel();
  live.apply = (p) => model.propsReceived(p);
  live.root.render(<BridgeGame model={model} bridge={live.bridge} initial={live.props} />);
}

export function mount(el: HTMLElement, props: GameProps, bridge: Bridge) {
  injectTheme();
  const live: LiveMount = { el, bridge, props, root: createRoot(el), apply: () => {} };
  render(live);
  // Keyed on the data bag, not the hot object: vitest exposes a partial
  // import.meta.hot with no `data`; only real Vite dev carries the swap bag.
  if (import.meta.hot?.data) import.meta.hot.data.live = live;
  return {
    update: (p: GameProps) => {
      live.props = p;
      live.apply(p);
    },
    unmount: () => live.root.unmount(),
  };
}

// The hot-swap half of the mount contract: the OLD module's accept handler hands
// the retained LiveMount to the NEW module, which re-renders its own graph over
// it. Exported so the incoming module namespace carries it.
export function remount(live: LiveMount): void {
  live.root.unmount();
  live.root = createRoot(live.el);
  render(live);
}

if (import.meta.hot?.data) {
  import.meta.hot.accept((mod) => {
    const live = import.meta.hot?.data?.live as LiveMount | undefined;
    const next = mod as { remount?: (l: LiveMount) => void } | undefined;
    if (live && live.el.isConnected && typeof next?.remount === "function") {
      next.remount(live);
    } else {
      // No retained mount (or the island left the DOM) — fall back to a full reload.
      import.meta.hot?.invalidate();
    }
  });
}

export { GameEdge };
