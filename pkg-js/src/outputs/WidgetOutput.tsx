import { ShinyOutput } from "../shinyreact";
import { useNs } from "../module/Module";

type Props = {
  id: string;
  /** The widget's own binding class, e.g. "igvShiny", "plotly", "r3dmol".
   *  Copy it from the widget's own *Output() function; it is not
   *  guessable and differs per widget. */
  widgetClass: string;
  height?: string;
  width?: string;
  className?: string;
};

/**
 * A generic htmlwidget output. Markup pinned against the `htmlwidget_output`
 * catalog sample (`htmlwidgets::shinyWidgetOutput()`, the same generic
 * shape igvShiny and every other plain htmlwidget share) and `DTOutput` (DT):
 * both are a bare div carrying "<widget> html-widget html-widget-output
 * shiny-report-size html-fill-item" plus an explicit size. Reuse this for
 * any htmlwidget the parent renders unchanged (igvShiny, plotly, r3dmol,
 * reactable, ...) rather than reimplementing the widget in React - the
 * TableOutput component is the DT-specific case of the same shape.
 */
export function WidgetOutput({
  id,
  widgetClass,
  height = "400px",
  width = "100%",
  className,
}: Props) {
  const fullId = useNs(id);
  return (
    <ShinyOutput
      id={fullId}
      namespace={null}
      className={[
        `${widgetClass} html-widget html-widget-output shiny-report-size html-fill-item`,
        className,
      ]
        .filter(Boolean)
        .join(" ")}
      style={{ width, height }}
    />
  );
}
