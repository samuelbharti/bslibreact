import { ActionLink, Card, CardHeader, CardBody, PageFillable, TextOutput } from "bslib-react";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Action link</CardHeader>
        <CardBody>
          <ActionLink id="go_ui" />
          <TextOutput id="count" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
