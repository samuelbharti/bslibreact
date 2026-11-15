import {
  Card,
  CardHeader,
  CardBody,
  PageFillable,
  SliderInput,
  VerbatimTextOutput,
} from "bslibreact";

export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Verbatim text</CardHeader>
        <CardBody>
          <SliderInput id="n_ui" />
          <VerbatimTextOutput id="summary" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
