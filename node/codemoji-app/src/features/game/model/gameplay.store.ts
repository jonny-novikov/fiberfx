import { atom } from 'jotai'

/**
 * Atom для хранения выбранных эмодзи в текущей попытке
 */
export const selectedEmojisAtom = atom<string[]>([])

/**
 * Atom для хранения заблокированных индексов эмодзи
 * Заблокированные эмодзи нельзя удалить или перетащить
 */
export const lockedEmojisAtom = atom<number[]>([])

/**
 * Atom для добавления эмодзи в выбранные
 */
export const addEmojiAtom = atom(null, (get, set, emoji: string) => {
  const current = get(selectedEmojisAtom)
  if (!current.includes(emoji)) {
    set(selectedEmojisAtom, [...current, emoji])
  }
})

/**
 * Atom для удаления эмодзи из выбранных
 */
export const removeEmojiAtom = atom(null, (get, set, emoji: string) => {
  const current = get(selectedEmojisAtom)
  set(
    selectedEmojisAtom,
    current.filter((e) => e !== emoji)
  )
})

/**
 * Atom для очистки всех выбранных эмодзи (кроме заблокированных)
 * Заблокированные эмодзи остаются на своих исходных позициях
 */
export const clearEmojisAtom = atom(null, (get, set) => {
  const current = get(selectedEmojisAtom)
  const locked = get(lockedEmojisAtom)

  if (locked.length === 0) {
    // Если нет заблокированных - просто очищаем всё
    set(selectedEmojisAtom, [])
    return
  }

  // Создаём разреженный массив, где заблокированные эмодзи остаются на своих местах
  // а незаблокированные позиции остаются пустыми (undefined)
  const newEmojis = current.reduce<string[]>((acc, emoji, index) => {
    if (locked.includes(index)) {
      acc[index] = emoji
    }
    return acc
  }, [])

  set(selectedEmojisAtom, newEmojis)
  // Индексы заблокированных НЕ меняются!
})

/**
 * Atom для toggle эмодзи (добавить если нет, удалить если есть)
 * Не удаляет заблокированные эмодзи
 */
export const toggleEmojiAtom = atom(null, (get, set, emoji: string) => {
  const current = get(selectedEmojisAtom)
  const locked = get(lockedEmojisAtom)

  // Ищем эмодзи в массиве (включая undefined элементы)
  let emojiIndex = -1
  for (let i = 0; i < current.length; i++) {
    if (current[i] === emoji) {
      emojiIndex = i
      break
    }
  }

  if (emojiIndex !== -1) {
    // Эмодзи уже есть - удаляем его

    // Если эмодзи заблокирован, не удаляем
    if (locked.includes(emojiIndex)) {
      return
    }

    // Создаём разреженный массив с удалённым эмодзи
    const newEmojis = [...current]
    delete newEmojis[emojiIndex] // Создаём "дырку" в массиве

    set(selectedEmojisAtom, newEmojis)
    // Индексы заблокированных НЕ меняются!
  } else {
    // Эмодзи нет - добавляем его

    // Находим первый пустой незаблокированный слот
    let firstEmptyIndex = -1
    for (let i = 0; i < 6; i++) {
      // Предполагаем максимум 6 слотов
      if (!current[i] && !locked.includes(i)) {
        firstEmptyIndex = i
        break
      }
    }

    if (firstEmptyIndex === -1) {
      // Нет свободных слотов
      return
    }

    // Создаём новый массив с эмодзи на нужной позиции
    const newEmojis = [...current]
    newEmojis[firstEmptyIndex] = emoji
    set(selectedEmojisAtom, newEmojis)
  }
})

/**
 * Atom для переупорядочивания эмодзи (drag and drop)
 * Заблокированные элементы остаются на своих местах
 */
export const reorderEmojisAtom = atom(
  null,
  (get, set, { oldIndex, newIndex }: { oldIndex: number; newIndex: number }) => {
    const current = [...get(selectedEmojisAtom)]
    const locked = get(lockedEmojisAtom)

    // Если пытаемся переместить заблокированный элемент - игнорируем
    if (locked.includes(oldIndex)) {
      return
    }

    // Создаем карту заблокированных элементов: индекс -> эмодзи
    const lockedMap = new Map<number, string>()
    locked.forEach((index) => {
      lockedMap.set(index, current[index])
    })

    // Извлекаем только незаблокированные элементы
    const unlocked: string[] = []
    current.forEach((emoji, index) => {
      if (!locked.includes(index)) {
        unlocked.push(emoji)
      }
    })

    // Находим индекс перемещаемого элемента в массиве незаблокированных
    let unlockedOldIndex = 0
    for (let i = 0; i < oldIndex; i++) {
      if (!locked.includes(i)) {
        unlockedOldIndex++
      }
    }

    // Находим целевой индекс в массиве незаблокированных
    // Считаем количество незаблокированных элементов, которые должны быть
    // ПЕРЕД вставляемым элементом на его новой позиции
    let unlockedNewIndex = 0

    if (oldIndex < newIndex) {
      // Перемещение вправо: считаем незаблокированные от oldIndex+1 до newIndex включительно
      for (let i = oldIndex + 1; i <= newIndex; i++) {
        if (!locked.includes(i)) {
          unlockedNewIndex++
        }
      }
      // Добавляем все незаблокированные, которые были до oldIndex
      unlockedNewIndex += unlockedOldIndex
    } else {
      // Перемещение влево: считаем незаблокированные от newIndex до oldIndex-1
      for (let i = newIndex; i < oldIndex; i++) {
        if (!locked.includes(i)) {
          unlockedNewIndex++
        }
      }
      // Вычитаем из позиции исходного элемента
      unlockedNewIndex = unlockedOldIndex - unlockedNewIndex
    }

    // Перемещаем элемент в массиве незаблокированных
    const [movedItem] = unlocked.splice(unlockedOldIndex, 1)
    unlocked.splice(unlockedNewIndex, 0, movedItem)

    // Собираем финальный массив
    const result: string[] = []
    let unlockedIndex = 0

    for (let i = 0; i < current.length; i++) {
      if (lockedMap.has(i)) {
        // Заблокированный элемент остается на месте
        result.push(lockedMap.get(i) as string)
      } else {
        // Берем следующий незаблокированный элемент
        result.push(unlocked[unlockedIndex])
        unlockedIndex++
      }
    }

    set(selectedEmojisAtom, result)
  }
)

/**
 * Atom для toggle блокировки эмодзи по индексу
 */
export const toggleEmojiLockAtom = atom(null, (get, set, index: number) => {
  const locked = get(lockedEmojisAtom)

  if (locked.includes(index)) {
    // Разблокировать
    set(
      lockedEmojisAtom,
      locked.filter((i) => i !== index)
    )
  } else {
    // Заблокировать
    set(lockedEmojisAtom, [...locked, index])
  }
})

/**
 * Validation result type for local checks
 */
interface ValidationResult {
  valid: boolean
  message?: string
}

/**
 * Atom для валидации выбранных эмодзи перед отправкой
 * (локальная проверка, не обращается к серверу)
 */
export const validateSelectionAtom = atom((get): ValidationResult => {
  const selected = get(selectedEmojisAtom)
  const selectedCount = selected.filter(Boolean).length

  if (selectedCount !== 6) {
    return {
      valid: false,
      message: `Нужно выбрать все 6 эмодзи (выбрано: ${selectedCount})`,
    }
  }

  return { valid: true }
})

/**
 * Atom для проверки, готовы ли эмодзи к отправке
 */
export const isSelectionReadyAtom = atom((get) => {
  const validation = get(validateSelectionAtom)
  return validation.valid
})

export const resetGameStateAtom = atom(null, (_get, set) => {
  set(selectedEmojisAtom, [])
  set(lockedEmojisAtom, [])
})

export const cleanSelectedEmojisAtom = atom((get) => {
  return get(selectedEmojisAtom).filter(Boolean)
})

/**
 * Atom для массового заполнения слотов эмодзи
 * Заполняет только незаблокированные слоты, сохраняя заблокированные эмодзи на своих местах
 * Фильтрует входные эмодзи, исключая те, которые уже заняты залоченными слотами (для уникальности)
 */
export const fillSlotsAtom = atom(null, (get, set, emojis: string[]) => {
  const locked = get(lockedEmojisAtom)
  const currentEmojis = get(selectedEmojisAtom)
  const newEmojis: string[] = []

  // Собираем эмодзи, которые уже заняты залоченными слотами
  const lockedEmojisSet = new Set<string>()
  locked.forEach((index) => {
    if (currentEmojis[index]) {
      lockedEmojisSet.add(currentEmojis[index])
    }
  })

  // Фильтруем входные эмодзи, исключая те, которые уже залочены
  const filteredEmojis = emojis.filter((emoji) => !lockedEmojisSet.has(emoji))

  let emojiIndex = 0
  for (let i = 0; i < 6; i++) {
    if (locked.includes(i)) {
      // Сохраняем заблокированный эмодзи
      newEmojis[i] = currentEmojis[i]
    } else if (emojiIndex < filteredEmojis.length) {
      // Заполняем незаблокированный слот
      newEmojis[i] = filteredEmojis[emojiIndex]
      emojiIndex++
    }
  }

  set(selectedEmojisAtom, newEmojis)
})

/**
 * Atom для триггера эффекта распада эмодзи
 * Увеличивается при каждой отправке guess'а для запуска анимации
 */
export const disintegrateTriggerAtom = atom(0)

/**
 * Atom для запуска эффекта распада
 */
export const triggerDisintegrateAtom = atom(null, (_get, set) => {
  set(disintegrateTriggerAtom, (prev) => prev + 1)
})
