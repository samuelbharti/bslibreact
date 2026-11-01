# Volcano plot

A small real analysis app: five hosted inputs (two thresholds, a
significance metric choice, a label toggle, and a label count) drive a
server-rendered volcano plot of a synthetic differential expression
result set, alongside three value boxes reading the same status counts
the plot colours by. Built with
[bslib-react](https://github.com/samuelbharti/bslib-react). The user
interface is a React client (`src/`, built to `www/ui.js`); `app.R` and
`app.py` hold only reactive computation and the plot rendering.

This example also shows a `_brand.yml` file in use: the page's colours and
typography come from it, through `bs_theme(brand = TRUE)` in R and
`ui.Theme.from_brand()` in Python, and the plot's own status colours are
read from a small palette helper (`R/_shared/palettes.R`,
`volcano.py`'s `STATUS_COLOURS`) rather than hard-coded into the chart
itself.

## Run it

R:

```powershell
Rscript --% -e "shiny::runApp('.', port = 3838)"
```

Python:

```bash
uv run shiny run app.py --port 8000
```

`www/ui.js` is committed, so either server runs with no Node step. After
changing `src/`, rebuild it from the repository root with `npm ci` and
`make bundles`.

## Layout

- `app.R` / `app.py`: reactive computation, unchanged in shape from a
  plain bslib or Shiny Express app of the same name.
- `R/mod-volcano.R`, `R/plot-volcano.R`, `R/_shared/`: the R side's data
  preparation, classification, and ggplot2 rendering, split the way a
  larger app would share this module across several pages.
- `volcano.py`: the Python twin of the three R files above, kept as one
  file since this example has nothing else to share it with.
- `src/App.tsx`: the one client both servers share. The plot sits inside
  a `<Module namespace="volcano">`, matching the R server's
  `moduleServer("volcano", ...)`; the Python server uses py-shiny's
  `@module.server` for the same id shape.

## A deliberate simplification

The R server's plot click handler (`nearPoints()`, mapping a click to the
nearest gene) is wired but not surfaced anywhere in this example's UI,
matching the app it is based on. The Python server enables click support
on the same output for markup parity but does not implement the
nearest-point lookup itself, since nothing here reads it either.
