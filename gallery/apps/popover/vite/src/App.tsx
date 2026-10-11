import { Card, CardHeader, CardBody, PageFillable, UiOutput } from "bslib-react";

// bslib::popover() has no dedicated component: MARKUP.md recommends
// hosting the whole call through UiOutput, the generic escape hatch.
export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Popover</CardHeader>
        <CardBody>
          <UiOutput id="pop" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
