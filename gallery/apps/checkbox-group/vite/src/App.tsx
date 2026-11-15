import { Card, CardHeader, CardBody, HostedInput, PageFillable, TextOutput } from "bslibreact";

// shiny::checkboxGroupInput() has no dedicated component: hosted through
// HostedInput, the same generic mechanism every named input alias uses.
export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Checkbox group</CardHeader>
        <CardBody>
          <HostedInput id="opts_ui" />
          <TextOutput id="selected" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
