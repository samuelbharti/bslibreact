import { Card, CardHeader, CardBody, PageFillable, TableOutput } from "bslib-react";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>DataTable</CardHeader>
        <CardBody>
          <TableOutput id="table" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
