import { useEffect } from 'react'
import { useTranslation } from 'react-i18next'

import LogoOutlined from '@/shared/assets/icons/logo-outlined.svg?react'
import { getWebApp } from '@/shared/libs/utils/telegram-mock'
import { AnimatedLoadingText } from '@/shared/ui'

export const MaintenanceScreen = () => {
  const { t } = useTranslation()

  useEffect(() => {
    const wa = getWebApp() as any

    wa.setHeaderColor?.('#141414')
    wa.setBackgroundColor?.('#363636')
  }, [])

  return (
    <div className="relative h-screen bg-linear-to-b from-[#141414] to-[#363636]">
      <div className="absolute top-0 left-0 right-0 shrink-0 flex items-end justify-center h-header pb-2.5">
        <LogoOutlined className="w-[126px]" />
      </div>
      {/* Текст о технических работах вверху экрана */}
      <div className="absolute top-[calc(var(--height-header)+16px)] left-0 right-0 flex justify-center z-10">
        <AnimatedLoadingText
          text={t('maintenance.message')}
          className="text-white/80 text-sm tracking-wide"
        />
      </div>
      <div className="h-full w-full flex flex-col items-center justify-end bg-[url('/images/app-loader/background2.png')] bg-cover bg-center bg-no-repeat">
        <img
          src="/images/app-loader/hero-main.webp"
          alt="Mr.Freeman"
          className="h-[600px] object-cover absolute bottom-0 right-0"
        />
        <div className="absolute left-0 bottom-[64px] pb-safe-bottom">
          <div className="rounded-lg backdrop-blur-sm text-white bg-black font-semibold leading-none w-[29px] flex items-center px-8 uppercase tracking-widest text-xs [writing-mode:vertical-rl] [text-orientation:mixed]">
            by Digital Mr.Freeman, Inc
          </div>
        </div>
      </div>
    </div>
  )
}
