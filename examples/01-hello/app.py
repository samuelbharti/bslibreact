"""Hello bslib-react, a shinyreact app built with bslib-react.

The client (src/, built to www/ui.js) owns the page. This file holds only
reactive computation: page_deps() gives the client the same CSS and
JavaScript a matching bslib page would attach on its own, and host_input()
hosts one server-rendered widget for the client to display.
"""

import matplotlib.pyplot as plt
import numpy as np
from shiny import App, render, req, ui
from shinyreact import page_react

from bslib_react import bslib_react_dep, host_input, page_deps

# py-shiny's Theme has no Bootstrap version knob (it targets Bootstrap 5
# only); None here means the stock theme, matching R's bs_theme(version = 5)
# with no other customization.
app_theme = None

app_ui = page_react(
    page_deps(app_theme),
    bslib_react_dep(),
    title="Hello bslib-react",
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
    # req(input.bins()): the slider is hosted, so it does not exist in the
    # initial page HTML the way a plain ui.input_slider() would. Shiny only
    # learns input.bins() after the client round-trips the widget's dynamic
    # UI and binds it, which happens after this reactive's first flush.
    # req() holds the output blank until that value actually arrives,
    # instead of erroring on an empty bins= argument on session start.
    @render.plot
    def plot():
        req(input.bins())
        fig, ax = plt.subplots()
        ax.hist(
            np.random.normal(size=500),
            bins=input.bins(),
            color="#447099",
            edgecolor="white",
        )
        ax.set_xlabel("value")
        return fig

    # Level R: a plain value, read by the client with useShinyOutputValue()
    # rather than hosted, since it is only ever a number formatted as text.
    # Same req() reasoning as plot() above.
    @render.text
    def bins_count():
        req(input.bins())
        return str(input.bins())


app = App(app_ui, server)
