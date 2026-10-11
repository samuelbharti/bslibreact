import { Card, CardHeader, CardBody, PageFillable, WidgetOutput } from "bslib-react";

// plotly has no dedicated component: WidgetOutput is the generic
// htmlwidget host (docs/markup.md names plotly as the example for this).
export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Plot (plotly)</CardHeader>
        <CardBody>
          <WidgetOutput id="plot" widgetClass="plotly" height="400px" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
