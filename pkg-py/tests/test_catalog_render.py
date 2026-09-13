"""``render_markup_catalog()``: the JSON file pkg-js's tests read."""

from __future__ import annotations

import json
import re
from pathlib import Path

import pytest
from bslib_react import __version__
from bslib_react._catalog_render import markup_catalog_key, render_markup_catalog


def test_top_level_fields(tmp_path: Path) -> None:
    out = tmp_path / "py.json"
    record = render_markup_catalog(out, served="never", quiet=True)

    assert record["schema"] == 1
    assert record["language"] == "py"
    assert record["key"] == markup_catalog_key()
    assert record["generator"] == {"package": "bslib-react", "version": __version__}
    assert set(record["versions"]) == {
        "shiny",
        "htmltools",
        "bslib_vendored",
        "runtime",
    }
    assert record["versions"]["runtime"].startswith("Python ")
    assert record["generated_at"].endswith("Z")
    assert out.is_file()
    on_disk = json.loads(out.read_text(encoding="utf-8"))
    assert on_disk == record


def test_every_sample_has_the_documented_fields(tmp_path: Path) -> None:
    record = render_markup_catalog(tmp_path / "py.json", served="never", quiet=True)
    for name, entry in record["samples"].items():
        assert set(entry) == {
            "kind",
            "group",
            "pkg",
            "served",
            "call",
            "html",
            "html_attrs",
            "head_inline_css",
            "deps",
            "skipped",
        }, name
        assert entry["pkg"] == "shiny"
        assert entry["skipped"] is None
        assert isinstance(entry["html"], str) and entry["html"]


def test_page_navbar_regression_nav_item_nav_link_active_together(
    tmp_path: Path,
) -> None:
    """The regression this repo exists for (see docs/decisions/0001).

    py-shiny's `nav_panel()` unconditionally adds `nav-item` to the `<li>`
    and `nav-link` to its `<a>` (see `shiny/ui/_navs.py`'s `NavPanel.resolve()`)
    -- there is no Bootstrap-3 branch to accidentally fall into the way a
    plain `as.character()` dump without a theme active could produce in R.
    The first nav_panel ("Browse") has no explicit `selected=`, so it is
    selected by default and should carry `active` on both the `<li>` and its
    `<a>`.
    """
    record = render_markup_catalog(tmp_path / "py.json", served="never", quiet=True)
    html = record["samples"]["page_navbar"]["html"]
    assert "nav-item" in html
    assert "nav-link" in html
    assert "active" in html
    # The three classes must actually co-occur on the same selected tab, not
    # just appear somewhere in the document independently. The <a> carries
    # several data-* attributes before `class=`, so this only anchors on
    # `<li class="nav-item">` immediately followed by an `<a ...>` whose
    # attributes (in any order) include `class="nav-link active"`.
    assert re.search(
        r'<li class="nav-item">\s*<a\b[^>]*\bclass="nav-link active"', html
    )
    # And never in the old Bootstrap-3 shape this repo exists to catch.
    assert '<li class="active">' not in html


def test_cache_skips_rewriting_when_the_key_matches(tmp_path: Path) -> None:
    out = tmp_path / "py.json"
    render_markup_catalog(out, served="never", quiet=True)
    first_mtime = out.stat().st_mtime_ns

    render_markup_catalog(out, served="never", cache=True, quiet=True)
    assert out.stat().st_mtime_ns == first_mtime


def test_cache_false_always_rewrites(tmp_path: Path) -> None:
    out = tmp_path / "py.json"
    render_markup_catalog(out, served="never", quiet=True)
    first_mtime = out.stat().st_mtime_ns

    render_markup_catalog(out, served="never", cache=False, quiet=True)
    assert out.stat().st_mtime_ns >= first_mtime


def test_components_filters_to_the_given_samples(tmp_path: Path) -> None:
    record = render_markup_catalog(
        tmp_path / "py.json",
        served="never",
        components=["sliderInput", "actionButton"],
        quiet=True,
    )
    assert set(record["samples"]) == {"sliderInput", "actionButton"}


def test_unknown_component_raises() -> None:
    with pytest.raises(ValueError, match="not_a_real_sample"):
        render_markup_catalog(
            components=["not_a_real_sample"], served="never", cache=False
        )


def test_served_auto_renders_full_documents_for_page_samples(tmp_path: Path) -> None:
    """The one test that starts a background app (see _app_runner.start_app)."""
    record = render_markup_catalog(
        tmp_path / "py.json", served="auto", components=["page_navbar"], quiet=True
    )
    entry = record["samples"]["page_navbar"]
    assert entry["served"] is True
    assert isinstance(entry["html_attrs"], dict)
    assert isinstance(entry["head_inline_css"], list)
    assert "nav-item" in entry["html"]
    assert re.search(
        r'<li class="nav-item">\s*<a\b[^>]*\bclass="nav-link active"', entry["html"]
    )
    # The captured body must be the real page's own (see _ServedPageParser),
    # not py-shiny's near-empty outer wrapper.
    assert "bslib-page-navbar" in entry["html"]
