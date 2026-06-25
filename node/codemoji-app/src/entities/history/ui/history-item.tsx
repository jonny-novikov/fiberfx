import { useEmojiHighlights } from '../lib/use-emoji-highlights'

import { cn } from '@/shared/libs'
import { ProgressBar, SpriteEmoji } from '@/shared/ui'

interface HistoryItemProps {
  gameId: string
  guessId: string
  attemptNumber: number
  emojis: string[]
  progress: number
  points?: number
}

export const HistoryItem = ({
  gameId,
  guessId,
  attemptNumber,
  emojis,
  progress,
  points,
}: HistoryItemProps) => {
  const { emojiStates, cycleEmojiState } = useEmojiHighlights(gameId, guessId)

  return (
    <div className="flex items-center justify-between gap-1 px-2 min-h-[28px]">
      <p className="flex items-center gap-1">
        <span className="text-base">🔖</span>
        <span className="text-sm text-dark-muted">{attemptNumber}</span>
      </p>

      <div className="flex gap-1 items-center justify-center flex-1 ">
        {emojis.map((emoji, index) => {
          const state = emojiStates[index] ?? 'idle'
          return (
            <button
              key={index}
              type="button"
              onClick={() => cycleEmojiState(index)}
              className={cn(
                'flex items-center justify-center rounded-lg border-2 p-1 transition-colors duration-150',
                {
                  'border-transparent': state === 'idle',
                  'border-[#4CAF50] bg-[#E8F5E9]': state === 'green',
                  'border-[#FFC107] bg-[#FFF8E1]': state === 'yellow',
                  'border-[#F44336] bg-[#FFEBEE]': state === 'red',
                }
              )}
            >
              <SpriteEmoji code={emoji} size={24} />
            </button>
          )
        })}
      </div>

      <div className="flex-1 max-w-20 text-right flex flex-col gap-1 justify-center">
        <p className="text-sm text-dark-muted font-medium leading-none">{points}</p>
        <ProgressBar progress={progress} className="h-[7px]" colorClassName="bg-[#54C0EC]" />
      </div>
    </div>
  )
}
