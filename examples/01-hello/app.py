"""Hello bslibreact, a shinyreact app built with bslibreact.

The client (src/, built to www/ui.js) owns the page. This file holds only
reactive computation: page_deps() gives the client the same CSS and
JavaScript a matching bslib page would attach on its own, and host_input()
hosts one server-rendered widget for the client to display.
"""

import matplotlib.pyplot as plt
import numpy as np
from bslibreact import host_input, page_deps
from shiny import App, render, ui
from shinyreact import page_react

# The stock theme, matching R's bs_theme(version = 5). page_react() attaches
# Bootstrap only when it is given a theme, so None here would leave the
# page with no Bootstrap JS at all.
app_theme = ui.Theme()

app_ui = page_react(
    page_deps(app_theme),
    title="Hello bslibreact",
    theme=app_theme,
)


def server(input, output, session):
    # Level H: a server-rendered widget, hosted for the client to display.
    # The client reads this with <SliderInput id="bins_ui" />, and reads
    # the slider's own value the usual way, from input.bins(), once it
    # mounts.
    host_input(output, "bins", lambda: ui.input_slider("bins", "Bins", 1, 50, 30))

    # Level H: a hosted plot. The client reads this with
    # <PlotOutput id="plot" />.
    #
    # The slider is hosted, so input.bins() has no value until the client
    # has bound it. Reading it before then raises py-shiny's silent
    # exception, so the plot stays blank until the value arrives; no req()
    # is needed.
    @render.plot
    def plot():
        # Read the input first: if it is not bound yet, nothing is drawn and
        # no figure is left open.
        bins = input.bins()
        fig, ax = plt.subplots()
        ax.hist(
            np.random.normal(size=500),
            bins=bins,
            color="#447099",
            edgecolor="white",
        )
        ax.set_xlabel("value")
        return fig

    # Level R: a plain value, read by the client with useShinyOutputValue()
    # rather than hosted, since it is only ever a number formatted as text.
    # Waits for the slider the same way plot() does.
    @render.text
    def bins_count():
        return str(input.bins())


app = App(app_ui, server)
