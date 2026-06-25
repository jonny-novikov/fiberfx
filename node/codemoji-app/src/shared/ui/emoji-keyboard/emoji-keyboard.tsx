import { useAtom, useSetAtom } from 'jotai'

import { selectedEmojisAtom, toggleEmojiAtom } from '@/features/game/model/gameplay.store'
import { cn, TelegramUtils } from '@/shared/libs'
import { SpriteEmoji, Spinner } from '@/shared/ui'

export interface EmojiKeyboardProps {
  /** Список эмодзи для отображения */
  emojis: string[]
  /** Callback при выборе эмодзи (опционально, помимо jotai) */
  onEmojiSelect?: (emoji: string) => void
  /** Ранее использованные эмодзи (подсвечиваются серым) */
  usedEmojis?: string[]
  /** Максимальное количество эмодзи, которое можно выбрать */
  maxEmojis?: number
  /** Количество колонок в сетке */
  columns?: number
  /** Размер одной ячейки */
  cellSize?: 'sm' | 'md' | 'lg' | 'auto'
  /** Дополнительные классы */
  loading?: boolean
  className?: string
}

export const EmojiKeyboard = ({
  emojis,
  onEmojiSelect,
  usedEmojis = [],
  maxEmojis = 10,
  columns = 8,
  cellSize = 'md',
  className,
  loading = false,
}: EmojiKeyboardProps) => {
  const [selectedEmojis] = useAtom(selectedEmojisAtom)
  const toggleEmoji = useSetAtom(toggleEmojiAtom)

  // Размеры ячеек
  const cellSizeClasses = {
    sm: 'w-9 h-9 text-xl',
    md: 'w-11 h-11 text-2xl',
    lg: 'w-14 h-14 text-3xl',
    auto: 'w-full aspect-square',
  }

  // Размер эмодзи в пикселях
  const emojiSize = cellSize === 'sm' ? 26 : cellSize === 'md' ? 30 : 34

  const handleEmojiClick = (emoji: string) => {
    const isSelected = selectedEmojis.includes(emoji)

    // Подсчитываем реальное количество выбранных эмодзи (не undefined)
    const selectedCount = selectedEmojis.filter(Boolean).length

    // Если эмодзи не выбран и достигнут лимит - не даем выбрать
    if (!isSelected && selectedCount >= maxEmojis) {
      return
    }

    // Haptic feedback при выборе эмодзи
    TelegramUtils.selectionChanged()

    // Toggle эмодзи в store
    toggleEmoji(emoji)

    // Вызываем callback если передан
    onEmojiSelect?.(emoji)
  }

  // Подсчитываем реальное количество выбранных эмодзи (не undefined)
  const selectedCount = selectedEmojis.filter(Boolean).length

  if (loading) {
    return (
      <div className={cn('flex flex-col justify-center items-center', className)}>
        <Spinner className="size-10" />
      </div>
    )
  }
  return (
    <div className={cn('flex flex-col', className)}>
      {/* Сетка с эмодзи */}
      <div className="overflow-y-auto px-2 pb-4 pt-1 h-full scrollbar-custom">
        <div
          key={emojis[0]}
          className={cn('grid gap-1.5 justify-items-center', {
            'grid-cols-6': columns === 6,
            'grid-cols-7': columns === 7,
            'grid-cols-8': columns === 8,
            'grid-cols-9': columns === 9,
            'grid-cols-10': columns === 10,
          })}
        >
          {emojis.map((emoji, index) => {
            const isSelected = selectedEmojis.includes(emoji)
            const isUsed = usedEmojis.includes(emoji)

            return (
              <button
                key={`${emoji}-${index}`}
                onClick={() => handleEmojiClick(emoji)}
                disabled={!isSelected && selectedCount >= maxEmojis}
                className={cn(
                  'flex items-center justify-center',
                  'rounded-[10px] transition-all duration-150',
                  'active:scale-90 animate-emoji-pop',
                  cellSizeClasses[cellSize],
                  {
                    'bg-green-100 ring-2 ring-green-400 shadow-md hover:scale-110': isSelected,
                    'bg-white/40 hover:bg-white/60 hover:scale-110': !isSelected && isUsed,
                    'bg-white ring-1 ring-black/10 border border-black/10 hover:bg-gray-100 hover:scale-110':
                      !isSelected && !isUsed && selectedCount < maxEmojis,
                    'bg-gray-100 text-gray-400 cursor-not-allowed opacity-50':
                      !isSelected && selectedCount >= maxEmojis,
                  }
                )}
                style={{ animationDelay: `${index * 15}ms` }}
                type="button"
              >
                <SpriteEmoji
                  code={emoji}
                  size={emojiSize}
                  className="animate-emoji-nudge"
                  style={{ animationDelay: `${index * 15 + 1100}ms` }}
                />
              </button>
            )
          })}
        </div>
      </div>
    </div>
  )
}
