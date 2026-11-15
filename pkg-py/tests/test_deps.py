"""``page_deps()``: the dependency list bslibreact's components need."""

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


def test_accepts_none_str_and_path_themes(tmp_path) -> None:
    page_deps(None)
    page_deps(str(tmp_path / "_brand.yml"))
    page_deps(tmp_path / "_brand.yml")
