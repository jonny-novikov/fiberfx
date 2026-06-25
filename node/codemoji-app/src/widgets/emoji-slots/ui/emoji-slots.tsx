import {
  DndContext,
  closestCenter,
  PointerSensor,
  useSensor,
  useSensors,
  DragOverlay,
} from '@dnd-kit/core'
import { SortableContext, useSortable, horizontalListSortingStrategy } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import { useAtom, useAtomValue, useSetAtom } from 'jotai'
import { useState, useRef, useEffect } from 'react'
import { useTranslation } from 'react-i18next'

import {
  selectedEmojisAtom,
  reorderEmojisAtom,
  lockedEmojisAtom,
  toggleEmojiLockAtom,
  disintegrateTriggerAtom,
} from '@/features/game/model/gameplay.store'
import { cn, disintegrate } from '@/shared/libs'
import { SpriteEmoji } from '@/shared/ui'

export interface EmojiSlotsProps {
  totalSlots?: number
  className?: string
}

interface SlotItemProps {
  id: string
  emoji?: string
  isActive: boolean
  isLocked: boolean
  isEmojiLocked: boolean
  onEmojiClick: () => void
  setSlotRef: (node: HTMLDivElement | null) => void
  lockAlt: string
}

const SlotItem = ({
  id,
  emoji,
  isActive,
  isLocked,
  isEmojiLocked,
  onEmojiClick,
  setSlotRef,
  lockAlt,
}: SlotItemProps) => {
  const { attributes, listeners, setNodeRef, transform, isDragging } = useSortable({
    id,
    disabled: !emoji || isEmojiLocked,
  })

  const style = {
    transform: CSS.Transform.toString(transform),
    zIndex: isDragging ? 999 : undefined,
  }

  // Комбинируем refs
  const combinedRef = (node: HTMLDivElement | null) => {
    setNodeRef(node)
    setSlotRef(node)
  }

  return (
    <div
      ref={combinedRef}
      style={style}
      {...(emoji && !isEmojiLocked ? { ...attributes, ...listeners } : {})}
      onClick={emoji && !isActive && !isLocked ? onEmojiClick : undefined}
      className={cn(
        'relative shrink-0 size-13 rounded-[0.625rem] flex items-center justify-center border-2 border-transparent',
        {
          // Заблокированный эмодзи - фон с синим бордером
          'bg-primary/10 border-border': emoji && isEmojiLocked,
          // Выбранный эмодзи - светлый фон
          'bg-primary/10 border-transparent': (emoji && !isEmojiLocked) || isLocked,
          'cursor-move touch-none': emoji && !isDragging && !isEmojiLocked,
          'cursor-pointer': emoji && !isDragging,
          // Перетаскивание
          'opacity-30': isDragging,
          // Активный слот (можно выбрать сейчас) - голубой фон
          'bg-active-slot border-active-slot': isActive,
        }
      )}
    >
      {/* Выбранный эмодзи */}
      {emoji && !isDragging && <SpriteEmoji code={emoji} size={40} />}

      {/* Индикатор блокировки */}
      {emoji && isEmojiLocked && !isDragging && (
        <div className="absolute -top-1 -right-1 size-3.25 bg-card border-2 border-border rounded-sm flex items-center justify-center">
          {/* <AppleEmoji id="lock" size={8} /> */}
          {/* <LockIcon className="size-2" /> */}
          <img src="/images/common/lock.png" alt={lockAlt} className="size-2" />
        </div>
      )}

      {/* Активный слот - вопросик */}
      <div
        className={cn(
          'absolute inset-0 flex items-center justify-center transition-all duration-300',
          isActive ? 'scale-100 opacity-100' : 'scale-0 opacity-0'
        )}
      >
        {isActive && (
          <div className="relative">
            <span className="text-[2rem] font-bold text-white animate-pulse">?</span>
          </div>
        )}
      </div>
    </div>
  )
}

// Компонент для DragOverlay - отображается поверх всего
const DragOverlayItem = ({ emoji }: { emoji: string }) => {
  return (
    <div
      className={cn(
        'relative w-16 h-16 rounded-2xl flex items-center justify-center',
        'border-2 bg-white border-gray-400 shadow-2xl',
        'cursor-grabbing'
      )}
      style={{
        transform: 'rotate(5deg) scale(1.1)',
      }}
    >
      <SpriteEmoji code={emoji} size={48} />
    </div>
  )
}

export const EmojiSlots = ({ totalSlots = 6, className }: EmojiSlotsProps) => {
  const { t } = useTranslation()
  const [selectedEmojis] = useAtom(selectedEmojisAtom)
  const [lockedEmojis] = useAtom(lockedEmojisAtom)
  const reorderEmojis = useSetAtom(reorderEmojisAtom)
  const toggleLock = useSetAtom(toggleEmojiLockAtom)
  const [activeIndex, setActiveIndex] = useState<number>(-1)
  const [draggedEmoji, setDraggedEmoji] = useState<string | null>(null)

  // Refs для слотов (для эффекта распада)
  const slotRefs = useRef<(HTMLDivElement | null)[]>([])
  const containerRef = useRef<HTMLDivElement>(null)

  // Триггер эффекта распада
  const disintegrateTrigger = useAtomValue(disintegrateTriggerAtom)

  // Эффект распада при изменении триггера
  useEffect(() => {
    if (disintegrateTrigger > 0 && containerRef.current) {
      // Запускаем эффект распада для всех слотов с эмодзи (кроме заблокированных)
      const slotsToDisintegrate = slotRefs.current.filter((ref, index) => {
        return ref && selectedEmojis[index] && !lockedEmojis.includes(index)
      })

      slotsToDisintegrate.forEach((slot, index) => {
        if (slot) {
          // Небольшая задержка между слотами для волнового эффекта
          setTimeout(() => {
            disintegrate(slot, {
              duration: 700,
              parent: containerRef.current!,
            })
          }, index * 50)
        }
      })
    }
  }, [disintegrateTrigger])

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: { distance: 5 },
    })
  )

  // Подсчитываем реальное количество выбранных эмодзи (не undefined)
  const selectedCount = selectedEmojis.filter(Boolean).length

  // Находим индекс первого пустого незаблокированного слота
  let firstEmptyIndex = -1
  for (let i = 0; i < totalSlots; i++) {
    if (!selectedEmojis[i] && !lockedEmojis.includes(i)) {
      firstEmptyIndex = i
      break
    }
  }

  const slots = Array.from({ length: totalSlots }, (_, index) => {
    const emoji = selectedEmojis[index]
    const isSelected = !!emoji
    const isEmojiLocked = lockedEmojis.includes(index)

    // Активный слот - это первый пустой незаблокированный слот
    const isActive = index === firstEmptyIndex && selectedCount < totalSlots

    // Слот заблокирован, если он пустой, не является активным и не заблокирован пользователем
    const isLocked = !emoji && !isEmojiLocked && !isActive

    return {
      id: `slot-${index}`,
      index,
      emoji,
      isSelected,
      isActive,
      isLocked,
      isEmojiLocked,
    }
  })

  const sortableItems = slots.filter((slot) => slot.emoji).map((slot) => slot.id)

  const handleDragStart = (event: any) => {
    const draggedIndex = parseInt((event.active.id as string).split('-')[1])
    setActiveIndex(draggedIndex)
    setDraggedEmoji(selectedEmojis[draggedIndex])
  }

  const handleDragEnd = (event: any) => {
    const { over } = event

    if (over && activeIndex !== -1) {
      const overIndex = parseInt((over.id as string).split('-')[1])
      if (activeIndex !== overIndex) {
        reorderEmojis({ oldIndex: activeIndex, newIndex: overIndex })
      }
    }

    setActiveIndex(-1)
    setDraggedEmoji(null)
  }

  return (
    <div ref={containerRef} className={cn('rounded-2xl px-3 relative', className)}>
      <DndContext
        sensors={sensors}
        collisionDetection={closestCenter}
        onDragStart={handleDragStart}
        onDragEnd={handleDragEnd}
      >
        <SortableContext items={sortableItems} strategy={horizontalListSortingStrategy}>
          <div className="flex gap-1.5 justify-center items-center">
            {slots.map((slot) => (
              <SlotItem
                key={slot.id}
                id={slot.id}
                emoji={slot.emoji}
                isActive={slot.isActive}
                isLocked={slot.isLocked}
                isEmojiLocked={slot.isEmojiLocked}
                onEmojiClick={() => toggleLock(slot.index)}
                setSlotRef={(node) => {
                  slotRefs.current[slot.index] = node
                }}
                lockAlt={t('common.lock')}
              />
            ))}
          </div>
        </SortableContext>

        {/* DragOverlay - красивый элемент при перетаскивании */}
        <DragOverlay dropAnimation={null}>
          {draggedEmoji ? <DragOverlayItem emoji={draggedEmoji} /> : null}
        </DragOverlay>
      </DndContext>
    </div>
  )
}
