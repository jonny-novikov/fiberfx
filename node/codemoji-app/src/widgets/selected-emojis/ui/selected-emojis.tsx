import { useAtom, useSetAtom } from 'jotai'
import { useTranslation } from 'react-i18next'

import {
  selectedEmojisAtom,
  removeEmojiAtom,
  clearEmojisAtom,
} from '@/features/game/model/gameplay.store'
import { cn } from '@/shared/libs'
import { AppleEmoji } from '@/shared/ui'

export interface SelectedEmojisProps {
  /** Максимальное количество эмодзи, которое можно выбрать */
  maxEmojis?: number
  /** Дополнительные классы */
  className?: string
}

export const SelectedEmojis = ({ maxEmojis = 10, className }: SelectedEmojisProps) => {
  const { t } = useTranslation()
  const [selectedEmojis] = useAtom(selectedEmojisAtom)
  const removeEmoji = useSetAtom(removeEmojiAtom)
  const clearEmojis = useSetAtom(clearEmojisAtom)

  const handleRemoveEmoji = (emoji: string) => {
    removeEmoji(emoji)
  }

  const handleClear = () => {
    clearEmojis()
  }

  return (
    <div className={cn('bg-white rounded-2xl p-4', className)}>
      {/* Заголовок с счетчиком */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <span className="text-sm font-medium text-gray-700">{t('selectedEmojis.title')}</span>
          <span
            className={cn(
              'text-xs font-bold px-2 py-0.5 rounded-full',
              selectedEmojis.length >= maxEmojis
                ? 'bg-red-100 text-red-600'
                : 'bg-blue-100 text-blue-600'
            )}
          >
            {selectedEmojis.length}/{maxEmojis}
          </span>
        </div>

        {/* Кнопка очистки */}
        {selectedEmojis.length > 0 && (
          <button
            onClick={handleClear}
            className="text-xs text-gray-500 hover:text-red-500 transition-colors px-2 py-1 rounded hover:bg-gray-100"
          >
            {t('selectedEmojis.clear')}
          </button>
        )}
      </div>

      {/* Список выбранных эмодзи */}
      <div className="flex flex-wrap gap-2 min-h-[60px]">
        {selectedEmojis.length === 0 ? (
          <div className="w-full flex items-center justify-center text-gray-400 text-sm py-4">
            {t('selectedEmojis.emptyState')}
          </div>
        ) : (
          selectedEmojis.map((emoji, index) => (
            <div key={`${emoji}-${index}`} className="relative group">
              <div className="w-12 h-12 flex items-center justify-center bg-green-50 border-2 border-green-300 rounded-xl transition-all duration-200 hover:scale-110">
                <AppleEmoji id={emoji} size={36} />
              </div>
              {/* Кнопка удаления при наведении */}
              <button
                onClick={() => handleRemoveEmoji(emoji)}
                className="absolute -top-1.5 -right-1.5 w-5 h-5 bg-red-500 text-white rounded-full flex items-center justify-center text-xs opacity-0 group-hover:opacity-100 transition-opacity shadow-md hover:bg-red-600"
                aria-label={t('selectedEmojis.removeLabel')}
              >
                ×
              </button>
            </div>
          ))
        )}
      </div>

      {/* Предупреждение о лимите */}
      {selectedEmojis.length >= maxEmojis && (
        <div className="mt-3 text-xs text-red-500 text-center">
          {t('selectedEmojis.limitReached')}
        </div>
      )}
    </div>
  )
}
