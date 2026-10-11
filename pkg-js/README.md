# bslib-react

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

React components that reproduce [bslib](https://rstudio.github.io/bslib/)'s
layout, page shell, and output markup, for apps built with
[shinyreact](https://posit-dev.github.io/shinyreact/)'s ui.tsx pattern. If
you are porting a Shiny app built with bslib to React, this kit gives you
the page shell, cards, sidebars, navbars, and output wrappers so you do not
have to reproduce bslib's HTML and classes by hand.

The kit does not invent its own design language. Every component reproduces
one specific bslib call, and is tested against the exact HTML the installed
bslib actually renders (see `../docs/markup-catalog.md` at the repo root).

## Install

```
npm install bslib-react @posit-dev/shinyreact react react-dom
```

`react` and `react-dom` are peer dependencies (`19.x`).
`@posit-dev/shinyreact` is an optional peer dependency: install it if you
bundle it yourself, or leave it out if your app loads shinyreact's own
served `shinyreact.js` on the page (see "Two ways to ship this" below).

## A small example

```tsx
import { PageSidebar, Card, CardHeader, CardBody, SliderInput, PlotOutput } from "bslib-react";

function App() {
  return (
    <PageSidebar title="A small app" sidebar={<SliderInput id="bins_ui" />}>
      <Card fullScreen>
        <CardHeader>Histogram</CardHeader>
        <CardBody>
          <PlotOutput id="plot" />
        </CardBody>
      </Card>
    </PageSidebar>
  );
}
```

`SliderInput` and `PlotOutput` are hosted: the actual widget markup comes
from the server's own `output$bins_ui <- renderUI(sliderInput(...))` and
`output$plot <- renderPlot(...)`, not from this package. `PageSidebar` and
`Card` reproduce bslib's own markup directly in TSX, so their styling and
Shiny bindings work exactly as they would on a server-rendered bslib page.

## Two ways to ship this

The R and Python packages vendor a prebuilt IIFE bundle
(`dist/bslib-react.js`). An app attaches it as a page dependency with
`bslibreact::bslib_react_dep()` (R) or `bslib_react.bslib_react_dep()`
(Python), next to shinyreact's own `shinyreact.js`, and never installs the
npm package at all: it reads this kit off `window.bslibReact` at runtime.

An app that bundles its own client with a JS bundler instead installs this
package from npm and imports it directly:

```tsx
import { Card } from "bslib-react";
```

The npm build (`dist-npm/`) is plain ESM with `react`/`react-dom`
externalized as peer dependencies, so your bundler resolves one shared
React instance the normal way.

## Scope

This kit mirrors bslib: it only has components for the pieces of bslib an
app has actually needed so far. A bslib component with no dedicated
component here yet is usually still reachable through `UiOutput`, the
escape hatch that hosts an entire dynamic R UI fragment as Shiny's own
`uiOutput()` binding renders it. See
[docs/markup.md](https://github.com/samuelbharti/bslib-react/blob/main/docs/markup.md)
for the full map of what exists, what is hosted instead of reproduced,
and what is not built yet.
