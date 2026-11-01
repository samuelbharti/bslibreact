import { Card, CardHeader, CardBody, HostedInput, PageFillable, TextOutput } from "bslibreact";

// bslib::input_switch() has no dedicated bslibreact component yet.
// HostedInput is the generic escape hatch every named input alias (like
// SliderInput) is itself built on: it hosts whatever widget the server's
// host_input() call rendered, verbatim, no widget-specific props needed.
export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Switch</CardHeader>
        <CardBody>
          <HostedInput id="enabled_ui" />
          <TextOutput id="status" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
