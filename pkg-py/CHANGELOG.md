# Changelog

## Unreleased

- The vendored bundle's `PageFillable` accepts a CSS length string for
  `padding` and `gap`, such as `"1rem"`. A number is still pixels.
- The vendored bundle's `PageFillable` no longer defaults `padding` and `gap`
  to 12px, matching `ui.page_fillable()`. A client with no build step that
  reads it from `window.bslibreact` gets the theme's own spacing unless it
  passes both.
- `page_deps()` no longer returns a theme stylesheet. py-shiny names it
  `shiny-theme-<name>`, so the `bootstrap` exclusion missed it, and a page
  with a `_brand.yml` theme loaded the stock stylesheet after its own, which
  overrode the brand colours and fonts. As in R, the page's own `theme=` is
  now the only source of the theme, so a page that passes no theme to
  `page_react()` gets no Bootstrap from `page_deps()`.

## 0.1.0

First release. Experimental: signatures may still change.

- Mirrors pkg-r's scope in Python: `page_deps()`, `host_input()`, and
  `bslibreact_dep()`, matching the R functions argument for argument.
- Ships the vendored `bslibreact.js` bundle inside the wheel.
