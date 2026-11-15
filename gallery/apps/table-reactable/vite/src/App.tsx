import { Card, CardHeader, CardBody, PageFillable, ReactableOutput } from "bslibreact";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Table (reactable)</CardHeader>
        <CardBody>
          <ReactableOutput id="table" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
