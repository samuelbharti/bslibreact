import { SelectizeInput, Card, CardHeader, CardBody, PageFillable, TextOutput } from "bslib-react";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Selectize</CardHeader>
        <CardBody>
          <SelectizeInput id="gene_ui" />
          <TextOutput id="selected" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
