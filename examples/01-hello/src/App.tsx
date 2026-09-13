import {
  PageSidebar,
  SliderInput,
  PlotOutput,
  ValueBox,
  TextOutput,
  useShinyInitialized,
} from "bslib-react";

/**
 * The smallest complete bslib-react app: a themed sidebar holding one
 * hosted slider, a hosted plot reading that slider's value, and a value
 * box reading the same value back as plain text (Level R: it is only ever
 * a number formatted as a string, so it is not worth hosting).
 */
export default function App() {
  const ready = useShinyInitialized();
  if (!ready) return null;

  return (
    <PageSidebar title="Hello bslib-react" sidebar={<SliderInput id="bins_ui" />}>
      <ValueBox title="Bins">
        <TextOutput id="bins_count" className="value-box-value" />
      </ValueBox>
      <PlotOutput id="plot" height="400px" />
    </PageSidebar>
  );
}
