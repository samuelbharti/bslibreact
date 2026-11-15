# bslibreact (Python)

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

Server helpers for [bslibreact](https://github.com/samuelbharti/bslibreact):
a React component kit that reproduces the exact markup `bslib` and Shiny
render, for apps built with [shinyreact](https://github.com/posit-dev/shinyreact)'s
`ui.tsx` pattern. This package is the Python half. It ships no UI of its own;
the components live in the npm package `bslibreact`.

## Install

```bash
pip install bslibreact shinyreact
```

## Use

```python
from pathlib import Path
from shiny import App, render, ui
from shinyreact import page_react
from bslibreact import page_deps, host_input

app_theme = (
    ui.Theme.from_brand(Path(__file__).parent)
    if (Path(__file__).parent / "_brand.yml").exists()
    else ui.Theme()
)
app_ui = page_react(page_deps(app_theme), title="Demo", theme=app_theme)


def server(input, output, session):
    host_input(output, "bins", lambda: ui.input_slider("bins", "Bins", 1, 50, 30))


app = App(app_ui, server)
```

`page_deps()` attaches the CSS and JS that bslibreact's React components
need at runtime (ion.rangeSlider, selectize, and friends), the same way a
plain bslib page would pick them up automatically. A client with no build
step also attaches `bslibreact_dep()`, the prebuilt component bundle it
reads as `window.bslibreact`. `host_input()` mounts one server-rendered
Shiny widget (here, a slider) inside a React page and hands back the output
id your `<SliderInput id="bins_ui" />` element should read.

See the [root README](https://github.com/samuelbharti/bslibreact#readme) for
the full picture across R, Python and JS, and `docs/` in the repository for
the porting guide and the markup catalog spec this package's catalog
renderer implements.
