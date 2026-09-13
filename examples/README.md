# Examples

Two runnable apps, each with both an R and a Python server, sharing one
React client per example.

| Example | Shows |
| --- | --- |
| `01-hello` | The smallest complete app: a themed sidebar, one hosted slider, one hosted plot, one value box. Start here. |
| `volcano-plot` | A small real analysis app: a hosted selectize input, a card-embedded plot with a click handler, and a value box row, ported from a plain bslib Shiny app. |

## Running an example

R:

```
Rscript -e "shiny::runApp('examples/01-hello', port = 3838)"
```

Python:

```
uv run shiny run examples/01-hello/app.py --port 8000
```

Each example's `www/ui.js` is committed, so the R server runs with no
Node step at all. Run `npm run build` inside the example's own directory
after changing `src/` before the change shows up.

## Checking a port against a parent

`volcano-plot` is also the working example for this package's port check
tools:

```r
bslibreact::port_deps_diff("examples/01-hello", "examples/01-hello")
bslibreact::port_peek("examples/volcano-plot", out = "docs/local/peek")
```

See `docs/porting.md` for what these functions check and why.
