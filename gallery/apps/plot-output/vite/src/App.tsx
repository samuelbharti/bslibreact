import { Card, CardHeader, CardBody, PageFillable, PlotOutput } from "bslib-react";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Plot</CardHeader>
        <CardBody>
          <PlotOutput id="plot" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
