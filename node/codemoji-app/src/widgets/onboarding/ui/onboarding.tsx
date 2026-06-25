import { useAtom, useAtomValue } from 'jotai'
import { useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import type { Swiper as SwiperType } from 'swiper'
import { Pagination } from 'swiper/modules'
import { Swiper, SwiperSlide } from 'swiper/react'

import 'swiper/css'
import 'swiper/css/pagination'

import { markOnboardingCompleted } from '../lib/onboarding-storage'
import {
  onboardingOpenAtom,
  onboardingDismissableAtom,
  hideOnboardingAtom,
} from '../model/onboarding.store'

import { DemoGameSlide, PrizeSlide, WelcomeSlide, type DemoGameSlideRef } from './slides'

import CloseIcon from '@/shared/assets/icons/close.svg?react'
import { cn, useBackButton, useConfetti, TelegramUtils } from '@/shared/libs'
import { Button } from '@/shared/ui'

interface OnboardingProps {
  /**
   * Открыт ли онбординг (для контролируемого режима)
   * Если не передан, используется значение из стора
   */
  open?: boolean
  /**
   * Можно ли закрыть онбординг (крестиком)
   * @default true
   */
  dismissable?: boolean
  /**
   * Колбэк при завершении онбординга
   */
  onComplete?: () => void
}

export const Onboarding = ({
  open: openProp,
  dismissable: dismissableProp,
  onComplete,
}: OnboardingProps) => {
  const { t } = useTranslation('onboarding')
  const [openFromStore] = useAtom(onboardingOpenAtom)
  const dismissableFromStore = useAtomValue(onboardingDismissableAtom)
  const [, hideOnboarding] = useAtom(hideOnboardingAtom)

  // Глобальное конфетти
  const { triggerConfetti, hideConfetti } = useConfetti()

  // Используем пропы если переданы, иначе значения из стора
  const open = openProp ?? openFromStore
  const dismissable = dismissableProp ?? dismissableFromStore

  const [swiperInstance, setSwiperInstance] = useState<SwiperType | null>(null)
  const [activeIndex, setActiveIndex] = useState(0)
  const [isDemoCompleted, setIsDemoCompleted] = useState(false)
  const [isDemoSlotsComplete, setIsDemoSlotsComplete] = useState(false)

  const demoGameRef = useRef<DemoGameSlideRef>(null)
  const autoTransitionTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  const isLastSlide = activeIndex === 2
  const isDemoSlide = activeIndex === 1

  // Блокируем свайп вперёд на слайде демо-игры (индекс 1) пока не отгадан код
  const canSlideNext = !isDemoSlide || isDemoCompleted

  const handleNext = () => {
    // На слайде демо-игры кнопка работает как "Проверить"
    if (isDemoSlide && !isDemoCompleted) {
      const isCorrect = demoGameRef.current?.checkCode()
      if (isCorrect) {
        setIsDemoCompleted(true)
      }
      return
    }

    if (isLastSlide) {
      handleComplete()
    } else {
      swiperInstance?.slideNext()
    }
  }

  const handleComplete = () => {
    markOnboardingCompleted()
    hideOnboarding()
    setActiveIndex(0)
    setIsDemoCompleted(false)
    setIsDemoSlotsComplete(false)
    hideConfetti()
    swiperInstance?.slideTo(0)
    onComplete?.()
  }

  const handleClose = () => {
    if (dismissable) {
      hideOnboarding()
      setActiveIndex(0)
      setIsDemoCompleted(false)
      setIsDemoSlotsComplete(false)
      hideConfetti()
      swiperInstance?.slideTo(0)
    }
  }

  // Кнопка "Назад" в Telegram закрывает онбординг
  useBackButton({ show: dismissable && open, onClick: handleClose })

  const handleDemoSuccess = () => {
    setIsDemoCompleted(true)
    // Haptic feedback при успешном завершении демо-игры
    TelegramUtils.notificationOccurred('success')
    triggerConfetti()

    // Автоматический переход на следующий слайд через 5 секунд
    autoTransitionTimerRef.current = setTimeout(() => {
      swiperInstance?.slideNext()
    }, 5000)
  }

  // Очищаем таймер при размонтировании
  useEffect(() => {
    return () => {
      if (autoTransitionTimerRef.current) {
        clearTimeout(autoTransitionTimerRef.current)
      }
    }
  }, [])

  // Определяем текст кнопки
  const getButtonText = () => {
    if (isLastSlide) return t('buttons.startGame')
    if (isDemoSlide) return t('buttons.check') // Всегда "Проверить" на демо-слайде
    return t('buttons.next')
  }

  // Кнопка disabled на слайде демо-игры: пока не заполнены все слоты ИЛИ после победы (во время автоперехода)
  const isButtonDisabled = isDemoSlide && (!isDemoSlotsComplete || isDemoCompleted)

  if (!open) {
    return null
  }

  return (
    <div className={cn('fixed inset-0 z-50 bg-primary-foreground flex flex-col')}>
      {/* Кнопка закрытия */}
      {dismissable && (
        <button
          onClick={handleClose}
          className="absolute right-4 top-4 z-10 w-10 h-10 flex items-center justify-center rounded-full bg-white/10 text-white hover:bg-white/20 transition-colors"
          aria-label={t('close')}
        >
          <CloseIcon className="w-5 h-5" />
        </button>
      )}

      {/* Swiper */}
      <div className="flex-1 min-h-0 flex flex-col overflow-hidden">
        <Swiper
          modules={[Pagination]}
          pagination={{
            clickable: true,
            bulletClass: 'swiper-pagination-bullet !bg-white/40 !w-2 !h-2 !mx-1',
            bulletActiveClass: '!bg-white !w-6 !rounded-full',
          }}
          allowSlideNext={canSlideNext}
          onSwiper={setSwiperInstance}
          onSlideChange={(swiper) => setActiveIndex(swiper.activeIndex)}
          className="flex-1 min-h-0 w-full"
        >
          <SwiperSlide>
            <WelcomeSlide />
          </SwiperSlide>
          <SwiperSlide>
            <DemoGameSlide
              ref={demoGameRef}
              onSuccess={handleDemoSuccess}
              onCompleteChange={setIsDemoSlotsComplete}
            />
          </SwiperSlide>
          <SwiperSlide>
            <PrizeSlide />
          </SwiperSlide>
        </Swiper>

        {/* Кнопка навигации */}
        <div className="shrink-0 px-8 pb-safe-bottom mb-4">
          <Button onClick={handleNext} disabled={isButtonDisabled} className="w-full">
            {getButtonText()}
          </Button>
        </div>
      </div>
    </div>
  )
}
