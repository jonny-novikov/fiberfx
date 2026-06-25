import { atom } from 'jotai'

export const isAuthenticatedAtom = atom<boolean>(false)

/** Server access allowed flag. If false or undefined after auth, show maintenance screen */
export const isAllowedAtom = atom<boolean | undefined>(undefined)
