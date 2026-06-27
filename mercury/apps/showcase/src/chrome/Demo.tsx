import type { ReactNode } from "react";
import { cx } from "@mercury/ui";
import { toast } from "@mercury/effector";

/*
 * Demo — a framed stage that renders live Mercury components, with an
 * optional JSX snippet and a Copy button. The copy action routes through the
 * Effector toast model, so every page exercises the @mercury/effector plug.
 */
export interface DemoProps {
  children: ReactNode;
  /** JSX shown beneath the stage and copied to the clipboard. */
  code?: string;
  /** Stage layout modifiers: "col" stacks, "center" centers, "dark" inverts. */
  layout?: "row" | "col" | "center" | "dark";
  label?: string;
}

export function Demo({ children, code, layout = "row", label = "JSX" }: DemoProps) {
  const copy = () => {
    if (!code) return;
    if (navigator.clipboard) {
      navigator.clipboard
        .writeText(code)
        .then(() => toast.success("Copied to clipboard"))
        .catch(() => toast.error("Couldn’t copy"));
    }
  };
  return (
    <div className="demo">
      <div className={cx("stage", layout !== "row" && layout)}>{children}</div>
      {code && (
        <>
          <pre className="code">{code}</pre>
          <div className="dlabel">
            <span>{label}</span>
            <button className="copy" type="button" onClick={copy}>
              Copy
            </button>
          </div>
        </>
      )}
    </div>
  );
}
