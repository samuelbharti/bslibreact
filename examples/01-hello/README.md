# Hello bslib-react

The smallest complete app built with
[bslib-react](https://github.com/samuelbharti/bslib-react): a themed
sidebar, one hosted slider, one hosted plot, and a value box reading the
slider's value back as plain text. The user interface is a React client
(`src/`, built to `www/ui.js`); `app.R` and `app.py` hold only reactive
computation.

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
