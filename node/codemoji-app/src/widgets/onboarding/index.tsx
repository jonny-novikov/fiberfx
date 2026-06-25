import { useSetAtom } from 'jotai'

import { showOnboardingAtom, hideOnboardingAtom } from './model/onboarding.store'

export { Onboarding } from './ui/onboarding'
export {
  onboardingOpenAtom,
  onboardingDismissableAtom,
  showOnboardingAtom,
  hideOnboardingAtom,
} from './model/onboarding.store'
export {
  isOnboardingCompleted,
  markOnboardingCompleted,
  resetOnboardingStatus,
} from './lib/onboarding-storage'

/**
 * Хук для управления онбордингом
 * @example
 * const { show, hide } = useOnboarding()
 * // Открыть с возможностью закрыть
 * show(true)
 * // Открыть без возможности закрыть (как при первом запуске)
 * show(false)
 */
export const useOnboarding = () => {
  const show = useSetAtom(showOnboardingAtom)
  const hide = useSetAtom(hideOnboardingAtom)
  return { show, hide }
}
