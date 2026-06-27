/*
 * Bespoke mobile glyphs.
 *
 * @mercury/ui ships an Icon set, but this consumer app needs finance-specific
 * glyphs it doesn't carry (diagonal send/receive arrows, wallet, card, the iOS
 * status-bar marks). They're part of the app's own chrome — ported verbatim
 * from static/mobile-app.html — not reusable design-system components.
 */
import type { SVGProps } from "react";

type G = { size?: number; sw?: number } & SVGProps<SVGSVGElement>;

function Svg({ size = 22, sw = 2, children, ...rest }: G & { children: React.ReactNode }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={sw}
      strokeLinecap="round"
      strokeLinejoin="round"
      {...rest}
    >
      {children}
    </svg>
  );
}

/* ── Status bar ── */
export const SignalIcon = () => (
  <svg width={15} height={15} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.4} strokeLinecap="round" strokeLinejoin="round">
    <path d="M4 20v-3M9 20v-7M14 20v-11M19 20V5" />
  </svg>
);
export const WifiIcon = () => (
  <svg width={15} height={15} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.2} strokeLinecap="round" strokeLinejoin="round">
    <path d="M5 12.55a11 11 0 0114 0M1.5 9a16 16 0 0121 0M8.5 16a6 6 0 017 0M12 20h.01" />
  </svg>
);
export const BatteryIcon = () => (
  <svg width={22} height={15} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}>
    <rect x={2} y={8} width={18} height={9} rx={2.5} />
    <path d="M22 11.5v3" strokeLinecap="round" />
    <rect x={4} y={10} width={12} height={5} rx={1} fill="currentColor" stroke="none" />
  </svg>
);

/* ── Header / nav ── */
export const MenuIcon = (p: G) => (
  <Svg {...p}>
    <path d="M3 12h18M3 6h18M3 18h18" />
  </Svg>
);
export const UserIcon = (p: G) => (
  <Svg {...p}>
    <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2" />
    <circle cx={12} cy={7} r={4} />
  </Svg>
);
export const HomeIcon = (p: G) => (
  <Svg {...p}>
    <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2h-4v-7h-6v7H5a2 2 0 01-2-2z" />
  </Svg>
);
export const ListIcon = (p: G) => (
  <Svg {...p}>
    <path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01" />
  </Svg>
);
export const WalletIcon = (p: G) => (
  <Svg {...p}>
    <path d="M19 7H5a2 2 0 00-2 2v8a2 2 0 002 2h14a2 2 0 002-2v-8a2 2 0 00-2-2z" />
    <path d="M3 9V7a2 2 0 012-2h11" />
    <path d="M16 13h2" />
  </Svg>
);

/* ── Money actions ── */
export const SendIcon = (p: G) => (
  <Svg {...p}>
    <path d="M7 17L17 7M8 7h9v9" />
  </Svg>
);
export const ReceiveIcon = (p: G) => (
  <Svg {...p}>
    <path d="M17 7L7 17M16 17H7V8" />
  </Svg>
);
export const PlusIcon = (p: G) => (
  <Svg {...p}>
    <path d="M12 5v14M5 12h14" />
  </Svg>
);
export const ConvertIcon = (p: G) => (
  <Svg {...p}>
    <path d="M17 1l4 4-4 4" />
    <path d="M3 11V9a4 4 0 014-4h14" />
    <path d="M7 23l-4-4 4-4" />
    <path d="M21 13v2a4 4 0 01-4 4H3" />
  </Svg>
);
export const TrendUpIcon = (p: G) => (
  <Svg {...p}>
    <path d="M23 6l-9.5 9.5-5-5L1 18" />
    <path d="M17 6h6v6" />
  </Svg>
);

/* ── Rows ── */
export const CardIcon = (p: G) => (
  <Svg {...p}>
    <rect x={2} y={5} width={20} height={14} rx={2} />
    <path d="M2 10h20" />
  </Svg>
);
export const ChevronRightIcon = (p: G) => (
  <Svg stroke="rgb(var(--slate-9))" {...p}>
    <path d="M9 18l6-6-6-6" />
  </Svg>
);
export const ShieldIcon = (p: G) => (
  <Svg {...p}>
    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
  </Svg>
);
export const BellIcon = (p: G) => (
  <Svg {...p}>
    <path d="M18 8a6 6 0 00-12 0c0 7-3 9-3 9h18s-3-2-3-9" />
    <path d="M13.73 21a2 2 0 01-3.46 0" />
  </Svg>
);
export const GlobeIcon = (p: G) => (
  <Svg {...p}>
    <circle cx={12} cy={12} r={10} />
    <path d="M2 12h20" />
    <path d="M12 2a15 15 0 010 20 15 15 0 010-20z" />
  </Svg>
);
export const HelpIcon = (p: G) => (
  <Svg {...p}>
    <circle cx={12} cy={12} r={10} />
    <path d="M9.09 9a3 3 0 015.83 1c0 2-3 3-3 3" />
    <path d="M12 17h.01" />
  </Svg>
);
