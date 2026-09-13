"""Volcano plot, a small real analysis app built with bslib-react.

The React client (src/, built to www/ui.js) owns the page. This file
holds only reactive computation and the matplotlib rendering; volcano.py
holds the pure data preparation and plotting logic shared with nothing
else here, kept separate only so it stays independently testable.
"""

from pathlib import Path

import pandas as pd
from bslib_react import bslib_react_dep, host_input, page_deps
from shiny import App, Inputs, Outputs, Session, module, reactive, render, ui
from shinyreact import page_react
from volcano import plot_volcano, volcano_data, volcano_status_counts

app_theme = ui.Theme.from_brand(Path(__file__).parent)

de_results = pd.read_csv(Path(__file__).parent / "data" / "de_results.csv")

app_ui = page_react(
    page_deps(app_theme),
    bslib_react_dep(),
    title="Volcano plot",
    theme=app_theme,
)


# The plot lives in a module ("volcano"), matching R's moduleServer("volcano", ...):
# the client's <Module namespace="volcano"> wrapper resolves "volcano-plot" and
# "volcano-click" without either id needing to be spelled out by hand, and the
# same client works against either server unchanged.
@module.server
def volcano_server(
    input: Inputs,
    output: Outputs,
    session: Session,
    lfc_threshold: reactive.Calc,
    p_threshold: reactive.Calc,
    p_col: reactive.Calc,
    label_top_n: reactive.Calc,
):
    @reactive.calc
    def vdata():
        return volcano_data(
            de_results,
            lfc_threshold=lfc_threshold(),
            p_threshold=p_threshold(),
            p_col=p_col(),
            label_top_n=label_top_n(),
        )

    @render.plot(alt="Volcano plot")
    def plot():
        return plot_volcano(vdata(), lfc_threshold(), p_threshold())

    return vdata


def server(input: Inputs, output: Outputs, session: Session):
    # Every hosted input is a @render.ui-wrapped output, hosted through
    # bslib-react's HostedInput components (see docs/porting.md, "Hosting
    # a widget").
    host_input(
        output,
        "lfc",
        lambda: ui.input_slider(
            "lfc", "|log2 fold change| threshold", 0, 5, 1, step=0.1
        ),
    )
    host_input(
        output,
        "p",
        lambda: ui.input_slider(
            "p", "Significance threshold", 0.001, 0.1, 0.05, step=0.001
        ),
    )
    host_input(
        output,
        "pcol",
        lambda: ui.input_radio_buttons(
            "pcol", "Significance metric", {"padj": "Adjusted p", "pvalue": "Raw p"}
        ),
    )
    host_input(
        output, "dolabel", lambda: ui.input_checkbox("dolabel", "Label top genes", True)
    )
    host_input(
        output, "topn", lambda: ui.input_slider("topn", "Max labels", 0, 30, 10, step=1)
    )

    # Hosted inputs have no value on the very first reactive flush, before
    # their own client round-trip completes (see examples/01-hello/app.py
    # for the same point made about a single input). The `or` fallbacks
    # below use each widget's own initial value, the same choice app.R
    # makes with %||%, so the plot renders immediately instead of waiting.
    vdata = volcano_server(
        "volcano",
        lfc_threshold=lambda: input.lfc() or 1,
        p_threshold=lambda: input.p() or 0.05,
        p_col=lambda: input.pcol() or "padj",
        label_top_n=lambda: (input.topn() or 10) if (input.dolabel() or True) else 0,
    )

    @reactive.calc
    def counts():
        return volcano_status_counts(vdata())

    @render.text
    def n_up():
        return str(counts()["Up"])

    @render.text
    def n_down():
        return str(counts()["Down"])

    @render.text
    def n_ns():
        return str(counts()["NS"])


app = App(app_ui, server)
