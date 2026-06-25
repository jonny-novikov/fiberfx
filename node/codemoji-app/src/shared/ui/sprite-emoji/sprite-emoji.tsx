import { memo, type CSSProperties } from 'react'

import { cn } from '@/shared/libs'
import {
  useEmojiSet,
  parseXXYYCode,
  getSpriteStyles,
  type EmojiSetConfig,
} from '@/shared/libs/contexts/emoji-set.context'

export interface SpriteEmojiProps {
  /**
   * Emoji code in XXYY format (e.g., "0305")
   * XX = column (00-99), YY = row (00-99)
   */
  code: string
  /**
   * Display size in pixels
   * @default 32
   */
  size?: number
  /**
   * Additional CSS classes
   */
  className?: string
  /**
   * Additional inline styles
   */
  style?: CSSProperties
  /**
   * Override sprite config (uses context if not provided)
   */
  config?: EmojiSetConfig
}

/**
 * Sprite-based emoji component for game rendering
 *
 * Renders emojis from a sprite sheet using XXYY coordinate codes.
 * Gets sprite configuration from EmojiSetContext or prop override.
 *
 * XXYY Format:
 * - XX: Column index (00-99)
 * - YY: Row index (00-99)
 * - Example: "0305" = column 3, row 5
 *
 * @example
 * ```tsx
 * // Using context (within EmojiSetProvider)
 * <SpriteEmoji code="0305" size={32} />
 *
 * // With explicit config
 * <SpriteEmoji
 *   code="0305"
 *   size={48}
 *   config={{ spriteUrl: '/emoji/set.png', cellSize: 144, gridCols: 10, gridRows: 15 }}
 * />
 * ```
 */
export const SpriteEmoji = memo(function SpriteEmoji({
  code,
  size = 32,
  className,
  style,
  config: configProp,
}: SpriteEmojiProps) {
  const { config: contextConfig } = useEmojiSet()
  const config = configProp ?? contextConfig

  if (!config) {
    console.warn('[SpriteEmoji] No sprite config available')
    return (
      <span
        className={cn('inline-flex items-center justify-center', className)}
        style={{ width: size, height: size, fontSize: size * 0.6, ...style }}
      >
        ?
      </span>
    )
  }

  const { col, row } = parseXXYYCode(code)
  const spriteStyles = getSpriteStyles(col, row, config, size)

  return (
    <div
      className={cn('inline-block shrink-0', className)}
      style={{ ...spriteStyles, ...style }}
      role="img"
      aria-label={`Emoji ${code}`}
    />
  )
})

export default SpriteEmoji
