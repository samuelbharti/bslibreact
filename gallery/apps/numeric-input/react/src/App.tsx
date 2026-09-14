import { NumericInput, Card, CardHeader, CardBody, PageFillable, TextOutput } from "bslib-react";

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
