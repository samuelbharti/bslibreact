// No build step and no npm. The components come from the bslibreact R
// package's own vendored bundle, which publishes them on window.bslibreact,
// and React itself comes from shinyreact, which page_react() already loads.
//
// Waiting for load matters: page_react() emits this file's script tag before
// bslibreact_dep()'s, so window.bslibreact is not populated yet while this
// file is first evaluated. Reading the globals inside the listener sidesteps
// the ordering entirely.
window.addEventListener("load", function () {
  const { React, ReactDOM } = window.shinyreact;
  const { Card, CardHeader, CardBody, PageFillable, SliderInput, TextOutput } = window.bslibreact;

  const h = React.createElement;

  // A two-handle sliderInput() is hosted by SliderInput like any other
  // slider; no separate "range" component is needed.
  function App() {
    return h(
      PageFillable,
      null,
      h(
        Card,
        null,
        h(CardHeader, null, "Slider range"),
        h(CardBody, null, h(SliderInput, { id: "range_ui" }), h(TextOutput, { id: "chosen" })),
      ),
    );
  }

  const container = document.body.appendChild(document.createElement("div"));
  container.className = "html-fill-item html-fill-container";
  ReactDOM.createRoot(container).render(h(App));
});
