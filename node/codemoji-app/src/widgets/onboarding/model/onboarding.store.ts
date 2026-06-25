import { atom } from 'jotai'

/**
 * Atom для управления открытием/закрытием онбординга
 */
export const onboardingOpenAtom = atom<boolean>(false)

/**
 * Atom для определения, можно ли закрыть онбординг
 * false - при первом запуске (обязательный онбординг)
 * true - при повторном открытии через кнопку
 */
export const onboardingDismissableAtom = atom<boolean>(true)

/**
 * Write-only atom для открытия онбординга
 * @param dismissable - можно ли закрыть онбординг (по умолчанию true)
 */
export const showOnboardingAtom = atom(null, (get, set, dismissable: boolean = true) => {
  set(onboardingDismissableAtom, dismissable)
  set(onboardingOpenAtom, true)
})

/**
 * Write-only atom для закрытия онбординга
 */
export const hideOnboardingAtom = atom(null, (get, set) => {
  set(onboardingOpenAtom, false)
})
