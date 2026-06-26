import * as React from 'react';
import { cn } from '../lib/cn';

// The phone chrome atop a screen (Figma "Header old (iOS)", 375×92), built from the
// exported status-bar assets in public/assets/status-bar/: the iOS status bar
// (system time · Dynamic Island · signal / wi-fi / battery) over the app header
// (the "‹ Back" pill, the CODEMOJI cat logo, and the extra-controls menu).
// Layout matches the Figma reference: the status bar is FULL-BLEED (time/battery sit
// near the phone corners), the header is inset, and the logo is enlarged on a circle
// filled with the control grey (bg-control = #A8ACB0, the same grey as the rasterised
// back/menu buttons). The panel itself is background-transparent so it floats on the
// screen-fill gradient. Self-contained: onBack / onMenu are callbacks. Assets are
// served at /assets/status-bar/* (see .storybook/main.ts).
const ASSET = '/assets/status-bar';

export interface NavPhonePanelProps {
  onBack?: () => void;
  onMenu?: () => void;
  className?: string;
}

export function NavPhonePanel({ onBack, onMenu, className }: NavPhonePanelProps) {
  return (
    <div className={cn('flex flex-col gap-1', className)}>
      {/* iOS status bar — full-bleed so time / battery sit near the phone corners */}
      <img src={`${ASSET}/iphone-topbar.png`} alt="" className="block w-full" />

      {/* app header — back · logo-on-circle · extra controls (inset) */}
      <div className="flex items-center justify-between px-3">
        <button type="button" onClick={onBack} aria-label="Back" className="shrink-0">
          <img src={`${ASSET}/tg-back.png`} alt="Back" className="block h-8 w-auto" />
        </button>

        {/* the cat logo, enlarged, on a circle matching the control-grey buttons */}
        <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-control">
          <img src={`${ASSET}/cm-logo-sm.png`} alt="CODEMOJI" className="block h-11 w-auto" />
        </div>

        <button type="button" onClick={onMenu} aria-label="Extra controls" className="shrink-0">
          <img src={`${ASSET}/tg-menu.png`} alt="" className="block h-8 w-auto" />
        </button>
      </div>
    </div>
  );
}
