import { PageFillable, TextOutput, ValueBox } from "bslibreact";

export default function App() {
  return (
    <PageFillable>
      <ValueBox title="Genes used" theme="primary">
        <TextOutput id="ngenes" className="value-box-value" />
      </ValueBox>
    </PageFillable>
  );
}
