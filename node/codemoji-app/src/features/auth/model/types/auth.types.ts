import { TelegramLoginResponseDto } from '@codemoji/types'

export type AuthResponse = TelegramLoginResponseDto & {
  /** Server access flag. If false or undefined, app shows maintenance screen */
  allow?: boolean
}
