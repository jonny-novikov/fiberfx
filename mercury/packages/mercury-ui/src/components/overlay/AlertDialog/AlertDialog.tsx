import { forwardRef, useCallback, useRef, useState } from "react";
import type { HTMLAttributes, ReactNode } from "react";
import { cx, useDismiss, useFocusTrap, useId } from "@mercury/core";
import { Portal } from "../_overlay/Portal";
import { Heading } from "../../foundations/Heading";
import { Button } from "../../actions/Button";

export interface AlertDialogProps extends Omit<HTMLAttributes<HTMLDivElement>, "title"> {
  /** Whether the confirmation is mounted + visible. Controlled. */
  open: boolean;
  /** The heading, wired to `aria-labelledby`. */
  title?: ReactNode;
  /** The prompt, wired to `aria-describedby`. */
  description?: ReactNode;
  /** Extra content between the description and the actions. */
  children?: ReactNode;
  /** The confirm action label. Default `"Confirm"`. */
  confirmLabel?: string;
  /** The cancel action label. Default `"Cancel"`. */
  cancelLabel?: string;
  /** Style the confirm action as destructive (a `Button variant="destructive"`). */
  destructive?: boolean;
  /** Invoked when the confirm action is pressed. */
  onConfirm?: () => void;
  /** Invoked on cancel, `Escape`, or the cancel action. */
  onCancel?: () => void;
}

/**
 * AlertDialog — a blocking confirmation that demands an explicit choice.
 * `role="alertdialog"`, composing the overlay-floor minus outside-press
 * dismiss: a backdrop press does NOT dismiss (deliberate), only `Escape` or the
 * cancel action. Composes mx.7.1's `Heading` and the `Button` actions.
 *
 * a11y: `aria-modal`; title/description wired via `aria-labelledby`/
 * `aria-describedby`; focus is trapped and lands on the confirm action on open,
 * returning to the trigger on close.
 */
export const AlertDialog = forwardRef<HTMLDivElement, AlertDialogProps>(function AlertDialog(
  {
    open,
    title,
    description,
    children,
    confirmLabel = "Confirm",
    cancelLabel = "Cancel",
    destructive,
    onConfirm,
    onCancel,
    className,
    ...rest
  },
  forwardedRef,
) {
  const panelRef = useRef<HTMLDivElement>(null);
  const confirmRef = useRef<HTMLButtonElement>(null);
  const [titleId] = useState(() => useId("mx-alert-title"));
  const [descId] = useState(() => useId("mx-alert-desc"));

  const setPanelRef = useCallback(
    (node: HTMLDivElement | null) => {
      panelRef.current = node;
      if (typeof forwardedRef === "function") forwardedRef(node);
      else if (forwardedRef) forwardedRef.current = node;
    },
    [forwardedRef],
  );

  // Initial focus lands on the confirm action (the prototype's confirmWrap intent).
  useFocusTrap(panelRef, { active: open, initialFocus: confirmRef });
  useDismiss(panelRef, {
    onDismiss: () => onCancel?.(),
    outsideClick: false,
    escapeKey: true,
    enabled: open,
  });

  if (!open) return null;

  return (
    <Portal>
      <div className="mx-modal-backdrop mx-alert-dialog-backdrop">
        <div
          ref={setPanelRef}
          className={cx("mx-modal", "mx-alert-dialog", className)}
          {...rest}
          role="alertdialog"
          aria-modal="true"
          tabIndex={-1}
          aria-labelledby={title != null ? titleId : undefined}
          aria-describedby={description != null ? descId : undefined}
        >
          {title != null && (
            <Heading size={3} as="h2" id={titleId} className="mx-alert-dialog__title">
              {title}
            </Heading>
          )}
          {description != null && (
            <p id={descId} className="mx-alert-dialog__desc">
              {description}
            </p>
          )}
          {children != null && <div className="mx-alert-dialog__extra">{children}</div>}
          <div className="mx-alert-dialog__actions">
            <Button variant="secondary" onClick={onCancel}>
              {cancelLabel}
            </Button>
            <Button
              ref={confirmRef}
              variant={destructive ? "destructive" : "primary"}
              onClick={onConfirm}
            >
              {confirmLabel}
            </Button>
          </div>
        </div>
      </div>
    </Portal>
  );
});

export default AlertDialog;
