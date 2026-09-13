import type { ReactNode } from "react";

/**
 * shiny::helpText(). Markup pinned against the `helpText_hr` catalog sample
 * (shiny 1.14.0): a plain span, no id, no Shiny binding needed.
 */
export function HelpText({ children }: { children: ReactNode }) {
  return <span className="help-block">{children}</span>;
}
