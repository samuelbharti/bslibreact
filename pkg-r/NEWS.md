# bslibreact (development version)

Not yet released.

* `page_deps()` collects the htmlDependency objects a client bundle needs to
  match a page built from bslib and shiny markup, without attaching
  bootstrap itself.
* `host_input()` registers a server-rendered widget as a `renderUI()` output
  under a `_ui`-suffixed name, and aborts at render time if the widget's own
  id collides with the output wrapper's id.
* `bslib_react_dep()` returns the htmlDependency for the vendored
  `bslib-react.js` bundle.
