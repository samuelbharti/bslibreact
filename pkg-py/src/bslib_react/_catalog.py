"""The markup catalog: sample UI calls and the live shiny markup they produce.

This is the Python half of the contract in ``docs/markup-catalog.md``. bslib
(and py-shiny) are the ground truth for what bslib-react's React components
should render: rather than commit HTML fixtures that go stale the moment
shiny's markup changes, this module holds a catalog of *calls* -- Python
source text -- that get evaluated against whatever version of ``shiny`` is
actually installed, by :func:`catalog_eval`. ``tools/markup/render_py.py``
turns the result into the JSON file the JS test suite reads.

Sample names are frozen: they must match the R catalog's names wherever
py-shiny has the component (see ``docs/markup-catalog.md``, "Sample names").
Renaming or removing one is a deliberate, visible edit -- ``test_catalog.py``
pins the whole name set as a literal.

Six of the R catalog's names have no Python entry, because ``shiny`` alone
cannot produce them (there is no "extra" third-party kind here the way R's
DT/reactable/htmlwidgets samples exist):

- ``plotOutput_with_spinner`` -- wraps a plot in ``shinycssloaders``.
- ``DTOutput``, ``DTOutput_no_fill`` -- the ``DT`` package.
- ``htmlwidget_output`` -- the generic ``htmlwidgets`` output shape.
  Python's analogue lives in the separate ``shinywidgets`` package.
- ``reactableOutput`` -- the ``reactable`` package.
- ``icon`` -- R's ``shiny::icon()`` renders Font Awesome markup that ships
  with base R shiny. py-shiny has no built-in icon helper at all (an icon is
  just whatever ``TagChild`` you pass), so there is no ``shiny``-only call
  that stands in for it.

``call`` strings are Python source, evaluated by :func:`catalog_eval` in a
small fixed namespace exposing only ``ui`` (``shiny.ui``). They are fixed
strings written by this module, never user input, so a plain ``eval()`` is
fine here -- the empty ``__builtins__`` just keeps the namespace from growing
by accident as this file evolves.
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass
from typing import TYPE_CHECKING, Literal, Sequence

from shiny import ui

if TYPE_CHECKING:
    from htmltools import TagChild

SampleKind = Literal["tag", "page"]


@dataclass(frozen=True)
class Sample:
    """One catalog entry: a name, and the call that produces its markup."""

    name: str
    kind: SampleKind
    group: str
    call: str


def _s(name: str, kind: SampleKind, group: str, call: str) -> Sample:
    return Sample(name=name, kind=kind, group=group, call=call)


# Kept from the original R kit (`tools/kit/dump-markup.R`), same sample
# names, translated to the equivalent py-shiny call.
SAMPLES: tuple[Sample, ...] = (
    _s(
        "selectInput",
        "tag",
        "input",
        'ui.input_select("x", "Quick pick", choices=["10", "20", "30"])',
    ),
    _s(
        "selectizeInput",
        "tag",
        "input",
        'ui.input_selectize("x", "Genes", choices=["A", "B", "C"], selected="A", '
        "multiple=True)",
    ),
    _s(
        "radioButtons",
        "tag",
        "input",
        'ui.input_radio_buttons("x", "Values", choices={"row": "Row z-score", '
        '"none": "Expression"})',
    ),
    _s(
        "checkboxInput",
        "tag",
        "input",
        'ui.input_checkbox("x", "Cluster genes", value=True)',
    ),
    _s(
        "sliderInput",
        "tag",
        "input",
        'ui.input_slider("x", "Bins", min=1, max=50, value=30)',
    ),
    _s("actionButton", "tag", "input", 'ui.input_action_button("x", "Go")'),
    _s("plotOutput", "tag", "output", 'ui.output_plot("x")'),
    _s(
        "card_full_screen",
        "tag",
        "card",
        'ui.card(ui.card_header("Title"), ui.card_body("Body"), full_screen=True)',
    ),
    _s(
        "sidebar_layout",
        "page",
        "page",
        'ui.page_sidebar(ui.sidebar(ui.input_select("x", "Pick", choices=["A"]), '
        "width=290), "
        'ui.card(ui.card_header("Main"), ui.card_body("Content")), title="Demo")',
    ),
    _s(
        "selectizeInput_server_placeholder",
        "tag",
        "input",
        'ui.input_selectize("x", "Pick genes", choices=[], multiple=True, '
        'options={"placeholder": "type to search..."})',
    ),
    _s(
        "textAreaInput",
        "tag",
        "input",
        'ui.input_text_area("x", None, rows=3, placeholder="GENE1, GENE2, GENE3...")',
    ),
    _s("textOutput", "tag", "output", 'ui.output_text("x")'),
    _s(
        "verbatimTextOutput",
        "tag",
        "output",
        'ui.output_code("x", placeholder=False)',
    ),
    _s(
        "details_summary",
        "tag",
        "misc",
        'ui.tags.details(ui.tags.summary("Paste a list"), '
        'ui.input_text_area("x", None, rows=3))',
    ),
    _s(
        "card_bare_children",
        "tag",
        "card",
        'ui.card(ui.card_header("Current selection"), ui.output_text("count"), '
        'ui.output_code("selected", placeholder=False))',
    ),
    _s(
        "actionButton_class_override",
        "tag",
        "input",
        'ui.input_action_button("x", "Apply", class_="btn-sm")',
    ),
    _s(
        "fileInput",
        "tag",
        "input",
        'ui.input_file("x", "de_results.csv", accept=".csv")',
    ),
    _s(
        "helpText_hr",
        "tag",
        "misc",
        'ui.TagList(ui.hr(), ui.help_text("Some help text here."))',
    ),
    _s(
        "layout_columns_value_box",
        "tag",
        "layout",
        'ui.layout_columns(ui.value_box("PC1 variance", ui.output_text("pc1"), '
        'theme="primary"), '
        'ui.value_box("PC2 variance", ui.output_text("pc2"), theme="warning"), '
        'ui.value_box("Genes used", ui.output_text("ngenes"), theme="secondary"), '
        "fill=False, col_widths=[4, 4, 4])",
    ),
    _s(
        "plotOutput_click",
        "tag",
        "output",
        'ui.output_plot("x", height="560px", click=True)',
    ),
    _s(
        "card_footer",
        "tag",
        "card",
        'ui.card(ui.card_header("Title"), ui.card_body("Body"), '
        'ui.card_footer("Footer text"))',
    ),
    _s(
        "sidebar_layout_titled",
        "tag",
        "layout",
        'ui.layout_sidebar(ui.sidebar("filters", title="Filters", width=260), '
        'ui.div("main"))',
    ),
    _s(
        "sidebar_layout_right_closed",
        "tag",
        "layout",
        'ui.layout_sidebar(ui.sidebar("controls", title="Selected study", '
        'position="right", '
        'width=360, open="closed", id="details_pane"), ui.div("main"))',
    ),
    _s(
        "accordion_checkbox_groups",
        "tag",
        "layout",
        'ui.accordion(ui.accordion_panel("Organism", '
        'ui.input_checkbox_group("organisms", None, '
        'choices={}), value="organism"), ui.accordion_panel("Data source", '
        'ui.input_checkbox_group("sources", None, choices={}), value="source"), '
        'id="filters", multiple=True, open=["organism", "source"])',
    ),
    _s(
        "textInput",
        "tag",
        "input",
        'ui.input_text("q", None, placeholder="Search accession, title or abstract", '
        'width="100%")',
    ),
    _s(
        "actionLink",
        "tag",
        "input",
        'ui.input_action_link("clear", "Clear all filters", class_="small")',
    ),
    _s(
        "downloadButton",
        "tag",
        "input",
        'ui.download_button("qc_pdf", "PDF", class_="btn-sm ms-auto")',
    ),
    _s(
        "sliderInput_no_ticks",
        "tag",
        "input",
        'ui.input_slider("font_size", "Font size", min=10, max=26, value=21, step=1, '
        "ticks=False)",
    ),
    _s(
        "selectizeInput_remove_button",
        "tag",
        "input",
        'ui.input_selectize("columns", "Columns", choices=[], multiple=True, '
        'width="100%", '
        'options={"plugins": ["remove_button"]})',
    ),
    _s(
        "selectizeInput_max_options",
        "tag",
        "input",
        'ui.input_selectize("gene", "Search for a gene", choices=[], '
        'options={"placeholder": "Symbol or Ensembl id", "maxOptions": 50})',
    ),
    _s(
        "radioButtons_inline",
        "tag",
        "input",
        'ui.input_radio_buttons("geom", "Plot", choices={"box": "Boxplot", '
        '"violin": "Violin"}, inline=True)',
    ),
    _s(
        "numericInput",
        "tag",
        "input",
        'ui.input_numeric("loading_pc", "Loadings for PC", value=1, min=1, max=10, '
        "step=1)",
    ),
    _s(
        "passwordInput",
        "tag",
        "input",
        'ui.input_password("api_key", "API key", placeholder="Paste your key")',
    ),
    _s("uiOutput", "tag", "output", 'ui.output_ui("x")'),
    _s("uiOutput_fill", "tag", "output", 'ui.output_ui("x", fill=True)'),
    _s(
        "page_fillable",
        "page",
        "page",
        'ui.page_fillable(ui.tags.h2("Title"), padding=8, gap=4)',
    ),
    _s(
        "layout_columns_fill",
        "tag",
        "layout",
        'ui.layout_columns(ui.card(ui.card_header("Left"), ui.card_body("Left body")), '
        'ui.card(ui.card_header("Right"), ui.card_body("Right body")), col_widths=[7, '
        "5])",
    ),
    _s(
        "page_navbar",
        "page",
        "page",
        'ui.page_navbar(ui.nav_panel("Browse", "x"), ui.nav_panel("Overview", "y"), '
        "ui.nav_spacer(), "
        'ui.nav_control(ui.output_ui("chip", inline=True)), '
        'ui.nav_control(ui.input_dark_mode(id="dark_mode")), title="Demo", id="nav", '
        'theme=ui.Theme("shiny"), '
        'navbar_options=ui.navbar_options(bg="var(--brand-roast)", theme="dark"), '
        'fillable=["Browse"], footer=ui.div("foot"))',
    ),
    _s(
        "page_navbar_icon",
        "page",
        "page",
        'ui.page_navbar(ui.nav_panel("Explorer", "x", '
        'icon=ui.tags.i(class_="bi bi-bar-chart-line")), '
        'ui.nav_panel("About", "y", icon=ui.tags.i(class_="bi bi-info-circle")), '
        'title="Demo", id="nav", theme=ui.Theme("shiny"))',
    ),
    _s(
        "page_navbar_sidebar",
        "page",
        "page",
        'ui.page_navbar(ui.nav_panel("Build", ui.div("build content")), '
        'ui.nav_panel("About", ui.div("about content")), title="Demo", id="nav", '
        'sidebar=ui.sidebar(ui.div("chat"), id="dock", position="left", open="closed", '
        "width=600), "
        'footer=ui.tags.footer("foot"))',
    ),
    _s(
        "sidebar_custom_class",
        "tag",
        "layout",
        'ui.layout_sidebar(ui.sidebar(ui.div("a"), width=420, '
        'class_="my-sidebar"), ui.div("main"))',
    ),
    # `page_navbar_dropdown` replaces the old hand-corrected fixture: a
    # live render needs no correction for a shape `as.character()` could not
    # represent faithfully.
    _s(
        "page_navbar_dropdown",
        "page",
        "page",
        'ui.page_navbar(ui.nav_panel("Review", "x"), ui.nav_menu("Docs", '
        'ui.nav_panel("Guide", "g"), '
        'ui.nav_panel("FAQ", "f")), id="nav", title="Demo")',
    ),
    # Added for coverage the original kit did not have (see docs/markup-catalog.md).
    _s(
        "page_navbar_not_fillable",
        "page",
        "page",
        'ui.page_navbar(ui.nav_panel("One", "a"), ui.nav_panel("Two", "b"), '
        'title="Demo", id="nav", '
        "fillable=False)",
    ),
    _s(
        "sidebar_layout_gap_padding",
        "tag",
        "layout",
        'ui.layout_sidebar(ui.sidebar("filters", width=260), ui.div("main"), '
        'gap="1rem", padding="1rem")',
    ),
    _s(
        "layout_columns_single_child",
        "tag",
        "layout",
        'ui.layout_columns(ui.card(ui.card_header("Solo"), '
        'ui.card_body("Only one column")))',
    ),
    _s(
        "card_id",
        "tag",
        "card",
        'ui.card(ui.card_header("Title"), ui.card_body("Body"), id="my_card")',
    ),
    _s(
        "card_height",
        "tag",
        "card",
        'ui.card(ui.card_header("Title"), ui.card_body("Body"), height="300px")',
    ),
    _s(
        "card_no_fill",
        "tag",
        "card",
        'ui.card(ui.card_header("Title"), ui.card_body("Body"), fill=False)',
    ),
    _s(
        "tooltip",
        "tag",
        "tooltip",
        'ui.tooltip(ui.input_action_button("btn", "Hover me"), "Extra information", '
        'id="tt")',
    ),
    _s(
        "popover",
        "tag",
        "tooltip",
        'ui.popover(ui.input_action_button("btn2", "Click me"), "Popover body", '
        'title="More info", id="pop")',
    ),
    _s(
        "value_box",
        "tag",
        "card",
        'ui.value_box("KPI", "42", "up 3% this week", theme="primary")',
    ),
    _s("uiOutput_inline", "tag", "output", 'ui.output_ui("x", inline=True)'),
    _s("input_dark_mode", "tag", "input", 'ui.input_dark_mode(id="dark_mode")'),
    _s(
        "input_switch",
        "tag",
        "input",
        'ui.input_switch("x", "Enable feature", value=True)',
    ),
    _s(
        "input_task_button",
        "tag",
        "input",
        'ui.input_task_button("go", "Run", label_busy="Running...")',
    ),
    _s(
        "accordion",
        "tag",
        "layout",
        'ui.accordion(ui.accordion_panel("Section A", "Body A", value="a"), '
        'ui.accordion_panel("Section B", "Body B", value="b"), id="acc")',
    ),
    _s(
        "navset_card_tab",
        "tag",
        "nav",
        'ui.navset_card_tab(ui.nav_panel("Tab 1", "One"), '
        'ui.nav_panel("Tab 2", "Two"))',
    ),
    _s(
        "navset_pill",
        "tag",
        "nav",
        'ui.navset_pill(ui.nav_panel("Tab 1", "One"), ui.nav_panel("Tab 2", "Two"))',
    ),
    _s(
        "checkboxGroupInput",
        "tag",
        "input",
        'ui.input_checkbox_group("opts", "Options", choices={"a": "Alpha", '
        '"b": "Beta"}, selected=["a"])',
    ),
    _s("dateInput", "tag", "input", 'ui.input_date("d", "Date")'),
    _s("dateRangeInput", "tag", "input", 'ui.input_date_range("dr", "Date range")'),
)


def markup_catalog(kind: Sequence[str] | None = None) -> tuple[Sample, ...]:
    """Return catalog samples, optionally filtered to the given ``kind`` values."""
    if kind is None:
        return SAMPLES
    kinds = set(kind)
    return tuple(sample for sample in SAMPLES if sample.kind in kinds)


def catalog_names(kind: Sequence[str] | None = None) -> list[str]:
    """Names of the catalog samples matching ``kind`` (all, if omitted)."""
    return [sample.name for sample in markup_catalog(kind)]


def catalog_eval(names: Sequence[str]) -> list["TagChild"]:
    """Evaluate each named sample's ``call`` and return the resulting tags.

    Uses a fixed namespace exposing only ``ui`` (``shiny.ui``) plus an empty
    ``__builtins__``. Every ``call`` string is one of this module's own
    literals (see :data:`SAMPLES`), not user input, so a plain ``eval()`` is
    appropriate here.
    """
    by_name = {sample.name: sample for sample in SAMPLES}
    namespace = {"ui": ui, "__builtins__": {}}
    results: list["TagChild"] = []
    for name in names:
        sample = by_name.get(name)
        if sample is None:
            raise ValueError(f"unknown catalog sample: {name!r}")
        results.append(eval(sample.call, namespace))  # noqa: S307
    return results


def catalog_hash(samples: Sequence[Sample] | None = None) -> str:
    """A stable hash of the catalog's names, kinds, groups and call text.

    Part of the catalog render key (see ``tools/markup/render_py.py``): it changes
    whenever a sample is added, removed, or its call text edited, so a stale
    cache gets re-rendered.
    """
    selected = samples if samples is not None else SAMPLES
    lines = "\n".join(
        f"{sample.name}|{sample.kind}|{sample.group}|{sample.call}"
        for sample in selected
    )
    return hashlib.sha256(lines.encode("utf-8")).hexdigest()
