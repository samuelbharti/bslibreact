import { RadioButtons, Card, CardHeader, CardBody, PageFillable, TextOutput } from "bslibreact";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Radio buttons</CardHeader>
        <CardBody>
          <RadioButtons id="values_ui" />
          <TextOutput id="selected" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
