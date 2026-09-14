"""The installed version, and (once they exist) agreement with pkg-js and pkg-r."""

from __future__ import annotations

import importlib.metadata
import json
from pathlib import Path

import pytest

_EXPECTED_VERSION = "0.1.0"


def test_installed_version_matches_expected() -> None:
    assert importlib.metadata.version("bslib-react") == _EXPECTED_VERSION


def test_bslib_react_dunder_version_matches() -> None:
    import bslib_react

    assert bslib_react.__version__ == _EXPECTED_VERSION


def _pkg_js_version(repo_root: Path) -> str | None:
    package_json = repo_root / "pkg-js" / "package.json"
    if not package_json.is_file():
        return None
    return json.loads(package_json.read_text(encoding="utf-8"))["version"]


def _pkg_r_version(repo_root: Path) -> str | None:
    description = repo_root / "pkg-r" / "DESCRIPTION"
    if not description.is_file():
        return None
    for line in description.read_text(encoding="utf-8").splitlines():
        if line.startswith("Version:"):
            return line.split(":", 1)[1].strip()
    return None


def test_version_matches_pkg_js(repo_root: Path) -> None:
    js_version = _pkg_js_version(repo_root)
    if js_version is None:
        pytest.skip("pkg-js/package.json does not exist yet")
    assert js_version == _EXPECTED_VERSION


def test_version_matches_pkg_r(repo_root: Path) -> None:
    r_version = _pkg_r_version(repo_root)
    if r_version is None:
        pytest.skip("pkg-r/DESCRIPTION does not exist yet")
    assert r_version == _EXPECTED_VERSION
