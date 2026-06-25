import { atom } from 'jotai'

export interface ShareRewardDialogData {
  rewardedAt: string // ISO timestamp, used as dedup key
}

export const shareRewardDialogOpenAtom = atom<boolean>(false)

export const shareRewardDialogDataAtom = atom<ShareRewardDialogData | null>(null)

export const showShareRewardDialogAtom = atom(null, (_get, set, data: ShareRewardDialogData) => {
  set(shareRewardDialogDataAtom, data)
  set(shareRewardDialogOpenAtom, true)
})

export const hideShareRewardDialogAtom = atom(null, (_get, set) => {
  set(shareRewardDialogOpenAtom, false)
  setTimeout(() => {
    set(shareRewardDialogDataAtom, null)
  }, 300)
})
