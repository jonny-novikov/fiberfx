import { forwardRef, useEffect, useImperativeHandle, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { cn, TelegramUtils } from '@/shared/libs'
import type { EmojiSetConfig } from '@/shared/libs/contexts/emoji-set.context'
import { SpriteEmoji } from '@/shared/ui'

/**
 * Demo emoji set configuration (static, hardcoded for onboarding)
 * Uses the dark emoji set sprite with known dimensions
 */
const DEMO_SPRITE_CONFIG: EmojiSetConfig = {
  spriteUrl: '/images/emoji-set/dark-emoji-set.png',
  cellSize: 72,
  gridCols: 10,
  gridRows: 12,
}

/**
 * 4 emoji codes for demo keyboard
 * XXYY format: XX=column, YY=row
 * Using emojis from row 1 (columns 4-7)
 */
const DEMO_EMOJIS = ['0401', '0501', '0601', '0701']
const TOTAL_SLOTS = 3

export interface DemoGameSlideRef {
  /**
   * Проверить код и вернуть результат
   */
  checkCode: () => boolean
  /**
   * Проверить, заполнены ли все слоты
   */
  isComplete: () => boolean
}

interface DemoGameSlideProps {
  /**
   * Callback вызывается когда код отгадан
   */
  onSuccess?: () => void
  /**
   * Callback вызывается при изменении состояния заполненности слотов
   */
  onCompleteChange?: (isComplete: boolean) => void
}

/**
 * Слот для выбранного эмодзи
 */
const Slot = ({
  emoji,
  isActive,
  isSuccess,
}: {
  emoji?: string
  isActive: boolean
  isSuccess: boolean
}) => {
  return (
    <div
      className={cn(
        'relative size-[clamp(2rem,14vw,6rem)] rounded-xl flex items-center justify-center transition-all duration-200 border-2',
        {
          // Активный слот (можно выбрать сейчас)
          'bg-slot-active border-slot-active': isActive && !emoji,
          // Слот с эмодзи или пустой неактивный
          'bg-slot border-slot': emoji || !isActive,
          'bg-[#F2F9EE] border-[#00CB5B]': isSuccess,
        }
      )}
    >
      {emoji ? (
        <SpriteEmoji code={emoji} size={42} config={DEMO_SPRITE_CONFIG} />
      ) : isActive ? (
        <span className="text-xl font-bold text-white/60 animate-pulse">?</span>
      ) : null}
    </div>
  )
}

/**
 * Кнопка эмодзи на клавиатуре
 */
const EmojiButton = ({
  emoji,
  isSelected,
  disabled,
  onClick,
}: {
  emoji: string
  isSelected: boolean
  disabled: boolean
  onClick: () => void
}) => {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className={cn(
        'size-[clamp(2rem,14vw,6rem)] rounded-xl flex items-center justify-center transition-all duration-200 border-2 border-primary/10',
        'active:scale-90',
        {
          'border-primary': isSelected,
          'bg-white/10 hover:bg-white/20': !isSelected && !disabled,
          'bg-white/5 opacity-50 cursor-not-allowed': disabled && !isSelected,
        }
      )}
    >
      <SpriteEmoji code={emoji} size={42} config={DEMO_SPRITE_CONFIG} />
    </button>
  )
}

/**
 * Слайд 2: Демо-игра
 * Мини-игра с 4 эмодзи-кнопками и 3 слотами
 */
export const DemoGameSlide = forwardRef<DemoGameSlideRef, DemoGameSlideProps>(
  ({ onSuccess, onCompleteChange }, ref) => {
    const { t } = useTranslation('onboarding')
    const [selectedEmojis, setSelectedEmojis] = useState<(string | undefined)[]>([
      undefined,
      undefined,
      undefined,
    ])
    const [error, setError] = useState<string | null>(null)
    const [isSuccess, setIsSuccess] = useState(false)

    const selectedCount = selectedEmojis.filter(Boolean).length
    const isComplete = selectedCount >= TOTAL_SLOTS

    // Уведомляем родителя об изменении состояния заполненности
    useEffect(() => {
      onCompleteChange?.(isComplete)
    }, [isComplete, onCompleteChange])

    // Найти индекс первого пустого слота
    const findFirstEmptySlot = (): number => {
      for (let i = 0; i < TOTAL_SLOTS; i++) {
        if (!selectedEmojis[i]) {
          return i
        }
      }
      return -1
    }

    // Toggle эмодзи через клавиатуру (добавить если нет, удалить если есть)
    const handleEmojiClick = (emoji: string) => {
      if (isSuccess) return // Если уже успех, не даём менять

      // Haptic feedback при выборе эмодзи
      TelegramUtils.impactOccurred('light')

      // Найти индекс этого эмодзи в слотах
      const existingIndex = selectedEmojis.findIndex((e) => e === emoji)

      if (existingIndex !== -1) {
        // Удалить из слота
        const newEmojis = [...selectedEmojis]
        newEmojis[existingIndex] = undefined
        setSelectedEmojis(newEmojis)
      } else {
        // Добавить в первый пустой слот
        const firstEmptyIndex = findFirstEmptySlot()
        if (firstEmptyIndex !== -1) {
          const newEmojis = [...selectedEmojis]
          newEmojis[firstEmptyIndex] = emoji
          setSelectedEmojis(newEmojis)
        }
      }

      // Сбрасываем ошибку при изменении
      setError(null)
    }

    // Проверить код - вызывается извне через ref
    const checkCode = (): boolean => {
      if (!isComplete) return false

      setIsSuccess(true)
      setError(null)
      TelegramUtils.notificationOccurred('success')
      onSuccess?.()
      return true
    }

    // Expose методы через ref
    useImperativeHandle(ref, () => ({
      checkCode,
      isComplete: () => isComplete,
    }))

    const firstEmptyIndex = findFirstEmptySlot()

    return (
      <div className="h-full flex flex-col items-center px-6 overflow-y-auto">
        {/* Верхняя часть - изображение (гибкая) */}
        <div className="flex-1 min-h-0 flex items-end justify-center">
          <img
            src="/images/onboarding/cringe.webp"
            alt={t('demo.imageAlt')}
            className="w-16 h-16 object-contain"
          />
        </div>

        {/* Контент - фиксированный */}
        <div className="shrink-0 w-full flex flex-col items-center">
          <h1 className="text-[clamp(1.25rem,14vw,2.25rem)] font-bold text-center leading-[1.1] tracking-[-0.03em] mt-3 whitespace-pre-line">
            {t('demo.title')}
          </h1>
          <p className="text-[clamp(0.8rem,10vw,1.1rem)] leading-[1.1] text-center mt-3 opacity-80">
            {t('demo.instruction')}
          </p>

          {/* Слоты */}
          <div className="flex gap-2 mt-4">
            {Array.from({ length: TOTAL_SLOTS }).map((_, index) => (
              <Slot
                key={index}
                emoji={selectedEmojis[index]}
                isActive={index === firstEmptyIndex && !isComplete}
                isSuccess={isSuccess}
              />
            ))}
          </div>

          <div className="h-[clamp(3rem,12vh,8rem)] flex flex-col items-center justify-center">
            {/* Сообщение об ошибке */}
            {error && (
              <p className="mt-2 text-red-400 font-medium text-xs animate-in fade-in duration-300">
                {error}
              </p>
            )}

            {/* Сообщение об успехе */}
            {isSuccess && (
              <div className="mt-2 text-center animate-in fade-in zoom-in duration-300">
                <p className="text-primary font-bold text-base">{t('demo.success')}</p>
                <p className="text-xs opacity-60">{t('demo.successHint')}</p>
              </div>
            )}
          </div>

          {/* Клавиатура */}
          <div className="grid grid-cols-4 gap-2  mb-[clamp(1rem,4vh,3rem)]">
            {DEMO_EMOJIS.map((emoji) => {
              const isSelected = selectedEmojis.includes(emoji)
              return (
                <EmojiButton
                  key={emoji}
                  emoji={emoji}
                  isSelected={isSelected}
                  disabled={isSuccess}
                  onClick={() => handleEmojiClick(emoji)}
                />
              )
            })}
          </div>
        </div>
      </div>
    )
  }
)

DemoGameSlide.displayName = 'DemoGameSlide'
