import { TextInput, Card, CardHeader, CardBody, PageFillable, TextOutput } from "bslib-react";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Text box</CardHeader>
        <CardBody>
          <TextInput id="q_ui" />
          <TextOutput id="echo" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
