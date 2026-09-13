"""Port-checking tools: triage a parent app, diff its deps against a port, peek at both.

Deliberately not imported by ``bslib_react``'s top-level ``__init__.py``:
``peek()`` needs Playwright, and importing this subpackage should not force
that dependency on an app that only wants ``page_deps()`` or ``host_input()``.
Import what you need directly::

    from bslib_react.port import triage, deps_diff, peek
"""

from ._app import AppHandle, attach_app, start_app
from ._deps_diff import DepsDiff, deps_diff
from ._peek import PeekReport, peek
from ._triage import TriageReport, triage

__all__ = [
    "AppHandle",
    "DepsDiff",
    "PeekReport",
    "TriageReport",
    "attach_app",
    "deps_diff",
    "peek",
    "start_app",
    "triage",
]
