import { NumericInput, Card, CardHeader, CardBody, PageFillable, TextOutput } from "bslibreact";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Numeric input</CardHeader>
        <CardBody>
          <NumericInput id="pc_ui" />
          <TextOutput id="value" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
