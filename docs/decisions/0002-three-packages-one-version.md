# 0002: three packages, one version, one tag

Date: 2026-09-13
Status: accepted

## Context

`posit-dev/shinyreact`, the package this kit sits on top of, ships three
independently versioned packages from one repository: `@posit-dev/shinyreact`
on npm, `shinyreact` on PyPI, and `shinyreact` on CRAN, each with its own
tag prefix (`js/v*`, `py/v*`, `r/v*`). That is the right choice for a
package whose three halves can genuinely change independently.

This kit is different. The R and Python packages exist mostly to vendor the
JS bundle and to give it dependencies to attach; they have no independent
release cadence of their own, and a user installing any one of the three
expects the same feature set as the other two.

## Decision

One version string, kept equal in `pkg-js/package.json`, the root
`pyproject.toml`, and `pkg-r/DESCRIPTION`. A test in each language asserts
the three agree. One git tag, `v0.1.0`, triggers all three release
workflows in one pipeline. Releasing means releasing all three, even when
only one changed; that is an accepted cost for the docs, the README, and
the mental model all naming one number.

The JS bundle's own version is pinned separately in two constants
(`pkg-r/R/dep.R`, `pkg-py/src/bslib_react/_dep.py`) but is bumped in
lockstep with the package version by `make version-bump`, since the
vendored bundle always matches the release it ships in.

## Consequences

An occasional release ships with no changes in one language. `make
version-bump V=0.2.0` is the one write path for a version change, and
`make version-check` fails CI if the three manifests ever disagree.
