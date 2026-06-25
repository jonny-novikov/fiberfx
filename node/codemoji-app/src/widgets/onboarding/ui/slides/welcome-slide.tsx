import { useTranslation } from 'react-i18next'

export const WelcomeSlide = () => {
  const { t } = useTranslation('onboarding')

  return (
    <div className="h-full flex flex-col items-center overflow-y-auto">
      {/* Изображение - занимает доступное пространство */}
      <div className="flex-1 min-h-0 flex items-end px-4 w-full">
        <img
          src="/images/onboarding/logo.webp"
          alt={t('welcome.imageAlt')}
          className="w-full max-h-full object-contain"
        />
      </div>

      {/* Текстовый контент - фиксированная высота */}
      <div className="shrink-0 px-4 flex flex-col justify-between">
        <h1 className="text-[clamp(1.5rem,15vw,2.25rem)] font-bold text-center leading-none tracking-[-0.03em] mt-[clamp(2rem,12vh,6rem)] whitespace-pre-line">
          {t('welcome.title')}
        </h1>
        <div className="flex flex-col gap-1.5 mt-[clamp(0.75rem,10vh,2rem)] mb-[clamp(1rem,8vh,2rem)] text-center text-[clamp(0.875rem,6vw,1rem)]">
          <p>
            {t('welcome.inSafe')} <span className="text-primary">{t('welcome.sixEmoji')}</span>
          </p>
          <p>
            {t('welcome.inGame')} <span className="text-primary">{t('welcome.prizePool')}</span>
          </p>
          <p>
            {t('welcome.goal')} <span className="text-primary">{t('welcome.getPoints')}</span>
          </p>
        </div>
      </div>
    </div>
  )
}
