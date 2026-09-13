# Releasing

One version string lives in `pkg-js/package.json`, the root
`pyproject.toml`, and `pkg-r/DESCRIPTION`. One git tag, `v<version>`,
triggers all three release workflows. See
`docs/decisions/0002-three-packages-one-version.md` for why.

## Before tagging

```
make update-dist
make examples
git status --porcelain
```

Both commands' output must leave the working tree clean. Then:

```
make check
prek run --all-files
```

## Make the repository public

npm provenance and r-universe both expect a public repository. Do this
before tagging, once, before the first release:

```
gh repo edit samuelbharti/bslib-react --visibility public --accept-visibility-change-consequences
```

## Tag

```
make version-bump V=0.1.0
git add -A
git commit -m "chore: release 0.1.0"
git tag v0.1.0
git push --no-verify origin main v0.1.0
```

Pushing is the owner's own action; the repository's pre-push hook blocks
an accidental push otherwise. `--no-verify` here is intentional, not a way
around a failing check, since the checks already ran locally above.

## npm

The very first publish of a new package name cannot go through staged,
trusted publishing, since npm has no package to attach the trust
relationship to yet. Publish by hand once:

```
cd pkg-js
npm run build
npm pack --dry-run
npm publish --access public
```

`npm publish` will ask for two factor authentication. After this first
publish, configure trusted publishing on npmjs.com for the `release.yaml`
workflow with `npm stage publish` as the allowed action, and require two
factor approval on every subsequent stage. From the next release onward,
the tag stages the release and a human approves it.

## PyPI

Register a pending trusted publisher on pypi.org for the project
`bslib-react`, workflow `release.yaml`, environment `pypi`, before the
project exists there; PyPI allows this. The tag then publishes through
`pypa/gh-action-pypi-publish` with no token stored anywhere. If the
pending publisher is refused for any reason, fall back to a one time
manual publish with `uv build && uv publish` and a throwaway token,
deleted immediately after.

## R

Publish to r-universe first: create `samuelbharti/samuelbharti.r-universe.dev`
with a `packages.json` entry pointing at this repository's `pkg-r`
subdirectory. r-universe rebuilds from the default branch automatically.
Submit to CRAN later, once 0.1.x has settled, following the usual release
checklist from `pkg-r/`.

## GitHub release

```
gh release create v0.1.0 --generate-notes --title "bslib-react 0.1.0"
```

One release covers all three packages; the body links each package's own
changelog.
