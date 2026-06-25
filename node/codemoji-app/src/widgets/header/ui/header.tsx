import { useMemo } from 'react'
import { useLocation } from 'react-router-dom'

import LogoOutlined from '@/shared/assets/icons/logo-outlined.svg?react'
import LogoSolid from '@/shared/assets/icons/logo-solid.svg?react'
import { TelegramUtils, cn } from '@/shared/libs'

export const Header = () => {
  const { pathname } = useLocation()

  const isRooms = pathname === '/rooms'
  const isAppLoader = pathname === '/app-loader'
  const isGame = pathname.includes('/game/')
  const isWithdraw = pathname === '/withdraw'

  const HeaderIcon = useMemo(() => {
    if (isRooms || isWithdraw) {
      return <LogoSolid className="w-[126px]" />
    }

    if (isAppLoader) {
      return <LogoOutlined className="w-[126px]" />
    }

    if (isGame) {
      return <LogoOutlined className="w-[126px]" />
    }

    return <LogoOutlined className="w-[126px]" />
  }, [isRooms, isAppLoader, isGame, isWithdraw])

  if (!TelegramUtils.isMobileDevice()) {
    return null
  }

  return (
    <div
      className={cn('shrink-0 flex items-end justify-center h-header pb-2.5', {
        'bg-black': isRooms || isWithdraw,
        'absolute top-0 left-0 right-0': isAppLoader,
      })}
    >
      {HeaderIcon}
    </div>
  )
}
