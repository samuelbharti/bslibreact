import { ShinyOutput } from "../shinyreact";
import { cx } from "../cx";
import { useNs } from "../module/Module";

type Props = {
  id: string;
  width?: string;
  height?: string;
  className?: string;
  /** shiny::plotOutput(click = ns("click")): the input id nearPoints()
   *  reads on the server. Pass a bare id ("click"); inside a <Module> it
   *  is namespaced the same way `id` is. */
  click?: string;
};

/**
 * Hosts a server-side shiny::renderPlot() with plotOutput()'s own
 * shiny-plot-output binding, so sizing, validate()/need() messages, and
 * the busy spinner all match a classic app. Markup pinned against the
 * `plotOutput` and `plotOutput_click` catalog samples. (shinyreact's
 * ImageOutput, which the kit also re-exports, renders a different
 * element shape.)
 */
export function PlotOutput({ id, width = "100%", height = "400px", className, click }: Props) {
  const fullClickId = useNs(click ?? "");
  return (
    <ShinyOutput
      id={useNs(id)}
      namespace={null}
      className={cx("shiny-plot-output html-fill-item", className)}
      style={{ width, height }}
      data-click-id={click ? fullClickId : undefined}
      data-click-clip={click ? "TRUE" : undefined}
    />
  );
}
