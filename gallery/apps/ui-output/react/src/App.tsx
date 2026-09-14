import { Card, CardHeader, CardBody, CheckboxInput, PageFillable, UiOutput } from "bslib-react";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>UI</CardHeader>
        <CardBody>
          <CheckboxInput id="show_extra_ui" />
          <UiOutput id="extra" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
