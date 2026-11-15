import { Card, CardHeader, CardBody, HostedInput, PageFillable, TextOutput } from "bslibreact";

// shiny::dateInput() has no dedicated component: hosted through HostedInput.
export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Date selector</CardHeader>
        <CardBody>
          <HostedInput id="date1_ui" />
          <TextOutput id="chosen" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
