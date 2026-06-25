import { useCallback, useRef, useState } from 'react'

import { createShare } from '../api/share.api'
import type { CreateShareResponse } from '../api/share.types'

import { TelegramUtils, ShareToStoryParams } from '@/shared/libs/utils/telegram'

export interface UseShareToStoryOptions {
  onSuccess?: () => void
  onError?: (error: Error) => void
}

export interface ShareError {
  /** Raw Error object */
  raw: Error
  /** Backend error code or null for network errors */
  code: string | null
}

export interface UseShareToStoryReturn {
  /** Step 1: Call POST /share/create (triggered by first click) */
  prepareShare: () => Promise<void>
  /** Step 2: Open Telegram Story (triggered by second click in dialog) */
  confirmShare: (params: ShareToStoryParams) => void
  /** Whether the HTTP request is in flight */
  isPreparing: boolean
  /** Response data from backend */
  shareData: CreateShareResponse | null
  /** Error, if any */
  error: Error | null
  /** Structured error with code */
  shareError: ShareError | null
  /** Whether Telegram Stories feature is available */
  isAvailable: boolean
}

/**
 * Two-step share hook for Telegram Stories.
 *
 * Step 1 (prepareShare): POST /share/create to get a shareUrl.
 * Step 2 (confirmShare): wa.shareToStory() called SYNCHRONOUSLY from user gesture.
 *
 * The two-step split is required because Telegram WebView demands
 * wa.shareToStory() be called from a user gesture context (synchronous click).
 * Async operations (HTTP request) before it cause silent blocking.
 */
export const useShareToStory = (options?: UseShareToStoryOptions): UseShareToStoryReturn => {
  const [isPreparing, setIsPreparing] = useState(false)
  const [shareData, setShareData] = useState<CreateShareResponse | null>(null)
  const [error, setError] = useState<Error | null>(null)
  const [shareError, setShareError] = useState<ShareError | null>(null)
  const isAvailable = TelegramUtils.isStoryAvailable()

  const shareDataRef = useRef<CreateShareResponse | null>(null)

  /** Step 1: Get shareUrl from backend */
  const prepareShare = useCallback(async () => {
    setIsPreparing(true)
    setError(null)
    setShareError(null)
    setShareData(null)
    shareDataRef.current = null

    try {
      const data = await createShare()
      setShareData(data)
      shareDataRef.current = data
    } catch (err) {
      const raw = err instanceof Error ? err : new Error(String(err))
      setError(raw)
      setShareError({ raw, code: null })

      // Graceful degradation: allow dialog to open even on error
      const fallbackData: CreateShareResponse = {
        shareUrl: '',
        status: 'pending',
        shareDate: '',
        referralCode: '',
      }
      setShareData(fallbackData)
      shareDataRef.current = fallbackData
    } finally {
      setIsPreparing(false)
    }
  }, [options])

  /** Step 2: Open Telegram Story SYNCHRONOUSLY from click */
  const confirmShare = useCallback(
    (params: ShareToStoryParams) => {
      try {
        TelegramUtils.shareToStory(params)
        options?.onSuccess?.()
      } catch (err) {
        const raw = err instanceof Error ? err : new Error(String(err))
        setError(raw)
        setShareError({ raw, code: null })
        options?.onError?.(raw)
      }
    },
    [options]
  )

  return {
    prepareShare,
    confirmShare,
    isPreparing,
    shareData,
    error,
    shareError,
    isAvailable,
  }
}
