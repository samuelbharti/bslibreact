import {
  Card,
  CardHeader,
  CardBody,
  PageFillable,
  PlotOutput,
  VerbatimTextOutput,
} from "bslibreact";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Plot (click input)</CardHeader>
        <CardBody>
          <PlotOutput id="plot" click="plot_click" />
          <VerbatimTextOutput id="info" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
