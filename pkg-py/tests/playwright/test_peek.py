"""``bslib_react.port.peek()``: look at a running app in headless Chromium.

Needs Playwright and a browser (``playwright install chromium``), so this
whole directory is excluded from the default ``pytest`` run -- see
``addopts`` in the root ``pyproject.toml``. Run explicitly::

    uv run --group tests-e2e pytest pkg-py/tests/playwright --browser chromium
"""

from __future__ import annotations

from pathlib import Path

from bslib_react.port import peek


def test_peek_connects_and_saves_a_screenshot(
    hello_app_dir: Path, tmp_path: Path
) -> None:
    report = peek(hello_app_dir, select=["#heading"], out=tmp_path, wait=20)

    assert report.port.info["shiny"] is True
    assert report.port.info["connected"] is True
    assert report.port.info["boundInputs"] >= 1
    assert report.port.info["boundOutputs"] >= 1
    assert report.port.screenshot.is_file()
    assert report.port.screenshot.parent == tmp_path

    picked = report.port.info["picked"][0]
    assert picked["sel"] == "#heading"
    assert picked.get("missing") is not True
    assert picked["text"] == "Hello"


def test_peek_reports_a_missing_selector() -> None:
    report = peek(
        Path(__file__).parent / "apps" / "hello", select=["#does-not-exist"], wait=20
    )
    picked = report.port.info["picked"][0]
    assert picked.get("missing") is True


def test_peek_str_report_reads_sensibly(hello_app_dir: Path) -> None:
    report = peek(hello_app_dir, wait=20)
    text = str(report)
    assert "port:" in text
    assert "connected" in text


def test_peek_against_a_parent_reports_no_unexpected_diff(hello_app_dir: Path) -> None:
    # The same app as both "port" and "parent": the two readouts should be
    # identical except for cosmetic details (which the diff logic already
    # excludes -- e.g. two apps never share a URL, so nothing there differs).
    report = peek(hello_app_dir, parent=hello_app_dir, wait=20)
    assert report.parent is not None
    assert report.parent.info["connected"] is True
    assert report.port.info["connected"] is True
    assert report.diff == []
