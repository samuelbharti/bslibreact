"""The installed package version.

Read from installed package metadata, so it always matches what ``pip show``
reports. The fallback only applies to a source tree imported without being
installed at all; ``uv sync`` installs the project in editable mode, which
writes the metadata.
"""

from importlib.metadata import PackageNotFoundError, version

try:
    __version__ = version("bslibreact")
except PackageNotFoundError:
    __version__ = "0.0.0"

__all__ = ["__version__"]
