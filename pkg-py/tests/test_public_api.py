"""The top-level public API is exactly what's documented, no more, no less."""

import subprocess
import sys

import bslib_react

_EXPECTED = [
    "__version__",
    "bslib_react_dep",
    "create_app",
    "host_input",
    "markup_catalog",
    "page_deps",
    "render_markup_catalog",
]


def test_dunder_all_matches_documented_api() -> None:
    assert sorted(bslib_react.__all__) == sorted(_EXPECTED)


def test_every_exported_name_is_actually_importable() -> None:
    for name in bslib_react.__all__:
        assert hasattr(bslib_react, name), (
            f"bslib_react.__all__ names {name!r}, but it isn't defined"
        )


def test_top_level_import_never_pulls_in_playwright() -> None:
    """``import bslib_react`` must not require Playwright.

    Runs in a fresh interpreter rather than checking ``sys.modules`` in this
    process, because other test modules in the same pytest run legitimately
    import ``bslib_react.port`` (which does import Playwright, lazily,
    inside ``peek()``) -- checking process-global state here would pass or
    fail depending on test collection order, not on what this import
    actually does.
    """
    result = subprocess.run(
        [
            sys.executable,
            "-c",
            "import bslib_react, sys; assert 'playwright' not in sys.modules",
        ],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
