import { Card, HostedInput, PageFillable } from "bslib-react";

// One hosted slider, rendered server-side by `host_input()` in app.py and
// mounted here at the output id it returns ("bins_ui" for id="bins").
// Replace pieces of this with plain bslib-react components as you build out
// the real page; the hosted widget is only here so a fresh scaffold runs.
export function App() {
  return (
    <PageFillable>
      <Card>
        <h2>APP_TITLE</h2>
        <HostedInput id="bins_ui" />
      </Card>
    </PageFillable>
  );
}
