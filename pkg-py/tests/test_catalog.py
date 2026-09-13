"""The markup catalog: every sample call must work, and the name set is frozen."""

from bslib_react._catalog import SAMPLES, catalog_eval, catalog_hash

# The full, frozen set of Python catalog sample names. Hardcoded here (not
# derived from SAMPLES) so a change to SAMPLES that adds, removes, or renames
# a sample shows up as a diff in this literal, not as a silently passing
# test -- see docs/markup-catalog.md, "Sample names".
EXPECTED_NAMES = {
    "selectInput",
    "selectizeInput",
    "radioButtons",
    "checkboxInput",
    "sliderInput",
    "actionButton",
    "plotOutput",
    "card_full_screen",
    "sidebar_layout",
    "selectizeInput_server_placeholder",
    "textAreaInput",
    "textOutput",
    "verbatimTextOutput",
    "details_summary",
    "card_bare_children",
    "actionButton_class_override",
    "fileInput",
    "helpText_hr",
    "layout_columns_value_box",
    "plotOutput_click",
    "card_footer",
    "sidebar_layout_titled",
    "sidebar_layout_right_closed",
    "accordion_checkbox_groups",
    "textInput",
    "actionLink",
    "downloadButton",
    "sliderInput_no_ticks",
    "selectizeInput_remove_button",
    "selectizeInput_max_options",
    "radioButtons_inline",
    "numericInput",
    "passwordInput",
    "uiOutput",
    "uiOutput_fill",
    "page_fillable",
    "layout_columns_fill",
    "page_navbar",
    "page_navbar_icon",
    "page_navbar_sidebar",
    "sidebar_custom_class",
    "page_navbar_dropdown",
    "page_navbar_not_fillable",
    "sidebar_layout_gap_padding",
    "layout_columns_single_child",
    "card_id",
    "card_height",
    "card_no_fill",
    "tooltip",
    "popover",
    "value_box",
    "uiOutput_inline",
    "input_dark_mode",
    "input_switch",
    "input_task_button",
    "accordion",
    "navset_card_tab",
    "navset_pill",
    "checkboxGroupInput",
    "dateInput",
    "dateRangeInput",
}

# Names the R catalog has that Python's does not, because `shiny` alone (the
# only package this catalog's `pkg` field ever names) cannot produce them.
# A deliberate, visible decision -- see `_catalog.py`'s module docstring for
# the reasoning behind each one.
R_ONLY_NAMES = {
    "plotOutput_with_spinner",  # shinycssloaders
    "DTOutput",  # DT
    "DTOutput_no_fill",  # DT
    # htmlwidget_output in R; shinywidgets is a separate Python package.
    "igvShinyOutput",
    "reactableOutput",  # reactable
    "icon",  # shiny::icon() (Font Awesome via base shiny); py-shiny has no icon helper
}


def test_sample_names_match_the_frozen_list() -> None:
    assert {sample.name for sample in SAMPLES} == EXPECTED_NAMES


def test_sample_names_are_unique() -> None:
    names = [sample.name for sample in SAMPLES]
    assert len(names) == len(set(names))


def test_r_only_names_do_not_overlap_the_python_catalog() -> None:
    assert EXPECTED_NAMES.isdisjoint(R_ONLY_NAMES)


def test_every_sample_call_evaluates_without_error() -> None:
    failures = []
    for sample in SAMPLES:
        try:
            catalog_eval([sample.name])
        except Exception as exc:  # noqa: BLE001 - collecting every failure for one clear message
            failures.append(f"{sample.name}: {exc!r}")
    assert not failures, "\n".join(failures)


def test_every_sample_pkg_is_shiny() -> None:
    assert all(sample.pkg == "shiny" for sample in SAMPLES)


def test_every_sample_kind_is_tag_or_page() -> None:
    # No "extra" (third-party) samples in Python for 0.1.0 -- see the
    # `Sample.pkg` note in `_catalog.py`.
    assert all(sample.kind in ("tag", "page") for sample in SAMPLES)


def test_catalog_hash_is_stable() -> None:
    assert catalog_hash() == catalog_hash()


def test_catalog_hash_changes_when_a_call_string_changes() -> None:
    original = SAMPLES[0]
    edited = type(original)(
        name=original.name,
        kind=original.kind,
        group=original.group,
        pkg=original.pkg,
        call=original.call + "  # changed",
    )
    edited_samples = (edited, *SAMPLES[1:])
    assert catalog_hash(edited_samples) != catalog_hash(SAMPLES)
