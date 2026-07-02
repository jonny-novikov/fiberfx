// Local no-op shim for the bare "storybook/test" specifier. Only fn() executes
// at story-module top level (in `args`), so it returns a callable no-op; the
// five play-only helpers throw loudly if ever reached — the showcase renders
// stories but never runs `play` (interaction tests are the Storybook host's job).
// A new story importing a 7th name fails LOUD at vite import-analysis; the fix
// is one added export here.

type AnyFn = (...args: unknown[]) => unknown;

export function fn(impl?: AnyFn): AnyFn {
  return (...args: unknown[]) => impl?.(...args);
}

function playOnly(name: string): AnyFn {
  return () => {
    throw new Error(`storybook/test shim: ${name} is play-only; the showcase does not run play functions`);
  };
}

export const expect = playOnly("expect");
export const userEvent = playOnly("userEvent");
export const fireEvent = playOnly("fireEvent");
export const waitFor = playOnly("waitFor");
export const within = playOnly("within");
