"""The installed version agrees with pyproject.toml, pkg-js and pkg-r."""

from __future__ import annotations

import importlib.metadata
import json
import re
from pathlib import Path

import bslib_react


def _pyproject_version(repo_root: Path) -> str:
    text = (repo_root / "pyproject.toml").read_text(encoding="utf-8")
    match = re.search(r'^version\s*=\s*"([^"]+)"', text, re.MULTILINE)
    assert match is not None
    return match.group(1)


def test_installed_version_matches_pyproject(repo_root: Path) -> None:
    expected = _pyproject_version(repo_root)
    assert importlib.metadata.version("bslib-react") == expected
    assert bslib_react.__version__ == expected


def test_pkg_js_and_pkg_r_match_pyproject(repo_root: Path) -> None:
    expected = _pyproject_version(repo_root)
    package_json = repo_root / "pkg-js" / "package.json"
    assert json.loads(package_json.read_text(encoding="utf-8"))["version"] == expected
    description = (repo_root / "pkg-r" / "DESCRIPTION").read_text(encoding="utf-8")
    match = re.search(r"^Version:\s*(\S+)", description, re.MULTILINE)
    assert match is not None and match.group(1) == expected
