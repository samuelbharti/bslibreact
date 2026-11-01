import { PasswordInput, Card, CardHeader, CardBody, PageFillable, TextOutput } from "bslibreact";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Password field</CardHeader>
        <CardBody>
          <PasswordInput id="key_ui" />
          <TextOutput id="status" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
