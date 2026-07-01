// The edge bundle entry. Built by vite as an ESM library, content-hashed, uploaded
// to edge.codemoji.games, and dynamic-imported by the GameIsland hook. It owns its
// own React (no shared-runtime contract with the host) — the ONLY contract is this
// mount signature + the GameProps shape + the Bridge.
import { createRoot, Root } from "react-dom/client";
import { GameEdge } from "@/GameEdge";
import type { GameProps, Bridge } from "@/types";

export function mount(el: HTMLElement, props: GameProps, bridge: Bridge) {
  const root: Root = createRoot(el);
  const render = (p: GameProps) => root.render(<GameEdge {...p} bridge={bridge} />);
  render(props);
  return {
    update: (p: GameProps) => render(p),
    unmount: () => root.unmount(),
  };
}

export { GameEdge };
