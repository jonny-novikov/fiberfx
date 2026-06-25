# GameOverDialog - Модальное окно проигрыша

Глобальный виджет для отображения информации игрокам, которые не успели разгадать код до победителя. Управляется через Jotai atoms.

## Назначение

Этот виджет показывается всем игрокам, которые не выиграли в игре по различным причинам:
- Другой игрок первым разгадал код
- Истекло время на разгадывание
- Закончились попытки

## Использование

Виджет уже интегрирован глобально в `BaseLayout`, поэтому вам не нужно добавлять его в компоненты.

### Рекомендуемый способ: использование хука

```typescript
import { useGameOverDialog } from '@/widgets/game-over-dialog'

function GameComponent() {
  const { show } = useGameOverDialog()

  const handleGameOver = (gameResult) => {
    show({
      winnerName: gameResult.winner,
      playerPosition: gameResult.myPosition,
      earnedPoints: gameResult.consolationPoints,
      consolationPrize: gameResult.consolationMoney,
      reason: 'winner_found',
      additionalInfo: 'Продолжайте играть!'
    })
  }

  return <button onClick={() => handleGameOver(result)}>Завершить игру</button>
}
```

### Альтернативный способ: использование atoms напрямую

```typescript
import { useSetAtom } from 'jotai'
import { showGameOverDialogAtom } from '@/widgets/game-over-dialog'

function GameComponent() {
  const showGameOverDialog = useSetAtom(showGameOverDialogAtom)

  const handleGameOver = () => {
    showGameOverDialog({
      winnerName: 'Player123',
      playerPosition: 2,
      earnedPoints: 50,
      reason: 'winner_found'
    })
  }

  return <button onClick={handleGameOver}>Game Over</button>
}
```

### Закрыть модальное окно программно

```typescript
import { useSetAtom } from 'jotai'
import { hideGameOverDialogAtom } from '@/widgets/game-over-dialog'

function SomeComponent() {
  const hideGameOverDialog = useSetAtom(hideGameOverDialogAtom)

  const handleClose = () => {
    hideGameOverDialog()
  }

  return <button onClick={handleClose}>Закрыть</button>
}
```

### Минимальный пример

```typescript
show({
  reason: 'winner_found'
})
```

## API

### GameOverDialogData

```typescript
interface GameOverDialogData {
  /** Имя победителя, который обошел игрока (опционально) */
  winnerName?: string
  
  /** Занятое место игрока (опционально) */
  playerPosition?: number
  
  /** Заработанные баллы - утешительный приз (опционально) */
  earnedPoints?: number
  
  /** Сумма утешительного приза (опционально) */
  consolationPrize?: number
  
  /** Осталось попыток (опционально) */
  attemptsLeft?: number
  
  /** Причина проигрыша (опционально, но рекомендуется) */
  reason?: 'winner_found' | 'time_expired' | 'attempts_exceeded'
  
  /** Дополнительная информация (опционально) */
  additionalInfo?: string
}
```

#### Причины проигрыша (reason)

- **`winner_found`** - найден победитель, кто-то первым разгадал код
- **`time_expired`** - истекло время на разгадывание кода
- **`attempts_exceeded`** - у игрока закончились попытки

### Хук useGameOverDialog

```typescript
const { show, hide, isOpen, data } = useGameOverDialog()
```

Возвращает:

- `show(data: GameOverDialogData)` - функция для показа модального окна
- `hide()` - функция для скрытия модального окна
- `isOpen: boolean` - текущее состояние (открыто/закрыто)
- `data: GameOverDialogData | null` - текущие данные в модальном окне

### Atoms

- `gameOverDialogOpenAtom` - состояние открытия/закрытия модального окна
- `gameOverDialogDataAtom` - данные для отображения в модальном окне
- `showGameOverDialogAtom` - write-only atom для открытия окна с данными
- `hideGameOverDialogAtom` - write-only atom для закрытия окна

## Примеры интеграции

### С WebSocket событием окончания игры

```typescript
import { useSetAtom } from 'jotai'
import { showGameOverDialogAtom } from '@/widgets/game-over-dialog'

function useGameWebSocket() {
  const showGameOverDialog = useSetAtom(showGameOverDialogAtom)

  useEffect(() => {
    socket.on('game:ended', (data) => {
      if (!data.isWinner) {
        showGameOverDialog({
          winnerName: data.winnerName,
          playerPosition: data.playerPosition,
          earnedPoints: data.consolationPoints,
          consolationPrize: data.consolationPrize,
          reason: 'winner_found'
        })
      }
    })

    socket.on('game:timeout', (data) => {
      showGameOverDialog({
        playerPosition: data.finalPosition,
        earnedPoints: data.earnedPoints,
        reason: 'time_expired'
      })
    })

    return () => {
      socket.off('game:ended')
      socket.off('game:timeout')
    }
  }, [])
}
```

### С mutation после отправки попытки

```typescript
import { useMutation } from '@tanstack/react-query'
import { useSetAtom } from 'jotai'
import { showGameOverDialogAtom } from '@/widgets/game-over-dialog'

function useSubmitGuessMutation() {
  const showGameOverDialog = useSetAtom(showGameOverDialogAtom)

  return useMutation({
    mutationFn: submitGuess,
    onSuccess: (response) => {
      if (response.gameEnded && !response.isWinner) {
        showGameOverDialog({
          winnerName: response.winnerName,
          playerPosition: response.finalPosition,
          earnedPoints: response.earnedPoints,
          consolationPrize: response.consolationPrize,
          reason: 'winner_found'
        })
      }
      
      if (response.noAttemptsLeft) {
        showGameOverDialog({
          earnedPoints: response.totalPoints,
          attemptsLeft: 0,
          reason: 'attempts_exceeded',
          additionalInfo: 'Купите дополнительные ключи для продолжения игры'
        })
      }
    }
  })
}
```

### С проверкой оставшихся попыток

```typescript
const handleGameOver = (result) => {
  const { show } = useGameOverDialog()
  
  if (result.attemptsLeft > 0) {
    // Игрок может попробовать еще раз
    show({
      earnedPoints: result.currentPoints,
      attemptsLeft: result.attemptsLeft,
      reason: 'time_expired',
      additionalInfo: `У вас еще ${result.attemptsLeft} попыток!`
    })
  } else {
    // Попыток больше нет
    show({
      earnedPoints: result.totalPoints,
      reason: 'attempts_exceeded'
    })
  }
}
```

## Визуальное оформление

Виджет использует:

- Изображение ошибки (изображение `/images/error-img.png`)
- Динамический контент в зависимости от причины проигрыша
- Блок с утешительными наградами (если есть)
- Красную кнопку закрытия (#FF2F00) или синюю кнопку "Попробовать еще раз" (#0050FF)
- Эмодзи для визуального украшения 💪

✅ Все необходимые изображения уже присутствуют в проекте.

## Логика кнопок

Виджет автоматически определяет, какие кнопки показывать:

- **Если есть оставшиеся попытки** (`attemptsLeft > 0`):
  - Показывается синяя кнопка "Попробовать еще раз" 💪
  - Показывается дополнительная кнопка "Закрыть"

- **Если попыток не осталось** (`attemptsLeft === 0` или не указано):
  - Показывается только красная кнопка "Закрыть"

## Адаптивный контент

Заголовок и описание автоматически меняются в зависимости от причины:

| Причина | Заголовок | Описание |
|---------|-----------|----------|
| `winner_found` | "Игра окончена" | Информация о победителе |
| `time_expired` | "Время вышло" | Время на разгадывание истекло |
| `attempts_exceeded` | "Попытки закончились" | У вас закончились попытки |
| по умолчанию | "Игра окончена" | Общее сообщение |

## Примеры

Для тестирования и изучения работы виджета смотрите файлы:

- `examples/game-over-dialog.example.tsx` - интерактивные примеры использования
- `examples/integration-with-websocket.example.ts` - интеграция с WebSocket

## Структура файлов

```
widgets/game-over-dialog/
├── index.tsx                              # Главный файл экспорта
├── README.md                              # Документация (этот файл)
├── QUICK_START.md                         # Быстрый старт
├── model/
│   └── game-over-dialog.store.ts         # Jotai atoms для управления состоянием
├── ui/
│   └── game-over-dialog.tsx              # React компонент модального окна
├── hooks/
│   └── use-game-over-dialog.ts           # Хук для удобного использования
└── examples/
    ├── game-over-dialog.example.tsx      # Примеры использования
    └── integration-with-websocket.example.ts # Интеграция с WebSocket
```

## Связанные виджеты

- **VictoryDialog** - показывается победителю игры
- **FirstPlaceDialog** - показывается при выходе на первое место во время игры
- **ErrorDialog** - показывается при технических ошибках

