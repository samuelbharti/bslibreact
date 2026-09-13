# 0001: no committed fixtures, bslib is the live ground truth

Date: 2026-09-13
Status: accepted

## Context

An earlier version of this kit, living inside `samuelbharti/shinyreact-apps`,
pinned its markup against 47 HTML files dumped from R by a script,
`tools/kit/dump-markup.R`. That approach had three real failures:

1. A fixture dumped outside a running Shiny session silently took bslib's
   Bootstrap 3 code path, because `buildNavItem()` branches on
   `shiny::getCurrentThemeVersion()`, which reads the Shiny option
   `bootstrapTheme`, not `bslib::bs_global_set()`. The navbar fixture
   claimed the active tab was `<li class="active"><a>`; a live app served
   `<li class="nav-item"><a class="nav-link active">`. That wrong fixture
   shipped in four apps before a screenshot diff caught it, not a test.
2. bslib mints element ids fresh on every render (`bslib-card-1234`,
   `data-tabsetid`, and so on) from Shiny's own private RNG, which cannot
   be seeded. Every regeneration rewrote about a third of the fixtures with
   no real change, and a real change was easy to miss in the noise.
3. Nothing ran the dump script on a schedule, so a bslib release could
   change a class name and nobody would know until a screenshot looked
   wrong. Reading bslib's own NEWS.md shows one breaking markup change
   roughly every two minor releases: the navbar markup changed in 0.9.0,
   the card header and sidebar markup changed in 0.10.0.

## Decision

Do not commit any HTML. Each of `pkg-r` and `pkg-py` owns a catalog of
sample calls, the same set of components a real app renders. A renderer
function in each package produces the catalog's markup live, from
whichever bslib, shiny, htmltools, and py-shiny are actually installed,
into a JSON file under `.cache/markup/`, which is gitignored. The pkg-js
test suite reads that JSON and compares rendered React output against it.

The renderer sets `shiny::shinyOptions(bootstrapTheme = bslib::bs_theme(version = 5))`
before rendering, which is the fix for failure 1. Volatile ids are
normalised by the JS reader before comparison, which is the fix for
failure 2. The renderer runs on every pull request against the pinned
versions in `markup-versions.json`, and weekly against the newest bslib,
shiny, and py-shiny, which is the fix for failure 3: a red weekly run is
the signal that bslib changed something, not a bug in this repository.

## Consequences

The JS test suite needs R installed to run its full suite, and Python
installed to check the Python side. A fresh clone runs `make markup`
before `vitest`. The version floor named in the README is the version the
catalog is tested against, not a guess. A markup test failure after a
bslib upgrade is expected and is the trigger to read the diff and cut a
new minor version of this package, not to "fix" the test.
