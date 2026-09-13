import { ShinyOutput } from "../shinyreact";
import { useNs } from "../module/Module";

/**
 * shiny::textOutput(). Markup pinned against the `textOutput` catalog
 * sample (shiny 1.14.0): a plain div carrying shiny-text-output. Hosted rather
 * than read with useShinyOutputValue so the parent's renderText() stays
 * completely unchanged, including how it formats its string.
 */
export function TextOutput({ id, className }: { id: string; className?: string }) {
  const fullId = useNs(id);
  return (
    <ShinyOutput
      id={fullId}
      namespace={null}
      className={["shiny-text-output", className].filter(Boolean).join(" ")}
    />
  );
}

/**
 * shiny::verbatimTextOutput(). Markup pinned against the
 * `verbatimTextOutput` catalog sample: a <pre>, not a <div>, with an extra
 * noplaceholder class.
 */
export function VerbatimTextOutput({ id, className }: { id: string; className?: string }) {
  const fullId = useNs(id);
  return (
    <ShinyOutput
      id={fullId}
      namespace={null}
      tagName="pre"
      className={["shiny-text-output noplaceholder", className].filter(Boolean).join(" ")}
    />
  );
}
