import { ShinyOutput } from "../shinyreact";
import { cx } from "../cx";
import { useNs } from "../module/Module";

type Props = { id: string; className?: string; fill?: boolean };

/**
 * DT::DTOutput(). Markup pinned against the `DTOutput` (fill = TRUE) and
 * `DTOutput_no_fill` (fill = FALSE) catalog samples: the only difference is
 * the html-fill-item class, dropped when fill = FALSE so a card sizes to the
 * table's full content. DT's own binding JS builds the table into this div.
 * Not shiny::tableOutput(): that is a plain renderTable() output, hosted
 * with UiOutput.
 */
export function DTOutput({ id, className, fill = true }: Props) {
  return (
    <ShinyOutput
      id={useNs(id)}
      namespace={null}
      className={cx(
        "datatables html-widget html-widget-output shiny-report-size",
        fill && "html-fill-item",
        className,
      )}
      style={{ width: "100%", height: "auto" }}
    />
  );
}
