import { forwardRef, useCallback, useRef, useState } from "react";
import type { HTMLAttributes, ReactNode } from "react";
import { cx, useDismiss, useFocusTrap, useId } from "@mercury/core";
import { Portal } from "../_overlay/Portal";
import { Heading } from "../../foundations/Heading";
import { IconButton } from "../../actions/IconButton";

export type DialogSize = "sm" | "md" | "lg";

export interface DialogProps extends Omit<HTMLAttributes<HTMLDivElement>, "title"> {
  /** Whether the dialog is mounted + visible. Controlled. */
  open: boolean;
  /** Requested close — the backdrop press, the close control, or `Escape`. */
  onClose?: () => void;
  /** The heading, wired to `aria-labelledby`. */
  title?: ReactNode;
  /** A supporting line under the title, wired to `aria-describedby`. */
  description?: ReactNode;
  /** The body content. */
  children?: ReactNode;
  /** Trailing actions (usually a `Button` row). */
  footer?: ReactNode;
  /** Panel max-width: `sm` 420 · `md` 496 (default) · `lg` 640. */
  size?: DialogSize;
  /** Render the corner close control (`IconButton`). Default `true`. */
  showClose?: boolean;
}

/**
 * Dialog — a focused, blocking surface with a divider header, description slot,
 * and footer actions. A richer `Modal`: monolithic (prop-driven, not
 * composable-parts), composing the overlay-floor (`Portal` + `useFocusTrap` +
 * `useDismiss`) and mx.7.1 (`Heading` title, `IconButton` close). It reuses the
 * `.mx-modal` style family and layers the `.mx-dialog` delta.
 *
 * a11y: `role="dialog"` + `aria-modal`; the title/description are wired via
 * `aria-labelledby`/`aria-describedby`; focus is trapped while open and returns
 * to the trigger on close; `Escape` and a backdrop press dismiss.
 */
export const Dialog = forwardRef<HTMLDivElement, DialogProps>(function Dialog(
  { open, onClose, title, description, children, footer, size = "md", showClose = true, className, ...rest },
  forwardedRef,
) {
  const panelRef = useRef<HTMLDivElement>(null);
  const [titleId] = useState(() => useId("mx-dialog-title"));
  const [descId] = useState(() => useId("mx-dialog-desc"));

  // Merge the forwarded ref with the internal panel ref the floor hooks read.
  const setPanelRef = useCallback(
    (node: HTMLDivElement | null) => {
      panelRef.current = node;
      if (typeof forwardedRef === "function") forwardedRef(node);
      else if (forwardedRef) forwardedRef.current = node;
    },
    [forwardedRef],
  );

  useFocusTrap(panelRef, { active: open });
  useDismiss(panelRef, {
    onDismiss: () => onClose?.(),
    outsideClick: true,
    escapeKey: true,
    enabled: open,
  });

  if (!open) return null;

  const hasHead = title != null || description != null;

  return (
    <Portal>
      <div className="mx-modal-backdrop mx-dialog-backdrop">
        <div
          ref={setPanelRef}
          className={cx("mx-modal", "mx-dialog", size !== "md" && `mx-dialog--${size}`, className)}
          {...rest}
          role="dialog"
          aria-modal="true"
          tabIndex={-1}
          aria-labelledby={title != null ? titleId : undefined}
          aria-describedby={description != null ? descId : undefined}
        >
          {hasHead && (
            <div className="mx-dialog__head">
              {title != null && (
                <Heading size={3} as="h2" id={titleId} className="mx-dialog__title">
                  {title}
                </Heading>
              )}
              {description != null && (
                <p id={descId} className="mx-dialog__desc">
                  {description}
                </p>
              )}
            </div>
          )}
          {showClose && (
            <IconButton
              icon="close"
              label="Close"
              variant="ghost"
              size="sm"
              className="mx-dialog__close"
              onClick={onClose}
            />
          )}
          {hasHead && <div className="mx-dialog__divider" />}
          <div className="mx-dialog__body">{children}</div>
          {footer != null && <div className="mx-dialog__foot">{footer}</div>}
        </div>
      </div>
    </Portal>
  );
});

export default Dialog;
