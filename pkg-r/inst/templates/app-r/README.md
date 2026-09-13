# APP_TITLE

A Shiny app built with [bslib-react](https://github.com/samuelbharti/bslib-react):
the user interface is a React client (`src/`, built to `www/ui.js`), and
`app.R` holds only reactive computation.

## Run it

```powershell
npm ci
npm run build
Rscript --% -e "shiny::runApp('.', port = 3838)"
```

## Status

If this app is a port of an existing bslib app, see `PORT.md` for the
behavior checklist and the parity checks
(`bslibreact::port_deps_diff()`, `bslibreact::port_peek()`) it uses. A
brand new app can delete `PORT.md`.
