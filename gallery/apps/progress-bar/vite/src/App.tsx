import { ActionButton, Card, CardHeader, CardBody, PageFillable } from "bslibreact";

// No progress-bar component exists in bslibreact: shiny::withProgress()
// renders through Shiny's own client JS, independent of the component
// tree, the same discovery as Notification and Modal.
export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Progress bar</CardHeader>
        <CardBody>
          <ActionButton id="go_ui" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
