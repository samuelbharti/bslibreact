# Changelog

## 0.1.0

- First release. Mirrors pkg-r's scope in Python.
- `page_deps()`, `host_input()`, `bslib_react_dep()`.
- `markup_catalog()` and `render_markup_catalog()`, the live catalog renderer
  that implements `docs/markup-catalog.md`'s schema for Python.
- `bslib_react.port`: `triage()`, `deps_diff()`, `peek()`, ported from
  `tools/port/*.R`. `peek()` needs the `peek` extra (Playwright).
- `create_app()` and a starter template for a new bslib-react app.
- A `bslib-react` console script wrapping all of the above.
