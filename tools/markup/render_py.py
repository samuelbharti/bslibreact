#!/usr/bin/env python3
"""Render the Python half of the markup catalog in docs/markup-catalog.md.

Run from the repository root:

    uv run python tools/markup/render_py.py --key
    uv run python tools/markup/render_py.py --out .cache/markup/py.json

--key prints a cache key and exits 0, rendering nothing: pkg-js's vitest
global setup calls this on every test run and only re-renders when the key
differs from the cached file's own key. --out <path> renders the full
catalog to that path and exits 0, or exits non-zero with a message on stderr
if rendering fails.

A dev-only script, like tools/markup/render-r.R: the sample list itself
(bslib_react._catalog) ships in the package because page_deps() needs it,
but rendering it to JSON is only ever done here.
"""

from __future__ import annotations

import importlib.metadata
import json
import platform
import re
import sys
import warnings
from datetime import datetime, timezone
from pathlib import Path

from bslib_react import __version__
from bslib_react._catalog import SAMPLES, Sample, catalog_eval, catalog_hash
from htmltools import TagList

# Bump when the render logic changes, so every cached catalog re-renders.
RENDERER_VERSION = 2

_STYLE = re.compile(r"<style[^>]*>(.*?)</style>", re.DOTALL)


def _pkg_version(name: str) -> str:
    return importlib.metadata.version(name)


def _bslib_vendored_version() -> str:
    """The bslib release py-shiny vendors, from its private ``_versions`` module.

    There is no public way to ask py-shiny which bslib it ships, so a move or
    rename of ``shiny._versions.bslib`` records "unknown" with a warning
    instead of failing the whole render over a version string meant for
    people reading the file.
    """
    try:
        from shiny import _versions

        return str(getattr(_versions, "bslib"))  # noqa: B009
    except Exception as exc:  # pragma: no cover - depends on shiny internals
        warnings.warn(
            f"could not read shiny._versions.bslib ({exc!r}); recording 'unknown'",
            stacklevel=2,
        )
        return "unknown"


def markup_catalog_key() -> str:
    """Changes with shiny, htmltools, vendored bslib, the samples, or this script."""
    return (
        f"py;shiny={_pkg_version('shiny')};htmltools={_pkg_version('htmltools')};"
        f"bslib_vendored={_bslib_vendored_version()};catalog={catalog_hash()};"
        f"renderer={RENDERER_VERSION}"
    )


def _render_sample(sample: Sample) -> dict:
    """``htmltools.TagList(tag).render()``, for tag and page samples alike."""
    rendered = TagList(catalog_eval([sample.name])[0]).render()
    deps = rendered["dependencies"]
    # A page's own <head> content (page_fillable()'s html { height: 100% },
    # say) reaches htmltools as a dependency's head, not as markup.
    head_css = [
        css.strip()
        for dep in deps
        if getattr(dep, "head", None)
        for css in _STYLE.findall(str(dep.head))
    ]
    return {
        "kind": sample.kind,
        "group": sample.group,
        "call": sample.call,
        "html": rendered["html"],
        "head_inline_css": head_css,
        # Sorted with no duplicates, as docs/markup-catalog.md requires.
        "deps": sorted({f"{dep.name}@{dep.version}" for dep in deps}),
        "skipped": None,
    }


def render_markup_catalog(path: Path) -> None:
    record = {
        "schema": 2,
        "language": "py",
        "key": markup_catalog_key(),
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "generator": {"package": "bslib-react", "version": __version__},
        "versions": {
            "shiny": _pkg_version("shiny"),
            "htmltools": _pkg_version("htmltools"),
            "bslib_vendored": _bslib_vendored_version(),
            "runtime": f"Python {platform.python_version()}",
        },
        "samples": {sample.name: _render_sample(sample) for sample in SAMPLES},
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(record, indent=2, default=str), encoding="utf-8")


def main(argv: list[str]) -> int:
    if "--key" in argv:
        print(markup_catalog_key())
        return 0

    if "--out" in argv:
        idx = argv.index("--out")
        if idx + 1 >= len(argv):
            print("usage: render_py.py --out <path>", file=sys.stderr)
            return 1
        try:
            render_markup_catalog(Path(argv[idx + 1]))
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
