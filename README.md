# bslib-react

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

React components that reproduce [bslib](https://rstudio.github.io/bslib/)
and [Shiny](https://shiny.posit.co/)'s own markup, class for class, for
[shinyreact](https://github.com/posit-dev/shinyreact)'s ui.tsx pattern: an
R or Python Shiny server that does reactive computation only, in front of
a React client that owns the page. shinyreact provides that plumbing; this
package provides the bslib-shaped components and the server helpers that
plumbing does not.

Status: experimental. The API may change without a deprecation cycle
while the shape of the three packages settles.

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
ui <- page_react(page_deps(app_theme), bslib_react_dep(), title = "Demo", theme = app_theme)

server <- function(input, output, session) {
  host_input(output, "bins", sliderInput("bins", "Bins", 1, 50, 30))
  output$plot <- renderPlot(hist(rnorm(500), breaks = req(input$bins)))
}

shinyApp(ui, server)
```

Server (Python):

```python
import matplotlib.pyplot as plt
import numpy as np
from shiny import App, render, req, ui
from shinyreact import page_react
from bslib_react import page_deps, bslib_react_dep, host_input

app_theme = ui.Theme()
app_ui = page_react(page_deps(app_theme), bslib_react_dep(), title="Demo", theme=app_theme)

def server(input, output, session):
    host_input(output, "bins", lambda: ui.input_slider("bins", "Bins", 1, 50, 30))

    @render.plot
    def plot():
        fig, ax = plt.subplots()
        ax.hist(np.random.normal(size=500), bins=req(input.bins()))
        return fig

app = App(app_ui, server)
```

Client (`src/App.tsx`):

```tsx
import { PageSidebar, SliderInput, PlotOutput } from "bslib-react";

export default function App() {
  return (
    <PageSidebar title="Demo" sidebar={<SliderInput id="bins_ui" />}>
      <PlotOutput id="plot" />
    </PageSidebar>
  );
}
```

See `examples/01-hello` for the full runnable version of this app, in both
languages, and `docs/build.md` for scaffolding a new app from scratch.

## Hosted widgets versus React state

Every input widget in this kit (`SliderInput`, `SelectInput`, and so on)
hosts the server's own widget markup through `renderUI()` or
`host_input()` rather than rebuilding it in React, so each one keeps the
behaviour Shiny already gives it: ionRangeSlider's skin, selectize's
dropdown, the datepicker. Plain text, value boxes, and small formatting
blocks are the cases worth making real React state instead, since
round-tripping to the server to format a number buys nothing.

This repository calls those two styles Level H, for hosted, and Level R,
for React. The shorthand runs through the source and the guides, so it is
worth knowing before reading either. See
`docs/decisions/0003-hosted-widgets.md` for where the line is drawn and
why, and `docs/build.md` for the recipe.

No Tailwind, no shadcn, no react-bootstrap. This package's whole reason to
exist is that those give a good looking app that does not look like the
bslib original.

## How the ground truth works

No HTML is committed to this repository. `make markup` renders a catalog
of bslib and shiny calls, using whichever versions of them you have
installed, into a gitignored cache. The component tests compare against
that cache. CI does the same on every pull request that touches the kit,
the catalog, or the pinned versions, and once a week
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
| shiny (Python) | >= 1.8.0 |
| react | 19.x |
| @posit-dev/shinyreact | >= 0.1.1 |

## Scope

This package mirrors bslib and Shiny's own UI. A component bslib does not
have is out of scope here; ask for it in bslib first, and it gets a row in
this kit once bslib ships it.

## Component gallery

`gallery/` is a side by side gallery matching
[shiny.posit.co/r/components](https://shiny.posit.co/r/components/): a
sidebar lists every example, and picking one shows it large, switchable
between classic bslib + Shiny and bslib-react + shinyreact, with a button
to compare the code. It's a real Shiny app (`Rscript -e
"shiny::runApp('gallery')"`), meant for Posit Connect Cloud eventually.
R only for now. See `gallery/README.md`; not deployed publicly yet.

## Learn more

- `docs/build.md`: build a new app with this kit, in R or Python.
- `docs/porting.md`: port an existing Shiny app to the ui.tsx pattern.
- `docs/markup.md`: the full R call, Python call, and TSX component map.
- `docs/decisions/`: why this repository is shaped the way it is.
- `pkg-js/CHANGELOG.md`, `pkg-py/CHANGELOG.md`, `pkg-r/NEWS.md`: what
  changed in each release.

## License

MIT. See `LICENSE`.
