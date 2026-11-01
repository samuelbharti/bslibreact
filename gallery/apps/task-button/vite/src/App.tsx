import { Card, CardHeader, CardBody, HostedInput, PageFillable, TextOutput } from "bslibreact";

// bslib::input_task_button() has no dedicated component: hosted through HostedInput.
export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Task button</CardHeader>
        <CardBody>
          <HostedInput id="run_ui" />
          <TextOutput id="status" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
