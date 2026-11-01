import { ActionButton, Card, CardHeader, CardBody, PageFillable } from "bslibreact";

// No notification-display component exists in bslibreact at all. This
// example exists to answer a real open question: shiny::showNotification()
// sends its message down the same websocket connection to Shiny's own
// client JS, which renders it into a fixed overlay it manages itself,
// entirely independent of bslibreact's component tree. If shinyreact
// boots a real, complete Shiny client (it does), this should just work
// with no bslibreact involvement at all.
export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Notification</CardHeader>
        <CardBody>
          <ActionButton id="go_ui" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
