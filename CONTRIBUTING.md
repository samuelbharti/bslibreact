# Contributing

I am the only one working on this repo right now. These notes are for me
and for an agent working alongside me, more than for outside contributors,
though outside contributions are welcome.

## Setup

```
npm install
uv sync --all-groups
Rscript -e "pak::local_install_dev_deps('pkg-r')"
prek install
```

## Branches and PRs

Branch off `main`. Name branches `feat/<name>`, `fix/<name>`,
`docs/<name>`, `chore/<name>`, or `ci/<name>`. PR titles follow
Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `ci:`, `test:`,
`refactor:`, `build:`. PRs are squash merged, and the squash message is
the PR title.

## Before opening a PR

```
prek run --all-files
make check
```

If the change touches the component kit or `page_deps()`, also run:

```
make update-dist
make examples
git status --porcelain
```

Both must come back empty. `www/ui.js` in each example is committed build
output; CI fails a PR that leaves it stale.

## Adding a component

There are no HTML fixtures to update. Instead:

1. Add a sample call with the same name to `pkg-r/R/catalog-samples.R` and
   `pkg-py/src/bslib_react/_catalog.py`.
2. Run `make markup`.
3. Read the rendered shape in `.cache/markup/r.json` (and the Python file).
4. Write the TSX component against that shape, and say in its doc comment
   which catalog sample it is pinned to.
5. Add a test in `pkg-js/tests/markup.test.tsx` that renders the component
   and compares its shape against the catalog sample.
6. Add a row to `docs/markup.md`.

See `docs/markup-catalog.md` for the full contract, and
`docs/decisions/0001-no-fixtures-live-ground-truth.md` for why this is the
design.

## Versions and changelogs

`pkg-js/package.json`, the root `pyproject.toml`, and `pkg-r/DESCRIPTION`
carry one shared version string; `make version-check` fails if they
disagree. Add a line under `## Unreleased` in `pkg-js/CHANGELOG.md`,
`pkg-py/CHANGELOG.md`, or `pkg-r/NEWS.md`, whichever package the PR
changes.

## Skills

`.claude/skills/bslib-react-port/` is this repo's own porting skill and is
committed on purpose; `make update-skills` copies it into `pkg-r/inst/skills/`
and `pkg-py/src/bslib_react/.agents/skills/` so an installed package ships
it too. Posit's own `shinyreact-build-app` and `shinyreact-convert-app`
skills come from the `shinyreact` package itself, not from here.

## Secrets

Never commit `.env`, `.Renviron`, or any key. A pre-commit hook blocks the
common file names; check a file's content before staging it if it might
hold one anyway.

## Writing

No em dashes, anywhere: not in code comments, not in commit messages, not
in docs. Plain, simple sentences.

## Release

See `docs/release.md`.
