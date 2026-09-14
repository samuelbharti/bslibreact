import { Card, CardHeader, CardBody, HostedInput, PageFillable, TextOutput } from "bslib-react";

// A two-handle sliderInput() is still SliderInput's own underlying
// mechanism (HostedInput with zero widget-specific props); no separate
// "range" component exists or is needed.
export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Slider range</CardHeader>
        <CardBody>
          <HostedInput id="range_ui" />
          <TextOutput id="chosen" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
