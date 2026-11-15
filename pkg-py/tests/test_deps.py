"""``page_deps()``: the dependency list bslibreact's components need."""

from pathlib import Path
from typing import Sequence

import pytest
from bslibreact._deps import page_deps
from htmltools import HTMLDependency, TagChild, TagList
from shiny import ui


def _names(deps: Sequence[TagChild]) -> set[str]:
    # page_deps() only ever returns HTMLDependency items; the isinstance
    # check is for the type checker's benefit (TagChild is a broad union),
    # not because a non-dependency is actually expected here.
    return {d.name for d in deps if isinstance(d, HTMLDependency)}


def test_returns_dependencies() -> None:
    deps = page_deps()
    assert len(deps) > 0
    assert all(isinstance(d, HTMLDependency) for d in deps)


def test_excludes_bootstrap_and_jquery() -> None:
    names = _names(page_deps())
    assert "bootstrap" not in names
    assert "jquery" not in names


def test_empty_components_plus_extra_yields_only_the_extras_dependencies() -> None:
    deps = page_deps(None, ui.input_slider("a", "A", 1, 10, 5), components=[])
    names = _names(deps)
    assert "ionrangeslider" in names
    # Nothing from the (excluded) catalog sample should sneak in: every
    # dependency present must be one input_slider() itself would pull in.
    solo_slider_deps = (
        TagList(ui.input_slider("a", "A", 1, 10, 5)).tagify().get_dependencies()
    )
    assert names <= _names(solo_slider_deps)


def test_unknown_component_name_raises_naming_it() -> None:
    with pytest.raises(ValueError, match="not_a_real_sample"):
        page_deps(components=["not_a_real_sample"])


def test_bad_theme_type_raises_type_error() -> None:
    with pytest.raises(TypeError):
        page_deps(theme=123)  # pyright: ignore[reportArgumentType]


def test_accepts_a_real_theme_instance_without_error() -> None:
    deps = page_deps(ui.Theme("shiny"))
    assert len(deps) > 0


def _theme_names(names: set[str]) -> set[str]:
    return {name for name in names if name.startswith("shiny-theme-")}


def test_py_shiny_still_names_the_theme_stylesheet_shiny_theme() -> None:
    # page_deps() finds the theme stylesheet by this name. If py-shiny renames
    # it, this fails first and says why the tests below stopped meaning much.
    page = ui.page_navbar(ui.nav_panel("A", "x"), theme=ui.Theme("shiny"))
    names = _names(TagList(page).tagify().get_dependencies())
    assert "shiny-theme-shiny" in names


def test_never_returns_a_theme_stylesheet() -> None:
    # The catalog's page_navbar samples carry the stock theme. Handed back
    # next to a page with its own theme, it would load after the page's
    # stylesheet and override it, so it is left to the page's theme=.
    assert not _theme_names(_names(page_deps()))
    assert not _theme_names(_names(page_deps(ui.Theme("shiny"))))


def test_a_brand_theme_page_gets_no_stock_stylesheet() -> None:
    pytest.importorskip("brand_yml")
    example = Path(__file__).parents[2] / "examples" / "volcano-plot"
    brand = ui.Theme.from_brand(example)
    assert not _theme_names(_names(page_deps(brand)))
    assert not _theme_names(_names(page_deps(example / "_brand.yml")))


def test_theme_stylesheets_in_extras_are_dropped_too() -> None:
    page = ui.page_navbar(ui.nav_panel("A", "x"), theme=ui.Theme("shiny"))
    assert not _theme_names(_names(page_deps(None, page, components=[])))


def test_accepts_none_str_and_path_themes(tmp_path) -> None:
    page_deps(None)
    page_deps(str(tmp_path / "_brand.yml"))
    page_deps(tmp_path / "_brand.yml")
