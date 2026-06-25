# 🎮 Шпаргалка по игровым диалогам

> Быстрый справочник для выбора правильного модального окна

## 🎯 Какой диалог использовать?

### Игрок ПОБЕДИЛ? → VictoryDialog 🎉
```typescript
import { useVictoryDialog } from '@/widgets/victory-dialog'
const { show } = useVictoryDialog()

show({
  prizeAmount: 2500,
  earnedPoints: 150
})
```
**Цвет:** Зеленый • **Эмодзи:** 🎉🎊

---

### Игрок НЕ УСПЕЛ победить? → GameOverDialog 😔
```typescript
import { useGameOverDialog } from '@/widgets/game-over-dialog'
const { show } = useGameOverDialog()

show({
  winnerName: 'Winner',
  playerPosition: 2,
  earnedPoints: 50,
  reason: 'winner_found' // или 'time_expired', 'attempts_exceeded'
})
```
**Цвет:** Красный/Синий • **Эмодзи:** 💪

---

### Игрок вышел на 1 МЕСТО во время игры? → FirstPlaceDialog 🥇
```typescript
// Обычно управляется напрямую через props
<FirstPlaceDialog
  open={isOpen}
  onOpenChange={setIsOpen}
  onSubscribe={handleSubscribe}
/>
```
**Цвет:** Синий • **Эмодзи:** 🔔

---

### Техническая ОШИБКА? → ErrorDialog ❌
```typescript
<ErrorDialog
  open={isOpen}
  onOpenChange={setIsOpen}
  eventId="error-123"
/>
```
**Цвет:** Красный • **Эмодзи:** ⚠️

---

## 🔄 Блок-схема выбора

```
Игра завершена?
├─ ДА → Игрок победил?
│        ├─ ДА → VictoryDialog 🎉
│        └─ НЕТ → GameOverDialog 😔
│
└─ НЕТ → Игрок вышел на 1 место впервые?
         ├─ ДА → FirstPlaceDialog 🥇
         └─ НЕТ → ничего не показываем

Произошла ошибка?
└─ ДА → ErrorDialog ❌
```

## 📋 Быстрое сравнение

| Ситуация | Диалог | Импорт |
|----------|--------|--------|
| Победа в игре | VictoryDialog | `@/widgets/victory-dialog` |
| Проигрыш в игре | GameOverDialog | `@/widgets/game-over-dialog` |
| Вышел на 1 место | FirstPlaceDialog | `@/widgets/first-place-dialog` |
| Техническая ошибка | ErrorDialog | `@/widgets/error-dialog` |

## 💡 Частые кейсы

### Обработка завершения игры
```typescript
const { show: showVictory } = useVictoryDialog()
const { show: showGameOver } = useGameOverDialog()

socket.on('game:ended', (data) => {
  if (data.isWinner) {
    showVictory({
      prizeAmount: data.prize,
      earnedPoints: data.points
    })
  } else {
    showGameOver({
      winnerName: data.winner,
      playerPosition: data.position,
      earnedPoints: data.consolationPoints,
      reason: 'winner_found'
    })
  }
})
```

### Обработка таймаута
```typescript
const { show } = useGameOverDialog()

socket.on('game:timeout', (data) => {
  show({
    playerPosition: data.finalPosition,
    earnedPoints: data.earnedPoints,
    reason: 'time_expired'
  })
})
```

### Обработка окончания попыток
```typescript
const { show } = useGameOverDialog()

if (attemptsLeft === 0) {
  show({
    earnedPoints: totalPoints,
    reason: 'attempts_exceeded',
    additionalInfo: 'Купите ключи для продолжения'
  })
}
```

## 🎨 Цветовой код

- 🟢 **Зеленый** (#34C759) = Успех, победа
- 🔵 **Синий** (#0050FF) = Действие, промежуточное достижение
- 🔴 **Красный** (#FF2F00) = Завершение, ошибка

## ⚡ Хуки vs Atoms

### Рекомендуется (через хук)
```typescript
const { show, hide } = useVictoryDialog()
const { show, hide } = useGameOverDialog()
```

### Альтернатива (через atoms)
```typescript
const show = useSetAtom(showVictoryDialogAtom)
const hide = useSetAtom(hideVictoryDialogAtom)
```

---

**Все диалоги уже интегрированы в `BaseLayout` и готовы к использованию!** ✅

