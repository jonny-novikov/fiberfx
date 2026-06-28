// branded_id.ts — the branded snowflake contract, TypeScript first.
//
// Doctrine: the snowflake is bigint INSIDE this module and at storage edges;
// the branded string is the type at every JSON boundary. Nothing here ever
// hands a bigint to a serializer, which is how the 2^53 hazard and the
// JSON.stringify-throws-on-bigint hazard are both retired at the type level.
// Functional surface: pure functions, Result values, no classes, no throws
// on the data path (literal/unwrap throw by design, at construction sites).

const ALPHABET = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
const MAX_PAYLOAD = 'AzL8n0Y58m7'; // base62(2^63 - 1): the lexicographic range gate
const MASK64 = (1n << 64n) - 1n;
const MAX_SNOW = (1n << 63n) - 1n;

export const EPOCH_MS = 1_704_067_200_000n; // 2024-01-01T00:00:00Z
export const LEN = 14;

const VALUES = new Int8Array(256).fill(-1);
for (let i = 0; i < 62; i++) VALUES[ALPHABET.charCodeAt(i)] = i;

// ---------------------------------------------------------------- the type
declare const BRAND: unique symbol;

/** A validated branded id. The namespace rides in the type parameter, so a
 *  BrandedId<'USR'> is not assignable where a BrandedId<'CRS'> is required —
 *  the cross-entity id bug becomes a compile error. */
export type BrandedId<NS extends string = string> = string & { readonly [BRAND]: NS };

type UC =
  | 'A' | 'B' | 'C' | 'D' | 'E' | 'F' | 'G' | 'H' | 'I' | 'J' | 'K' | 'L' | 'M'
  | 'N' | 'O' | 'P' | 'Q' | 'R' | 'S' | 'T' | 'U' | 'V' | 'W' | 'X' | 'Y' | 'Z';

/** Extracts the namespace literal from a string literal type. */
export type Ns<S extends string> =
  S extends `${infer A extends UC}${infer B extends UC}${infer C extends UC}${string}`
    ? `${A}${B}${C}`
    : never;

type ValidShape<S extends string> = S extends `${UC}${UC}${UC}${string}` ? unknown : never;

// ------------------------------------------------------------- result type
export type BrandedIdError = 'length' | 'namespace' | 'charset' | 'range';

export type Result<T, E = BrandedIdError> =
  | { readonly ok: true; readonly value: T }
  | { readonly ok: false; readonly error: E };

export const ok = <T>(value: T): Result<T, never> => ({ ok: true, value });
export const err = <E>(error: E): Result<never, E> => ({ ok: false, error });
export const unwrap = <T, E>(r: Result<T, E>): T => {
  if (!r.ok) throw new Error(`branded-id: ${String(r.error)}`);
  return r.value;
};

// ------------------------------------------------------------------- codec
const upper3 = (s: string): boolean => {
  for (let i = 0; i < 3; i++) {
    const c = s.charCodeAt(i);
    if (c < 65 || c > 90) return false;
  }
  return true;
};

export const parse = (id: string): Result<{ ns: string; snow: bigint }> => {
  if (id.length !== LEN) return err('length');
  if (!upper3(id)) return err('namespace');
  if (id.slice(3) > MAX_PAYLOAD) return err('range'); // string compare IS the 2^63 gate
  let snow = 0n;
  for (let i = 3; i < LEN; i++) {
    const d = VALUES[id.charCodeAt(i)] ?? -1; // out-of-range char code -> invalid
    if (d < 0) return err('charset');
    snow = snow * 62n + BigInt(d);
  }
  return ok({ ns: id.slice(0, 3), snow });
};

export const decode = (id: string): Result<bigint> => {
  const r = parse(id);
  return r.ok ? ok(r.value.snow) : r;
};

export const encode = <N extends string>(ns: N, snow: bigint): Result<BrandedId<N>> => {
  if (ns.length !== 3 || !upper3(ns)) return err('namespace');
  if (snow < 0n || snow > MAX_SNOW) return err('range');
  let payload = '';
  let k = snow;
  for (let i = 0; i < 11; i++) {
    payload = ALPHABET[Number(k % 62n)]! + payload; // index is always 0..61
    k /= 62n;
  }
  return ok((ns + payload) as BrandedId<N>);
};

/** Compile-time-shaped literal constructor — the ~b sigil, in TypeScript.
 *  The argument must start with three uppercase letters or the call does not
 *  compile; the body still parses, so a malformed payload throws at the
 *  construction site, never downstream. */
export const literal = <S extends string>(id: S & ValidShape<S>): BrandedId<Ns<S>> => {
  const r = parse(id);
  if (!r.ok) throw new Error(`invalid branded literal ${JSON.stringify(id)}: ${r.error}`);
  return id as unknown as BrandedId<Ns<S>>;
};

// ------------------------------------------------------------ derived data
/** Contract placement hash: first half of MurmurHash3 fmix64, low 32 bits. */
export const hash32 = (snow: bigint): number => {
  let k = snow & MASK64;
  k ^= k >> 33n;
  k = (k * 0xff51afd7ed558ccdn) & MASK64;
  k ^= k >> 33n;
  return Number(k & 0xffffffffn);
};

/** Mint instant in Unix ms — returned as number: always < 2^53, JSON-safe. */
export const unixMs = (snow: bigint): number => Number((snow >> 22n) + EPOCH_MS);

/** Smallest snowflake mintable at or after the instant: the synthetic cursor. */
export const minFor = (d: Date): bigint => (BigInt(d.getTime()) - EPOCH_MS) << 22n;

/** The order theorem as an API: string comparison is time comparison. */
export const compare = (a: BrandedId, b: BrandedId): number => (a < b ? -1 : a > b ? 1 : 0);

export const namespace = <N extends string>(id: BrandedId<N>): N => id.slice(0, 3) as N;

// ------------------------------------------------------------- type guards
export const isBrandedId = (s: unknown): s is BrandedId =>
  typeof s === 'string' && parse(s).ok;

/** Curried, namespace-narrowing guard: `inNamespace('CRS')` is a predicate
 *  that narrows unknown -> BrandedId<'CRS'>. Composes with filter/find. */
export const inNamespace = <N extends string>(ns: N) =>
  (s: unknown): s is BrandedId<N> =>
    typeof s === 'string' && s.startsWith(ns) && parse(s).ok;

// ----------------------------------------------------------------- minting
/** Per-worker minter. The lock-free CAS the BEAM needed dissolves on Node:
 *  one thread per cluster worker means a closure over `last` suffices, and
 *  cross-worker uniqueness comes from the node bits. max(now, last+1) keeps
 *  the same burst-borrow and clock-regression semantics as the Elixir core. */
export const makeMinter = (nodeId: number): (() => bigint) => {
  if (!Number.isInteger(nodeId) || nodeId < 0 || nodeId > 1023) {
    throw new RangeError(`nodeId out of range: ${nodeId}`);
  }
  const node = BigInt(nodeId) << 12n;
  let last = 0n;
  return (): bigint => {
    const floor = ((BigInt(Date.now()) - EPOCH_MS) << 22n) | node;
    last = floor > last ? floor : last + 1n;
    return last;
  };
};
