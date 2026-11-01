import { Card, CardHeader, CardBody, PageFillable, UiOutput } from "bslibreact";

// gt has no dedicated component: gt_output() is a plain HTML output
// binding (like tableOutput()/uiOutput()), so UiOutput hosts it.
export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Table (gt)</CardHeader>
        <CardBody>
          <UiOutput id="table" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
