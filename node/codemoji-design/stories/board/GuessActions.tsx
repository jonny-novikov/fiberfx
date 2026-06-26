import * as React from 'react';
import { cn } from '../lib/cn';
import { Button } from '../components/Button';

// The Check + Clear row under the guess slots (94:2974). Re-expresses
// features/emoji-actions (CheckClearButtons): Clear wipes the unlocked slots
// (a muted outline button, left), Check submits the guess and costs keys (the
// primary submit, fills the row; the cost rides inline as `🔑 5`). Check is
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
  return (
    <div className={cn('flex gap-3', className)}>
      <Button variant="outline" className="w-fit" onClick={onClear}>
        Clear
      </Button>
      <Button className="flex-1" disabled={disabled} onClick={onCheck}>
        Check 🔑 {keyCost}
      </Button>
    </div>
  );
}
