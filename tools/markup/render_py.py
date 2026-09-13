#!/usr/bin/env python3
"""Render the Python half of the markup catalog contract in
docs/markup-catalog.md. Run from the repository root:

    uv run python tools/markup/render_py.py --key
    uv run python tools/markup/render_py.py --out .cache/markup/py.json

--key prints a cache key and exits 0, rendering nothing: pkg-js's vitest
global setup calls this on every test run and only re-renders when the
key differs from the cached file's own key. --out <path> renders the full
catalog to that path and exits 0, or exits non-zero with a message on
stderr if rendering fails.

Unlike the R side (tools/markup/render-r.R), this is a thin wrapper:
render_markup_catalog() and markup_catalog_key() live inside bslib_react
itself (bslib_react._catalog_render), unexported from the package's public
API. Python's packaging has no equivalent to R's Suggests-must-be-used
strictness, and this catalog has no "extra" third-party-widget samples to
begin with (see bslib_react._catalog's module docstring), so there is no
dependency-weight reason to duplicate the rendering logic here the way the
R script has to.
"""

from __future__ import annotations

import sys

from bslib_react._catalog_render import markup_catalog_key, render_markup_catalog


def main(argv: list[str]) -> int:
    if "--key" in argv:
        print(markup_catalog_key())
        return 0

    if "--out" in argv:
        idx = argv.index("--out")
        if idx + 1 >= len(argv):
            print("usage: render_py.py --out <path>", file=sys.stderr)
            return 1
        out_path = argv[idx + 1]
        try:
            render_markup_catalog(path=out_path)
        except Exception as exc:
            print(f"render_markup_catalog() failed: {exc}", file=sys.stderr)
            return 1
        return 0

    print(
        "usage: render_py.py --key\n       render_py.py --out <path>", file=sys.stderr
    )
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
