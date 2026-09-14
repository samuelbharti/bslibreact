import { PasswordInput, Card, CardHeader, CardBody, PageFillable, TextOutput } from "bslib-react";

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
