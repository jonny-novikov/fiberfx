import { SpriteEmoji } from '../sprite-emoji'

import { cn } from '@/shared/libs'

export interface PreviousAttemptProps {
  emojis: string[]
  className?: string
  emojiSize?: number
  points?: number
  onClick?: () => void
}

export const PreviousAttempt = ({
  emojis,
  className = '',
  emojiSize = 14,
  points = 0,
  onClick,
}: PreviousAttemptProps) => {
  return (
    <div className="flex justify-center">
      <button
        className={cn(
          'text-xs font-medium flex items-center justify-center leading-none gap-2',
          onClick && 'cursor-pointer hover:opacity-70 active:opacity-50 transition-opacity',
          className
        )}
        onClick={onClick}
      >
        <span>Предыдущая попытка:</span>
        <span className="inline-flex gap-1 items-center">
          {emojis.map((emoji, index) =>
            emoji ? (
              <SpriteEmoji key={index} code={emoji} size={emojiSize} />
            ) : (
              <span key={index} style={{ width: `${emojiSize}px`, display: 'inline-block' }} />
            )
          )}
        </span>
        {points !== 0 ? <span>{points}</span> : null}
      </button>
    </div>
  )
}
