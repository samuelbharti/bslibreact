# Building a new app

This is the workflow for a brand new Shiny app using the ui.tsx pattern
and this component kit, not a port of an existing app. See
`docs/porting.md` for porting.

## Tier

There is one supported client tier right now: a Vite build whose
client bundle externalizes React to `window.shinyreact`, and whose server
serves shinyreact's own runtime bundle. `examples/01-hello` is set up this
way, and it is the only tier this kit's components are tested against.

A no-build tier exists too: `bslib_react_dep()` (R or Python) serves a
prebuilt IIFE that registers `window.bslibReact`, so a page with no Node
step at all can still use `React.createElement(window.bslibReact.Card,
...)`. It is suitable for a small page; most apps should use the Vite
tier.

## Start from the example

There is no scaffolding tool. Copy `examples/01-hello` (both the R and
Python servers are there; keep whichever one you need) as a starting
point:

```
cp -R examples/01-hello myapp
cd myapp
```

Edit `app.R` or `app.py`'s app title and hosted widgets, and `src/App.tsx`
for the client. Delete the server file you are not using.

## Build and run

```
cd myapp
npm install
npm run build
```

R:

```r
shiny::runApp(".", port = 3838)
```

Python:

```
shiny run app.py --port 8000
```

## Dev loop

Run `npm run dev` (a watching build) in one terminal and the server in
another; reload the page after each client change.

## Hosting a widget

Every Shiny-bound widget in a ui.tsx app is hosted: the server renders the
widget's own call through `renderUI()` or `@render.ui`, and the client
reads it back with the matching hosted component. The recipe:

```r
output$bins_ui <- renderUI(sliderInput("bins", "Bins", 1, 50, 30))
```

```python
@render.ui
def bins_ui():
    return ui.input_slider("bins", "Bins", 1, 50, 30)
```

```tsx
<SliderInput id="bins_ui" />
```

Or, using the helper this package ships, which also catches an id
collision at render time instead of leaving it to show up as a browser
console warning:

```r
bslibreact::host_input(output, "bins", sliderInput("bins", "Bins", 1, 50, 30))
```

```python
bslib_react.host_input(output, "bins", lambda: ui.input_slider("bins", "Bins", 1, 50, 30))
```

Two rules that matter here:

1. The output name and the widget's own input id must differ. The `_ui`
   suffix is why: `sliderInput("bins", ...)` puts the id `bins` on the
   widget's own markup, and the hosted output wrapper puts its own id on
   its own element. Reusing one string for both puts two elements under
   one DOM id, and the browser logs a duplicate output id warning.
2. A holder that starts hidden, inside a closed accordion panel or a
   non-default tab, never renders at all by default, because Shiny
   suspends outputs that are not visible. Set
   `outputOptions(output, "bins_ui", suspendWhenHidden = FALSE)` in R, or
   `@render.ui(suspend_when_hidden=False)` in Python, if the widget needs
   to exist before its tab is first opened.

## The page

A ui.tsx app's page is shinyreact's own `page_react()`, given two things
from this package: `page_deps()`, the HTML dependencies this kit's
components and the app's hosted widgets need, and `bslib_react_dep()`,
the component bundle itself.

```r
library(shinyreact)

ui <- page_react(
  page_deps(app_theme),
  bslib_react_dep(),
  title = "My app",
  theme = app_theme
)
```

```python
from shinyreact import page_react
from bslib_react import page_deps, bslib_react_dep

app_ui = page_react(
    page_deps(app_theme),
    bslib_react_dep(),
    title="My app",
    theme=app_theme,
)
```

`bslib_react_dep()` must come after `page_deps()` so bslib-react's
component script, which reads `window.shinyreact` at load time, runs
after shinyreact's own script has set that global (see `bslib_react_dep()`'s
own doc comment on `defer` and load order).

Pass extra tags to `page_deps()` for any third party widget the app hosts
and this kit does not already sample, so its dependency gets collected
too:

```r
page_deps(app_theme, DT::DTOutput("x"), shinychat::chat_ui("x"))
```

## Level R

Not every piece needs to be hosted. Plain text, value boxes, and small
formatting blocks read cleanly as real React state instead:

```tsx
const status = useShinyOutputValue<string>("status");
```

Reach for a hosted widget by default and Level R only for values that are
truly just data, not an interactive control.

## Tests

R: `shiny::runTests(".")`. Python: `pytest`. Both run against the
scaffolded starter test; extend it as you add server logic.

## Deploy

If the target host has no Node build step (for example, deploying straight
from a GitHub repository), commit `www/ui.js` and `www/ui.css`. Otherwise
build the client as part of your deployment pipeline.
