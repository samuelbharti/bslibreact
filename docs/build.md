# Building a new app

This is the workflow for a brand new Shiny app using the ui.tsx pattern
and this component kit, not a port of an existing app. See
`docs/porting.md` for porting.

## Tier

There is one supported client tier in version 0.1.0: a Vite build whose
client bundle externalizes React to `window.shinyreact`, and whose server
serves shinyreact's own runtime bundle. This is what `create_app()`
scaffolds, and it is the only tier this kit's components are tested
against.

A no-build tier exists too: `bslib_react_dep()` (R) or `bslib_react_dep()`
(Python) serves a prebuilt IIFE that registers `window.bslibReact`, so a
page with no Node step at all can still use
`React.createElement(window.bslibReact.Card, ...)`. It is suitable for a
small page; most apps should use the Vite tier.

## Scaffold

```r
bslibreact::create_app("myapp", title = "My app")
```

```bash
python -m bslib_react create-app myapp --title "My app"
```

This creates `app.R` or `app.py`, `src/ui.tsx`, `src/App.tsx`,
`vite.config.ts`, `tsconfig.json`, `package.json`, and a starter test, all
wired to run as soon as you build.

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

## Page dependencies

Every ui.tsx app needs one call collecting the HTML dependencies its
hosted widgets and this kit's own components require, themed correctly:

```r
ui <- page_react(theme = app_theme, page_deps(app_theme))
```

```python
app_ui = page_react(page_deps(app_theme))
```

Pass extra tags for any third party widget the app hosts and this kit does
not already sample, so its dependency gets collected too:

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
