"""Server helpers for bslib-react: React components reproducing bslib and Shiny markup.

Provides page dependency discovery so a client bundle can request the same
CSS and JavaScript a bslib page would attach on its own, and a hosted-input
helper for widgets rendered server-side and displayed by the client. The
matching React components live in the ``bslib-react`` npm package.
"""

from ._dep import bslib_react_dep
from ._deps import page_deps
from ._host import host_input
from ._version import __version__

__all__ = [
    "__version__",
    "bslib_react_dep",
    "host_input",
    "page_deps",
]
