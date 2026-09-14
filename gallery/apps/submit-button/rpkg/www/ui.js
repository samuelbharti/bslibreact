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
    HostedInput,
    PageFillable,
    SliderInput,
    TextOutput,
  } = window.bslibReact;

  const h = React.createElement;

  // shiny::submitButton() has no dedicated component; hosted through
  // HostedInput.
  //
  // Known limitation, confirmed by hand: submitButton()'s whole point is to
  // hold back every input on the page until it is clicked, but Shiny's
  // client only checks the page for a .shiny-submit-button once, at
  // startup, before any hosted output (including this button itself) has
  // had a chance to render. So that check never finds it, the hold-back
  // mode never turns on, and the slider updates the text right away
  // instead of waiting for Apply. The value still reaches the server
  // either way, so the example is not broken, just not deferred. The
  // no-build route hits the same wall as the npm one: the button would
  // have to exist in the very first HTML response, which means writing
  // its markup by hand instead of hosting it, breaking the one pattern
  // every hosted widget in this gallery follows.
  function App() {
    return h(
      PageFillable,
      null,
      h(
        Card,
        null,
        h(CardHeader, null, "Submit button"),
        h(
          CardBody,
          null,
          h(SliderInput, { id: "n_ui" }),
          h(HostedInput, { id: "apply_ui" }),
          h(TextOutput, { id: "value" }),
        ),
      ),
    );
  }

  const container = document.body.appendChild(document.createElement("div"));
  container.className = "html-fill-item html-fill-container";
  ReactDOM.createRoot(container).render(h(App));
});
