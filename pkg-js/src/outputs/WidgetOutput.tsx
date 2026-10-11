import { ShinyOutput } from "../shinyreact";
import { cx } from "../cx";

type Props = {
  id: string;
  /** The widget's own binding class, e.g. "plotly" or "leaflet". Copy it
   *  from the widget's own *Output() function; it differs per widget. */
  widgetClass: string;
  height?: string;
  width?: string;
  className?: string;
};

/**
 * A generic htmlwidget output (plotly, leaflet, and any other widget whose
 * *Output() is htmlwidgets::shinyWidgetOutput()). Markup pinned against
 * the `htmlwidget_output` catalog sample: a div carrying
 * "<widget> html-widget html-widget-output shiny-report-size
 * html-fill-item" plus an explicit size. DTOutput and ReactableOutput are
 * the two widgets whose markup differs enough to need their own component.
 */
export function WidgetOutput({
  id,
  widgetClass,
  height = "400px",
  width = "100%",
  className,
}: Props) {
  return (
    <ShinyOutput
      id={id}
      className={cx(
        `${widgetClass} html-widget html-widget-output shiny-report-size html-fill-item`,
        className,
      )}
      style={{ width, height }}
    />
  );
}
