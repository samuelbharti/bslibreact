import { ShinyOutput } from "../shinyreact";
import { cx } from "../cx";
import { useNs } from "../module/Module";

type Props = { id: string; className?: string; height?: string; width?: string };

/**
 * reactable::reactableOutput(). Markup pinned against the `reactableOutput`
 * catalog sample. It differs from WidgetOutput's generic shape in two ways:
 * a data-reactable-output attribute (reactable's own JS finds its mount
 * point through it, e.g. for updateReactable()) and an auto width and
 * height in place of 100% and 400px.
 */
export function ReactableOutput({ id, className, height = "auto", width = "auto" }: Props) {
  const fullId = useNs(id);
  return (
    <ShinyOutput
      id={fullId}
      namespace={null}
      className={cx(
        "reactable html-widget html-widget-output shiny-report-size html-fill-item",
        className,
      )}
      style={{ width, height }}
      data-reactable-output={fullId}
    />
  );
}
