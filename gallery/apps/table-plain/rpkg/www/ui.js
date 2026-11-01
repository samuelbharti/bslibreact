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
  const { Card, CardHeader, CardBody, PageFillable, UiOutput } = window.bslibreact;

  const h = React.createElement;

  // Plain shiny::tableOutput() has no dedicated component (and needs no
  // widget binding beyond basic Shiny output plumbing): UiOutput hosts it.
  function App() {
    return h(
      PageFillable,
      null,
      h(Card, null, h(CardHeader, null, "Table"), h(CardBody, null, h(UiOutput, { id: "table" }))),
    );
  }

  const container = document.body.appendChild(document.createElement("div"));
  container.className = "html-fill-item html-fill-container";
  ReactDOM.createRoot(container).render(h(App));
});
