import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { cn } from '../lib/cn';
import { Button } from '../components/Button';

// The "Тысяча" hero banner in the lobby (121:2056, Figma "Emoji section" 880:16787) —
// a dark image card pitching the $1000 prize. The app paints it with a .webp hero;
// rasters 404 in the design system, so this stands in with a flat `bg-primary` surface.
// Text is verbatim from the Figma master (the "Тысяча." pitch), and the CTA is Figma's
// light button with black label ("Это что такое?"), reproduced via the card tokens
// (bg-card / text-card-foreground). Self-contained: onClose / onCta are callbacks.
export interface SubscriptionBannerProps {
  heading?: string;
  description?: string;
  ctaLabel?: string;
  onClose?: () => void;
  onCta?: () => void;
  className?: string;
}

export function SubscriptionBanner({
  heading,
  description,
  ctaLabel,
  onClose,
  onCta,
  className,
}: SubscriptionBannerProps) {
  const { t } = useTranslation();
  const resolvedHeading = heading ?? t('lobby.subscription.heading');
  const resolvedDescription = description ?? t('lobby.subscription.description');
  const resolvedCta = ctaLabel ?? t('lobby.subscription.cta');
  return (
    <div className={cn('relative rounded-2xl bg-primary p-6 text-white', className)}>
      {onClose && (
        <button
          type="button"
          aria-label={t('common.close')}
          onClick={onClose}
          className="absolute right-3 top-3 text-white transition-opacity hover:opacity-70"
        >
          ✕
        </button>
      )}
      <p className="text-h3 font-bold">{resolvedHeading}</p>
      <p className="mt-2 text-h5 font-medium leading-snug">{resolvedDescription}</p>
      <Button className="mt-4 bg-card text-card-foreground" variant="default" onClick={onCta}>
        {resolvedCta}
      </Button>
    </div>
  );
}
