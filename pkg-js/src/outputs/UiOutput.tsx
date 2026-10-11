import { ShinyOutput } from "../shinyreact";
import { cx } from "../cx";

type Props = { id: string; className?: string; fill?: boolean; inline?: boolean };

/**
 * shiny::uiOutput() / renderUI(). Markup pinned against the `uiOutput`,
 * `uiOutput_fill` and `uiOutput_inline` catalog samples. The escape hatch:
 * hosts a whole server-rendered UI fragment, dependencies and all. Use it
 * for UI that is genuinely dynamic, or for a bslib piece this kit has no
 * component for yet.
 *
 * `fill` matches uiOutput(fill = TRUE): it adds html-fill-item and
 * html-fill-container, without which the fill chain between a fillable
 * page and the hosted content breaks. `inline` matches
 * uiOutput(inline = TRUE): a <span> in place of the <div>.
 */
export function UiOutput({ id, className, fill = false, inline = false }: Props) {
  return (
    <ShinyOutput
      id={id}
      tagName={inline ? "span" : "div"}
      className={cx("shiny-html-output", fill && "html-fill-item html-fill-container", className)}
    />
  );
}
