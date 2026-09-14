import {
  Card,
  CardHeader,
  CardBody,
  PageFillable,
  PlotOutput,
  SliderInput,
  useShinyInitialized,
} from "bslib-react";

export default function App() {
  const ready = useShinyInitialized();
  if (!ready) return null;

  return (
    <PageFillable>
      <Card>
        <CardHeader>Slider</CardHeader>
        <CardBody>
          <SliderInput id="bins_ui" />
          <PlotOutput id="plot" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
