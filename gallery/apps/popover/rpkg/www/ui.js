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
  const { Card, CardHeader, CardBody, PageFillable, UiOutput } =
    window.bslibReact;

  const h = React.createElement;

  // bslib::popover() has no dedicated component: MARKUP.md recommends
  // hosting the whole call through UiOutput, the generic escape hatch.
  function App() {
    return h(
      PageFillable,
      null,
      h(
        Card,
        null,
        h(CardHeader, null, "Popover"),
        h(CardBody, null, h(UiOutput, { id: "pop" })),
      ),
    );
  }

  const container = document.body.appendChild(document.createElement("div"));
  container.className = "html-fill-item html-fill-container";
  ReactDOM.createRoot(container).render(h(App));
});
