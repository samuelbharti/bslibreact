# 0004: pkg-r and pkg-py ship three functions, nothing else

Date: 2026-09-13
Status: accepted

## Context

An earlier draft of this repository shipped much more from `pkg-r` and
`pkg-py` than page dependency discovery and hosted inputs: an exported
markup catalog and catalog renderer, port-checking tools (`triage`,
`deps_diff`, a headless-browser `peek`), and an app scaffold
(`create_app()`). A one-call page helper (`bslib_react_page()`) was also
briefly added on top, wrapping shinyreact's own `page_react()`, with
`shinyreact` promoted from Suggests to a hard Imports dependency to
support it.

None of that matched what this package needs to be. bslib-react exists to
supplement shinyreact, not to compete with it or to become a second thing
to maintain at the same scale: a component kit plus its own port-checking
CLI, browser automation, and scaffolding is a much bigger maintenance
surface than "the CSS and JS a bslib page would have attached, plus a
hosted-widget helper." The port tools in particular pulled in `callr`,
`chromote`, `curl`, `httpuv`, `processx`, `xml2`, `DT`, `reactable`,
`htmlwidgets`, and `shinycssloaders` as transitive dependencies of an
installed package, for functionality used once per port, not at app
runtime, and one of those tools (the chromote-backed browser check) was
independently flaky under `R CMD check`'s isolated environment.

## Decision

`pkg-r` and `pkg-py` each ship exactly three functions at runtime:
`page_deps()`, `host_input()`, and `bslib_react_dep()`. `shinyreact` stays
a `Suggests`/documentation-only relationship, never a hard dependency: an
app assembles its own page with `page_react(page_deps(theme),
bslib_react_dep(), ...)`, the same three-call pattern shinyreact's own
docs already teach for attaching a dependency. There is no
`bslib_react_page()` wrapper.

Everything else moves out of the shipped packages:

- The markup catalog *renderer* (third party "extra" samples for
  DT/reactable/htmlwidgets/shinycssloaders included) becomes a dev-only
  concern. `tools/markup/render-r.R` is fully self-contained, reaching
  into `pkg-r`'s unexported internals, not an exported package function,
  and `tools/markup/render_py.py` does the same for
  `pkg-py`. (Until 2026-10-11 the Python renderer and a background-app
  runner for page samples still shipped inside `pkg-py`; both renderers
  now render page samples with a plain tag render, so neither needs one.)
  The sample list itself (`catalog-samples.R`, `_catalog.py`) still ships
  inside both packages, unexported, since `page_deps()` needs it.
- Port-checking (triage, a dependency diff, a headless-browser peek)
  is not a package feature. `docs/porting.md` and
  `.claude/skills/bslib-react-port/SKILL.md` describe the same checks as
  a manual, side by side comparison against a running parent app instead:
  browser devtools for the dependency and console checks, a plain
  screenshot by eye for the visual one. This is a check run once per
  port, not a runtime or CI dependency worth carrying permanently.
- App scaffolding is gone. `docs/build.md` points at copying
  `examples/01-hello` instead of a `create_app()` call.

## Consequences

Porting and building a new app take one more manual step each
(comparing two browser tabs by hand instead of calling a function that
does it), in exchange for pkg-r's and pkg-py's own dependency trees
staying close to what bslib and shiny already require. An app that
depends on bslib-react never pulls in browser automation. Someone who
wants the cut tools can still find their logic in this repository's git
history (the commits before this decision).
