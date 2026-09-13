"""A minimal, real Shiny app for ``test_peek.py`` to point a browser at.

Deliberately plain: one input, one output, no bslib-react or shinyreact
involved, so a failure in this test can only mean ``bslib_react.port.peek()``
itself is broken, not some other package's markup.
"""

from shiny import App, render, ui

app_ui = ui.page_fluid(
    ui.h2("Hello", id="heading"),
    ui.input_slider("n", "N", min=1, max=10, value=3),
    ui.output_text("doubled"),
)


def server(input, output, session):
    @render.text
    def doubled():
        return str(input.n() * 2)


app = App(app_ui, server)
