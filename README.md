# bslib-react

React components that reproduce [bslib](https://rstudio.github.io/bslib/)
and [Shiny](https://shiny.posit.co/)'s own markup, class for class, for
[shinyreact](https://github.com/posit-dev/shinyreact)'s ui.tsx pattern: an
R or Python Shiny server that does reactive computation only, in front of
a React client that owns the page. shinyreact provides that plumbing; this
package provides the bslib-shaped components and the server helpers that
plumbing does not.

Status: version 0.1.0 is in progress. See `REPORT.md` for why this package
exists and what it measured before the first line of code moved here.

## Install

npm:

```
npm install bslib-react @posit-dev/shinyreact react react-dom
```

R:

```r
pak::pak("samuelbharti/bslib-react/pkg-r")
```

Python:

```
uv add bslib-react
```

## A worked example

Server (R):

```r
library(shiny)
library(bslib)
library(shinyreact)
library(bslibreact)

app_theme <- bs_theme(version = 5)
ui <- page_react(theme = app_theme, page_deps(app_theme))

server <- function(input, output, session) {
  host_input(output, "bins", sliderInput("bins", "Bins", 1, 50, 30))
  output$plot <- renderPlot(hist(rnorm(input$bins)))
}

shinyApp(ui, server)
```

Server (Python):

```python
from shiny import App, render, ui
from shinyreact import page_react
from bslib_react import host_input, page_deps

app_ui = page_react(page_deps())

def server(input, output, session):
    host_input(output, "bins", lambda: ui.input_slider("bins", "Bins", 1, 50, 30))

    @render.plot
    def plot():
        import numpy as np
        return None  # draw your plot here

app = App(app_ui, server)
```

Client (`src/App.tsx`):

```tsx
import { PageSidebar, SliderInput, PlotOutput } from "bslib-react";

export function App() {
  return (
    <PageSidebar sidebar={<SliderInput id="bins_ui" />}>
      <PlotOutput id="plot" />
    </PageSidebar>
  );
}
```

See `examples/01-hello` for the full runnable version of this app, in both
languages, and `docs/build.md` for scaffolding a new app from scratch.

## Level H and Level R

Every input widget in this kit (`SliderInput`, `SelectInput`, and so on)
hosts the server's own widget markup through `renderUI()` or `host_input()`
rather than rebuilding it in React. This kit calls that Level H, for
hosted. Plain text, value boxes, and small formatting blocks are the cases
worth making real React state instead, called Level R. See
`docs/decisions/0003-hosted-widgets.md` for why, and `docs/build.md` for
the exact recipe.

No Tailwind, no shadcn, no react-bootstrap. This package's whole reason to
exist is that those give a good looking app that does not look like the
bslib original.

## How the ground truth works

No HTML is committed to this repository. `make markup` renders a catalog
of bslib and shiny calls, using whichever versions of them you have
installed, into a gitignored cache. The component tests compare against
that cache. CI does the same on every pull request, and once a week
against the newest released bslib, shiny, and py-shiny; a failure there
means bslib changed its markup, which is the signal to read the diff and
cut a new minor version, not a bug in this repository. See
`docs/decisions/0001-no-fixtures-live-ground-truth.md` and
`docs/markup-catalog.md`.

## Supported versions

The catalog is rendered and tested against these versions; anything older
is untested, not necessarily broken.

| | Version |
| --- | --- |
| bslib | >= 0.12.0 |
| shiny (R) | >= 1.14.0 |
| shiny (Python) | >= 1.7.0 |
| react | 19.x |
| @posit-dev/shinyreact | >= 0.1.1 |

## Scope

This package mirrors bslib and Shiny's own UI. A component bslib does not
have is out of scope here; ask for it in bslib first, and it gets a row in
this kit once bslib ships it.

## Learn more

- `docs/build.md`: build a new app with this kit, in R or Python.
- `docs/porting.md`: port an existing Shiny app to the ui.tsx pattern.
- `docs/markup.md`: the full R call, Python call, and TSX component map.
- `docs/decisions/`: why this repository is shaped the way it is.
- `pkg-js/CHANGELOG.md`, `pkg-py/CHANGELOG.md`, `pkg-r/NEWS.md`: what
  changed in each release.

## License

MIT. See `LICENSE`.
