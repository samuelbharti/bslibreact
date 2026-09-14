import { Card, CardHeader, CardBody, PageFillable, ImageOutput } from "bslib-react";

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
