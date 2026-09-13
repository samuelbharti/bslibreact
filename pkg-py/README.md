# bslib-react (Python)

Server helpers for [bslib-react](https://github.com/samuelbharti/bslib-react):
a React component kit that reproduces the exact markup `bslib` and Shiny
render, for apps built with [shinyreact](https://github.com/posit-dev/shinyreact)'s
`ui.tsx` pattern. This package is the Python half. It ships no UI of its own;
the components live in the npm package `bslib-react`.

## Install

```bash
pip install bslib-react shinyreact
```

## Use

```python
from pathlib import Path
from shiny import App, render, ui
from shinyreact import page_react
from bslib_react import page_deps, bslib_react_dep, host_input

app_theme = (
    ui.Theme.from_brand(Path(__file__).parent)
    if (Path(__file__).parent / "_brand.yml").exists()
    else None
)
app_ui = page_react(
    page_deps(app_theme), bslib_react_dep(), title="Demo", theme=app_theme
)


def server(input, output, session):
    host_input(output, "bins", lambda: ui.input_slider("bins", "Bins", 1, 50, 30))


app = App(app_ui, server)
```

`page_deps()` attaches the CSS and JS that bslib-react's React components
need at runtime (ion.rangeSlider, selectize, and friends), the same way a
plain bslib page would pick them up automatically; `bslib_react_dep()` is
the component bundle itself. `host_input()` mounts one server-rendered
Shiny widget (here, a slider) inside a React page and hands back the output
id your `<SliderInput id="bins_ui" />` element should read.

See the [root README](https://github.com/samuelbharti/bslib-react#readme) for
the full picture across R, Python and JS, and `docs/` in the repository for
the porting guide and the markup catalog contract this package's catalog
renderer implements.
