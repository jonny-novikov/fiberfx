import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { cn } from '../lib/cn';
import { Button } from '../components/Button';

// The Проверить + Очистить row under the guess slots (94:2974). Re-expresses
// features/emoji-actions (CheckClearButtons): "Очистить" wipes the unlocked slots
// (a muted outline button, left), "Проверить" submits the guess and costs keys
// (the primary submit, fills the row; the cost rides inline as `🔑 5`). The submit
// is the app's BLUE button (the `enter` role color == the app's bg-[#0050FF]). It is
// disabled until all six slots are filled (the app's isSelectionReady gate).
export interface GuessActionsProps {
  /** keys an attempt costs — shown on the Check button (the room's guess fee) */
  keyCost?: number;
  /** true until the guess is complete (six chosen) — disables Check */
  disabled?: boolean;
  onCheck?: () => void;
  onClear?: () => void;
  className?: string;
}

export function GuessActions({
  keyCost = 5,
  disabled = false,
  onCheck,
  onClear,
  className,
}: GuessActionsProps) {
  const { t } = useTranslation();
  return (
    <div className={cn('flex gap-3', className)}>
      <Button variant="outline" className="w-fit" onClick={onClear}>
        {t('game.actions.clear')}
      </Button>
      <Button variant="enter" className="flex-1" disabled={disabled} onClick={onCheck}>
        {t('game.actions.check')} 🔑 {keyCost}
      </Button>
    </div>
  );
}
