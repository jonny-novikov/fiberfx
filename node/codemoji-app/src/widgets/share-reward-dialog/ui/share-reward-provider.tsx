import { useSetAtom } from 'jotai'
import { useEffect, useRef } from 'react'

import { showShareRewardDialogAtom } from '../model/share-reward-dialog.store'

import { useShareStatusQuery } from '@/features/share-story/api/share.queries'

const LAST_SEEN_REWARD_KEY = 'codemoji_last_seen_reward_share_id'

export const ShareRewardProvider = () => {
  const { data } = useShareStatusQuery()
  const showDialog = useSetAtom(showShareRewardDialogAtom)
  const lastSeenRef = useRef<string | null>(null)

  useEffect(() => {
    try {
      lastSeenRef.current = localStorage.getItem(LAST_SEEN_REWARD_KEY)
    } catch {}
  }, [])

  useEffect(() => {
    if (!data) return

    if (
      data.status === 'rewarded' &&
      data.rewardedAt !== null &&
      data.rewardedAt !== lastSeenRef.current
    ) {
      lastSeenRef.current = data.rewardedAt
      try {
        localStorage.setItem(LAST_SEEN_REWARD_KEY, data.rewardedAt)
      } catch {}

      showDialog({ rewardedAt: data.rewardedAt })
    }
  }, [data, showDialog])

  return null
}
