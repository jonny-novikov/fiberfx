import { useMutation, useQuery, useQueryClient, UseQueryOptions } from '@tanstack/react-query'
import { useTranslation } from 'react-i18next'

import { purchaseKeys, getPackages, toKeyPackages, type PurchaseResult } from '../api/shop.api'
import type { KeyPackage } from '../model/store'

import { playerQueryKeys } from '@/entities/player'

/** Query keys for shop data */
export const shopQueryKeys = {
  all: ['shop'] as const,
  packages: () => [...shopQueryKeys.all, 'packages'] as const,
}

/**
 * Hook for fetching key packages from backend with caching.
 *
 * Packages are fetched from backend's GET /shop/packages and transformed
 * using toKeyPackages() to compute USD and discount values.
 *
 * This ensures frontend displays the same prices that backend uses for invoices.
 *
 * @example
 * ```tsx
 * function PackageList() {
 *   const { data: packages, isLoading } = useKeyPackages()
 *
 *   if (isLoading) return <Skeleton />
 *
 *   return packages?.map(pkg => (
 *     <PackageItem key={pkg.id} {...pkg} />
 *   ))
 * }
 * ```
 */
export function useKeyPackages(options?: Partial<UseQueryOptions<KeyPackage[]>>) {
  return useQuery<KeyPackage[]>({
    queryKey: shopQueryKeys.packages(),
    queryFn: async () => {
      const response = await getPackages()
      // Transform backend packages to frontend format with computed usd and discount
      return toKeyPackages(response.packages)
    },
    staleTime: 5 * 60 * 1000, // 5 minutes
    gcTime: 30 * 60 * 1000, // 30 minutes (formerly cacheTime)
    refetchInterval: 15_000, // 15 seconds
    ...options,
  })
}

/**
 * Hook for purchasing keys via Telegram Stars
 *
 * Handles the full purchase flow:
 * 1. Creates order and gets invoice URL from backend
 * 2. Opens Telegram payment dialog
 * 3. Handles payment result (success/cancelled/failed)
 * 4. Invalidates resources cache on success
 *
 * @example
 * ```tsx
 * function BuyButton({ packageId }: { packageId: string }) {
 *   const { mutate, isPending } = usePurchaseKeys()
 *
 *   return (
 *     <button
 *       onClick={() => mutate(packageId)}
 *       disabled={isPending}
 *     >
 *       {isPending ? 'Processing...' : 'Buy Keys'}
 *     </button>
 *   )
 * }
 * ```
 */
export function usePurchaseKeys({ onClose }: { onClose?: () => void } = {}) {
  const queryClient = useQueryClient()
  const { t } = useTranslation()

  return useMutation({
    mutationFn: async (packageId: string): Promise<PurchaseResult & { paymentStatus?: string }> => {
      // Step 1: Create order and get invoice URL
      const result = await purchaseKeys(packageId)

      // Step 2: Open Telegram payment dialog
      const tg = typeof window !== 'undefined' ? window.Telegram?.WebApp : null

      if (!tg?.openInvoice) {
        throw new Error('Telegram WebApp not available')
      }

      // Open Telegram invoice and wait for result
      return new Promise((resolve, reject) => {
        tg.openInvoice(result.invoiceUrl, (status: string) => {
          console.log('[Shop] Payment status:', status, 'orderId:', result.orderId)

          if (status === 'paid') {
            // Payment successful - keys credited via AppFather webhook
            tg.HapticFeedback?.notificationOccurred('success')

            tg.showPopup?.({
              title: t('keys.purchase.successTitle'),
              message: t('keys.purchase.successMessage'),
              buttons: [{ type: 'ok' }],
            })

            resolve({ ...result, paymentStatus: 'paid' })
          } else if (status === 'cancelled') {
            // User cancelled - not an error
            resolve({ ...result, paymentStatus: 'cancelled' })
          } else if (status === 'failed') {
            tg.HapticFeedback?.notificationOccurred('error')
            reject(new Error('Payment failed'))
          } else if (status === 'pending') {
            // Payment is processing
            resolve({ ...result, paymentStatus: 'pending' })
          } else {
            // Unknown status
            resolve({ ...result, paymentStatus: status })
          }
        })
      })
    },

    onSuccess: (data) => {
      // Refresh balance on successful payment
      if (data.paymentStatus === 'paid') {
        queryClient.invalidateQueries({ queryKey: playerQueryKeys.resources() })
        // Close drawer after successful purchase
        onClose?.()
      }
    },

    onError: (error) => {
      console.error('[Shop] Purchase failed:', error)

      const tg = typeof window !== 'undefined' ? window.Telegram?.WebApp : null
      if (tg) {
        tg.HapticFeedback?.notificationOccurred('error')
        tg.showPopup?.({
          title: t('keys.purchase.errorTitle'),
          message: error instanceof Error ? error.message : t('keys.purchase.errorMessage'),
          buttons: [{ type: 'ok' }],
        })
      }
    },
  })
}
