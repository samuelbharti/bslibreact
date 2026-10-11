import { useNs } from "../module/Module";
import { ShinyOutput } from "../shinyreact";

type Props = { id: string };

/**
 * A traditional Shiny input widget (sliderInput, selectizeInput, and so
 * on), hosted the way shinyreact's maintainers recommend rather than the
 * way this kit used to: posit-dev/shinyreact#286 asked for a `ShinyInput`
 * component that would write a widget's markup on the client and call
 * Shiny's binding functions by hand. The closing PR (#294) answered
 * that a `ShinyInput` is unnecessary and would silently skip dependency
 * delivery: Shiny's own dynamic-UI output already does everything a
 * hosted input needs -- loads the widget's JS/CSS, then runs
 * `initializeInputs()` and `bindAll()` -- because `renderUI()`'s client
 * binding calls `renderContent()`, and `ShinyOutput` already hosts that
 * path. `NavbarTabStrip.tsx`, and `LayoutSidebar` when given an `id`,
 * still call Shiny's binding functions by hand (through `useBoundScope`),
 * since each mixes Shiny-bound markup with React-owned content in a way
 * `renderUI()` cannot express; see their own file comments.
 *
 * The app side of this: `app.R` defines
 * `output$<id>_ui <- renderUI({ sliderInput(<id>, ...) })`, with the
 * exact widget call the parent's own UI makes, copied verbatim rather
 * than reproduced as TSX props. This component only hosts that output;
 * it has no widget-specific props of its own, on purpose, so there is
 * nothing here to drift out of sync with the parent.
 *
 * The `id` passed here is the output slot's own id (an `_ui` suffix by
 * convention), not the widget's own input id. The two must be
 * different strings: `ShinyOutput` puts the output id on the wrapper
 * element (`<div id="topn_ui">`), and the widget's own markup inside it
 * carries its own id too (`<select id="topn">`). Giving both the same
 * id, which reads naturally from the R side (`output$topn <- renderUI(
 * selectInput("topn", ...))`), makes two DOM elements share one id and
 * shows up in the browser console as "Duplicate output IDs", mixing
 * input and output counts in the warning. PR #294's own example avoids
 * this by naming the output `widgets` and the input `bins`.
 *
 * `namespace={null}`: the id below is already the fully namespaced one
 * (`useNs()` resolves it against the surrounding `<Module>`, if any),
 * so `ShinyOutput` must not namespace it again.
 */
export function HostedInput({ id }: Props) {
  const fullId = useNs(id);
  return <ShinyOutput id={fullId} namespace={null} className="shiny-html-output" />;
}
