import { SelectizeInput, Card, CardHeader, CardBody, PageFillable, TextOutput } from "bslib-react";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Selectize (multiple)</CardHeader>
        <CardBody>
          <SelectizeInput id="genes_ui" />
          <TextOutput id="selected" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
