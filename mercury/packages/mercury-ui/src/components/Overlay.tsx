import { useEffect } from "react";
import { createPortal } from "react-dom";
import type { ReactNode } from "react";
import { cx } from "../cx";

/* ───────── Modal ───────── */
export interface ModalProps {
  open: boolean;
  onClose?: () => void;
  title?: ReactNode;
  footer?: ReactNode;
  size?: "sm" | "md" | "lg";
  children?: ReactNode;
}

export function Modal({ open, onClose, title, footer, size = "md", children }: ModalProps) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose?.();
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open || typeof document === "undefined") return null;

  return createPortal(
    <div className="mx-modal-backdrop" onClick={onClose}>
      <div
        className={cx("mx-modal", size !== "md" && `mx-modal--${size}`)}
        role="dialog"
        aria-modal="true"
        onClick={(e) => e.stopPropagation()}
      >
        {title && (
          <div className="mx-modal__head">
            <h3 className="mx-modal__title">{title}</h3>
            <button className="mx-modal__x" type="button" aria-label="Close" onClick={onClose}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                <path d="M18 6 6 18M6 6l12 12" />
              </svg>
            </button>
          </div>
        )}
        <div className="mx-modal__body">{children}</div>
        {footer && <div className="mx-modal__foot">{footer}</div>}
      </div>
    </div>,
    document.body,
  );
}

/* ───────── Tooltip (CSS-hover) ───────── */
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
