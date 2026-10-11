# Releasing

One version string lives in `pkg-js/package.json`, the root
`pyproject.toml`, and `pkg-r/DESCRIPTION`. One git tag, `v<version>`,
and the GitHub release made from it starts the npm and PyPI release
workflows; R reaches users through r-universe. See
`docs/decisions/0002-three-packages-one-version.md` for why.

## Before tagging

```
make update-dist
make bundles
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

Set the new version in every file `tools/check_versions.py` lists
(regenerate `uv.lock` with `uv lock` and `package-lock.json` with
`npm install` in place of editing them), then confirm they agree with
`make version-check`.

```
git add -A
git commit -m "chore: release 0.1.0"
git tag v0.1.0
git push --no-verify origin main v0.1.0
```

Pushing is the owner's own action; the repository's pre-push hook blocks
an accidental push otherwise. `--no-verify` here is intentional, not a way
around a failing check, since the checks already ran locally above.

## npm

`release-js.yml` publishes when a GitHub release is published. The very
first publish of a new package name cannot use trusted publishing, since
npm has no package to attach the trust relationship to yet, so that one
run reads a short-lived `NPM_TOKEN` repository secret (see the note at
the top of the workflow). After it succeeds, configure trusted
publishing on npmjs.com for this repository and `release-js.yml`, remove
the `NODE_AUTH_TOKEN` line from the workflow, and delete the secret.

## PyPI

Register a pending trusted publisher on pypi.org for the project
`bslib-react`, workflow `release-py.yml`, environment `pypi`, before the
project exists there; PyPI allows this. The GitHub release then publishes
through
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

Publishing it starts `release-js.yml` and `release-py.yml`. One release
covers all three packages; the body links each package's own changelog.
