import { Card, CardHeader, CardBody, PageFillable, DTOutput } from "bslibreact";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>DataTable</CardHeader>
        <CardBody>
          <DTOutput id="table" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
