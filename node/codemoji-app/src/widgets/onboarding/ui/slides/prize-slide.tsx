import { useTranslation } from 'react-i18next'

/**
 * Слайд 3: Призы и награды
 */
export const PrizeSlide = () => {
  const { t } = useTranslation('onboarding')

  return (
    <div className="h-full flex flex-col items-center overflow-y-auto">
      {/* Изображение - занимает доступное пространство */}
      <div className="flex-1 min-h-0 flex items-end justify-center px-4 w-full">
        <img
          src="/images/onboarding/prize.webp"
          alt={t('prize.imageAlt')}
          className="w-full object-contain"
        />
      </div>

      {/* Текстовый контент - фиксированная высота */}
      <div className="shrink-0 px-4">
        <h1 className="text-[clamp(1.5rem,10vw,2.25rem)] font-bold text-center leading-none tracking-[-0.03em] mt-[clamp(1rem,4vh,2rem)]">
          {t('prize.title')}
        </h1>
        <p className="text-center text-[clamp(0.875rem,3.5vw,1rem)] mt-[clamp(0.75rem,2vh,1.25rem)] mb-[clamp(1rem,3vh,2rem)]">
          {t('prize.subtitle')}
        </p>
        <div className="flex flex-col gap-1.5 mt-[clamp(0.75rem,2vh,1.25rem)] mb-[clamp(1rem,3vh,2rem)] text-center text-[clamp(0.875rem,3.5vw,1rem)] bg-[#E8EFF1] w-fit px-6 py-4 rounded-2xl mx-auto">
          <div className="flex items-center gap-3">
            <p className="text-right text-green-500 w-7">100</p>
            <p>{t('prize.scoring.100')}</p>
          </div>
          <div className="flex items-center gap-3">
            <p className="text-right text-green-500 w-7">80</p>
            <p>{t('prize.scoring.80')}</p>
          </div>
          <div className="flex items-center gap-3">
            <p className="text-right text-orange-500 w-7">60</p>
            <p>{t('prize.scoring.60')}</p>
          </div>
          <div className="flex items-center gap-3">
            <p className="text-right text-orange-500 w-7">40</p>
            <p>{t('prize.scoring.40')}</p>
          </div>
          <div className="flex items-center gap-3">
            <p className="text-right text-primary w-7">20</p>
            <p>{t('prize.scoring.20')}</p>
          </div>
          <div className="flex items-center gap-3">
            <p className="text-right text-primary w-7">0</p>
            <p>{t('prize.scoring.0')}</p>
          </div>
        </div>
      </div>
    </div>
  )
}
