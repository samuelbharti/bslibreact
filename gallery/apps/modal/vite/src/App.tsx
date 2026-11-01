import { ActionButton, Card, CardHeader, CardBody, PageFillable } from "bslib-react";

// No modal-display component exists in bslib-react: shiny::showModal()
// renders through Shiny's own client JS, independent of the component
// tree, the same discovery as the Notification example.
export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Modal</CardHeader>
        <CardBody>
          <ActionButton id="go_ui" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
