import { DarkModeInput, Card, CardHeader, CardBody, PageFillable, TextOutput } from "bslibreact";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Dark mode switch</CardHeader>
        <CardBody>
          <DarkModeInput id="dark_mode_ui" />
          <TextOutput id="mode" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
