import { ShinyOutput } from "../shinyreact";
import { cx } from "../cx";

/**
 * shiny::textOutput(). Markup pinned against the `textOutput` catalog
 * sample: a plain div carrying shiny-text-output. Hosted, not read with
 * useShinyOutputValue, so the server's renderText() formats the string
 * exactly as it does in a classic app.
 */
export function TextOutput({ id, className }: { id: string; className?: string }) {
  return <ShinyOutput id={id} className={cx("shiny-text-output", className)} />;
}

/**
 * shiny::verbatimTextOutput(). Markup pinned against the
 * `verbatimTextOutput` catalog sample: a <pre>, not a <div>, with an extra
 * noplaceholder class.
 */
export function VerbatimTextOutput({ id, className }: { id: string; className?: string }) {
  return (
    <ShinyOutput
      id={id}
      tagName="pre"
      className={cx("shiny-text-output noplaceholder", className)}
    />
  );
}
