# 😔 Game Over Dialog - Быстрый старт

## ✅ Что уже готово

Глобальный виджет **GameOverDialog** полностью настроен и готов к использованию!

- ✅ Виджет автоматически подключен в `BaseLayout`
- ✅ Управление состоянием через Jotai
- ✅ Адаптивный контент в зависимости от причины проигрыша
- ✅ Утешительные награды и статистика
- ✅ Responsive дизайн

## 🚀 Использование (3 простых шага)

### 1. Импортируйте хук

```typescript
import { useGameOverDialog } from '@/widgets/game-over-dialog'
```

### 2. Получите функцию show

```typescript
const { show } = useGameOverDialog()
```

### 3. Вызовите при проигрыше

```typescript
show({
  winnerName: 'Player123',
  playerPosition: 3,
  earnedPoints: 25,
  reason: 'winner_found'
})
```

## 📝 Полный пример

```typescript
import { useGameOverDialog } from '@/widgets/game-over-dialog'

function GameComponent() {
  const { show } = useGameOverDialog()

  const handleGameEnd = (result) => {
    if (!result.isWinner) {
      show({
        winnerName: result.winner,
        playerPosition: result.position,
        earnedPoints: result.consolationPoints,
        consolationPrize: result.consolationAmount,
        reason: 'winner_found'
      })
    }
  }

  return (
    // ваш компонент
  )
}
```

## 🎭 Типы причин проигрыша

```typescript
type Reason = 
  | 'winner_found'      // Найден победитель
  | 'time_expired'      // Время истекло
  | 'attempts_exceeded' // Попытки закончились
```

## 🎨 Отличия от других диалогов

| Dialog | Когда показывается | Цвет кнопки |
|--------|-------------------|-------------|
| **VictoryDialog** | Победа в игре | Зеленый 🎉 |
| **FirstPlaceDialog** | Выход на 1 место | Синий 🔔 |
| **GameOverDialog** | Проигрыш/конец игры | Красный 😔 |

## 💡 Быстрые примеры

### Победитель найден
```typescript
show({
  winnerName: 'SuperPlayer',
  playerPosition: 2,
  earnedPoints: 50,
  reason: 'winner_found'
})
```

### Время вышло
```typescript
show({
  playerPosition: 5,
  earnedPoints: 20,
  reason: 'time_expired'
})
```

### Попытки закончились
```typescript
show({
  earnedPoints: 10,
  reason: 'attempts_exceeded',
  additionalInfo: 'Купите дополнительные ключи для новых попыток'
})
```

### С утешительным призом
```typescript
show({
  winnerName: 'Player1',
  playerPosition: 3,
  earnedPoints: 30,
  consolationPrize: 100,
  reason: 'winner_found'
})
```

### С оставшимися попытками
```typescript
show({
  earnedPoints: 15,
  attemptsLeft: 2,
  reason: 'time_expired',
  additionalInfo: 'У вас еще есть попытки!'
})
```

## 📚 Дополнительная документация

- `README.md` - полная документация API
- `examples/game-over-dialog.example.tsx` - интерактивные примеры
- `examples/integration-with-websocket.example.ts` - интеграция с WebSocket

## 🛠️ Расположение файлов

```
widgets/game-over-dialog/
├── index.tsx                      # Экспорты
├── QUICK_START.md                # Этот файл
├── README.md                     # Полная документация
├── model/
│   └── game-over-dialog.store.ts # Jotai atoms
├── ui/
│   └── game-over-dialog.tsx      # UI компонент
├── hooks/
│   └── use-game-over-dialog.ts   # Хук
└── examples/                     # Примеры
```

---

**Готово! Начните использовать прямо сейчас! 🚀**

