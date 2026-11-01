import {
  Card,
  CardBody,
  CardHeader,
  CheckboxInput,
  LayoutColumns,
  Module,
  PageSidebar,
  PlotOutput,
  RadioButtons,
  SliderInput,
  TextOutput,
  ValueBox,
  useShinyInitialized,
} from "bslibreact";

/**
 * A small real analysis app: five hosted inputs in a sidebar drive a
 * server-rendered ggplot2 volcano plot, with three value boxes reading
 * the same status counts the plot colours by. The plot lives inside a
 * <Module namespace="volcano">, since the R server hosts it through a
 * real moduleServer("volcano", ...): the module resolves "volcano-plot"
 * and "volcano-click" (the plot's click input) without either id needing
 * to be spelled out by hand.
 */
export default function App() {
  const ready = useShinyInitialized();
  if (!ready) return null;

  return (
    <PageSidebar title="Volcano plot" sidebarWidth={290} sidebar={<Sidebar />}>
      <LayoutColumns colWidths={[4, 4, 4]} fill={false}>
        <ValueBox title="Up" theme="warning">
          <TextOutput id="n_up" className="value-box-value" />
        </ValueBox>
        <ValueBox title="Down" theme="primary">
          <TextOutput id="n_down" className="value-box-value" />
        </ValueBox>
        <ValueBox title="Not significant" theme="secondary">
          <TextOutput id="n_ns" className="value-box-value" />
        </ValueBox>
      </LayoutColumns>
      <Card fullScreen>
        <CardHeader>Differential expression: synthetic dataset</CardHeader>
        <CardBody>
          <Module namespace="volcano">
            <PlotOutput id="plot" height="560px" click="click" />
          </Module>
        </CardBody>
      </Card>
    </PageSidebar>
  );
}

function Sidebar() {
  return (
    <>
      <SliderInput id="lfc_ui" />
      <SliderInput id="p_ui" />
      <RadioButtons id="pcol_ui" />
      <CheckboxInput id="dolabel_ui" />
      <SliderInput id="topn_ui" />
    </>
  );
}
