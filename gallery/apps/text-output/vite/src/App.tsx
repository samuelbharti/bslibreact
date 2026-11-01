import { Card, CardHeader, CardBody, PageFillable, SliderInput, TextOutput } from "bslibreact";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Text</CardHeader>
        <CardBody>
          <SliderInput id="n_ui" />
          <TextOutput id="value" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
