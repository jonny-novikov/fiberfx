import type { ReactNode } from "react";

/** Any function — used where the signature is irrelevant. */
export type { AnyFn, Without } from "#types.js";

/** A component's props plus the standard React `children`. */
export type WithChildren<T = Record<never, never>> = T & { children?: ReactNode };

/**
 * A component's props plus an optional `child` render slot — the React analogue
 * of the bits-ui `child` snippet, for headless "render your own element" APIs.
 */
export type WithChild<T = Record<never, never>> = T & {
	child?: (props: Record<string, unknown>) => ReactNode;
};
