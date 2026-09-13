# bslibreact

<!-- badges: start -->
<!-- badges: end -->

An R package for building [shinyreact](https://posit-dev.github.io/shinyreact/)
apps that look like [bslib](https://rstudio.github.io/bslib/) apps: it
gives a React client the same CSS and JavaScript a bslib page would
attach on its own, hosts server-rendered widgets for that client to
display, and ships the checks used to port an existing bslib app to the
shinyreact `ui.tsx` pattern. See the
[root README](https://github.com/samuelbharti/bslib-react#readme) for the
full picture across all three language packages.

## Install

```r
# From r-universe, once published:
install.packages("bslibreact", repos = "https://samuelbharti.r-universe.dev")

# From source, from this repository:
# install.packages("pak")
pak::pak("samuelbharti/bslib-react/pkg-r")
```

## Example

```r
library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)

ui <- page_react(
  title = "Demo",
  theme = app_theme,
  page_deps(app_theme),
  bslib_react_dep()
)

server <- function(input, output, session) {
  host_input(output, "bins", sliderInput("bins", "Bins", 1, 50, 30))
}

shinyApp(ui, server)
```

The client reads the hosted slider with `<ShinyOutput id="bins_ui" />` (or
the `HostedInput` component from the `bslib-react` npm package), and reads
its value the usual way, from `input$bins`.

## Scaffold a new app

```r
bslibreact::create_app("path/to/new-app", title = "My App")
```

## Porting an existing app

```r
bslibreact::port_triage("path/to/parent")
bslibreact::port_deps_diff("path/to/parent", "path/to/port")
bslibreact::port_peek("path/to/port", parent = "path/to/parent")
```

See `vignette("porting")` (once written) or the root repository's
`docs/porting.md` for the full workflow.

## Learn more

* Root [README](https://github.com/samuelbharti/bslib-react#readme)
* [docs/markup-catalog.md](https://github.com/samuelbharti/bslib-react/blob/main/docs/markup-catalog.md):
  the JSON contract `render_markup_catalog()` produces
* [docs/decisions/](https://github.com/samuelbharti/bslib-react/tree/main/docs/decisions):
  why this package is built the way it is
