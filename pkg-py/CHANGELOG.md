# Changelog

## Unreleased

- `page_deps()` no longer hands back the stock theme stylesheet when it is
  given a theme. A page with a `_brand.yml` theme loaded both stylesheets,
  and the stock one overrode the brand colours and fonts.

## 0.1.0

First release. Experimental: signatures may still change.

- Mirrors pkg-r's scope in Python: `page_deps()`, `host_input()`, and
  `bslibreact_dep()`, matching the R functions argument for argument.
- Ships the vendored `bslibreact.js` bundle inside the wheel.
