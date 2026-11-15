import { Card, CardHeader, CardBody, HostedInput, PageFillable } from "bslibreact";

// shiny::downloadLink() has no dedicated component yet (DownloadButton is
// the button-styled sibling); hosted through HostedInput.
export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Download link</CardHeader>
        <CardBody>
          <HostedInput id="dl_ui" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
