# Share Story Feature

Фича для шаринга контента в Telegram Stories через WebApp API.

## Состав

- `ShareStoryButton` - UI компонент кнопки для шаринга
- `useShareToStory` - React хук для работы с API шаринга

## Использование

### Простой пример

```tsx
import { ShareStoryButton } from '@/features/share-story'

function MyComponent() {
  return (
    <ShareStoryButton
      storyParams={{
        mediaUrl: 'https://example.com/image.jpg',
        text: 'Посмотри на это!'
      }}
    >
      Поделиться в Stories
    </ShareStoryButton>
  )
}
```

### С виджет-ссылкой

```tsx
<ShareStoryButton
  storyParams={{
    mediaUrl: '/assets/my-image.jpg',
    text: 'Круто!',
    widgetLink: {
      url: 'https://t.me/mybot/app',
      name: 'Открыть приложение'
    }
  }}
  variant="gradient"
  onSuccess={() => console.log('Успешно!')}
  onError={(err) => console.error(err)}
/>
```

### Кнопка с иконкой

```tsx
<ShareStoryButton
  storyParams={{ mediaUrl: 'https://example.com/image.jpg' }}
  iconOnly
  size="icon"
  variant="ghost"
/>
```

### Использование хука напрямую

```tsx
import { useShareToStory } from '@/features/share-story'

function MyComponent() {
  const { shareToStory, isLoading, isAvailable, error } = useShareToStory({
    onSuccess: () => console.log('Успешно!'),
    onError: (err) => console.error(err)
  })

  const handleShare = () => {
    shareToStory({
      mediaUrl: 'https://example.com/image.jpg',
      text: 'Посмотри!',
    })
  }

  if (!isAvailable) {
    return <div>Stories недоступны</div>
  }

  return (
    <button onClick={handleShare} disabled={isLoading}>
      {isLoading ? 'Загрузка...' : 'Поделиться'}
    </button>
  )
}
```

## API

### ShareStoryButton Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `storyParams` | `ShareToStoryParams` | required | Параметры для шаринга (mediaUrl, text, widgetLink) |
| `children` | `ReactNode` | 'Поделиться в Stories' | Текст кнопки |
| `iconOnly` | `boolean` | `false` | Показать только иконку |
| `variant` | `'default' \| 'outline' \| 'gradient' \| 'ghost' \| 'clear'` | `'default'` | Вариант стиля кнопки |
| `size` | `'default' \| 'sm' \| 'lg' \| 'icon'` | `'default'` | Размер кнопки |
| `className` | `string` | - | Дополнительные CSS классы |
| `onSuccess` | `() => void` | - | Callback при успешном шаринге |
| `onError` | `(error: Error) => void` | - | Callback при ошибке |
| `disabled` | `boolean` | `false` | Disabled состояние |

### useShareToStory Return

| Property | Type | Description |
|----------|------|-------------|
| `shareToStory` | `(params: ShareToStoryParams) => Promise<void>` | Функция для шаринга в сторис |
| `isLoading` | `boolean` | Индикатор загрузки |
| `error` | `Error \| null` | Ошибка, если произошла |
| `isAvailable` | `boolean` | Доступна ли функция сторис |

### ShareToStoryParams

```typescript
interface ShareToStoryParams {
  mediaUrl: string          // URL медиа-файла (изображение или видео)
  text?: string             // Текст для сторис
  widgetLink?: {
    url: string             // URL, который откроется при нажатии на виджет
    name?: string           // Текст кнопки виджета
  }
}
```

## Требования

- Telegram WebApp API >= 7.8
- Функция автоматически проверяет доступность и отключает кнопку, если Stories недоступны
