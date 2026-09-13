import { ShinyOutput } from "../shinyreact";
import { useNs } from "../module/Module";

type Props = { id: string; className?: string; fill?: boolean; inline?: boolean };

/**
 * shiny::uiOutput() / renderUI(). Markup pinned against the `uiOutput`
 * catalog sample (shiny 1.14.0). The escape hatch: hosts an entire dynamic R UI fragment
 * as Shiny's own htmlOutput binding renders it, deps and all, rather than
 * hand-reproducing a complex control-by-control UI in TSX. Reach for this
 * only when a module's UI is genuinely dynamic or too complex to be worth
 * reproducing piece by piece, not to avoid writing TSX for static layout.
 *
 * Set fill when the parent placed the hosted UI's own top-level element
 * (its own bslib::card(height = "100%"), say) directly inside a fillable
 * page. shiny::uiOutput(fill = TRUE) adds html-fill-item html-fill-container
 * to the output div in that case (confirmed by rendering it from R); without
 * that, the plain shiny-html-output div has no fill classes and breaks the
 * fill chain between the page and the hosted content, no matter how the
 * hosted content itself is sized.
 *
 * Set inline when the parent called uiOutput(inline = TRUE): the only
 * difference (confirmed by rendering both from R) is the wrapping tag,
 * <span> instead of <div>, so a card-header "source link" slot (variant-
 * reviewer's vr_card_header(), say) sits next to its title instead of
 * dropping to its own line.
 */
export function UiOutput({ id, className, fill = false, inline = false }: Props) {
  const fullId = useNs(id);
  const classes = ["shiny-html-output", fill && "html-fill-item html-fill-container", className]
    .filter(Boolean)
    .join(" ");
  return (
    <ShinyOutput
      id={fullId}
      tagName={inline ? "span" : "div"}
      namespace={null}
      className={classes}
    />
  );
}
