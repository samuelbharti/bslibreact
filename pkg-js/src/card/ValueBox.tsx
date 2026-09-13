import { useLayoutEffect, type ReactNode } from "react";
import { cx } from "../cx";

type Props = {
  title: string;
  theme?: "primary" | "secondary" | "warning" | "danger" | "success" | "info";
  children: ReactNode;
};

/**
 * bslib::value_box(). Markup pinned against the `value_box` catalog sample
 * (bslib 0.12.0): a card variant
 * carrying bslib-value-box plus a bg-<theme> class, with a
 * .value-box-area holding a title <p> and the value itself. The value is
 * usually a hosted TextOutput, passed as children with its own
 * className="value-box-value" so the final class list matches exactly.
 */
export function ValueBox({ title, theme = "primary", children }: Props) {
  useLayoutEffect(() => {
    window.bslib?.Card?.initializeAllCards();
  }, []);

  return (
    <div
      className={cx(
        "card bslib-card bslib-mb-spacing html-fill-item html-fill-container bslib-value-box",
        `bg-${theme}`,
      )}
      data-bslib-card-init=""
      data-require-bs-caller="card() value_box()"
      data-require-bs-version="5 5"
    >
      <div
        className="card-body bslib-gap-spacing html-fill-item html-fill-container"
        style={{ marginTop: "auto", marginBottom: "auto", flex: "1 1 auto" }}
      >
        <div className="value-box-area html-fill-item html-fill-container">
          <p className="value-box-title">{title}</p>
          {children}
        </div>
      </div>
    </div>
  );
}
