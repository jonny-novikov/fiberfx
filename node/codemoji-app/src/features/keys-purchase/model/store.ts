import { atom } from 'jotai'

/**
 * Key package available for purchase via Telegram Stars.
 *
 * v2.1: Backend now returns pre-computed `usd` and `discount` values.
 * No frontend computation needed.
 *
 * @see useKeyPackages() for fetching with caching
 */
export type KeyPackage = {
  /** Package identifier (e.g., 'pack_1', 'pack_15') */
  id: string
  /** Number of keys in the package */
  keys: number
  /** Price in Telegram Stars (XTR) */
  stars: number
  /** Display name for UI */
  name: string
  /** Description text for UI */
  description: string
  /** Currency code ('XTR' for Telegram Stars) */
  currency: 'XTR' | 'USD'
  /** Approximate USD value (pre-computed by backend) */
  usd?: number
  /** Discount percentage vs Starter pack (pre-computed by backend) */
  discount?: number
}

/**
 * @deprecated Use useKeyPackages() hook instead.
 * Hardcoded packages are no longer the source of truth.
 * Backend returns packages via GET /shop/packages with pre-computed values.
 */
export const KEY_PACKAGES: KeyPackage[] = []

export const keysPurchaseDrawerAtom = atom<boolean>(false)
