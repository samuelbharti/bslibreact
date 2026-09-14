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
  const { ActionButton, Card, CardHeader, CardBody, PageFillable } = window.bslibReact;

  const h = React.createElement;

  // No progress-bar component exists in bslib-react: shiny::withProgress()
  // renders through Shiny's own client JS, independent of the component
  // tree, the same discovery as Notification and Modal.
  function App() {
    return h(
      PageFillable,
      null,
      h(
        Card,
        null,
        h(CardHeader, null, "Progress bar"),
        h(CardBody, null, h(ActionButton, { id: "go_ui" })),
      ),
    );
  }

  const container = document.body.appendChild(document.createElement("div"));
  container.className = "html-fill-item html-fill-container";
  ReactDOM.createRoot(container).render(h(App));
});
