"""Server helpers for bslib-react: React components reproducing bslib and Shiny markup.

``bslib_react.port`` (triage, deps_diff, peek) is a separate subpackage you
import explicitly -- keeping it out of this top-level import means
``import bslib_react`` never requires Playwright, which only ``peek()``
needs::

    from bslib_react.port import triage, deps_diff, peek
"""

from ._catalog import markup_catalog
from ._catalog_render import render_markup_catalog
from ._dep import bslib_react_dep
from ._deps import page_deps
from ._host import host_input
from ._scaffold import create_app
from ._version import __version__

__all__ = [
    "__version__",
    "bslib_react_dep",
    "create_app",
    "host_input",
    "markup_catalog",
    "page_deps",
    "render_markup_catalog",
]
