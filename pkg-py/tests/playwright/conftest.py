"""Fixtures for the browser-driven tests under ``tests/playwright/``.

Excluded from the default ``pytest`` run (see ``addopts`` in the root
``pyproject.toml``); run explicitly with the ``tests-e2e`` dependency group
and a browser installed::

    uv run --group tests-e2e pytest pkg-py/tests/playwright --browser chromium
"""

from __future__ import annotations

from pathlib import Path

import pytest

_APPS_DIR = Path(__file__).parent / "apps"


@pytest.fixture
def hello_app_dir() -> Path:
    """The minimal real Shiny app ``test_peek.py`` points a browser at."""
    return _APPS_DIR / "hello"
