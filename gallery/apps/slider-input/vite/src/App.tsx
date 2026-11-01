import { Card, CardHeader, CardBody, PageFillable, PlotOutput, SliderInput } from "bslib-react";

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
