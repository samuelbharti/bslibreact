import { Card, CardHeader, CardBody, PageFillable, PlotOutput, SliderInput } from "bslibreact";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Slider</CardHeader>
        <CardBody>
          <SliderInput id="bins_ui" />
          <PlotOutput id="plot" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
