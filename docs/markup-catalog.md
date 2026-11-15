# The markup catalog spec

This file specifies what the R and Python catalog renderers must produce,
and what `pkg-js`'s test suite reads. All three packages code against this
file; changing the spec means updating all three.

Neither renderer ships inside the installed R or Python package: rendering
the catalog needs things (third party widget packages for the R side's
"extra" samples) that no app using `page_deps()`/`host_input()`/
`bslibreact_dep()` at runtime ever needs. Both live in `tools/markup/`:
`render-r.R` reaches into `pkg-r`'s unexported internals for the "tag" and
"page" samples and defines the "extra" samples itself, and `render_py.py`
reads `bslibreact._catalog`. The sample lists stay in the packages because
`page_deps()` needs them.

See [0001-no-fixtures-live-ground-truth](decisions/0001-no-fixtures-live-ground-truth.md)
for why this exists instead of committed HTML fixtures.

## Commands

Run from the repository root:

```
Rscript tools/markup/render-r.R --key
Rscript tools/markup/render-r.R --out .cache/markup/r.json

uv run python tools/markup/render_py.py --key
uv run python tools/markup/render_py.py --out .cache/markup/py.json
```

`--key` prints one line and renders nothing. The key changes when bslib,
shiny, htmltools, or py-shiny versions change, when a sample's name, kind,
group or call changes, when an R "extra" sample's package is installed,
removed or upgraded, or when the renderer's own logic version is bumped. The R
script always loads `pkg-r` from the checkout with `pkgload::load_all()`,
never an installed copy, so `pkgload` must be installed.

pkg-js's `tests/global-setup.ts` calls `--key` on every test run, compares
it against the cached file, and only re-renders when it differs.

## JSON shape (schema 2)

```jsonc
{
  "schema": 2,
  "language": "r",                       // "r" | "py"
  "key": "r;bslib=0.12.0;shiny=1.14.0;htmltools=0.5.9;catalog=<hash>;renderer=2",
  "generated_at": "2026-09-13T12:00:00Z",
  "generator": { "package": "bslibreact", "version": "0.1.0" },
  "versions": {
    "bslib": "0.12.0",
    "shiny": "1.14.0",
    "htmltools": "0.5.9",
    "runtime": "R 4.6.1"
  },
  "samples": {
    "card_full_screen": {
      "kind": "tag",                     // "tag" | "page" | "extra"
      "group": "card",                   // page nav layout card tooltip output input misc
      "call": "bslib::card(full_screen = TRUE, bslib::card_header(\"Title\"), bslib::card_body(\"Body\"))",
      "html": "<div class=\"card bslib-card ...\">...</div>",
      "head_inline_css": [],             // <style> blocks the sample puts in <head>
      "deps": ["bslib-component-js@0.12.0", "bootstrap@5.3.3"],
      "skipped": null                    // extras only: a reason string when the package is missing
    }
  }
}
```

Python's file differs only in `language` (`"py"`), `generator.package`
(`"bslibreact"`), `versions` (Python adds `bslib_vendored`, the bslib
version py-shiny bundles, read from `shiny._versions`), `call` in Python
syntax, and a page sample's `html`, which is the whole `<html>` document
py-shiny's page functions return, not just `<body>`.

`html` is raw. Neither renderer normalises anything; the cache stays a
faithful record of what bslib or py-shiny actually emitted, which is what
you want to read when a drift test fails. Normalisation happens once, in
the JS reader (`pkg-js/tests/catalog.ts`), described below.

## Render rules

**`kind: "tag"` and `kind: "page"`.** R: `htmltools::renderTags(tag)`
called while `shiny::shinyOptions(bootstrapTheme = bslib::bs_theme(version = 5))`
is set, restored afterward. This is not optional: several bslib render
hooks, most importantly the nav item and dropdown builders, branch on
`shiny::getCurrentThemeVersion()`, which reads that Shiny option, not
`bslib::bs_global_set()`. Rendering outside this wrap silently produces
Bootstrap 3 markup; inside it, the markup matches what a running app
serves. Python: `htmltools.TagList(tag).render()`, no equivalent wrap
needed since py-shiny has no such branch. A page sample's `html` includes
its `<body>` tag, so page-shell components (`PageFillable`, `PageSidebar`,
`PageNavbar`), which set `<body>`'s own classes and inline style, are
checked against it; its `<head>` `<style>` blocks (bslib's
`html { height: 100% }`) go in `head_inline_css`.

**`kind: "extra"`.** Third party widgets: `DT::DTOutput()`,
`reactable::reactableOutput()`, `shinycssloaders::withSpinner()`,
`htmlwidgets::shinyWidgetOutput()`. Skipped with a `skipped` reason when
the package is absent, instead of failing the whole render. Never
included by default in `page_deps()`'s sampler; an app passes them
explicitly as extra tags. R only: `pkg-r`'s own shipped catalog
(`R/catalog-samples.R`) defines no `"extra"` samples, since none of these
four packages is a dependency an installed app should ever need; the five
`"extra"` samples exist only in `tools/markup/render-r.R`'s own list.
Python has no `"extra"` samples at all (see `_catalog.py`'s module
docstring for why py-shiny has no equivalent for any of them).

## Sample names

Every sample name from the earlier `tools/kit/dump-markup.R` is kept,
except `igvShinyOutput`, which becomes `htmlwidget_output`
(`htmlwidgets::shinyWidgetOutput("x", "foo", "100%", "400px")`, the same
generic markup shape, with no Bioconductor package needed to render it).
`page_navbar_dropdown` is rendered from
`bslib::page_navbar(id = "nav", bslib::nav_menu(...))`, replacing the
earlier fixture that was hand corrected because a plain `as.character()`
dump could not represent it faithfully; the live render needs no such
correction.

Names added for coverage this kit did not have before: `page_navbar_not_fillable`,
`sidebar_layout_gap_padding`, `layout_columns_single_child`, `card_id`,
`card_height`, `card_no_fill`, `tooltip`, `popover`, `value_box`,
`uiOutput_inline`, `input_dark_mode`, `input_switch`, `input_task_button`,
`accordion`, `navset_card_tab`, `navset_pill`, `checkboxGroupInput`,
`dateInput`, `dateRangeInput`, `icon`, `page_fillable_default`.

Each package's tests hold a literal list of its names (pkg-r's and
pkg-py's catalog tests, and pkg-js's `catalog-spec.test.ts` for the names
both catalogs share), and that test also checks the two catalogs hold
the same names, R-only samples aside. Renaming or dropping a sample is a
deliberate edit, not something that happens by accident.

## Id normalisation

bslib mints several kinds of id at render time, from Shiny's own private
random number generator, which cannot be seeded (`set.seed()` has no
effect on it). py-shiny mints its own, in a different format. Neither
renderer normalises these; the JS reader does, applying these patterns to
the `html` string before parsing it:

```
bslib[-_](card|sidebar|accordion[-_]panel|accordion)[-_][0-9a-f]+   ->  bslib-<kind>-ID
navbar[-_]collapse[-_][0-9a-f]+                                     ->  navbar-collapse-ID
data-tabsetid="[0-9a-f]+"                                           ->  data-tabsetid="ID"
tab-[0-9a-f]+-(\d+)                                                 ->  tab-ID-$1
```

On top of that, the reader's `shapeOf()` helper drops a fixed set of
volatile attributes (`id`, `for`, `href`, `data-target`, `data-bs-target`,
`aria-controls`, `aria-labelledby`, `data-tabsetid`), treats
`bsOptions="[]"` and `bsOptions="{}"` as equal (R emits the former for "no
options", the TS default and py-shiny both use the latter), and compares
inline `style` as a sorted list of declarations instead of a literal
string, so declaration order and whitespace differences do not fail a
test.
