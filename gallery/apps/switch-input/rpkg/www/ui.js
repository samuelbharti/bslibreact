// No build step and no npm. The components come from the bslibreact R
// package's own vendored bundle, which publishes them on window.bslibReact,
// and React itself comes from shinyreact, which page_react() already loads.
//
// Waiting for load matters: page_react() emits this file's script tag before
// bslib_react_dep()'s, so window.bslibReact is not populated yet while this
// file is first evaluated. Reading the globals inside the listener sidesteps
// the ordering entirely.
window.addEventListener("load", function () {
  const { React, ReactDOM } = window.shinyreact;
  const { Card, CardHeader, CardBody, HostedInput, PageFillable, TextOutput } = window.bslibReact;

  const h = React.createElement;

  // bslib::input_switch() has no dedicated bslib-react component yet.
  // HostedInput is the generic escape hatch every named input alias (like
  // SliderInput) is itself built on: it hosts whatever widget the server's
  // host_input() call rendered, verbatim, no widget-specific props needed.
  function App() {
    return h(
      PageFillable,
      null,
      h(
        Card,
        null,
        h(CardHeader, null, "Switch"),
        h(CardBody, null, h(HostedInput, { id: "enabled_ui" }), h(TextOutput, { id: "status" })),
      ),
    );
  }

  const container = document.body.appendChild(document.createElement("div"));
  container.className = "html-fill-item html-fill-container";
  ReactDOM.createRoot(container).render(h(App));
});
