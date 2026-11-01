import { Card, CardHeader, CardBody, PageFillable, UiOutput } from "bslibreact";

// Plain shiny::tableOutput() has no dedicated component (and needs no
// widget binding beyond basic Shiny output plumbing): UiOutput hosts it.
export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Table</CardHeader>
        <CardBody>
          <UiOutput id="table" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
