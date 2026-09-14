import { CheckboxInput, Card, CardHeader, CardBody, PageFillable, TextOutput } from "bslib-react";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Checkbox</CardHeader>
        <CardBody>
          <CheckboxInput id="cluster_ui" />
          <TextOutput id="status" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
