# bslib-react: needs, findings, gaps, and the plan

Date: 2026-09-13
Author: Samuel Bharti
Status: founding report. No code has moved into this repository yet.

Status update, 2026-09-13: sections 4.4, 5.3, 5.5 and 7.1 describe
committed fixtures and a dump script. The repository took a different
route instead: no fixtures are committed, and the markup catalog is
rendered live at test time into a gitignored cache. See
[docs/decisions/0001-no-fixtures-live-ground-truth.md](docs/decisions/0001-no-fixtures-live-ground-truth.md).
Section 5.1 names one npm package and one R package; a Python package
ships as well, and all three release on one shared version number. See
[docs/decisions/0002-three-packages-one-version.md](docs/decisions/0002-three-packages-one-version.md).

This report explains why this package exists, what measurements support
it, what is missing, and what gets built. It stands on its own. A reader
does not need `shinyreact-apps` open to follow it.

---

## 1. What this package is

bslib-react is a React component library that reproduces the markup of
bslib and shiny. It exists so that a React client can sit in front of a
Shiny server and still look like a bslib app, down to the class names.

It targets the ui.tsx pattern, which is the arrangement where the R or
Python server does reactive computation only, and a React client owns
the page. The shinyreact package provides that plumbing. bslib-react
provides the components that plumbing does not.

---

## 2. The need

### 2.1 The problem in one sentence

A person who ports a bslib Shiny app to the ui.tsx pattern must rebuild
bslib's layout in React by hand, and nothing exists to help them.

### 2.2 Who has this problem

Three groups have it:

1. Anyone who ports an existing bslib app and needs the port to look
   like the original.
2. Anyone who builds a new ui.tsx app and wants the bslib look, because
   the rest of their organization already uses it.
3. Anyone who has an app with a `_brand.yml` file and wants the brand
   colors to reach the client.

### 2.3 What they do today

They write the components themselves. There is no other option. The
measured cost of doing that is in section 3.

### 2.4 Why the existing answers do not fit

Three other approaches exist. None of them solves this.

shinyreact's own guidance tells a porter to use shadcn/ui with Tailwind
as the default component layer. That produces a good looking app that
does not look like the original. Its own convert skill says so plainly:
Bootstrap on the original and nothing on the port is expected, and every
Bootstrap class the original leaned on is unstyled until your components
supply it.

Appsilon ships `shiny.react` on CRAN with `shiny.fluent` and
`shiny.blueprint` on top. Those put React components inside Shiny's own
UI tree, declared from R. That is a different architecture, and the
components are Fluent UI and Blueprint, not bslib. A port built on them
looks like a Microsoft product.

Writing raw HTML with `dangerouslySetInnerHTML` works for one widget and
fails as a strategy. bslib decides some of its markup at render time
through `shiny::getCurrentTheme()`, so copying a static dump produces
markup that is wrong in a live session.

---

## 3. Findings

Every number here was measured on 2026-09-13 against a catalog of 20
ported apps in `samuelbharti/shinyreact-apps`.

### 3.1 The kit already exists and works

| Item | Measurement |
| --- | --- |
| Source files | 42 |
| Source lines | 1776 |
| Fixtures | 47 HTML files dumped from R |
| Public exports | 40 export lines |
| Apps in production use | 20 |
| Markup tests | 8, all passing |

Lines by area:

| Area | Lines | Files |
| --- | --- | --- |
| page | 314 | 4 |
| inputs | 265 | 18 |
| nav | 252 | 2 |
| outputs | 228 | 6 |
| layout | 220 | 2 |
| card | 174 | 2 |
| module, tooltip, misc | 64 | 3 |

### 3.2 The components are used, not decorative

Import counts across the 20 apps:

| Component | Uses |
| --- | --- |
| SliderInput | 26 |
| SelectInput | 22 |
| ActionButton | 20 |
| SelectizeInput | 19 |
| TextInput | 11 |
| RadioButtons | 11 |
| CheckboxInput | 10 |
| DownloadButton | 9 |

Two components have zero uses, which are `PasswordInput` and
`NativeInput`. Everything else earns its place.

### 3.3 Only part of the kit carries version risk

The kit has two tiers, and they fail differently.

Layout, page, nav, outputs and card components reproduce bslib markup.
That is 1188 lines. A bslib release can change a class name and break
them.

Input components reproduce no markup. All 18 of them are `HostedInput`,
which hosts an `output$<id>_ui <- renderUI({ ... })` defined in R. The
HTML arrives from R at runtime. That is 265 lines, and a bslib release
cannot break them.

This matters for the promise the package makes. The surface that needs
version testing is smaller than the package.

### 3.4 Port cost does not track app size

Client lines written per port, against the size of the original app:

| Original app | Original lines | Client lines |
| --- | --- | --- |
| genescout | 21,700 | 192 |
| tahoe-explorer | 12,500 | 913 |
| variant-reviewer | 8,700 | 592 |
| de-explorer | 1,400 | 604 |

The largest original produced the smallest client. What varies is how
much of the page gets hosted whole through `renderUI()` rather than
rebuilt control by control.

### 3.5 No port used React state

This is the strongest finding and it shaped the design.

| App | useState | useShinyInput | useShinyOutputValue | hosted outputs |
| --- | --- | --- | --- | --- |
| genescout | 0 | 0 | 0 | 12 |
| tahoe-explorer | 0 | 0 | 0 | 53 |
| variant-reviewer | 0 | 0 | 5 | 23 |
| de-explorer | 0 | 0 | 2 | 8 |
| recount-explorer | 0 | 0 | 2 | 13 |

Across five apps, no component holds React state and no component owns a
Shiny input. The client is a layout shell around hosted Shiny widgets.

The design follows from this. bslib-react must be excellent at layout
and hosting. It does not need to be a state management library.

### 3.6 The name is free

The npm registry returns 404 for `bslib-react`, `@posit-dev/bslib-react`,
`@posit/bslib-react` and `react-bslib`. A GitHub code search for the
string `bslib-react` returns hits in one repository, which is
`samuelbharti/shinyreact-apps`. bslib ships a `srcts/` TypeScript
directory and no React bindings.

---

## 4. Gaps

### 4.1 Nobody can use this today

The package is marked private, lives inside a monorepo, is imported as
`@apps/bslib-react`, and points its entry at raw TypeScript. A person
outside that repository cannot install it. This is the whole reason for
this repository.

### 4.2 One real defect ships in every navbar app

`NavbarTabStrip.tsx` at lines 112 and 113, and `Sidebar.tsx` at lines
102 and 103, call `Shiny.initializeInputs()` and `Shiny.bindAll()` on
their own element. That element holds hosted outputs. Shiny registers
those outputs a second time and writes a duplicate output ID warning to
the browser console.

A run of the peek tool against the de-explorer app on 2026-09-13 found
the id `demo_ui` bound twice, repeated across 41 console messages.

shinyreact cannot fix this from its side. Its deduplicating bind
function is private to one module, and the `window.shinyreact` global
exposes hooks plus three components only. A component author with a real
reason to bind a scope cannot join the deduplication.

The fix belongs here, and this repository will carry it.

### 4.3 There is no R half

`port_page_deps()` collects the htmlDependency objects that bslib and
shiny attach to the widgets a client renders. Without it, a themed app
loads no widget CSS and the page looks unstyled.

Today every app copies that function by hand into `R/shinyreact-deps.R`.
Six of nine ported apps carry a copy. That is the same file written nine
times.

### 4.4 Markup drift has no owner

The 47 fixtures come from `dump-markup.R`, which needs R with bslib and
shiny installed. They were dumped against bslib 0.12.0 and shiny 1.14.0.
Nothing runs that script on a schedule. A bslib release can change a
class name today and nobody finds out until a screenshot looks wrong.

This already happened once. The navbar active tab drifted from
`<li class="nav-item"><a class="nav-link active">` to
`<li class="active"><a>`, shipped in four apps, and a screenshot
comparison caught it rather than a test.

### 4.5 Upstream has no runnable hosting example

shinyreact documents the hosted widget recipe in
`references/shiny-outputs.md`. Every one of its 11 example apps was
checked on 2026-09-13. No example server hosts a real Shiny input widget
through `renderUI()` or `@render.ui`.

This is not this repository's gap to fill, but it explains why the
recipe is hard to find and easy to get wrong. It is tracked in section
7.3.

---

## 5. The solution

### 5.1 Shape

Ship one npm package and one R package from one repository. The npm
package carries the components. The R package carries `port_page_deps()`
and the helpers that pair with it. They release together and their
version numbers match.

### 5.2 Decisions taken

| Decision | Choice | Reason |
| --- | --- | --- |
| npm name | `bslib-react`, unscoped | The name is free |
| License | MIT | Matches the source repository |
| R half | Ship `pkg-r/` from version 0.1.0 | Removes a file copied nine times |
| Build output | ESM plus `.d.ts`, source also published | Raw TypeScript only works for Vite users |
| shinyreact link | Read `window.shinyreact`, declare a peer dependency | The global already works and the npm package now exists |
| The bind defect | Fix before the first release | It writes a warning in every navbar app |

### 5.3 Layout

```
bslib-react/
  LICENSE                   MIT, Samuel Bharti
  README.md                 install, one worked example, supported versions
  REPORT.md                 this file
  MARKUP.md                 the R call to TSX map
  package.json              name bslib-react, exports map, peer deps
  tsconfig.json
  vitest.config.ts          jsdom
  src/                      the 42 component files
  fixtures/                 the 47 dumped HTML files
  tests/
    fixture.ts              loadFixture, shapeOf, fixtureShape
    markup.test.tsx         the markup tests
  tools/
    dump-markup.R           regenerates fixtures from R
  pkg-r/
    DESCRIPTION
    NAMESPACE
    R/deps.R                port_page_deps()
    man/
  examples/
    volcano-plot/           one runnable app, R server plus TSX client
  .github/workflows/
    ci.yaml                 typecheck, test, build
    fixtures.yaml           scheduled, regenerate and diff
```

### 5.4 Supported versions

State these in the README and test them:

1. bslib 0.12.0 or later, because the fixtures were dumped against it.
2. shiny 1.14.0 or later, for the same reason.
3. react 19.0.0 or later, as a peer dependency.
4. @posit-dev/shinyreact 0.1.0 or later, as a peer dependency.

### 5.5 The drift guard

The scheduled workflow installs R with current bslib and shiny, runs
`dump-markup.R`, and fails when the output differs from the committed
fixtures. A failure is not a bug. It is the signal to look at what bslib
changed and cut a new minor version.

Run it weekly, not on every pull request. Installing R is slow and bslib
does not release often.

---

## 6. Risks

Three risks are worth stating before work starts.

bslib markup drift is the main one. The guard in section 5.5 reduces it
and does not remove it, because a drift that no fixture covers stays
invisible.

Scope creep is the second. This package mirrors bslib. Requests to add
components that bslib does not have will arrive. Write the answer into
the README before the first user asks.

Maintaining two release processes is the third. Shipping `pkg-r/` means
CRAN or r-universe as well as npm. That is the cost of closing gap 4.3
and it was accepted deliberately.

---

## 7. Plan

### 7.1 Before the first release

1. Copy `src/`, `fixtures/`, `tests/` and `MARKUP.md` from
   `shinyreact-apps/packages/bslib-react/` unchanged.
2. Copy `tools/kit/dump-markup.R` and correct the output path inside it.
3. Write `package.json` with the name `bslib-react`, an exports map, and
   the peer dependencies from section 5.4.
4. Add a build that emits ESM and type declarations.
5. Write a failing test for the duplicate bind defect in section 4.2.
6. Fix the defect by narrowing the bind scope so that it excludes hosted
   outputs. Make sure that the test passes afterward.
7. Write `pkg-r/` with `port_page_deps()` and its documentation.
8. Write the README with install, one worked example, and the supported
   versions.
9. Copy the volcano-plot app into `examples/`.
10. Add both CI workflows.

### 7.2 Migration of shinyreact-apps

Do this after version 0.1.0 is published, not before.

1. In one app, replace `"@apps/bslib-react": "*"` with
   `"bslib-react": "^0.1.0"`.
2. Change the import path from `@apps/bslib-react` to `bslib-react`
   across that app's `src/`.
3. Run typecheck, build and the test suite. Make sure that the committed
   `www/ui.js` still matches.
4. Repeat for the other 19 apps.
5. Delete `packages/bslib-react/` and its workspace entry.

### 7.3 Separate work, tracked but not part of this repository

Two items belong elsewhere and are recorded here so they do not get
lost.

Ask posit-dev/shinyreact to expose its deduplicating bind function. The
fix in section 4.2 works around a limit that affects every component
author, not only this package.

Offer posit-dev/shinyreact a runnable hosted widget example, numbered
`12-hosted-widgets`, that uses no component library at all. This closes
gap 4.5 and needs nothing from this repository.

---

## 8. What this report does not recommend

This report does not recommend adopting `shiny.react`, `shiny.fluent` or
`shiny.blueprint` from Appsilon. Those packages declare React components
from R inside Shiny's own UI tree. That is a different architecture, the
components are not bslib, and `shiny.react` has had no commit since
2024-05-20.

This report does not recommend dropping the goal of matching the
original app. Matching by construction is testable with a script.
Equivalence is not, and it moves the work from an automated check to a
person looking at two screens.
