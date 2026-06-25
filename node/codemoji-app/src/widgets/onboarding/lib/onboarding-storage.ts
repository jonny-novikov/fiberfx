const STORAGE_KEY = 'codemoji_onboarding_completed'

/**
 * Проверяет, был ли онбординг уже пройден
 */
export const isOnboardingCompleted = (): boolean => {
  try {
    return localStorage.getItem(STORAGE_KEY) === 'true'
  } catch {
    return false
  }
}

/**
 * Отмечает онбординг как пройденный
 */
export const markOnboardingCompleted = (): void => {
  try {
    localStorage.setItem(STORAGE_KEY, 'true')
  } catch {
    // Игнорируем ошибки localStorage (например, в приватном режиме)
  }
}

/**
 * Сбрасывает статус прохождения онбординга (для тестирования)
 */
export const resetOnboardingStatus = (): void => {
  try {
    localStorage.removeItem(STORAGE_KEY)
  } catch {
    // Игнорируем ошибки localStorage
  }
}
