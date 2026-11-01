import {
  Card,
  CardHeader,
  CardBody,
  HostedInput,
  PageFillable,
  SliderInput,
  TextOutput,
} from "bslib-react";

// shiny::submitButton() has no dedicated component; hosted through HostedInput.
//
// Known limitation, confirmed by hand: submitButton()'s whole point is to
// hold back every input on the page until it is clicked, but Shiny's
// client only checks the page for a .shiny-submit-button once, at
// startup, before any hosted output (including this button itself) has
// had a chance to render. So that check never finds it, the hold-back
// mode never turns on, and the slider updates the text right away
// instead of waiting for Apply. The value still reaches the server
// either way, so the example is not broken, just not deferred. There is
// no fix for this at the app.R/App.tsx level: the button would have to
// exist in the very first HTML response, which means writing its markup
// by hand instead of hosting it, breaking the one pattern every hosted
// widget in this gallery follows.
export default function App() {
  return (
    <PageFillable>
      <Card>
        <CardHeader>Submit button</CardHeader>
        <CardBody>
          <SliderInput id="n_ui" />
          <HostedInput id="apply_ui" />
          <TextOutput id="value" />
        </CardBody>
      </Card>
    </PageFillable>
  );
}
