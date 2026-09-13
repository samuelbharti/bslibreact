# bslibreact 0.1.0

Initial release.

* `page_deps()` collects the htmlDependency objects a client bundle needs to
  match a page built from bslib and shiny markup, without attaching
  bootstrap itself.
* `host_input()` registers a server-rendered widget as a `renderUI()` output
  under a `_ui`-suffixed name, and aborts at render time if the widget's own
  id collides with the output wrapper's id.
* `bslib_react_dep()` returns the htmlDependency for the vendored
  `bslib-react.js` bundle.
* `markup_catalog()` and `markup_catalog_key()` expose the catalog of
  sample bslib and shiny calls this package renders for its own tests and
  for the matching JavaScript package's markup tests.
* `render_markup_catalog()` renders the catalog live, from whichever bslib,
  shiny, and htmltools are installed, into a JSON file read by the
  JavaScript test suite.
* `port_triage()` reads a Shiny app's R source and reports its page
  function, theme, inputs, outputs, dynamic UI, modules, and packages.
* `port_deps_diff()` compares the stylesheets and scripts two running Shiny
  apps load, so a shinyreact port can be checked against its parent.
* `port_peek()` opens a running app in headless Chrome and reports console
  errors, bound inputs and outputs, and a screenshot.
* `create_app()` scaffolds a new shinyreact app that uses `page_deps()` and
  `host_input()`.
