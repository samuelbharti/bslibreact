import { DownloadButton, Card, CardHeader, CardBody, PageFillable } from "bslib-react";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Download button</CardHeader>
        <CardBody>
          <DownloadButton id="dl_ui" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
