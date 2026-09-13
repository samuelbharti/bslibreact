import { ShinyOutput } from "../shinyreact";
import { useNs } from "../module/Module";

type Props = { id: string; className?: string; fill?: boolean };

/**
 * DT::DTOutput(). Markup pinned against the `DTOutput` catalog sample (DT
 * 0.34.0, fill = TRUE) and `DTOutput_no_fill` (fill =
 * FALSE): the only difference is the html-fill-item class, dropped when
 * fill = FALSE (a card that should size to its table's full content,
 * not stretch or clip it - de-explorer uses this for its Results and
 * Enrichment tables). DT's own binding JS builds the actual table into
 * this div once data arrives. Kept unchanged from the parent's
 * renderDT() - re-implementing DT in React is real work for no benefit
 * when the widget already works, per the convert skill's own guidance.
 */
export function TableOutput({ id, className, fill = true }: Props) {
  const fullId = useNs(id);
  return (
    <ShinyOutput
      id={fullId}
      namespace={null}
      className={[
        "datatables html-widget html-widget-output shiny-report-size",
        fill && "html-fill-item",
        className,
      ]
        .filter(Boolean)
        .join(" ")}
      style={{ width: "100%", height: "auto" }}
    />
  );
}
