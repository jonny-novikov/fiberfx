/**
 * Типы для хуков работы с Telegram WebApp
 */

/**
 * Опции для хука useTelegramBackButton
 */
export interface UseTelegramBackButtonOptions {
  /**
   * Коллбэк, который будет вызван при нажатии на кнопку "Назад"
   */
  onClick?: () => void;

  /**
   * Показывать ли кнопку при монтировании компонента
   * @default true
   */
  show?: boolean;
}

/**
 * Возвращаемое значение хука useTelegramBackButton
 */
export interface TelegramBackButtonControls {
  /**
   * Показать кнопку "Назад"
   */
  show: () => void;

  /**
   * Скрыть кнопку "Назад"
   */
  hide: () => void;

  /**
   * Установить обработчик клика
   */
  setOnClick: (handler: () => void) => void;

  /**
   * Удалить обработчик клика
   */
  removeOnClick: () => void;

  /**
   * Текущее состояние видимости кнопки
   */
  isVisible: boolean;
}

/**
 * Опции для хука useBackButton
 */
export interface UseBackButtonOptions {
  /**
   * Кастомный обработчик клика.
   * Если не указан, будет использован navigate(-1)
   */
  onClick?: () => void;

  /**
   * Путь для навигации вместо navigate(-1)
   */
  navigateTo?: string;

  /**
   * Показывать ли кнопку при монтировании компонента
   * @default true
   */
  show?: boolean;

  /**
   * Отключить автоматическую навигацию назад
   * @default false
   */
  disableAutoNavigate?: boolean;
}

/**
 * Возвращаемое значение хука useBackButton
 */
export type BackButtonControls = TelegramBackButtonControls;

