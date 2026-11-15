"""Shared fixtures for bslibreact's Python test suite."""

from __future__ import annotations

from pathlib import Path

import pytest

# pkg-py/tests/conftest.py -> pkg-py/tests -> pkg-py -> repo root.
REPO_ROOT = Path(__file__).parents[2]


@pytest.fixture
def repo_root() -> Path:
    """The repo root, for tests that check sibling packages (pkg-js, pkg-r)."""
    return REPO_ROOT
