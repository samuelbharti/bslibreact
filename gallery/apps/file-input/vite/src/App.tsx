import { FileInput, Card, CardHeader, CardBody, PageFillable, TextOutput } from "bslibreact";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>File input</CardHeader>
        <CardBody>
          <FileInput id="upload_ui" />
          <TextOutput id="status" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
