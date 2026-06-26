import * as React from 'react';
import { cn } from '../lib/cn';

// The phone chrome atop a screen (Figma "Header old (iOS)", 375×92), built from the
// exported status-bar assets in public/assets/status-bar/: the iOS status bar
// (system time · Dynamic Island · signal / wi-fi / battery) over the app header
// (the "‹ Back" pill, the CODEMOJI cat logo, and the extra-controls menu). The
// assets carry their own (transparent-surround) surfaces, so the panel itself has no
// background — it floats on the screen-fill gradient. Self-contained: onBack / onMenu
// are callbacks. Assets are served at /assets/status-bar/* (see .storybook/main.ts).
const ASSET = '/assets/status-bar';

export interface NavPhonePanelProps {
  onBack?: () => void;
  onMenu?: () => void;
  className?: string;
}

export function NavPhonePanel({ onBack, onMenu, className }: NavPhonePanelProps) {
  return (
    <div className={cn('flex flex-col gap-2', className)}>
      {/* iOS status bar — time · Dynamic Island · signal / wi-fi / battery */}
      <img src={`${ASSET}/iphone-topbar.png`} alt="" className="block w-full" />

      {/* app header — back · cat logo · extra controls (vertically centered) */}
      <div className="flex items-center justify-between px-1">
        <button type="button" onClick={onBack} aria-label="Back" className="shrink-0">
          <img src={`${ASSET}/tg-back.png`} alt="Back" className="block h-8 w-auto" />
        </button>

        <img
          src={`${ASSET}/cm-logo-sm.png`}
          alt="CODEMOJI"
          className="block h-10 w-auto shrink-0"
        />

        <button type="button" onClick={onMenu} aria-label="Extra controls" className="shrink-0">
          <img src={`${ASSET}/tg-menu.png`} alt="" className="block h-8 w-auto" />
        </button>
      </div>
    </div>
  );
}
