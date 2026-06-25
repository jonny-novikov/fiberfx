import { atom } from 'jotai'

import { currencyConverter } from '@/shared/libs/consts/currency.consts'

// Минимальная сумма для вывода
export const MIN_WITHDRAW_CRYSTALS = 1000

// Атом для состояния drawer вывода
export const withdrawDrawerAtom = atom<boolean>(false)

// Расчет суммы вывода в USD
export const calculateWithdrawAmount = (diamonds: number) => {
  const cents = currencyConverter.diamondsToCents(diamonds)
  return {
    cents,
    usd: currencyConverter.centsToUsd(cents),
  }
}
