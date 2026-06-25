import data from '@emoji-mart/data'
import { init } from 'emoji-mart'

/**
 * Инициализируем emoji-mart данные
 */
init({ data })

interface AppleEmojiProps {
  /**
   * ID эмодзи из emoji-mart (например "dog", "cat", "smile")
   * или сам unicode символ (например "🐶")
   */
  id: string
  /**
   * Размер эмодзи в пикселях
   * @default 24
   */
  size?: number
  /**
   * Дополнительные CSS классы
   */
  className?: string
}

/**
 * Компонент для отображения эмодзи в стиле Apple
 * Обеспечивает единообразный вид эмодзи на всех платформах (Android, Desktop, iOS)
 *
 * @example
 * ```tsx
 * // Использование с ID
 * <AppleEmoji id="dog" size={32} />
 *
 * // Использование с Unicode символом
 * <AppleEmoji id="🐶" size={32} />
 * ```
 */
export function AppleEmoji({ id, size = 24, className = '' }: AppleEmojiProps) {
  // Получаем эмодзи из данных emoji-mart
  const getEmoji = () => {
    try {
      // Если передан unicode символ, ищем его в данных
      const emojiData = (data as any).emojis[id] || searchEmojiByNative(id)

      if (!emojiData) {
        // Если не нашли в данных, возвращаем оригинальный символ
        return (
          <span
            className={className}
            style={{
              fontSize: `${size}px`,
              lineHeight: 1,
              display: 'inline-block',
              verticalAlign: 'middle',
            }}
          >
            {id}
          </span>
        )
      }

      // Используем Apple CDN для эмодзи
      const unified = emojiData.unified || emojiData.skins?.[0]?.unified
      if (!unified) {
        return <span className={className}>{id}</span>
      }

      const imageUrl = `https://cdn.jsdelivr.net/npm/emoji-datasource-apple@15.0.1/img/apple/64/${unified}.png`

      return (
        <img
          src={imageUrl}
          alt={emojiData.name || id}
          className={className}
          style={{
            width: `${size}px`,
            height: `${size}px`,
            display: 'inline-block',
            verticalAlign: 'middle',
            objectFit: 'contain',
          }}
          draggable={false}
        />
      )
    } catch (error) {
      console.error('Error loading emoji:', error)
      // Fallback на оригинальный символ
      return <span className={className}>{id}</span>
    }
  }

  return getEmoji()
}

/**
 * Поиск эмодзи по нативному символу
 */
function searchEmojiByNative(native: string): any {
  const emojis = (data as any).emojis

  // Ищем эмодзи по нативному символу
  for (const emojiId in emojis) {
    const emoji = emojis[emojiId]
    if (emoji.skins) {
      for (const skin of emoji.skins) {
        if (skin.native === native) {
          return emoji
        }
      }
    }
  }

  return null
}
