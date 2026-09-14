"""The installed package version.

Read from installed package metadata so it always matches what ``pip show``
or ``uv pip show`` reports. The literal fallback only matters when this
package is imported straight from a source checkout without being installed
at all (no ``.dist-info``) -- ``uv sync`` installs the project in editable
mode, which does write that metadata, so the fallback is a defensive nicety
rather than something day-to-day development depends on.
"""

from importlib.metadata import PackageNotFoundError, version

try:
    __version__ = version("bslib-react")
except PackageNotFoundError:
    __version__ = "0.1.0"

__all__ = ["__version__"]
