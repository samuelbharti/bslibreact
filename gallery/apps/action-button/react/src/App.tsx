import { ActionButton, Card, CardHeader, CardBody, PageFillable, TextOutput } from "bslib-react";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Action button</CardHeader>
        <CardBody>
          <ActionButton id="go_ui" />
          <TextOutput id="count" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
