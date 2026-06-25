import { useEffect, useState } from 'react'

import { type EmojiHighlight, loadHighlights, saveHighlights } from './highlight-storage'

const CYCLE: EmojiHighlight[] = ['idle', 'green', 'yellow', 'red']

export function useEmojiHighlights(gameId: string, guessId: string) {
  const [emojiStates, setEmojiStates] = useState<Record<number, EmojiHighlight>>(() =>
    loadHighlights(gameId, guessId)
  )

  useEffect(() => {
    saveHighlights(gameId, guessId, emojiStates)
  }, [gameId, guessId, emojiStates])

  const cycleEmojiState = (index: number) => {
    setEmojiStates((prev) => {
      const current = prev[index] ?? 'idle'
      const next = CYCLE[(CYCLE.indexOf(current) + 1) % CYCLE.length]
      return { ...prev, [index]: next }
    })
  }

  return { emojiStates, cycleEmojiState }
}
