# bslibreact 0.1.0

First release. The package is experimental: the three functions below are
what it exports, and their signatures may still change.

* `page_deps()` renders a sample of bslib and shiny markup under a theme
  and returns the `htmlDependency()` objects that markup attaches, so a
  shinyreact client can be served the same CSS and JavaScript a matching
  bslib page would have attached on its own. `"bootstrap"` and
  `"jquery"` are left out, since a shiny page already carries both, and
  each remaining dependency is returned once.

* `host_input()` renders a shiny input server-side into an output the
  React client displays, for the widgets that have no dedicated
  component. The output is named with a `_ui` suffix, which the client's
  own `id` has to match, and keeps rendering while hidden, as the Python
  `host_input()` does.

* `bslib_react_dep()` returns the `htmlDependency()` for the vendored
  `bslib-react.js` bundle. Attach it after shinyreact's own dependency:
  the bundle reads `window.shinyreact` as it evaluates.
