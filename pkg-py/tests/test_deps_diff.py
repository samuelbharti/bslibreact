"""``port.deps_diff()``: compare what the browser loads for two apps."""

from __future__ import annotations

from pathlib import Path

from bslib_react.port import deps_diff
from bslib_react.port._deps_diff import lib_key

_APP_WITH_PAGE_DEPS = (
    "from shiny import App, ui\n"
    "from bslib_react import page_deps\n\n"
    'app_ui = ui.page_fluid(*page_deps(), ui.input_slider("x", "X", 1, 10, 5))\n\n'
    "def server(input, output, session):\n"
    "    pass\n\n"
    "app = App(app_ui, server)\n"
)

_APP_WITHOUT_PAGE_DEPS = (
    "from shiny import App, ui\n\n"
    'app_ui = ui.page_fluid(ui.input_slider("x", "X", 1, 10, 5))\n\n'
    "def server(input, output, session):\n"
    "    pass\n\n"
    "app = App(app_ui, server)\n"
)


def test_an_app_compared_against_itself_is_clean(tmp_path: Path) -> None:
    app_dir = tmp_path / "app"
    app_dir.mkdir()
    (app_dir / "app.py").write_text(_APP_WITH_PAGE_DEPS, encoding="utf-8")

    result = deps_diff(app_dir, app_dir, timeout=60)
    assert result.n == 0
    assert "clean" in str(result)


def test_missing_page_deps_shows_up_as_a_difference(tmp_path: Path) -> None:
    with_deps = tmp_path / "with_deps"
    with_deps.mkdir()
    (with_deps / "app.py").write_text(_APP_WITH_PAGE_DEPS, encoding="utf-8")

    without_deps = tmp_path / "without_deps"
    without_deps.mkdir()
    (without_deps / "app.py").write_text(_APP_WITHOUT_PAGE_DEPS, encoding="utf-8")

    result = deps_diff(with_deps, without_deps, timeout=60)
    assert result.n > 0
    assert "difference" in str(result)


def test_lib_key_groups_versioned_bootstrap_builds_together() -> None:
    assert lib_key("bootstrap-5.3.3/bootstrap.min.css") == lib_key(
        "bootstrap-3.4.1/css/bootstrap.min.css"
    )


def test_lib_key_groups_shared_ionrangeslider_with_versioned_build() -> None:
    assert lib_key("shared/ionrangeslider/css/ion.rangeSlider.css") == lib_key(
        "ionRangeSlider-2.3.1/ionRangeSlider.min.css"
    )
