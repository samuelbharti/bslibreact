import { Card, CardHeader, CardBody, PageFillable, SliderInput, TextOutput } from "bslib-react";

// A two-handle sliderInput() is hosted by SliderInput like any other
// slider; no separate "range" component is needed.
export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Slider range</CardHeader>
        <CardBody>
          <SliderInput id="range_ui" />
          <TextOutput id="chosen" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
