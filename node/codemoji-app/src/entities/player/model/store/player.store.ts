import { atom } from 'jotai'

import { PlayerInfo } from '../types/player.types'

export const playerIdAtom = atom<string>('')

export const playerAtom = atom<PlayerInfo | null>(null)
