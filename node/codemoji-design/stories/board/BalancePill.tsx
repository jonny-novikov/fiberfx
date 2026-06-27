import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { cn } from '../lib/cn';

// Row 1 of the board's Info dashboard (Figma 94:2974 → "Info"/Frame 16): a thin
// white pill with the add-keys action on the left and the player's key balance on
// the right. Re-expresses the app's top-up entry point; the balance here is KEYS
// (the room's guess currency), distinct from the diamonds shown in the prize card.
// Floats on the screen gradient with the soft blue lift the whole Info block carries.
const LIFT = '0 10px 22px rgba(170,201,216,0.5)';

export interface BalancePillProps {
  /** the player's key balance shown on the right (Figma: "Баланс 🔑 34") */
  keys?: number;
  /** fired when the add-keys action is tapped (the app's top-up flow) */
  onAddKeys?: () => void;
  className?: string;
}

export function BalancePill({ keys = 34, onAddKeys, className }: BalancePillProps) {
  const { t } = useTranslation();
  return (
    <div
      className={cn(
        'flex h-9 w-full items-center justify-between rounded-2xl bg-card px-3 text-2xs text-card-foreground',
        className
      )}
      style={{ boxShadow: LIFT }}
    >
      <button type="button" onClick={onAddKeys} className="font-medium">
        {t('board.addKeys')}
      </button>
      <span className="flex items-center gap-1 text-card-foreground-secondary">
        <span>{t('lobbyInfo.balance')}</span>
        <span className="font-medium text-card-foreground">🔑 {keys}</span>
      </span>
    </div>
  );
}
