# VictoryDialog - Модальное окно победителя

Глобальный виджет для поздравления игрока с победой в игре. Управляется через Jotai atoms.

## Отличия от FirstPlaceDialog

- **FirstPlaceDialog** - показывается когда игрок выходит на первое место в лидерборде во время игры
- **VictoryDialog** - показывается когда игрок побеждает в игре (финальная победа)

## Использование

Виджет уже интегрирован глобально в `BaseLayout`, поэтому вам не нужно добавлять его в компоненты.

### Рекомендуемый способ: использование хука

```typescript
import { useVictoryDialog } from '@/widgets/victory-dialog'

function GameComponent() {
  const { show } = useVictoryDialog()

  const handleGameWin = () => {
    show({
      playerName: 'Игрок123',
      prizeAmount: 2500,
      earnedPoints: 150,
      leaderboardPosition: 1,
      bonusRewards: {
        keys: 5,
        specialItems: ['Золотая медаль']
      }
    })
  }

  return <button onClick={handleGameWin}>Победить</button>
}
```

### Альтернативный способ: использование atoms напрямую

```typescript
import { useSetAtom } from 'jotai'
import { showVictoryDialogAtom } from '@/widgets/victory-dialog'

function GameComponent() {
  const showVictoryDialog = useSetAtom(showVictoryDialogAtom)

  const handleGameWin = () => {
    showVictoryDialog({
      playerName: 'Игрок123',
      prizeAmount: 2500,
      earnedPoints: 150,
      leaderboardPosition: 1,
      bonusRewards: {
        keys: 5,
        specialItems: ['Золотая медаль']
      }
    })
  }

  return <button onClick={handleGameWin}>Победить</button>
}
```

### Закрыть модальное окно программно

```typescript
import { useSetAtom } from 'jotai'
import { hideVictoryDialogAtom } from '@/widgets/victory-dialog'

function SomeComponent() {
  const hideVictoryDialog = useSetAtom(hideVictoryDialogAtom)

  const handleClose = () => {
    hideVictoryDialog()
  }

  return <button onClick={handleClose}>Закрыть</button>
}
```

### Минимальный пример (только обязательные поля)

```typescript
showVictoryDialog({})
```

Виджет покажет модальное окно с дефолтным поздравительным текстом.

## API

### VictoryDialogData

```typescript
interface VictoryDialogData {
  /** Имя победителя (опционально) */
  playerName?: string
  /** Сумма выигрыша (опционально) */
  prizeAmount?: number
  /** Заработанные баллы (опционально) */
  earnedPoints?: number
  /** Позиция в рейтинге (опционально) */
  leaderboardPosition?: number
  /** Дополнительные награды (опционально) */
  bonusRewards?: {
    keys?: number
    specialItems?: string[]
  }
}
```

### Хук useVictoryDialog

```typescript
const { show, hide, isOpen, data } = useVictoryDialog()
```

Возвращает:

- `show(data: VictoryDialogData)` - функция для показа модального окна
- `hide()` - функция для скрытия модального окна
- `isOpen: boolean` - текущее состояние (открыто/закрыто)
- `data: VictoryDialogData | null` - текущие данные в модальном окне

### Atoms

- `victoryDialogOpenAtom` - состояние открытия/закрытия модального окна
- `victoryDialogDataAtom` - данные для отображения в модальном окне
- `showVictoryDialogAtom` - write-only atom для открытия окна с данными
- `hideVictoryDialogAtom` - write-only atom для закрытия окна

## Примеры интеграции

### С mutation при завершении игры

```typescript
import { useMutation } from '@tanstack/react-query'
import { useSetAtom } from 'jotai'
import { showVictoryDialogAtom } from '@/widgets/victory-dialog'

function useGameCompleteMutation() {
  const showVictoryDialog = useSetAtom(showVictoryDialogAtom)

  return useMutation({
    mutationFn: completeGame,
    onSuccess: (data) => {
      if (data.isWinner) {
        showVictoryDialog({
          playerName: data.playerName,
          prizeAmount: data.prizeAmount,
          earnedPoints: data.points,
          leaderboardPosition: data.position,
        })
      }
    },
  })
}
```

### В обработчике WebSocket события

```typescript
import { useSetAtom } from 'jotai'
import { showVictoryDialogAtom } from '@/widgets/victory-dialog'

function useGameWebSocket() {
  const showVictoryDialog = useSetAtom(showVictoryDialogAtom)

  useEffect(() => {
    socket.on('game:victory', (data) => {
      showVictoryDialog({
        prizeAmount: data.prize,
        earnedPoints: data.points,
      })
    })

    return () => {
      socket.off('game:victory')
    }
  }, [])
}
```

## Визуальное оформление

Виджет использует:

- Медаль победителя (изображение `/images/game/medal.png`)
- Конфетти в качестве фона (изображение `/images/game/confetti.png`)
- Эмодзи для визуального украшения 🎉🎊
- Зеленую кнопку подтверждения (#34C759)

✅ Все необходимые изображения уже присутствуют в проекте.

## Примеры

Для тестирования и изучения работы виджета смотрите файл:

- `examples/victory-dialog.example.tsx` - интерактивные примеры использования

## Структура файлов

```
widgets/victory-dialog/
├── index.tsx                          # Главный файл экспорта
├── README.md                          # Документация
├── model/
│   └── victory-dialog.store.ts       # Jotai atoms для управления состоянием
├── ui/
│   └── victory-dialog.tsx            # React компонент модального окна
├── hooks/
│   └── use-victory-dialog.ts         # Хук для удобного использования
└── examples/
    └── victory-dialog.example.tsx    # Примеры использования
```
