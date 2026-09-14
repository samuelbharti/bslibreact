"""``bslib_react_dep()``: the vendored JS/CSS bundle as an HTMLDependency.

Mirrors the same pattern ``posit-dev/shinyreact``'s own Python package uses
for its vendored bundle (``pkg-py/src/shinyreact/_dep.py`` in that repo):
the bundle in ``www/`` is vendored in by ``make update-dist`` from
``pkg-js/dist/bslib-react.js``, and the version string gets an mtime suffix
in a dev checkout so a rebuild still busts the browser cache even though the
release version hasn't changed.
"""

from __future__ import annotations

from pathlib import Path

from htmltools import HTMLDependency

_WWW_DIR = Path(__file__).parent / "www"

# bslib-react's own release version, i.e. the release of the bundle `www/`
# should contain. Bump alongside `pkg-js/package.json`; `test_dep.py` and
# `test_version.py` guard the three packages staying in step.
_BSLIB_REACT_JS_VERSION = "0.1.0"

# Only reachable from a repo checkout (this package installed editable from
# source), never from an installed wheel -- a wheel has no `pkg-js/` sibling
# at all. Its presence is the "dev checkout" signal `_bundle_version()` uses.
_JS_PACKAGE_JSON = Path(__file__).parents[3] / "pkg-js" / "package.json"


def _file_mtime_int(path: Path) -> int | None:
    """Return ``path``'s mtime in whole seconds, or ``None`` if it doesn't exist."""
    try:
        return int(path.stat().st_mtime)
    except FileNotFoundError:
        return None


def _bundle_version() -> str:
    """``_BSLIB_REACT_JS_VERSION``, suffixed with the bundle's mtime in a dev checkout.

    An installed package serves ``/lib/bslib-react-0.1.0/``. In a repo
    checkout it is ``/lib/bslib-react-0.1.0.<mtime>/`` instead, so
    ``make update-dist`` still cache-busts the browser while the URL still
    names the release.
    """
    if _JS_PACKAGE_JSON.is_file():
        mtime = _file_mtime_int(_WWW_DIR / "bslib-react.js")
        if mtime is not None:
            return f"{_BSLIB_REACT_JS_VERSION}.{mtime}"
    return _BSLIB_REACT_JS_VERSION


def bslib_react_dep() -> HTMLDependency:
    """The bslib-react JS (and CSS, if built) bundle as an HTMLDependency.

    The stylesheet is attached only when ``www/bslib-react.css`` actually
    exists -- the bundle may ship JS only -- so this never points a
    ``<link>`` at a file that isn't there. Likewise the JS file itself may be
    absent before the first ``make update-dist``; :func:`_bundle_version`
    handles that (falls back to the bare release string) rather than
    erroring, since importing ``bslib_react`` must work before the bundle
    has ever been built.
    """
    css = _WWW_DIR / "bslib-react.css"
    return HTMLDependency(
        name="bslib-react",
        version=_bundle_version(),
        source={"subdir": str(_WWW_DIR)},
        script={"src": "bslib-react.js", "defer": ""},
        stylesheet={"href": "bslib-react.css"} if css.exists() else None,
    )
