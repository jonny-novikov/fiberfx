import type { ReactNode } from "react";

export interface TooltipProps {
  content: ReactNode;
  children: ReactNode;
}

export function Tooltip({ content, children }: TooltipProps) {
  return (
    <span className="mx-tooltip-wrap">
      {children}
      <span className="mx-tooltip" role="tooltip">
        {content}
      </span>
    </span>
  );
}
