import type { CSSProperties } from "react";
import { ShinyOutput } from "../shinyreact";
import { useNs } from "../module/Module";

type Props = {
  id: string;
  width?: string;
  height?: string;
  className?: string;
  /** shiny::plotOutput(click = ns("click")): the input id nearPoints()
   *  reads on the server. Pass a bare id ("click"); it is namespaced the
   *  same way `id` is. */
  click?: string;
};

/**
 * Hosts a server-side shiny::renderPlot() the same way the parent app's
 * plotOutput() would: the exact class shiny-plot-output, so sizing,
 * validate()/need() error messages, and the busy spinner all match. Markup
 * pinned against catalog samples `plotOutput` and `plotOutput_click`
 * (shiny 1.14.0).
 *
 * shinyreact's ImageOutput is the documented alternative, but it renders a
 * different element shape, so plotOutput's own binding is used here
 * instead, hosted through shinyreact's ShinyOutput.
 */
export function PlotOutput({ id, width = "100%", height = "400px", className, click }: Props) {
  const fullId = useNs(id);
  const fullClickId = useNs(click ?? "");
  const style: CSSProperties = { width, height };
  return (
    <ShinyOutput
      id={fullId}
      // The kit's own <Module> already qualified fullId (e.g. "heat-plot").
      // ShinyOutput would otherwise apply the enclosing
      // ShinyModuleProvider's namespace a second time, doubling the
      // prefix ("heat-heat-plot"). namespace={null} opts out, matching
      // the rule shinyreact's own ImageOutput follows for the same reason.
      namespace={null}
      className={["shiny-plot-output html-fill-item", className].filter(Boolean).join(" ")}
      style={style}
      data-click-id={click ? fullClickId : undefined}
      data-click-clip={click ? "TRUE" : undefined}
    />
  );
}
