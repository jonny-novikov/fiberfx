import { useSetAtom } from 'jotai'
import { FC } from 'react'

import { keysPurchaseDrawerAtom } from '@/features/keys-purchase'
import { cn } from '@/shared/libs'
import { AppleEmoji } from '@/shared/ui'

interface CharacterKeyBannerProps {
  className?: string
  characterImage?: string
  keysBalance?: number
}

export const CharacterKeyBanner: FC<CharacterKeyBannerProps> = ({
  className,
  characterImage = '/images/rooms/mr-freeman-with-heart.png',
  keysBalance,
}) => {
  const setDrawerOpen = useSetAtom(keysPurchaseDrawerAtom)

  const handleKeyClick = () => {
    setDrawerOpen(true)
  }

  return (
    <div className={cn('relative', className)}>
      {/* Кнопка ключа с балансом */}
      <button
        onClick={handleKeyClick}
        className="absolute top-[calc(50%-70px)] -translate-y-1/2 left-[calc(50%+90px)] -translate-x-1/2 active:scale-95 transition-transform"
      >
        <div className="relative size-10 bg-black text-white rounded-full flex items-center justify-center shadow-lg">
          <AppleEmoji id="🔑" size={24} className="relative z-10" />
          <div className="absolute bottom-0 left-0 bg-black size-1/2 rounded-bl-md" />
        </div>

        {/* Баланс ключей (опционально) */}
        {keysBalance !== undefined && (
          <div className="absolute -top-2 -right-2 bg-purple-600 text-white text-[10px] font-bold rounded-full min-w-[20px] h-[20px] flex items-center justify-center px-1 shadow-md">
            {keysBalance > 99 ? '99+' : keysBalance}
          </div>
        )}
      </button>

      {/* Изображение персонажа */}
      <img src={characterImage} alt="Character with heart" className="w-full h-full object-cover" />
    </div>
  )
}
