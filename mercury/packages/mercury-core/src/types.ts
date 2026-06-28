/* eslint-disable @typescript-eslint/no-explicit-any */
import type * as CSS from "csstype";

export type FunctionArgs<Args extends any[] = any[], Return = void> = (...args: Args) => Return;
export type Getter<T> = () => T;

export type Expand<T> = T extends infer U ? { [K in keyof U]: U[K] } : never;

/**
 * Constructs a new type by omitting properties from type
 * 'T' that exist in type 'U'.
 *
 * @template T - The base object type from which properties will be omitted.
 * @template U - The object type whose properties will be omitted from 'T'.
 * @example
 * type Result = Without<{ a: number; b: string; }, { b: string; }>;
 * // Result type will be { a: number; }
 */
export type Without<T extends object, U extends object> = Omit<T, keyof U>;
export type WithoutChild<T> = T extends { child?: any } ? Omit<T, "child"> : T;
export type WithoutChildrenOrChild<T> = WithoutChildren<WithoutChild<T>>;
export type WithoutChildren<T> = T extends { children?: any } ? Omit<T, "children"> : T;
export type WithElementRef<T, U extends HTMLElement = HTMLElement> = T & { ref?: U | null };

export type StyleProperties = CSS.Properties & {
	// Allow any CSS Custom Properties
	[str: `--${string}`]: any;
};

export type AnyFn = (...args: any[]) => any;
