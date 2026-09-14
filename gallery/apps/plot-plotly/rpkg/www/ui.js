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
  const {
    Card,
    CardHeader,
    CardBody,
    PageFillable,
    WidgetOutput,
  } = window.bslibReact;

  const h = React.createElement;

  // plotly has no dedicated component: WidgetOutput is the generic
  // htmlwidget host (MARKUP.md names plotly as the example for this).
  function App() {
    return h(
      PageFillable,
      null,
      h(
        Card,
        null,
        h(CardHeader, null, "Plot (plotly)"),
        h(
          CardBody,
          null,
          h(WidgetOutput, {
            id: "plot",
            widgetClass: "plotly",
            height: "400px",
          }),
        ),
      ),
    );
  }

  const container = document.body.appendChild(document.createElement("div"));
  container.className = "html-fill-item html-fill-container";
  ReactDOM.createRoot(container).render(h(App));
});
