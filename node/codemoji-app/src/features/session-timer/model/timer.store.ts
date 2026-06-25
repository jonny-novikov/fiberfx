import { atom } from 'jotai'

/**
 * Round end time from server
 */
export const roundEndTimeAtom = atom<string | null>(null)

/**
 * Derived atom for time left calculation
 */
export const timeLeftAtom = atom((get) => {
  const endTime = get(roundEndTimeAtom)

  if (!endTime) {
    return { hours: 0, minutes: 0, seconds: 0 }
  }

  const now = new Date().getTime()
  const end = new Date(endTime).getTime()
  const distance = end - now

  if (distance > 0) {
    const hours = Math.floor(distance / (1000 * 60 * 60))
    const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60))
    const seconds = Math.floor((distance % (1000 * 60)) / 1000)

    return { hours, minutes, seconds }
  }

  return { hours: 0, minutes: 0, seconds: 0 }
})

/**
 * Action to set round end time
 */
export const setRoundEndTimeAtom = atom(null, (get, set, endTime: string | null) => {
  set(roundEndTimeAtom, endTime)
})

/**
 * Action to clear timer
 */
export const clearTimerAtom = atom(null, (get, set) => {
  set(roundEndTimeAtom, null)
})
