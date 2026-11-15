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
  const { ActionButton, Card, CardHeader, CardBody, PageFillable } = window.bslibreact;

  const h = React.createElement;

  // No notification-display component exists in bslibreact at all. This
  // example exists to answer a real open question: shiny::showNotification()
  // sends its message down the same websocket connection to Shiny's own
  // client JS, which renders it into a fixed overlay it manages itself,
  // entirely independent of bslibreact's component tree. If shinyreact
  // boots a real, complete Shiny client (it does), this should just work
  // with no bslibreact involvement at all.
  function App() {
    return h(
      PageFillable,
      null,
      h(
        Card,
        null,
        h(CardHeader, null, "Notification"),
        h(CardBody, null, h(ActionButton, { id: "go_ui" })),
      ),
    );
  }

  const container = document.body.appendChild(document.createElement("div"));
  container.className = "html-fill-item html-fill-container";
  ReactDOM.createRoot(container).render(h(App));
});
