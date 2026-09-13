import { ShinyOutput } from "../shinyreact";
import { useNs } from "../module/Module";

type Props = { id: string; className?: string; height?: string; width?: string };

/**
 * reactable::reactableOutput(). Markup pinned against the `reactableOutput`
 * catalog sample (reactable 0.4.4): a bare div carrying
 * "reactable html-widget html-widget-output shiny-report-size html-fill-item",
 * a data-reactable-output attribute (reactable's own JS reads this to find
 * its mount point for `updateReactable()` calls, e.g. row-selection proxies),
 * and a default style of width:auto;height:auto rather than the 100%/400px
 * WidgetOutput defaults to for a generic htmlwidget. Both details are real
 * (confirmed by dumping reactable::reactableOutput("x") directly), not
 * cosmetic, so this app's own reactable() tables (tahoe_table_ui(), used 11
 * times across 6 modules) get their own small component instead of
 * `WidgetOutput` with `widgetClass="reactable"` -- unlike echarts4r or
 * DiagrammeR's grViz in the same port, which match WidgetOutput's generic
 * shape exactly and so use it unchanged.
 */
export function ReactableOutput({ id, className, height = "auto", width = "auto" }: Props) {
  const fullId = useNs(id);
  return (
    <ShinyOutput
      id={fullId}
      namespace={null}
      className={[
        "reactable html-widget html-widget-output shiny-report-size html-fill-item",
        className,
      ]
        .filter(Boolean)
        .join(" ")}
      style={{ width, height }}
      data-reactable-output={fullId}
    />
  );
}
