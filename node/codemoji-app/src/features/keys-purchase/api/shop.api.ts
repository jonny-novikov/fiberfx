import type { KeyPackage } from '../model/store'

import { api } from '@/shared/api/axios'

// ─── Types ──────────────────────────────────────────────────────────────────

/**
 * Response from POST /shop/purchase
 */
export interface PurchaseResult {
  /** Telegram Stars invoice URL to open with tg.openInvoice() */
  invoiceUrl: string
  /** Invoice ID from AppFather */
  invoiceId: string
  /** Internal order ID for tracking */
  orderId: string
  /** Invoice expiration time */
  expiresAt: string
}

/**
 * Frontend no longer needs to compute these values.
 */
export interface BackendPackage {
  id: string
  name: string
  keys: number
  stars: number
  description: string
  currency: 'XTR'
  /** Approximate USD value (pre-computed by backend) */
  usd?: number
  /** Discount percentage vs Starter pack (pre-computed by backend) */
  discount?: number
}

/**
 * Response from GET /shop/packages
 */
export interface PackagesResponse {
  packages: BackendPackage[]
}

// ─── API Functions ──────────────────────────────────────────────────────────

/**
 * Purchase keys via Telegram Stars
 *
 * Flow:
 * 1. Call this to create order and get invoice URL
 * 2. Open Telegram payment dialog via WebApp.openInvoice()
 * 3. Backend webhook credits keys to player on payment success
 *
 * @param packageId Package identifier (e.g., 'pack_15', 'pack_25')
 * @returns Invoice URL for Telegram payment
 *
 * @example
 * ```typescript
 * const { invoiceUrl, orderId } = await purchaseKeys('pack_15')
 * window.Telegram?.WebApp?.openInvoice(invoiceUrl, (status) => {
 *   if (status === 'paid') {
 *     // Refresh balance - keys credited via webhook
 *     queryClient.invalidateQueries({ queryKey: ['resources'] })
 *   }
 * })
 * ```
 */
export async function purchaseKeys(packageId: string): Promise<PurchaseResult> {
  const response = await api.post<PurchaseResult>('/shop/purchase', { packageId })
  return response.data
}

/**
 * Get available key packages from backend
 *
 * Note: Frontend currently uses hardcoded KEY_PACKAGES for faster loading.
 * This endpoint can be used to sync with backend package definitions.
 *
 * @returns List of available packages with prices in Stars (XTR)
 */
export async function getPackages(): Promise<PackagesResponse> {
  const response = await api.get<PackagesResponse>('/shop/packages')
  return response.data
}

/**
 * Transform backend packages to frontend KeyPackage format.
 *
 * @deprecated Since v2.1, backend returns pre-computed `usd` and `discount` values.
 * Use getPackages().packages directly without transformation.
 * This function is kept for backwards compatibility.
 *
 * @param packages - All packages from backend
 * @returns Packages with usd/discount (already provided by backend)
 */
export function toKeyPackages(packages: BackendPackage[]): KeyPackage[] {
  // Backend now returns pre-computed values, just pass through
  return packages.map((pkg) => ({
    id: pkg.id,
    keys: pkg.keys,
    stars: pkg.stars,
    usd: pkg.usd ?? pkg.stars * 0.013, // Fallback for backwards compat
    discount: pkg.discount,
  }))
}

/**
 * Transform single backend package to frontend KeyPackage format.
 *
 * @deprecated Since v2.1, backend returns pre-computed values.
 * Use getPackages().packages directly.
 */
export function toKeyPackage(pkg: BackendPackage): KeyPackage {
  return {
    id: pkg.id,
    keys: pkg.keys,
    stars: pkg.stars,
    usd: pkg.usd ?? pkg.stars * 0.013,
    discount: pkg.discount,
  }
}
