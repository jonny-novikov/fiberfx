# 🎉 Victory Dialog - Быстрый старт

## ✅ Что уже готово

Глобальный виджет **VictoryDialog** полностью настроен и готов к использованию!

- ✅ Виджет автоматически подключен в `BaseLayout`
- ✅ Управление состоянием через Jotai
- ✅ Все изображения (медаль, конфетти) уже присутствуют
- ✅ Responsive дизайн
- ✅ Анимации открытия/закрытия

## 🚀 Использование (3 простых шага)

### 1. Импортируйте хук

```typescript
import { useVictoryDialog } from '@/widgets/victory-dialog'
```

### 2. Получите функцию show

```typescript
const { show } = useVictoryDialog()
```

### 3. Вызовите при победе

```typescript
show({
  playerName: 'Игрок123',
  prizeAmount: 2500,
  earnedPoints: 150,
})
```

## 📝 Полный пример

```typescript
import { useVictoryDialog } from '@/widgets/victory-dialog'

function GameComponent() {
  const { show } = useVictoryDialog()

  const handleGameComplete = (result) => {
    if (result.isWinner) {
      show({
        playerName: result.playerName,
        prizeAmount: result.prize,
        earnedPoints: result.points,
        leaderboardPosition: result.rank,
        bonusRewards: {
          keys: result.bonusKeys
        }
      })
    }
  }

  return (
    // ваш компонент
  )
}
```

## 🎨 Отличия от FirstPlaceDialog

| FirstPlaceDialog                   | VictoryDialog            |
| ---------------------------------- | ------------------------ |
| Выход на 1 место во время игры     | Финальная победа в игре  |
| Предлагает подписку на уведомления | Поздравление с победой   |
| Синяя кнопка (#0050FF)             | Зеленая кнопка (#34C759) |
| Иконка 🔔                          | Иконка 🎊                |

## 📚 Дополнительная документация

- `README.md` - полная документация API
- `examples/victory-dialog.example.tsx` - интерактивные примеры
- `examples/integration-with-mutations.example.ts` - интеграция с мутациями

## 🛠️ Расположение файлов

```
widgets/victory-dialog/
├── index.tsx                    # Экспорты
├── QUICK_START.md              # Этот файл
├── README.md                   # Полная документация
├── model/
│   └── victory-dialog.store.ts # Jotai atoms
├── ui/
│   └── victory-dialog.tsx      # UI компонент
├── hooks/
│   └── use-victory-dialog.ts   # Хук
└── examples/                   # Примеры
```

## 💡 Быстрые примеры

### Минимальный вызов

```typescript
show({})
```

### С призом

```typescript
show({ prizeAmount: 1000 })
```

### Полный набор данных

```typescript
show({
  playerName: 'Игрок',
  prizeAmount: 5000,
  earnedPoints: 200,
  leaderboardPosition: 1,
  bonusRewards: {
    keys: 10,
    specialItems: ['Золотая медаль'],
  },
})
```

---

**Готово! Начните использовать прямо сейчас! 🚀**
