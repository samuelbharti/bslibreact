import { Card, CardHeader, CardBody, PageFillable, ImageOutput } from "bslibreact";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Image</CardHeader>
        <CardBody>
          <ImageOutput id="img" height="300px" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
