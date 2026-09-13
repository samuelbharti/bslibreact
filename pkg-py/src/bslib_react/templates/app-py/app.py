from pathlib import Path

from shiny import App, ui
from shinyreact import page_react

from bslib_react import host_input, page_deps

app_theme = (
    ui.Theme.from_brand(Path(__file__).parent)
    if (Path(__file__).parent / "_brand.yml").exists()
    else None
)
app_ui = page_react(page_deps(app_theme), title="APP_TITLE", theme=app_theme)


def server(input, output, session):
    host_input(output, "bins", lambda: ui.input_slider("bins", "Bins", 1, 50, 30))


app = App(app_ui, server)
