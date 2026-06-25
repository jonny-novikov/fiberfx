import { Link } from 'react-router-dom'

import { TelegramUtils, cn } from '@/shared/libs'

interface AppLinkProps {
  children: React.ReactNode
  to?: string
  className?: string
  type?: 'link' | 'telegramExternal' | 'telegramInternal'
}

export const AppLink = (props: AppLinkProps) => {
  const { children, to, className, type = 'link' } = props

  const appLinkStyle = cn(
    'inline-flex items-center justify-center gap-2 rounded font-medium transition-colors cursor-pointer',
    className
  )

  if (type === 'telegramExternal') {
    return (
      <button
        className={appLinkStyle}
        onClick={() => TelegramUtils.openExternal(to || '', { tryInstantView: true })}
      >
        {children}
      </button>
    )
  }

  if (type === 'telegramInternal') {
    return (
      <button className={appLinkStyle} onClick={() => TelegramUtils.openTelegramLink(to || '')}>
        {children}
      </button>
    )
  }

  return (
    <Link to={to || ''} className={appLinkStyle}>
      {children}
    </Link>
  )
}
