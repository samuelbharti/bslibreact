import { Card, CardHeader, CardBody, PageFillable, WidgetOutput } from "bslib-react";

// leaflet has no dedicated component: WidgetOutput is the generic
// htmlwidget host, given the widget's own binding class.
export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Map (leaflet)</CardHeader>
        <CardBody>
          <WidgetOutput id="map" widgetClass="leaflet" height="400px" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
