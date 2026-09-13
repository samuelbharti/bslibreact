# bslibreact

<!-- badges: start -->
<!-- badges: end -->

An R package for building [shinyreact](https://posit-dev.github.io/shinyreact/)
apps that look like [bslib](https://rstudio.github.io/bslib/) apps: it
gives a React client the same CSS and JavaScript a bslib page would
attach on its own, and hosts server-rendered widgets for that client to
display. The matching React components live in the `bslib-react` npm
package. See the
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

ui <- page_react(page_deps(app_theme), bslib_react_dep(), title = "Demo", theme = app_theme)

server <- function(input, output, session) {
  host_input(output, "bins", sliderInput("bins", "Bins", 1, 50, 30))
}

shinyApp(ui, server)
```

The client reads the hosted slider with `<ShinyOutput id="bins_ui" />` (or
the `HostedInput` component from the `bslib-react` npm package), and reads
its value the usual way, from `input$bins`.

## Starting a new app or porting one

See the root repository's `docs/build.md` for a new app and
`docs/porting.md` for porting an existing bslib app to this pattern.

## Learn more

* Root [README](https://github.com/samuelbharti/bslib-react#readme)
* [docs/markup-catalog.md](https://github.com/samuelbharti/bslib-react/blob/main/docs/markup-catalog.md):
  the JSON contract the repository's markup catalog renderer produces
* [docs/decisions/](https://github.com/samuelbharti/bslib-react/tree/main/docs/decisions):
  why this package is built the way it is
