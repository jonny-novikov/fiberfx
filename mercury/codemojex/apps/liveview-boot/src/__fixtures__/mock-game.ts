// Test fixture — a stand-in for the edge-loaded game bundle. The real bundle is
// dynamic-imported from edge.codemoji.games at runtime; GameIsland.mounted does
// `await import(el.dataset.bundle)` then calls `mod.mount(el, props, bridge)`. The mount
// test points el.dataset.bundle at THIS file, so the same import seam is exercised. mount
// delegates to spies the test installs on a globalThis sink (the two modules cannot share
// a lexical scope, so the sink is how the test asserts the call and drives the handle).
interface GameTestSink {
  mount?: (el: HTMLElement, props: unknown, bridge: unknown) => void;
  handle?: { update(payload: unknown): void; unmount?(): void };
}

function sink(): GameTestSink {
  const g = globalThis as unknown as { __gameTestSink?: GameTestSink };
  return (g.__gameTestSink ??= {});
}

export function mount(el: HTMLElement, props: unknown, bridge: unknown) {
  sink().mount?.(el, props, bridge);
  return sink().handle ?? { update() {}, unmount() {} };
}
