import { TextAreaInput, Card, CardHeader, CardBody, PageFillable, TextOutput } from "bslibreact";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Text area</CardHeader>
        <CardBody>
          <TextAreaInput id="genes_ui" />
          <TextOutput id="echo" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
