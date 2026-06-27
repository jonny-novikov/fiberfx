// The edge bundle entry. Built by vite as an ESM library, content-hashed, uploaded
// to static.codemoji.games, and dynamic-imported by the EdgeReact hook. It owns its
// own React (no shared-runtime contract with the host) — the ONLY contract is this
// mount signature + the BoardProps shape + the Bridge.
import { createRoot, Root } from "react-dom/client";
import { BoardScreen } from "./BoardScreen";
import type { BoardProps, Bridge } from "./types";

export function mount(el: HTMLElement, props: BoardProps, bridge: Bridge) {
  const root: Root = createRoot(el);
  const render = (p: BoardProps) => root.render(<BoardScreen {...p} bridge={bridge} />);
  render(props);
  return {
    update: (p: BoardProps) => render(p),
    unmount: () => root.unmount(),
  };
}

export { BoardScreen };
