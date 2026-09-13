"""``port.triage()``: take stock of a parent app from its source alone."""

from __future__ import annotations

from pathlib import Path

import pytest
from bslib_react.port import triage

_APP_PY = """\
from pathlib import Path
from shiny import App, reactive, render, ui

app_theme = ui.Theme("shiny")

app_ui = ui.page_navbar(
    ui.nav_panel(
        "Main",
        ui.layout_sidebar(
            ui.sidebar(
                ui.input_slider("bins", "Bins", 1, 50, 30),
                ui.input_select("kind", "Kind", choices=["a", "b"]),
            ),
            ui.card(ui.card_header("Plot"), ui.output_plot("hist")),
        ),
    ),
    title="Demo",
    id="nav",
)


def server(input, output, session):
    @reactive.calc
    def data():
        return input.bins() * 2

    @render.plot
    def hist():
        return data()
"""


@pytest.fixture
def app_dir(tmp_path: Path) -> Path:
    d = tmp_path / "fixture_app"
    d.mkdir()
    (d / "app.py").write_text(_APP_PY, encoding="utf-8")
    (d / "requirements.txt").write_text("shiny\n", encoding="utf-8")
    return d


def test_counts_page_input_output_and_layout_calls(app_dir: Path) -> None:
    report = triage(app_dir)
    by_name = {h.name: h.n for h in report.page_hits}
    assert by_name.get("page_navbar") == 1

    input_by_name = {h.name: h.n for h in report.input_hits}
    assert input_by_name.get("input_slider") == 1
    assert input_by_name.get("input_select") == 1

    output_by_name = {h.name: h.n for h in report.output_hits}
    assert output_by_name.get("output_plot") == 1

    layout_by_name = {h.name: h.n for h in report.layout_hits}
    assert layout_by_name.get("layout_sidebar") == 1
    assert layout_by_name.get("sidebar") == 1
    assert layout_by_name.get("card") == 1
    assert layout_by_name.get("card_header") == 1
    assert layout_by_name.get("nav_panel") == 1


def test_finds_the_theme_line(app_dir: Path) -> None:
    report = triage(app_dir)
    assert report.theme_line is not None
    assert "app.py" in report.theme_line


def test_render_calls_are_counted(app_dir: Path) -> None:
    report = triage(app_dir)
    render_names = {h.name for h in report.render_hits}
    assert "render.plot" in render_names


def test_reactivity_calls_are_counted(app_dir: Path) -> None:
    report = triage(app_dir)
    reactivity_names = {h.name for h in report.reactivity_hits}
    assert "reactive.calc" in reactivity_names


def test_env_files_presence(app_dir: Path) -> None:
    report = triage(app_dir)
    assert report.env_files_present["requirements.txt"] is True
    assert report.env_files_present[".env"] is False
    assert report.env_files_present["_brand.yml"] is False


def test_markdown_starts_with_the_triage_header(app_dir: Path) -> None:
    report = triage(app_dir)
    text = str(report)
    assert text.startswith(f"# Triage: {app_dir.name}")
    assert "## Size" in text
    assert "## Page and theme" in text
    assert "## Notes" in text


def test_missing_directory_raises() -> None:
    with pytest.raises(FileNotFoundError):
        triage("this/path/does/not/exist")


def test_triage_also_scans_r_files(tmp_path: Path) -> None:
    d = tmp_path / "r_app"
    d.mkdir()
    (d / "app.R").write_text(
        "library(shiny)\n"
        'ui <- fluidPage(sliderInput("x", "X", 1, 10, 5), plotOutput("p"))\n'
        "server <- function(input, output, session) {}\n"
        "shinyApp(ui, server)\n",
        encoding="utf-8",
    )
    report = triage(d)
    assert report.r_files == 1
    input_by_name = {h.name: h.n for h in report.input_hits}
    assert input_by_name.get("sliderInput") == 1
    output_by_name = {h.name: h.n for h in report.output_hits}
    assert output_by_name.get("plotOutput") == 1
