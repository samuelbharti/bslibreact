import { TextInput, Card, CardHeader, CardBody, PageFillable, TextOutput } from "bslibreact";

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
