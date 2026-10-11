import { Card, CardHeader, CardBody, HostedInput, PageFillable, TextOutput } from "bslib-react";

// shiny::dateRangeInput() has no dedicated component: hosted through HostedInput.
export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Date range selector</CardHeader>
        <CardBody>
          <HostedInput id="dates_ui" />
          <TextOutput id="chosen" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
