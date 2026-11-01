import { SelectInput, Card, CardHeader, CardBody, PageFillable, TextOutput } from "bslibreact";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Select (multiple)</CardHeader>
        <CardBody>
          <SelectInput id="x_ui" />
          <TextOutput id="selected" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
