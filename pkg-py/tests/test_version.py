"""The installed version agrees with pyproject.toml.

Agreement with pkg-js and pkg-r is checked by tools/check_versions.py and
pkg-r's test-version.R.
"""

from __future__ import annotations

import importlib.metadata
import re
from pathlib import Path

import bslibreact
from packaging.version import Version


def test_installed_version_matches_pyproject(repo_root: Path) -> None:
    text = (repo_root / "pyproject.toml").read_text(encoding="utf-8")
    project = text.split("[project]", 1)[1]
    match = re.search(r'^version\s*=\s*"([^"]+)"', project, re.MULTILINE)
    assert match is not None
    # Installed metadata is PEP 440 normalised ("0.2.0-rc.1" becomes
    # "0.2.0rc1"), so compare parsed versions, not strings.
    expected = Version(match.group(1))
    assert Version(importlib.metadata.version("bslibreact")) == expected
    assert Version(bslibreact.__version__) == expected
